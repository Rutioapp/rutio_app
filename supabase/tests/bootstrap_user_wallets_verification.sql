-- Bootstrap user wallets verification.
-- Safe to run after applying the migration.
-- This file does not mutate production data.

-- 1) Coverage: expected result after applying is 0.
select count(*) as auth_users_without_wallet
from auth.users u
left join public.user_wallets w on w.user_id = u.id
where w.user_id is null;

-- 2) Wallet for a concrete user.
-- Replace the UUID placeholder with a real auth.users.id.
-- select *
-- from public.user_wallets
-- where user_id = '00000000-0000-0000-0000-000000000000';

-- 3) Trigger: should exist, be enabled, and run after insert on auth.users.
select
  t.tgname as trigger_name,
  case t.tgenabled
    when 'O' then 'enabled'
    when 'D' then 'disabled'
    when 'R' then 'replica'
    when 'A' then 'always'
  end as trigger_status,
  pg_get_triggerdef(t.oid) as trigger_definition
from pg_trigger t
where t.tgrelid = 'auth.users'::regclass
  and t.tgname = 'trg_auth_users_bootstrap_user_wallet'
  and not t.tgisinternal;

-- 4) Function: schema, SECURITY DEFINER, and search_path configuration.
select
  n.nspname as function_schema,
  p.proname as function_name,
  p.prosecdef as is_security_definer,
  p.proconfig as function_config,
  pg_get_functiondef(p.oid) as function_definition
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'app_private'
  and p.proname = 'bootstrap_user_wallet_on_auth_insert';

-- 5) Direct execution privileges: anon/authenticated should both be false.
select
  has_function_privilege(
    'anon',
    'app_private.bootstrap_user_wallet_on_auth_insert()'::regprocedure,
    'EXECUTE'
  ) as anon_can_execute_bootstrap_trigger_function,
  has_function_privilege(
    'authenticated',
    'app_private.bootstrap_user_wallet_on_auth_insert()'::regprocedure,
    'EXECUTE'
  ) as authenticated_can_execute_bootstrap_trigger_function;

-- 6) Wallet table read/write privileges for client roles.
select
  has_table_privilege(
    'authenticated',
    'public.user_wallets',
    'SELECT'
  ) as authenticated_can_select_user_wallets,
  has_table_privilege(
    'authenticated',
    'public.user_wallets',
    'INSERT'
  ) as authenticated_can_insert_user_wallets,
  has_table_privilege(
    'authenticated',
    'public.user_wallets',
    'UPDATE'
  ) as authenticated_can_update_user_wallets,
  has_table_privilege(
    'anon',
    'public.user_wallets',
    'INSERT'
  ) as anon_can_insert_user_wallets,
  has_table_privilege(
    'anon',
    'public.user_wallets',
    'UPDATE'
  ) as anon_can_update_user_wallets;

-- 7) Existing updated_at trigger: should remain the single wallet updated_at trigger.
select
  t.tgname as trigger_name,
  pg_get_triggerdef(t.oid) as trigger_definition
from pg_trigger t
where t.tgrelid = 'public.user_wallets'::regclass
  and t.tgname = 'trg_user_wallets_set_updated_at'
  and not t.tgisinternal;

-- 8) Integrity checks: all should return 0.
select count(*) as wallets_with_negative_coins
from public.user_wallets
where coins < 0;

select count(*) as wallets_with_negative_version
from public.user_wallets
where version < 0;

select
  user_id,
  count(*) as wallet_rows
from public.user_wallets
group by user_id
having count(*) > 1
order by user_id;
