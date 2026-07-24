begin;

create or replace function public.purchase_shop_bundle(
  p_request_id text,
  p_bundle_id text,
  p_user_id uuid default null
)
returns table (
  request_id text,
  bundle_id text,
  user_id uuid,
  coins_delta bigint,
  wallet_coins_after bigint,
  wallpaper_item_id text,
  habit_card_item_id text,
  user_card_item_id text,
  is_idempotent boolean,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := coalesce(p_user_id, auth.uid());
  v_existing_ledger public.shop_bundle_ledger%rowtype;
  v_bundle public.shop_bundles%rowtype;
  v_wallet_coins bigint;
  v_wallet_coins_after bigint;
  v_bundle_item_count integer;
  v_distinct_slot_count integer;
  v_wallpaper_item_id text;
  v_habit_card_item_id text;
  v_user_card_item_id text;
  v_owned_bundle boolean;
  v_owned_item_count integer := 0;
  v_missing_item_count integer := 0;
  v_missing_retail_price bigint := 0;
  v_effective_price bigint := 0;
  v_ledger public.shop_bundle_ledger%rowtype;
begin
  if p_request_id is null or btrim(p_request_id) = '' then
    raise exception 'request_id is required';
  end if;

  if p_bundle_id is null or btrim(p_bundle_id) = '' then
    raise exception 'bundle_id is required';
  end if;

  if v_user_id is null then
    raise exception 'user_id is required';
  end if;

  if auth.uid() is not null and auth.uid() <> v_user_id then
    raise exception 'authenticated user does not match requested user';
  end if;

  perform pg_advisory_xact_lock(hashtext(v_user_id::text));
  perform pg_advisory_xact_lock(hashtext('shop_bundle_request:' || p_request_id));

  select ledger.*
    into v_existing_ledger
  from public.shop_bundle_ledger as ledger
  where ledger.request_id = p_request_id;

  if found then
    if v_existing_ledger.user_id <> v_user_id
       or v_existing_ledger.bundle_id <> p_bundle_id then
      raise exception 'request_id already used by another user';
    end if;

    request_id := v_existing_ledger.request_id;
    bundle_id := v_existing_ledger.bundle_id;
    user_id := v_existing_ledger.user_id;
    coins_delta := v_existing_ledger.coins_delta;
    wallet_coins_after := v_existing_ledger.wallet_coins_after;
    wallpaper_item_id := v_existing_ledger.wallpaper_item_id;
    habit_card_item_id := v_existing_ledger.habit_card_item_id;
    user_card_item_id := v_existing_ledger.user_card_item_id;
    is_idempotent := true;
    created_at := v_existing_ledger.created_at;
    return next;
    return;
  end if;

  select bundle.*
    into v_bundle
  from public.shop_bundles as bundle
  where bundle.id = p_bundle_id
    and bundle.is_active = true;

  if not found then
    raise exception 'bundle not found or inactive';
  end if;

  select
    count(*),
    count(distinct bundle_item.slot),
    max(bundle_item.item_id) filter (where bundle_item.slot = 'screen_background'),
    max(bundle_item.item_id) filter (where bundle_item.slot = 'habit_card_background'),
    max(bundle_item.item_id) filter (where bundle_item.slot = 'user_card_background')
  into
    v_bundle_item_count,
    v_distinct_slot_count,
    v_wallpaper_item_id,
    v_habit_card_item_id,
    v_user_card_item_id
  from public.shop_bundle_items as bundle_item
  where bundle_item.bundle_id = p_bundle_id;

  if v_bundle_item_count <> 3
     or v_distinct_slot_count <> 3
     or v_wallpaper_item_id is null
     or v_habit_card_item_id is null
     or v_user_card_item_id is null then
    raise exception 'bundle configuration invalid';
  end if;

  select count(*)
    into v_owned_item_count
  from public.shop_items as shop_item
  where shop_item.id in (
    v_wallpaper_item_id,
    v_habit_card_item_id,
    v_user_card_item_id
  )
    and shop_item.is_active = true;

  if v_owned_item_count <> 3 then
    raise exception 'bundle configuration invalid';
  end if;

  select wallet.coins
    into v_wallet_coins
  from public.user_wallets as wallet
  where wallet.user_id = v_user_id
  for update;

  if not found then
    raise exception 'wallet not found for user';
  end if;

  select exists (
    select 1
    from public.user_owned_bundles as owned_bundle
    where owned_bundle.user_id = v_user_id
      and owned_bundle.bundle_id = p_bundle_id
  ) into v_owned_bundle;

  if v_owned_bundle then
    raise exception 'bundle already owned';
  end if;

  select
    count(*) filter (where inventory.item_id is not null),
    count(*) filter (where inventory.item_id is null),
    coalesce(
      sum(
        case
          when inventory.item_id is null then shop_item.price_coins
          else 0
        end
      ),
      0
    )
  into
    v_owned_item_count,
    v_missing_item_count,
    v_missing_retail_price
  from (
    values
      (v_wallpaper_item_id),
      (v_habit_card_item_id),
      (v_user_card_item_id)
  ) as bundle_item(item_id)
  join public.shop_items as shop_item
    on shop_item.id = bundle_item.item_id
   and shop_item.is_active = true
  left join public.user_inventory as inventory
    on inventory.user_id = v_user_id
   and inventory.item_id = bundle_item.item_id;

  if v_missing_item_count = 0 then
    v_effective_price := 0;
  elsif v_missing_item_count = 3 then
    v_effective_price := v_bundle.price_coins;
  elsif v_bundle.original_price_coins <= 0 then
    v_effective_price := v_missing_retail_price;
  else
    v_effective_price := ceil(
      v_missing_retail_price::numeric
      * v_bundle.price_coins::numeric
      / v_bundle.original_price_coins::numeric
    )::bigint;
  end if;

  if v_effective_price < 0 then
    v_effective_price := 0;
  end if;

  if v_effective_price > v_missing_retail_price then
    v_effective_price := v_missing_retail_price;
  end if;

  if v_wallet_coins < v_effective_price then
    raise exception 'insufficient wallet balance';
  end if;

  insert into public.user_inventory (
    user_id,
    item_id,
    quantity,
    acquisition_source,
    acquired_at,
    updated_at
  )
  select
    v_user_id,
    bundle_item.item_id,
    1,
    'purchase',
    now(),
    now()
  from (
    values
      (v_wallpaper_item_id),
      (v_habit_card_item_id),
      (v_user_card_item_id)
  ) as bundle_item(item_id)
  where not exists (
    select 1
    from public.user_inventory as inventory
    where inventory.user_id = v_user_id
      and inventory.item_id = bundle_item.item_id
  )
  on conflict on constraint user_inventory_user_item_unique do nothing;

  insert into public.user_owned_bundles (
    user_id,
    bundle_id,
    acquisition_source,
    acquired_at,
    updated_at
  ) values (
    v_user_id,
    p_bundle_id,
    'purchase',
    now(),
    now()
  );

  if v_effective_price > 0 then
    update public.user_wallets as wallet
       set coins = wallet.coins - v_effective_price,
           version = wallet.version + 1
     where wallet.user_id = v_user_id
     returning wallet.coins into v_wallet_coins_after;
  else
    v_wallet_coins_after := v_wallet_coins;
  end if;

  insert into public.shop_bundle_ledger (
    request_id,
    user_id,
    bundle_id,
    wallpaper_item_id,
    habit_card_item_id,
    user_card_item_id,
    coins_delta,
    wallet_coins_after,
    created_at
  ) values (
    p_request_id,
    v_user_id,
    p_bundle_id,
    v_wallpaper_item_id,
    v_habit_card_item_id,
    v_user_card_item_id,
    -v_effective_price,
    v_wallet_coins_after,
    now()
  )
  returning * into v_ledger;

  request_id := v_ledger.request_id;
  bundle_id := v_ledger.bundle_id;
  user_id := v_ledger.user_id;
  coins_delta := v_ledger.coins_delta;
  wallet_coins_after := v_ledger.wallet_coins_after;
  wallpaper_item_id := v_ledger.wallpaper_item_id;
  habit_card_item_id := v_ledger.habit_card_item_id;
  user_card_item_id := v_ledger.user_card_item_id;
  is_idempotent := false;
  created_at := v_ledger.created_at;
  return next;
  return;
end;
$$;

revoke all on function public.purchase_shop_bundle(text, text, uuid) from public, anon, authenticated;
grant execute on function public.purchase_shop_bundle(text, text, uuid) to authenticated;

commit;
