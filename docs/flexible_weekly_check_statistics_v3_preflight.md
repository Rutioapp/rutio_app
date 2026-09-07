# Flexible Weekly Check — Statistics V3 Preflight

## 1. Executive summary

This is an audit and technical design only. No production code, Weekly Report,
Home, rewards, Supabase, migrations, Auth, or `CompletedDayPhrase` was changed.

Statistics V3 already has a separate `timesPerWeek` contribution path, so the
feature is not currently expanded into seven fixed daily obligations. However,
the implementation is not yet the final Statistics contract:

- `lib/features/statistics/presentation/v3/application/statistics_v3_data_adapter.dart`
  adds one quota per week but caps completed values at the quota.
- The same adapter uses elapsed-window rounding for the current period. This
  conflicts with the requested open-week display (`2/3` on Wednesday, not a
  reduced target) and makes monthly attribution dependent on the current day.
- Daily calendar/heatmap data still comes from daily expected/completed sets;
  a flexible weekly check must contribute activity without creating a daily
  miss.
- Current Statistics reads `store.activeHabits`, current schedule fields, and
  daily history. There is no canonical configuration timeline in the state
  consumed by Statistics, so historical schedule changes cannot be reconstructed
  safely from the current habit alone.

Recommended contract: derive distinct completed dates from completion history,
derive an effective weekly quota from the configuration effective during each
week, keep raw `completedDays / quota`, cap only presentation ratios that need a
bounded visual, and never treat a pending or skipped flexible day as a daily
failure.

## 2. Current Statistics V3 architecture

### Entry point and view composition

`StatisticsV3Screen` in
`lib/features/statistics/presentation/v3/screens/statistics_v3_screen.dart`
observes `UserStateStore`, calls the adapter, and renders:

- `StatisticsV3SummaryCard` for completed count and reward totals;
- `StatisticsV3ConsistencyCard` for completed/total and a bounded ring;
- `StatisticsV3WeeklyActivityShell` for the seven-point weekly series;
- `StatisticsV3MonthlyCalendarShell` for daily month cells;
- `StatisticsV3YearlyConsistencyShell` for month summaries and daily dots;
- `StatisticsV3HabitListView` for per-habit labels;
- `StatisticsV3BestMomentCard`, family/highlight cards, improvement chip, and
  the global insight footer.

### Adapter and models

`buildStatisticsV3ViewData` and `buildStatisticsV3HabitListData` are in
`statistics_v3_data_adapter.dart`. The adapter derives:

- `StatisticsV3ViewData.totalDays`, `completedHabits`, `activeDays`, and
  `consistencyPct`;
- `StatisticsV3WeeklyActivityDay` values;
- `StatisticsV3MonthlyCalendarDay` values;
- `StatisticsV3YearlyConsistencyMonth` and day values;
- `StatisticsV3HabitListItem` values;
- best-moment and weekly-improvement data.

The public models are in
`lib/features/statistics/presentation/v3/models/statistics_v3_view_data.dart`.
`StatisticsV3Period` is in `statistics_v3_period.dart` and exposes day/week/
month/year. There is no public Statistics model carrying both raw and capped
quota ratios today.

### Current helper graph

The relevant private adapter methods are:

- `_buildPeriodConsistencyStats`: daily aggregation plus
  `_buildTimesPerWeekContribution`;
- `_buildDayCompletionStats`, `_expectedHabitIdsForDay`, and
  `_completedHabitIdsForDay`: daily expected/completed sets;
- `_buildWeeklyActivityData` and `_buildMonthlyCalendarData`: daily widget
  projections;
- `_buildYearlyConsistencyData` and `_buildYearlyConsistencyMonthDays`:
  year/month/day projections;
- `_buildWeeklyImprovementData`: current and previous consistency comparison;
- `_isScheduledForDate`, `_isTimesPerWeekCheckHabit`,
  `_timesPerWeekTargetOf`, and `_timesPerWeekWeekStartsOn`: schedule parsing.

## 3. Current schedule evaluation

The canonical persisted shape is `HabitKind.check` plus a schedule map such as:

```text
{ type: timesPerWeek, timesPerWeek: N, weekStartsOn: 1 }
```

Daily history is stored under `userState.history`:

- `habitCompletions[YYYY-MM-DD][habitId]` is the completion signal;
- `habitSkips[YYYY-MM-DD][habitId]` is the skip signal;
- `habitCompletionTimes[YYYY-MM-DD][habitId]` supplies optional timestamps;
- `habitCountValues[YYYY-MM-DD][habitId]` is for count habits, not flexible
  CHECK completion.

`activeHabits` provides current configuration, identity, `createdAt`, and
`archived`. The adapter excludes archived habits and generally cannot see a
removed/archived habit as a historical subject.

The domain metrics layer is separate and more explicit:

- `HabitOccurrenceEvaluator.evaluate` returns a daily result. For
  `timesPerWeek`, it deliberately returns `scheduled: false` and
  `scope: weeklyQuota`.
- `HabitOccurrenceEvaluator.effectiveScheduledQuota` delegates to
  `calculateEffectiveScheduledQuota`.
- `WeeklyHabitMetrics.fromOccurrences` derives weekly metrics.
- `HabitWeeklyCheckProgressCalculator` derives distinct completion days and
  excludes skips.
- `TimesPerWeekQuotaPolicy.proratedCeil` calculates an effective quota for a
  partial active week.

This domain split is useful, but Statistics V3 does not consume these domain
models; it reimplements equivalent logic privately in the presentation adapter.

## 4. Current timesPerWeek behavior

The current implementation correctly avoids the main daily-expansion mistake in
the period summary: `_isScheduledForDate` returns false for a CHECK
`timesPerWeek` habit, and `_buildTimesPerWeekContribution` adds one quota per
week encountered in the range. It therefore does not add seven daily expected
occurrences for `timesPerWeek=3`.

The important inconsistencies are:

1. `_buildTimesPerWeekContribution` returns zero when `from == to`, so a day
   period has no flexible-weekly contribution even when that day contains a
   completion. This is safe against a daily penalty but loses activity from a
   day-only Statistics period.
2. It bounds the range to `today`; this is appropriate for an open period but
   makes the same helper unsuitable as a general historical range aggregator.
3. It uses `_timesPerWeekExpectedCount`, which computes
   `round(activeDays / 7 * weeklyTarget)`, forces a minimum of one, and caps at
   active days. This is an elapsed-window policy, not the requested full open
   week quota policy.
4. It adds `completedCount += min(completedInWindow, expectedForWindow)`.
   Therefore `4/3` becomes `3/3` in the derived data and raw over-target data
   is irretrievably lost.
5. `WeeklyHabitMetrics.fromOccurrences` has the same early cap in
   `completedCount` and `completionRate`; it is suitable as an existing
   Weekly Report contract only if that contract remains unchanged, but it is
   not the raw Statistics model requested here.
6. The adapter's public `consistencyPct` clamps to `0..100`, and the ring,
   chart painter, and `StatisticsV3ConsistencyCard` also clamp visual progress.
   Those visual clamps are acceptable only after raw values have been retained.
7. Current habits are the only configuration set used by the adapter. A
   current schedule is therefore applied retroactively to old completion dates.

Existing tests document this behavior rather than the final contract. In
`test/features/statistics/v3/statistics_v3_data_adapter_test.dart`, the current
tests expect `1/2` on Friday for target three, expect a `4/3` case to remain
`100%`, and expect no day-period contribution. These are regression baselines
to revise during implementation, not evidence that the final contract is met.

## 5. Canonical statistical contract

For a complete week and a CHECK `timesPerWeek=N` habit:

```text
completedDays = count(distinct days with completion && !skip)
scheduledQuota = N
rawRatio = completedDays / scheduledQuota
cappedRatio = clamp(rawRatio, 0, 1)
```

The completion history, not rewards, is the source of completion. A completion
and skip on the same date resolves to skipped/non-completed, matching the
existing history readers and domain evaluator.

For `target=3`, Monday/Wednesday/Friday yields `3/3`, `1.0`, and `100%`.
Adding Saturday yields `4/3`, `1.333...`, and `133.3%` raw. The UI may show a
full ring or `100%` visual fill, but the model must retain `4`, `3`, and the raw
ratio.

`timesPerWeek` is only valid for CHECK in this product contract. A count habit
with a `timesPerWeek` schedule must continue using count semantics and must not
be routed through flexible CHECK quota logic.

## 6. Weekly calculation

The recommended weekly evaluator takes a `WeeklyReportWeek`, a configuration
segment effective during that week, and daily history. It should:

1. select the effective config for the week;
2. calculate the eligible days in the week from creation/archive/configuration
   boundaries;
3. calculate `scheduledQuota` once for that weekly bucket;
4. count distinct completed, non-skipped date keys in the eligible interval;
5. preserve the uncapped completion count and raw ratio.

For a complete active week, quota is exactly `N`; it is not seven and it is not
the number of days elapsed. For a partial active week, use the existing domain
policy (`proratedCeil`) only where a partial-week policy is explicitly required.

## 7. Current-week semantics

The current week is open, but its displayed target remains the full weekly quota
for an active habit. A target-three habit with two completions on Wednesday is
`2/3`, not `2/1`, `2/2`, or a daily-obligation rate. Future days are not
failures and pending days do not lower the ratio beyond the unchanged quota.

The current adapter's elapsed-window result conflicts with this decision and
must be replaced for the Statistics weekly summary. Future activity points may
remain neutral in the chart, but that is a display treatment and must not change
the weekly denominator.

## 8. Historical-week semantics

Closed weeks use the effective quota for that week and the distinct completed
dates inside that week's eligible interval. A skip remains a skip and never
becomes a completion or a quota reduction.

Creation and archival boundaries must be applied before quota calculation. A
habit created midweek, archived midweek, or absent for part of a custom range
has an eligible interval, not seven obligations. The quota policy for an
eligible partial week should be the existing `proratedCeil` policy until Product
explicitly changes that contract.

The current adapter cannot reliably do this for archived or historically changed
habits because it starts from `store.activeHabits` and current fields.

## 9. Partial-week policy

Reuse `TimesPerWeekQuotaPolicy.proratedCeil` and
`calculateEffectiveScheduledQuota` as the current canonical partial-week
formula:

```text
eligibleDays = intersection(week, active interval)
quota = min(N, max(0, ceil(N * eligibleDays / 7)))
```

Examples from the existing domain tests for `N=3` are 0→0, 1→1, 2→1,
3→2, 4→2, 5→3, 6→3, and 7→3 eligible days. `N=1` remains one for any
non-empty eligible week.

This policy applies to creation/archive/range boundaries, not to the current
day merely because the week is still open. A full current week remains target
`N` for the weekly UI.

## 10. Monthly aggregation

Monthly scheduled and completed totals must be aggregated by weekly quota
buckets, not by `daysInMonth * dailyExpected` and not by independently adding a
full quota to every month touched by a week.

Recommended algorithm:

1. Build the requested month interval, clipped to today only for the current
   month.
2. Partition the interval by the habit's `weekStartsOn` weeks.
3. For each habit/configuration segment/week intersection, compute eligible
   days and the effective quota once.
4. Attribute that quota to the month using an explicit boundary policy (see
   section 11), and count completions by their actual date keys in the same
   attributed interval.
5. Sum all habit buckets; calculate percentage only after summation.

The current year/month path calls `_buildDayCompletionStats` for every calendar
day and relies on `_buildTimesPerWeekContribution` at period-summary level.
That produces inconsistent granularity: the calendar is daily while the summary
is weekly, and `completedCount` is capped. The new aggregator should be the
single source for monthly summary totals and should expose a daily activity
projection separately.

## 11. Month-boundary handling

For a week spanning August 31 through September 6, do not assign the full quota
to both months. The recommended deterministic rule is interval attribution:

- quota is prorated to the eligible days of the week that fall in the month;
- use the same `ceil(N * monthEligibleDays / 7)` policy, capped at `N`, for the
  month slice;
- completions are counted only when their date lies in that month slice;
- the weekly view still owns the whole weekly quota and is not changed by the
  split.

This makes August and September additive for a custom month range, while the
weekly aggregate remains `N` exactly once. The rule must be implemented in the
period aggregator, not duplicated in calendar widgets. If Product instead
wants a week-owned-by-start-date policy, it must be decided before STAT-1;
the current code contains no canonical month-boundary helper to reuse.

## 12. Configuration history

There is no sufficient canonical configuration history today for Statistics to
reconstruct arbitrary historical quota changes. Evidence:

- habits carry current `schedule`, `createdAt`, and `archived` fields;
- `_stampWeeklyReportConfigMutation` in
  `lib/stores/user_state_store_habits.dart` stamps `sourceMutationId`,
  `effectiveFrom`, and optional `effectiveTimezoneName` on the current habit;
- subsequent mutations overwrite those fields rather than append a timeline;
- history contains completion, skip, count-value, completion-time, and
  occurrence-status maps, but no `habitConfigurationHistory`/schedule timeline;
- remote habit mapping persists current habit configuration, not an append-only
  configuration event stream.

Therefore the answer is **NO** for arbitrary historical reconstruction from
Statistics's current inputs. `createdAt` can support creation boundaries and
the current `archived` flag can support present-day filtering, but an archive
date and prior `timesPerWeek` values are not reliably available. Persisted
Weekly Report snapshots may contain historical report values, but they are not
a general Statistics configuration source and Weekly Report must not be changed
in this task.

Recommended contract for a future configuration timeline: each schedule edit
creates an immutable segment `{habitId, effectiveFrom, effectiveUntil?, kind,
schedule, timezone}`. Until that exists, Statistics should not silently infer a
past target from the current schedule; it should document the limitation or
exclude unverifiable historical quota buckets.

## 13. Calendar impact

`StatisticsV3MonthlyCalendarDay` is currently a daily expected/completed cell.
For a flexible CHECK:

- completed day: show real completion activity;
- skipped day: show real skipped activity if the existing legend can represent
  it;
- pending/unrecorded day: show neutral/no activity, not an inferred missed
  daily obligation;
- a weekly quota should not be copied into every calendar date.

The smallest safe UI adaptation is to keep the existing daily cell shape,
return `expectedCount=0` for flexible CHECK daily cells unless the model has an
explicit activity denominator, and add a separate weekly quota summary rather
than reusing “missed day” intensity. The calendar remains activity-oriented;
the quota summary remains week-oriented.

## 14. Heatmap impact

The annual heatmap is implemented by
`StatisticsV3YearlyConsistencyShell` from
`StatisticsV3YearlyConsistencyMonth.days`, and each day currently consumes
`completedCount`, `expectedCount`, and `percentage` through
`StatisticsV3ConsistencyPalette`.

If a cell means activity/completion intensity, a flexible completion can add
real completion activity for that date. If a cell means daily obligation
percentage, it is incompatible with flexible weekly CHECK because no fixed
daily obligation exists. The recommended treatment is activity/neutral for
flexible days, with weekly quota percentages kept out of daily cells. Monthly
and annual totals should come from the period aggregator, not by summing these
daily visual cells.

## 15. Last 7 Days impact

Statistics V3's “last 7 days” habit list is built in
`buildStatisticsV3HabitListData`; the global weekly activity graph is built by
`_buildWeeklyActivityData`. Both are currently date-oriented. For flexible CHECK
they must count distinct completion dates and expose the weekly quota separately
when the selected scope is a week.

Do not use seven as the denominator for `timesPerWeek=3`. If the block is an
activity block, show completed active dates and skips/activity without a rate.
If it is a completion-rate block, use the relevant weekly quota bucket(s), not
seven daily occurrences. A seven-day window crossing two quota weeks must sum
the two effective quotas once each, with no duplicate week quota.

## 16. Per-habit statistics

The existing per-habit surface is `StatisticsV3HabitListItem`; it currently
formats a flexible habit as `completed/target` using current-week completion
count and target, while its global highlighted cards count completions.

Adapt existing metrics, without a new screen, to:

- this week: raw `completedDays / effectiveWeeklyQuota` (`4/3` allowed);
- weekly completion count: number of closed weeks with raw ratio `>= 1`;
- average completions/week: total distinct completed days divided by the
  number of included quota weeks, with the range policy explicit;
- skips: optional activity metric, never completion.

The current target source is `_timesPerWeekTargetOf(habit)` and therefore is
not historical-safe. The adapted item must receive derived period data rather
than rereading current configuration in the widget.

## 17. Global denominator

For each quota bucket, sum the denominator appropriate to that schedule:

```text
daily CHECK:       7 (for a complete week)
weekday CHECK:     number of configured weekdays (for a complete week)
timesPerWeek CHECK: N
```

Thus daily + Mon/Wed/Fri + flexible target three is `7 + 3 + 3`, not
`7 + 3 + 7`. For partial intervals, use each schedule's eligible denominator
and the shared period policy. Sum raw completed counts without converting a
flexible completion to a daily expected occurrence. Only the final global
visual percentage may be capped; the underlying totals and raw ratio remain
available for insights and auditability.

## 18. Over-target handling

`completed > scheduled` is valid only for flexible weekly CHECK quota. The
following current assumptions are risks:

- `min(completedInWindow, expectedForWindow)` in the adapter;
- `clamp(0, scheduledCount)` in `WeeklyHabitMetrics.fromOccurrences`;
- `consistencyPct.clamp(0, 100)` in the adapter;
- `StatisticsV3ConsistencyCard` and `_ProgressRingPainter` clamp visual fill;
- `_buildWeeklyActivityData` clamps plotted values to 100;
- percentage formatters and insight resolvers may assume a bounded ratio.

STAT-1 must preserve raw values before any of these UI clamps. The UI contract
can be `4/3` plus `100%` ring, or `4/3` plus a numeric `133%` insight, but must
not turn the data into `3/3`.

## 19. Skip handling

For flexible CHECK, a skip:

- does not increment completed days;
- does not reduce the weekly quota;
- does not create a daily scheduled miss;
- may increment a separate skipped/activity metric;
- must not be counted once as a skip and again as a missed daily obligation.

The current history readers already discard skipped completions in
`_completedHabitIdsForDay` and `_buildTimesPerWeekContribution`'s completion
reader. The new quota evaluator must preserve that behavior while not using
skip removal from the daily denominator as a substitute for weekly quota
calculation.

## 20. HabitOccurrenceEvaluator assessment

`HabitOccurrenceEvaluator` currently has a useful daily API and explicitly
returns `scope: weeklyQuota` with `scheduled: false` for `timesPerWeek`. Its
callers include the domain metric tests, parity tests, and Weekly Report
metrics. Deforming `evaluate` to return `scheduled: true` on every day would
reintroduce the architectural bug.

Recommendation: keep `evaluate` as a daily/date-bound API and complement it
with a `WeeklyQuotaEvaluator` (or equivalent domain service) that accepts a
week, effective configuration interval, and daily history. Reuse
`TimesPerWeekQuotaPolicy`, `WeeklyReportWeek`, and date utilities. Decide in
STAT-1 whether `WeeklyHabitMetrics` should gain an uncapped/raw mode; do not
change Weekly Report behavior as part of this preflight.

## 21. Recommended domain model

Add a derived, non-persisted model near the domain metrics layer:

```text
FlexibleWeeklyQuotaProgress {
  habitId
  weekStart
  weekEnd
  completedDays        // uncapped distinct completion dates
  scheduledQuota       // effective quota for the bucket
  skippedDays          // optional activity metric
  eligibleDays
  rawRatio
  cappedRatio
  isComparable
}
```

For adapter integration, add period-level results containing `completed` and
`scheduled` totals plus optional per-day activity. Derive them from history,
effective configuration segments, and the requested range. Do not persist the
model and do not use rewards, resolved-day phrase state, or current UI state as
the completion source.

## 22. Recommended period aggregator

Introduce one domain/application abstraction, for example
`HabitPeriodStatisticsAggregator`, with:

```text
aggregate(habits, history, configurationHistory, from, to, today)
  -> PeriodHabitStatistics
```

It should partition a range into schedule units:

- daily schedule: date units;
- weekday schedule: configured weekday date units;
- once schedule: its one date;
- flexible weekly CHECK: week/configuration segments.

It must return `completed`, `scheduled`, `rawRatio`, `cappedRatio`, skips, and
activity projections. A week is counted once. A month/custom range intersects
weekly buckets deterministically. This replaces private duplicate denominator
logic in `_buildPeriodConsistencyStats`, calendar/year helpers, and weekly
improvement calculations.

## 23. Existing UI KEEP/ADAPT matrix

| Widget/data surface | Decision | Required treatment |
|---|---|---|
| Summary card | ADAPT | Keep layout; feed quota-aware global totals. Rewards remain independent. |
| Consistency card/ring | ADAPT | Preserve raw ratio in data; cap only ring/fill if required. |
| Breakdown/family/highlights | ADAPT | Count real completions; do not count quota as seven occurrences. |
| Weekly summary/activity | ADAPT | Show completed/quota and activity; full target for open week. |
| Monthly summary | ADAPT | Aggregate quota slices by week; no daily expansion. |
| Monthly calendar | ADAPT | Activity/skip/neutral cells; no inferred flexible daily miss. |
| Annual heatmap | ADAPT | Activity semantics for flexible days; quota remains period-level. |
| Last 7 Days | ADAPT | Distinct completion dates and non-daily denominator semantics. |
| Per-habit list | ADAPT | `completed/effectiveQuota`, over-target raw data, historical config input. |
| Best moment | KEEP | Uses timestamped real completions; no quota logic needed. |
| Weekly improvement | ADAPT | Compare two period aggregates with full current-week quota. |
| Reward breakdown | KEEP | Reward transactions are not a completion source. |

No new Statistics screen or ARB key is required for the design. Reuse the
existing “Objetivo semanal” terminology from Home during implementation.

## 24. Weekly Report reuse boundary

Weekly Report must not be modified in this task. The future reusable boundary
should be the domain quota/period result from STAT-1, especially the effective
quota and distinct completed-day calculation. Weekly Report can consume that
model later, but Statistics must not import presentation adapters or persisted
Weekly Report snapshots as its source of truth.

## 25. Test strategy

### Existing focal tests executed

The following command passed with **107 tests**:

```text
flutter test test/features/statistics/v3/statistics_v3_data_adapter_test.dart \
  test/features/statistics/v3/statistics_v3_summary_breakdown_test.dart \
  test/features/habits/domain/metrics/habit_occurrence_evaluator_test.dart \
  test/features/habits/domain/metrics/habit_metrics_statistics_v3_parity_test.dart \
  test/features/habits/domain/metrics/weekly_check_progress_test.dart
```

Relevant test files also include Statistics V3 consistency/calendar shell
tests and habit-detail monthly/yearly helper tests. No production defect was
fixed by this run.

### Required implementation tests

Add domain and adapter tests for:

| Case | Expected |
|---|---|
| A. target 3, Mon/Wed/Fri complete | `3/3`, raw 1.0 |
| B. plus Sat complete | `4/3`, raw 1.333..., capped 1.0 |
| C. Mon complete, Tue skip, Wed/Fri complete | `3/3`; skip does not alter quota |
| D. target 3, only two completions | `2/3`, including open current week |
| E. daily + weekday + flexible habits | global denominator `7 + 3 + 3` |
| F. month with 4+ partial/full weeks | each weekly quota/slice counted once |
| G. habit created midweek | eligible-day quota policy, no pre-creation miss |
| H. target changed midweek | split configuration segments; no current-config retroactivity |
| I. archived midweek | quota/completions stop at archive boundary |
| J. year boundary | weeks/month slices do not duplicate or disappear |

Also test day/month/year activity cells, last-seven-day crossing a week
boundary, skipped flexible days, stale `doneToday`, absent config history, and
all completed/scheduled assumptions that currently clamp.

## 26. Exact implementation phases

### STAT-1 — domain quota evaluator and period aggregation

Keep daily `HabitOccurrenceEvaluator`; add weekly quota evaluation and a range
aggregator. Reuse `TimesPerWeekQuotaPolicy`, define partial and month-boundary
rules, retain raw/capped ratios, and add A–J domain tests.

### STAT-2 — StatisticsV3DataAdapter integration

Replace private flexible contribution/denominator logic with the aggregator.
Pass history and effective configuration inputs explicitly. Preserve reward
aggregation as a separate path.

### STAT-3 — weekly/monthly summary

Adapt consistency totals, weekly improvement, weekly activity data, and monthly
summary. Use full quota for an open week and weekly-bucket/month-slice rules for
closed and custom ranges. Update old elapsed-window/capped expectations.

### STAT-4 — calendar, heatmap, last-seven-day, and per-habit adjustments

Keep daily visuals activity-oriented, remove flexible daily-failure inference,
feed quota data to per-habit views, and audit all visual clamps and insight
formatters.

### STAT-5 — regression and QA

Run the focused suites, full Statistics V3 tests, golden/layout checks where
available, manual boundary checks for local timezone and year/month edges, and
`git diff --check`. Confirm no Weekly Report/Home/rewards/Supabase files are
changed.

## 27. Risks

- No append-only configuration history means historical target changes and
  archive dates cannot be proven from current state.
- Month-boundary prorating can differ from any future Weekly Report policy;
  the helper must be shared before both surfaces implement it.
- Current models use integer `expectedCount`/`completedCount` and bounded
  percentages; adding raw ratio without changing UI semantics can silently
  reintroduce caps.
- The day, month, and year projections currently use different granularity
  from the period summary.
- Current active-habit filtering can omit valid historical completions.
- Current tests protect old behavior for open-week elapsed targets and capped
  over-completion; they must be intentionally revised, not made flaky.
- Local timezone normalization and `weekStartsOn` must be consistent at month
  and year boundaries.

## 28. Critical decisions

1. **Weekly calculation:** distinct completed days divided by one effective
   weekly quota; never seven daily obligations.
2. **Over-target:** keep raw `4/3` and raw 133.3%; cap only bounded visuals.
3. **Skip:** NO quota reduction, NO completion, NO daily miss.
4. **Pending:** not an automatic failure for flexible weekly CHECK.
5. **Current week:** show progress against the full weekly target, e.g. `2/3`
   on Wednesday.
6. **Month:** aggregate weekly quota buckets and their range intersections.
7. **Month boundary:** attribute quota/completions to month slices once; never
   duplicate a full weekly quota in both months.
8. **Configuration history:** current information is insufficient for arbitrary
   historical reconstruction; do not infer old targets from current config.
9. **Midweek target change:** split at effective dates when canonical history
   exists; otherwise mark the historical result unverifiable rather than
   silently applying current config.
10. **Create/archive midweek:** use eligible intervals and the existing
    `proratedCeil` partial-week policy.
11. **Global denominator:** sum schedule-native denominators (`7 + weekdays +
    flexible quota`).
12. **Calendar:** real activity/skip/neutral; no flexible daily failure.
13. **Heatmap:** activity semantics for flexible days, not daily obligation
    percentages.
14. **Last 7 Days:** distinct activity/completions or quota buckets, never a
    seven-occurrence flexible denominator.
15. **Per-habit:** adapt existing list metrics to `completed/effectiveQuota`,
    weekly success count, and average completions/week.
16. **HabitOccurrenceEvaluator:** keep daily semantics and complement with a
    weekly evaluator.
17. **Weekly Report reuse:** share the domain quota/period result later; do not
    change Weekly Report now.
18. **Supabase:** no change is required for the derived calculation itself.
    Existing remote/current habit data is enough for forward-compatible data,
    but not for historical config reconstruction; that limitation must be
    explicit unless a future product decision adds history.
19. **Next phases:** STAT-1 through STAT-5 above, in order.

## Verification and scope

The only file created by this preflight is this document:
`docs/flexible_weekly_check_statistics_v3_preflight.md`.

Production implementation is intentionally **not done**. `git diff --check`
must be run after adding this document; pre-existing worktree changes are not
part of this audit and must remain untouched.
