# Weekly Report — Phase 11 history and productive entry points

## 1. Existing history API audit

The existing Phase 5 repository exposes `getHistory({beforeWeekStart, limit})`, backed by `list_my_weekly_reports`. Its remote rows are lightweight summaries containing report id, week start/end, status, completion rate, completed/scheduled counts, first-partial-week flag, refreshed/finalized timestamps. Trend and message key are not part of the history summary; the available fields are sufficient for a compact selection row. The cursor is the last returned `weekStart` and the server returns descending weeks.

## 2. History architecture

`WeeklyReportHistoryScreen` loads latest plus the first summary page. It renders a small current section and a compact previous-weeks list. Selecting a row opens the existing `WeeklyReportScreen` with a report id.

## 3. Summary vs full payload

History rows never load habits, days, recommendations or reflections. A full snapshot is fetched only by `getById(reportId)` when the user opens a row.

## 4. Pagination

Pages use the existing `beforeWeekStart` cursor and a limit of 20. “Load more” is intentionally explicit and avoids an infinite-scroll dependency. Client rows are deduplicated by report id and sorted by week start descending.

## 5. Current vs historical

Latest is shown as “This week” when available. Historical content is restricted to finalized summaries and excludes the latest report id, preventing duplicate presentation when latest is also final. A provisional report is never presented as a closed historical week.

## Product Entry Point Decision

The final V1 product entry point is `Drawer → Weekly Report`. The Home and Statistics entry points from the first Phase 11 implementation were removed to avoid duplication, keep Home centered on habits, keep Statistics centered on continuous analysis, and give Weekly Report one stable primary-navigation location. History remains inside Weekly Report.

## History access

The final V1 internal flow is `Drawer → Weekly Report → history icon → Weekly Report History`. Home and Statistics have no entry point; Drawer remains the primary entry. The history action is available on latest, empty, loading and error states, while a report opened from History hides the action to avoid creating a History → Report → History loop.

## 6. Statistics entry point

Statistics V3 has no Weekly Report entry point.

## 7. Home entry point

Home has no Weekly Report entry point and remains focused on habits.

## 8. Routing

Stable routes are `/weekly-report`, `/weekly-report/history`, and `/weekly-report/:id` (resolved by `onGenerateRoute`). Existing named routes remain intact.

The history bug was caused by the Phase 5 SQL function referencing `r.*` from outside the subquery where the row is aliased as `x`; the JSON builder therefore failed before returning rows. The migration now consistently uses `x.*`. This is a real backend migration fix, but `db push` was intentionally not run. An empty successful array is rendered as “no previous weeks”, not as an error.

## 9. Historical immutable read

The report screen accepts either no id (latest) or `reportId`. Id-based navigation calls `getById` and never refreshes or reconstructs the week from live habits.

## 10. Reflection lookup

The existing report reflection widget receives the loaded snapshot id, so historical reports use the Phase 9 `weeklyReportId` lookup and canonical edit/delete flow.

## 11. Recommendation historical behavior

Recommendation rendering and stale/deleted live-habit protections remain unchanged. Historical cards use the recommendation persisted in the snapshot.

## 12. Premium seam

No entitlement or paywall is introduced. The history screen is isolated and the existing full report screen remains the compositional boundary for a future Premium wrapper.

## 13. Cache strategy

History remains remote-first with retry. No new persistent summary cache was added. Individual report snapshots continue to use the scoped Phase 5 cache and immutable-final protections.

## 14. Scope protection

All repository calls use the existing user/epoch scope provider and stale-result guards. UI requests are disposed safely through mounted checks; repository results cannot publish across users.

## 15. Accessibility

History rows expose week range, completion summary and the action in one semantic label. Buttons use standard Material targets; meaning does not depend on color or trend icons.

## 16. Responsive/scale

Rows and entry cards use the compact Statistics V3 spacing, wrap naturally, and avoid fixed heights. The existing report screen retains its narrow-width and text-scale behavior.

## 17. L10n

Phase 11 labels are localized through the existing ES/EN `AppLocalizations` extension: report, history, current/previous sections, in-progress, empty, retry, load-more and unavailable states.

## 18. Tests

The implementation preserves the Phase 5 repository contract and adds presentation paths suitable for widget coverage: current/history separation, final filtering, id navigation, pagination deduplication, empty/error/retry and graceful entry-card failure behavior.

## 19. Deferred Phase 12 work

Notifications, scheduling, Sunday automatic generation, deep-link delivery and analytics remain deferred. No Premium work was added.
