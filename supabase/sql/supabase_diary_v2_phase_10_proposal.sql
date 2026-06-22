-- Rutio Phase 10 proposal: Diary V2 structured Supabase schema
-- Date: 2026-06-22
--
-- Intent:
-- - Schema preparation and verification only
-- - Additive schema for Diary V2
-- - No runtime app behavior changes
-- - Keep existing public.journal_entries intact while a future app migration is designed
--
-- Paste this file into Supabase SQL Editor and run it manually.

begin;

create extension if not exists pgcrypto;

-- Shared helper reused by Rutio tables that maintain updated_at.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.diary_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  local_id text not null,
  entry_date date not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  local_created_at_ms bigint not null,
  title text,
  body text,
  legacy_text text,
  mood integer,
  tags text[] not null default '{}'::text[],
  is_pinned boolean not null default false,
  habit_id text,
  family_id text,
  metadata jsonb not null default '{}'::jsonb
);

comment on table public.diary_entries is
  'Diary V2 structured entries. Separate from legacy public.journal_entries to allow additive rollout.';

comment on column public.diary_entries.local_id is
  'Stable local diary entry id used for reconciliation/backfill from local-first storage.';

comment on column public.diary_entries.legacy_text is
  'Backward-compatible combined text payload preserved during migration from legacy/local diary formats.';

comment on column public.diary_entries.mood is
  'Entry-level mood integer only. Do not confuse with public.daily_moods.mood.';

create unique index if not exists idx_diary_entries_user_local_id
  on public.diary_entries (user_id, local_id);

create index if not exists idx_diary_entries_user_date
  on public.diary_entries (user_id, entry_date desc);

create index if not exists idx_diary_entries_user_updated
  on public.diary_entries (user_id, updated_at desc);

create index if not exists idx_diary_entries_user_mood
  on public.diary_entries (user_id, mood);

create index if not exists idx_diary_entries_tags
  on public.diary_entries using gin (tags);

-- Recreate the trigger safely to avoid duplicate trigger errors on reruns.
drop trigger if exists trg_diary_entries_set_updated_at on public.diary_entries;
create trigger trg_diary_entries_set_updated_at
before update on public.diary_entries
for each row
execute function public.set_updated_at();

alter table public.diary_entries enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'diary_entries'
      and policyname = 'diary_entries_select_own'
  ) then
    execute 'create policy diary_entries_select_own on public.diary_entries for select to authenticated using (auth.uid() = user_id)';
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'diary_entries'
      and policyname = 'diary_entries_insert_own'
  ) then
    execute 'create policy diary_entries_insert_own on public.diary_entries for insert to authenticated with check (auth.uid() = user_id)';
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'diary_entries'
      and policyname = 'diary_entries_update_own'
  ) then
    execute 'create policy diary_entries_update_own on public.diary_entries for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id)';
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'diary_entries'
      and policyname = 'diary_entries_delete_own'
  ) then
    execute 'create policy diary_entries_delete_own on public.diary_entries for delete to authenticated using (auth.uid() = user_id)';
  end if;
end
$$;

create table if not exists public.daily_moods (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  mood_date date not null,
  mood integer not null,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  local_created_at_ms bigint,
  local_updated_at_ms bigint,
  metadata jsonb not null default '{}'::jsonb,
  constraint daily_moods_user_date_unique unique (user_id, mood_date)
);

comment on table public.daily_moods is
  'Diary V2 daily mood snapshots. Separate from entry-level moods and limited to one row per user per day.';

comment on column public.daily_moods.mood is
  'Day-level mood integer only. Do not mix with public.diary_entries.mood.';

create index if not exists idx_daily_moods_user_date
  on public.daily_moods (user_id, mood_date desc);

create index if not exists idx_daily_moods_user_updated
  on public.daily_moods (user_id, updated_at desc);

-- Recreate the trigger safely to avoid duplicate trigger errors on reruns.
drop trigger if exists trg_daily_moods_set_updated_at on public.daily_moods;
create trigger trg_daily_moods_set_updated_at
before update on public.daily_moods
for each row
execute function public.set_updated_at();

alter table public.daily_moods enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'daily_moods'
      and policyname = 'daily_moods_select_own'
  ) then
    execute 'create policy daily_moods_select_own on public.daily_moods for select to authenticated using (auth.uid() = user_id)';
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'daily_moods'
      and policyname = 'daily_moods_insert_own'
  ) then
    execute 'create policy daily_moods_insert_own on public.daily_moods for insert to authenticated with check (auth.uid() = user_id)';
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'daily_moods'
      and policyname = 'daily_moods_update_own'
  ) then
    execute 'create policy daily_moods_update_own on public.daily_moods for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id)';
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'daily_moods'
      and policyname = 'daily_moods_delete_own'
  ) then
    execute 'create policy daily_moods_delete_own on public.daily_moods for delete to authenticated using (auth.uid() = user_id)';
  end if;
end
$$;

commit;
