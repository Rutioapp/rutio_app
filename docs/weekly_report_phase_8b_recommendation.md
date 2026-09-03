# Weekly Report Phase 8B — recommendation

Estado: READY_TO_DEVICE_QA

## 1. Existing contract audit

Phase 2 already defined `reduceFrequency`, `changeDays`, `simplifyTarget`,
`changeMoment` and `keepStable`. Phase 5 already transported recommendations,
but only as type/reason. The existing table had a JSON patch and a status; it
did not preserve enough historical identity/configuration for this feature.

## 2. V1 supported types

Only `reduceFrequency` is implemented, for `check` habits whose snapshot
schedule is `timesPerWeek` with a quota of at least two. Count targets, daily,
weekly-day, once, change-days and moment changes are deferred.

## 3. Candidate selection

Only `needs_attention` snapshot rows are eligible. Ordering is lowest
completion rate, highest scheduled count, then stable `habit_id` ascending.
There is at most one proposed recommendation per report.

## 4. Exclusions

No recommendation is created for a first partial week, zero scheduled rows,
unavailable rows, once schedules, unsupported schedule shapes, or quotas that
cannot be reduced to a positive integer.

## 5. First partial behavior

`is_first_partial_week` suppresses productive recommendations.

## 6. Provisional/final behavior

The backend may calculate a provisional candidate while refreshing, but the
read payload exposes recommendations only when the report is `final`.

## 7. Proposed patch schema

Version 1 is `{version: 1, type: reduceFrequency, current: {schedule},
proposed: {schedule}}`. The database validates object shape, type, version and
positive times-per-week values.

## 8. Snapshot semantics

The recommendation stores habit id, name, emoji, type, current config and the
patch. It does not depend on a live-habit join and is protected by the existing
final-child immutability trigger.

## 9. Policy version

`recommendation_policy_version = 1`.

## 10. UI

The compact block appears below the weekly summary/charts and before the habit
section. It is hidden when there is no recommendation.

## 11. Editor integration

The CTA reuses `HabitDetailScreen` in `editOnly` mode and passes the patch to
the existing `EditHabitTab`. No second editor or save path was introduced.

## 12. Stale live config

The editor compares the live times-per-week schedule with the snapshot current
schedule. If it differs, the proposed patch is not applied and a localized
message asks the user to review current values.

## 13. Deleted/archived behavior

The historical card still renders from the report. If no active live habit is
found, the CTA is disabled. The editor's existing archive behavior remains
unchanged.

## 14. Accessibility

The card has a semantic label containing title, habit and adjustment. The CTA
has a minimum 44x44 target and meaning is not conveyed by color alone.

## 15. Responsive/scale

The card uses compact padding and no fixed height. Its content wraps naturally
for narrow widths and large text.

## 16. Tests

Existing DTO/mapper/repository tests continue to cover recommendation transport;
the policy is additionally constrained by the static SQL contract and the
editor preview path. Device QA should cover final-only visibility, deleted
habit, stale live schedule, narrow width and text scale.

## 17. Deferred work

Count-target recommendations, richer copy catalog, interaction analytics,
accepted/dismissed action storage, entitlement gating and other recommendation
types remain deferred.
