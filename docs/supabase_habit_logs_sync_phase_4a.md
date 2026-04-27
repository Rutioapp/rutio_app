# Supabase Habit Logs Sync - Phase 4A (Best-Effort Local-First Daily Sync)

Date: April 27, 2026  
Branch: `feature/supabase-habit-logs-sync`

## Goal

Mirror local daily habit state changes to `public.habit_logs` without changing Rutio's local-first behavior.

## What Is Synced In Phase 4A

After local habit mutations are saved, Rutio now performs non-blocking best-effort remote upserts to `public.habit_logs` for the affected habit/date:

- check habit complete/incomplete state changes
- check habit skip/unskip state changes
- count habit value updates (increment/decrement/direct set flows)
- count completion state derived from value/target for that day
- both today and non-today date edits already supported in local flows

Remote writes are always scoped to the currently authenticated Supabase user session.

## Local -> Remote Mapping

- `habit_id`: local habit `remoteId` (UUID) only
- `log_date`: date-only `YYYY-MM-DD` using local app day semantics
- `source`: `manual`
- `note`: `null` (no diary/journal text is mapped in this phase)

Value/completion mapping:

- check habit:
  - completed -> `value=1`, `is_completed=true`
  - incomplete/skipped -> `value=0`, `is_completed=false`
- count habit:
  - `value` from local daily count value (integer persisted remotely)
  - `is_completed=true` when not skipped and local completion is true or value reaches target
  - skipped -> `is_completed=false` and current local behavior writes zero value for skip flows

## RemoteId Dependency

Daily habit log sync requires the local habit to have a persisted `remoteId` (mapped to `public.habits.id`).

- If `remoteId` is missing/invalid, sync is safely skipped.
- Local mutation still succeeds.
- Debug warning is printed only in `kDebugMode`.

## Local-First Behavior (Preserved)

- Local mutation/storage remains source of truth.
- Remote sync is fire-and-forget (`unawaited`) and non-blocking.
- Remote sync failures never throw into UI/store mutation flows.
- No user-facing sync error UI is introduced in this phase.

## What Remains Intentionally Local / Not Synced Yet

- full local progress/history data model remains primary
- XP, coins, achievements, diary, journal entries, user progress
- two-way sync/download of logs
- destructive migrations
- hardcoded Supabase URL/keys

## Manual Test Checklist

Run:

```bash
flutter run --dart-define-from-file=.env/dev.json
```

Then validate:

1. Sign in.
2. Ensure target habit has `remoteId` (from Phase 3B/3C).
3. Complete a check habit today.
4. Verify one `public.habit_logs` row exists with `value=1`, `is_completed=true`.
5. Mark it incomplete/unskip cycle if supported and verify row updates.
6. Increment a count habit and verify `value` updates.
7. Reach count target and verify `is_completed=true`.
8. Restart app and repeat one mutation; verify sync still works.
9. Confirm no duplicate rows for same `user_id + habit_id + log_date`.
10. Confirm Home/Weekly/Monthly/Achievements behavior is unchanged.
11. Confirm logout and delete-account flows still work.

## Next Phases

- Phase 4B: backfill historical habit logs from existing local history
- Phase 4C: fetch remote logs on clean device sign-in and merge strategy
