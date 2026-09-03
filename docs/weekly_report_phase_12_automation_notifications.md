# Weekly Report Phase 12 — automation and notifications

## 1. Preflight audit

Phases 3–11 already provide the activation RPC, immutable snapshot tables,
authoritative generator/finalizer, refresh RPC, owner-scoped read API,
repository/cache, drawer route, history route, and `scopeEpoch` protection.
The existing notification stack is `NotificationService` + timezone-aware
`flutter_local_notifications`, V2 manifest/reconciler/orchestrator, payload
schema 2, foreground/background/cold-start pending payload handling, and the
permission/master preference gates. `weeklyReport` and the 50000–59999 ID
range were already reserved. No backend scheduler was present in the repo.

## 2. Product lifecycle

After authenticated bootstrap reaches Home, `WeeklyReportActivationService`
calls `activate_weekly_report(today, DeviceTimeZoneProvider IANA timezone)`.
The service coalesces concurrent calls and de-duplicates calls per user and
scope epoch. The first activation remains non-backfilling and may produce a
partial first week. Subsequent calls update only the current automation
timezone; `activated_at` remains the activation boundary and historical
week snapshots are untouched.

## 3. Server automation

The forward migration creates one `pg_cron` job, every 15 minutes, calling
`app_private.process_weekly_report_automation()`. The worker processes users
in deterministic order and isolates each user in an exception block. Sunday
from 19:00 local it creates the current provisional report once. Monday from
00:10 local it invokes the existing authoritative finalizer for the previous
week. The finalizer refreshes safely, handles a missing provisional report,
and writes `status = final` last. Existing final-report immutability triggers
remain authoritative. All calculations use stored IANA timezone names and are
DST-safe for Europe/Madrid and America/New_York.

## 4. Notifications and routing

Product Weekly Report notifications are independent of Personalized
Notifications V2 quota/selection, but still respect the real global master
switch and OS permission. The existing reconciler schedules eight individual
Sunday 20:00 occurrences, with no recurring opaque notification. Each ID is
deterministic from family, scope, exact week start and slot, and uses the
weekly range. Reconciliation replaces future entries after a timezone change
and never changes delivered entries.

Payload schema 2 uses `kind = futureWeeklyReport`, `family = weeklyReport`,
`route = weekly-report`, and `dateKey = YYYY-MM-DD` for the local Monday
`weekStartDate`; it contains no sensitive data. The router accepts the payload
in foreground, background and cold start, waits for authenticated bootstrap,
deduplicates it, resolves the exact week with
`get_my_weekly_report_by_week_start`, and opens `/weekly-report/:id`. A current
week miss may use the public current refresh RPC. A historical miss goes to
Weekly Report History and is never reconstructed client-side. Thus a Tuesday
tap on Sunday’s notification opens Sunday’s week, not the latest report.

## 5. Security, copy and tests

The by-week RPC is `SECURITY DEFINER`, hardened with `search_path = ''`,
uses `auth.uid()` ownership, is read-only and returns the existing full JSON
contract or null. Weekly copy is static/localized: Spanish “Revisa tu semana”
and English “Review your week”; no metrics or generative copy is used.

Added coverage includes repository by-week plumbing, weekly notification
payload/range integration points, exact-week routing, activation lifecycle,
and migration static inspection. Existing notification, router, bootstrap,
weekly report, immutability and history tests remain applicable. Debug
generate/refresh/recommendation/reflection actions remain QA-only; redundant
debug activation cleanup is deferred to Phase 13.

Validation: `dart format`, directed `flutter analyze`, directed Weekly Report
and notification tests, `git diff --check`, `supabase migration list --linked`,
and `supabase db push --dry-run --linked`. No migration was pushed remotely.

## Debug notification QA harness

`WeeklyReportScreen` exposes **Programar notificación semanal de prueba ·
Debug** only under `kDebugMode`, and only after a real report is loaded. It
uses the real `futureWeeklyReport` / `weeklyReport` type, schema-2 production
payload (`route=weekly-report`, `dateKey=weekStartDate`) and the existing OS
scheduler. Delivery is scheduled for approximately one minute in the future.

The previous harness scheduled directly through `NotificationScheduler` and
therefore bypassed the V2 manifest. A later bootstrap/foreground reconciliation
could correctly classify that otherwise valid V2 payload as
`orphan_native_owned_for_scope` and cancel it. The fixed harness creates a
debug-only `DesiredNotification`, sends it through the normal V2 coordinator,
and persists ownership in the manifest. Subsequent reconciliations retain the
pending debug entry; scheduling the same week again replaces the same logical
entry rather than creating a duplicate. Once its scheduled time is sufficiently
past and it is no longer pending in the OS, normal reconciliation cleans the
debug entry. The harness logs `pendingNotificationRequests()` after
reconciliation so QA can distinguish plugin registration from delivery.

The harness uses a deterministic platform ID in 60000–60999 and a debug-only
logical ID, so it cannot collide with production IDs. It does not create a
report, add a routing callback, change reconciliation rules for production, or
alter production cadence/settings. The notification copy is the same
localized production copy. Intended QA scenarios are foreground, background,
cold start, and historical/late tap; the existing router resolves the exact
week. The harness must remain debug-only or be removed during Phase 13 cleanup.

### Debug QA timezone contract

The device QA harness previously paired a local wall-clock value with the
runtime clock's `UTC` timezone, so `21:09 Europe/Madrid` could be sent to the
gateway as `21:09 UTC`. The harness now obtains the canonical IANA timezone
from `DeviceTimeZoneProvider`, passes the local wall-clock datetime together
with that timezone through `DesiredNotification`, and lets the timezone
package resolve the UTC instant. For example, `21:09 Europe/Madrid` becomes
`19:09Z` on 3 September. No offset is applied manually; DST remains owned by
the IANA timezone database. Product notification planning was not changed.
