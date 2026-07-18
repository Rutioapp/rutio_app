-- Shop foundation verification script.
-- Safe to run after the migration and seed are applied.
-- This file does not mutate production data.

-- 1) Table existence.
select
  to_regclass('public.shop_items') as shop_items,
  to_regclass('public.user_wallets') as user_wallets,
  to_regclass('public.user_inventory') as user_inventory,
  to_regclass('public.user_equipped_cosmetics') as user_equipped_cosmetics;

-- 2) Table + constraint inventory.
select
  c.relname as table_name,
  con.conname as constraint_name,
  con.contype as constraint_type,
  pg_get_constraintdef(con.oid) as definition
from pg_constraint con
join pg_class c on c.oid = con.conrelid
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname in (
    'shop_items',
    'user_wallets',
    'user_inventory',
    'user_equipped_cosmetics'
  )
order by c.relname, con.conname;

-- 3) RLS status.
select
  c.relname as table_name,
  c.relrowsecurity as rls_enabled,
  c.relforcerowsecurity as force_rls
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname in (
    'shop_items',
    'user_wallets',
    'user_inventory',
    'user_equipped_cosmetics'
  )
order by c.relname;

-- 4) Policies.
select
  schemaname,
  tablename,
  policyname,
  cmd,
  roles,
  qual,
  with_check
from pg_policies
where schemaname = 'public'
  and tablename in (
    'shop_items',
    'user_wallets',
    'user_inventory',
    'user_equipped_cosmetics'
  )
order by tablename, policyname;

-- 5) Indexes.
select
  schemaname,
  tablename,
  indexname,
  indexdef
from pg_indexes
where schemaname = 'public'
  and indexname in (
    'shop_items_pkey',
    'shop_items_id_equip_slot_unique',
    'idx_shop_items_active_category_sort_order',
    'idx_shop_items_active_rarity_sort_order',
    'user_wallets_pkey',
    'user_inventory_pkey',
    'user_inventory_user_item_unique',
    'idx_user_inventory_item_id',
    'user_equipped_cosmetics_pkey',
    'idx_user_equipped_cosmetics_item_id'
  )
order by tablename, indexname;

-- 6) Manual authenticated smoke tests.
-- Replace the UUID placeholders with real auth.users.id values.
-- Run the block inside a single transaction and roll it back at the end.
--
-- begin;
-- set local role authenticated;
-- set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';
--
-- -- Catalog reads: active rows should be visible, inactive rows should not.
-- select count(*) as active_shop_items
-- from public.shop_items
-- where is_active = true;
--
-- select count(*) as inactive_shop_items
-- from public.shop_items
-- where is_active = false;
--
-- -- Ownership reads: each query should only return rows for the active user.
-- select * from public.user_wallets where user_id = '00000000-0000-0000-0000-000000000001';
-- select * from public.user_inventory where user_id = '00000000-0000-0000-0000-000000000001';
-- select * from public.user_equipped_cosmetics where user_id = '00000000-0000-0000-0000-000000000001';
--
-- -- Negative checks: should return zero rows for a different user.
-- select * from public.user_wallets where user_id = '00000000-0000-0000-0000-000000000002';
-- select * from public.user_inventory where user_id = '00000000-0000-0000-0000-000000000002';
-- select * from public.user_equipped_cosmetics where user_id = '00000000-0000-0000-0000-000000000002';
--
-- -- Write attempts: these should fail because no write privileges/policies exist.
-- -- insert into public.user_wallets (user_id, coins, version, created_at, updated_at)
-- -- values ('00000000-0000-0000-0000-000000000001', 10, 0, now(), now());
-- -- insert into public.user_inventory (user_id, item_id, quantity, acquisition_source, acquired_at, updated_at)
-- -- values ('00000000-0000-0000-0000-000000000001', 'utility_xp_boost_1d', 1, 'starter', now(), now());
--
-- rollback;

