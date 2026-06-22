# Habits Supabase Sync Audit

Date: 2026-06-22

## Goal

Audit the current local-first habits architecture and the current Supabase write-through structure before implementing any remote pull/merge for habits.

This document describes the current state only. It does not propose behavior changes in this phase.

## Scope Guardrails

- Do not implement habits remote pull/merge yet.
- Do not change app behavior, UI, or Supabase schema in this phase.
- Do not delete or migrate data.
- Diary V2 is referenced only as a comparison pattern for future work.

## 1. Current Local Habits Architecture

### Local owner and storage

- Habits live inside scoped user-state JSON stored through:
  - [lib/data/local/user_state_storage.dart](/D:/dev/alpha/rutio_app/lib/data/local/user_state_storage.dart)
  - [lib/data/repositories/user_state_repository.dart](/D:/dev/alpha/rutio_app/lib/data/repositories/user_state_repository.dart)
- The owning runtime store is [lib/stores/user_state_store.dart](/D:/dev/alpha/rutio_app/lib/stores/user_state_store.dart), mainly via:
  - [lib/stores/user_state_store_habits.dart](/D:/dev/alpha/rutio_app/lib/stores/user_state_store_habits.dart)
  - [lib/stores/user_state_store_habit_progress.dart](/D:/dev/alpha/rutio_app/lib/stores/user_state_store_habit_progress.dart)
  - [lib/stores/user_state_store_core.dart](/D:/dev/alpha/rutio_app/lib/stores/user_state_store_core.dart)
  - [lib/stores/user_state_store_achievements.dart](/D:/dev/alpha/rutio_app/lib/stores/user_state_store_achievements.dart)
- The persisted root shape is `root.userState`.
- Active habits are stored in `userState.activeHabits`.
- Historical daily state is stored in `userState.history`.
- Daily reward idempotency is stored in `userState.daily.habitsCompletedToday`.

### Local habit shape

Current habits are map-based, not a dedicated Dart `Habit` model. Common fields found in `activeHabits`:

- Identity and sync:
  - `id`
  - `habitId`
  - `remoteId`
- Display/config:
  - `name`
  - `description`
  - `emoji`
  - `familyId`
  - `allFamilies`
  - `type`
  - `unit`
  - `target`
  - `schedule`
  - `routine`
  - `reminderEnabled`
  - `reminderTime`
  - `colorId`
- Daily state:
  - `progress`
  - `doneToday`
  - `skippedToday`
- Lifecycle/meta:
  - `createdAt`
  - `updatedAt` is not consistently persisted locally
  - `archived`
  - `isCustom`

### Files handling create/update/delete/progress

- Habit create:
  - `_addHabitFromCatalog(...)`
  - `_addCustomHabit(...)`
  - in [lib/stores/user_state_store_habits.dart](/D:/dev/alpha/rutio_app/lib/stores/user_state_store_habits.dart)
- Habit delete:
  - `_deleteHabitById(...)`
  - in [lib/stores/user_state_store_habits.dart](/D:/dev/alpha/rutio_app/lib/stores/user_state_store_habits.dart)
- Habit reorder:
  - `_reorderVisibleHabits(...)`
  - in [lib/stores/user_state_store_habits.dart](/D:/dev/alpha/rutio_app/lib/stores/user_state_store_habits.dart)
- Habit plan/schedule updates:
  - `_updateHabitPlan(...)`
  - in [lib/stores/user_state_store_habits.dart](/D:/dev/alpha/rutio_app/lib/stores/user_state_store_habits.dart)
- Habit detail edits including archive toggle:
  - `_updateHabitDetailsFromEdit(...)`
  - in [lib/stores/user_state_store_habits.dart](/D:/dev/alpha/rutio_app/lib/stores/user_state_store_habits.dart)
- Current-day completion/progress:
  - `_completeHabit(...)`
  - `_setCountHabitValue(...)`
  - in [lib/stores/user_state_store_habits.dart](/D:/dev/alpha/rutio_app/lib/stores/user_state_store_habits.dart)
- Historical day edits:
  - `_toggleHabitDoneForDate(...)`
  - `_setHabitCompletionForKey(...)`
  - `_setHabitSkipForKey(...)`
  - `_setCountHabitValueForDate(...)`
  - in [lib/stores/user_state_store_habits.dart](/D:/dev/alpha/rutio_app/lib/stores/user_state_store_habits.dart)

### Active, archived, and deleted representation

- Active habits are all rows in `userState.activeHabits` that are not archived.
- Archived habits remain in `userState.activeHabits` with `archived == true`.
- UI and selectors treat archived habits as not expected for the day.
- Local delete removes the habit from `activeHabits` entirely.
- Local delete can also purge historical records via `_removeHabitFromHistory(...)`.
- There is no durable local tombstone row for deleted habits.
- Some code checks `deleted` / `isDeleted` during backfill eligibility, but active local habits are not currently represented as persisted soft-deleted rows. That means delete semantics are partly implicit and partly unclear.

### Check habits vs count habits

- Habit type is normalized to:
  - `check`
  - `count`
- Check habits:
  - typically use `target = 1`
  - daily completion is represented by `doneToday` and history completion booleans
- Count habits:
  - use numeric `target`
  - current-day value is stored in `progress`
  - historical per-day value is stored in `history.habitCountValues[dateKey][habitId]`
  - completion is derived from `value >= target`

### Daily history and progress storage

History lives under `userState.history` and is normalized in [lib/stores/user_state_store_core.dart](/D:/dev/alpha/rutio_app/lib/stores/user_state_store_core.dart).

- `history.habitCompletions[YYYY-MM-DD][habitId] = bool`
- `history.habitCountValues[YYYY-MM-DD][habitId] = num`
- `history.habitSkips[YYYY-MM-DD][habitId] = bool`
- `history.habitCompletionTimes[YYYY-MM-DD][habitId] = epochMillis`
- Daily notes buckets are also probed during habit-log backfill:
  - `habitLogNotes`
  - `habitNotes`
  - `habitDailyNotes`
  - `habitCompletionNotes`

Important nuance:

- Current-day in-memory habit state is hydrated from history when the active view date changes.
- `_ensureDailyReset(...)` snapshots the previous day into history, clears current-day counters, and resets `doneToday` / `skippedToday`.

### Streak calculation

Streaks are calculated from history, not stored as first-class persisted counters.

- Snapshot API:
  - `habitStreakSnapshotForHabitId(...)`
  - `habitStreakSnapshots`
  - `familyConsistencySnapshots`
  - in [lib/stores/user_state_store.dart](/D:/dev/alpha/rutio_app/lib/stores/user_state_store.dart)
- Implementation:
  - `_extractHabitDoneCountsByDay(...)`
  - `_extractFamilyDoneCountsByDay(...)`
  - `_computeCurrentStreak(...)`
  - `_computeBestStreak(...)`
  - in [lib/stores/user_state_store_achievements.dart](/D:/dev/alpha/rutio_app/lib/stores/user_state_store_achievements.dart)

Current streak rules observed:

- Check habits count a day as done when `habitCompletions[day][habitId] == true`.
- Count habits count a day as done when `habitCountValues[day][habitId] > 0` for streak extraction.
- Family consistency counts a day as done if any scheduled habit in that family was done on that day.
- Streaks are recomputed from history each time; there is no remote streak table.

Risk note:

- Count-habit streak extraction currently uses `> 0`, while completion/reward logic uses `value >= target`. That mismatch matters for future merge logic because a pulled remote partial count could affect streaks differently than completion rewards.

### XP and rewards from habit completion

Habit completion can trigger:

- XP / wallet updates in local state
- level progression recalculation
- level-up celebration queueing
- achievement unlock recalculation
- achievement reward application
- best-effort remote progress/event mirroring

Main implementation files:

- Rewards/progress:
  - [lib/stores/user_state_store_habit_progress.dart](/D:/dev/alpha/rutio_app/lib/stores/user_state_store_habit_progress.dart)
- Achievements and streak-derived unlocks:
  - [lib/stores/user_state_store_achievements.dart](/D:/dev/alpha/rutio_app/lib/stores/user_state_store_achievements.dart)

Current reward behavior:

- Check habit completion grants fixed reward:
  - XP: `10`
  - coins: `5`
- Count habit reward is granted when it crosses completion and daily reward was not already granted.
- Daily reward idempotency is guarded by `userState.daily.habitsCompletedToday[habitId]`.
- Achievement reward idempotency is guarded by `profile.achievements.rewardAppliedAchievementIds`.

### Demo profile and authenticated user separation

There are two different isolation layers:

- Local storage scope:
  - guest scope uses `user_state_v1`
  - authenticated scope uses `user_state_v1_<sanitizedUserId>`
  - implemented in [lib/data/local/user_state_storage.dart](/D:/dev/alpha/rutio_app/lib/data/local/user_state_storage.dart)
- Runtime/store scope switching:
  - [lib/data/repositories/user_state_repository.dart](/D:/dev/alpha/rutio_app/lib/data/repositories/user_state_repository.dart)
  - [lib/stores/user_state_store_core.dart](/D:/dev/alpha/rutio_app/lib/stores/user_state_store_core.dart)

Demo profile:

- Demo runtime profile is controlled by [lib/devtools/rutio_runtime_profile.dart](/D:/dev/alpha/rutio_app/lib/devtools/rutio_runtime_profile.dart)
- Demo seeding uses dedicated scope `demo_user` via [lib/devtools/demo_seed/demo_seed_runner.dart](/D:/dev/alpha/rutio_app/lib/devtools/demo_seed/demo_seed_runner.dart)
- Demo state is kept in its own scoped local state and should not be merged with authenticated Supabase data.

Authenticated state safety already present:

- Save calls are blocked if payload user id does not match the active local scope.
- Most Supabase sync services also require local user id to match the authenticated Supabase user.

## 2. Current Supabase / Backend Architecture For Habits

### Repository and sync files that exist today

Habits:

- Repository:
  - [lib/data/repositories/habit_repository.dart](/D:/dev/alpha/rutio_app/lib/data/repositories/habit_repository.dart)
- Remote model:
  - [lib/data/models/remote/remote_habit.dart](/D:/dev/alpha/rutio_app/lib/data/models/remote/remote_habit.dart)
- Mapper:
  - [lib/data/mappers/habit_remote_mapper.dart](/D:/dev/alpha/rutio_app/lib/data/mappers/habit_remote_mapper.dart)
- Sync service:
  - [lib/data/services/habit_sync_service.dart](/D:/dev/alpha/rutio_app/lib/data/services/habit_sync_service.dart)

Habit logs:

- Repository:
  - [lib/data/repositories/habit_log_repository.dart](/D:/dev/alpha/rutio_app/lib/data/repositories/habit_log_repository.dart)
- Remote model:
  - [lib/data/models/remote/remote_habit_log.dart](/D:/dev/alpha/rutio_app/lib/data/models/remote/remote_habit_log.dart)
- Mapper:
  - [lib/data/mappers/habit_log_remote_mapper.dart](/D:/dev/alpha/rutio_app/lib/data/mappers/habit_log_remote_mapper.dart)
- Sync service:
  - [lib/data/services/habit_log_sync_service.dart](/D:/dev/alpha/rutio_app/lib/data/services/habit_log_sync_service.dart)

Progress and rewards related to habits:

- Progress snapshot sync:
  - [lib/data/services/user_progress_sync_service.dart](/D:/dev/alpha/rutio_app/lib/data/services/user_progress_sync_service.dart)
  - [lib/data/repositories/user_progress_repository.dart](/D:/dev/alpha/rutio_app/lib/data/repositories/user_progress_repository.dart)
- XP event mirror:
  - [lib/data/repositories/xp_event_repository.dart](/D:/dev/alpha/rutio_app/lib/data/repositories/xp_event_repository.dart)
- Currency event mirror:
  - [lib/data/repositories/currency_event_repository.dart](/D:/dev/alpha/rutio_app/lib/data/repositories/currency_event_repository.dart)

Schema reference:

- [docs/supabase_backend_schema_reference.md](/D:/dev/alpha/rutio_app/docs/supabase_backend_schema_reference.md)

### Supabase tables currently used for habits/progress/user state

#### `public.habits`

Appears to store one remote habit row per local habit mirror.

Columns used by app mapping:

- `id`
- `user_id`
- `name`
- `family_id`
- `emoji`
- `habit_type`
- `target_count`
- `unit`
- `color_id`
- `reminder_enabled`
- `reminder_time`
- `is_archived`
- `sort_order`
- `created_at`
- `updated_at`

Important current meaning:

- Remote `id` is the Supabase UUID.
- Local habit identity remains the local `id`.
- Local app persists the remote UUID back into local habit `remoteId`.

#### `public.habit_logs`

Appears to store one daily remote mirror row per `user + habit + day`.

Columns used:

- `id`
- `user_id`
- `habit_id`
- `log_date`
- `value`
- `is_completed`
- `note`
- `source`
- `created_at`
- `updated_at`

Important current meaning:

- `habit_id` is the remote habit UUID, not the local habit id.
- The app writes logs with upsert conflict key `user_id,habit_id,log_date`.

#### `public.user_progress`

Appears to store mirrored aggregate progression snapshot.

Columns used:

- `user_id`
- `level`
- `total_xp`
- `current_level_xp`
- `next_level_xp`
- `ambar_balance`
- `total_ambar_earned`
- `total_ambar_spent`
- `created_at`
- `updated_at`

Important current meaning:

- This is a mirrored snapshot, not the source of truth.
- The repository may fetch existing remote totals first to accumulate earned/spent deltas.

#### `public.xp_events`

Appears to store append-only mirrored XP events.

Columns used:

- `id`
- `user_id`
- `amount`
- `source`
- `source_id`
- `description`
- `created_at`

Important current meaning:

- Current habit-related sources map to `habit_completed` or `habit_count_progress`.
- Events are inserted, not merged.

#### `public.currency_events`

Appears to store append-only mirrored currency events.

Columns used:

- `id`
- `user_id`
- `amount`
- `currency`
- `source`
- `source_id`
- `description`
- `created_at`

Important current meaning:

- Habit-related currency source is normalized to `habit_completed`.
- Events are inserted, not merged.

### Stable local identifiers available today

Current local identity options:

- Local habit stable id: `activeHabits[].id`
- Local remote mapping field: `activeHabits[].remoteId`
- Historical progress identity:
  - habit-local id + date key
  - stored under history maps

Remote identity options:

- `habits.id` is a stable remote UUID
- `habit_logs.id` exists but daily row identity is effectively `user_id + habit_id + log_date`
- `user_progress.user_id` is the primary key

Important gap:

- `public.habits` does not currently store the local habit id as a dedicated `local_id` column.
- That means future remote pull cannot match purely by stable local id at the database level today.
- Matching will depend on local `remoteId` when present, or weaker heuristics if it is missing.

### Timestamp availability and reliability for conflict resolution

Available remote timestamps:

- `habits.created_at`
- `habits.updated_at`
- `habit_logs.created_at`
- `habit_logs.updated_at`
- `user_progress.created_at`
- `user_progress.updated_at`
- `xp_events.created_at`
- `currency_events.created_at`

Current local timestamp situation:

- `createdAt` is often present on habits.
- `updatedAt` is not consistently maintained on local habits.
- Historical habit completion dates are stored by date key, not by per-row last-updated timestamp.
- `habitCompletionTimes` stores completion epoch for some days, but only for done-state timing, not general row mutation timing.

Assessment:

- Remote timestamps are useful but not sufficient alone.
- Local habits and local history do not currently provide a reliable general-purpose `updatedAt` for deterministic two-way conflict resolution.
- `user_progress.updated_at` is not enough to resolve per-habit or per-day progress conflicts.

### Delete semantics in backend

- Remote habit delete is currently a hard delete through `HabitRepository.deleteHabitForCurrentUser(...)`.
- Remote habit archive is currently represented as `habits.is_archived = true`.
- Remote habit log rows are upserted; delete support exists in repository/service but is not the main current path for habit progress changes.
- Local habit delete removes the local row and may purge local history.
- There is no confirmed remote soft-delete tombstone for habits.

Assessment:

- Archive semantics are clear.
- Delete semantics are destructive and non-tombstoned.
- For future pull/merge, remote missing habit cannot safely be interpreted as “delete locally.”

## 3. Current Sync Behavior

### What already pushes local -> Supabase

Already implemented:

- Habit creation pushes to `public.habits`
- Habit updates push to `public.habits`
- Habit archive toggles push to `public.habits`
- Habit delete calls remote delete in `public.habits`
- Habit completion / skip / count-value changes push to `public.habit_logs`
- Progress and reward totals push to `public.user_progress`
- XP rewards insert into `public.xp_events`
- Currency rewards insert into `public.currency_events`
- Auth-time backfill uploads:
  - habits without `remoteId`
  - historical habit logs
  - user progress snapshot

### What happens on habit create/update/delete

Create:

- Local habit is added to `activeHabits`.
- Store is saved first.
- Then `HabitSyncService.syncHabitCreated(...)` runs best-effort and non-blocking.
- If the remote insert returns a UUID, the store persists it locally into `remoteId`.

Update:

- Local habit is updated and saved first.
- Then `HabitSyncService.syncHabitUpdated(...)` runs best-effort.
- If the habit changed archived state, `syncHabitArchived(...)` is used instead.

Delete:

- Local habit is removed from `activeHabits`.
- Optional history purge runs locally.
- Store is saved first.
- Then `HabitSyncService.syncHabitDeleted(...)` tries remote hard delete if a `remoteId` mapping is available.

Important current gaps:

- `_updateHabitPlan(...)` updates local schedule/routine but does not currently trigger remote habit sync.
- `_reorderVisibleHabits(...)` updates local order but does not currently trigger remote habit sync.
- That means some habit metadata can diverge between local and remote even before remote pull exists.

### What happens on habit completion / progress update

Check habits:

- `completeHabit(...)` marks current-day local state done, writes history, applies rewards, recalculates achievements, saves, then queues:
  - habit log sync
  - progress snapshot sync
  - XP event insert
  - currency event insert
  - achievement sync if needed

Count habits:

- `setCountHabitValue(...)` updates local numeric progress, derives completion, writes history, may apply rewards once, recalculates achievements, saves, then queues the same best-effort sync family.

Past-date edits:

- Historical completion/skip/count value edits save locally and then queue best-effort habit-log sync for the affected date.
- Past-date edits do not trigger XP or coin recalculation in the same way current-day completion does.

### What happens with count habits

- Count habits are mirrored to `habits.habit_type = 'count'` with `target_count` and `unit`.
- Daily values are mirrored to `habit_logs.value`.
- Completion is mirrored to `habit_logs.is_completed`.
- Current streak extraction treats `value > 0` as done, while reward logic uses `value >= target`.

### What happens with archived / deleted habits

Archived:

- Local archive keeps the row in `activeHabits` with `archived = true`.
- Remote archive mirrors `is_archived = true`.
- History is retained locally.

Deleted:

- Local delete removes the habit row entirely.
- History may also be purged locally when `purgeHistory = true`.
- Remote delete is a hard delete if `remoteId` exists.
- No local or remote tombstone is kept.

### What happens if auth is missing

Across sync services, if there is no authenticated Supabase user:

- local mutation still succeeds
- remote sync is skipped
- no exception should reach UI/store mutation flow

This pattern exists in:

- [lib/data/services/habit_sync_service.dart](/D:/dev/alpha/rutio_app/lib/data/services/habit_sync_service.dart)
- [lib/data/services/habit_log_sync_service.dart](/D:/dev/alpha/rutio_app/lib/data/services/habit_log_sync_service.dart)
- [lib/data/services/user_progress_sync_service.dart](/D:/dev/alpha/rutio_app/lib/data/services/user_progress_sync_service.dart)

### What happens if Supabase fails

- Remote calls are best-effort and generally `unawaited` from user-facing mutation flows.
- Local save remains authoritative.
- Failures are debug logged.
- No user-facing sync error UI is added in current habit sync phases.

### Whether any remote pull already exists

For habits:

- Repository fetch methods exist:
  - `HabitRepository.fetchHabitsForCurrentUser()`
  - `HabitLogRepository.fetchLogsForDateRange(...)`
  - `HabitLogRepository.fetchLogsForHabit(...)`
- But no habits remote-to-local merge path is currently wired into the store.
- No manual refresh for habits exists.

For comparison only:

- Diary V2 has remote pull/merge and manual refresh.
- Habits do not.

### Whether any startup sync already exists

Yes, but only for local -> remote backfill after authenticated profile sync.

Current auth startup chain in [lib/application/auth/auth_controller.dart](/D:/dev/alpha/rutio_app/lib/application/auth/auth_controller.dart):

1. Switch local scope to authenticated user id.
2. Apply Supabase identity into local state.
3. Fire background backfills:
   - `syncSupabaseUserProgressBackfillOnce()`
   - `syncExistingLocalHabitsOnce()`
   - `syncExistingLocalHabitLogsOnce()`
   - `syncExistingLocalJournalEntriesOnce()`
   - `syncExistingLocalAchievementsOnce()`

Important distinction:

- This is startup backfill, not startup pull.
- It uploads local data to remote when eligible.

## 4. Risks Before Implementing Remote Pull / Merge

### Identity and duplication risks

- Missing dedicated remote `local_id` column means future matching cannot rely on stable local id in Supabase.
- Habits without `remoteId` could be duplicated if remote pull uses weak fingerprint matching.
- Habit backfill already uses a fingerprint heuristic for duplicate avoidance; pull/merge must not rely on the same heuristic as an authoritative identity rule.

### Delete / archive risks

- Remote missing habit is ambiguous because current delete is hard delete and archive is a separate flag.
- Pull logic could incorrectly revive locally deleted habits.
- Pull logic could incorrectly delete local habits just because remote rows are absent.
- Archived habits are still local rows; merging them carelessly could unarchive or duplicate them.

### Progress and history risks

- Local history is keyed by local habit id + date.
- Remote logs are keyed by remote habit id + date.
- If `remoteId` is missing or wrong, pulled logs could attach to the wrong habit or become orphaned.
- Count-habit logs are more sensitive than check habits because value and completion can diverge.
- Older remote `habit_logs.value` must not overwrite newer local count values.
- Current local streak extraction for count habits uses `value > 0`, which can disagree with completion rules.

### Timestamp and recency risks

- Local habits do not have consistently reliable `updatedAt`.
- History rows do not have a general mutation timestamp.
- Remote `updated_at` exists, but local freshness is not directly comparable in many cases.
- Pulling remote state over local state without clear recency evidence risks overwriting newer local changes.

### XP / rewards / achievements risks

- Habit pull must not re-trigger XP, coins, achievements, or level-ups.
- Current reward idempotency keys are local and device-scoped, not a cross-device sync contract.
- Re-importing historical completion could duplicate:
  - XP events
  - currency events
  - achievement rewards
  - level-up reward side effects

### Demo / account separation risks

- Demo profile uses `demo_user` scoped local data and should never merge with authenticated remote rows.
- Guest scope and authenticated scope are separate local stores; pull must respect active scope strictly.
- Any fallback path that ignores `expectedLocalUserId` or scope guards could mix accounts.

### Existing divergence risks already present

- Schedule/routine edits in `_updateHabitPlan(...)` are local-only today.
- Habit reorder is local-only today.
- Future pull must decide whether remote or local should win for these fields if they diverge.

## 5. Proposed Implementation Plan For Later Phases

These are small future phases only. They are not part of this audit phase.

### Phase: `feature/habits-remote-fetch-repository`

Goal:

- Add explicit store-level read path for remote habits and remote habit logs without merging into local state yet.

Likely files:

- [lib/data/repositories/habit_repository.dart](/D:/dev/alpha/rutio_app/lib/data/repositories/habit_repository.dart)
- [lib/data/repositories/habit_log_repository.dart](/D:/dev/alpha/rutio_app/lib/data/repositories/habit_log_repository.dart)
- new service, likely `lib/data/services/habit_pull_service.dart`
- possibly new audit/helper tests under `test/data/repositories/` or `test/stores/`

Main risks:

- reading too broad a date range for habit logs
- assuming remote rows can be matched without `remoteId`
- accidentally changing behavior while introducing fetch helpers

Focused tests to add:

- repository fetch returns only current user rows
- habits fetch preserves `is_archived`
- habit logs fetch preserves `value`, `is_completed`, and date ordering
- fetch with missing auth degrades safely

Validation commands:

- `flutter analyze`
- focused tests for new fetch service/repositories only

### Phase: `feature/habits-remote-pull-merge`

Goal:

- Implement conservative remote-to-local merge for habits and daily logs without deleting local-only data.

Likely files:

- new merge service, likely `lib/data/services/habit_pull_merge_service.dart`
- [lib/stores/user_state_store_habits.dart](/D:/dev/alpha/rutio_app/lib/stores/user_state_store_habits.dart)
- [lib/stores/user_state_store_core.dart](/D:/dev/alpha/rutio_app/lib/stores/user_state_store_core.dart)
- possibly small comparison helpers under `lib/data/mappers/`

Main risks:

- duplicate habits
- reviving deleted habits
- overwriting fresher local count progress
- stale remote archive state changing active local habits
- attaching remote logs to wrong local habit
- triggering rewards or achievements during merge

Focused tests to add:

- remote habit with known `remoteId` updates local fields conservatively
- remote habit missing locally adds a new local habit only when safe
- local habit missing remotely is retained
- archived local habit is not unintentionally revived
- count log merge prefers newer/higher-confidence local values
- merge does not mutate XP, coins, achievements, or pending overlays

Validation commands:

- `flutter analyze`
- focused store/service tests only

### Phase: `feature/habits-manual-refresh-sync`

Goal:

- Add explicit user-triggered refresh for habits after conservative pull/merge exists.

Likely files:

- store methods in [lib/stores/user_state_store.dart](/D:/dev/alpha/rutio_app/lib/stores/user_state_store.dart)
- implementation in [lib/stores/user_state_store_habits.dart](/D:/dev/alpha/rutio_app/lib/stores/user_state_store_habits.dart)
- whichever non-Diary habits screen owns refresh entry point

Main risks:

- double-running pull while local save is in flight
- user-visible stale state if refresh completes after another local mutation
- accidental UI coupling before merge rules are stable

Focused tests to add:

- refresh no-ops safely without auth
- refresh is single-flight
- refresh does not clear local state on remote failure

Validation commands:

- `flutter analyze`
- focused refresh/store tests

### Phase: `feature/habits-controlled-sync-policy`

Goal:

- Introduce explicit habit sync policy similar in spirit to Diary V2: cooldowns, single-flight guards, and controlled startup behavior.

Likely files:

- [lib/stores/user_state_store.dart](/D:/dev/alpha/rutio_app/lib/stores/user_state_store.dart)
- [lib/stores/user_state_store_habits.dart](/D:/dev/alpha/rutio_app/lib/stores/user_state_store_habits.dart)
- [lib/application/auth/auth_controller.dart](/D:/dev/alpha/rutio_app/lib/application/auth/auth_controller.dart)

Main risks:

- startup race conditions with existing backfills
- re-entrant merge while current-day completion is being saved
- policy differences between demo, guest, and authenticated scopes

Focused tests to add:

- startup does not run pull during guest/demo mismatch
- pull cooldown is respected
- active scope change cancels or ignores stale pull results

Validation commands:

- `flutter analyze`
- focused auth/store tests

## 6. Recommended Conservative Merge Rules For Future Implementation

These are recommended rules, not current behavior.

### Habit identity rules

- Match habits by persisted stable local mapping first:
  - local `remoteId` <-> remote `habits.id`
- If a future schema adds remote `local_id`, prefer that as first-class match key.
- Do not use fingerprint matching as the primary merge key once pull exists.

### Habit existence rules

- Remote habit missing locally can be added only when identity is clear and scope is safe.
- Local habit missing remotely must be kept locally.
- Do not delete local habits just because remote is missing.
- Do not revive locally deleted or archived habits unless explicit rules are defined.

### Field precedence rules

- Prefer local when timestamps are missing or ambiguous.
- Prefer remote only when remote `updated_at` is clearly newer and the local field is not known to be fresher.
- Treat schedule, reorder, and archive fields carefully because local-only divergence already exists today.

### Progress / history rules

- Merge progress/history by resolved habit identity + date.
- Check habits:
  - remote `is_completed=true` can fill a missing local completion for that date
  - remote absence must not erase local history
- Count habits:
  - never overwrite a local count value with an older or less specific remote value
  - if both sides exist and recency is unclear, prefer local
- Skips should never silently erase confirmed local completions.

### Reward and achievement rules

- Pull/merge must not trigger:
  - XP gains
  - coin gains
  - achievement rewards
  - level-up rewards
  - unlock overlays
- Merge should update state only, not replay reward side effects.

### Scope and safety rules

- Never merge remote authenticated data into guest scope.
- Never merge remote authenticated data into demo scope.
- Enforce active local scope user id == authenticated Supabase user id before any pull.
- Single-flight the merge path and ignore stale results after scope switch.

## 7. Final Recommended Next Phase

Recommended next phase:

- `feature/habits-remote-fetch-repository`

Why this first:

- It is the smallest safe step.
- It creates explicit remote read primitives without changing habit behavior.
- It lets us inspect real remote payload shapes and edge cases before any merge logic touches local history, streaks, or rewards.
- It reduces risk before building the more sensitive `feature/habits-remote-pull-merge` phase.

## Current-State Summary

- Habits are local-first and stored as map-based rows in scoped user-state JSON.
- Supabase already receives best-effort habit, habit-log, progress, XP, and currency writes.
- Auth startup already performs local-to-remote backfill for habits and logs.
- No habits remote pull/merge exists today.
- The biggest blockers for safe pull/merge are identity, delete semantics, local timestamp gaps, and reward/streak sensitivity.
