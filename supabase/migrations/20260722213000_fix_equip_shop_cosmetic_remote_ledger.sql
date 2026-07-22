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
  v_existing_operation public.shop_ledger%rowtype;
  v_item public.shop_items%rowtype;
  v_owned_quantity integer;
  v_wallet_balance bigint;
  v_created_at timestamptz := pg_catalog.now();
  v_result jsonb;
begin
  if v_user_id is null then
    raise exception using
      errcode = 'P0001',
      message = 'AUTH_REQUIRED';
  end if;

  if p_request_id is null then
    raise exception using
      errcode = 'P0001',
      message = 'REQUEST_ID_REQUIRED';
  end if;

  if p_item_id is null
     or pg_catalog.length(pg_catalog.btrim(p_item_id)) = 0 then
    raise exception using
      errcode = 'P0001',
      message = 'ITEM_ID_REQUIRED';
  end if;

  if p_slot is null
     or pg_catalog.length(pg_catalog.btrim(p_slot)) = 0 then
    raise exception using
      errcode = 'P0001',
      message = 'INVALID_EQUIP_SLOT';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_user_id::text, 0)
  );

  select ledger.*
    into v_existing_operation
  from public.shop_ledger as ledger
  where ledger.request_id = p_request_id;

  if found then
    if v_existing_operation.user_id <> v_user_id
       or v_existing_operation.operation_type <> 'equip'
       or v_existing_operation.item_id is distinct from p_item_id
       or v_existing_operation.result ->> 'slot' is distinct from p_slot then
      raise exception using
        errcode = 'P0001',
        message = 'REQUEST_ID_CONFLICT';
    end if;

    return v_existing_operation.result;
  end if;

  select item.*
    into v_item
  from public.shop_items as item
  where item.id = p_item_id
    and item.is_active = true;

  if not found then
    raise exception using
      errcode = 'P0001',
      message = 'ITEM_NOT_FOUND';
  end if;

  if v_item.category = 'utility'
     or v_item.equip_slot is null then
    raise exception using
      errcode = 'P0001',
      message = 'ITEM_NOT_EQUIPPABLE';
  end if;

  if v_item.equip_slot <> p_slot then
    raise exception using
      errcode = 'P0001',
      message = 'INVALID_EQUIP_SLOT';
  end if;

  select inventory.quantity
    into v_owned_quantity
  from public.user_inventory as inventory
  where inventory.user_id = v_user_id
    and inventory.item_id = p_item_id
  for update;

  if not found or pg_catalog.coalesce(v_owned_quantity, 0) <= 0 then
    raise exception using
      errcode = 'P0001',
      message = 'ITEM_NOT_OWNED';
  end if;

  select wallet.coins
    into v_wallet_balance
  from public.user_wallets as wallet
  where wallet.user_id = v_user_id;

  insert into public.user_equipped_cosmetics (
    user_id,
    slot,
    item_id,
    equipped_at
  )
  values (
    v_user_id,
    v_item.equip_slot,
    p_item_id,
    v_created_at
  )
  on conflict (user_id, slot)
  do update
  set
    item_id = excluded.item_id,
    equipped_at = excluded.equipped_at;

  v_result := pg_catalog.jsonb_build_object(
    'requestId', p_request_id,
    'operation', 'equip',
    'itemId', p_item_id,
    'slot', v_item.equip_slot,
    'createdAt', v_created_at
  );

  insert into public.shop_ledger (
    user_id,
    request_id,
    operation_type,
    item_id,
    coin_delta,
    quantity_delta,
    balance_after,
    inventory_quantity_after,
    result,
    metadata
  )
  values (
    v_user_id,
    p_request_id,
    'equip',
    p_item_id,
    0,
    0,
    v_wallet_balance,
    v_owned_quantity,
    v_result,
    pg_catalog.jsonb_build_object(
      'slot', v_item.equip_slot,
      'category', v_item.category,
      'subtype', v_item.subtype,
      'rarity', v_item.rarity,
      'catalogVersion', v_item.catalog_version
    )
  );

  return v_result;
end;
$$;

revoke all on function public.equip_shop_cosmetic(text, text, uuid)
  from public, anon;

grant execute on function public.equip_shop_cosmetic(text, text, uuid)
  to authenticated;

commit;