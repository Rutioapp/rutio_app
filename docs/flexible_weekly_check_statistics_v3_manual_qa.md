# Flexible Weekly CHECK — Statistics V3 manual QA

Device-oriented smoke checklist for the Statistics V3 closure pass. Use a
real device or narrow emulator, with both light/dark theme if supported. Keep
the app locale and timezone fixed while recording results.

## Setup

- Create a CHECK habit with `timesPerWeek = 3`.
- Keep one daily CHECK and one weekday CHECK available for mixed-habit checks.
- Have at least one historical week and one current week available.
- If the app supports changing the week start, repeat the boundary checks with
  the configured start day.

## Scenarios

- [ ] Complete the flexible habit 2 times in the current week: Statistics V3
  shows `2/3` and does not mark the flexible habit as a daily failure.
- [ ] Complete it a third time: the weekly result reaches `3/3`.
- [ ] Complete it a fourth time: the raw activity remains visible as `4/3`,
  while progress visuals stay bounded at 100%.
- [ ] Skip the habit on a day: the skip is not counted as a completion and does
  not create an extra daily obligation.
- [ ] Open the monthly calendar: a flexible completion day has visible
  activity, a neutral flexible day is unavailable/neutral, and no flexible
  completion is converted into a one-day 0% failure.
- [ ] Open the yearly consistency view/heatmap: the same activity-only and
  neutral-day behavior is preserved across month boundaries.
- [ ] Open Last 7 Days in habit detail: the range shows seven calendar dates,
  including pending/future states where applicable; it does not become seven
  flexible obligations.
- [ ] Open the habit detail weekly section: current and previous weekly values
  use the weekly quota and preserve over-target completion.
- [ ] Open the habit detail monthly section: the objective is composed from
  weekly quota slices intersecting the month, with no daily expansion.
- [ ] Mix daily, weekday, and flexible CHECK habits: daily/weekday misses still
  appear where appropriate; flexible habits do not create false misses.
- [ ] Check a month boundary and a year boundary: a week crossing the boundary
  is not charged a full quota twice.
- [ ] Inspect a historical range with unavailable/incomplete history, if the
  app can reproduce it: the UI communicates unavailable or unverifiable data
  instead of presenting fabricated precision.

## Layout and accessibility

- [ ] Verify no overflow at a narrow phone width and landscape/compact width.
- [ ] Verify the calendar, heatmap, weekly summary, and insight text with
  increased system text size/Dynamic Type.
- [ ] Verify labels and colors remain understandable without relying only on
  color.

## Record

Record device, OS, app build, locale, timezone, configured week start, and the
result of each scenario. Capture screenshots for any discrepancy.
