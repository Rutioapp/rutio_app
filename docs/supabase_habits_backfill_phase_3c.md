# Supabase Habits Backfill - Phase 3C (One-Time Local Upload)

Date: April 26, 2026  
Branch: `feature/supabase-habits-backfill`

## Goal

Backfill existing local habits that were created before `remoteId` support so they can participate in ongoing best-effort remote mirroring.

## What Backfill Does

- Scans local `activeHabits` for entries that are missing `remoteId`.
- Keeps local-first behavior: local data remains source of truth.
- Uploads eligible habits to `public.habits` through `HabitRepository.upsertHabitForCurrentUser(...)`.
- Persists returned remote UUID into local habit as `remoteId`.
- Continues processing even when a single habit upload fails.
- Produces a summary:
  - `totalCandidates`
  - `uploadedCount`
  - `skippedCount`
  - `failedCount`
- Uses debug logging only (`debugPrint` in `kDebugMode`).

## What Backfill Intentionally Does Not Do

- No two-way sync.
- No remote habit download/fetch bootstrap.
- No `habit_logs` sync.
- No XP/coins/achievements/journal/diary remote sync.
- No hardcoded Supabase URL/keys.
- No user-facing sync UI added in this phase.

## Eligibility Rules

- Only habits without `remoteId` are candidates.
- Invalid/deleted habits are skipped safely.
- Archived habits are still eligible if they exist in local habits list.

## Duplicate Avoidance Strategy

Backfill first fetches current remote habits for the authenticated user and builds a fingerprint index (name, family, emoji, type, target, unit, color, reminder fields, archive flag, sort order).

- If a candidate matches an existing remote fingerprint, backfill reuses that remote row id and only writes `remoteId` locally.
- If no match exists, it inserts/upserts remotely.

This is best-effort duplicate prevention (not a strict uniqueness guarantee), but it reduces duplicate inserts on retries/crash-recovery scenarios.

## Local `remoteId` Persistence

When a remote UUID is assigned (either matched or uploaded), `UserStateStore` writes it into the local habit map as `remoteId` and persists user state.

## Partial Failure Behavior

- Backfill never deletes local data.
- If a habit fails to upload or fails to persist `remoteId`, processing continues for remaining habits.
- Completion marker is **not** finalized when eligible unsynced habits remain.

## Completion Marker (Per User)

`userState.meta.supabaseHabitsBackfillCompletedByUser` stores completion by Supabase user id.

- Marker is scoped by authenticated Supabase user id, safe for multi-user same-device usage.
- Marker is set to `true` only when no eligible habits remain without `remoteId` and there are no failures.
- If eligible unsynced habits remain, marker stays unset/cleared so retries are allowed.

## Activation Strategy

Phase 3C is callable and also auto-triggered safely:

- Trigger point: after successful auth/profile identity sync in `AuthController`.
- Execution: non-blocking (`unawaited`), guarded against concurrent runs.
- Scope: only runs when an authenticated Supabase session exists and local `userId` matches that session.
- Repeat behavior: marker + remaining-candidate check prevent repeated duplicate uploads on every startup.

## Next Steps

### Phase 3D
- Add remote fetch/download bootstrap for clean-device sign-in.

### Phase 4
- Add `habit_logs` sync once habit identity is stable end-to-end.
