# Supabase Habits Sync - Phase 3A (Best-Effort Local Mirroring)

Date: April 26, 2026  
Branch: `feature/supabase-habits-sync`

## What Is Synced Now

When a user is authenticated in Supabase, local habit mutations in `UserStateStore` now trigger best-effort remote writes to `public.habits`:

- Create habit locally -> remote insert/upsert attempt.
- Edit habit locally -> remote upsert attempt (only when a safe remote UUID mapping exists).
- Archive/unarchive habit locally -> remote upsert attempt (only when a safe remote UUID mapping exists).
- Delete habit locally -> remote delete attempt (only when a safe remote UUID mapping exists).

All remote writes remain scoped by authenticated Supabase session user.

## Local-First Behavior (Still Preserved)

- Local mutation is the source of truth.
- Local save succeeds even if Supabase write fails.
- Remote sync failures are debug warnings only (`kDebugMode`), with no new user-facing error UI.
- Offline behavior remains usable.

## Current Local Habit Model Reality

Rutio still uses map-based habits (`List<Map<String, dynamic>> activeHabits`), not a single typed `Habit` entity.

Common keys observed in create/edit/store flows:

- `id` (fallback aliases read: `habitId`, `uuid`, `key`)
- `name` / `title`
- `familyId`
- `emoji` / `habitEmoji`
- `type` (normalized to `check`/`count`; alternate edit aliases: `trackingType`, `habitType`, `tracking`)
- `target` / `targetCount` / `goal` / `times` / `timesPerWeekTarget`
- `unit` / `unitLabel` / `counterUnit`
- `colorId` (optional, not broadly present yet)
- `reminderEnabled` / `remindersEnabled`
- `reminderTime`
- `archived` / `isArchived`
- `sortOrder` (usually absent; list index is used as fallback for remote `sort_order`)
- `createdAt` / `updatedAt` (optional and inconsistent in local maps)

## Local -> Remote Mapping Used

`HabitRemoteMapper` maps local habit maps to `RemoteHabit`:

- `name/title` -> `name`
- `familyId` -> `family_id`
- `emoji/habitEmoji` -> `emoji`
- normalized local type -> `habit_type` (`check` or `count`)
- local target fields -> `target_count` (count habits always get a positive target; check habits keep only meaningful values)
- `unit/unitLabel/counterUnit` -> `unit` (count habits)
- `colorId/familyColorId` -> `color_id`
- reminder flags -> `reminder_enabled`
- `reminderTime` (normalized to `HH:mm:ss`) -> `reminder_time`
- `archived/isArchived` -> `is_archived`
- `sortOrder` or active list index -> `sort_order`

## Local ID vs Supabase UUID Limitation

Supabase `habits.id` is UUID, while many local habit IDs are non-UUID strings (for example `custom_...` or catalog IDs).

Current safe strategy:

- On create, if local ID is not UUID, remote write inserts without forcing `id` (DB generates UUID).
- No risky local schema migration is done in this phase.
- No persistent `localId <-> remoteId` mapping is stored yet.
- An in-memory session map is used only to continue syncing updates/deletes for habits created during the same app session.

Consequence:

- Updates/archive/delete for older non-UUID local habits can be skipped remotely after app restart (no safe UUID mapping available yet).

## What Remains Local-Only

- Habit logs (`habit_logs`) are not connected yet.
- XP, coins, progression, achievement unlock state, diary/journal data remain local-first and unchanged in this phase.
- No remote-to-local pull, startup download, or two-way sync is enabled yet.

## Why `habit_logs` Is Not Connected Yet

Habit logs require durable habit identity mapping and conflict-safe replay rules (`user_id`, `habit_id`, `log_date` uniqueness). Without persistent habit ID mapping first, log sync can produce orphaned or duplicated remote data.

## Phase 3B Plan

1. Add persistent local `remoteId` mapping (or equivalent local-to-remote identity table).
2. Run a one-time, guarded backfill upload of existing local habits.
3. Add remote habit fetch for clean-device sign-in bootstrap.
4. After identity is stable, wire `habit_logs` with conflict-safe upserts.

## Manual Test Checklist

1. Sign in (or create account) with Supabase-enabled config.
2. Create a habit and confirm local UI updates immediately.
3. Confirm row appears in `public.habits` for current user.
4. Edit/archive/delete and verify local UI still works with no red screen.
5. Verify logout still works.
6. Verify achievements behavior is unchanged.
7. Repeat with network disabled to confirm local-first behavior remains usable.
