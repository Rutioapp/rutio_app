-- MANUAL VALIDATION ONLY
-- DO NOT RUN BLINDLY
-- REPLACE TEST USER / PAYLOAD
-- RUN AGAINST EXPECTED ENVIRONMENT ONLY
--
-- This file is intentionally outside supabase/migrations and is never run by
-- Flutter tests or Supabase CLI migration application. Use a dedicated QA
-- account with no personal or production data. Do not put passwords, tokens,
-- or service-role keys in this file.

-- 0) Apply/inspect the migration through the normal controlled release
-- process first. Do not use this script as a deployment mechanism.
select n.nspname as schema_name, c.relname as relation_name,
       c.relkind as relation_kind
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'app_private'
  and c.relname = 'onboarding_completion_operations';

select p.pronamespace::regnamespace as schema_name,
       p.proname,
       pg_get_function_identity_arguments(p.oid) as signature,
       p.prosecdef as security_definer,
       p.proconfig as configuration
from pg_proc p
where p.pronamespace = 'public'::regnamespace
  and p.proname = 'complete_onboarding_v1';

select grantee, privilege_type
from information_schema.role_table_grants
where table_schema = 'app_private'
  and table_name = 'onboarding_completion_operations';

select grantee, privilege_type
from information_schema.role_routine_grants
where routine_schema = 'public'
  and routine_name = 'complete_onboarding_v1';

-- 1) AUTH CONTEXT
-- Preferred: execute the calls below from the app using a real session for
-- the dedicated QA account. auth.uid() must be the QA account's UUID.
--
-- Controlled local-only alternative, if the environment's auth.uid()
-- implementation supports request claims (never use this as a production
-- bypass):
-- begin;
-- set local role authenticated;
-- set local request.jwt.claim.sub = '<QA_USER_UUID>';
--
-- 2) First completion: replace UUID and payload values.
-- select public.complete_onboarding_v1(
--   '<OPERATION_UUID>'::uuid,
--   'newAccount',
--   'keep',
--   jsonb_build_object('name', 'QA Name'),
--   jsonb_build_object(
--     'name', 'QA habit', 'emoji', '✓', 'habit_type', 'check',
--     'schedule', jsonb_build_object(
--       'type', 'timesPerWeek', 'timesPerWeek', 3, 'weekStartsOn', 1
--     )
--   ),
--   jsonb_build_object('enabled', true, 'hour', 9, 'minute', 30)
-- );

-- 3) Replay: same operation and exactly the same JSON values. Expected:
-- alreadyCompletedSameOperation and the same habitId.
-- select public.complete_onboarding_v1(
--   '<OPERATION_UUID>'::uuid, 'newAccount', 'keep',
--   jsonb_build_object('name', 'QA Name'),
--   jsonb_build_object(
--     'name', 'QA habit', 'emoji', '✓', 'habit_type', 'check',
--     'schedule', jsonb_build_object(
--       'type', 'timesPerWeek', 'timesPerWeek', 3, 'weekStartsOn', 1
--     )
--   ),
--   jsonb_build_object('enabled', true, 'hour', 9, 'minute', 30)
-- );

-- 4) Same operation with a changed name/decision: expected operation_conflict.
-- select public.complete_onboarding_v1(
--   '<OPERATION_UUID>'::uuid, 'newAccount', 'discard',
--   jsonb_build_object('name', 'CHANGED'), null, null
-- );

-- 5) Existing account keep/discard: use two fresh operation UUIDs. Verify
-- profile.display_name remains the remote value and count the resulting rows.
-- select public.complete_onboarding_v1(
--   '<KEEP_OPERATION_UUID>'::uuid, 'existingAccountCompleted', 'keep',
--   '{}'::jsonb,
--   jsonb_build_object(
--     'name', 'Existing prepared', 'emoji', '✓', 'habit_type', 'check',
--     'schedule', jsonb_build_object('type', 'daily')
--   ), '{}'::jsonb
-- );
-- select public.complete_onboarding_v1(
--   '<DISCARD_OPERATION_UUID>'::uuid, 'existingAccountCompleted', 'discard',
--   '{}'::jsonb, null, null
-- );

-- 6) Rollback: send an invalid schedule in a fresh operation. Expected no
-- completed ledger row, no new habit, and no partial profile transition.
-- select public.complete_onboarding_v1(
--   '<ROLLBACK_OPERATION_UUID>'::uuid, 'existingAccountIncomplete', 'keep',
--   '{}'::jsonb,
--   jsonb_build_object(
--     'name', 'Invalid', 'emoji', 'x', 'habit_type', 'check',
--     'schedule', jsonb_build_object('type', 'not-a-schedule')
--   ), null
-- );

-- 7) Inspect results as the QA user (ledger rows are intentionally private;
-- the operation result is observed through the RPC response, not direct SQL).
-- select id, display_name, onboarding_status, onboarding_completed_at
-- from public.profiles
-- where id = '<QA_USER_UUID>'::uuid;
-- select id, name, habit_type, target_count, schedule,
--        reminder_enabled, reminder_time
-- from public.habits
-- where user_id = '<QA_USER_UUID>'::uuid
-- order by created_at desc;
--
-- rollback;
