# Achievement Rewards Phase 7A (Local + Idempotent)

## Scope

This phase adds local-first achievement reward application with persistent idempotency.

- No Supabase `user_achievements` persistence yet.
- No remote achievement unlock sync.
- No unlock condition changes.
- No achievement UI redesign.

## Reward Mapping

Centralized in:

- `lib/features/achievements/application/achievement_rewards.dart`

Tier rewards:

- `wood`: XP 50, Ambar 25
- `stone`: XP 100, Ambar 50
- `bronze`: XP 200, Ambar 100
- `silver`: XP 400, Ambar 200
- `gold`: XP 800, Ambar 400
- `diamond`: XP 1600, Ambar 750
- `prismaticDiamond`: XP 3500, Ambar 1500

Helper APIs:

- `AchievementRewards.getAchievementReward(tier)`
- `AchievementRewards.resolveForAchievement(...)`

## Idempotency Strategy

Rewards are granted only for newly-created unlock records during the unlock sync pass, and only when the achievement id has not been marked as rewarded yet.

Persistent local marker:

- `userState.profile.achievements.rewardAppliedAchievementIds: string[]`

If an achievement id is already present in `rewardAppliedAchievementIds`, reward application is skipped.

## Where Rewards Are Applied

Local unlock evaluation continues in:

- `lib/stores/user_state_store_achievements.dart`
  - `_syncAchievementsFromCurrentHabits(...)`

When new unlock records are detected, reward application:

- updates local `progression.xp` and `progression.level`
- updates local `wallet.coins` (Ambar)
- updates local daily counters (`daily.xpEarnedToday`, `daily.coinsEarnedToday`)
- appends achievement id to `rewardAppliedAchievementIds`

## Supabase Progress/Event Integration (Phase 6 Reuse)

After local save, each newly applied achievement reward triggers best-effort existing sync via:

- `lib/stores/user_state_store_habits.dart`
  - `_queueBestEffortProgressAndRewardSync(...)`

Per achievement reward:

- progress upsert (`user_progress`)
- one XP event with source `achievement_unlocked`
- one currency event with source `achievement_unlocked`

This preserves local-first behavior and reuses existing Phase 6 plumbing.

## Phase 7B Remaining Work

- Persist unlock state to Supabase `user_achievements`.
- Define remote idempotency for unlock records across devices/sessions.
- Add eventual reconciliation strategy between local unlock ledger and remote unlock ledger.
