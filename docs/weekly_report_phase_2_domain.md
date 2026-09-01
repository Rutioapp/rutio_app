# Weekly Report Phase 2 Domain

## Scope

This phase adds the pure domain base for Weekly Report plus the shared habit-occurrence metrics contract.

Implemented in this phase:

- `HabitSnapshot`
- `HabitSchedule`
- `HabitOccurrenceResult`
- `HabitOccurrenceEvaluator`
- `TimesPerWeekQuotaPolicy`
- `WeeklyReportWeek`
- `WeeklyHabitMetrics`
- Weekly Report domain models
- parity and characterization tests

Not implemented in this phase:

- Weekly Report UI
- navigation
- Supabase migrations
- `weekly_reports` table
- RPCs
- Edge Functions
- cron jobs
- authoritative generation / persistence
- repository / cache for Weekly Report
- notifications
- Diary integration
- RevenueCat / paywall logic
- analytics
- Home card
- history UI

## Shared Metrics Contract

The shared contract is:

`HabitSnapshot` + `HabitOccurrenceEvaluator` -> `HabitOccurrenceResult`

and then:

`HabitOccurrenceResult[]` + `WeeklyReportWeek` -> `WeeklyHabitMetrics`

The evaluator is intentionally small and pure.

### `HabitOccurrenceResult`

Represents a single evaluated occurrence with:

- `date`
- `scope`
- `scheduleType`
- `scheduled`
- `completed`
- `skipped`
- `progress`
- `target`
- optional weekly quota fields

`completed` is binary and does not imply partial progress.
Skip is distinct from incomplete.

### `WeeklyHabitMetrics`

Represents the weekly aggregation for a habit with:

- `scheduledCount`
- `completedCount`
- `skippedCount`
- `partialCount`
- `completionRate`
- optional `progressRate`
- original `occurrences`

When `scheduledCount == 0`, `completionRate` is `null`, not `0`.

## `timesPerWeek` Policy

`timesPerWeek` is treated as a flexible weekly quota, not fixed daily expectation.

Policy used in this phase:

- full eligible week: `scheduledCount = configuredTimesPerWeek`
- partial eligible week: `scheduledCount = ceil(configuredTimesPerWeek * eligibleDays / 7)`
- denominator is capped so it never exceeds the configured quota
- no artificial 7-day daily schedule is created

`eligibleDays` are the days inside the report week that are actually eligible after activation/start bounds are applied.

This is encapsulated in `TimesPerWeekQuotaPolicy` so the policy can change later without rewriting the evaluator contract.

## Week Semantics

`WeeklyReportWeek` uses:

- Monday as `weekStartDate`
- Sunday as `weekEndDate`
- conceptual local dates, not UTC duration semantics

The week boundary is stable and explicit.

## Zero Scheduled Semantics

If a weekly metric has no scheduled occurrences:

- `completionRate` is `null`
- the report should not surface a fake `0%` failure state
- comparable/trend logic can mark the item unavailable

## Weekly Report Domain

The report payload base now exists with:

- `WeeklyReport`
- `WeeklyReportStatus`
- `WeeklyReportSummary`
- `WeeklyReportDay`
- `WeeklyReportHabit`
- `WeeklyReportTrend`
- `WeeklyReportRecommendation`

Report state is currently modeled as:

- `provisional`
- `finalized`

The Dart enum intentionally uses `finalized` because `final` is a Dart keyword.
The future transport/persistence contract will map these values as follows:

- `WeeklyReportStatus.provisional` -> `"provisional"`
- `WeeklyReportStatus.finalized` -> `"final"`

DTO and Supabase serialization are outside this phase.

The report also carries version fields:

- `schemaVersion`
- `metricsPolicyVersion`
- `contentVersion`

## Habit Snapshot Decisions

`WeeklyReportHabit` is snapshot-oriented and does not depend on the current live Habit object.

It is prepared to store:

- `habitId`
- `name`
- `emoji`
- `type`
- `target`
- `schedule`
- `scheduledCount`
- `completedCount`
- `completionRate`
- weekly occurrence results
- optional streak snapshot

This is intentionally enough to keep report content stable even if the live habit changes later.

## Trend / Recommendation Contracts

Trend contract:

- `improved`
- `stable`
- `declined`
- `unavailable`

Recommendation contract:

- `reduceFrequency`
- `changeDays`
- `simplifyTarget`
- `changeMoment`
- `keepStable`

These are contracts only.
No recommendation engine is implemented yet.

## Parity With Statistics V3

The new contract was compared with Statistics V3 for the semantically stable cases:

- check daily
- count daily
- weekly schedule
- once schedule

`timesPerWeek` remains a separate weekly quota contract and is not forced into a daily denominator.

Statistics V3 still has unrelated baseline failures in highlighted habits / families tests, which were already present on this branch and were not changed by this phase.

## Pending Work For Phase 3 / 4

Phase 3 should consume this domain contract for persistence / schema work.

Phase 4 should generate Weekly Report payloads from:

- resolved daily occurrences
- weekly quota policy
- immutable habit snapshots
- week boundary + timezone snapshot

Still pending:

- transport DTOs
- storage / sync
- report generation orchestration
- UI rendering
- notification / diary integration
