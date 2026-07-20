begin;

create or replace function public.equip_shop_cosmetic(
  p_item_id text,
  p_slot text,
  p_request_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_existing_ledger public.shop_ledger%rowtype;
  v_item public.shop_items%rowtype;
  v_owned_quantity integer;
  v_ledger public.shop_ledger%rowtype;
begin
  if p_request_id is null then
    raise exception 'request_id is required';
  end if;

  if p_item_id is null or btrim(p_item_id) = '' then
    raise exception 'item_id is required';
  end if;

  if v_user_id is null then
    raise exception 'user_id is required';
  end if;

  if auth.uid() is not null and auth.uid() <> v_user_id then
    raise exception 'authenticated user does not match requested user';
  end if;

  perform pg_advisory_xact_lock(hashtext(v_user_id::text));
  perform pg_advisory_xact_lock(hashtext('shop_request:' || p_request_id::text));

  select *
    into v_existing_ledger
  from public.shop_ledger
  where request_id = p_request_id::text;

  if found then
    if v_existing_ledger.user_id <> v_user_id then
      raise exception 'request_id already used by another user';
    end if;

    return to_jsonb(v_existing_ledger);
  end if;

  select *
    into v_item
  from public.shop_items
  where id = p_item_id
    and is_active = true;

  if not found then
    raise exception 'shop item not found or inactive';
  end if;

  if v_item.category = 'utility' or v_item.equip_slot is null then
    raise exception 'item cannot be equipped';
  end if;

  if p_slot is null or btrim(p_slot) = '' then
    raise exception 'invalid equip slot';
  end if;

  if v_item.equip_slot <> p_slot then
    raise exception 'invalid equip slot';
  end if;

  select quantity
    into v_owned_quantity
  from public.user_inventory
  where user_id = v_user_id
    and item_id = p_item_id
  for update;

  if not found or coalesce(v_owned_quantity, 0) <= 0 then
    raise exception 'item must be owned before equip';
  end if;

  insert into public.user_equipped_cosmetics (
    user_id,
    slot,
    item_id,
    equipped_at
  ) values (
    v_user_id,
    v_item.equip_slot,
    p_item_id,
    now()
  )
  on conflict (user_id, slot) do update
    set item_id = excluded.item_id,
        equipped_at = excluded.equipped_at;

  insert into public.shop_ledger (
    request_id,
    user_id,
    operation,
    item_id,
    slot,
    coins_delta,
    quantity_delta,
    created_at
  ) values (
    p_request_id::text,
    v_user_id,
    'equip',
    p_item_id,
    v_item.equip_slot,
    0,
    0,
    now()
  )
  returning * into v_ledger;

  return to_jsonb(v_ledger);
end;
$$;

revoke all on function public.equip_shop_cosmetic(text, text, uuid) from public, anon;
grant execute on function public.equip_shop_cosmetic(text, text, uuid) to authenticated;

commit;
