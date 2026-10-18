begin;

-- user_progress is a compatibility projection, not a client-owned economic
-- state machine. Keep historical reads for restore/UI compatibility, but do
-- not allow client roles to create or mutate XP, level, or currency totals.
--
-- The owner/service_role may still perform controlled maintenance. This
-- migration does not grant any new internal write path and does not alter
-- existing rows or balances.
revoke insert, update, delete
on table public.user_progress
from public, anon, authenticated;

-- Remove the client row-write policies as a second authorization barrier.
-- The SELECT policy remains unchanged for authenticated users owning the row.
drop policy if exists user_progress_insert_own on public.user_progress;
drop policy if exists user_progress_update_own on public.user_progress;
drop policy if exists user_progress_delete_own on public.user_progress;

comment on table public.user_progress is
  'Compatibility projection for user progress. Client roles may read their own row; writes require controlled server-side maintenance or an approved projection RPC.';

commit;
