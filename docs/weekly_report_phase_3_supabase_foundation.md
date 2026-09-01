# Weekly Report — Phase 3 Supabase foundation

## 1. Current Supabase architecture inspected

The linked project uses `public.habits` (`id uuid`, `user_id`, `name`, `emoji`, `habit_type`, `target_count`, `schedule jsonb`, `is_archived`, `created_at`, `updated_at`) and `public.habit_logs` (`habit_id`, `log_date`, `value`, `is_completed`). Ownership is normally enforced with `auth.uid() = user_id`. `app_private` is revoked from client roles, security-definer functions use `search_path = ''`, and the database owns `updated_at` through a trigger. Habit sync is local-first/best-effort; remote `updated_at` is server-generated, local timestamps are incomplete, schedule updates are not consistently mirrored, and hard delete has no tombstone.

Migration list was checked before implementation and had no drift through `20260831090000`.

## 2. Tables created

`weekly_report_activations`, `weekly_report_habit_config_versions`, `weekly_reports`, `weekly_report_days`, `weekly_report_habits`, and `weekly_report_recommendations`. No message catalog table was created.

## 3. Relationships

Reports belong to `auth.users`. Report children use `(report_id, user_id)` composite foreign keys, so a child cannot be attached across owners. Child rows cascade when an administrative report delete is eventually allowed. `habit_id` in snapshots/history is a logical reference without a foreign key, so deleting a habit cannot destroy historical context.

## 4. Snapshot strategy

Phase 4 will write a provisional report and its normalized day/habit children, then finalize it. Habit occurrences are stored as validated JSONB because they are already a small domain value object and this avoids a fourth child table. No colors or presentation data are persisted.

## 5. Effective habit configuration strategy

The feature-scoped history stores name, emoji, type, target, schedule, archive state, effective local date/timezone, source timestamp, and optional mutation id. Activation captures the current configuration of existing habits. A trigger captures later relevant changes and hard deletes after activation. A trusted backend seam can record the actual effective timestamp/local date for late offline mutations and is idempotent by `source_mutation_id`. The trigger's server-observed time is explicitly a fallback, not proof of when an offline mutation became effective.

```text
habit/config changes
       ↓
effective configuration history
       ↓
Phase 4 generator
       ↓
weekly_reports
 ├─ days
 └─ habits
```

## 6. Offline/sync implications

The current client sync sends a row and receives a server `updated_at`; it does not carry a reliable client mutation timestamp/version and does not sync every schedule update. Therefore Phase 4 must use the explicit trusted history seam when applying queued mutations, or the report must be marked non-authoritative for that interval. No migration pretends `now()` is the effective local time.

## 7. Activation/no-backfill strategy

The activation row is the authoritative boundary. A generator must exclude weeks ending before activation, mark the activation week as `is_first_partial_week` when applicable, and use the stored activation timezone/local date. No historical habit/config rows before activation are created.

## 8. Security/RLS strategy

All snapshot/history tables have RLS enabled. Authenticated clients receive no direct privileges on internal snapshots; future RPCs will enforce summary/full access policy server-side. Activation is the only directly readable own-state table. No RevenueCat or entitlement logic is introduced.

## 9. Final immutability

Database triggers reject update/delete of a final report and any insert/update/delete of its children. Provisional rows remain refreshable. A future administrative rebuild path is intentionally not implemented.

## 10. Indexes

Indexes cover latest/history report lookup, config history by user/habit/effective time, child pagination by report/user, and recommendation lookup. Primary/unique indexes are not duplicated.

## 11. Versioning

Reports default to `schema_version = 1`, `metrics_policy_version = 1`, and `content_version = 1`. `message_keys` is an array on the report to preserve future keys without creating the Phase 10 catalog.

## 12. Future RPC boundaries

Future RPCs should read internal snapshots and apply Free/Premium shaping. Snapshot writes, finalization, and effective-history assertions remain trusted-backend operations. `proposed_patch` is data for a future editor and never executes SQL.

## 13. Deferred work for Phase 4+

Generator math, exact `timesPerWeek` calculation, report repository/cache, RPC read endpoints, client sync mutation metadata, cron/jobs, UI, notifications, diary/reflection, Premium/RevenueCat, and copy catalog remain deferred.

## 14. Migration validation

`supabase migration list --linked` succeeded with local/remote parity before the migration. Docker was not used and no remote migration was applied. The static verification file follows the repository's transaction/rollback catalog checks. A linked dry-run must be run after review.

## 15. Risks

The main residual risk is late offline mutations: until sync supplies an effective mutation timestamp/local date, trigger rows are observed-at-server rows. Hard deletes are preserved only from activation onward. The current remote schema assumes the existing `public.is_valid_habit_schedule` helper and `app_private.set_updated_at` helper remain available.

## Decision summary

Recommendations are included as minimal proposal storage because Phase 2 already defines the contract; messages are deferred to Phase 10. The foundation is intentionally backend-only and does not duplicate the Dart metrics engine.

## Phase 3 Final Security & Integrity Review

### Effective config ordering

The canonical future query orders versions by `effective_from ASC`, `source_updated_at ASC NULLS LAST`, `created_at ASC`, `source_mutation_id ASC NULLS LAST`, and `id ASC`. `effective_local_date` is a partition/filtering context, never the ordering key. The final `id` tie-breaker makes ordering deterministic even when timestamps collide. A late offline mutation uses the explicit backend seam and its effective timestamp; the trigger fallback records server observation time and must not be treated as historical proof.

### Offline late mutation seam and idempotency

`effective_from` is the effective instant, `effective_local_date` and `effective_timezone_name` preserve the logical context, and `observed_at` records server arrival/observation. `source_updated_at` carries the source timestamp when available. `source_mutation_id` is unique within `(user_id, habit_id)` through a partial unique index; null means no idempotency key was supplied.

### Function privilege model

`public.activate_weekly_report(date,text)` is `SECURITY DEFINER`, derives ownership exclusively from `auth.uid()`, validates the IANA timezone, uses fixed `search_path = ''`, is idempotent on `(user_id)`, and is executable only by `authenticated` and `service_role`. Capture, occurrence-validation, config-recording, and immutability helpers are internal, fixed-search-path functions with execute revoked from `public`, `anon`, and `authenticated`.

### Exact client table privileges

| Table | RLS | anon SELECT/INSERT/UPDATE/DELETE | authenticated SELECT/INSERT/UPDATE/DELETE |
| --- | --- | --- | --- |
| `weekly_report_activations` | yes | no/no/no/no | yes/no/no/no |
| `weekly_report_habit_config_versions` | yes | no/no/no/no | no/no/no/no |
| `weekly_reports` | yes | no/no/no/no | no/no/no/no |
| `weekly_report_days` | yes | no/no/no/no | no/no/no/no |
| `weekly_report_habits` | yes | no/no/no/no | no/no/no/no |
| `weekly_report_recommendations` | yes | no/no/no/no | no/no/no/no |

Future RPCs are the only intended report read/write boundary. `service_role` is trusted backend access and bypasses ordinary RLS by platform design.

### Final report immutability

Final status blocks parent update/delete and child insert/update/delete for days, habits, and recommendations. Recommendations are treated as part of the closed snapshot: `status` and `acted_at` are not a post-final lifecycle channel in Phase 3. Any future user action should be stored separately, leaving recommendation type, reason, and proposed patch immutable.

### Delete, week, rate, and occurrences integrity

The habit delete trigger is `AFTER DELETE`, reads `OLD`, writes a logical history row without a habit FK, and therefore survives the physical habit delete. Week dates are plain `date` values: start must be ISO Monday and end must be that start plus six days. Partial activation weeks retain canonical Monday-Sunday boundaries. Reports, days, and habits all require NULL rate for zero schedule and a non-null rate in `[0,1]` otherwise. Occurrences must be an array whose elements are objects containing `date`, `scope`, `scheduleType`, `scheduled`, `completed`, and `skipped`; no UI fields are required.
