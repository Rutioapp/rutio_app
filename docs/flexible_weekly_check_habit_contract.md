# Flexible weekly CHECK habit contract

This document is the source of truth for the flexible weekly CHECK habit. It
supersedes the previous WEEKLY COUNT TARGET decisions whenever they conflict:
the feature is not a COUNT habit with `targetPeriod.weekly`, and it has no
weekly economic claim or bonus.

The previous QA decision that hid Skip and excluded `timesPerWeek` from the
daily CompletedDayPhrase denominator is superseded. The final contract below
restores both daily decisions while keeping the weekly quota flexible.

## Final model

The representation is a normal CHECK habit with a flexible weekly schedule:

```json
{
  "type": "check",
  "schedule": {
    "type": "timesPerWeek",
    "timesPerWeek": 3,
    "weekStartsOn": 1
  }
}
```

`timesPerWeek = N` means that the user wants to complete the habit on N days
of the Monday–Sunday week. The habit is available every day and each day has
its own pending, completed, or skipped state. Skip does not reduce the weekly
target or count as a completion.

## Daily UI and semantics

The Home card is visually and behaviorally a CHECK card: one circle, no `+` or
`−` controls, normal tap/swipe completion, and the normal undo behavior. The
circle represents `completedToday`, never the weekly quota. The card remains
interactive after reaching the quota. Skip is available through the normal
CHECK swipe action. A skipped day has no reward and remains excluded from the
weekly completed-day count; the habit is available again tomorrow.

The secondary label is localized as `Objetivo semanal · 2/3 días` in Spanish
and `Weekly goal · 2/3 days` in English. It may show 3/3, 4/3, or higher.

Home pending/completed/skipped filters use today's CHECK resolution. A pending
`timesPerWeek` habit participates in the daily denominator and blocks
CompletedDayPhrase; completed and skipped habits both resolve the day for the
phrase. The weekly quota is irrelevant to this decision. Skip still does not
mean a perfect day: any independent perfect-day concept may continue to require
zero skips. Streaks remain outside this feature's scope; no seven-day streak is
introduced.

CompletedDayPhrase eligibility means that there is at least one relevant habit,
the selected date is local today, the data is ready, and
`pending == 0` with `completed + skipped == total`. Thus a day with only skips,
or a mix of completions and skips, can show the same phrase. Historical dates
remain ineligible.

## Weekly progress

`weeklyCompletedDays` is derived, never persisted as mutable weekly state. The
calculator reads canonical daily CHECK completion history, takes the local
Monday–Sunday range, and counts distinct completed date keys. Thus three days
produce 3/3, a fourth produces 4/3, and the next week starts automatically
without changing historical logs.

## Rewards

Each newly completed day reuses the existing normal CHECK daily reward path,
with its existing idempotency and same-day behavior. Reaching 3/3 does not
create an additional reward. Completing a new day at 4/3 still receives the
normal CHECK reward for that day.

## Create, Edit, onboarding, and persistence

Create, Edit, and onboarding use the same functional habit-form sections for
tracking type and frequency. Onboarding only wraps those sections with its
draft state and CTA/navigation; it does not maintain a second form
implementation or perform persistence side effects. CHECK onboarding therefore
exposes the same `X times / week` control and preserves N when returning to the
step or resuming a draft.

All schedule summaries use one localized resolver. It renders `Every day` for
`daily`, `1 time per week`/`N times per week` for `timesPerWeek`, and the
localized short weekday list for fixed weekdays. A `timesPerWeek` schedule must
never fall back to `Every day`/`Todos los días` merely because it has no
weekday list.

Create, Edit, and onboarding persist the
canonical schedule above. Local and remote round-trips preserve
`timesPerWeek`; the schedule normalizer accepts the remote spelling
case-insensitively and does not fall back to `daily`.

No `HabitTargetPeriod`, `target_period`, weekly claim ledger, weekly reward RPC,
or `reward_period` is part of this contract. The obsolete, undeployed
migrations and tests for those concepts were removed. Existing pre-flight
documents remain as historical records. Existing Statistics and Weekly Report
are intentionally not redesigned; their future work should report raw
`completedDaysThisWeek / timesPerWeek` without using the reward ledger.
