begin;

create extension if not exists pgcrypto;
create schema if not exists app_private;

revoke all on schema app_private from public;

create table if not exists public.shop_bundles (
  id text primary key,
  family_id text not null,
  rarity text not null,
  price_coins integer not null,
  original_price_coins integer not null,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  catalog_version integer not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint shop_bundles_rarity_check check (
    rarity in ('common', 'rare', 'epic', 'legendary')
  ),
  constraint shop_bundles_price_coins_check check (price_coins >= 0),
  constraint shop_bundles_original_price_check check (
    original_price_coins >= price_coins
  ),
  constraint shop_bundles_sort_order_check check (sort_order >= 0),
  constraint shop_bundles_catalog_version_check check (catalog_version >= 1)
);

create table if not exists public.shop_bundle_items (
  bundle_id text not null references public.shop_bundles(id) on delete cascade,
  item_id text not null,
  slot text not null,
  created_at timestamptz not null default now(),
  constraint shop_bundle_items_pkey primary key (bundle_id, item_id),
  constraint shop_bundle_items_bundle_slot_unique unique (bundle_id, slot),
  constraint shop_bundle_items_slot_check check (
    slot in (
      'screen_background',
      'habit_card_background',
      'user_card_background'
    )
  ),
  constraint shop_bundle_items_item_slot_fkey
    foreign key (item_id, slot)
    references public.shop_items (id, equip_slot)
    on update cascade
    on delete restrict
);

create table if not exists public.user_owned_bundles (
  user_id uuid not null references auth.users(id) on delete cascade,
  bundle_id text not null references public.shop_bundles(id) on delete restrict,
  acquisition_source text not null,
  acquired_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint user_owned_bundles_pkey primary key (user_id, bundle_id),
  constraint user_owned_bundles_source_check check (
    acquisition_source in ('purchase', 'migration', 'reward', 'admin', 'starter')
  )
);

create table if not exists public.shop_bundle_ledger (
  id uuid primary key default gen_random_uuid(),
  request_id text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  bundle_id text not null references public.shop_bundles(id) on delete restrict,
  wallpaper_item_id text not null,
  habit_card_item_id text not null,
  user_card_item_id text not null,
  coins_delta bigint not null,
  wallet_coins_after bigint not null,
  created_at timestamptz not null default now(),
  constraint shop_bundle_ledger_request_id_nonempty check (btrim(request_id) <> ''),
  constraint shop_bundle_ledger_request_id_unique unique (request_id),
  constraint shop_bundle_ledger_coins_delta_check check (coins_delta <= 0),
  constraint shop_bundle_ledger_wallet_coins_after_check check (wallet_coins_after >= 0)
);

create index if not exists idx_shop_bundles_active_sort_order
  on public.shop_bundles (sort_order)
  where is_active;

create index if not exists idx_shop_bundle_items_bundle_id
  on public.shop_bundle_items (bundle_id);

create index if not exists idx_shop_bundle_items_item_id
  on public.shop_bundle_items (item_id);

create index if not exists idx_user_owned_bundles_bundle_id
  on public.user_owned_bundles (bundle_id);

create index if not exists idx_user_owned_bundles_user_created_at
  on public.user_owned_bundles (user_id, acquired_at desc);

create index if not exists idx_shop_bundle_ledger_user_created_at
  on public.shop_bundle_ledger (user_id, created_at desc);

create index if not exists idx_shop_bundle_ledger_user_request_id
  on public.shop_bundle_ledger (user_id, request_id);

drop trigger if exists trg_shop_bundles_set_updated_at on public.shop_bundles;
create trigger trg_shop_bundles_set_updated_at
before update on public.shop_bundles
for each row
execute function app_private.set_updated_at();

drop trigger if exists trg_user_owned_bundles_set_updated_at on public.user_owned_bundles;
create trigger trg_user_owned_bundles_set_updated_at
before update on public.user_owned_bundles
for each row
execute function app_private.set_updated_at();

alter table public.shop_bundles enable row level security;
alter table public.shop_bundle_items enable row level security;
alter table public.user_owned_bundles enable row level security;
alter table public.shop_bundle_ledger enable row level security;

drop policy if exists shop_bundles_select_active on public.shop_bundles;
create policy shop_bundles_select_active
  on public.shop_bundles
  for select
  to authenticated
  using (is_active);

drop policy if exists user_owned_bundles_select_own on public.user_owned_bundles;
create policy user_owned_bundles_select_own
  on public.user_owned_bundles
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

revoke all on public.shop_bundles from public, anon, authenticated;
revoke all on public.shop_bundle_items from public, anon, authenticated;
revoke all on public.user_owned_bundles from public, anon, authenticated;
revoke all on public.shop_bundle_ledger from public, anon, authenticated;

grant select on public.shop_bundles to authenticated;
grant select on public.user_owned_bundles to authenticated;

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
  v_owned_item_count integer;
  v_active_item_count integer;
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

  select *
    into v_existing_ledger
  from public.shop_bundle_ledger
  where request_id = p_request_id;

  if found then
    if v_existing_ledger.user_id <> v_user_id then
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

  select *
    into v_bundle
  from public.shop_bundles
  where id = p_bundle_id
    and is_active = true;

  if not found then
    raise exception 'bundle not found or inactive';
  end if;

  select
    count(*),
    count(distinct slot),
    max(item_id) filter (where slot = 'screen_background'),
    max(item_id) filter (where slot = 'habit_card_background'),
    max(item_id) filter (where slot = 'user_card_background')
  into
    v_bundle_item_count,
    v_distinct_slot_count,
    v_wallpaper_item_id,
    v_habit_card_item_id,
    v_user_card_item_id
  from public.shop_bundle_items
  where bundle_id = p_bundle_id;

  if v_bundle_item_count <> 3
     or v_distinct_slot_count <> 3
     or v_wallpaper_item_id is null
     or v_habit_card_item_id is null
     or v_user_card_item_id is null then
    raise exception 'bundle configuration invalid';
  end if;

  select count(*)
    into v_active_item_count
  from public.shop_items
  where id in (
    v_wallpaper_item_id,
    v_habit_card_item_id,
    v_user_card_item_id
  )
    and is_active = true;

  if v_active_item_count <> 3 then
    raise exception 'bundle configuration invalid';
  end if;

  select coins
    into v_wallet_coins
  from public.user_wallets
  where user_id = v_user_id
  for update;

  if not found then
    raise exception 'wallet not found for user';
  end if;

  select exists (
    select 1
    from public.user_owned_bundles
    where user_id = v_user_id
      and bundle_id = p_bundle_id
  ) into v_owned_bundle;

  if v_owned_bundle then
    raise exception 'bundle already owned';
  end if;

  select count(*)
    into v_owned_item_count
  from public.user_inventory
  where user_id = v_user_id
    and item_id in (
      v_wallpaper_item_id,
      v_habit_card_item_id,
      v_user_card_item_id
    );

  if v_owned_item_count > 0 then
    raise exception 'bundle contains owned items';
  end if;

  if v_wallet_coins < v_bundle.price_coins then
    raise exception 'insufficient wallet balance';
  end if;

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

  insert into public.user_inventory (
    user_id,
    item_id,
    quantity,
    acquisition_source,
    acquired_at,
    updated_at
  ) values
    (
      v_user_id,
      v_wallpaper_item_id,
      1,
      'purchase',
      now(),
      now()
    ),
    (
      v_user_id,
      v_habit_card_item_id,
      1,
      'purchase',
      now(),
      now()
    ),
    (
      v_user_id,
      v_user_card_item_id,
      1,
      'purchase',
      now(),
      now()
    );

  update public.user_wallets
     set coins = coins - v_bundle.price_coins,
         version = version + 1
   where user_id = v_user_id
   returning coins into v_wallet_coins_after;

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
    -v_bundle.price_coins,
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
