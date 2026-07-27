-- Read-only verification for:
-- supabase/migrations/20260727193000_neutralize_legacy_record_habit_log_rewards.sql
--
-- Expected:
-- - record_habit_log keeps the exact legacy signature and return columns
-- - record_habit_log is SECURITY DEFINER, owner postgres, search_path=''
-- - record_habit_log no longer calls grant_user_reward or writes legacy rewards
-- - record_habit_log can execute only for authenticated and service_role
-- - grant_user_reward remains executable only by owner/service_role
-- - historical legacy balances/events/columns remain present

begin transaction read only;

select
  p.proname as function_name,
  pg_get_function_identity_arguments(p.oid) as identity_arguments,
  pg_get_function_result(p.oid) as function_result,
  p.prosecdef as security_definer,
  p.proconfig as function_config,
  r.rolname as owner_name
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
join pg_roles r on r.oid = p.proowner
where n.nspname = 'public'
  and p.proname = 'record_habit_log'
  and pg_get_function_identity_arguments(p.oid) =
      'habit_id_input uuid, log_date_input date, value_input integer, is_completed_input boolean, note_input text';

select
  pg_get_functiondef(p.oid) not ilike '%grant_user_reward%' as does_not_call_grant_user_reward,
  pg_get_functiondef(p.oid) not ilike '%update public.user_progress%' as does_not_update_user_progress,
  pg_get_functiondef(p.oid) not ilike '%insert into public.xp_events%' as does_not_insert_xp_events,
  pg_get_functiondef(p.oid) not ilike '%insert into public.currency_events%' as does_not_insert_currency_events
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname = 'record_habit_log'
  and pg_get_function_identity_arguments(p.oid) =
      'habit_id_input uuid, log_date_input date, value_input integer, is_completed_input boolean, note_input text';

select
  has_function_privilege(
    'public',
    'public.record_habit_log(uuid,date,integer,boolean,text)',
    'EXECUTE'
  ) as public_can_execute,
  has_function_privilege(
    'anon',
    'public.record_habit_log(uuid,date,integer,boolean,text)',
    'EXECUTE'
  ) as anon_can_execute,
  has_function_privilege(
    'authenticated',
    'public.record_habit_log(uuid,date,integer,boolean,text)',
    'EXECUTE'
  ) as authenticated_can_execute,
  has_function_privilege(
    'service_role',
    'public.record_habit_log(uuid,date,integer,boolean,text)',
    'EXECUTE'
  ) as service_role_can_execute;

select
  has_function_privilege(
    'public',
    'public.grant_user_reward(integer,integer,text,uuid,text)',
    'EXECUTE'
  ) as public_can_execute,
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
  count(*) as user_progress_rows,
  coalesce(sum(total_xp), 0) as total_legacy_xp,
  coalesce(sum(ambar_balance), 0) as total_legacy_ambar_balance
from public.user_progress;

select
  (select count(*) from public.xp_events) as historical_xp_events,
  (select count(*) from public.currency_events) as historical_currency_events;

select
  column_name,
  data_type
from information_schema.columns
where table_schema = 'public'
  and table_name = 'habit_logs'
  and column_name in (
    'reward_granted',
    'xp_reward_granted',
    'ambar_reward_granted',
    'completed_at'
  )
order by column_name;

commit;
