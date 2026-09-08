-- MANUAL READ-ONLY POST-DEPLOY CHECK.
-- Replace the UUID only; this script performs no writes and no RPC call.
select
  p.id,
  p.onboarding_completed,
  p.onboarding_status,
  p.onboarding_completed_at,
  (
    select count(*)
    from app_private.onboarding_completion_operations o
    where o.user_id = p.id
      and o.status = 'completed'
  ) as completion_operations,
  (
    select count(*)
    from public.habits h
    where h.user_id = p.id
  ) as habits
from public.profiles p
where p.id = '27d964b2-f839-482f-89d4-e6c504bf7e68'::uuid;
