begin;

-- user_progress is a server-owned economic projection. Keep authenticated
-- SELECT through the existing own-row policy; controlled SECURITY DEFINER
-- functions owned by postgres continue to refresh it.
revoke insert, update, delete
on table public.user_progress
from public, anon, authenticated;

drop policy if exists user_progress_insert_own on public.user_progress;
drop policy if exists user_progress_update_own on public.user_progress;
drop policy if exists user_progress_delete_own on public.user_progress;

-- Direct habit-log DML must not be another state machine for rewards. The
-- authoritative completion RPC writes logs transactionally with the ledgers.
-- Keep authenticated SELECT through the existing own-row policy.
revoke insert, update, delete
on table public.habit_logs
from public, anon, authenticated;

drop policy if exists habit_logs_insert_own on public.habit_logs;
drop policy if exists habit_logs_update_own on public.habit_logs;
drop policy if exists habit_logs_delete_own on public.habit_logs;

commit;
