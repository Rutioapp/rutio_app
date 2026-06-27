# Shop Economy Phase 2 Audit

Branch audited: `feature/shop-economy-phase-2`

## Scope

This audit documents the current state of coins, XP, achievements, habits, and shop persistence before Phase 2 behavior changes.

No functional changes were made during this audit.

## Relevant File Map

- `lib/stores/user_state_store_habits.dart`
  - Main habit mutation flows.
  - Current reward grant entry points for check/count habits.
  - Current "uncomplete", skip, and historical edit flows.
- `lib/stores/user_state_store_habit_progress.dart`
  - Reward math and application to XP/coins.
  - History write helpers.
  - Supabase progress restore helpers.
- `lib/stores/user_state_store_achievements.dart`
  - Achievement persistence shape under `userState.profile.achievements`.
  - Achievement reward application and reward idempotency via `rewardAppliedAchievementIds`.
- `lib/stores/user_state_store_core.dart`
  - Root normalization.
  - Daily reset.
  - History root creation.
- `lib/stores/user_state_store_diary.dart`
  - Diary reward flow and delete flow.
  - Useful comparison because it also grants XP/coins but does not revert on delete.
- `lib/data/local/user_state_storage.dart`
  - Local persistence in `SharedPreferences`.
- `lib/data/repositories/user_state_repository.dart`
  - Scoped local persistence and save guards by active user scope.
- `assets/templates/user_state_template.json`
  - Initial local shape for progression, wallet, achievements, family XP, etc.
- `lib/data/repositories/user_progress_repository.dart`
  - Remote persistence for level/XP/coin aggregate state in `user_progress`.
- `lib/data/services/user_progress_sync_service.dart`
  - Best-effort remote mirroring for aggregate progress plus XP/currency events.
- `lib/data/services/achievement_sync_service.dart`
  - Best-effort remote mirroring for unlocked achievements.
- `lib/features/shop/domain/shop_state.dart`
  - Separate shop state model with its own `coins`.
- `lib/features/shop/data/shop_local_repository.dart`
  - Separate local persistence for `ShopState`.
- `lib/features/shop/application/shop_service.dart`
  - Pure shop domain service operating on `ShopState`.
- `lib/services/shop_service.dart`
  - Legacy map-based purchase service operating on `userState.wallet.coins`.
- `lib/screens/shop_screen.dart`
  - Current shop UI stub uses local widget state `_coins = 120`; not wired to real economy.

## Current Source Of Truth

### Coins

The active economy path currently uses:

- `userState.wallet.coins`

This is the field updated by habit rewards, diary rewards, achievement rewards, level-up rewards, and remote progress restore.

Key references:

- `lib/stores/user_state_store_habit_progress.dart:549`
- `lib/stores/user_state_store_achievements.dart:108`
- `lib/stores/user_state_store_diary.dart:142`
- `lib/stores/user_state_store_habit_progress.dart:169`
- `assets/templates/user_state_template.json:16`

### XP

XP currently lives in:

- `userState.progression.xp`
- `userState.progression.level`

Key references:

- `lib/stores/user_state_store_habit_progress.dart:535`
- `lib/stores/user_state_store_habit_progress.dart:165`
- `assets/templates/user_state_template.json:10`

### Achievements

Achievements currently live under:

- `userState.profile.achievements.unlocked`
- `userState.profile.achievements.featured`
- `userState.profile.achievements.rewardAppliedAchievementIds`

Key references:

- `lib/stores/user_state_store_achievements.dart:28`
- `assets/templates/user_state_template.json:36`

### Shop State

There is already a separate Phase 1 shop model:

- `ShopState.coins`
- `ShopState.inventory`
- `ShopState.backpackItems`
- `ShopState.equippedCosmetics`

Persisted independently in:

- `SharedPreferences['rutio_shop_state_v1']`

Key references:

- `lib/features/shop/domain/shop_state.dart:6`
- `lib/features/shop/data/shop_local_repository.dart:12`

Important: this is not currently the same source of truth as `userState.wallet.coins`.

### GameConfig

`GameConfig` is not the active source of truth for current coins.

The legacy `lib/services/shop_service.dart` reads prices/catalog from config and spends from `userState.wallet.coins`, but the newer Phase 1 shop stack uses `ShopState` instead.

## Current Habit Completion Flow

### Check habit completion today

Current entry:

- `UserStateStore.completeHabit(...)`
- implementation in `lib/stores/user_state_store_habits.dart:2443`

Flow:

1. Load `userState`, run daily reset, resolve active habit.
2. Guard against non-scheduled dates and duplicate same-day check completion.
3. Read daily grant marker from `daily.habitsCompletedToday[habitId]`.
4. `_applyHabitProgressDelta(...)` marks check habits as `doneToday=true`.
5. `_applyHabitRewards(...)` adds XP, level progression, coins, family XP, and daily counters.
6. If this is the first reward for that habit/day, mark `daily.habitsCompletedToday[habitId]=true`.
7. Sync local day history via `_syncHabitHistoryFromState(...)`.
8. Recompute achievements and apply achievement rewards if newly unlocked.
9. Save local state.
10. Trigger best-effort remote sync for achievements, aggregate progress, currency/XP events, and habit logs.

Reward math:

- check habit XP: `_xpForCheck()`
- check habit coins: `_coinsForCheck()`

Observed expectations from tests:

- check completion grants `10 XP` and `5 coins`
- file: `test/stores/user_state_store_reward_persistence_test.dart:15`

### Count habit progress today

Current entry:

- `UserStateStore.setCountHabitValue(...)`
- implementation in `lib/stores/user_state_store_habits.dart:2343`

Flow:

1. Load `userState`, run daily reset, resolve active count habit.
2. Read daily grant marker from `daily.habitsCompletedToday[habitId]`.
3. `_setCountHabitProgress(...)` writes `progress`, sets `doneToday = progress >= target`.
4. Reward is granted only when target is reached and the day reward has not already been granted.
5. Save active habit state and sync history.
6. Recompute achievements, persist, and queue best-effort remote sync.

Observed expectations from tests:

- no reward below target
- one-time reward when target is first reached
- no extra reward when value increases again after target
- file: `test/stores/user_state_store_reward_persistence_test.dart:41`

## Current Uncomplete / Revert / Edit Flows

### Uncomplete habit today

There is no dedicated rollback method that subtracts coins or XP.

Current path:

- `UserStateStore.setHabitCompletion(...)`
- wrapper delegates to `setHabitCompletionForKey(...)`
- implementation in `lib/stores/user_state_store_habits.dart:2601`

When the target date is today and `done=false`:

1. It sets `habit['doneToday'] = false`.
2. It clears `skippedToday`.
3. For count habits it keeps current `progress`.
4. It writes history/log sync state.
5. It does **not** subtract XP.
6. It does **not** subtract coins.
7. It does **not** clear `daily.habitsCompletedToday[habitId]`.

Current behavior is already characterized by test:

- `test/stores/user_state_store_reward_persistence_test.dart:93`
- expectation: uncompleting today keeps already granted reward

This matches the product note you provided: reward rollback does not exist yet.

### Toggle completion for past date

Current entry:

- `UserStateStore.toggleHabitDoneForDate(...)`
- implementation in `lib/stores/user_state_store_habits.dart:2546`

For non-today dates it directly flips `history.habitCompletions[dateKey][habitId]` and completion time state, then saves and syncs habit logs.

Important:

- no XP/coin reward logic
- no achievement reward logic
- no rollback logic

### Set completion for arbitrary date

Current entry:

- `UserStateStore.setHabitCompletionForKey(...)`
- implementation in `lib/stores/user_state_store_habits.dart:2601`

For past dates it writes:

- `history.habitCompletions`
- `history.habitSkips`
- completion time state

Important:

- no XP/coin reward logic
- no achievement reward logic
- no rollback logic

### Set skip for arbitrary date

Current entry:

- `UserStateStore.setHabitSkipForKey(...)`
- implementation in `lib/stores/user_state_store_habits.dart:2672`

For skip=true it:

- marks skip
- forces completion false
- zeroes count value for that date

Important:

- no XP/coin rollback
- no achievement rollback

### Edit count progress for arbitrary date

Current entry:

- `UserStateStore.setCountHabitValueForDate(...)`
- implementation in `lib/stores/user_state_store_habits.dart:2759`

For past dates it updates:

- `history.habitCountValues[dateKey][habitId]`
- `history.habitCompletions[dateKey][habitId] = value >= target`
- `history.habitSkips[dateKey][habitId] = false`

Important:

- no XP/coin reward logic
- no XP/coin rollback logic
- no achievement reward logic

### Delete diary entry

Current entry:

- `UserStateStore.deleteDiaryEntry(...)`
- implementation in `lib/stores/user_state_store_diary.dart:320`

Delete removes the entry locally and syncs remote delete, but does not revert any previously granted diary reward.

This is useful precedent: reward-bearing flows already exist in the app where delete does not imply reward rollback.

### Delete habit

Current entry:

- `UserStateStore.deleteHabitById(...)`
- implementation in `lib/stores/user_state_store_habits.dart:1800`

Delete can purge local history buckets for the habit:

- `habitCompletions`
- `habitCountValues`
- `habitSkips`
- `habitCompletionTimes`

Important:

- deleting a habit does not adjust XP/coins
- deleting a habit does not recalculate achievement rewards backward

## Persistence Summary

### Local persistence

`UserState` is persisted as a scoped JSON blob in `SharedPreferences`.

- storage layer: `lib/data/local/user_state_storage.dart`
- repository layer: `lib/data/repositories/user_state_repository.dart`

Key shape inside the blob:

- `userState.progression`
- `userState.wallet`
- `userState.profile.achievements`
- `userState.familyXp`
- `userState.daily`
- `userState.history`
- `userState.activeHabits`

Notes:

- template includes progression/wallet/achievements/familyXp/daily
- history is created lazily by `_ensureHistoryRoot(...)`

### Remote persistence

Current remote best-effort persistence exists for:

- aggregate user progress in `user_progress`
- XP events
- currency events
- unlocked achievements
- habit logs

Current local-first design remains primary:

- local save happens first
- remote sync is best-effort and non-blocking

### Shop persistence

Shop Phase 1 has its own separate persistence:

- `ShopLocalRepository` -> `SharedPreferences['rutio_shop_state_v1']`

At audit time, this is not the same persisted object as `UserState`.

## Tests Currently Related

### Reward and current uncomplete behavior

- `test/stores/user_state_store_reward_persistence_test.dart`
  - check habits grant XP/coins
  - count habits grant once when reaching target
  - uncompleting today keeps reward

### Historical/date mutation guards

- `test/stores/user_state_store_schedule_guards_test.dart`
  - historical completion/skip/count edits respect schedule/archived guards

### User progress restore

- `test/stores/user_state_store_user_progress_restore_test.dart`
  - remote progress restores local XP/coins/level
  - conflicting local state is protected

### Shop domain and shop persistence

- `test/features/shop/application/shop_service_test.dart`
  - separate `ShopState` purchase/equip/spend logic
- `test/features/shop/data/shop_local_repository_test.dart`
  - separate `ShopState` persistence

### Achievement reward idempotency / balance

- `test/features/achievements/user_state_store_special_achievements_balance_test.dart`
  - achievement state and reward-applied identifiers are persisted and read

## Key Risks

### 1. Dual coin sources

There are currently at least three coin notions in the repo:

- active runtime economy: `userState.wallet.coins`
- separate Phase 1 shop model: `ShopState.coins`
- current shop screen stub: `_ShopScreenState._coins`

Risk:

- Phase 2 can easily wire purchases against a different balance than habit rewards.

### 2. No rollback marker clearing

`daily.habitsCompletedToday[habitId]` is used as the daily reward idempotency flag.

Current uncomplete flows do not clear it.

Risk:

- if Phase 2 introduces subtraction on uncomplete without a matching grant-state strategy, users may get stuck unable to re-earn or may re-earn twice depending on implementation order.

### 3. Double reward risk on mixed mutation paths

Today only "today" completion flows grant rewards. Historical edit flows do not.

Risk:

- if Phase 2 starts reusing historical setters for reward logic, it could accidentally bypass the current daily idempotency guard.

### 4. Check vs count asymmetry

Check habits are binary and `completeHabit(...)` early-returns when already done today.

Count habits can be edited repeatedly and rely on:

- target crossing
- `daily.habitsCompletedToday[habitId]`

Risk:

- count rollback is trickier because progress can move both above and below target multiple times in one day.

### 5. Achievement reward coupling

Habit completion can trigger:

- habit reward
- level-up reward
- achievement reward

Current achievement rewards are guarded by `rewardAppliedAchievementIds`.

Risk:

- rolling back only habit coins may still leave achievement and level-up rewards over-granted unless Phase 2 explicitly defines whether those are reversible.

### 6. Local-first sync semantics

Current remote sync mirrors post-save local state and reward deltas best-effort.

Risk:

- introducing negative deltas for rollback will need careful mapping into:
  - `user_progress`
  - `currency_events`
  - possibly `xp_events`
- remote event schemas may accept negative currency deltas, but current local code paths mostly assume positive habit reward grants.

### 7. Tests likely to break

Most likely existing characterization failures if behavior changes:

- `test/stores/user_state_store_reward_persistence_test.dart:93`
  - explicitly expects no rollback on uncomplete
- potentially progress/achievement/level-up tests if rollback touches shared reward plumbing
- shop tests if coin source is unified by replacing `ShopState.coins`

### 8. Current shop screen is still a stub

`lib/screens/shop_screen.dart` currently:

- uses local `_coins = 120`
- subtracts coins in widget state only
- does not read `UserStateStore`
- does not use `ShopState`

Risk:

- integrating economy behavior into the UI later may expose hidden divergence between stub UI and actual persisted economy.

## Proposed Phase 2.1

Recommended narrow scope for Phase 2.1:

1. Keep `userState.wallet.coins` as the single economy source of truth for now.
2. Do not make `ShopState.coins` authoritative.
3. Add explicit characterization tests for same-day uncomplete/recomplete cases before changing behavior.
4. Implement rollback only for the direct habit daily reward granted by that habit on that date.
5. Gate rollback through the existing daily reward marker so the system knows whether the day reward was ever granted.
6. Decide explicitly whether level-up rewards and achievement rewards are reversible in 2.1.

Recommended product-safe interpretation:

- Phase 2.1 should reverse only the habit completion reward itself.
- Achievement rewards and level-up rewards should remain non-reversible unless product explicitly wants full economic rewind.

Why this is safer:

- it avoids retroactive recomputation of achievements
- it avoids complex XP/level rewind cascades in the first step
- it limits regression surface in local-first sync

## Recommendations

### Must do before functional change

1. Add characterization tests for:
   - complete today -> uncomplete today
   - complete today -> uncomplete today -> recomplete today
   - count habit reach target -> drop below target -> reach target again same day
2. Decide single source of truth between:
   - `userState.wallet.coins`
   - `ShopState.coins`
3. Document whether rollback affects:
   - XP
   - coins
   - family XP
   - achievements
   - level-up rewards

### Strong recommendation

Use `UserStateStore` economy fields as the Phase 2 integration point first, then either:

- migrate shop to read/write that source, or
- define `ShopState` as inventory/cosmetics-only and stop storing coins there

### Avoid in 2.1

- retroactive reward recalculation for past dates
- full achievement rollback
- full remote replay/reconciliation redesign
- mixing stub `ShopScreen` state with real economy mutation logic

## Audit Conclusion

The live economy today is centered on `UserStateStore` and persisted in `userState.wallet.coins` plus `userState.progression.xp`.

Habit rewards are granted only through same-day completion flows and are protected from duplicate same-day grants by `daily.habitsCompletedToday[habitId]`.

Current uncomplete, skip, historical edit, diary delete, and habit delete flows do not subtract previously granted rewards.

The main implementation risk for Phase 2 is not the reward math itself but the existence of multiple coin models (`wallet.coins`, `ShopState.coins`, and current shop UI stub state) plus the shared coupling between habit rewards, achievement rewards, and level-up rewards.
