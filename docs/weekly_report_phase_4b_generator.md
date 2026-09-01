# Weekly Report — Phase 4B authoritative generator

Estado: **READY_TO_REVIEW** (migration creada, pendiente de dry-run/revisión; no aplicada).

## 1. Execution architecture

The generator is a small-helper SQL architecture: week-boundary, effective-config,
schedule, and quota helpers feed one transactional internal generator. It writes a
provisional parent and replaces its day/habit children in one transaction. No Flutter,
UI, cache, premium, diary, notification, recommendation, or production cron work is
included.

## 2. Generator functions

- `app_private.generate_or_refresh_weekly_report(uuid,date)` is the authoritative
  idempotent backend operation.
- `app_private.finalize_weekly_report(uuid,date)` refreshes, verifies the local close,
  then writes `status = 'final'` last.
- `app_private.weekly_report_week_bounds`, `weekly_report_effective_config`,
  `weekly_report_schedule_matches`, and `weekly_report_prorated_quota` are small
  internal helpers.
- A public refresh RPC is deferred: the existing Phase 3 contract intentionally keeps
  snapshot writes trusted-backend-only; no arbitrary historical client generation is
  exposed in 4B.

## 3. Data sources and effective configuration

Activation supplies the user boundary and IANA timezone. Config history supplies the
habit snapshot; activity comes from `habit_logs`, including `is_skipped` and orphaned
logical habit IDs after delete. Config selection uses `effective_from <= target instant`
and deterministic descending ordering by `effective_from`, `source_updated_at NULLS
LAST`, `created_at`, `source_mutation_id NULLS LAST`, and `id`. The target instant is
the next local midnight for each report date, so a version effective during a date is
the effective version for that date. This is the explicit date-granularity policy for
mid-day changes.

## 4. Activation and first partial

No activation means no report. Weeks ending at or before activation are rejected.
Weeks are always Monday–Sunday. The activation week is marked
`is_first_partial_week` when activation local date is after Monday; dates before it
are neutral `noPlan` days and never enter denominators.

## 5. Check, count, and skip

Check completion is `is_completed AND NOT is_skipped`. Count completion is
`value >= target effective for that date AND NOT is_skipped`; partial values remain
in `occurrences.progress` and do not complete. Skip remains scheduled, increments
`skipped_count`, and never completes, even if count value reaches target.

## 6. Schedules and snapshots

Daily, weekly ISO weekdays, and exact once dates create date-bound occurrences only
when eligible and not archived/deleted. Each habit snapshot uses the latest effective
metadata at week end plus per-date `occurrences` carrying effective target/schedule,
so a midweek configuration change is not hidden by a single live config.

## 7. timesPerWeek and config changes

`timesPerWeek` never creates scheduled daily occurrences. For effective-config
segments, the generator performs exactly one weekly rounding operation:
`ceil(sum(configuredQuota * eligibleDays) / 7)`. Thus a constant quota of 3 over a
full week is 3; the closed matrix is `0,1,1,2,2,3,3,3` for configured 3. A
Mon–Wed quota 5 plus Thu–Sun quota 3 is `ceil((5*3 + 3*4)/7) = 4`, not 5.
Seven one-day segments with quota 3 still produce 3. Raw valid completions are
capped by the resulting weekly quota. `weeklyQuota` and `scope = weeklyQuota` are
preserved in occurrences.

Daily rows do not receive a fabricated denominator or completed counter for
timesPerWeek; its raw activity is retained only in habit occurrences. Consequently
global scheduled counts need not equal the sum of daily scheduled counts. If a week
contains only timesPerWeek habits, `best_day` is `NULL`; with date-bound schedules,
best day uses only their real daily ratios.

For multiple versions on one local date, the latest version effective at the next local
midnight wins using the same deterministic instant ordering. That version supplies the
date's count target and schedule evaluation. This is a deliberate LocalDate policy:
`habit_logs` has one row per habit/date, so the generator does not invent intra-day
activity attribution.

## 8. Global metrics, best day, and trend

Global scheduled is date-bound scheduled occurrences plus weekly quotas. Global
completed is date-bound completions plus capped timesPerWeek completions. Zero scheduled
means `completion_rate = NULL`. Best day excludes zero-scheduled days and sorts by
completion rate, completed count, then earliest date. Trend compares the previous final
report only; first partial, missing previous final, or either zero denominator is
`unavailable`, otherwise exact delta signs classify improved/stable/declined.

## 9. Streak and late sync

No reliable canonical streak read is currently available to this generator, so
`streak_snapshot` remains NULL. Shield/recover affect continuity only, never completion.
Provisional refresh uses rows received by the backend after successful sync. Final is a
snapshot of data received at close; later mutations do not reopen it. An explicit,
versioned/admin rebuild is deferred.

## 10. Timezone/DST and security

Local midnight boundaries use `timestamp AT TIME ZONE` with the stored IANA timezone;
the generator never assumes 168 UTC hours. Internal functions are `SECURITY DEFINER`,
use `search_path = ''`, schema-qualified references, and have execute revoked from
client roles. No direct snapshot-table grants are added.

## 11. Idempotency and parity matrix

The `(user_id, week_start_date)` unique key plus transactional child replacement makes
generate-twice stable; a new log changes provisional output; final refresh is a no-op;
finalize-twice is idempotent. Parity fixtures are covered by the domain contract:

| Case | Expected |
|---|---|
| check 0/7, 3/7, 7/7 | exact binary completion rate |
| count 5/10, 10/10, 12/10 | only >= target completes |
| completion + skip | skipped, not completed |
| weekly / once | only configured weekday / exact date |
| timesPerWeek 3 | full=3; partial matrix 0,1,1,2,2,3,3,3 |
| zero scheduled | rate NULL |
| first partial / target or schedule change / delete midweek | local-date effective config and activation boundary |
| DST European week | Monday–Sunday local dates, offset changes allowed |

## 12. Deferred work and validation

Flutter repository/cache, DTO consumption, screens, premium/paywall, diary, notifications,
recommendations, copy, Home, cron, and rebuild remain Phase 5+. Validate with the
static SQL test, `git diff --check`, `supabase migration list --linked`, and
`supabase db push --dry-run --linked`. Do not apply the migration.
