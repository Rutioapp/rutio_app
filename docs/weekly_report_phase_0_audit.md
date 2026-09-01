# Weekly Report Phase 0 Audit

## 1. Executive summary

Conclusion: there is no single canonical Weekly Report metrics engine today.
The closest productive source of truth is the combination of:

- `UserStateStore` history buckets (`habitCompletions`, `habitCountValues`, `habitSkips`, `habitCompletionTimes`, `habitOccurrenceStatuses`)
- current `activeHabits`
- `HabitScheduleNormalizer`
- `buildStatisticsV3ViewData(...)`
- `buildHabitDaySummary(...)`

What we can reuse now:

- schedule normalization and expected-day gating
- local/history persistence patterns for habits
- auth scope / stale-result protection
- Diary V2 local + Supabase sync patterns
- notification timezone and payload routing patterns
- streak shield / streak break persistence

What is missing:

- historical versioning for habit name, emoji, target, schedule, and pause state
- a shared canonical habit-metrics contract
- a dedicated premium entitlement seam
- a Weekly Report reflection model / relation

Main risks:

- `timesPerWeek` is handled with different semantics in different consumers
- historical reconstruction after later habit edits is only partial
- current Statistics V3 mixes live habit state with date history and current-day overrides

## 2. Architecture map

Weekly Report
-> Statistics V3
-> schedules
-> completion records
-> streaks
-> Diary V2
-> auth/scope
-> cache
-> notifications
-> premium

Concrete map:

- Statistics V3 screen: `lib/features/statistics/presentation/v3/screens/statistics_v3_screen.dart`
- Statistics V3 data adapter: `lib/features/statistics/presentation/v3/application/statistics_v3_data_adapter.dart`
- Habit-day summary helper: `lib/features/habits/domain/habit_day_summary.dart`
- Habit schedule normalizer: `lib/data/mappers/habit_schedule_normalizer.dart`
- Habit persistence / mutations: `lib/stores/user_state_store_habits.dart`
- Daily reset / view-date hydration / history snapshots: `lib/stores/user_state_store_core.dart`
- Streak models: `lib/features/habits/domain/models/active_streak_shield.dart`, `lib/features/habits/domain/models/recoverable_streak_break.dart`
- Streak rollover logic: `lib/stores/user_state_store_core.dart`
- Diary V2 model: `lib/models/diary_entry.dart`
- Diary V2 store sync: `lib/stores/user_state_store_diary.dart`
- Diary V2 Supabase repo: `lib/data/repositories/diary_v2_supabase_repository.dart`
- Auth scope and stale-result guards: `lib/application/auth/auth_controller.dart`, `lib/stores/user_state_store_core.dart`
- Notification runtime: `lib/services/notification_service.dart`
- Notification clock/timezone: `lib/features/notifications/domain/notification_clock.dart`
- Notification scheduling / routing: `lib/features/notifications/application/notification_schedule_policy.dart`, `lib/features/notifications/application/notification_interaction_router.dart`
- Cache patterns: `lib/data/local/authoritative_bootstrap_cache_v2.dart` via `lib/application/bootstrap/bootstrap_controller.dart`, plus scope-guarded stores in notifications/shop/habits
- Premium seam today: no explicit entitlement abstraction found; only adjacent shop/wallet systems exist

## 3. Canonical metrics audit

Current completion math is implemented in `buildStatisticsV3ViewData(...)`:

- file: `lib/features/statistics/presentation/v3/application/statistics_v3_data_adapter.dart:18`
- period consistency: `_buildPeriodConsistencyStats(...)`
- day-level scheduling: `_expectedHabitIdsForDay(...)`
- day-level completion: `_completedHabitIdsForDay(...)`
- current-day/live override: current view-date logic in `UserStateStore`

Where the math lives:

- UI consumes prepared view data in `StatisticsV3Screen`
- the adapter computes counts, percentages, families, highlighted habits, activity shells, and reward totals
- `HabitDaySummary` re-implements a similar but not identical interpretation for habit-detail views

Current canonical-ish inputs:

- `activeHabits`
- `userState.history.habitCompletions`
- `userState.history.habitCountValues`
- `userState.history.habitSkips`
- `userState.history.habitCompletionTimes`
- current date / selected date

Current outputs:

- `scheduledCount` is effectively `expectedCount`
- `completedCount` is effectively `completedCount`
- `completionRate` is `completedCount / expectedCount`, rounded and clamped

Important observation:

- `timesPerWeek` is not represented by one shared formula today
- the Statistics V3 adapter has special-case logic for it
- `HabitDaySummary` has a separate weekly-quota interpretation

That means Weekly Report does not yet have a single reusable mathematical contract to consume.

## 4. Habit type matrix

| Habit type | Storage | Completion semantics | Statistics semantics | Weekly Report implication |
| --- | --- | --- | --- | --- |
| check | `doneToday`, `skippedToday`, `habitCompletions`, `habitCompletionTimes`, `habitSkips` | binary done / not done; skip cancels completion | counts as completed only when done; skipped removes it from completion counts | safe to use as binary completed occurrence |
| count | `progress`, `target`, `habitCountValues`, `habitCompletions`, `habitSkips` | completed when `progress >= target`; partial progress stays partial | partial progress is shown in habit detail, but completion math only counts threshold reached | completedCount should ignore partial progress |

Notes:

- `count` completion is threshold-based, not proportional
- partial progress is visible in habit detail insights but does not count as completed
- current count persistence stores the raw progress value historically, which is useful

## 5. Schedule matrix

| Schedule | How it works now | Edge cases / notes |
| --- | --- | --- |
| daily | expected every day after creation and before archive/delete | normalized fallback when schedule is missing or invalid |
| weekly | expected only on listed weekdays | weekdays are normalized to integers 1..7 |
| once | expected only on the exact ISO date string | exact `YYYY-MM-DD`; invalid dates normalize away |
| timesPerWeek | weekly quota, not fixed weekdays | target is a weekly count; `weekStartsOn` defaults to Monday / 1 |

Current behavior details:

- schedule normalization is centralized in `HabitScheduleNormalizer`
- `createdAt` gates whether a habit existed on a date
- archived habits are excluded from expected/completed counts
- deleted habits can optionally purge history

`timesPerWeek` is the most important edge case:

- `HabitDaySummary` treats it as a weekly quota
- habit-detail stats also treat it as a weekly quota
- Statistics V3 still has a separate special-case path for it, which is a source of semantic drift

## 6. Historical reconstruction audit

What is already supported:

- per-day completion history
- per-day count values
- per-day skips
- per-day completion timestamps
- streak shield / streak break history
- createdAt-based "habit existed on this date" gating

What is partially supported:

- current habit identity data can often be reused for older dates
- remote merge uses `updatedAt` to decide whether to replace a local habit row
- the app can infer some history from current state plus history buckets

What is not supported:

- exact historical schedule version for "what did this habit look like on Wednesday last week"
- historical name / emoji / target snapshots
- a reliable schedule-change timeline
- a full historical pause timeline

Classification:

- historical completion data: `YA SOPORTADO`
- historical schedule identity: `PARCIALMENTE SOPORTADO`
- historical schedule/version reconstruction after edits: `NO SOPORTADO`

Implication for Weekly Report:

- the report will need its own snapshot strategy if it must remain stable after later habit edits
- otherwise it can only reflect the current habit definition projected over old completion history

## 7. Streak contract

Current streak system:

- completion is separate from streak continuity
- streak continuity is derived from rollover logic and streak status records
- shields and recoveries change continuity, not the underlying completion concept

Relevant code paths:

- rollover and status finalization: `lib/stores/user_state_store_core.dart:617`
- protected status: `lib/stores/user_state_store_core.dart:685`
- recoverable break creation: `lib/stores/user_state_store_core.dart:698`
- shield model: `lib/features/habits/domain/models/active_streak_shield.dart`
- recoverable break model: `lib/features/habits/domain/models/recoverable_streak_break.dart`

Meaning:

- `completed` is the occurrence being done for the day
- `shield` prevents a missed occurrence from breaking continuity
- `recover` restores continuity after a break
- neither shield nor recover should be assumed to mean the occurrence was completed

This is important for Weekly Report:

- Weekly Report should not automatically treat shielded or recovered days as completed days unless the productive domain already says so

## 8. Timezone contract

Current state:

- device timezone is read through `flutter_timezone` in `lib/features/habits/data/cloud/device_time_zone_provider.dart`
- notification runtime initializes timezone data and resolves a local `tz.Location` in `lib/services/notification_service.dart`
- notification clock has a `timezoneId()` abstraction in `lib/features/notifications/domain/notification_clock.dart`
- streak-protection sync validates IANA time zones and stores logical timezone context on the habit side

The app is already DST-aware in the sense that it uses IANA zones, not fixed UTC offsets.

What is canonical today:

- there is no single universal timezone store for every feature
- notifications persist their own `timezoneId`
- streak protection persists a habit logical timezone

Recommendation for Weekly Report:

- use the persisted logical IANA timezone that already drives habit-day boundaries
- fallback to device local IANA timezone when no persisted habit timezone is available
- do not hardcode UTC or `Europe/Madrid`

## 9. Diary V2 integration audit

Current model:

- `DiaryEntry` is defined in `lib/models/diary_entry.dart`
- fields: `id`, `createdAt`, `dateKey`, `text`, `title`, `body`, `remoteId`, `habitId`, `familyId`, `mood`, `entryType`, `tags`, `isPinned`
- current enum values: `learning`, `reflection`, `moment`, `gratitude`

Current local persistence:

- entries live in `userState['diaryEntries']`
- daily mood lives in `userState['dailyMoods']`
- store sync is handled in `lib/stores/user_state_store_diary.dart`

Current Supabase persistence:

- table `diary_entries`
- table `daily_moods`
- local ids are used as the stable client-side key
- remote ids are stored back into the local model when sync succeeds

Current sync behavior:

- create, update, delete are best-effort
- remote pulls merge by local id
- local/remote conflict resolution is timestamp-based
- user scope is validated before sync

Future `weekly_report_reflection` seam:

- the current `entryType` enum does not yet have a weekly-report-specific value
- a dedicated `weeklyReportId` or `contextId` field is needed for a real 1:1 relationship
- the cleanest extension is additive, not overload-only
- Supabase already has a `metadata` field in the row mapping, which is a possible compatibility seam

Best recommendation:

- add a first-class nullable `weeklyReportId` field later rather than overloading `entryType`

## 10. Auth/cache/multi-user contract

Current robust pattern:

- `AuthController` owns sign-in/sign-out and session transitions
- `UserStateStore` owns local scope switching and scope epoch invalidation
- stale auth events after a local sign-out are explicitly ignored
- stale async work is guarded by scope epoch and operation keys

Relevant code:

- `lib/application/auth/auth_controller.dart:61` for `scopeKey`
- `lib/application/auth/auth_controller.dart:335` for sign-out
- `lib/application/auth/auth_controller.dart:467` for auth stream stale-event handling
- `lib/stores/user_state_store_core.dart:169` for local scope switching
- `lib/stores/user_state_store_core.dart:766` for stale load result discards

Cache / stale-result patterns already in the app:

- scope-epoch invalidation
- in-flight task deduplication
- user-scoped persisted caches
- "discard if current user changed" guards

Weekly Report should copy this exact style:

- key every async task by `userId + scopeEpoch`
- discard any computation whose user/epoch no longer matches
- never let a stale result reopen private data after logout

## 11. Notification integration map

Current runtime:

- `NotificationService.init()` initializes timezone data, resolves local location, creates the notification channel, and performs one-time cleanup
- `NotificationInteractionRouter` consumes payloads and routes `journalNudge` into `DiaryV2EntryEditorScreen`
- `NotificationSchedulePolicy` builds slot-based opportunities and assigns timezone semantics per slot
- schedule manifests are stored in shared preferences with scope and timezone metadata

Relevant files:

- `lib/services/notification_service.dart`
- `lib/features/notifications/application/notification_interaction_router.dart`
- `lib/features/notifications/application/notification_schedule_policy.dart`
- `lib/features/notifications/data/local/shared_preferences_notification_schedule_store.dart`

Implication for Weekly Report:

- the future weekly-report notification should be a new payload kind, not a reused journal payload
- it should preserve scope, timezone, and destination routing exactly like the current notification stack
- route payloads only after confirming the current scope and `scopeEpoch`

## 12. Premium seam

What exists:

- no explicit `PremiumState` found
- no explicit entitlement abstraction found
- no RevenueCat integration found in the code paths inspected
- no subscription service seam found

What is adjacent:

- shop / wallet / utility systems exist and are robust
- these are not a premium entitlement layer

Recommendation:

- introduce a dedicated future interface for entitlement decisions, separate from shop currency and utility items
- Weekly Report should not depend on payments implementation details

## 13. Recommended shared metrics contract

Smallest useful shared contract:

```dart
class HabitRangeMetrics {
  final int scheduledCount;
  final int completedCount;
  final int completionRatePct;
  final Set<String> scheduledHabitIds;
  final Set<String> completedHabitIds;
}

class HabitMetricsCalculator {
  HabitRangeMetrics forDay({
    required DateTime localDay,
    required List<Map<String, dynamic>> activeHabits,
    required Map<String, dynamic> history,
    DateTime? today,
  });

  HabitRangeMetrics forRange({
    required DateTime start,
    required DateTime end,
    required List<Map<String, dynamic>> activeHabits,
    required Map<String, dynamic> history,
    DateTime? today,
  });
}
```

Inputs:

- current habit definitions
- history buckets
- target date or date range
- current date / live current-day override

Outputs:

- scheduled count
- completed count
- completion rate
- scheduled/completed habit ids

Files likely to change first:

- `lib/features/statistics/presentation/v3/application/statistics_v3_data_adapter.dart`
- `lib/features/habits/domain/habit_day_summary.dart`
- possibly `lib/stores/user_state_store_core.dart` only if a helper wants to reuse view-date hydration logic

Incremental strategy:

1. extract a pure calculator from the current Statistics V3 adapter
2. add characterization tests around its current outputs
3. switch Statistics V3 to the extracted helper
4. make Weekly Report consume the same helper

Important:

- do not try to unify everything at once
- first preserve current behavior
- then reuse the same pure math from both consumers

## 14. Risks / blockers

BLOCKER

- No historical versioning for habit schedule / target / name / emoji
- No unified canonical treatment for `timesPerWeek`
- No explicit canonical pause state in the metrics engine

HIGH

- Statistics V3 and habit detail already duplicate similar math in different shapes
- current-day live overrides can diverge from historical snapshots if not handled carefully
- Weekly Report could accidentally become a second implementation of habit math

MEDIUM

- Diary V2 does not yet have a weekly-report link field
- no entitlement seam exists yet for premium branching
- notification payloads need a new kind and routing rule later

LOW

- helper naming / file organization cleanup after the contract is extracted

## 15. Decisions required before Phase 2/3

Only the decisions that matter now:

1. Should Weekly Report use the current habit definition projected onto history, or should it snapshot resolved habit metadata at generation time?
2. What is the canonical meaning of `timesPerWeek` for report math: quota only, or quota plus per-day expected presence?
3. Which timezone is canonical for week boundaries: persisted habit logical timezone, notification timezone, or device timezone fallback?
4. Does a pause mean "not scheduled" or just "UI paused" for reporting?
5. Should weekly reflections become a dedicated Diary V2 type or a 1:1 relation field?

## 16. Recommended implementation order

Recommended order remains:

1. Phase 2 Domain
2. Phase 3 Supabase
3. Phase 4 Generator
4. Phase 5 Repository/cache

Adjustment based on the audit:

- Phase 2 must include the shared habit-metrics contract extraction
- timezone choice must be locked before Phase 3 schema decisions
- notification payload design should wait until the report snapshot contract is fixed

## 17. Test / validation notes

Tests executed:

- `flutter test test/features/statistics/v3/statistics_v3_data_adapter_test.dart test/features/statistics/v3/statistics_v3_consistency_calendar_shells_test.dart test/stores/user_state_store_schedule_guards_test.dart test/stores/user_state_store_times_per_week_schedule_test.dart test/models/diary_entry_test.dart test/data/repositories/diary_v2_supabase_repository_test.dart test/services/notification_rules_test.dart test/services/notification_service_test.dart test/application/auth/auth_controller_test.dart`

Result:

- the run completed with failures in existing tests
- failing areas included Statistics V3 expectations and notification rules expectations
- the auth controller tests exercised the stale-event and fail-closed paths successfully

Observed failures in this run:

- `test/features/statistics/v3/statistics_v3_data_adapter_test.dart`
- `test/services/notification_rules_test.dart`

No Supabase migrations were applied.
No production behavior was changed for this audit.

## 18. Second-pass contract details

### 18.1 `timesPerWeek`: exact current behavior

| Implementation | File | Function / class | Input | Semantics | Output |
| --- | --- | --- | --- | --- | --- |
| Normalization | `lib/data/mappers/habit_schedule_normalizer.dart` | `HabitScheduleNormalizer.normalize` | schedule map and legacy aliases | converts `frequencyMode`, `timesPerWeekTarget`, `goal`, or `times` to a positive `schedule.timesPerWeek`; preserves optional `weekStartsOn` | canonical schedule map |
| Store expected-day gate | `lib/stores/user_state_store_core.dart` | `_isScheduledForDate` / `_isHabitExpectedForDate` | habit, local date | `daily`, `once`, and `weekly` have date predicates; `timesPerWeek` falls through to `true`, therefore it is expected on every existing, non-archived day | boolean expected/not expected |
| Store hydration | `lib/stores/user_state_store_core.dart` | `_hydrateActiveHabitsForDate` | current user state and date | hydrates a date from history; for a check habit, `doneToday` is the persisted boolean unless skipped; `timesPerWeek` is not quota-gated here | live `activeHabits` fields |
| Habit-day summary | `lib/features/habits/domain/habit_day_summary.dart` | `buildHabitDaySummary` | active habits, history, selected day, today | includes `timesPerWeek` in `expectedHabits` every day; separately counts check completions across the selected Monday/Sunday-style window, respecting `weekStartsOn`; marks the habit completed once quota is met even when selected day is not complete | daily lists plus `weeklyCompletedCount`, `weeklyTargetCount`, `isWeeklyTargetMet` |
| Statistics V3 range | `lib/features/statistics/presentation/v3/application/statistics_v3_data_adapter.dart` | `_buildPeriodConsistencyStats` and callers | date range, current habits, history, today | special-cases check `timesPerWeek` as a quota for period summaries; completed occurrences are counted in the weekly window, and the current week uses elapsed days so future days do not penalize the percentage | expected/completed totals and percentage |
| Statistics V3 day shells | same adapter | `_buildDayCompletionStats`, weekly activity, calendar | one date, current habits, history | treats a `timesPerWeek` check as not daily-expected for day-level consistency; a completion can still contribute to the range quota | per-day expected/completed shell |
| Home / detail presentation | `lib/features/habits/domain/habit_day_summary.dart` and its consumers | pending/completed/skipped selectors | summary view habits | quota is a weekly progress concept, but the habit may still be displayed in the selected-day expected list | UI grouping and weekly progress |

For a check habit with `timesPerWeek = 3`, Monday and Wednesday completed, and no other completions:

- Store hydration considers the habit expected on each existing non-archived day and only sets the selected day's `doneToday` from that day's record.
- `HabitDaySummary` reports `weeklyCompletedCount = 2`, `weeklyTargetCount = 3`, and keeps it pending unless the selected day's completion or the weekly quota makes it completed.
- Statistics V3 range math reports `2 / 3` for a complete/elapsed weekly quota window, while its day activity does not create a daily denominator for this flexible schedule.

Answers to the concrete questions:

1. The current product does not assign three fixed weekdays.
2. It does not dynamically assign remaining days either.
3. There is no persisted `expected=true` occurrence for selected weekdays.
4. It is a quota in Statistics V3 and habit detail; the store's generic expected-day gate still treats it as expected every day.
5. Statistics V3 uses `timesPerWeek` as the denominator for the quota path, with elapsed-window handling for the current week and capped percentage.
6. `HabitDaySummary` uses a daily expected list plus a separate seven-day completion count; it does not use `timesPerWeek` as a daily denominator.
7. A skip suppresses the completion for the skipped day. It does not reduce the weekly quota target; a quota already met remains met.
8. `createdAt` excludes dates before creation. A mid-week creation can therefore produce fewer than seven eligible days, but there is no persisted partial-week denominator for the quota.
9. Current archive state excludes the habit; archive timing is not retained, so a later archived habit cannot be reconstructed exactly for older days.
10. A week is Monday-Sunday by default in the quota path, or starts at `weekStartsOn`; the current week is elapsed in Statistics V3, while `HabitDaySummary` scans the whole seven-day window.

Explicit divergence:

| Consumer A | Consumer B | Divergence |
| --- | --- | --- |
| Statistics V3 range | store / `HabitDaySummary` expected list | V3 treats flexible frequency as a quota rather than seven daily expected instances; store/summary expose it as expected each existing day |
| Statistics V3 day activity | `HabitDaySummary` selected-day summary | V3 avoids a daily penalty for `timesPerWeek`; summary can include the habit in the daily expected/completed/pending lists |
| Statistics V3 current-week quota | `HabitDaySummary` selected-day quota display | V3 uses elapsed days for current-week range math; summary scans all seven dates, including future dates, for weekly progress |

### 18.2 Check/count contract

`check` completion is the history record `history.habitCompletions[dateKey][habitId] == true`, provided the occurrence is scheduled and not skipped. Unchecking writes/removes the false completion state through the store path; it does not leave a completed result. A skip is recorded in `history.habitSkips`, suppresses completion, and is not itself completion.

`count` completion is `progress >= target`. `progress < target` is partial and not completed; equality and over-target values are completed. The raw daily progress is persisted in `history.habitCountValues`; the completion bucket is also finalized from the threshold. Lowering the current target can make the current live state complete without rewriting old count values. Changing the target later cannot tell which historical target applied, so historical completion can be misclassified after an edit.

Conceptual future result:

```text
HabitOccurrenceResult {
  scheduled: bool
  completed: bool
  skipped: bool
  progress: num?
  target: num?
}
```

All five values are not reliably reconstructable for arbitrary historical dates today. Completion, skip, and count progress are mostly available; scheduled depends on the current definition; target is current rather than historical; and pause/version metadata is absent.

### 18.3 Created, archive, and delete availability

| Field | Exists | Local | Supabase | Historically reliable |
| --- | --- | --- | --- | --- |
| `createdAt` | yes | habit map and `RemoteHabit.createdAt` | `habits.created_at` | yes when populated; legacy/missing values fall back to treating the habit as existing |
| `archivedAt` | no | no | no inspected column/model field | no |
| `deletedAt` | no for habits | no durable habit deletion timestamp | no inspected habit field; delete may purge local history | no |
| `activeFrom` | no | no | no | no |
| `activeUntil` | no | no | no | no |
| archive flag | yes: `archived` / `isArchived` | current habit map | `is_archived` | only current state, not the effective date |

There is no productive `paused`, `isPaused`, or inactive interval model in the inspected habit state, UX, or Supabase habit model. Archive is a visibility/lifecycle flag and should not be rebranded as pause.

### 18.4 Historical configuration strategy

| Strategy | Complexity | Sync / offline / multi-user | Reconstruction and compatibility |
| --- | --- | --- | --- |
| A. Configuration versions | high; new version rows and effective-date rules | needs conflict ordering and offline version merges; robust when implemented | exact schedule, target, name, emoji; compatible with Statistics after resolver migration |
| B. Daily planned-occurrence ledger | medium-high; materializes every eligible date | more writes and merge surface; naturally idempotent by `(user, habit, date)` | exact scheduled/completion denominator, but metadata still needs snapshot fields; good offline behavior |
| C. Incremental weekly snapshot | medium; generator and repair logic | fewer historical reads, but offline edits need durable event/snapshot reconciliation | reliable only from activation and only if every mutation updates the snapshot; weaker repairability |
| D. Activation epoch plus resolved report snapshot | lowest compatible change | one user-scoped activation marker and immutable report payload; offline generation is retryable/idempotent | does not repair arbitrary old Statistics history, but makes reports exact from activation; can carry schedule/target/name/emoji snapshots |

Recommendation: D for Weekly Report V1. At activation, establish a user-scoped `weeklyReportTrackingStartedAt` and, during report generation, resolve only dates on/after activation from the current occurrence ledger plus immutable per-report habit metadata. The first implementation should persist a report snapshot keyed by user and week, with deterministic upsert. If later product requirements need live historical analytics outside reports, add A rather than expanding the report generator into a general ledger. This is the smallest correct path and avoids a premature full version-history subsystem.

### 18.5 Backfill

V1 must not promise complete reports before the activation marker. Reports are reliable only from activation onward; the first report may be partial if activation occurs mid-week. This materially reduces complexity and avoids presenting a false denominator from current definitions projected onto old history.

### 18.6 Current-day source contract

Statistics uses persisted history for dates before today. For today it can read the live hydrated `activeHabits` state, while history may still contain the last rollover snapshot. The store hydrates today's live fields from history on load and finalizes the closed day during rollover. If the app closes before rollover, today's unsnapshotted live mutation can differ from the historical bucket; after sync/relogin, the persisted authoritative state wins and the live override is rebuilt.

Future canonical source:

- `date < today`: immutable daily occurrence/history record, never the current live habit map.
- `date == today`: live state layered over today's persisted record, then persisted before report finalization.
- `date > today`: not scheduled/completed for a report; future UI shells are neutral and excluded from denominator.

The report generator should snapshot only after resolving today's live state and should be idempotent if called again after rollover.

### 18.7 Timezone source

The device IANA timezone is obtained in `lib/features/habits/data/cloud/device_time_zone_provider.dart`. Notification scheduling initializes IANA data and resolves a `tz.Location` in `lib/services/notification_service.dart`; notification schedule manifests persist a `timezoneId`. Streak protection also carries logical timezone context on the habit side. There is no single user-profile timezone authority today, and the notification manifest is install/scope-local rather than a guaranteed cross-device user preference.

Recommended contract: `reportTimezoneId = persisted logical habit-day timezone when present, otherwise current device IANA timezone`. Snapshot `reportTimezoneId`, resolved `weekStartsOn`, `weekStartDate`, and `weekEndDate` in every immutable report. A device travel/change must affect only future unresolved weeks; already generated reports remain tied to their snapshot timezone.

### 18.8 Phase 0 fixture matrix

| Fixture | Status | Expected characterization |
| --- | --- | --- |
| check daily 0/7 | SUPPORTED NOW | seven scheduled, zero completed |
| check daily 3/7 | SUPPORTED NOW | three completed, four pending |
| check daily 7/7 | SUPPORTED NOW | 100% |
| count partial | SUPPORTED NOW | progress below target is visible but incomplete |
| count exact target | SUPPORTED NOW | completion at threshold |
| count over target | SUPPORTED NOW | completion above threshold |
| weekly scheduled weekday | SUPPORTED NOW | only listed weekdays expected |
| weekly non-scheduled weekday | SUPPORTED NOW | excluded from denominator |
| once before/exact/after date | SUPPORTED NOW | only exact date expected |
| timesPerWeek 0/N | SUPPORTED NOW | normalization rejects/falls back to positive target |
| timesPerWeek partial quota | SUPPORTED NOW | quota progress below target |
| timesPerWeek completed/exceeded quota | SUPPORTED NOW | met at target; percentage capped in V3 |
| timesPerWeek created midweek | SUPPORTED NOW | creation gate works, but no historical partial-week policy |
| first partial week | SUPPORTED NOW | current code has observable partial behavior; canonical report rule pending activation snapshot |
| archive midweek | NEEDS NEW INFRASTRUCTURE | archive flag exists, archive date does not |
| schedule edit midweek | NEEDS NEW INFRASTRUCTURE | no effective schedule history |
| target edit midweek | NEEDS NEW INFRASTRUCTURE | no effective target history |
| DST boundary | SUPPORTED NOW for local runtime | IANA timezone runtime exists; report snapshot not yet implemented |
| timezone travel/change | NEEDS NEW INFRASTRUCTURE | no single cross-device user timezone authority |

## 19. Characterization coverage and isolated failures

No new production code or new tests were added in this pass. Existing tests already characterize the requested behaviors, including check/count threshold semantics, daily/weekly/once schedules, `timesPerWeek`, Monday boundaries, skips, creation dates, calendar shells, and current-week elapsed handling. Adding duplicate tests would increase maintenance without resolving the identified consumer divergence.

The two originally failing files were rerun in isolation:

| Test file / test name | Expected | Actual | Relevant assertion | Baseline/regression | Weekly Report relation |
| --- | --- | --- | --- | --- | --- |
| `test/features/statistics/v3/statistics_v3_data_adapter_test.dart` / `highlighted habits returns the top 3 habits in descending completion order` | 3 items | 0 | line 1996: expected length 3, actual length 0 | reproducible on this branch; no audit production edits | unrelated presentation fixture failure |
| same file / `highlighted habits returns only the available habits when fewer than 3 have completions` | 2 items | 0 | line 2027: expected length 2, actual length 0 | reproducible on this branch | unrelated presentation fixture failure |
| same file / `families aggregates completions by family and returns up to 4 entries` | 4 items | 0 | line 2082: expected length 4, actual length 0 | reproducible on this branch | unrelated presentation fixture failure |
| `test/services/notification_rules_test.dart` / `only configured streak milestones from 7 days produce candidates` | 1 candidate | 0 | line 13: expected length 1, actual length 0 | reproducible on this branch | future notification integration must not assume this rule is green |
| same file / `orders a batch by completion timestamp and falls back to habit order` | `['early', 'late']` | `[]` | line 28: expected two ids, actual empty list | reproducible on this branch | unrelated notification rule failure |

These are baseline failures for this audit branch, not regressions caused by the documentation-only change. The isolated command completed with only the listed failures in each file.

## Phase 0 Decisions

- **D01 canonical completion semantics: RESOLVED.** A scheduled occurrence is completed only when a check record is true or a count reaches `progress >= target`, and never when skipped. Shields/recovery do not change completion.
- **D02 count partial semantics: RESOLVED.** Partial progress is reported as progress, but `completed=false` until the target is reached; over-target is completed.
- **D03 `timesPerWeek` semantics: RESOLVED FOR FUTURE REPORTS, CURRENT DIVERGENCE DOCUMENTED.** Treat it as a flexible weekly quota, not fixed weekday occurrences. `scheduledCount` is the quota for a complete week and the prorated eligible quota for an activation/partial week; do not use seven daily occurrences. This is the least-change interpretation matching V3 range math and habit detail. Existing store/day-summary daily exposure remains a compatibility divergence to migrate gradually.
- **D04 week boundary: RESOLVED.** Monday-Sunday, with a future explicit `weekStartsOn` only if product exposes it consistently; snapshot the resolved boundary in the report.
- **D05 timezone source: RESOLVED.** Use persisted logical habit-day IANA timezone where available, otherwise device IANA timezone; snapshot the chosen id and computed dates.
- **D06 historical schedule strategy: RESOLVED.** Use activation epoch plus immutable report-time occurrence/metadata snapshot for V1; reserve full configuration versions for broader future analytics.
- **D07 backfill policy: RESOLVED.** No reliable full backfill before activation; first post-rollout week may be partial.
- **D08 pause support: RESOLVED.** Rutio has no productive pause contract. Weekly Report V1 must not invent pause; only scheduled, completed, skipped, archived/current lifecycle data supported by the domain is eligible.
- **D09 streak shield semantics: RESOLVED.** Shield and recovery preserve/restore streak continuity only; they do not set completion true or inflate completion rate.
- **D10 current-day source: RESOLVED.** Before today use persisted occurrence history; today use live state layered over persistence and finalize before snapshot; future dates are excluded.
- **D11 shared metrics extraction strategy: RESOLVED.** Extract a pure `HabitOccurrenceEvaluator` and `WeeklyHabitMetrics` under `lib/features/habits/domain/metrics/`, characterize current outputs first, migrate Statistics V3, then detail/home and Weekly Report. Do not make notifications, rewards, UI, or premium part of this contract.

## 20. Exit status

Status: **READY_TO_CLOSE** for Phase 0. The three blockers are not implemented, but each has an explicit future strategy, scope, and decision. Phase 1 and Phase 2 were not started.

Next step: freeze this contract and begin a narrowly scoped Phase 1 design for the shared occurrence evaluator plus activation/snapshot schema, with no UI or notification work.
