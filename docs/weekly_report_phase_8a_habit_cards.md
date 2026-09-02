# Weekly Report Phase 8A — Habit cards

Estado: **READY_TO_REVIEW** para UI local y contratos existentes.

## 1. Data source

`WeeklyReportHabitsSection` consumes only `WeeklyReport.habits`, from the same
`WeeklyReportSnapshot` already loaded by the screen. It does not query live
habits or make one request per habit.

## 2. Snapshot identity

Name, emoji, type, target, schedule, counts, rate, occurrences and nullable
streak are taken from `WeeklyReportHabit`. The current Habit model cannot replace
snapshot identity.

## Classification Policy V1

Classification is now authoritative in the backend snapshot. The centralized
policy is:

- `scheduled_count = 0` or null/invalid rate → `unavailable`
- `completion_rate >= 0.80` → `highlighted`
- `completion_rate < 0.50` → `needs_attention`
- remaining valid rates → `stable`

The policy uses only generator metrics, is deterministic and versionable. It does
not use streak, skips, trend, emotions, family, history or recommendations. The
classification is computed at snapshot insertion by the backend policy trigger
and is protected by the existing final-child immutability guard. Flutter never
calculates it and never changes a missing legacy value to `stable`; missing legacy
payload fields map to `unavailable`.

## 3. Classification source

`weekly_report_habits.classification` is persisted as part of the snapshot and is
returned by the private payload builder. Public RPC signatures are unchanged.

## 4. Ordering

The payload is ordered by backend relevance groups: highlighted, stable,
needs_attention, unavailable. Highlighted/stable use rate descending then
completed descending; needs_attention uses rate ascending then scheduled
descending; all groups finish with name and habit ID ascending. No
`relevance_order` column was added because this order is reconstructible from
classification plus snapshot metrics. Flutter preserves the received order.

## 5. Card/row architecture

One compact bordered container holds compact rows. Each row contains snapshot
identity, backend result, a classification chip and seven small activity dots.
There is no tap action, editor, recommendation CTA or accordion.

## 6. Daily states

Date-bound occurrences map to Monday–Sunday by their snapshot date. Filled dots
mean completed; outlined neutral dots mean scheduled/incomplete; a minus-marked
dot means skipped; soft green means partial progress; empty neutral means no
activity/no schedule. Each dot also has an aggregated accessible label.

## 7. timesPerWeek representation

`scheduledCount`, `completedCount` and `completionRate` are rendered directly.
`weeklyQuota` occurrences can show activity on their actual occurrence date, but
missing days are neutral and are never presented as expected failures.

## 8. Count partial

Partial is detected only from occurrence `progress < target` and changes the dot
visual state. It never changes or recomputes the weekly completion rate.

## 9. Skip

Skipped remains distinct from incomplete, uses a minus marker, and is never
treated as completed or removed from the backend denominator.

## 10. Streak

The streak is rendered only when `WeeklyReportHabit.streakSnapshot` is non-null.
The mapper now preserves the nullable backend snapshot. No streak is calculated
in Flutter.

## 11. Responsive scale

The section follows Phase 6/Statistics V3 scale: 10px row padding, 13px habit
name, 11px result, 12px dots, and no fixed row height. Widths below 350 logical
pixels stack identity and details. No mockup-sized spacing or global UI scaling
was changed.

## Phase 6 Scale Preservation

Habit rows preserve the compact scale approved during device QA on Pixel 9 and do
not reintroduce the large cards/heights from the original mockup composition.

## 12. Accessibility

Each row exposes identity, result, classification and streak in one
semantic label. Day dots expose full weekday plus completed, skipped, partial,
pending, no schedule or no activity. Meaning does not depend on color alone.

## 13. L10n

Spanish and English keys were added for section title, classification/result
states, streak and day accessibility labels.

## 14. Tests

Widget tests cover three rows, snapshot rendering, 3/3 and 6/7 rates, zero
scheduled neutrality, nullable/present streak, timesPerWeek denominator, partial,
skip, narrow width and large text scale.

## 15. Deferred recommendation work

Recommendation engine/card, proposed patches, observation copy, Diary reflection,
Premium/paywall, history, Home entry point, notifications and analytics remain
outside Phase 8A. Habit trend and observation key are also deliberately deferred.
