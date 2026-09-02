# Weekly Report — Phase 6 Core UI

## Mockups used

The approved provisional, final/Premium-composition, free and paywall mockups were used for hierarchy and block order. Premium, recommendations, reflection, habits and history remain deferred.

## Statistics screens used as scale reference

The primary reference is `lib/features/statistics/presentation/v3/screens/statistics_v3_screen.dart`, with `statistics_v3_summary_card.dart` and `statistics_v3_weekly_activity_shell.dart` as the closest metric/card/chart references.

## Reused visual tokens/components

The UI follows the productive cream surfaces, dark green text, green progress, warm borders and Material theme already used by Statistics V3. No new design system or Supabase access was added to widgets.

## Statistics Scale Reference

- Horizontal padding: 14, matching the Statistics V3 list.
- Section spacing: 10–14, matching the V3 cards and weekly section.
- Card radius: 18 for the compact summary/card surface, aligned with the V3 summary card.
- Card padding: 14, matching the V3 summary card.
- Metric typography: compact 22px value and 11px label, below the V3 summary density where three report metrics must coexist.
- Chart sizing: responsive, with a 142px ring and a 210px daily chart area; no fixed mockup-sized hero height.
- Day labels: shared localized weekday helpers from `AppLocalizations`.
- Header spacing: Material `AppBar` plus 14px content padding and SafeArea.

## Device QA Scale Correction

Before this correction, Weekly Report used a visually oversized header, ring and chart viewport on Pixel 9, so the first viewport showed too little content compared with Statistics V3.

After the correction, the screen uses the Statistics V3 productive scale: 14px horizontal screen padding, 10–12px section gaps, 12px card padding, compact 15px section titles, 20px metric values, a smaller 112px ring with a 9px stroke, and a 170px daily chart viewport. Status banners use compact chip-like padding and 18px icons. The existing cream/green palette, typography family, semantics and responsive stacking remain unchanged. No global transform or business logic was changed.

## Second Device QA Scale Correction

The first compacting pass was still insufficient on Pixel 9. A second presentation-only reduction brings the screen closer to Statistics V3 and prioritizes vertical scan density for the future habits, recommendation and reflection phases.

The Statistics reference remains unchanged: the screen keeps 14px horizontal padding, uses 8px-level local gaps, 10px card padding, 16px card radius, smaller section labels and metric values, and compact status-chip treatment. The ring is now 94px with a 7px stroke and the daily chart viewport is 145px with 76px maximum bars. Debug actions are visually minimized while retaining accessible tap targets. No business logic, data contracts, semantics or responsive branching were changed.

## Screen architecture

`WeeklyReportScreen` provides `_WeeklyReportView`, `_ReportContent`, `_SummaryCard`, `_CompletionRing`, and `_DailyBars`. Future blocks can be inserted below the general visualization without rewriting the top half.

## State architecture

`WeeklyReportController` exposes loading, data, empty and recoverable failure. Data carries the real `WeeklyReportSnapshot`, including provisional/final and cached/stale source information.

## Ring implementation

The small reusable painter consumes only `summary.completionRate`. A null rate is neutral and never rendered as 0%. Semantics expose completed and scheduled counts.

## Daily bars implementation

Seven bars are rendered Monday–Sunday from `WeeklyReportDay`. No-plan days are neutral and are not treated as incomplete scheduled days.

## timesPerWeek visual contract

Global summary metrics use the backend `scheduledCount`. Daily bars use each day’s own schedule fields and do not manufacture a daily denominator or reconcile totals locally.

## Provisional/final/first-week states

Provisional reports show an informational Sunday update banner; finalized reports show the closed chip; first partial weeks show a neutral first-week banner and do not invent comparisons.

## Offline/error/empty

Stale cached snapshots remain visible with a discreet offline banner. Empty and network error states are neutral and retryable; technical exceptions are not shown.

## Accessibility

Ring and each daily bar have explicit localized semantics. No-plan and scheduled-incomplete states are distinguishable without color.

## Responsive behavior

The chart stacks below 350 logical pixels and uses flexible rows otherwise. Cards avoid fixed heights except for the compact chart viewport. Text can wrap under Dynamic Type.

## L10n

All visible Weekly Report copy and accessibility labels use the existing generated ES/EN localization pipeline.

## Tests

Controller/repository contract tests remain the domain authority tests from earlier phases. The screen is structured for widget tests covering states, semantics, narrow widths and text scaling.

## Deferred blocks for Phase 7/8/9/11

Premium/paywall and entitlement, recommendations and application, productive diary reflection, full history, Home entry point, notifications, definitive copy catalog and analytics are intentionally not implemented.
