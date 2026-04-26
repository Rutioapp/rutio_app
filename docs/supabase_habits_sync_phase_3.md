# Supabase Habits Sync - Phase 3B (Persistent Remote Habit ID)

Date: April 26, 2026  
Branch: `feature/supabase-habit-remote-id`

## What Changed In Phase 3B

Rutio now persists the Supabase habit UUID in local habit maps using `remoteId`.

- Local create still happens first.
- Remote create still runs as best-effort.
- When remote create succeeds, returned `public.habits.id` is saved into the matching local habit as `remoteId`.
- Update/archive/delete now read the persisted `remoteId`, so remote mirroring continues working after app restarts.

All remote writes remain scoped to the authenticated Supabase user.

## Local-First Behavior (Preserved)

- Local mutation remains the source of truth.
- Local save succeeds even when Supabase write fails.
- Remote failures are debug warnings only in `kDebugMode`.
- No new user-facing sync error UI is introduced.

## Local Habit Identity Rules

Rutio still keeps its existing local habit `id` unchanged.

- `id` remains local identity (catalog/custom/non-UUID values are still valid).
- `remoteId` stores the Supabase UUID when available.
- Missing `remoteId` means "not synced yet" and is valid.

No startup migration is required; existing local habits without `remoteId` continue working locally.

## Local -> Remote Mapping

`HabitRemoteMapper` now resolves remote habit identity in this order:

1. Explicit override (session/runtime).
2. Persisted local `remoteId` (plus accepted aliases).
3. Local `id` only if it is already a UUID.

Write mapping to `public.habits` columns is unchanged (`name`, `family_id`, `emoji`, `habit_type`, `target_count`, `unit`, `color_id`, `reminder_enabled`, `reminder_time`, `is_archived`, `sort_order`).

## Repository Write Behavior

`HabitRepository` now handles write intent explicitly:

- No remote id provided -> insert row and let Supabase generate `id`.
- Remote id provided -> update by `user_id + id`; if no row updated, insert with that id.

Repository always forces `user_id` from current auth session and never trusts local `user_id`.

## Existing Habits Without `remoteId`

Existing habits created before Phase 3B may not have `remoteId`.

- They remain fully usable locally.
- Remote update/archive/delete is safely skipped until a future backfill phase assigns remote IDs.
- No crash or blocking behavior is introduced.

## What Remains Intentionally Not Synced

- No two-way sync.
- No startup remote habit download.
- No startup bulk upload of all local habits.
- No `habit_logs` sync yet.
- No XP/coins/achievements/journal/diary remote wiring in this phase.

## Next: Phase 3C

1. Explicit one-time upload/backfill for existing local habits without `remoteId`.
2. Guarded duplicate prevention during backfill.
3. Remote habit fetch/bootstrap for clean-device sign-in.
4. After habit identity is stable, connect `habit_logs` sync.
