-- Shop bundle catalog verification.
-- Run this after applying the shop bundle catalog migration and seed.

select
  to_regclass('public.shop_bundles') as shop_bundles,
  to_regclass('public.shop_bundle_items') as shop_bundle_items,
  to_regclass('public.user_owned_bundles') as user_owned_bundles,
  to_regclass('public.shop_bundle_ledger') as shop_bundle_ledger,
  to_regprocedure('public.purchase_shop_bundle(text, text, uuid)') as purchase_shop_bundle;

select
  c.relname as table_name,
  c.relrowsecurity as rls_enabled,
  c.relforcerowsecurity as force_rls
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname in (
    'shop_bundles',
    'shop_bundle_items',
    'user_owned_bundles',
    'shop_bundle_ledger'
  )
order by c.relname;

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
    'shop_bundles',
    'user_owned_bundles'
  )
order by tablename, policyname;

select
  p.proname as function_name,
  p.prosecdef as is_security_definer,
  p.proconfig as function_config
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname = 'purchase_shop_bundle'
order by p.proname;

select
  'bundle_counts' as check_name,
  count(*) as total_bundles,
  count(*) filter (where is_active) as active_bundles,
  count(*) filter (where not is_active) as inactive_bundles
from public.shop_bundles;

select
  'bundle_item_counts' as check_name,
  count(*) as total_rows,
  count(*) filter (where slot = 'screen_background') as wallpaper_rows,
  count(*) filter (where slot = 'habit_card_background') as habit_card_rows,
  count(*) filter (where slot = 'user_card_background') as user_card_rows
from public.shop_bundle_items;

select
  'invalid_bundle_shapes' as check_name,
  bundle_id,
  count(*) as item_rows,
  count(distinct slot) as distinct_slots
from public.shop_bundle_items
group by bundle_id
having count(*) <> 3 or count(distinct slot) <> 3
order by bundle_id;

select
  'duplicate_bundle_items' as check_name,
  bundle_id,
  item_id,
  count(*) as occurrences
from public.shop_bundle_items
group by bundle_id, item_id
having count(*) > 1
order by bundle_id, item_id;

select
  'missing_or_inactive_items' as check_name,
  bi.bundle_id,
  bi.slot,
  bi.item_id,
  si.id as shop_item_id,
  si.is_active
from public.shop_bundle_items bi
left join public.shop_items si on si.id = bi.item_id
where si.id is null or si.is_active is distinct from true
order by bi.bundle_id, bi.slot;

select
  'grant_checks' as check_name,
  has_table_privilege('authenticated', 'public.shop_bundles', 'SELECT') as auth_can_read_bundles,
  has_table_privilege('authenticated', 'public.user_owned_bundles', 'SELECT') as auth_can_read_owned_bundles,
  has_function_privilege('authenticated', 'public.purchase_shop_bundle(text, text, uuid)', 'EXECUTE') as auth_can_execute_rpc;
