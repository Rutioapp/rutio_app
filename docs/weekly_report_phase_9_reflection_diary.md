# Weekly Report Phase 9 — Reflection + Diary integration

Estado: READY_TO_DEVICE_QA (migration creada; no aplicada).

## 1. Existing Diary V2 contract

`DiaryEntry` is the local canonical model. It contains stable local `id`,
`createdAt`, optional title/body/legacy text, nullable entry-level mood in the
existing `-2..2` scale, tags, pin state and `DiaryEntryContentType`. The
existing values are `learning`, `reflection`, `moment` and `gratitude`.
`UserStateStore` is local-first, persists scoped JSON, and best-effort syncs
through `DiaryV2SupabaseRepository` to `public.diary_entries`. CRUD and the
Diary V2 editor already preserve unknown fields through `copyWith`.

## 2. Canonical entity and relation

Weekly reflection uses the existing `DiaryEntry` with
`entryType = reflection`; it is not a new entity or enum. A nullable
`weeklyReportId`/`weekly_report_id` contextual relation was added to the local
model, JSON mapping and remote repository. The FK lives on Diary, so immutable
`weekly_reports` rows do not need a reflection column.

## 3. Invariants and security

The forward migration adds a partial unique index for one reflection per
`(user_id, weekly_report_id)`, a lookup index, and an FK with `ON DELETE SET
NULL`. A security-definer trigger rejects a link when the report owner differs
from the Diary owner. Existing Diary RLS remains owner-scoped; ordinary entries
with a null relation are unaffected.

## 4. Report behavior

The composer is hidden for provisional reports and shown for final reports,
including a first partial week once finalized. It is independent of
recommendations. Composition remains: header/status, summary, charts, habits,
recommendation when present, then reflection. The report snapshot/cache is not
changed.

## 5. Create, update, delete and read flows

The compact composer creates one `DiaryEntry` on the report week-end date,
with optional text and the existing mood scale. Repeated submits are guarded
in-flight and the database invariant makes retries idempotent. Editing updates
the same local entry/id and preserves `createdAt`, type and relation. Diary
editing uses the existing editor and therefore preserves `weeklyReportId`.
For Weekly Reflection, `DiaryEntry.text` is the single canonical content field;
`body` and `title` remain null so compatibility renderers cannot display the
same content twice. Empty content is stored as `text = ""`.
The Diary list/filter sees it as a normal `reflection`; no parallel section or
filter was added. Deleting the Diary entry removes the relation with it and the
report shows an empty composer again. If the report is deleted, the Diary row
survives and its relation is nulled.

## 6. Offline and scope

Weekly writes use `UserStateStore`'s existing local-first persistence and
best-effort Diary V2 sync; no second sync engine was added. The composer checks
the captured user and `scopeEpoch` before publishing its result, preserving the
existing stale-user protection. A load failure in remote sync does not remove
the local entry.

## 7. UI, accessibility and l10n

The UI is a compact report section, not a hero card. It has empty, saved,
editing and saving states, preserves input during save, uses the shared mood
visuals, labels each mood for assistive technology, and uses a 44px save target.
The mood row is flexible and the text field wraps naturally for narrow widths
and larger text. Spanish and English copy is provided through the existing
localization extension.

## 8. Tests and validation

The migration is additive and includes FK/delete behavior, ownership trigger,
partial uniqueness and lookup indexing. Existing Diary model/repository and
Weekly Report composition tests remain applicable; Phase 9 UI/integration tests
should be extended during device QA with final/provisional, create/edit/delete,
failure preservation, duplicate retry, ownership and scope-switch cases.

No backfill is performed. Contextual copy enrichment and prompts remain
deferred to Phase 10. Premium, history UI, notifications, analytics,
recommendation changes and snapshot generation changes remain out of scope.
