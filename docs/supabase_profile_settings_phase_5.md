# Supabase Profile Settings - Phase 5 Foundation

Date: April 27, 2026  
Branch: `feature/supabase-profile-settings`

## Goal

Strengthen the `public.profiles` foundation for account/profile settings metadata while preserving Rutio's local-first behavior.

This phase does **not** introduce multi-device sync, two-way merge, or remote-first profile hydration.

## Local State Isolation (Critical Fix)

Rutio local state is now scoped per authenticated Supabase user on the same device.

### Storage key strategy

- Legacy guest key (unchanged): `user_state_v1`
- Authenticated per-user key: `user_state_v1_<sanitizedUserId>`

`sanitizedUserId` keeps `a-z`, `A-Z`, `0-9`, `_`, `-` and replaces other chars with `_`.

### Auth/local scope behavior

- On app startup, if Supabase session exists, local repository scope is initialized to that user id before first `load()`.
- On sign-in/sign-up/session restoration, store scope switches to the authenticated user key and reloads that scoped state.
- On logout, store scope switches to guest key and reloads guest state.
- On account switch, each account reloads its own scoped local data.

This prevents cross-account leakage of habits, history, achievements, progress, profile, and settings.

### Legacy migration/copy behavior

To preserve Alpha installs safely:

- Legacy key `user_state_v1` is **never auto-deleted**.
- Automatic legacy-to-authenticated copy is currently **disabled** for privacy.
- New authenticated users start with fresh scoped template data unless their scoped key already exists.
- Legacy migration/backfill is deferred to a future explicit, user-safe migration step.

This favors no-data-leak isolation over aggressive migration.

## Current Profile Schema Assumptions Found In Code

### Already used as baseline

- `id` (auth user id, row ownership key)
- `email`
- `display_name`
- `avatar_url`

### Parsed when present (safe optional)

- `preferred_language_code`
- `notifications_enabled`
- `daily_motivation_enabled`
- `marketing_notifications_enabled`
- `daily_motivation_time`
- `last_login_at`
- `last_seen_at`
- `created_at`
- `updated_at`

If optional columns are absent, app behavior remains local-first and writes degrade safely without crashing.

## What Is Written To Supabase In This Phase

All writes are always scoped to the authenticated Supabase user and force profile row identity to `auth.uid()` through current session user id.

### Auth bootstrap writes (best-effort, non-blocking)

- `ensureCurrentProfile()` on session bootstrap/login/signup
- `touchLastLogin()` on sign-in/sign-up/session restoration
- `touchLastSeen()` on auth/session bootstrap events

Failures here are logged in debug only and do not block app startup or auth routing.

### Local profile/settings write-through (best-effort after local save)

- Profile basics updates:
  - `display_name`
  - `avatar_url`
  - `email` (best-effort from current auth/local identity for row safety)
- Preferred language updates:
  - `preferred_language_code`
- Notification settings updates (supported subset only):
  - `notifications_enabled` (maps from local `settings.notifications.enabled`)
  - `daily_motivation_enabled` (maps from local `dailyMotivation`)
  - `marketing_notifications_enabled` (maps from local `marketing`)
  - `daily_motivation_time` (maps from local `dailyMotivationTime`)

Remote failure never rolls back local writes.

## What Remains Local-Only

- Full notification matrix not mapped to `profiles` in this phase:
  - `habitReminders`
  - `dayClosure`
  - `dayClosureTime`
  - `streakRisk`
  - `streakCelebration`
  - `inactivityReengagement`
  - `notification metadata`
- `bio`, `goal`, cosmetic/local profile fields not represented in `profiles`
- XP, coins/currency, achievements, diary/journal, habits, habit logs behavior remains unchanged in this phase
- No two-way profile sync and no remote->local merge policy

## Optional Columns (If Missing) - Suggested SQL

Run only if these columns are missing in your Supabase project:

```sql
alter table public.profiles
  add column if not exists preferred_language_code text,
  add column if not exists notifications_enabled boolean,
  add column if not exists daily_motivation_enabled boolean,
  add column if not exists marketing_notifications_enabled boolean,
  add column if not exists daily_motivation_time text,
  add column if not exists last_login_at timestamptz,
  add column if not exists last_seen_at timestamptz;
```

Recommended (if not already present) for updated timestamps:

```sql
alter table public.profiles
  add column if not exists updated_at timestamptz default now();
```

## Why This Is Not Multi-Device Sync Yet

The app remains local-first by design in this step:

- local state updates still succeed first
- remote writes are best-effort metadata persistence only
- no startup pull/merge from remote profile into local settings state
- no conflict strategy introduced yet

This keeps behavior stable while strengthening Supabase profile coverage safely.

## Manual Test Checklist (Isolation)

1. Sign in as user A.
2. Create/complete a habit.
3. Logout.
4. Sign in as user B.
5. Verify user B does not see user A habits/history/achievements/progress.
6. Create a different habit for user B.
7. Logout.
8. Sign back in as user A and verify only user A data.
9. Sign back in as user B and verify only user B data.
10. Verify Supabase `habits` / `habit_logs` writes still use correct `user_id`.
11. Delete account for one test user and verify only that user's scoped local state is removed.
12. Verify `flutter analyze --no-pub` is clean.

## Next Phase 6 Direction

Phase 6 should focus on remote foundation for progression/currency domains (for example `user_progress`, XP events, and Ambar/currency primitives) with explicit conflict and replay safety, still without breaking local-first guarantees.
