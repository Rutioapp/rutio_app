# Diary Daily Reward - Phase 8A (Local-First + Idempotent)

## Scope
- Phase 8A adds a **local-first daily diary reward**.
- No Supabase `journal_entries` persistence is introduced in this phase.
- No two-way diary sync is introduced in this phase.

## Reward Amount
- XP: `10`
- Ambar: `5`
- Centralized constants:
  - `lib/constants/reward_constants.dart`
  - `RewardConstants.dailyDiaryXpReward`
  - `RewardConstants.dailyDiaryAmbarReward`

## Valid Entry Criteria
- A diary entry is reward-eligible only if:
  - `entry.text.trim().isNotEmpty`
- Empty/placeholder text does not grant reward.

## Marker Location
- Persistent idempotency marker is stored per user in:
  - `userState.meta.diaryRewardAppliedDateKeys`
- Value shape:
  - List of normalized local date keys (`YYYY-MM-DD`)
- Marker is sanitized on load/save and diary operations:
  - Invalid/non-date values are discarded.
  - Duplicates are removed.

## Idempotency Behavior
- Date key source:
  - Local day from `DiaryEntry.createdAt` via existing `_dateKey(...)` semantics.
- Reward is granted only when saving a valid entry and the date key is not already claimed.
- Once claimed for a date:
  - Editing same entry does not grant again.
  - Creating another entry on same date does not grant again.
  - App restarts/reloads do not grant again.
- No historical backfill/migration rewards are applied in Phase 8A.

## Edit/Delete Behavior
- Edit:
  - Can trigger reward only if the day has never been claimed and entry becomes valid.
  - Already claimed day never rewards again.
- Delete:
  - Does not revoke already granted XP/Ambar in this phase.
  - Recreating another entry on that same claimed day does not re-reward.

## Local Progress + Supabase Event Integration
- Local reward mutation updates:
  - `userState.progression` (`xp`, `level`)
  - `userState.wallet.coins`
  - `userState.daily.xpEarnedToday`
  - `userState.daily.coinsEarnedToday`
  - `userState.meta.diaryRewardAppliedDateKeys`
- After successful local save, existing Phase 6 best-effort sync is triggered:
  - `syncCurrentProgressFromLocalState(...)`
  - `recordXpEvent(...)` with source `journal_entry`
  - `recordCurrencyEvent(...)` with source `journal_entry`
- No manual direct SQL insertions are introduced here.

## What Remains for Phase 8B
- Supabase persistence for diary/journal entries (`journal_entries` table flow).
- Diary backend sync strategy (upload/reconcile policy).
- Any conflict-resolution strategy for multi-device diary data.
