-- Rutio Phase 9B: Supabase analytics SQL views (internal/admin)
-- Date: 2026-04-28
--
-- Purpose:
-- - Provide aggregate backend analytics for internal alpha/admin analysis.
-- - Keep app behavior unchanged (no Flutter/UI coupling).
--
-- Security guidance:
-- - These views are intended for internal/admin use only.
-- - Do NOT expose these views directly to normal end users.
-- - In Supabase, keep API/RLS access restricted (prefer service role or admin-only paths).
-- - Example hardening (review before applying in your environment):
--   revoke all on public.analytics_total_users from anon, authenticated;
--   revoke all on public.analytics_new_users_by_day from anon, authenticated;
--   revoke all on public.analytics_daily_active_users from anon, authenticated;
--   revoke all on public.analytics_habits_created_by_day from anon, authenticated;
--   revoke all on public.analytics_habit_logs_completed_by_day from anon, authenticated;
--   revoke all on public.analytics_journal_entries_by_day from anon, authenticated;
--   revoke all on public.analytics_achievement_unlocks_by_day from anon, authenticated;
--   revoke all on public.analytics_xp_generated_by_day from anon, authenticated;
--   revoke all on public.analytics_ambar_by_day from anon, authenticated;
--   revoke all on public.analytics_daily_summary from anon, authenticated;
--
-- NOTE ABOUT auth.users:
-- - View analytics_new_users_by_day uses auth.users.created_at by default.
-- - If your environment should avoid auth schema exposure, use profiles.created_at
--   in an alternative view/query documented in docs/supabase_analytics_views_phase_9b.md.

create or replace view public.analytics_total_users as
with counts as (
  select
    (
      select count(*)::bigint
      from auth.users
    ) as auth_users,
    (
      select count(*)::bigint
      from public.profiles
    ) as profile_rows,
    (
      select count(*)::bigint
      from (
        select u.id
        from auth.users u
        union
        select p.id
        from public.profiles p
      ) ids
    ) as total_users
)
select
  total_users,
  auth_users,
  profile_rows
from counts;

comment on view public.analytics_total_users is
  'Internal/admin analytics only. Aggregate user counts across auth.users and public.profiles.';

create or replace view public.analytics_new_users_by_day as
select
  u.created_at::date as signup_date,
  count(*)::bigint as new_users
from auth.users u
group by u.created_at::date
order by signup_date;

comment on view public.analytics_new_users_by_day is
  'Internal/admin analytics only. New user signups by day from auth.users.created_at.';

create or replace view public.analytics_daily_active_users as
with activity_events as (
  select h.user_id, h.created_at::date as activity_date
  from public.habits h

  union all

  select hl.user_id, hl.created_at::date as activity_date
  from public.habit_logs hl

  union all

  select hl.user_id, hl.updated_at::date as activity_date
  from public.habit_logs hl

  union all

  select je.user_id, je.created_at::date as activity_date
  from public.journal_entries je
  where coalesce(je.is_deleted, false) = false

  union all

  select je.user_id, je.updated_at::date as activity_date
  from public.journal_entries je
  where coalesce(je.is_deleted, false) = false

  union all

  select xe.user_id, xe.created_at::date as activity_date
  from public.xp_events xe

  union all

  select ce.user_id, ce.created_at::date as activity_date
  from public.currency_events ce

  union all

  select ua.user_id, ua.unlocked_at::date as activity_date
  from public.user_achievements ua

  union all

  select ua.user_id, ua.created_at::date as activity_date
  from public.user_achievements ua
)
select
  ae.activity_date,
  count(distinct ae.user_id)::bigint as active_users
from activity_events ae
where ae.activity_date is not null
group by ae.activity_date
order by ae.activity_date;

comment on view public.analytics_daily_active_users is
  'Internal/admin analytics only. DAU by day from habits, habit_logs, journal_entries, xp_events, currency_events, and user_achievements.';

create or replace view public.analytics_habits_created_by_day as
select
  h.created_at::date as created_date,
  count(*)::bigint as habits_created,
  count(distinct h.user_id)::bigint as unique_users
from public.habits h
group by h.created_at::date
order by created_date;

comment on view public.analytics_habits_created_by_day is
  'Internal/admin analytics only. Habits created by day from public.habits.created_at.';

create or replace view public.analytics_habit_logs_completed_by_day as
select
  hl.log_date as log_date,
  count(*)::bigint as completed_logs,
  count(distinct hl.user_id)::bigint as unique_users
from public.habit_logs hl
where hl.is_completed = true
group by hl.log_date
order by hl.log_date;

comment on view public.analytics_habit_logs_completed_by_day is
  'Internal/admin analytics only. Completed habit logs by day from public.habit_logs.log_date.';

create or replace view public.analytics_journal_entries_by_day as
select
  je.entry_date as entry_date,
  count(*)::bigint as journal_entries,
  count(distinct je.user_id)::bigint as unique_users
from public.journal_entries je
where coalesce(je.is_deleted, false) = false
group by je.entry_date
order by je.entry_date;

comment on view public.analytics_journal_entries_by_day is
  'Internal/admin analytics only. Non-deleted journal entries by day from public.journal_entries.entry_date.';

create or replace view public.analytics_achievement_unlocks_by_day as
select
  ua.unlocked_at::date as unlock_date,
  count(*)::bigint as achievement_unlocks,
  count(distinct ua.user_id)::bigint as unique_users
from public.user_achievements ua
group by ua.unlocked_at::date
order by unlock_date;

comment on view public.analytics_achievement_unlocks_by_day is
  'Internal/admin analytics only. Achievement unlocks by day from public.user_achievements.unlocked_at.';

create or replace view public.analytics_xp_generated_by_day as
select
  xe.created_at::date as event_date,
  sum(xe.amount)::bigint as xp_generated,
  count(*)::bigint as events_count,
  count(distinct xe.user_id)::bigint as unique_users
from public.xp_events xe
group by xe.created_at::date
order by event_date;

comment on view public.analytics_xp_generated_by_day is
  'Internal/admin analytics only. XP generated by day from public.xp_events.created_at and amount.';

create or replace view public.analytics_ambar_by_day as
select
  ce.created_at::date as event_date,
  sum(case when ce.amount > 0 then ce.amount else 0 end)::bigint as ambar_generated,
  sum(case when ce.amount < 0 then -ce.amount else 0 end)::bigint as ambar_spent,
  sum(ce.amount)::bigint as net_ambar,
  count(*)::bigint as events_count,
  count(distinct ce.user_id)::bigint as unique_users
from public.currency_events ce
where ce.currency = 'ambar'
group by ce.created_at::date
order by event_date;

comment on view public.analytics_ambar_by_day is
  'Internal/admin analytics only. Ambar generated/spent/net by day from public.currency_events.';

create or replace view public.analytics_daily_summary as
with all_dates as (
  select signup_date as activity_date from public.analytics_new_users_by_day
  union
  select activity_date from public.analytics_daily_active_users
  union
  select created_date as activity_date from public.analytics_habits_created_by_day
  union
  select log_date as activity_date from public.analytics_habit_logs_completed_by_day
  union
  select entry_date as activity_date from public.analytics_journal_entries_by_day
  union
  select unlock_date as activity_date from public.analytics_achievement_unlocks_by_day
  union
  select event_date as activity_date from public.analytics_xp_generated_by_day
  union
  select event_date as activity_date from public.analytics_ambar_by_day
)
select
  d.activity_date,
  coalesce(nu.new_users, 0)::bigint as new_users,
  coalesce(dau.active_users, 0)::bigint as active_users,
  coalesce(hc.habits_created, 0)::bigint as habits_created,
  coalesce(hl.completed_logs, 0)::bigint as completed_logs,
  coalesce(je.journal_entries, 0)::bigint as journal_entries,
  coalesce(au.achievement_unlocks, 0)::bigint as achievement_unlocks,
  coalesce(xp.xp_generated, 0)::bigint as xp_generated,
  coalesce(am.ambar_generated, 0)::bigint as ambar_generated,
  coalesce(am.ambar_spent, 0)::bigint as ambar_spent,
  coalesce(am.net_ambar, 0)::bigint as net_ambar
from all_dates d
left join public.analytics_new_users_by_day nu
  on nu.signup_date = d.activity_date
left join public.analytics_daily_active_users dau
  on dau.activity_date = d.activity_date
left join public.analytics_habits_created_by_day hc
  on hc.created_date = d.activity_date
left join public.analytics_habit_logs_completed_by_day hl
  on hl.log_date = d.activity_date
left join public.analytics_journal_entries_by_day je
  on je.entry_date = d.activity_date
left join public.analytics_achievement_unlocks_by_day au
  on au.unlock_date = d.activity_date
left join public.analytics_xp_generated_by_day xp
  on xp.event_date = d.activity_date
left join public.analytics_ambar_by_day am
  on am.event_date = d.activity_date
order by d.activity_date;

comment on view public.analytics_daily_summary is
  'Internal/admin analytics only. Daily rollup joining all Phase 9B aggregate views by date.';
