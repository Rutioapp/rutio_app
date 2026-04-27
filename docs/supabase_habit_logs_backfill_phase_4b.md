# Supabase Habit Logs Backfill - Phase 4B (Safe Historical Local Backfill)

Date: April 27, 2026  
Branch: `feature/supabase-habit-logs-backfill`

## Goal

Backfill existing local habit history into `public.habit_logs` with safe, non-blocking, best-effort behavior while preserving Rutio's local-first model.

## What Historical Backfill Does

Phase 4B reads local history day maps and uploads historical habit log rows with upsert semantics:

- `history.habitCompletions[YYYY-MM-DD][habitId]`
- `history.habitSkips[YYYY-MM-DD][habitId]`
- `history.habitCountValues[YYYY-MM-DD][habitId]`
- optional local note maps when present (kept `null` when absent)

For each discovered habit/date candidate, Rutio attempts to upsert into `public.habit_logs` using:

- unique conflict target: `user_id,habit_id,log_date`
- `source='migration'`
- date-only `log_date` (`YYYY-MM-DD`)

The backfill is best-effort:

- no startup/UI blocking
- no throw into UI/store flows
- per-row failures do not stop the whole run

## RemoteId Dependency

Only habits with a valid persisted `remoteId` are uploaded.

- If a history row belongs to a habit without valid `remoteId`, it is skipped safely.
- Skipped rows are counted in summary as `skippedCount` (not failures).

## Completion Marker (Per Supabase User)

Backfill completion is tracked per authenticated user in local metadata:

- `userState.meta.supabaseHabitLogsBackfillCompletedByUser[userId] = true`

Rules:

- mark complete when `failedCount == 0`
- this includes the case of zero candidates
- do not mark complete when failures occur
- marker is per-user to support multiple Supabase users on one device

## Auto-Run Strategy

Phase 4B auto-runs once per authenticated user in a non-blocking chain after profile/identity sync:

1. Phase 3C habit backfill (`syncExistingLocalHabitsOnce`) runs first to give habits a chance to persist `remoteId`.
2. Phase 4B habit logs backfill (`syncExistingLocalHabitLogsOnce`) runs immediately after, still non-blocking.

This keeps the app local-first and avoids startup navigation delays.

## Mapping Rules Used

- check habit:
  - completed -> `value=1`, `is_completed=true`
  - skipped/incomplete -> `value=0`, `is_completed=false`
- count habit:
  - `value` from local daily count value
  - skipped -> forced `value=0`, `is_completed=false`
  - when target exists: `is_completed=true` if value reaches target (or existing completion state is true)
  - when target is absent: fall back to existing completion state
- note:
  - `null` unless local note exists

Because `public.habit_logs` has no skip column, skipped days are represented as incomplete rows (`value=0`, `is_completed=false`) with `source='migration'`.

## Duplicate Prevention

Duplicates are prevented by design:

- database unique constraint: `(user_id, habit_id, log_date)`
- repository upsert conflict target: `user_id,habit_id,log_date`

Re-running backfill or mutating old days updates the same row instead of creating duplicates.

## What Remains Intentionally Local / Not Synced

- local history remains source of truth in this phase
- no two-way sync/download merge yet
- no XP/coins/achievements/user_progress backfill
- no diary/journal migration
- no destructive migrations

## Next Phases

- Phase 4C: remote habit_logs fetch/download and clean-device hydration strategy
- Phase 5: user_progress + XP/coins/level sync scope
