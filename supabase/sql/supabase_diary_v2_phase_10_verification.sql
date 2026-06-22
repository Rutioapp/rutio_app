-- Rutio Phase 10 verification: Diary V2 structured Supabase schema
-- Date: 2026-06-22
--
-- Run this only after successfully applying:
--   supabase/sql/supabase_diary_v2_phase_10_proposal.sql

-- 1) Confirm the tables exist.
select
  n.nspname as schema_name,
  c.relname as table_name,
  c.relkind as relation_kind
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname in ('diary_entries', 'daily_moods')
  and c.relkind = 'r'
order by c.relname;

-- 2) Confirm RLS is enabled on both tables.
select
  schemaname,
  tablename,
  rowsecurity,
  forcerowsecurity
from pg_tables
where schemaname = 'public'
  and tablename in ('diary_entries', 'daily_moods')
order by tablename;

-- 3) Confirm the own-row policies exist.
select
  schemaname,
  tablename,
  policyname,
  cmd,
  roles,
  qual,
  with_check
from pg_policies
where schemaname = 'public'
  and tablename in ('diary_entries', 'daily_moods')
order by tablename, policyname;

-- 4) Confirm the expected indexes exist.
select
  schemaname,
  tablename,
  indexname,
  indexdef
from pg_indexes
where schemaname = 'public'
  and (
    (tablename = 'diary_entries' and indexname in (
      'diary_entries_pkey',
      'idx_diary_entries_user_local_id',
      'idx_diary_entries_user_date',
      'idx_diary_entries_user_updated',
      'idx_diary_entries_user_mood',
      'idx_diary_entries_tags'
    ))
    or
    (tablename = 'daily_moods' and indexname in (
      'daily_moods_pkey',
      'daily_moods_user_date_unique',
      'idx_daily_moods_user_date',
      'idx_daily_moods_user_updated'
    ))
  )
order by tablename, indexname;

-- 5) Confirm the daily_moods uniqueness constraint exists.
select
  con.conname as constraint_name,
  con.conrelid::regclass as table_name,
  pg_get_constraintdef(con.oid) as definition
from pg_constraint con
join pg_namespace n on n.oid = con.connamespace
where n.nspname = 'public'
  and con.conrelid = 'public.daily_moods'::regclass
  and con.conname = 'daily_moods_user_date_unique';

-- Optional manual smoke test:
-- Replace the UUID below with a real authenticated auth.users.id from your project.
-- This is intentionally separate and manual because SQL Editor sessions do not
-- automatically run as an authenticated client user.
--
-- begin;
--
-- insert into public.diary_entries (
--   user_id,
--   local_id,
--   entry_date,
--   local_created_at_ms,
--   title,
--   body,
--   legacy_text,
--   mood,
--   tags,
--   is_pinned,
--   metadata
-- ) values (
--   '00000000-0000-0000-0000-000000000000',
--   'phase10-smoke-test-entry',
--   current_date,
--   1760000000000,
--   'Phase 10 smoke test',
--   'Temporary test row for manual verification.',
--   'Phase 10 smoke test',
--   1,
--   array['mood'],
--   false,
--   '{"source":"manual_smoke_test"}'::jsonb
-- );
--
-- select id, user_id, local_id, entry_date, mood, tags, created_at, updated_at
-- from public.diary_entries
-- where local_id = 'phase10-smoke-test-entry';
--
-- delete from public.diary_entries
-- where local_id = 'phase10-smoke-test-entry';
--
-- commit;
