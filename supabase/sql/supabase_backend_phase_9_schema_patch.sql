-- Rutio Phase 9: Backend hardening schema patch
-- Date: 2026-04-28
--
-- Goals:
-- - Defensive/idempotent schema alignment for current local-first app behavior
-- - Add missing columns/constraints/indexes/policies where possible
-- - Drop incompatible constraints discovered during earlier phases
-- - Avoid destructive data operations
--
-- Important:
-- - create table if not exists does NOT patch existing tables
-- - this patch uses explicit alter/add statements for existing schemas

begin;

create extension if not exists pgcrypto;

-- Shared updated_at trigger helper
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- profiles
-- -----------------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  display_name text,
  avatar_url text,
  preferred_language_code text,
  notifications_enabled boolean,
  daily_motivation_enabled boolean,
  marketing_notifications_enabled boolean,
  daily_motivation_time text,
  last_login_at timestamptz,
  last_seen_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table if exists public.profiles
  add column if not exists email text,
  add column if not exists display_name text,
  add column if not exists avatar_url text,
  add column if not exists preferred_language_code text,
  add column if not exists notifications_enabled boolean,
  add column if not exists daily_motivation_enabled boolean,
  add column if not exists marketing_notifications_enabled boolean,
  add column if not exists daily_motivation_time text,
  add column if not exists last_login_at timestamptz,
  add column if not exists last_seen_at timestamptz,
  add column if not exists created_at timestamptz default now(),
  add column if not exists updated_at timestamptz default now();

alter table public.profiles alter column created_at set default now();
alter table public.profiles alter column updated_at set default now();

drop trigger if exists trg_profiles_set_updated_at on public.profiles;
create trigger trg_profiles_set_updated_at
before update on public.profiles
for each row
execute function public.set_updated_at();

alter table public.profiles enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'profiles' and policyname = 'profiles_select_own'
  ) then
    execute 'create policy profiles_select_own on public.profiles for select to authenticated using (auth.uid() = id)';
  end if;
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'profiles' and policyname = 'profiles_insert_own'
  ) then
    execute 'create policy profiles_insert_own on public.profiles for insert to authenticated with check (auth.uid() = id)';
  end if;
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'profiles' and policyname = 'profiles_update_own'
  ) then
    execute 'create policy profiles_update_own on public.profiles for update to authenticated using (auth.uid() = id) with check (auth.uid() = id)';
  end if;
end
$$;

-- -----------------------------------------------------------------------------
-- habits
-- -----------------------------------------------------------------------------
create table if not exists public.habits (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  family_id text,
  emoji text,
  habit_type text not null default 'check',
  target_count integer,
  unit text,
  color_id text,
  reminder_enabled boolean not null default false,
  reminder_time time,
  is_archived boolean not null default false,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table if exists public.habits
  add column if not exists user_id uuid,
  add column if not exists name text,
  add column if not exists family_id text,
  add column if not exists emoji text,
  add column if not exists habit_type text default 'check',
  add column if not exists target_count integer,
  add column if not exists unit text,
  add column if not exists color_id text,
  add column if not exists reminder_enabled boolean default false,
  add column if not exists reminder_time time,
  add column if not exists is_archived boolean default false,
  add column if not exists sort_order integer default 0,
  add column if not exists created_at timestamptz default now(),
  add column if not exists updated_at timestamptz default now();

alter table public.habits alter column habit_type set default 'check';
alter table public.habits alter column reminder_enabled set default false;
alter table public.habits alter column is_archived set default false;
alter table public.habits alter column sort_order set default 0;
alter table public.habits alter column created_at set default now();
alter table public.habits alter column updated_at set default now();

alter table if exists public.habits
  drop constraint if exists habits_habit_type_check;
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'habits_habit_type_check'
      and conrelid = 'public.habits'::regclass
  ) then
    alter table public.habits
      add constraint habits_habit_type_check
      check (habit_type in ('check', 'count'));
  end if;
end
$$;

create index if not exists idx_habits_user_sort_order
  on public.habits (user_id, sort_order, created_at);
create index if not exists idx_habits_user_updated_at
  on public.habits (user_id, updated_at desc);

drop trigger if exists trg_habits_set_updated_at on public.habits;
create trigger trg_habits_set_updated_at
before update on public.habits
for each row
execute function public.set_updated_at();

alter table public.habits enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'habits' and policyname = 'habits_select_own'
  ) then
    execute 'create policy habits_select_own on public.habits for select to authenticated using (auth.uid() = user_id)';
  end if;
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'habits' and policyname = 'habits_insert_own'
  ) then
    execute 'create policy habits_insert_own on public.habits for insert to authenticated with check (auth.uid() = user_id)';
  end if;
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'habits' and policyname = 'habits_update_own'
  ) then
    execute 'create policy habits_update_own on public.habits for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id)';
  end if;
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'habits' and policyname = 'habits_delete_own'
  ) then
    execute 'create policy habits_delete_own on public.habits for delete to authenticated using (auth.uid() = user_id)';
  end if;
end
$$;

-- -----------------------------------------------------------------------------
-- habit_logs
-- -----------------------------------------------------------------------------
create table if not exists public.habit_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  habit_id uuid not null references public.habits(id) on delete cascade,
  log_date date not null,
  value integer not null default 0,
  is_completed boolean not null default false,
  note text,
  source text not null default 'manual',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table if exists public.habit_logs
  add column if not exists user_id uuid,
  add column if not exists habit_id uuid,
  add column if not exists log_date date,
  add column if not exists value integer default 0,
  add column if not exists is_completed boolean default false,
  add column if not exists note text,
  add column if not exists source text default 'manual',
  add column if not exists created_at timestamptz default now(),
  add column if not exists updated_at timestamptz default now();

alter table public.habit_logs alter column source set default 'manual';
alter table public.habit_logs alter column value set default 0;
alter table public.habit_logs alter column is_completed set default false;
alter table public.habit_logs alter column created_at set default now();
alter table public.habit_logs alter column updated_at set default now();

alter table if exists public.habit_logs
  drop constraint if exists habit_logs_source_check;
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'habit_logs_source_check'
      and conrelid = 'public.habit_logs'::regclass
  ) then
    alter table public.habit_logs
      add constraint habit_logs_source_check
      check (source in ('manual', 'migration', 'system'));
  end if;
end
$$;

create unique index if not exists idx_habit_logs_user_habit_date_unique
  on public.habit_logs (user_id, habit_id, log_date);
create index if not exists idx_habit_logs_user_date
  on public.habit_logs (user_id, log_date desc);
create index if not exists idx_habit_logs_user_updated_at
  on public.habit_logs (user_id, updated_at desc);

drop trigger if exists trg_habit_logs_set_updated_at on public.habit_logs;
create trigger trg_habit_logs_set_updated_at
before update on public.habit_logs
for each row
execute function public.set_updated_at();

alter table public.habit_logs enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'habit_logs' and policyname = 'habit_logs_select_own'
  ) then
    execute 'create policy habit_logs_select_own on public.habit_logs for select to authenticated using (auth.uid() = user_id)';
  end if;
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'habit_logs' and policyname = 'habit_logs_insert_own'
  ) then
    execute 'create policy habit_logs_insert_own on public.habit_logs for insert to authenticated with check (auth.uid() = user_id)';
  end if;
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'habit_logs' and policyname = 'habit_logs_update_own'
  ) then
    execute 'create policy habit_logs_update_own on public.habit_logs for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id)';
  end if;
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'habit_logs' and policyname = 'habit_logs_delete_own'
  ) then
    execute 'create policy habit_logs_delete_own on public.habit_logs for delete to authenticated using (auth.uid() = user_id)';
  end if;
end
$$;

-- -----------------------------------------------------------------------------
-- user_progress
-- -----------------------------------------------------------------------------
create table if not exists public.user_progress (
  user_id uuid primary key references auth.users(id) on delete cascade,
  level integer not null default 1,
  total_xp integer not null default 0,
  current_level_xp integer not null default 0,
  next_level_xp integer not null default 100,
  ambar_balance integer not null default 0,
  total_ambar_earned integer not null default 0,
  total_ambar_spent integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table if exists public.user_progress
  add column if not exists level integer default 1,
  add column if not exists total_xp integer default 0,
  add column if not exists current_level_xp integer default 0,
  add column if not exists next_level_xp integer default 100,
  add column if not exists ambar_balance integer default 0,
  add column if not exists total_ambar_earned integer default 0,
  add column if not exists total_ambar_spent integer default 0,
  add column if not exists created_at timestamptz default now(),
  add column if not exists updated_at timestamptz default now();

alter table public.user_progress alter column level set default 1;
alter table public.user_progress alter column total_xp set default 0;
alter table public.user_progress alter column current_level_xp set default 0;
alter table public.user_progress alter column next_level_xp set default 100;
alter table public.user_progress alter column ambar_balance set default 0;
alter table public.user_progress alter column total_ambar_earned set default 0;
alter table public.user_progress alter column total_ambar_spent set default 0;
alter table public.user_progress alter column created_at set default now();
alter table public.user_progress alter column updated_at set default now();

alter table if exists public.user_progress
  drop constraint if exists user_progress_level_check;
alter table if exists public.user_progress
  drop constraint if exists user_progress_totals_check;
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'user_progress_level_check'
      and conrelid = 'public.user_progress'::regclass
  ) then
    alter table public.user_progress
      add constraint user_progress_level_check check (
        level >= 1 and
        total_xp >= 0 and
        current_level_xp >= 0 and
        next_level_xp >= 1 and
        ambar_balance >= 0 and
        total_ambar_earned >= 0 and
        total_ambar_spent >= 0
      );
  end if;
end
$$;

drop trigger if exists trg_user_progress_set_updated_at on public.user_progress;
create trigger trg_user_progress_set_updated_at
before update on public.user_progress
for each row
execute function public.set_updated_at();

alter table public.user_progress enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'user_progress' and policyname = 'user_progress_select_own'
  ) then
    execute 'create policy user_progress_select_own on public.user_progress for select to authenticated using (auth.uid() = user_id)';
  end if;
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'user_progress' and policyname = 'user_progress_insert_own'
  ) then
    execute 'create policy user_progress_insert_own on public.user_progress for insert to authenticated with check (auth.uid() = user_id)';
  end if;
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'user_progress' and policyname = 'user_progress_update_own'
  ) then
    execute 'create policy user_progress_update_own on public.user_progress for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id)';
  end if;
end
$$;

-- -----------------------------------------------------------------------------
-- xp_events
-- -----------------------------------------------------------------------------
create table if not exists public.xp_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  amount integer not null,
  source text not null,
  source_id uuid,
  description text,
  created_at timestamptz not null default now()
);

alter table if exists public.xp_events
  add column if not exists user_id uuid,
  add column if not exists amount integer,
  add column if not exists source text,
  add column if not exists source_id uuid,
  add column if not exists description text,
  add column if not exists created_at timestamptz default now();

alter table public.xp_events alter column created_at set default now();

alter table if exists public.xp_events
  drop constraint if exists xp_events_source_check;
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'xp_events_source_check'
      and conrelid = 'public.xp_events'::regclass
  ) then
    alter table public.xp_events
      add constraint xp_events_source_check check (
        source in (
          'habit_completed',
          'habit_count_progress',
          'achievement_unlocked',
          'level_bonus',
          'journal_entry',
          'migration',
          'system'
        )
      );
  end if;
end
$$;

create index if not exists idx_xp_events_user_created_at
  on public.xp_events (user_id, created_at desc);
create index if not exists idx_xp_events_user_source
  on public.xp_events (user_id, source);

alter table public.xp_events enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'xp_events' and policyname = 'xp_events_select_own'
  ) then
    execute 'create policy xp_events_select_own on public.xp_events for select to authenticated using (auth.uid() = user_id)';
  end if;
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'xp_events' and policyname = 'xp_events_insert_own'
  ) then
    execute 'create policy xp_events_insert_own on public.xp_events for insert to authenticated with check (auth.uid() = user_id)';
  end if;
end
$$;

-- -----------------------------------------------------------------------------
-- currency_events
-- -----------------------------------------------------------------------------
create table if not exists public.currency_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  amount integer not null,
  currency text not null default 'ambar',
  source text not null,
  source_id uuid,
  description text,
  created_at timestamptz not null default now()
);

alter table if exists public.currency_events
  add column if not exists user_id uuid,
  add column if not exists amount integer,
  add column if not exists currency text default 'ambar',
  add column if not exists source text,
  add column if not exists source_id uuid,
  add column if not exists description text,
  add column if not exists created_at timestamptz default now();

alter table public.currency_events alter column currency set default 'ambar';
alter table public.currency_events alter column created_at set default now();

alter table if exists public.currency_events
  drop constraint if exists currency_events_currency_check;
alter table if exists public.currency_events
  drop constraint if exists currency_events_source_check;
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'currency_events_currency_check'
      and conrelid = 'public.currency_events'::regclass
  ) then
    alter table public.currency_events
      add constraint currency_events_currency_check
      check (currency = 'ambar');
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'currency_events_source_check'
      and conrelid = 'public.currency_events'::regclass
  ) then
    alter table public.currency_events
      add constraint currency_events_source_check check (
        source in (
          'habit_completed',
          'achievement_unlocked',
          'shop_purchase',
          'refund',
          'journal_entry',
          'migration',
          'system'
        )
      );
  end if;
end
$$;

create index if not exists idx_currency_events_user_created_at
  on public.currency_events (user_id, created_at desc);
create index if not exists idx_currency_events_user_source
  on public.currency_events (user_id, source);

alter table public.currency_events enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'currency_events' and policyname = 'currency_events_select_own'
  ) then
    execute 'create policy currency_events_select_own on public.currency_events for select to authenticated using (auth.uid() = user_id)';
  end if;
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'currency_events' and policyname = 'currency_events_insert_own'
  ) then
    execute 'create policy currency_events_insert_own on public.currency_events for insert to authenticated with check (auth.uid() = user_id)';
  end if;
end
$$;

-- -----------------------------------------------------------------------------
-- user_achievements
-- -----------------------------------------------------------------------------
create table if not exists public.user_achievements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  achievement_id text not null,
  family_id text,
  tier text not null,
  unlocked_at timestamptz not null default now(),
  reward_xp integer not null default 0,
  reward_ambar integer not null default 0,
  reward_applied boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table if exists public.user_achievements
  add column if not exists user_id uuid,
  add column if not exists achievement_id text,
  add column if not exists family_id text,
  add column if not exists tier text,
  add column if not exists unlocked_at timestamptz default now(),
  add column if not exists reward_xp integer default 0,
  add column if not exists reward_ambar integer default 0,
  add column if not exists reward_applied boolean default true,
  add column if not exists created_at timestamptz default now(),
  add column if not exists updated_at timestamptz default now();

alter table public.user_achievements alter column unlocked_at set default now();
alter table public.user_achievements alter column reward_xp set default 0;
alter table public.user_achievements alter column reward_ambar set default 0;
alter table public.user_achievements alter column reward_applied set default true;
alter table public.user_achievements alter column created_at set default now();
alter table public.user_achievements alter column updated_at set default now();

-- Required cleanup from prior phases:
alter table if exists public.journal_entries
  drop constraint if exists journal_entries_unique_day_per_user;
alter table if exists public.user_achievements
  drop constraint if exists user_achievements_achievement_id_fkey;

alter table if exists public.user_achievements
  drop constraint if exists user_achievements_tier_check;
alter table if exists public.user_achievements
  drop constraint if exists user_achievements_reward_values_check;
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'user_achievements_tier_check'
      and conrelid = 'public.user_achievements'::regclass
  ) then
    alter table public.user_achievements
      add constraint user_achievements_tier_check check (
        tier in (
          'wood',
          'stone',
          'bronze',
          'silver',
          'gold',
          'diamond',
          'prismaticDiamond'
        )
      );
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'user_achievements_reward_values_check'
      and conrelid = 'public.user_achievements'::regclass
  ) then
    alter table public.user_achievements
      add constraint user_achievements_reward_values_check
      check (reward_xp >= 0 and reward_ambar >= 0);
  end if;
end
$$;

create unique index if not exists idx_user_achievements_user_achievement_unique
  on public.user_achievements (user_id, achievement_id);
create index if not exists idx_user_achievements_user_unlocked_at
  on public.user_achievements (user_id, unlocked_at desc);
create index if not exists idx_user_achievements_family_id
  on public.user_achievements (family_id);

drop trigger if exists trg_user_achievements_set_updated_at on public.user_achievements;
create trigger trg_user_achievements_set_updated_at
before update on public.user_achievements
for each row
execute function public.set_updated_at();

alter table public.user_achievements enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'user_achievements' and policyname = 'user_achievements_select_own'
  ) then
    execute 'create policy user_achievements_select_own on public.user_achievements for select to authenticated using (auth.uid() = user_id)';
  end if;
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'user_achievements' and policyname = 'user_achievements_insert_own'
  ) then
    execute 'create policy user_achievements_insert_own on public.user_achievements for insert to authenticated with check (auth.uid() = user_id)';
  end if;
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'user_achievements' and policyname = 'user_achievements_update_own'
  ) then
    execute 'create policy user_achievements_update_own on public.user_achievements for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id)';
  end if;
end
$$;

-- -----------------------------------------------------------------------------
-- journal_entries
-- -----------------------------------------------------------------------------
create table if not exists public.journal_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  entry_date date not null,
  title text,
  content text not null,
  mood text,
  emoji text,
  habit_id uuid references public.habits(id) on delete set null,
  local_habit_id text,
  family_id text,
  source text not null default 'manual',
  is_deleted boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table if exists public.journal_entries
  add column if not exists user_id uuid,
  add column if not exists entry_date date,
  add column if not exists title text,
  add column if not exists content text,
  add column if not exists mood text,
  add column if not exists emoji text,
  add column if not exists habit_id uuid,
  add column if not exists local_habit_id text,
  add column if not exists family_id text,
  add column if not exists source text default 'manual',
  add column if not exists is_deleted boolean default false,
  add column if not exists created_at timestamptz default now(),
  add column if not exists updated_at timestamptz default now();

alter table public.journal_entries alter column source set default 'manual';
alter table public.journal_entries alter column is_deleted set default false;
alter table public.journal_entries alter column created_at set default now();
alter table public.journal_entries alter column updated_at set default now();

-- Never enforce unique(user_id, entry_date): multiple entries/day are valid.
alter table if exists public.journal_entries
  drop constraint if exists journal_entries_unique_day_per_user;

alter table if exists public.journal_entries
  drop constraint if exists journal_entries_source_check;
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'journal_entries_source_check'
      and conrelid = 'public.journal_entries'::regclass
  ) then
    alter table public.journal_entries
      add constraint journal_entries_source_check
      check (source in ('manual', 'migration', 'system'));
  end if;
end
$$;

create index if not exists idx_journal_entries_user_date
  on public.journal_entries (user_id, entry_date desc);
create index if not exists idx_journal_entries_user_updated
  on public.journal_entries (user_id, updated_at desc);
create index if not exists idx_journal_entries_user_local_habit
  on public.journal_entries (user_id, local_habit_id);
create index if not exists idx_journal_entries_user_active
  on public.journal_entries (user_id, is_deleted, entry_date desc);

comment on column public.journal_entries.content is
  'Sensitive personal diary/journal content. Restrict via RLS and avoid logging raw text.';

drop trigger if exists trg_journal_entries_set_updated_at on public.journal_entries;
create trigger trg_journal_entries_set_updated_at
before update on public.journal_entries
for each row
execute function public.set_updated_at();

alter table public.journal_entries enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'journal_entries' and policyname = 'journal_entries_select_own'
  ) then
    execute 'create policy journal_entries_select_own on public.journal_entries for select to authenticated using (auth.uid() = user_id)';
  end if;
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'journal_entries' and policyname = 'journal_entries_insert_own'
  ) then
    execute 'create policy journal_entries_insert_own on public.journal_entries for insert to authenticated with check (auth.uid() = user_id)';
  end if;
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'journal_entries' and policyname = 'journal_entries_update_own'
  ) then
    execute 'create policy journal_entries_update_own on public.journal_entries for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id)';
  end if;
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'journal_entries' and policyname = 'journal_entries_delete_own'
  ) then
    execute 'create policy journal_entries_delete_own on public.journal_entries for delete to authenticated using (auth.uid() = user_id)';
  end if;
end
$$;

commit;
