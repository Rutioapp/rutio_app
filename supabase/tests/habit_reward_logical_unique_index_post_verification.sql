-- Read-only post-verification for
-- 20260727203000_add_habit_reward_logical_unique_index.sql.
-- Does not invoke economic RPCs.

-- 1) Exact index existence, uniqueness, validity/readiness, simplicity, and no predicate.
select
  i.relname as index_name,
  tn.nspname as table_schema,
  t.relname as table_name,
  ix.indisunique,
  ix.indisvalid,
  ix.indisready,
  ix.indpred is null as has_no_partial_predicate,
  ix.indexprs is null as has_no_expressions,
  pg_catalog.pg_get_indexdef(ix.indexrelid) as index_definition
from pg_catalog.pg_index as ix
join pg_catalog.pg_class as i on i.oid = ix.indexrelid
join pg_catalog.pg_class as t on t.oid = ix.indrelid
join pg_catalog.pg_namespace as tn on tn.oid = t.relnamespace
where tn.nspname = 'public'
  and t.relname = 'habit_currency_reward_ledger'
  and i.relname = 'idx_habit_currency_reward_ledger_user_op_habit_date_unique';

-- 2) Exact column order. Expected rows:
-- 1 user_id, 2 operation_type, 3 habit_id, 4 logical_date_key.
select
  cols.ordinality as index_position,
  a.attname as column_name
from pg_catalog.pg_index as ix
join pg_catalog.pg_class as i on i.oid = ix.indexrelid
join pg_catalog.pg_class as t on t.oid = ix.indrelid
join pg_catalog.pg_namespace as tn on tn.oid = t.relnamespace
join lateral unnest(ix.indkey) with ordinality as cols(attnum, ordinality) on true
join pg_catalog.pg_attribute as a
  on a.attrelid = t.oid
 and a.attnum = cols.attnum
where tn.nspname = 'public'
  and t.relname = 'habit_currency_reward_ledger'
  and i.relname = 'idx_habit_currency_reward_ledger_user_op_habit_date_unique'
order by cols.ordinality;

-- 3) Confirm the index is exactly the expected simple, full-table unique index.
select
  ix.indisunique
  and ix.indisvalid
  and ix.indisready
  and ix.indpred is null
  and ix.indexprs is null
  and array_agg(a.attname order by cols.ordinality) = array[
    'user_id',
    'operation_type',
    'habit_id',
    'logical_date_key'
  ] as exact_logical_unique_index_present
from pg_catalog.pg_index as ix
join pg_catalog.pg_class as i on i.oid = ix.indexrelid
join pg_catalog.pg_class as t on t.oid = ix.indrelid
join pg_catalog.pg_namespace as tn on tn.oid = t.relnamespace
join lateral unnest(ix.indkey) with ordinality as cols(attnum, ordinality) on true
join pg_catalog.pg_attribute as a
  on a.attrelid = t.oid
 and a.attnum = cols.attnum
where tn.nspname = 'public'
  and t.relname = 'habit_currency_reward_ledger'
  and i.relname = 'idx_habit_currency_reward_ledger_user_op_habit_date_unique'
group by ix.indisunique, ix.indisvalid, ix.indisready, ix.indpred, ix.indexprs;

-- 4) Ledger columns should be unchanged by this migration.
select
  column_name,
  data_type,
  udt_name,
  is_nullable,
  column_default
from information_schema.columns
where table_schema = 'public'
  and table_name = 'habit_currency_reward_ledger'
order by ordinal_position;

-- 5) Ledger integrity after deployment. Expected: zero rows for each anomaly.
select
  user_id,
  operation_type,
  habit_id,
  logical_date_key,
  count(*) as row_count
from public.habit_currency_reward_ledger
group by user_id, operation_type, habit_id, logical_date_key
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

select user_id, coins, version, updated_at
from public.user_wallets
where coins < 0
   or version < 0;

-- 6) Function signatures, SECURITY DEFINER flag, owner, and search_path remain intact.
select
  n.nspname as schema_name,
  p.proname as function_name,
  pg_catalog.pg_get_function_identity_arguments(p.oid) as identity_arguments,
  pg_catalog.pg_get_function_result(p.oid) as result_type,
  p.prosecdef as security_definer,
  r.rolname as owner,
  p.proconfig as function_config,
  pg_catalog.pg_get_functiondef(p.oid) like '%set search_path = ''''%' as has_empty_search_path
from pg_catalog.pg_proc as p
join pg_catalog.pg_namespace as n on n.oid = p.pronamespace
join pg_catalog.pg_roles as r on r.oid = p.proowner
where n.nspname = 'public'
  and p.proname in (
    'apply_habit_completion_reward',
    'reverse_habit_completion_reward'
  )
order by p.proname;

-- 7) Grants for both RPCs remain intact.
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
