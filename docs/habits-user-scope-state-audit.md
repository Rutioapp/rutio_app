# Habits User Scope And State Audit

Date: 2026-06-22
Branch: `docs/habits-user-scope-state-audit`

## Goal

Audit the current habits, auth scope, and user progression persistence flow before implementing any more fixes.

This document describes the current code as of this branch. It does not change behavior, UI, or Supabase schema.

## Executive Summary

The observed bug is most plausibly a combination of two independent realities:

1. Current progression restore is incomplete by design.
   - Local progression and wallet state are mirrored to Supabase, but login/bootstrap does not fetch `user_progress` back into local state.
   - After clearing local storage, the app reloads the template state (`level=1`, `xp=0`, `coins=0`) and then pushes that snapshot back to Supabase through `syncSupabaseUserProgressBackfillOnce()`.
   - Result: losing local cache can reset the visible user to level 1 / 0 coins, and may also overwrite the remote snapshot with the reset values.

2. Current habits remote pull code is scoped defensively in the app code now, but the reported cross-user import implies one of these is still true in practice:
   - the polluted local state was created by an earlier unscoped remote pull and is not fully repairable because many local rows have no trustworthy ownership metadata
   - another runtime/build/environment still uses older repository/store code
   - remote rows or responses do not actually match the assumptions in the current branch
   - there is another import path outside the current manual refresh path in the running app binary

The current branch is not sufficient to guarantee recovery after cache clear because habits and progress are treated differently:

- habits now have a remote pull path
- progress still has only local-to-remote write-through/backfill, not remote-to-local restore

## 1. Auth / Session Source Of Truth

### Current auth user source

- `AuthController` uses `AuthRepository.currentUser` and `authStateChanges` as its session source of truth in [lib/application/auth/auth_controller.dart](/D:/dev/alpha/rutio_app/lib/application/auth/auth_controller.dart) and [lib/data/repositories/auth_repository.dart](/D:/dev/alpha/rutio_app/lib/data/repositories/auth_repository.dart).
- `AuthRepository.currentUser` is `Supabase.instance.client.auth.currentUser`.
- `UserStateStore` also has a fallback provider `_currentSupabaseUserIdProvider`, defaulting to the current Supabase authenticated user id in [lib/stores/user_state_store.dart](/D:/dev/alpha/rutio_app/lib/stores/user_state_store.dart).

### How auth user id is passed into local scope

- App startup sets the initial local scope from:
  - `DemoSeedScope.userId` when demo profile is active
  - `RutioSupabaseClient.instance.auth.currentUser?.id` otherwise
  - in [lib/main.dart](/D:/dev/alpha/rutio_app/lib/main.dart)
- `AuthController` calls `await _userStateStore.switchLocalScope(userId: _currentUser!.id)` after sign-in, sign-up, initial session, and later auth-state changes.
- `UserStateRepository.setActiveUserScope(...)` stores the active scoped storage key in [lib/data/repositories/user_state_repository.dart](/D:/dev/alpha/rutio_app/lib/data/repositories/user_state_repository.dart).

### What happens when no auth user exists

- Repositories that require auth degrade safely:
  - `HabitRepository.fetchHabitsForCurrentUser()` returns empty when there is no user
  - `HabitLogRepository` fetch methods return empty when there is no user
  - write methods fail with `notAuthenticated`
- `AuthController.signOut()` and auth-state sign-out call `switchLocalScope(userId: null, forceReload: true)`.
- Guest scope persists to `SharedPreferences` key `user_state_v1` in [lib/data/local/user_state_storage.dart](/D:/dev/alpha/rutio_app/lib/data/local/user_state_storage.dart).

### Demo profile / screenshot mode

- Demo profile is controlled by `RutioRuntimeProfile` in [lib/devtools/rutio_runtime_profile.dart](/D:/dev/alpha/rutio_app/lib/devtools/rutio_runtime_profile.dart).
- Demo mode skips Supabase auth sync entirely in `AuthController` and leaves `_currentUser = null`.
- Demo seed writes to dedicated local scope `demo_user` via `DemoSeedRunner` in [lib/devtools/demo_seed/demo_seed_runner.dart](/D:/dev/alpha/rutio_app/lib/devtools/demo_seed/demo_seed_runner.dart).
- Screenshot mode suppresses gamification overlays but does not itself create a separate data scope.

### Hardcoded or fallback user ids

Found:

- template placeholder local user id: `user_123`
  - [assets/templates/user_state_template.json](/D:/dev/alpha/rutio_app/assets/templates/user_state_template.json)
  - normalized away by `_normalizeUserIdForActiveScope(...)` in [lib/stores/user_state_store_core.dart](/D:/dev/alpha/rutio_app/lib/stores/user_state_store_core.dart)
- demo scope user id: `demo_user`
  - [lib/devtools/demo_seed/demo_seed_models.dart](/D:/dev/alpha/rutio_app/lib/devtools/demo_seed/demo_seed_models.dart)
- `guest` appears only as a debug/log label, not as a persisted authenticated fallback user id.

I did not find app runtime code that intentionally queries Supabase with a hardcoded user id.

## 2. Local State Bootstrap After Launch / Login

### Which code loads local state

- `UserStateStore.load()` calls `_loadStore(...)` in [lib/stores/user_state_store_core.dart](/D:/dev/alpha/rutio_app/lib/stores/user_state_store_core.dart).
- `_loadStore(...)` calls `UserStateRepository.loadOrCreate()`.
- `UserStateRepository.loadOrCreate()`:
  - reads the current scoped `SharedPreferences` key
  - if missing, initializes from `assets/templates/user_state_template.json`
  - legacy-to-scoped auto-migration is currently disabled via `_autoMigrateLegacyIntoScoped = false`

### Which code loads remote user state

Remote profile / identity:

- `AuthController._bootstrapCurrentUserProfileMetadata(...)` ensures a `profiles` row exists.
- `AuthController._syncCurrentUserProfile(...)` fetches the `profiles` row and applies display name/email/avatar into local state through `applySupabaseIdentity(...)`.

Remote habits:

- only loaded by `UserStateStore.syncHabitsFromRemoteBestEffort()` in [lib/stores/user_state_store_habits.dart](/D:/dev/alpha/rutio_app/lib/stores/user_state_store_habits.dart)
- this is manual refresh driven, not startup driven

Remote diary V2:

- Diary V2 has its own auto/manual pull flow in [lib/stores/user_state_store_diary.dart](/D:/dev/alpha/rutio_app/lib/stores/user_state_store_diary.dart)

Remote user progression:

- there is no code path that fetches `user_progress` and hydrates local `progression` / `wallet`.
- `UserProgressRepository.fetchCurrentProgress()` exists, but I found no production caller.

### Which code seeds default/demo/catalog habits

- Template state contains no starter habits:
  - [assets/templates/user_state_template.json](/D:/dev/alpha/rutio_app/assets/templates/user_state_template.json)
- Demo profile seeds habits only in demo scope:
  - [lib/devtools/demo_seed/demo_seed_runner.dart](/D:/dev/alpha/rutio_app/lib/devtools/demo_seed/demo_seed_runner.dart)
- Habit catalog is local asset data used only when the user adds habits:
  - [assets/data/habits_catalog.json](/D:/dev/alpha/rutio_app/assets/data/habits_catalog.json)
  - add flows live in [lib/stores/user_state_store_habits.dart](/D:/dev/alpha/rutio_app/lib/stores/user_state_store_habits.dart)

I did not find an authenticated bootstrap path that auto-seeds catalog/default habits into a real signed-in scope.

### Which code decides the active scope

- initial scope in `main.dart`
- subsequent scope changes in `AuthController`
- actual scope switch and reload in `_switchLocalScope(...)` in [lib/stores/user_state_store_core.dart](/D:/dev/alpha/rutio_app/lib/stores/user_state_store_core.dart)

### Can authenticated state and demo state mix

By storage design, they should not:

- guest: `user_state_v1`
- demo: `user_state_v1_demo_user`
- authenticated: `user_state_v1_<sanitized auth uid>`

Additional guards:

- `_shouldSyncHabitsForCurrentScope(...)` blocks habits pull for demo scope
- auth controller does not bind Supabase session in demo profile

Residual risk:

- if old polluted rows already exist in the authenticated scoped local file, current repair only prunes rows with explicit foreign ownership metadata
- local rows without ownership metadata are intentionally preserved

### Why clearing cache can reset level / coins

This is clear in the current code:

- clearing scoped local state removes the saved authenticated local store
- next load falls back to `user_state_template.json`
- template progression is `level: 1`, `xp: 0`
- template wallet is `coins: 0`
- no remote restore path fills those values back in

Then auth bootstrap calls `syncSupabaseUserProgressBackfillOnce()`, which pushes the current local snapshot to remote. That means a clean-device sign-in can turn into a remote overwrite instead of a remote restore.

## 3. Habits Remote Fetch Audit

### Files inspected

- [lib/data/repositories/habit_repository.dart](/D:/dev/alpha/rutio_app/lib/data/repositories/habit_repository.dart)
- [lib/data/repositories/habit_log_repository.dart](/D:/dev/alpha/rutio_app/lib/data/repositories/habit_log_repository.dart)
- [lib/data/services/habit_sync_service.dart](/D:/dev/alpha/rutio_app/lib/data/services/habit_sync_service.dart)
- [lib/data/services/habit_log_sync_service.dart](/D:/dev/alpha/rutio_app/lib/data/services/habit_log_sync_service.dart)

### Tables queried

- `public.habits`
- `public.habit_logs`
- no habit repository reads `profiles` or `user_progress`

### App-side filtering

`HabitRepository.fetchHabitsForCurrentUser()`:

- query includes `.eq('user_id', userId)`
- response is also filtered again with `.where((habit) => habit.userId == userId)`

`HabitLogRepository.fetchLogsForDateRange(...)`:

- query includes `.eq('user_id', userId)`
- response filtered again by `log.userId == userId`

`HabitLogRepository.fetchLogsForHabit(...)`:

- query includes `.eq('user_id', userId).eq('habit_id', normalizedHabitId)`
- response filtered again by both `userId` and `habitId`

`HabitLogRepository.fetchLogsForHabits(...)`:

- query includes `.eq('user_id', userId).inFilter('habit_id', normalizedHabitIds)`
- response filtered again by both user and habit ids

### RLS vs explicit filters

- The current code does not rely on RLS alone.
- It uses explicit app-side `user_id` filters and then defensive in-memory re-filtering.
- Repo schema docs in [docs/supabase_backend_schema_reference.md](/D:/dev/alpha/rutio_app/docs/supabase_backend_schema_reference.md) also assume per-user RLS.

### Can all rows be fetched accidentally from current repository code

From the code currently on disk, these repository methods should not fetch all users' rows unless:

- `_currentUserId()` resolves to the wrong user id
- a different build is running older code
- Supabase or transport behavior is not matching the request assumptions

The current repository code itself is explicitly scoped.

### Can current fetch path import other users' habits

From the current code alone, the manual habits pull path is defensive:

- repository fetch filters by `user_id`
- store re-filters habits by `remoteHabit.userId == authenticatedUserId`
- store fetches logs only for the fetched remote habit ids
- store re-filters logs by both `userId` and allowed remote habit ids

So the current branch does not explain a fresh cross-user import by simple repository omission.

## 4. Habits Local Merge / Pull Audit

### Method that merges remote habits into local state

- entry point: `syncHabitsFromRemoteBestEffort()`
- merge helpers in [lib/stores/user_state_store_habits.dart](/D:/dev/alpha/rutio_app/lib/stores/user_state_store_habits.dart):
  - `_mergeRemoteHabitsIntoLocalState(...)`
  - `_mergeRemoteHabitLogsIntoLocalState(...)`
  - `_pruneForeignRemoteHabitsFromLocalState(...)`

### Whether merge validates remote user_id

Yes.

- `_filterScopedRemoteHabits(...)`
- `_isRemoteHabitScopedToUser(...)`
- `_filterScopedRemoteHabitLogs(...)`
- `_isRemoteHabitLogScopedToUser(...)`

### Whether merge can remove / hide foreign-owned local habits

Yes, but only when ownership is explicit.

- `_pruneForeignRemoteHabitsFromLocalState(...)` removes local habits only if `_isClearlyForeignRemoteOwnedHabit(...)` is true.
- `_isClearlyForeignRemoteOwnedHabit(...)` trusts only explicit metadata such as:
  - `remoteUserId`
  - `remote_user_id`
  - `supabaseUserId`
  - `supabase_user_id`
  - `userId`
  - `user_id`

Important limitation:

- polluted local rows without explicit ownership metadata are preserved on purpose to avoid destructive deletion of possibly valid local-only habits
- this means a previously contaminated local state can survive cleanup

### Whether local-only habits are preserved

Yes.

- if a local habit has no remote match, it stays
- remote absence never deletes local-only habits

### Whether progress / logs merge safely by habit + date

Partially, and conservatively.

- remote logs are attached only through local `remoteId` -> remote `habit_id`
- check-habit remote completion can fill local history for a date
- count-habit remote values do not overwrite existing local date progress:
  - `_shouldReplaceLocalProgressWithRemote(...)` always returns `false` for count habits

### Whether XP / rewards / streak / confetti can trigger during pull

Pull is intentionally side-effect-safe:

- `_applyRemoteLogToLocalHistory(...)` only mutates history maps
- it does not call `_applyHabitRewards(...)`
- it does not call `_queueBestEffortProgressAndRewardSync(...)`
- tests already assert that remote pull does not change XP/coins or queue unlock/level celebrations in [test/stores/user_state_store_habits_remote_pull_test.dart](/D:/dev/alpha/rutio_app/test/stores/user_state_store_habits_remote_pull_test.dart)

## 5. Other Possible Import Paths Affecting Active Habits

### Manual refresh

- Home manual refresh calls `store.syncHabitsFromRemoteBestEffort()`
- file: [lib/screens/home/state/home_state.dart](/D:/dev/alpha/rutio_app/lib/screens/home/state/home_state.dart)

This is the only production call site I found for habits remote pull.

### Login / bootstrap / startup

Auth bootstrap runs these after sign-in/session restore:

- `syncSupabaseUserProgressBackfillOnce()`
- `syncExistingLocalHabitsOnce()`
- `syncExistingLocalHabitLogsOnce()`
- `syncExistingLocalJournalEntriesOnce()`
- `syncExistingLocalAchievementsOnce()`

These are all local-to-remote backfills, not remote-to-local imports.

### Repository hydration

- `UserStateRepository.loadOrCreate()` only loads scoped local JSON or creates the template.
- it does not read habits from Supabase.

### Demo seed

- demo seed affects only `demo_user` scoped local state.

### Legacy migration / backfill

- legacy migration from unscoped `user_state_v1` into an authenticated scoped key exists in storage
- but repository constant `_autoMigrateLegacyIntoScoped` is currently `false`
- so it is not active in current production code

### Catalog defaults

- no startup catalog import path found

### Previous legacy sync code

Relevant historical contradiction:

- [docs/supabase_habits_sync_phase_3.md](/D:/dev/alpha/rutio_app/docs/supabase_habits_sync_phase_3.md) explicitly said there was no startup remote habit download in that phase
- the current codebase now does contain a manual remote pull path plus repair/prune tests

Conclusion for import paths:

- current production habits import path appears to be manual Home refresh only
- if users still see cross-user import on login without refreshing, that likely points to:
  - an older binary/build
  - previously polluted local scoped state
  - or an external behavior not represented in the current branch

## 6. User Progression State Audit

### Local location

Local progression state lives in scoped user JSON:

- `userState.progression.level`
- `userState.progression.xp`
- derived level progress from `xp`
- `userState.wallet.coins`
- `userState.familyXp`
- local achievement reward state under `userState.profile.achievements`

Main code:

- [lib/stores/user_state_store_habit_progress.dart](/D:/dev/alpha/rutio_app/lib/stores/user_state_store_habit_progress.dart)
- [lib/stores/user_state_store_achievements.dart](/D:/dev/alpha/rutio_app/lib/stores/user_state_store_achievements.dart)

### Remote location

- snapshot row: `public.user_progress`
- event mirrors: `public.xp_events`, `public.currency_events`
- profile metadata: `public.profiles`

### Are level / coins pushed to Supabase

Yes.

- reward flows call `_queueBestEffortProgressAndRewardSync(...)`
- that calls `UserProgressSyncService.syncCurrentProgressFromLocalState(...)`
- which writes `user_progress`
- XP and currency deltas also insert event rows

Auth bootstrap also calls `syncSupabaseUserProgressBackfillOnce()`, which pushes the current local snapshot once per user marker.

### Are level / coins pulled from Supabase after clearing cache

No.

- `UserProgressRepository.fetchCurrentProgress()` exists
- but I found no production code that uses it to restore local state

### If not, what repository would be responsible

- `UserProgressRepository` would be the natural read source for snapshot restore
- if event replay were ever needed, `XpEventRepository` / `CurrencyEventRepository` would also matter, but there is no such restore implementation now

### Risk of separate / incomplete sync

High.

- habits can now be pulled from remote
- progress is only pushed to remote
- profile metadata is pulled
- journal and achievements have their own separate paths

This means a clean-device login can restore identity and possibly habits, but not progression.

## 7. Supabase Tables And RLS Assumptions

This section is based on the current repository code plus [docs/supabase_backend_schema_reference.md](/D:/dev/alpha/rutio_app/docs/supabase_backend_schema_reference.md). I did not inspect live SQL migrations in this audit.

### `public.habits`

- primary key: `id`
- local id field in app state: local `activeHabits[].id`
- remote id persisted locally as: `remoteId`
- user_id field: `user_id`
- updated field: `updated_at`
- deleted/archived fields: `is_archived` only, no delete tombstone documented
- rows are per-user: yes
- app code filters by user_id: yes
- RLS likely protects it: yes, per docs

### `public.habit_logs`

- primary key: `id`
- logical uniqueness: `(user_id, habit_id, log_date)`
- local identity in app state: local habit id + local date key
- user_id field: `user_id`
- updated field: `updated_at`
- deleted/archived fields: none documented
- rows are per-user: yes
- app code filters by user_id: yes
- RLS likely protects it: yes, per docs

### `public.user_progress`

- primary key: `user_id`
- local matching fields: `progression.*`, `wallet.coins`
- user_id field: `user_id`
- updated field: `updated_at`
- deleted/archived fields: none
- rows are per-user: yes
- app code filters by user_id: yes in repository
- RLS likely protects it: yes, per docs

### `public.profiles`

- primary key: `id` (auth user id)
- local matching fields: identity/profile metadata
- user ownership field: `id`
- updated field: `updated_at`
- deleted/archived fields: none
- rows are per-user: yes
- app fetch is scoped by `id == current auth user`
- RLS likely protects it: yes, per docs

### `public.xp_events`

- primary key: `id`
- user_id field: `user_id`
- updated field: none, append-only `created_at`
- rows are per-user: yes
- app only inserts current-user rows
- RLS likely protects it: yes, per docs

### `public.currency_events`

- primary key: `id`
- user_id field: `user_id`
- updated field: none, append-only `created_at`
- rows are per-user: yes
- app only inserts current-user rows
- RLS likely protects it: yes, per docs

### Legacy local storage

- guest storage key: `user_state_v1`
- authenticated scoped storage key: `user_state_v1_<sanitizedUserId>`
- demo storage key: `user_state_v1_demo_user`

## 8. Ranked Root-Cause Hypotheses

### Why all users' habits appear after clearing cache

1. Most likely: previously contaminated remote or local state plus incomplete repair.
   - current repair only prunes rows with explicit ownership metadata
   - rows imported by an older bug may still lack ownership metadata and survive

2. Very plausible: the user ran an older binary/branch where remote habits fetch or merge was not fully scoped.
   - current code on disk is explicitly scoped
   - the observed behavior contradicts the current repository/store code

3. Plausible: another import path exists outside this branch’s Home refresh path in the actual running app.
   - I did not find one in this checkout
   - but the behavior reported after reinstall/cache clear suggests validating the real build is important

4. Less likely from code on disk: current Supabase repositories still fetch all rows.
   - current source strongly argues against this
   - only environment/build drift or unexpected backend behavior would make it true

### Why level / coins are lost after clearing cache

1. Most likely and directly supported by code: no remote restore exists for `user_progress`.
   - cache clear loads the template
   - template starts at level 1 / 0 XP / 0 coins

2. Very likely secondary damage: auth bootstrap then pushes the reset snapshot back to Supabase.
   - `syncSupabaseUserProgressBackfillOnce()` runs after sign-in/session restore
   - on a clean local state, that snapshot is the reset template

### Whether current fixes are sufficient

No.

- current branch adds scoped repository fetches and safer habits pull logic
- but it does not provide:
  - remote progression restore
  - guaranteed contaminated-state cleanup
  - proof that the running build cannot still call an older import path

## 9. Recommended Repair Plan

### Phase 0: emergency containment

- Temporarily disable or guard Home habits remote refresh for authenticated users if field evidence still shows cross-user imports.
- Keep the guard small and reversible.
- Prefer fail-closed over importing possibly foreign rows.

### Phase 1: verify the real import path

- Instrument all habits remote entry points with unambiguous debug logs:
  - auth bootstrap
  - home manual refresh
  - any future startup pull
- confirm exact build/branch in the affected runtime
- confirm actual REST query parameters emitted in the failing environment

### Phase 2: harden repository scope

- Keep explicit `.eq('user_id', currentUserId)` on all habits/progress queries.
- Add focused tests around request query parameters for every fetch path.
- Review any related repositories for the same pattern.

### Phase 3: harden store merge / repair

- Keep current store-side user filtering even if repositories are scoped.
- Add stronger contamination repair only when ownership can be proven.
- Do not delete local rows with unknown ownership blindly.

### Phase 4: progression restore before further sync

- Add remote-to-local restore for `user_progress` before any backfill push on clean-device login.
- The bootstrap order should restore remote snapshot first, then decide whether any local-to-remote reconciliation is needed.

### Phase 5: clean-device authenticated bootstrap contract

- Define an explicit authenticated bootstrap policy:
  - identity/profile restore
  - progression restore
  - optional habits pull
  - only then selective local-to-remote backfill

### Phase 6: contamination repair tooling

- if enough ownership evidence exists, provide a scoped repair path to:
  - remove clearly foreign-owned local habits
  - preserve local-only/unknown rows
  - avoid deleting history without a trustworthy mapping

### Phase 7: cross-user isolation tests

- add repository and store tests for mixed remote rows
- add clean-device login tests that assert only current-user data appears

### Manual verification steps

1. Start with a clean local state on a test account that has known remote habits and known remote progress.
2. Sign in and capture whether any habits import before manual refresh.
3. Trigger Home refresh and verify habit count does not exceed that account’s remote rows.
4. Confirm `user_progress` local state after login matches remote snapshot.
5. Repeat with a second account on the same device and confirm no cross-account bleed.

## 10. Focused Test Plan

- `no-auth fetch returns empty`
  - already covered for habits and habit logs repository fetches
- `authenticated user fetch returns only own habits`
  - already covered in repository tests
- `mixed remote rows only merge current user's rows`
  - already covered in habits remote pull tests
- `refresh cannot increase habit count with foreign rows`
  - partially covered; add explicit regression for the original reproduction count jump
- `clearing local state then login restores only current user's data`
  - missing and should be added
- `level/coins restore behavior`
  - currently missing and should expose the present failure first
- `demo profile never mixes with authenticated profile`
  - habits pull demo guard is covered; add auth/bootstrap coverage if needed
- `clean-device login does not overwrite remote progress with template defaults`
  - missing and high priority

## Acceptance Mapping

- `docs/habits-user-scope-state-audit.md exists`
  - yes
- `explains why this bug can happen`
  - yes: missing remote progress restore plus likely earlier/current contamination path mismatch
- `maps every habits import/sync/bootstrap path`
  - yes, within the current checkout
- `maps level/coins persistence and restore behavior`
  - yes
- `identifies whether remote queries are correctly scoped`
  - yes: current code is explicitly scoped
- `identifies whether local merge is defensively scoped`
  - yes: current merge is defensive but intentionally non-destructive for unknown ownership
- `proposes a safe repair plan`
  - yes

## Final Audit Conclusion

The code currently on disk already contains explicit user scoping for habits and habit logs fetches, plus store-side defensive filtering during manual habits pull. That means the cross-user habit import bug is either:

- a legacy contamination problem that current repair cannot fully undo
- a runtime/build mismatch using older code
- or another import behavior not represented in this checkout

The level/coins reset is clearer: it is an architectural gap in the current branch. `user_progress` is mirrored outward but never restored inward, so clearing local storage necessarily falls back to the template state and can then backfill that reset state to Supabase.
