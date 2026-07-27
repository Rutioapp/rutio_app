-- Read-only post-verification for
-- 20260727200000_harden_habit_reward_rpcs_logical_idempotency.sql.
-- Does not invoke economic RPCs.

-- 1) Function signatures, SECURITY DEFINER flag, owner, and search_path.
select
  n.nspname as schema_name,
  p.proname as function_name,
  pg_catalog.pg_get_function_identity_arguments(p.oid) as identity_arguments,
  pg_catalog.pg_get_function_result(p.oid) as result_type,
  p.prosecdef as security_definer,
  r.rolname as owner,
  p.proconfig as function_config
from pg_catalog.pg_proc as p
join pg_catalog.pg_namespace as n on n.oid = p.pronamespace
join pg_catalog.pg_roles as r on r.oid = p.proowner
where n.nspname = 'public'
  and p.proname in (
    'apply_habit_completion_reward',
    'reverse_habit_completion_reward'
  )
order by p.proname;

-- 2) Grants for client roles.
select
  routine_name,
  pg_catalog.has_function_privilege(
    'public',
    ('public.' || routine_name || '(text, uuid, text, text, text)')::regprocedure,
    'execute'
  ) as public_execute,
  pg_catalog.has_function_privilege(
    'anon',
    ('public.' || routine_name || '(text, uuid, text, text, text)')::regprocedure,
    'execute'
  ) as anon_execute,
  pg_catalog.has_function_privilege(
    'authenticated',
    ('public.' || routine_name || '(text, uuid, text, text, text)')::regprocedure,
    'execute'
  ) as authenticated_execute,
  pg_catalog.has_function_privilege(
    'service_role',
    ('public.' || routine_name || '(text, uuid, text, text, text)')::regprocedure,
    'execute'
  ) as service_role_execute
from (
  values
    ('apply_habit_completion_reward'),
    ('reverse_habit_completion_reward')
) as functions(routine_name);

-- 3) Body snippets that should be present in the hardened functions.
select
  p.proname,
  pg_catalog.pg_get_functiondef(p.oid) like '%set search_path = ''''%' as has_empty_search_path,
  pg_catalog.pg_get_functiondef(p.oid) like '%v_logical_date_key := (v_logical_date_key::date)::text%' as has_logical_date_normalization,
  pg_catalog.pg_get_functiondef(p.oid) like '%habit_currency_reward_logic:%' as has_logical_lock,
  pg_catalog.pg_get_functiondef(p.oid) like '%and habit_id = v_habit_id%and logical_date_key = v_logical_date_key%and operation_type = ''apply''%' as has_logical_apply_lookup,
  pg_catalog.pg_get_functiondef(p.oid) like '%and habit_id = v_habit_id%and logical_date_key = v_logical_date_key%and operation_type = ''reverse''%' as has_logical_reverse_lookup,
  pg_catalog.pg_get_functiondef(p.oid) like '%v_effective_request_id := v_request_id || '':reverse''%' as has_legacy_reverse_request_id,
  pg_catalog.pg_get_functiondef(p.oid) like '%when unique_violation then%' as has_unique_violation_recovery,
  pg_catalog.pg_get_functiondef(p.oid) like '%v_existing.balance_after := v_wallet.coins%' as returns_current_wallet_balance,
  pg_catalog.pg_get_functiondef(p.oid) not like '%update public.habit_currency_reward_ledger%set balance_after%' as does_not_persist_idempotent_balance_after
from pg_catalog.pg_proc as p
join pg_catalog.pg_namespace as n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'apply_habit_completion_reward',
    'reverse_habit_completion_reward'
  )
order by p.proname;

-- 4) Confirm this phase did not add the future unique logical index.
select indexname, indexdef
from pg_catalog.pg_indexes
where schemaname = 'public'
  and tablename = 'habit_currency_reward_ledger'
  and indexdef ilike '%unique%'
  and indexdef ilike '%user_id%'
  and indexdef ilike '%operation_type%'
  and indexdef ilike '%habit_id%'
  and indexdef ilike '%logical_date_key%';

-- 5) Confirm current ledger columns; this migration should not add columns.
select column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'public'
  and table_name = 'habit_currency_reward_ledger'
order by ordinal_position;

-- 6) Ledger integrity after deployment.
select user_id, habit_id, logical_date_key, operation_type, count(*) as row_count
from public.habit_currency_reward_ledger
group by user_id, habit_id, logical_date_key, operation_type
having count(*) > 1;

select r.*
from public.habit_currency_reward_ledger as r
left join public.habit_currency_reward_ledger as a
  on a.id = r.related_ledger_id
where r.operation_type = 'reverse'
  and (
    a.id is null
    or a.operation_type <> 'apply'
    or a.user_id <> r.user_id
    or a.habit_id <> r.habit_id
    or a.logical_date_key <> r.logical_date_key
  );

-- 7) Wallet sanity.
select user_id, coins, version, updated_at
from public.user_wallets
where coins < 0
   or version < 0;
