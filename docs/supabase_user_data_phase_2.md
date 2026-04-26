# Supabase User Data Sync - Phase 2 Foundation

Date: April 26, 2026  
Branch: `feature/supabase-user-data-foundation`

## Current Known Supabase Tables (public schema)

- `achievement_definitions`
- `currency_events`
- `habit_logs`
- `habits`
- `journal_entries`
- `profiles`
- `user_achievements`
- `user_progress`
- `xp_events`

## Current Local Data Reality (Rutio)

- The app is local-first and stores user data in `assets/templates/user_state_template.json` + `UserStateStore`.
- Habits are currently map-driven (`List<Map<String, dynamic>> activeHabits`), not a single strongly typed Habit entity.
- Auth identity is synced to local store (`userId`, email, displayName, avatarUrl), but feature data remains local.
- `UserStateStore` remains the source of truth for current habit/diary/achievement behavior in this phase.

## Confirmed Schema Input (April 26, 2026)

### `public.habits` (confirmed)

- `id uuid primary key default gen_random_uuid()`
- `user_id uuid not null references auth.users(id) on delete cascade`
- `name text not null`
- `family_id text nullable`
- `emoji text nullable`
- `habit_type text not null default 'check'` (valid: `check`, `count`)
- `target_count integer nullable`
- `unit text nullable`
- `color_id text nullable`
- `reminder_enabled boolean not null default false`
- `reminder_time time nullable`
- `is_archived boolean not null default false`
- `sort_order integer not null default 0`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

### `public.habit_logs` (confirmed)

- `id uuid primary key default gen_random_uuid()`
- `user_id uuid not null references auth.users(id) on delete cascade`
- `habit_id uuid not null`
- `log_date date not null`
- `value integer not null default 0`
- `is_completed boolean not null default false`
- `note text nullable`
- `source text not null default 'manual'` (valid: `manual`, `migration`, `system`)
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`
- `unique (user_id, habit_id, log_date)`
- RLS scoped by `auth.uid() = user_id`

## Proposed Local-to-Remote Mapping (Foundation)

| Local app area | Candidate remote table | Phase status | Notes |
|---|---|---|---|
| `userState.userId`, `profile.displayName`, `profile.avatarUrl`, `meta.authEmail` | `profiles` | Phase 2A | Safe first integration. |
| `userState.activeHabits[*]` | `habits` | Phase 2A skeleton only, Phase 2B for real sync | Repository prepared, not wired to UI writes yet. |
| Habit completion/skips/count history (`history.*`) | `habit_logs` | Phase 2A foundation only, Phase 2C for real sync | Repository prepared, no UI wiring yet. |
| XP/coins/level/progression (`progression`, `wallet`, `familyXp`) | `user_progress`, `xp_events`, `currency_events` | Deferred to Phase 2D | High risk for double grants and replay. |
| Achievement unlock/progress | `achievement_definitions`, `user_achievements` | Deferred to Phase 2E | Must preserve current achievement engine behavior. |
| Diary entries | `journal_entries` | Deferred to Phase 2F | Needs per-entry ownership and migration rules. |

## Phase Plan

### Phase 2A: Profiles + Repository Skeleton

- Add typed remote models and typed repository results.
- Refine `ProfileRepository` to:
  - `fetchCurrentProfile()`
  - `upsertCurrentProfile(...)`
  - `ensureCurrentProfile(...)`
- Handle missing auth session safely and avoid UI crashes if profile row is missing.
- Add `HabitRepository` skeleton methods scoped by authenticated `user_id`.
- Add `HabitLogRepository` skeleton methods scoped by authenticated `user_id`.
- Keep app behavior local-first.

### Phase 2B: Habits Remote Sync

- Define authoritative `habits` row contract in sync flows.
- Add explicit opt-in sync from local habits to remote habits.
- Add pull strategy with non-destructive merge rules.

### Phase 2C: `habit_logs` Sync

- Add conflict handling for offline writes and retries.
- Prevent duplicate day logs while respecting `(user_id, habit_id, log_date)` uniqueness.

### Phase 2D: `user_progress` + XP/Coins/Level

- Add durable event-based progression sync (`xp_events`, `currency_events`).
- Reconcile totals from events; avoid direct overwrite of local totals.

### Phase 2E: Achievements

- Sync user unlock state to `user_achievements`.
- Keep `achievement_definitions` treated as global/static catalog.

### Phase 2F: Journal Entries

- Add repository for `journal_entries`.
- Support local draft/offline-first with safe conflict timestamps.

## Risks to Manage

- Local data loss during migration if remote overwrite is automatic.
- Multi-user on same device if local state is not partitioned by `user_id`.
- Duplicate habits when local ids and remote ids are not reconciled.
- Offline mode drift and replay conflicts.
- RLS policy mismatches causing silent failures or partial writes.

## Recommended Sync Principles

- Keep local-first behavior until each feature migration is explicit.
- Use explicit, guarded remote writes (no hidden background destructive sync).
- No silent destructive overwrite of local state.
- Scope all user-owned queries/writes by authenticated `user_id`.
- Use timestamps (`created_at`, `updated_at`) for conflict handling and auditability.

## Manual Supabase Checks Required (Developer)

### 1) Constraints and referential checks

- Verify `public.habits.habit_type` is constrained to `check|count`.
- Verify `public.habit_logs.source` is constrained to `manual|migration|system`.
- Verify `public.habit_logs` has `unique (user_id, habit_id, log_date)`.
- Verify FK + cascade behavior for `habits.user_id -> auth.users.id`.
- Verify FK + cascade behavior for `habit_logs.user_id -> auth.users.id`.

### 2) RLS checks

- `habits`: authenticated user can `select/insert/update/delete` only own rows (`user_id = auth.uid()`).
- `habit_logs`: authenticated user can `select/insert/update/delete` only own rows (`user_id = auth.uid()`).
- `profiles`: authenticated user can `select/insert/update` only own row (`id = auth.uid()`).

### 3) Cross-table integrity check requested

- Verify whether `public.habits` also has a unique constraint/index on `(id, user_id)`.
  This matters if downstream constraints or joins expect `(habit_id, user_id)` pairing guarantees.

## Foundation Scope Boundary (Intentional)

- Not migrating `habit_logs`, `journal_entries`, `user_progress`, `xp_events`, `currency_events`, `user_achievements`, or achievements logic in this step.
- Not replacing local `UserStateStore` as source of truth.
- Not changing existing UI behavior except internal profile bootstrap safety.
