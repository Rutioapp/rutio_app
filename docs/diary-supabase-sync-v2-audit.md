# Diary V2 Supabase Sync Audit

Date: 2026-06-22

## Current State

### Local models found

- `DiaryEntry` in [lib/models/diary_entry.dart](/D:/dev/alpha/rutio_app/lib/models/diary_entry.dart)
  - Local fields: `id`, `createdAt`, `text`, `title`, `body`, `remoteId`, `habitId`, `familyId`, `mood`, `tags`, `isPinned`
  - `text` is still the backward-compatible legacy payload.
  - `legacyText` is derived from `title` + `body` when present.
- `DailyMood` in [lib/models/daily_mood.dart](/D:/dev/alpha/rutio_app/lib/models/daily_mood.dart)
  - Local fields: `date`, `mood`, `note`, `createdAt`, `updatedAt`

### Local persistence found

- Diary V2 local persistence lives inside scoped user-state JSON in shared preferences.
- Root storage and scoping:
  - [lib/data/local/user_state_storage.dart](/D:/dev/alpha/rutio_app/lib/data/local/user_state_storage.dart)
  - [lib/data/repositories/user_state_repository.dart](/D:/dev/alpha/rutio_app/lib/data/repositories/user_state_repository.dart)
- Diary-specific persistence:
  - `userState.diaryEntries` is a list of entry maps.
  - `userState.dailyMoods` is a map keyed by `YYYY-MM-DD`.
  - Implemented in [lib/stores/user_state_store_diary.dart](/D:/dev/alpha/rutio_app/lib/stores/user_state_store_diary.dart) and normalized in [lib/stores/user_state_store_core.dart](/D:/dev/alpha/rutio_app/lib/stores/user_state_store_core.dart).

### Existing Supabase sync found

- Diary entries: yes, already best-effort synced to Supabase.
  - Sync service: [lib/data/services/journal_entry_sync_service.dart](/D:/dev/alpha/rutio_app/lib/data/services/journal_entry_sync_service.dart)
  - Repository: [lib/data/repositories/journal_entry_repository.dart](/D:/dev/alpha/rutio_app/lib/data/repositories/journal_entry_repository.dart)
  - Remote model: [lib/data/models/remote/remote_journal_entry.dart](/D:/dev/alpha/rutio_app/lib/data/models/remote/remote_journal_entry.dart)
  - Mapper: [lib/data/mappers/journal_entry_remote_mapper.dart](/D:/dev/alpha/rutio_app/lib/data/mappers/journal_entry_remote_mapper.dart)
- Daily moods: no Supabase repository/service/table usage found. `setDailyMood(...)` only updates local user-state JSON.
- Current sync direction remains local-first and write-through only.
  - No remote-to-local diary pull found.
  - No conflict resolution found.

### Existing database/table strategy found

- Current backend reference: [docs/supabase_backend_schema_reference.md](/D:/dev/alpha/rutio_app/docs/supabase_backend_schema_reference.md)
- Current schema patch SQL: [supabase/sql/supabase_backend_phase_9_schema_patch.sql](/D:/dev/alpha/rutio_app/supabase/sql/supabase_backend_phase_9_schema_patch.sql)
- Existing journal backend doc: [docs/supabase_journal_entries_phase_8b.md](/D:/dev/alpha/rutio_app/docs/supabase_journal_entries_phase_8b.md)
- Current Supabase schema already includes structured tables such as `profiles`, `habits`, `habit_logs`, `user_progress`, `xp_events`, `currency_events`, `user_achievements`, and `journal_entries`.
- No generic remote `user_state` JSON table was found.

## Audit Answers

1. Diary entries are currently synced to Supabase, but through the older `public.journal_entries` shape.
2. Daily moods are currently stored only locally.
3. Rutio currently uses structured Supabase tables, not a single remote user-state blob.
4. No generic user-state JSON sync table was found.
5. Diary V2 fields in Supabase today:
   - stored: `title` partially, `mood`, habit linkage, family linkage, legacy body as `content`
   - not stored as first-class columns: `body`, `legacy_text`, `tags`, `isPinned`
6. `DailyMood` is not stored in Supabase today.
7. Authenticated rows use Supabase Auth UUIDs via `auth.users(id)` and `auth.uid()`.
8. Current RLS style is per-table, authenticated-only, own-row access using `auth.uid() = user_id` or `auth.uid() = id` for profiles.
9. Missing for Diary V2: a dedicated structured `diary_entries` table and a dedicated `daily_moods` table.
10. Safest future schema: add new structured tables for Diary V2 and leave current `journal_entries` intact until app sync migration is intentionally implemented.

## Current Supabase Schema Relevant To Diary

### Current remote diary table

`public.journal_entries` currently contains:

- `id`
- `user_id`
- `entry_date`
- `title`
- `content`
- `mood`
- `emoji`
- `habit_id`
- `local_habit_id`
- `family_id`
- `source`
- `is_deleted`
- `created_at`
- `updated_at`

### Important mismatch with Diary V2

- `journal_entries` was designed around legacy journal content plus habit-linked notes.
- Diary V2 now has separate `title`, `body`, `legacyText`, `tags`, and `isPinned`.
- `content` can preserve legacy-compatible combined text, but it is not enough as the long-term structured schema for Diary V2.
- `DailyMood` is conceptually separate from entry mood and should not be forced into `journal_entries`.

## Data Inventory

| Field | Source model | Current local storage | Sync to Supabase? | Suggested Supabase column | Nullability | Notes |
|---|---|---|---|---|---|---|
| `DiaryEntry.id` | `DiaryEntry` | `userState.diaryEntries[].id` | Yes | `diary_entries.local_id` | required | Keep stable local id for reconciliation; remote PK should remain UUID. |
| `DiaryEntry.remoteId` | `DiaryEntry` | `userState.diaryEntries[].remoteId` | N/A local sync marker | none in row payload | nullable | Local-only mapping to remote UUID; continue storing locally. |
| `DiaryEntry.createdAt` | `DiaryEntry` | `userState.diaryEntries[].createdAt` epoch ms | Yes | `diary_entries.local_created_at_ms` | required | Preserve exact local creation time for ordering/backfill safety. |
| `DiaryEntry.updatedAt` | not present | not present | Not yet | `diary_entries.updated_at` | required remote | No local field exists yet; remote timestamp should still be maintained by DB trigger. |
| `DiaryEntry.date/day` | derived from `createdAt` | derived only | Yes | `diary_entries.entry_date` | required | Date-only query field for calendar/day views. |
| `DiaryEntry.title` | `DiaryEntry` | `userState.diaryEntries[].title` | Yes | `diary_entries.title` | nullable | Present in local model and already partially mirrored to `journal_entries.title`. |
| `DiaryEntry.body` | `DiaryEntry` | `userState.diaryEntries[].body` | Yes | `diary_entries.body` | nullable | Needed as first-class field for V2 editor/detail/search. |
| `DiaryEntry.legacy text` | `DiaryEntry.text` / `legacyText` | `userState.diaryEntries[].text` | Yes | `diary_entries.legacy_text` | nullable | Preserve backward compatibility and migration safety. |
| `DiaryEntry.mood` | `DiaryEntry` | `userState.diaryEntries[].mood` | Yes | `diary_entries.mood` | nullable | Keep separate from daily mood; app uses int mood values now. |
| `DiaryEntry.tags` | `DiaryEntry` | `userState.diaryEntries[].tags` | Yes | `diary_entries.tags` | required | Best as `text[] not null default '{}'`. |
| `DiaryEntry.isPinned` | `DiaryEntry` | `userState.diaryEntries[].isPinned` | Yes | `diary_entries.is_pinned` | required | V2 all-entries and premium flows can rely on this later. |
| `DiaryEntry.habitId` | `DiaryEntry` | `userState.diaryEntries[].habitId` | Yes | `diary_entries.habit_id` | nullable | Local model stores local habit id today; do not force FK yet in V2 table unless app migration is defined. |
| `DiaryEntry.familyId` | `DiaryEntry` | `userState.diaryEntries[].familyId` | Yes | `diary_entries.family_id` | nullable | Useful for filters and preserving existing habit-family coupling. |
| `DiaryEntry.metadata` | proposed | none | Future-ready | `diary_entries.metadata` | required | JSONB for safe additive growth like prompts/layout flags later. |
| `DailyMood.date` | `DailyMood` | `userState.dailyMoods[YYYY-MM-DD].date` | Yes | `daily_moods.mood_date` | required | One row per user/day. |
| `DailyMood.mood` | `DailyMood` | `userState.dailyMoods[YYYY-MM-DD].mood` | Yes | `daily_moods.mood` | required | Separate meaning from entry mood. |
| `DailyMood.note` | `DailyMood` | `userState.dailyMoods[YYYY-MM-DD].note` | Yes | `daily_moods.note` | nullable | Local model already supports it, even if UI usage is limited. |
| `DailyMood.createdAt` | `DailyMood` | `userState.dailyMoods[YYYY-MM-DD].createdAt` epoch ms | Yes | `daily_moods.local_created_at_ms` | nullable | Optional but useful for migration/debug parity. |
| `DailyMood.updatedAt` | `DailyMood` | `userState.dailyMoods[YYYY-MM-DD].updatedAt` epoch ms | Yes | `daily_moods.local_updated_at_ms` | nullable | Optional but useful for conflict handling later. |
| `DailyMood.metadata` | proposed | none | Future-ready | `daily_moods.metadata` | required | JSONB for additive growth. |

## Recommended Supabase Schema

### Recommendation

Add new structured tables:

- `public.diary_entries`
- `public.daily_moods`

Do not replace `public.journal_entries` yet.

### Why new tables instead of extending `journal_entries`

- `journal_entries` is already serving an older sync path and includes legacy concerns like `is_deleted`, `source`, `emoji`, and remote habit FK behavior.
- Diary V2 has a clearer domain model than the legacy journal sync shape.
- A new table avoids risky migration pressure on existing production behavior.
- It also lets the app adopt V2 sync gradually while preserving local-first behavior and backward compatibility.

### Recommended `diary_entries` design

- Remote UUID primary key for Supabase identity.
- `user_id` scoped to `auth.users(id)`.
- `local_id` preserved for deterministic local reconciliation.
- `entry_date` optimized for day/month queries.
- Structured `title`, `body`, `legacy_text`, `mood`, `tags`, `is_pinned`.
- Keep `habit_id` and `family_id` nullable as plain text for now because local `habitId` is a local identifier today and should not be silently reinterpreted as a remote FK.
- `metadata jsonb` reserved for future-compatible additive fields.

### Recommended `daily_moods` design

- Separate table from diary entries.
- One row per user per date via `unique(user_id, mood_date)`.
- Keep `note` nullable because the model already supports it.
- Separate metadata for future expansion.

### Optional future table

Not required now, but a good future direction:

- `public.diary_entry_attachments`
  - `id uuid`
  - `diary_entry_id uuid references public.diary_entries(id) on delete cascade`
  - attachment metadata columns
  - storage path / mime / duration / width / height

## SQL Ready To Paste Into Supabase

Primary schema file:

- [supabase/sql/supabase_diary_v2_phase_10_proposal.sql](/D:/dev/alpha/rutio_app/supabase/sql/supabase_diary_v2_phase_10_proposal.sql)

Verification file to run after the schema applies:

- [supabase/sql/supabase_diary_v2_phase_10_verification.sql](/D:/dev/alpha/rutio_app/supabase/sql/supabase_diary_v2_phase_10_verification.sql)

### Final schema decisions confirmed

- `public.diary_entries` and `public.daily_moods` are additive new tables.
- `public.journal_entries` remains untouched during this transition phase.
- `diary_entries.habit_id` stays nullable `text` for local-id compatibility.
- `diary_entries.tags` uses `text[]`.
- `metadata` stays `jsonb` on both tables.
- `daily_moods` keeps `unique(user_id, mood_date)`.
- No strict SQL check constraint is added for mood values yet.
- `DiaryEntry.mood` and `DailyMood.mood` remain separate concepts and separate columns.
- Mood columns are typed as `integer` in the new tables to match the current Dart models, while remaining unconstrained for now.

### Paste-readiness notes

- `create extension if not exists pgcrypto` is included.
- `create table if not exists` is used for both new tables.
- `create index if not exists` is used for all explicit indexes.
- RLS is enabled on both new tables.
- Policies are created only when missing via `pg_policies` checks inside `do $$ ... $$`.
- The shared `public.set_updated_at()` helper is created with `create or replace function`.
- Triggers are recreated safely with `drop trigger if exists ...` followed by `create trigger`.
- The script is additive and does not drop tables, alter `journal_entries`, or remove existing policies on other tables.

### Manual apply checklist

1. Open Supabase Dashboard for the target project.
2. Open SQL Editor.
3. Paste the full contents of [supabase/sql/supabase_diary_v2_phase_10_proposal.sql](/D:/dev/alpha/rutio_app/supabase/sql/supabase_diary_v2_phase_10_proposal.sql).
4. Run the schema SQL once.
5. Paste the full contents of [supabase/sql/supabase_diary_v2_phase_10_verification.sql](/D:/dev/alpha/rutio_app/supabase/sql/supabase_diary_v2_phase_10_verification.sql).
6. Run the verification SQL and confirm both tables, both RLS flags, all policies, the expected indexes, and the `daily_moods_user_date_unique` constraint are present.
7. Only if you want a manual smoke test, run the optional insert/select/delete block in the verification file after replacing the placeholder UUID with a real `auth.users.id`.

### Manual verification checklist

- Verify table creation:
  - `public.diary_entries`
  - `public.daily_moods`
- Verify RLS is enabled on both tables.
- Verify policies exist for `select`, `insert`, `update`, and `delete` on both tables.
- Verify indexes exist for:
  - `idx_diary_entries_user_local_id`
  - `idx_diary_entries_user_date`
  - `idx_diary_entries_user_updated`
  - `idx_diary_entries_user_mood`
  - `idx_diary_entries_tags`
  - `idx_daily_moods_user_date`
  - `idx_daily_moods_user_updated`
- Verify `daily_moods_user_date_unique` exists.
- Optional manual smoke test:
  - insert one temporary `diary_entries` row with a real user UUID
  - select it back
  - delete it
  - confirm cleanup succeeded

### What not to touch yet

- Do not add Flutter sync logic yet.
- Do not change runtime behavior.
- Do not change UI.
- Do not change `DiaryEntry` or `DailyMood` models.
- Do not change local persistence.
- Do not backfill or migrate `journal_entries`.
- Do not remove `journal_entries`.

## Migration And Safety Notes

- This proposal is additive.
- It does not modify current runtime behavior.
- It does not change current local persistence.
- It can be applied in Supabase without affecting existing local-only users because the app does not read/write these new tables yet.
- No destructive migration is required now.
- No backfill is required before applying the SQL itself.
- Backfill will be needed later only when the app starts syncing Diary V2 into these new tables.
- The SQL is rerunnable for the intended fresh-apply case, but `create table if not exists` will not repair a previously created conflicting table shape. If these tables already exist with different columns or types, inspect and reconcile manually before applying follow-up changes.

### Legacy text mapping

Recommended mapping when sync is implemented later:

- `title` -> `diary_entries.title`
- `body` -> `diary_entries.body`
- `legacyText` or local `text` -> `diary_entries.legacy_text`

If an old entry only has `text`:

- keep `legacy_text = text`
- optionally derive display title/body in app logic without dropping original legacy payload

### Why `DailyMood` must stay separate

- `DailyMood` represents the emotional summary for a day.
- `DiaryEntry.mood` represents the mood attached to one specific entry.
- A day may have multiple entries but only one daily mood snapshot.
- Mixing them would create ambiguity, overwrite risk, and harder future sync logic.

### Data-loss avoidance

- Do not repurpose `journal_entries` in place.
- Do not remove legacy local `text`.
- Keep local `remoteId` behavior isolated until the new sync path is intentionally built.
- Keep new tables independent so rollout can be feature-flagged or phased safely.

### What to test before enabling app sync

- SQL applies cleanly in Supabase.
- RLS blocks cross-user reads/writes.
- `daily_moods` uniqueness works for one row per user/day.
- `diary_entries` supports multiple rows per user/day.
- `set_updated_at()` trigger updates `updated_at`.
- Tag array queries and indexes behave as expected.
- Authenticated client can insert/update/delete only own rows.
- Migration from local legacy `text` does not lose title/body semantics.

## Next Implementation Phases

### Phase 1

- Apply SQL manually in Supabase SQL Editor.
- Verify tables, indexes, triggers, and RLS policies.

### Phase 2

- Add Supabase repository for `diary_entries`.
- Pull remote entries after login.
- Push local changes.
- Keep local-first behavior.

### Phase 3

- Add Supabase repository for `daily_moods`.
- Sync `DailyMood` separately from diary entries.

### Phase 4

- Add conflict handling using `updated_at`.
- Define offline replay and retry behavior.
- Decide how to reconcile local `remoteId` with new table identity.

## Summary

- Current state: local Diary V2 is rich, but Supabase support is only partial through legacy `journal_entries`; daily moods are not remotely stored.
- Recommended tables: `diary_entries` and `daily_moods`.
- SQL placement: added to this audit doc and mirrored into a proposal SQL file.
- Safest rollout: additive schema first, app sync later.
