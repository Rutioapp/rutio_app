begin;

create extension if not exists pgcrypto;
create schema if not exists app_private;

create table if not exists public.mystery_box_reward_catalog (
  catalog_version integer not null,
  reward_id text not null,
  reward_type text not null,
  quantity integer not null,
  weight integer not null,
  rarity text,
  is_active boolean not null default true,
  max_quantity integer,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint mystery_box_reward_catalog_pkey primary key (catalog_version, reward_id),
  constraint mystery_box_reward_catalog_reward_id_check check (btrim(reward_id) <> ''),
  constraint mystery_box_reward_catalog_reward_type_check check (
    reward_type in ('coins', 'xp', 'utility', 'cosmetic')
  ),
  constraint mystery_box_reward_catalog_quantity_check check (quantity >= 0),
  constraint mystery_box_reward_catalog_weight_check check (weight > 0),
  constraint mystery_box_reward_catalog_max_quantity_check check (
    max_quantity is null or max_quantity > 0
  )
);

create index if not exists idx_mystery_box_reward_catalog_version_active
  on public.mystery_box_reward_catalog (catalog_version desc, is_active);
create index if not exists idx_mystery_box_reward_catalog_type_active
  on public.mystery_box_reward_catalog (reward_type, is_active);

create table if not exists public.mystery_box_opening_ledger (
  id uuid primary key default gen_random_uuid(),
  request_id text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  operation_type text not null,
  source_type text not null,
  source_id text not null,
  catalog_version integer not null,
  reward_id text not null,
  reward_type text not null,
  reward_quantity integer not null,
  reward_weight integer not null,
  reward_rarity text,
  reward_is_active boolean not null,
  reward_max_quantity integer,
  coin_delta bigint not null default 0,
  xp_delta integer not null default 0,
  utility_item_id text,
  utility_quantity integer not null default 0,
  wallet_version bigint not null,
  balance_after bigint not null,
  remaining_boxes integer not null,
  related_ledger_id uuid references public.mystery_box_opening_ledger(id) on delete set null,
  is_idempotent boolean not null default false,
  created_at timestamptz not null default now(),
  constraint mystery_box_opening_ledger_request_id_check check (btrim(request_id) <> ''),
  constraint mystery_box_opening_ledger_operation_type_check check (operation_type = 'open'),
  constraint mystery_box_opening_ledger_source_type_check check (source_type = 'mystery_box'),
  constraint mystery_box_opening_ledger_source_id_check check (btrim(source_id) <> ''),
  constraint mystery_box_opening_ledger_reward_id_check check (btrim(reward_id) <> ''),
  constraint mystery_box_opening_ledger_reward_type_check check (
    reward_type in ('coins', 'xp', 'utility', 'cosmetic')
  ),
  constraint mystery_box_opening_ledger_reward_quantity_check check (reward_quantity >= 0),
  constraint mystery_box_opening_ledger_reward_weight_check check (reward_weight > 0),
  constraint mystery_box_opening_ledger_wallet_version_check check (wallet_version >= 0),
  constraint mystery_box_opening_ledger_balance_after_check check (balance_after >= 0),
  constraint mystery_box_opening_ledger_remaining_boxes_check check (remaining_boxes >= 0),
  constraint mystery_box_opening_ledger_request_id_unique unique (request_id)
);

create index if not exists idx_mystery_box_opening_ledger_user_created_at
  on public.mystery_box_opening_ledger (user_id, created_at desc);
create index if not exists idx_mystery_box_opening_ledger_user_request_id
  on public.mystery_box_opening_ledger (user_id, request_id);
create index if not exists idx_mystery_box_opening_ledger_user_source
  on public.mystery_box_opening_ledger (user_id, operation_type, source_type, source_id);

alter table public.mystery_box_reward_catalog enable row level security;
alter table public.mystery_box_opening_ledger enable row level security;

revoke all on public.mystery_box_reward_catalog from public, anon, authenticated;
revoke all on public.mystery_box_opening_ledger from public, anon, authenticated;

drop policy if exists mystery_box_reward_catalog_select_authenticated
  on public.mystery_box_reward_catalog;
create policy mystery_box_reward_catalog_select_authenticated
  on public.mystery_box_reward_catalog
  for select
  to authenticated
  using (true);

drop policy if exists mystery_box_opening_ledger_select_own
  on public.mystery_box_opening_ledger;
create policy mystery_box_opening_ledger_select_own
  on public.mystery_box_opening_ledger
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

grant select on public.mystery_box_reward_catalog to authenticated;
grant select on public.mystery_box_opening_ledger to authenticated;

insert into public.mystery_box_reward_catalog (
  catalog_version,
  reward_id,
  reward_type,
  quantity,
  weight,
  rarity,
  is_active,
  max_quantity
) values
  (1, 'reward_80_coins_40_xp', 'coins', 80, 40, 'common', true, null),
  (1, 'reward_100_coins_50_xp', 'coins', 100, 25, 'common', true, null),
  (1, 'reward_125_coins', 'coins', 125, 15, 'uncommon', true, null),
  (1, 'reward_150_coins', 'coins', 150, 5, 'rare', true, null),
  (1, 'reward_xp_boost_30_coins', 'utility', 1, 5, 'rare', true, 10),
  (1, 'reward_coin_boost_30_coins', 'utility', 1, 4, 'rare', true, 10),
  (1, 'reward_streak_shield_40_coins', 'utility', 1, 3, 'epic', true, 1),
  (1, 'reward_streak_recover_50_coins', 'utility', 1, 3, 'epic', true, 1)
on conflict (catalog_version, reward_id) do update
  set reward_type = excluded.reward_type,
      quantity = excluded.quantity,
      weight = excluded.weight,
      rarity = excluded.rarity,
      is_active = excluded.is_active,
      max_quantity = excluded.max_quantity,
      updated_at = now();

create or replace function app_private.mystery_box_opening_payload(
  p_ledger public.mystery_box_opening_ledger
)
returns jsonb
language sql
stable
set search_path = ''
as $$
  select jsonb_build_object(
    'requestId', p_ledger.request_id,
    'operation', p_ledger.operation_type,
    'userId', p_ledger.user_id::text,
    'mysteryBoxUtilityId', p_ledger.source_id,
    'reward', jsonb_build_object(
      'rewardId', p_ledger.reward_id,
      'rewardType', p_ledger.reward_type,
      'quantity', p_ledger.reward_quantity,
      'weight', p_ledger.reward_weight,
      'rarity', p_ledger.reward_rarity,
      'isActive', p_ledger.reward_is_active,
      'catalogVersion', p_ledger.catalog_version,
      'coins', p_ledger.coin_delta,
      'xp', p_ledger.xp_delta,
      'utilityRewards',
        case
          when p_ledger.utility_item_id is null then '{}'::jsonb
          else jsonb_build_object(p_ledger.utility_item_id, p_ledger.utility_quantity)
        end,
      'maxQuantity', p_ledger.reward_max_quantity
    ),
    'createdAt', p_ledger.created_at,
    'balanceAfter', p_ledger.balance_after,
    'walletVersion', p_ledger.wallet_version,
    'remainingBoxes', p_ledger.remaining_boxes,
    'ledgerId', p_ledger.id::text,
    'isIdempotent', p_ledger.is_idempotent
  );
$$;

create or replace function public.open_mystery_box(
  p_request_id text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_request_id text := btrim(coalesce(p_request_id, ''));
  v_existing public.mystery_box_opening_ledger%rowtype;
  v_box_item public.user_inventory%rowtype;
  v_catalog_version integer;
  v_reward record;
  v_selected public.mystery_box_reward_catalog%rowtype;
  v_total_weight integer := 0;
  v_roll integer;
  v_cumulative integer := 0;
  v_reward_item public.shop_items%rowtype;
  v_existing_reward_quantity integer := 0;
  v_wallet public.user_wallets%rowtype;
  v_coin_delta bigint := 0;
  v_xp_delta integer := 0;
  v_utility_item_id text := null;
  v_utility_quantity integer := 0;
  v_wallet_version bigint;
  v_remaining_boxes integer;
  v_ledger public.mystery_box_opening_ledger%rowtype;
begin
  if v_request_id = '' then
    raise exception 'request_id is required';
  end if;
  if v_user_id is null then
    raise exception 'authentication required';
  end if;

  perform pg_advisory_xact_lock(hashtext(v_user_id::text));
  perform pg_advisory_xact_lock(hashtext('mystery_box_request:' || v_request_id));

  select *
    into v_existing
  from public.mystery_box_opening_ledger
  where request_id = v_request_id;

  if found then
    if v_existing.user_id <> v_user_id
       or v_existing.operation_type <> 'open'
       or v_existing.source_type <> 'mystery_box' then
      raise exception 'request_id already used by another mystery box open';
    end if;

    update public.mystery_box_opening_ledger
       set is_idempotent = true
     where id = v_existing.id
       and is_idempotent = false;

    select *
      into v_existing
    from public.mystery_box_opening_ledger
    where id = v_existing.id;

    return app_private.mystery_box_opening_payload(v_existing);
  end if;

  select *
    into v_box_item
  from public.user_inventory
  where user_id = v_user_id
    and item_id = 'utility_mystery_box_basic'
  for update;

  if not found or v_box_item.quantity <= 0 then
    raise exception 'no mystery box inventory available';
  end if;

  select max(catalog_version)
    into v_catalog_version
  from public.mystery_box_reward_catalog
  where is_active = true;

  if v_catalog_version is null then
    raise exception 'mystery box reward catalog is empty';
  end if;

  for v_reward in
    select *
    from public.mystery_box_reward_catalog
    where is_active = true
      and catalog_version = v_catalog_version
    order by reward_id
  loop
    if v_reward.reward_type in ('utility', 'cosmetic')
       and v_reward.max_quantity is not null then
      select quantity
        into v_existing_reward_quantity
      from public.user_inventory
      where user_id = v_user_id
        and item_id = v_reward.reward_id
      for update;

      if coalesce(v_existing_reward_quantity, 0) + v_reward.quantity > v_reward.max_quantity then
        continue;
      end if;
    end if;

    v_total_weight := v_total_weight + v_reward.weight;
  end loop;

  if v_total_weight <= 0 then
    raise exception 'no eligible mystery box rewards available';
  end if;

  v_roll := floor(random() * v_total_weight)::integer + 1;

  for v_reward in
    select *
    from public.mystery_box_reward_catalog
    where is_active = true
      and catalog_version = v_catalog_version
    order by reward_id
  loop
    if v_reward.reward_type in ('utility', 'cosmetic')
       and v_reward.max_quantity is not null then
      select quantity
        into v_existing_reward_quantity
      from public.user_inventory
      where user_id = v_user_id
        and item_id = v_reward.reward_id
      for update;

      if coalesce(v_existing_reward_quantity, 0) + v_reward.quantity > v_reward.max_quantity then
        continue;
      end if;
    end if;

    v_cumulative := v_cumulative + v_reward.weight;
    if v_roll <= v_cumulative then
      v_selected := v_reward;
      exit;
    end if;
  end loop;

  if v_selected.reward_id is null then
    raise exception 'failed to select a mystery box reward';
  end if;

  if v_selected.reward_type in ('utility', 'cosmetic') then
    select *
      into v_reward_item
    from public.shop_items
    where id = v_selected.reward_id
      and is_active = true
      and category in ('utility', 'cosmetic');

    if not found then
      raise exception 'reward item is not eligible';
    end if;

    v_utility_item_id := v_reward_item.id;
    v_utility_quantity := v_selected.quantity;

    select quantity
      into v_existing_reward_quantity
    from public.user_inventory
    where user_id = v_user_id
      and item_id = v_reward_item.id
    for update;

    if v_selected.max_quantity is not null
       and coalesce(v_existing_reward_quantity, 0) + v_selected.quantity > v_selected.max_quantity then
      raise exception 'reward quantity limit reached';
    end if;
  end if;

  select *
    into v_wallet
  from public.user_wallets
  where user_id = v_user_id
  for update;

  if not found then
    raise exception 'wallet missing for user';
  end if;

  if v_selected.reward_type = 'coins' then
    v_coin_delta := v_selected.quantity::bigint;
  elsif v_selected.reward_type = 'xp' then
    v_xp_delta := v_selected.quantity;
  end if;

  v_wallet_version := v_wallet.version + case when v_coin_delta <> 0 then 1 else 0 end;
  v_remaining_boxes := v_box_item.quantity - 1;

  if v_coin_delta <> 0 then
    if v_wallet.coins + v_coin_delta < 0 then
      raise exception 'wallet would go negative';
    end if;

    update public.user_wallets
       set coins = coins + v_coin_delta,
           version = version + 1
     where user_id = v_user_id;
  end if;

  if v_selected.reward_type in ('utility', 'cosmetic') then
    insert into public.user_inventory (
      user_id,
      item_id,
      quantity,
      acquisition_source,
      acquired_at,
      updated_at
    ) values (
      v_user_id,
      v_utility_item_id,
      v_utility_quantity,
      'reward',
      now(),
      now()
    )
    on conflict (user_id, item_id) do update
      set quantity = public.user_inventory.quantity + excluded.quantity,
          acquisition_source = excluded.acquisition_source,
          updated_at = excluded.updated_at;
  end if;

  if v_remaining_boxes > 0 then
    update public.user_inventory
       set quantity = v_remaining_boxes,
           acquisition_source = 'reward',
           updated_at = now()
     where user_id = v_user_id
       and item_id = 'utility_mystery_box_basic';
  else
    delete from public.user_inventory
    where user_id = v_user_id
      and item_id = 'utility_mystery_box_basic';
  end if;

  insert into public.mystery_box_opening_ledger (
    request_id,
    user_id,
    operation_type,
    source_type,
    source_id,
    catalog_version,
    reward_id,
    reward_type,
    reward_quantity,
    reward_weight,
    reward_rarity,
    reward_is_active,
    reward_max_quantity,
    coin_delta,
    xp_delta,
    utility_item_id,
    utility_quantity,
    wallet_version,
    balance_after,
    remaining_boxes,
    is_idempotent,
    created_at
  ) values (
    v_request_id,
    v_user_id,
    'open',
    'mystery_box',
    'utility_mystery_box_basic',
    v_catalog_version,
    v_selected.reward_id,
    v_selected.reward_type,
    v_selected.quantity,
    v_selected.weight,
    v_selected.rarity,
    v_selected.is_active,
    v_selected.max_quantity,
    v_coin_delta,
    v_xp_delta,
    v_utility_item_id,
    v_utility_quantity,
    v_wallet_version,
    v_wallet.coins + v_coin_delta,
    v_remaining_boxes,
    false,
    now()
  )
  returning * into v_ledger;

  return app_private.mystery_box_opening_payload(v_ledger);
end;
$$;

revoke all on function public.open_mystery_box(text) from public, anon, authenticated;
grant execute on function public.open_mystery_box(text) to authenticated;

commit;
