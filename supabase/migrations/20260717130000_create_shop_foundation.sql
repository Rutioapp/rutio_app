begin;

create extension if not exists pgcrypto;

create schema if not exists app_private;

revoke all on schema app_private from public;

create or replace function app_private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.shop_items (
  id text primary key,
  category text not null,
  subtype text not null,
  rarity text,
  price_coins integer not null,
  is_consumable boolean not null default false,
  is_stackable boolean not null default false,
  max_quantity integer,
  equip_slot text,
  asset_key text not null,
  localization_key text not null,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  catalog_version integer not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint shop_items_category_check
    check (category in (
      'screen_background',
      'habit_card_background',
      'user_card_background',
      'utility'
    )),
  constraint shop_items_price_coins_check
    check (price_coins >= 0),
  constraint shop_items_sort_order_check
    check (sort_order >= 0),
  constraint shop_items_catalog_version_check
    check (catalog_version >= 1),
  constraint shop_items_max_quantity_check
    check (max_quantity is null or max_quantity > 0),
  constraint shop_items_role_integrity_check
    check (
    (
      category = 'utility'
      and is_consumable = true
      and is_stackable = true
      and rarity is null
      and equip_slot is null
      and max_quantity is null
    )
      or
      (
        category <> 'utility'
        and is_consumable = false
        and is_stackable = false
        and max_quantity = 1
        and rarity in ('common', 'rare', 'epic', 'legendary')
        and equip_slot = category
      )
    ),
  constraint shop_items_id_equip_slot_unique unique (id, equip_slot)
);

create table if not exists public.user_wallets (
  user_id uuid primary key references auth.users(id) on delete cascade,
  coins bigint not null default 0,
  version bigint not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint user_wallets_coins_check check (coins >= 0),
  constraint user_wallets_version_check check (version >= 0)
);

create table if not exists public.user_inventory (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  item_id text not null references public.shop_items(id),
  quantity integer not null,
  acquisition_source text not null,
  acquired_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint user_inventory_quantity_check check (quantity > 0),
  constraint user_inventory_source_check check (
    acquisition_source in ('purchase', 'migration', 'reward', 'admin', 'starter')
  ),
  constraint user_inventory_user_item_unique unique (user_id, item_id)
);

create table if not exists public.user_equipped_cosmetics (
  user_id uuid not null references auth.users(id) on delete cascade,
  slot text not null,
  item_id text not null,
  equipped_at timestamptz not null default now(),
  constraint user_equipped_cosmetics_pkey primary key (user_id, slot),
  constraint user_equipped_cosmetics_slot_check check (
    slot in (
      'screen_background',
      'habit_card_background',
      'user_card_background'
    )
  ),
  constraint user_equipped_cosmetics_item_slot_fkey
    foreign key (item_id, slot)
    references public.shop_items (id, equip_slot)
    on update cascade
    on delete restrict
);

create index if not exists idx_shop_items_active_category_sort_order
  on public.shop_items (category, sort_order)
  where is_active;

create index if not exists idx_shop_items_active_rarity_sort_order
  on public.shop_items (rarity, sort_order)
  where is_active and rarity is not null;

create index if not exists idx_user_inventory_item_id
  on public.user_inventory (item_id);

create index if not exists idx_user_equipped_cosmetics_item_id
  on public.user_equipped_cosmetics (item_id);

drop trigger if exists trg_shop_items_set_updated_at on public.shop_items;
create trigger trg_shop_items_set_updated_at
before update on public.shop_items
for each row
execute function app_private.set_updated_at();

drop trigger if exists trg_user_wallets_set_updated_at on public.user_wallets;
create trigger trg_user_wallets_set_updated_at
before update on public.user_wallets
for each row
execute function app_private.set_updated_at();

drop trigger if exists trg_user_inventory_set_updated_at on public.user_inventory;
create trigger trg_user_inventory_set_updated_at
before update on public.user_inventory
for each row
execute function app_private.set_updated_at();

alter table public.shop_items enable row level security;
alter table public.user_wallets enable row level security;
alter table public.user_inventory enable row level security;
alter table public.user_equipped_cosmetics enable row level security;

drop policy if exists shop_items_select_active on public.shop_items;
create policy shop_items_select_active
  on public.shop_items
  for select
  to authenticated
  using (is_active);

drop policy if exists user_wallets_select_own on public.user_wallets;
create policy user_wallets_select_own
  on public.user_wallets
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists user_inventory_select_own on public.user_inventory;
create policy user_inventory_select_own
  on public.user_inventory
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists user_equipped_cosmetics_select_own on public.user_equipped_cosmetics;
create policy user_equipped_cosmetics_select_own
  on public.user_equipped_cosmetics
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

revoke all on public.shop_items from anon, authenticated;
revoke all on public.user_wallets from anon, authenticated;
revoke all on public.user_inventory from anon, authenticated;
revoke all on public.user_equipped_cosmetics from anon, authenticated;

grant select on public.shop_items to authenticated;
grant select on public.user_wallets to authenticated;
grant select on public.user_inventory to authenticated;
grant select on public.user_equipped_cosmetics to authenticated;

commit;
