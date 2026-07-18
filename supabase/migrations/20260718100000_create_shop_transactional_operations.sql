begin;

create extension if not exists pgcrypto;

create table if not exists public.shop_ledger (
  id uuid primary key default gen_random_uuid(),
  request_id text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  operation text not null,
  item_id text not null references public.shop_items(id),
  slot text,
  coins_delta bigint not null,
  quantity_delta integer not null default 0,
  created_at timestamptz not null default now(),
  constraint shop_ledger_request_id_nonempty check (btrim(request_id) <> ''),
  constraint shop_ledger_operation_check check (operation in ('purchase', 'equip')),
  constraint shop_ledger_slot_check check (
    slot is null or slot in (
      'screen_background',
      'habit_card_background',
      'user_card_background'
    )
  ),
  constraint shop_ledger_coins_delta_check check (
    (operation = 'purchase' and coins_delta < 0 and quantity_delta > 0 and slot is null)
    or
    (operation = 'equip' and coins_delta = 0 and quantity_delta = 0 and slot is not null)
  ),
  constraint shop_ledger_request_id_unique unique (request_id)
);

create index if not exists idx_shop_ledger_user_created_at
  on public.shop_ledger (user_id, created_at desc);

create index if not exists idx_shop_ledger_user_request_id
  on public.shop_ledger (user_id, request_id);

alter table public.shop_ledger enable row level security;

revoke all on public.shop_ledger from public, anon, authenticated;

create or replace function public.purchase_shop_item(
  p_request_id text,
  p_item_id text,
  p_user_id uuid default null
)
returns public.shop_ledger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := coalesce(p_user_id, auth.uid());
  v_existing_ledger public.shop_ledger%rowtype;
  v_item public.shop_items%rowtype;
  v_wallet_coins bigint;
  v_existing_quantity integer;
  v_ledger public.shop_ledger%rowtype;
begin
  if p_request_id is null or btrim(p_request_id) = '' then
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
  perform pg_advisory_xact_lock(hashtext('shop_request:' || p_request_id));

  select *
    into v_existing_ledger
  from public.shop_ledger
  where request_id = p_request_id;

  if found then
    if v_existing_ledger.user_id <> v_user_id then
      raise exception 'request_id already used by another user';
    end if;

    return v_existing_ledger;
  end if;

  select *
    into v_item
  from public.shop_items
  where id = p_item_id
    and is_active = true;

  if not found then
    raise exception 'shop item not found or inactive';
  end if;

  select coins
    into v_wallet_coins
  from public.user_wallets
  where user_id = v_user_id
  for update;

  if not found then
    raise exception 'wallet not found for user';
  end if;

  if v_wallet_coins < v_item.price_coins then
    raise exception 'insufficient wallet balance';
  end if;

  select quantity
    into v_existing_quantity
  from public.user_inventory
  where user_id = v_user_id
    and item_id = p_item_id
  for update;

  if v_item.category = 'utility' then
    if v_item.max_quantity is not null
       and coalesce(v_existing_quantity, 0) + 1 > v_item.max_quantity then
      raise exception 'utility quantity limit reached';
    end if;

    insert into public.user_inventory (
      user_id,
      item_id,
      quantity,
      acquisition_source,
      acquired_at,
      updated_at
    ) values (
      v_user_id,
      p_item_id,
      1,
      'purchase',
      now(),
      now()
    )
    on conflict (user_id, item_id) do update
      set quantity = public.user_inventory.quantity + excluded.quantity;
  else
    if coalesce(v_existing_quantity, 0) > 0 then
      raise exception 'item already owned';
    end if;

    insert into public.user_inventory (
      id,
      user_id,
      item_id,
      quantity,
      acquisition_source,
      acquired_at,
      updated_at
    ) values (
      gen_random_uuid(),
      v_user_id,
      p_item_id,
      1,
      'purchase',
      now(),
      now()
    );
  end if;

  update public.user_wallets
     set coins = coins - v_item.price_coins,
         version = version + 1
   where user_id = v_user_id;

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
    p_request_id,
    v_user_id,
    'purchase',
    p_item_id,
    null,
    -v_item.price_coins,
    1,
    now()
  )
  returning * into v_ledger;

  return v_ledger;
end;
$$;

create or replace function public.equip_shop_cosmetic(
  p_request_id text,
  p_item_id text,
  p_user_id uuid default null
)
returns public.shop_ledger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := coalesce(p_user_id, auth.uid());
  v_existing_ledger public.shop_ledger%rowtype;
  v_item public.shop_items%rowtype;
  v_owned_quantity integer;
  v_ledger public.shop_ledger%rowtype;
begin
  if p_request_id is null or btrim(p_request_id) = '' then
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
  perform pg_advisory_xact_lock(hashtext('shop_request:' || p_request_id));

  select *
    into v_existing_ledger
  from public.shop_ledger
  where request_id = p_request_id;

  if found then
    if v_existing_ledger.user_id <> v_user_id then
      raise exception 'request_id already used by another user';
    end if;

    return v_existing_ledger;
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
    p_request_id,
    v_user_id,
    'equip',
    p_item_id,
    v_item.equip_slot,
    0,
    0,
    now()
  )
  returning * into v_ledger;

  return v_ledger;
end;
$$;

revoke all on function public.purchase_shop_item(text, text, uuid) from public, anon;
revoke all on function public.equip_shop_cosmetic(text, text, uuid) from public, anon;
grant execute on function public.purchase_shop_item(text, text, uuid) to authenticated;
grant execute on function public.equip_shop_cosmetic(text, text, uuid) to authenticated;

commit;
