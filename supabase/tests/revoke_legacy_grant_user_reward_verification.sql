-- Read-only verification for:
-- supabase/migrations/20260727190000_revoke_direct_execution_from_legacy_grant_user_reward.sql
--
-- Expected:
-- - anon_can_execute = false
-- - authenticated_can_execute = false
-- - service_role_can_execute = true
-- - PUBLIC does not have EXECUTE in proacl/effective privileges
-- - grant_user_reward and record_habit_log keep owner postgres
-- - grant_user_reward definition still exists and was not replaced by this migration

begin transaction read only;

select
  has_function_privilege(
    'anon',
    'public.grant_user_reward(integer,integer,text,uuid,text)',
    'EXECUTE'
  ) as anon_can_execute,
  has_function_privilege(
    'authenticated',
    'public.grant_user_reward(integer,integer,text,uuid,text)',
    'EXECUTE'
  ) as authenticated_can_execute,
  has_function_privilege(
    'service_role',
    'public.grant_user_reward(integer,integer,text,uuid,text)',
    'EXECUTE'
  ) as service_role_can_execute;

select
  p.proacl,
  has_function_privilege(
    'public',
    'public.grant_user_reward(integer,integer,text,uuid,text)',
    'EXECUTE'
  ) as public_can_execute
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname = 'grant_user_reward'
  and pg_get_function_identity_arguments(p.oid) =
      'xp_amount_input integer, ambar_amount_input integer, source_input text, source_id_input uuid, description_input text';

select
  p.proname as function_name,
  r.rolname as owner_name,
  p.prosecdef as security_definer,
  p.proconfig as function_config,
  pg_get_function_identity_arguments(p.oid) as identity_arguments
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
join pg_roles r on r.oid = p.proowner
where n.nspname = 'public'
  and p.proname in ('grant_user_reward', 'record_habit_log')
order by p.proname;

select
  pg_get_functiondef(p.oid) as grant_user_reward_definition
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname = 'grant_user_reward'
  and pg_get_function_identity_arguments(p.oid) =
      'xp_amount_input integer, ambar_amount_input integer, source_input text, source_id_input uuid, description_input text';

commit;
