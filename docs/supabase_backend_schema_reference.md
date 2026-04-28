# Supabase Backend Schema Reference (Phase 9)

Date: April 28, 2026  
Branch: `chore/backend-hardening`

This document is the consolidated backend schema reference for Rutio's current local-first Supabase integration.

## Scope and guardrails

- Local state remains source of truth.
- Remote writes are best-effort, non-blocking persistence.
- No remote-to-local merge is defined here.
- No two-way sync is defined here.

## Known lessons (must keep)

1. `create table if not exists` does not patch existing schemas.
2. `journal_entries` must **not** enforce `unique(user_id, entry_date)` because multiple entries per day are supported.
3. `user_achievements.achievement_id` must **not** reference `achievement_definitions` while achievement definitions remain local-only.
4. `user_achievements.tier` values must be technical values:  
   `wood`, `stone`, `bronze`, `silver`, `gold`, `diamond`, `prismaticDiamond`.
5. `journal_entries.content` is sensitive personal data and must be protected by strict RLS and log hygiene.

## Table: `public.profiles`

### Columns
- `id uuid not null` (auth user id)
- `email text null`
- `display_name text null`
- `avatar_url text null`
- `preferred_language_code text null`
- `notifications_enabled boolean null`
- `daily_motivation_enabled boolean null`
- `marketing_notifications_enabled boolean null`
- `daily_motivation_time text null`
- `last_login_at timestamptz null`
- `last_seen_at timestamptz null`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

### Primary key
- `profiles_pkey (id)`

### Foreign keys
- `profiles.id -> auth.users(id)` `on delete cascade`

### Unique constraints
- Primary key only.

### Check constraints
- None required currently.

### RLS policies
- Authenticated user can `select` own row (`auth.uid() = id`)
- Authenticated user can `insert` own row (`auth.uid() = id`)
- Authenticated user can `update` own row (`auth.uid() = id`)

### Indexes
- Primary key index on `id`

### Local-first notes
- Profile writes are best-effort metadata persistence.
- Missing optional columns must degrade safely (no app crash).

### Patch issues seen during development
- Older environments may miss optional columns; repository drops unsupported patch columns and retries.

## Table: `public.habits`

### Columns
- `id uuid not null default gen_random_uuid()`
- `user_id uuid not null`
- `name text not null`
- `family_id text null`
- `emoji text null`
- `habit_type text not null default 'check'`
- `target_count integer null`
- `unit text null`
- `color_id text null`
- `reminder_enabled boolean not null default false`
- `reminder_time time null`
- `is_archived boolean not null default false`
- `sort_order integer not null default 0`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

### Primary key
- `habits_pkey (id)`

### Foreign keys
- `habits.user_id -> auth.users(id)` `on delete cascade`

### Unique constraints
- Primary key only (no extra uniqueness required for local-first writes).

### Check constraints
- `habit_type in ('check', 'count')`

### RLS policies
- Authenticated user can `select/insert/update/delete` own rows (`auth.uid() = user_id`)

### Indexes
- `idx_habits_user_sort_order (user_id, sort_order, created_at)`
- `idx_habits_user_updated_at (user_id, updated_at desc)`

### Local-first notes
- Local habit id remains local identity.
- Remote `id` is stored as local `remoteId` when available.

### Patch issues seen during development
- Existing rows created before `remoteId` persistence require backfill assignment.

## Table: `public.habit_logs`

### Columns
- `id uuid not null default gen_random_uuid()`
- `user_id uuid not null`
- `habit_id uuid not null`
- `log_date date not null`
- `value integer not null default 0`
- `is_completed boolean not null default false`
- `note text null`
- `source text not null default 'manual'`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

### Primary key
- `habit_logs_pkey (id)`

### Foreign keys
- `habit_logs.user_id -> auth.users(id)` `on delete cascade`
- `habit_logs.habit_id -> habits(id)` `on delete cascade`

### Unique constraints
- `(user_id, habit_id, log_date)` for idempotent daily upsert

### Check constraints
- `source in ('manual', 'migration', 'system')`

### RLS policies
- Authenticated user can `select/insert/update/delete` own rows (`auth.uid() = user_id`)

### Indexes
- `idx_habit_logs_user_habit_date_unique unique (user_id, habit_id, log_date)`
- `idx_habit_logs_user_date (user_id, log_date desc)`
- `idx_habit_logs_user_updated_at (user_id, updated_at desc)`

### Local-first notes
- Backfill writes historical rows with `source='migration'`.
- Local writes continue even if remote upsert fails.

### Patch issues seen during development
- `upsert(... onConflict: user_id,habit_id,log_date)` depends on a matching unique index/constraint.

## Table: `public.user_progress`

### Columns
- `user_id uuid not null`
- `level integer not null default 1`
- `total_xp integer not null default 0`
- `current_level_xp integer not null default 0`
- `next_level_xp integer not null default 100`
- `ambar_balance integer not null default 0`
- `total_ambar_earned integer not null default 0`
- `total_ambar_spent integer not null default 0`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

### Primary key
- `user_progress_pkey (user_id)`

### Foreign keys
- `user_progress.user_id -> auth.users(id)` `on delete cascade`

### Unique constraints
- Primary key only.

### Check constraints
- Non-negative totals and level guard:
  - `level >= 1`
  - `total_xp >= 0`
  - `current_level_xp >= 0`
  - `next_level_xp >= 1`
  - `ambar_balance >= 0`
  - `total_ambar_earned >= 0`
  - `total_ambar_spent >= 0`

### RLS policies
- Authenticated user can `select/insert/update` own row (`auth.uid() = user_id`)

### Indexes
- Primary key index on `user_id`

### Local-first notes
- Local progress is authoritative; remote row is mirrored snapshot + safe totals.

### Patch issues seen during development
- Older environments may miss progress columns; patch must add missing columns defensively.

## Table: `public.xp_events`

### Columns
- `id uuid not null default gen_random_uuid()`
- `user_id uuid not null`
- `amount integer not null`
- `source text not null`
- `source_id uuid null`
- `description text null`
- `created_at timestamptz not null default now()`

### Primary key
- `xp_events_pkey (id)`

### Foreign keys
- `xp_events.user_id -> auth.users(id)` `on delete cascade`

### Unique constraints
- None required.

### Check constraints
- `source in ('habit_completed', 'habit_count_progress', 'achievement_unlocked', 'level_bonus', 'journal_entry', 'migration', 'system')`

### RLS policies
- Authenticated user can `select/insert` own rows (`auth.uid() = user_id`)

### Indexes
- `idx_xp_events_user_created_at (user_id, created_at desc)`
- `idx_xp_events_user_source (user_id, source)`

### Local-first notes
- Events are append-only mirrors of local reward/spend decisions.

### Patch issues seen during development
- Source check mismatch can silently block event inserts if `journal_entry` is not allowed.

## Table: `public.currency_events`

### Columns
- `id uuid not null default gen_random_uuid()`
- `user_id uuid not null`
- `amount integer not null`
- `currency text not null default 'ambar'`
- `source text not null`
- `source_id uuid null`
- `description text null`
- `created_at timestamptz not null default now()`

### Primary key
- `currency_events_pkey (id)`

### Foreign keys
- `currency_events.user_id -> auth.users(id)` `on delete cascade`

### Unique constraints
- None required.

### Check constraints
- `currency = 'ambar'`
- `source in ('habit_completed', 'achievement_unlocked', 'shop_purchase', 'refund', 'journal_entry', 'migration', 'system')`

### RLS policies
- Authenticated user can `select/insert` own rows (`auth.uid() = user_id`)

### Indexes
- `idx_currency_events_user_created_at (user_id, created_at desc)`
- `idx_currency_events_user_source (user_id, source)`

### Local-first notes
- Events are append-only mirrors from local wallet mutations.

### Patch issues seen during development
- Source/currency checks can reject otherwise valid local-first write-through payloads if stale.

## Table: `public.user_achievements`

### Columns
- `id uuid not null default gen_random_uuid()`
- `user_id uuid not null`
- `achievement_id text not null`
- `family_id text null`
- `tier text not null`
- `unlocked_at timestamptz not null default now()`
- `reward_xp integer not null default 0`
- `reward_ambar integer not null default 0`
- `reward_applied boolean not null default true`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

### Primary key
- `user_achievements_pkey (id)`

### Foreign keys
- `user_achievements.user_id -> auth.users(id)` `on delete cascade`
- No FK from `achievement_id` to `achievement_definitions` (definitions are local-only in current architecture)

### Unique constraints
- `(user_id, achievement_id)` for idempotent unlock persistence

### Check constraints
- `tier in ('wood', 'stone', 'bronze', 'silver', 'gold', 'diamond', 'prismaticDiamond')`
- `reward_xp >= 0`
- `reward_ambar >= 0`

### RLS policies
- Authenticated user can `select/insert/update` own rows (`auth.uid() = user_id`)

### Indexes
- `idx_user_achievements_user_achievement_unique unique (user_id, achievement_id)`
- `idx_user_achievements_user_unlocked_at (user_id, unlocked_at desc)`
- `idx_user_achievements_family_id (family_id)`

### Local-first notes
- Remote row persistence does not trigger or re-trigger rewards.
- Local `rewardAppliedAchievementIds` remains reward idempotency source.

### Patch issues seen during development
- Some environments had incompatible FK `user_achievements_achievement_id_fkey`; this must be removed.
- Missing unique `(user_id, achievement_id)` can break upsert conflict behavior (`42P10`).

## Table: `public.journal_entries`

### Columns
- `id uuid not null default gen_random_uuid()`
- `user_id uuid not null`
- `entry_date date not null`
- `title text null`
- `content text not null`
- `mood text null`
- `emoji text null`
- `habit_id uuid null`
- `local_habit_id text null`
- `family_id text null`
- `source text not null default 'manual'`
- `is_deleted boolean not null default false`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

### Primary key
- `journal_entries_pkey (id)`

### Foreign keys
- `journal_entries.user_id -> auth.users(id)` `on delete cascade`
- `journal_entries.habit_id -> habits(id)` `on delete set null`

### Unique constraints
- No unique `(user_id, entry_date)` constraint.

### Check constraints
- `source in ('manual', 'migration', 'system')`

### RLS policies
- Authenticated user can `select/insert/update/delete` own rows (`auth.uid() = user_id`)

### Indexes
- `idx_journal_entries_user_date (user_id, entry_date desc)`
- `idx_journal_entries_user_updated (user_id, updated_at desc)`
- `idx_journal_entries_user_local_habit (user_id, local_habit_id)`
- `idx_journal_entries_user_active (user_id, is_deleted, entry_date desc)`

### Local-first notes
- Local diary entries are authoritative.
- Remote soft-delete uses `is_deleted = true`.
- Content is sensitive and must never be logged.

### Patch issues seen during development
- Incompatible `journal_entries_unique_day_per_user` must be dropped (multiple entries/day supported).
- Environments missing table/columns should degrade safely without blocking local diary.

## Local-only markers and state keys (not multi-device sync)

These are local-first progress markers and idempotency guards, stored in local scoped user state:

- `meta.supabaseHabitsBackfillCompletedByUser`
- `meta.supabaseHabitLogsBackfillCompletedByUser`
- `meta.supabaseUserProgressBackfillCompletedByUser`
- `meta.supabaseAchievementsBackfillCompletedByUser`
- `meta.supabaseJournalBackfillCompletedByUser`
- `meta.diaryRewardAppliedDateKeys`
- `profile.achievements.rewardAppliedAchievementIds`
- Storage keys:
  - guest: `user_state_v1`
  - authenticated user scope: `user_state_v1_<userId>` (sanitized)

These markers are intentionally device-local and do not provide cross-device sync guarantees.
