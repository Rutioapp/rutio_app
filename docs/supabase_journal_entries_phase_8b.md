# Supabase Journal Entries - Phase 8B

## Scope
- Add best-effort Supabase persistence for local-first diary/journal entries.
- Keep local diary as source of truth.
- No two-way sync and no remote-to-local merge in this phase.
- Keep Phase 8A daily reward behavior unchanged.

## Local Diary Structure Found
`userState.diaryEntries` stores a list of maps with the effective local shape:
- `id` (stable local id, string)
- `createdAt` (epoch ms, int)
- `text` (entry content)
- `habitId` (optional local habit id)
- `familyId` (optional family id)
- `mood` (optional int)
- `isPinned` (bool)
- `remoteId` (optional Supabase UUID, added in Phase 8B)

Related metadata:
- `userState.meta.diaryRewardAppliedDateKeys` (Phase 8A idempotent daily reward markers)
- `userState.meta.supabaseJournalBackfillCompletedByUser` (Phase 8B one-time backfill marker per user)

## Supabase Table Contract
Target table: `public.journal_entries`

Recommended SQL:

```sql
create extension if not exists pgcrypto;

create table if not exists public.journal_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  entry_date date not null,
  title text null,
  content text not null,
  mood text null,
  emoji text null,
  habit_id uuid null references public.habits(id) on delete set null,
  local_habit_id text null,
  family_id text null,
  source text not null default 'manual'
    check (source in ('manual', 'migration', 'system')),
  is_deleted boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
```

Optional `updated_at` trigger:

```sql
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_journal_entries_set_updated_at on public.journal_entries;
create trigger trg_journal_entries_set_updated_at
before update on public.journal_entries
for each row execute function public.set_updated_at();
```

If the table does not exist, app behavior is fail-safe:
- Local diary operations remain successful.
- Remote sync returns repository errors and logs in `kDebugMode`.
- No crash and no data loss in local state.

## RLS Policies

```sql
alter table public.journal_entries enable row level security;

create policy if not exists "journal_entries_select_own"
on public.journal_entries
for select
to authenticated
using (auth.uid() = user_id);

create policy if not exists "journal_entries_insert_own"
on public.journal_entries
for insert
to authenticated
with check (auth.uid() = user_id);

create policy if not exists "journal_entries_update_own"
on public.journal_entries
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy if not exists "journal_entries_delete_own"
on public.journal_entries
for delete
to authenticated
using (auth.uid() = user_id);
```

## Recommended Indexes

```sql
create index if not exists idx_journal_entries_user_date
  on public.journal_entries (user_id, entry_date desc);

create index if not exists idx_journal_entries_user_updated
  on public.journal_entries (user_id, updated_at desc);

create index if not exists idx_journal_entries_user_local_habit
  on public.journal_entries (user_id, local_habit_id);

create index if not exists idx_journal_entries_user_active
  on public.journal_entries (user_id, is_deleted, entry_date desc);
```

## Mapping Rules (Phase 8B)
- `entry_date`: local date-only derived from local `createdAt` epoch ms.
- `content`: local `text` (trimmed, required).
- `title`: nullable (kept null unless local field exists).
- `mood`: maps from local mood when present.
- `emoji`: maps only if local field exists.
- `family_id`: maps from local `familyId` when present.
- `local_habit_id`: maps from local `habitId` when present.
- `habit_id`: set only when a matching active local habit has a valid persisted remote UUID.
- `source`: `manual` for normal create/update, `migration` for backfill.
- `is_deleted`: `false` for active entries.

Invalid entries:
- Empty/whitespace-only text is skipped for remote writes.

## Local-First Runtime Behavior
- Local create/update/delete always persists locally first.
- Remote writes are best-effort and non-blocking.
- Remote failures do not block local UX and do not crash the app.
- `user_id` is always forced from current authenticated Supabase session.

## remoteId Strategy
- `remoteId` is stored in each local diary entry map after successful remote insert/upsert.
- Existing entries without `remoteId` remain valid.
- `remoteId` persistence survives app restart because it is saved in local user state JSON.

## Create / Edit / Delete Behavior
- Create:
  - Save local entry.
  - Best-effort remote insert/upsert.
  - Persist `remoteId` locally when remote succeeds.
- Edit:
  - Save local entry.
  - Best-effort remote update when `remoteId` exists.
  - No forced destructive remote action when `remoteId` is missing.
- Delete:
  - Remove local entry (hard delete locally).
  - Best-effort remote soft delete (`is_deleted = true`) when `remoteId` exists.

## Backfill Behavior
- One-time per-user backfill marker:
  - `meta.supabaseJournalBackfillCompletedByUser[userId] = true`
- Backfill uploads entries without `remoteId`.
- On each successful upload, corresponding local entry stores `remoteId`.
- Backfill continues across per-entry failures.
- Marker is only set when no eligible remaining entries and no failures.
- If table/schema is missing, backfill fails safely and can retry later.

## Reward Safety
- Phase 8A reward logic remains in local diary mutation path.
- Backfill and remote sync do not grant XP/currency events.
- No duplicate daily reward introduced by remote persistence path.

## Privacy Note
- Diary content is sensitive personal data.
- Debug logging intentionally avoids diary text and logs only ids/dates/status.
- Use least-privilege RLS and avoid exposing service-role access in client code.

## Explicitly Not Included Yet
- No remote download of journal entries.
- No merge/conflict resolution.
- No multi-device reconciliation.
- No two-way sync.

## Phase 9 Hardening (Future)
- Add remote pull + reconciliation strategy.
- Add dedupe strategy for no-`remoteId` edge cases after interrupted writes.
- Add retry queue with exponential backoff and offline replay.
- Add optional encryption-at-rest strategy for sensitive fields.
- Add richer operational telemetry and migration observability.
