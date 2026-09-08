-- READ-ONLY POST-DEPLOY CHECKS
-- Run against the linked project after applying the forward migration.

with target as (
  select to_regprocedure(
    'public.complete_onboarding_v1(uuid,text,text,jsonb,jsonb,jsonb)'
  ) as oid
)
select
  target.oid::regprocedure as signature,
  p.prosecdef as security_definer,
  p.proconfig as configuration,
  pg_get_functiondef(target.oid) like '%pg_catalog.btrim(%' as has_btrim,
  pg_get_functiondef(target.oid) not like '%pg_catalog.trim(%' as has_no_invalid_trim,
  pg_get_functiondef(target.oid) not like '%pg_catalog.nullif(%' as has_no_invalid_nullif,
  pg_get_functiondef(target.oid) like '%nullif(pg_catalog.btrim(%' as has_typed_nullif_candidate
from target
join pg_proc p on p.oid = target.oid;

select
  grantee,
  privilege_type
from information_schema.routine_privileges
where specific_schema = 'public'
  and routine_name = 'complete_onboarding_v1'
  and data_type = 'jsonb'
order by grantee, privilege_type;

-- Expected: EXECUTE for authenticated; no EXECUTE for anon or PUBLIC.
