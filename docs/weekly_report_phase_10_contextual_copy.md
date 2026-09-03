# Weekly Report Phase 10 — Contextual copy

1. Existing copy contract

`weekly_reports.message_keys` was already a JSONB array and was returned by the private payload builder, but the mapper discarded it. `content_version` was already the content/catalog version. `weekly_report_habits` had no observation field.

2. Backend vs Flutter responsibilities

The generator-side triggers select keys from snapshot metrics. Flutter only maps a known key to `AppLocalizations`; it never classifies a week.

3. Content versioning

The existing `content_version` remains the catalog version. `schema_version` and `metrics_policy_version` are unchanged.

4. Summary families

`summary_first_partial`, `summary_provisional`, `summary_no_schedule`, `summary_strong`, `summary_good`, `summary_mixed`, `summary_needs_recovery`, `summary_improved`, and `summary_declined`.

5. Summary policy/thresholds

Zero schedule wins; first partial wins next; provisional wins next. Final rates use strong >= .80, good >= .60, mixed >= .40, otherwise needs recovery.

6. Trend precedence

Improved/declined can qualify the copy when it adds useful context without contradicting the completion bucket. A high declined week remains strong; a low improved week remains constructive.

7. Provisional behavior

Provisional reports use “Por ahora…” / “For now…” keys and can be regenerated.

8. First partial behavior

The first partial week has dedicated copy and is not penalized for pre-activation days.

9. Catalog implementation

`app_private.weekly_report_copy_catalog` stores family, key, content version, and deterministic order. It stores no localized text and is not client writable.

10. Expanded Catalog Completion

V1 now contains exactly 102 approved keys: 78 summary keys and 24 habit
observation keys. The approved Spanish master is integrated in app_es.arb;
app_en.arb contains the reviewed natural English equivalents. Each approved
key is present in the private backend catalog, both ARB files, and the typed
WeeklyReportCopyResolver. Integrity tests assert family counts, cross-layer
parity, non-empty localized values, resolver coverage, and safe unknown-key
fallbacks.

The family counts are 8/8/6/10/10/10/10/8/8 for summary families and 8/8/8
for observation families. The catalog expansion remains additive within
content_version = 1, the Weekly Report contextual copy V1 catalog/policy.

11. Deterministic selection

Selection orders by `md5(user, week, family, content_version, habit)` and never uses random ordering.

12. Anti-repeat implementation

The selector excludes keys used by the latest four final reports, then falls back to the complete family pool if needed.

13. Habit observation families

Highlighted, stable, and needs_attention receive observations. Unavailable receives null.

14. Número de observations ES/EN

V1 ships 24 localized observation entries per language; observation pools are
structured for deterministic in-report and historical anti-repeat.

15. Observation persistence

`weekly_report_habits.observation_key` is populated inside the backend snapshot path and returned in the payload.

16. timesPerWeek handling

Observations use snapshot scheduled/completed counts and classification. They do not infer missed daily occurrences from empty dots.

17. Flutter copy resolver

`WeeklyReportCopyResolver` uses exhaustive typed switches and localized getters. No reflection or dynamic invocation is used.

18. Unknown/legacy key behavior

Unknown summary keys use a neutral localized fallback. Unknown observation keys are omitted. Missing legacy fields remain safe.

19. Language-switch behavior

The persisted key is unchanged; only the current `AppLocalizations` instance changes.

20. UI integration

Summary copy is inserted in the existing summary card. Observation copy appears only in expanded habit rows.

21. Scale preservation

No cards, charts, grouping, global spacing, recommendation, or reflection layout was redesigned.

22. Migration creada

`20260903120000_weekly_report_contextual_copy.sql`, forward-only and after the Phase 9 migration.

23. Generator/finalization integration

Before-insert/update triggers select keys after metric updates and the existing final guards freeze parent and child snapshots.

24. Security

Catalog and helper functions are private; no public write RPC or new client grant was added.

25. Tests añadidos

Resolver language switching and unknown/legacy fallback tests were added. SQL contracts are covered by migration structure and existing static security tests.

26. Tests/comandos ejecutados

`flutter gen-l10n` completed. Dart format/analyze/tests are run at delivery.

27. Dry-run

Supabase dry-run is not available in this environment unless the linked CLI project is authenticated; no real `db push` is performed.

28. Gaps diferidos

Additional catalog variants can be added by migration and ARB entries. Notifications remain Phase 12.

29. Riesgos restantes

The linked Supabase project must validate trigger ordering and SQL function replacement with `supabase db push --dry-run --linked` before applying.

30. Estado final

READY_TO_DEVICE_QA after linked SQL dry-run and the local test commands pass.
