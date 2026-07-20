-- Cloud economy rollout verification.
-- Safe local verification script for the final rollout phase.
-- Does not mutate production data.

-- 1) Core cloud-economy tables and rollout audit objects.
select
  to_regclass('public.user_wallets') as user_wallets,
  to_regclass('public.user_inventory') as user_inventory,
  to_regclass('public.user_equipped_cosmetics') as user_equipped_cosmetics,
  to_regclass('public.shop_ledger') as shop_ledger,
  to_regclass('public.habit_currency_reward_ledger') as habit_currency_reward_ledger,
  to_regclass('public.achievement_level_reward_ledger') as achievement_level_reward_ledger,
  to_regclass('public.mystery_box_opening_ledger') as mystery_box_opening_ledger,
  to_regclass('public.utility_consumption_ledger') as utility_consumption_ledger,
  to_regclass('public.global_cloud_economy_rollout_audit') as rollout_audit,
  to_regclass('public.global_cloud_economy_rollout_status') as rollout_status;

-- 2) RLS and grants for the rollout audit objects.
select
  c.relname as table_name,
  c.relrowsecurity as rls_enabled,
  c.relforcerowsecurity as force_rls
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname in (
    'user_wallets',
    'user_inventory',
    'user_equipped_cosmetics',
    'shop_ledger',
    'habit_currency_reward_ledger',
    'achievement_level_reward_ledger',
    'mystery_box_opening_ledger',
    'utility_consumption_ledger',
    'global_cloud_economy_rollout_audit'
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
    'user_wallets',
    'user_inventory',
    'user_equipped_cosmetics',
    'shop_ledger',
    'habit_currency_reward_ledger',
    'achievement_level_reward_ledger',
    'mystery_box_opening_ledger',
    'utility_consumption_ledger',
    'global_cloud_economy_rollout_audit'
  )
order by tablename, policyname;

-- 3) Search-path hardening for security-definer RPCs.
select
  p.proname as function_name,
  p.prosecdef as is_security_definer,
  p.proconfig as function_config
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'purchase_shop_item',
    'equip_shop_cosmetic',
    'apply_habit_completion_reward',
    'reverse_habit_completion_reward',
    'claim_achievement_reward',
    'claim_level_reward',
    'open_mystery_box'
  )
order by p.proname;

-- 4) Rollout snapshot.
select *
from public.global_cloud_economy_rollout_status
order by user_id
limit 25;

-- 5) Sanity checks for legacy compatibility.
select
  count(*) filter (where legacy_ambar_balance < 0) as negative_legacy_balances,
  count(*) filter (where wallet_coins < 0) as negative_wallet_balances,
  count(*) filter (where balance_delta <> 0) as divergent_balances
from public.global_cloud_economy_rollout_status;

-- 6) Manual authenticated smoke test block.
-- Replace the UUID placeholder with a real auth.users.id and run inside a transaction.
--
-- begin;
-- set local role authenticated;
-- set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';
--
-- -- Confirm the rollout view is readable for the active user.
-- select *
-- from public.global_cloud_economy_rollout_status
-- where user_id = '00000000-0000-0000-0000-000000000001';
--
-- -- Confirm the audit table is read-only for users and protected by RLS.
-- select *
-- from public.global_cloud_economy_rollout_audit
-- where user_id = '00000000-0000-0000-0000-000000000001';
--
-- rollback;
