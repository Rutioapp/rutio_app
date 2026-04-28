# Supabase Analytics Views (Phase 9B)

Date: April 28, 2026  
Branch: `chore/supabase-analytics-views`

## Purpose

Phase 9B adds backend-only Supabase SQL views for internal alpha/admin analytics. These are aggregate usage views and do not change Flutter app behavior.

## Security and access scope (important)

- These views are internal/admin analytics views.
- Do not expose them to normal app users.
- Keep Supabase API access restricted (service role or admin-only access paths).
- Consider revoking `anon`/`authenticated` access unless explicitly needed by trusted admin clients.

Example hardening commands are included as comments inside:
- `supabase/sql/supabase_analytics_views_phase_9b.sql`

## SQL file

- `supabase/sql/supabase_analytics_views_phase_9b.sql`

The file is idempotent for repeated runs because all views use `create or replace view`.

## Views and what they measure

### 1) `public.analytics_total_users`

Columns:
- `total_users`
- `auth_users`
- `profile_rows`

Measures:
- `auth_users`: count of `auth.users`
- `profile_rows`: count of `public.profiles`
- `total_users`: distinct union count of user ids across both tables

Use:
- Detect auth/profile row mismatches while still surfacing a total.

### 2) `public.analytics_new_users_by_day`

Columns:
- `signup_date`
- `new_users`

Source:
- `auth.users.created_at`

Note:
- If your environment should avoid direct `auth` schema exposure in analytics, use `public.profiles.created_at` as an alternative proxy.

Alternative example:

```sql
select
  p.created_at::date as signup_date,
  count(*)::bigint as new_users
from public.profiles p
group by p.created_at::date
order by signup_date;
```

### 3) `public.analytics_daily_active_users`

Columns:
- `activity_date`
- `active_users`

Definition:
- A user is active on a day if they have at least one event in any source table:
  - `public.habits.created_at`
  - `public.habit_logs.updated_at` or `created_at`
  - `public.journal_entries.updated_at` or `created_at` (non-deleted rows)
  - `public.xp_events.created_at`
  - `public.currency_events.created_at`
  - `public.user_achievements.unlocked_at` or `created_at`
- The view unions those activity rows and counts distinct `user_id` per date.

### 4) `public.analytics_habits_created_by_day`

Columns:
- `created_date`
- `habits_created`
- `unique_users`

Source:
- `public.habits.created_at`

### 5) `public.analytics_habit_logs_completed_by_day`

Columns:
- `log_date`
- `completed_logs`
- `unique_users`

Source:
- `public.habit_logs.log_date`

Filter:
- `is_completed = true`

### 6) `public.analytics_journal_entries_by_day`

Columns:
- `entry_date`
- `journal_entries`
- `unique_users`

Source:
- `public.journal_entries.entry_date`

Filter:
- `is_deleted = false`

### 7) `public.analytics_achievement_unlocks_by_day`

Columns:
- `unlock_date`
- `achievement_unlocks`
- `unique_users`

Source:
- `public.user_achievements.unlocked_at`

### 8) `public.analytics_xp_generated_by_day`

Columns:
- `event_date`
- `xp_generated`
- `events_count`
- `unique_users`

Source:
- `public.xp_events.created_at`
- `sum(amount)` for XP total

### 9) `public.analytics_ambar_by_day`

Columns:
- `event_date`
- `ambar_generated`
- `ambar_spent`
- `net_ambar`
- `events_count`
- `unique_users`

Source:
- `public.currency_events.created_at`

Filter:
- `currency = 'ambar'`

Computation:
- `ambar_generated`: sum of positive amounts
- `ambar_spent`: absolute sum of negative amounts
- `net_ambar`: sum of raw amount

### 10) `public.analytics_daily_summary`

Columns:
- `activity_date`
- `new_users`
- `active_users`
- `habits_created`
- `completed_logs`
- `journal_entries`
- `achievement_unlocks`
- `xp_generated`
- `ambar_generated`
- `ambar_spent`
- `net_ambar`

Definition:
- Joins all daily views by a unioned date set so days with partial data are still included.

## How to run

In Supabase SQL Editor (or your migration runner), execute:

```sql
-- Run this file:
-- supabase/sql/supabase_analytics_views_phase_9b.sql
```

If you use Supabase CLI migrations, convert/append this SQL to your migration workflow as appropriate.

## Example queries

```sql
select *
from public.analytics_total_users;
```

```sql
select *
from public.analytics_daily_summary
order by activity_date desc
limit 30;
```

```sql
select
  activity_date,
  active_users,
  new_users
from public.analytics_daily_summary
where activity_date >= current_date - interval '30 days'
order by activity_date;
```

```sql
select
  event_date,
  ambar_generated,
  ambar_spent,
  net_ambar
from public.analytics_ambar_by_day
order by event_date desc
limit 30;
```

## Limitations

- This is not a replacement for full product analytics SDK instrumentation.
- Metrics depend on backend write success and data quality.
- Date bucketing uses database date casting (`timestamptz::date`) unless explicitly changed.
- No device/session analytics are included.

## Future extensions

- Internal admin dashboard on top of these views
- Retention cohorts (D1/D7/D30)
- Conversion funnels (signup -> first habit -> first completion)
- Churn/inactivity metrics
