begin;

create extension if not exists pgcrypto;
create schema if not exists app_private;
revoke all on schema app_private from public, anon, authenticated;

create table if not exists public.weekly_report_activations (
  user_id uuid primary key references auth.users(id) on delete cascade,
  activated_at timestamptz not null default now(),
  activation_local_date date not null,
  timezone_name text not null,
  created_at timestamptz not null default now(),
  constraint weekly_report_activations_timezone_check check (btrim(timezone_name) <> ''),
  constraint weekly_report_activations_date_check check (activation_local_date = (activated_at at time zone timezone_name)::date)
);

create table if not exists public.weekly_report_habit_config_versions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  habit_id uuid not null,
  effective_from timestamptz not null,
  effective_local_date date not null,
  effective_timezone_name text not null,
  name text not null,
  emoji text,
  habit_type text not null,
  target_count numeric,
  schedule jsonb not null,
  is_archived boolean not null default false,
  source_event text not null,
  source_updated_at timestamptz,
  source_mutation_id text,
  observed_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  constraint weekly_report_habit_config_type_check check (habit_type in ('check', 'count')),
  constraint weekly_report_habit_config_target_check check (target_count is null or target_count > 0),
  constraint weekly_report_habit_config_schedule_check check (public.is_valid_habit_schedule(schedule)),
  constraint weekly_report_habit_config_effective_date_check check (effective_local_date = (effective_from at time zone effective_timezone_name)::date),
  constraint weekly_report_habit_config_event_check check (source_event in ('activation', 'insert', 'update', 'archive', 'delete', 'explicit_sync')),
  constraint weekly_report_habit_config_timezone_check check (btrim(effective_timezone_name) <> ''),
  constraint weekly_report_habit_config_mutation_id_check check (source_mutation_id is null or btrim(source_mutation_id) <> '')
);

create or replace function public.activate_weekly_report(p_activation_local_date date, p_timezone_name text)
returns public.weekly_report_activations
language plpgsql security definer set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_now timestamptz := now();
  v_activation public.weekly_report_activations%rowtype;
begin
  if v_user_id is null then raise exception 'authentication required'; end if;
  if p_timezone_name is null or not exists (select 1 from pg_catalog.pg_timezone_names where name = btrim(p_timezone_name)) then raise exception 'timezone_name must be a valid IANA time zone'; end if;
  if p_activation_local_date is distinct from (v_now at time zone btrim(p_timezone_name))::date then raise exception 'activation_local_date must be today in timezone_name'; end if;
  insert into public.weekly_report_activations (user_id, activated_at, activation_local_date, timezone_name)
  values (v_user_id, v_now, p_activation_local_date, btrim(p_timezone_name))
  on conflict (user_id) do nothing
  returning * into v_activation;
  if not found then
    select * into v_activation from public.weekly_report_activations where user_id = v_user_id;
  end if;
  if v_activation.activated_at = v_now then
    insert into public.weekly_report_habit_config_versions (user_id, habit_id, effective_from, effective_local_date, effective_timezone_name, name, emoji, habit_type, target_count, schedule, is_archived, source_event, source_updated_at)
    select h.user_id, h.id, v_activation.activated_at, v_activation.activation_local_date, v_activation.timezone_name, h.name, h.emoji, h.habit_type, h.target_count, h.schedule, h.is_archived, 'activation', h.updated_at
    from public.habits as h where h.user_id = v_user_id;
  end if;
  return v_activation;
end;
$$;
create index if not exists idx_weekly_report_config_user_habit_effective on public.weekly_report_habit_config_versions (user_id, habit_id, effective_from desc);
create unique index if not exists idx_weekly_report_config_source_mutation on public.weekly_report_habit_config_versions (user_id, habit_id, source_mutation_id) where source_mutation_id is not null;

create table if not exists public.weekly_reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  week_start_date date not null,
  week_end_date date not null,
  timezone_name text not null,
  status text not null default 'provisional',
  is_first_partial_week boolean not null default false,
  scheduled_count integer not null default 0,
  completed_count integer not null default 0,
  completion_rate numeric,
  best_day date,
  previous_report_id uuid,
  trend_kind text not null default 'unavailable',
  trend_delta numeric,
  comparability_reason text,
  schema_version integer not null default 1,
  metrics_policy_version integer not null default 1,
  content_version integer not null default 1,
  message_keys jsonb not null default '[]'::jsonb,
  generated_at timestamptz not null default now(),
  refreshed_at timestamptz,
  finalized_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint weekly_reports_user_week_unique unique (user_id, week_start_date),
  constraint weekly_reports_id_user_unique unique (id, user_id),
  constraint weekly_reports_week_start_check check (extract(isodow from week_start_date) = 1),
  constraint weekly_reports_week_end_check check (extract(isodow from week_end_date) = 7 and week_end_date = week_start_date + 6),
  constraint weekly_reports_timezone_check check (btrim(timezone_name) <> ''),
  constraint weekly_reports_status_check check (status in ('provisional', 'final')),
  constraint weekly_reports_trend_check check (trend_kind in ('improved', 'stable', 'declined', 'unavailable')),
  constraint weekly_reports_counts_check check (scheduled_count >= 0 and completed_count >= 0 and completed_count <= scheduled_count),
  constraint weekly_reports_rate_check check ((scheduled_count = 0 and completion_rate is null) or (scheduled_count > 0 and completion_rate between 0 and 1)),
  constraint weekly_reports_finalized_check check ((status = 'provisional' and finalized_at is null) or (status = 'final' and finalized_at is not null)),
  constraint weekly_reports_message_keys_check check (jsonb_typeof(message_keys) = 'array')
);
create index if not exists idx_weekly_reports_user_week_desc on public.weekly_reports (user_id, week_start_date desc);
create index if not exists idx_weekly_reports_user_id on public.weekly_reports (user_id, id);
alter table public.weekly_reports add constraint weekly_reports_previous_report_fk foreign key (previous_report_id) references public.weekly_reports(id) on delete set null;

create table if not exists public.weekly_report_days (
  report_id uuid not null,
  user_id uuid not null,
  local_date date not null,
  scheduled_count integer not null default 0,
  completed_count integer not null default 0,
  skipped_count integer not null default 0,
  completion_rate numeric,
  day_state text,
  primary key (report_id, local_date),
  constraint weekly_report_days_report_user_fk foreign key (report_id, user_id) references public.weekly_reports(id, user_id) on delete cascade,
  constraint weekly_report_days_counts_check check (scheduled_count >= 0 and completed_count >= 0 and skipped_count >= 0 and completed_count <= scheduled_count),
  constraint weekly_report_days_rate_check check ((scheduled_count = 0 and completion_rate is null) or (scheduled_count > 0 and completion_rate between 0 and 1)),
  constraint weekly_report_days_state_check check (day_state is null or day_state in ('noPlan', 'scheduledIncomplete', 'partial', 'completed', 'skipped'))
);
create index if not exists idx_weekly_report_days_user_date on public.weekly_report_days (user_id, local_date desc);

create or replace function app_private.is_valid_weekly_report_occurrences(value jsonb)
returns boolean language plpgsql immutable set search_path = '' as $$
declare item jsonb;
begin
  if jsonb_typeof(value) is distinct from 'array' then return false; end if;
  for item in select * from jsonb_array_elements(value) loop
    if jsonb_typeof(item) is distinct from 'object'
       or not (item ? 'date') or jsonb_typeof(item->'date') is distinct from 'string'
       or not (item ? 'scope') or jsonb_typeof(item->'scope') is distinct from 'string'
       or not (item ? 'scheduleType') or jsonb_typeof(item->'scheduleType') is distinct from 'string'
       or not (item ? 'scheduled') or jsonb_typeof(item->'scheduled') is distinct from 'boolean'
       or not (item ? 'completed') or jsonb_typeof(item->'completed') is distinct from 'boolean'
       or not (item ? 'skipped') or jsonb_typeof(item->'skipped') is distinct from 'boolean' then
      return false;
    end if;
  end loop;
  return true;
exception when others then return false;
end;
$$;

create table if not exists public.weekly_report_habits (
  report_id uuid not null,
  user_id uuid not null,
  habit_id text not null,
  name text not null,
  emoji text,
  habit_type text not null,
  target_count numeric,
  schedule jsonb not null,
  scheduled_count integer not null default 0,
  completed_count integer not null default 0,
  skipped_count integer not null default 0,
  completion_rate numeric,
  streak_snapshot jsonb,
  occurrences jsonb not null default '[]'::jsonb,
  primary key (report_id, habit_id),
  constraint weekly_report_habits_report_user_fk foreign key (report_id, user_id) references public.weekly_reports(id, user_id) on delete cascade,
  constraint weekly_report_habits_type_check check (habit_type in ('check', 'count')),
  constraint weekly_report_habits_target_check check (target_count is null or target_count > 0),
  constraint weekly_report_habits_schedule_check check (public.is_valid_habit_schedule(schedule)),
  constraint weekly_report_habits_occurrences_check check (app_private.is_valid_weekly_report_occurrences(occurrences)),
  constraint weekly_report_habits_counts_check check (scheduled_count >= 0 and completed_count >= 0 and skipped_count >= 0 and completed_count <= scheduled_count),
  constraint weekly_report_habits_rate_check check ((scheduled_count = 0 and completion_rate is null) or (scheduled_count > 0 and completion_rate between 0 and 1))
);
create index if not exists idx_weekly_report_habits_user_habit on public.weekly_report_habits (user_id, habit_id, report_id);

create table if not exists public.weekly_report_recommendations (
  id uuid primary key default gen_random_uuid(),
  report_id uuid not null,
  user_id uuid not null,
  habit_id text,
  recommendation_type text not null,
  reason_code text not null,
  proposed_patch jsonb not null default '{}'::jsonb,
  status text not null default 'proposed',
  created_at timestamptz not null default now(),
  acted_at timestamptz,
  constraint weekly_report_recommendations_report_user_fk foreign key (report_id, user_id) references public.weekly_reports(id, user_id) on delete cascade,
  constraint weekly_report_recommendations_status_check check (status in ('proposed', 'accepted', 'dismissed')),
  constraint weekly_report_recommendations_patch_check check (jsonb_typeof(proposed_patch) = 'object')
);
create index if not exists idx_weekly_report_recommendations_report on public.weekly_report_recommendations (report_id, created_at);

create or replace function app_private.weekly_report_capture_habit_config()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  v_activation public.weekly_report_activations%rowtype;
  v_event text;
  v_effective_at timestamptz;
begin
  select * into v_activation from public.weekly_report_activations where user_id = coalesce(new.user_id, old.user_id);
  if not found then
    if tg_op = 'DELETE' then return old; else return new; end if;
  end if;
  if tg_op = 'DELETE' then
    v_event := 'delete'; v_effective_at := statement_timestamp();
  elsif tg_op = 'INSERT' then
    v_event := 'insert'; v_effective_at := coalesce(new.updated_at, statement_timestamp());
  elsif old.name is distinct from new.name or old.emoji is distinct from new.emoji or old.habit_type is distinct from new.habit_type or old.target_count is distinct from new.target_count or old.schedule is distinct from new.schedule or old.is_archived is distinct from new.is_archived then
    v_event := case when new.is_archived then 'archive' else 'update' end; v_effective_at := coalesce(new.updated_at, statement_timestamp());
  else return new;
  end if;
  insert into public.weekly_report_habit_config_versions (user_id, habit_id, effective_from, effective_local_date, effective_timezone_name, name, emoji, habit_type, target_count, schedule, is_archived, source_event, source_updated_at, observed_at)
  values (coalesce(new.user_id, old.user_id), coalesce(new.id, old.id), v_effective_at, (v_effective_at at time zone v_activation.timezone_name)::date, v_activation.timezone_name, coalesce(new.name, old.name), coalesce(new.emoji, old.emoji), coalesce(new.habit_type, old.habit_type), coalesce(new.target_count, old.target_count), coalesce(new.schedule, old.schedule), coalesce(new.is_archived, true), v_event, coalesce(new.updated_at, old.updated_at), statement_timestamp());
  if tg_op = 'DELETE' then return old; else return new; end if;
end;
$$;
drop trigger if exists trg_weekly_report_capture_habit_config on public.habits;
create trigger trg_weekly_report_capture_habit_config after insert or update or delete on public.habits for each row execute function app_private.weekly_report_capture_habit_config();

create or replace function app_private.record_weekly_report_habit_config_version(p_user_id uuid, p_habit_id uuid, p_effective_from timestamptz, p_effective_local_date date, p_timezone_name text, p_name text, p_emoji text, p_habit_type text, p_target_count numeric, p_schedule jsonb, p_is_archived boolean, p_source_updated_at timestamptz, p_source_mutation_id text)
returns public.weekly_report_habit_config_versions language plpgsql security definer set search_path = '' as $$
declare v_row public.weekly_report_habit_config_versions%rowtype;
begin
  if p_timezone_name is null or not exists (select 1 from pg_catalog.pg_timezone_names where name = btrim(p_timezone_name)) then raise exception 'timezone_name must be a valid IANA time zone'; end if;
  if p_effective_local_date is distinct from (p_effective_from at time zone btrim(p_timezone_name))::date then raise exception 'effective_local_date must match effective_from in effective_timezone_name'; end if;
  insert into public.weekly_report_habit_config_versions (user_id, habit_id, effective_from, effective_local_date, effective_timezone_name, name, emoji, habit_type, target_count, schedule, is_archived, source_event, source_updated_at, source_mutation_id)
  values (p_user_id, p_habit_id, p_effective_from, p_effective_local_date, p_timezone_name, p_name, p_emoji, p_habit_type, p_target_count, p_schedule, p_is_archived, 'explicit_sync', p_source_updated_at, p_source_mutation_id)
  on conflict (user_id, habit_id, source_mutation_id) where source_mutation_id is not null do update set observed_at = now()
  returning * into v_row;
  return v_row;
end;
$$;

create or replace function app_private.weekly_report_guard_immutable()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if old.status = 'final' then raise exception 'final weekly reports are immutable'; end if;
  if tg_op = 'DELETE' then return old; end if;
  return new;
end;
$$;
create or replace function app_private.weekly_report_guard_final_child()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if tg_op = 'DELETE' then
    if exists (select 1 from public.weekly_reports where id = old.report_id and status = 'final') then raise exception 'children of final weekly reports are immutable'; end if;
    return old;
  else
    if exists (select 1 from public.weekly_reports where id = new.report_id and status = 'final') then raise exception 'children of final weekly reports are immutable'; end if;
    return new;
  end if;
end;
$$;
drop trigger if exists trg_weekly_reports_guard_immutable on public.weekly_reports;
create trigger trg_weekly_reports_guard_immutable before update or delete on public.weekly_reports for each row execute function app_private.weekly_report_guard_immutable();
drop trigger if exists trg_weekly_reports_set_updated_at on public.weekly_reports;
create trigger trg_weekly_reports_set_updated_at before update on public.weekly_reports for each row execute function app_private.set_updated_at();
do $$ declare t text; begin foreach t in array array['weekly_report_days','weekly_report_habits','weekly_report_recommendations'] loop execute format('drop trigger if exists %I on public.%I', 'trg_' || t || '_guard_final', t); execute format('create trigger %I before insert or update or delete on public.%I for each row execute function app_private.weekly_report_guard_final_child()', 'trg_' || t || '_guard_final', t); end loop; end $$;

alter table public.weekly_report_activations enable row level security;
alter table public.weekly_report_habit_config_versions enable row level security;
alter table public.weekly_reports enable row level security;
alter table public.weekly_report_days enable row level security;
alter table public.weekly_report_habits enable row level security;
alter table public.weekly_report_recommendations enable row level security;
revoke all on public.weekly_report_activations, public.weekly_report_habit_config_versions, public.weekly_reports, public.weekly_report_days, public.weekly_report_habits, public.weekly_report_recommendations from public, anon, authenticated;
grant select on public.weekly_report_activations to authenticated;
revoke insert, update, delete on public.weekly_report_activations from public, anon, authenticated;
create policy weekly_report_activations_select_own on public.weekly_report_activations for select to authenticated using ((select auth.uid()) = user_id);
revoke all on function app_private.weekly_report_capture_habit_config() from public, anon, authenticated;
revoke all on function app_private.is_valid_weekly_report_occurrences(jsonb) from public, anon, authenticated;
revoke all on function public.activate_weekly_report(date, text) from public, anon, authenticated;
grant execute on function public.activate_weekly_report(date, text) to authenticated, service_role;
revoke all on function app_private.record_weekly_report_habit_config_version(uuid, uuid, timestamptz, date, text, text, text, text, numeric, jsonb, boolean, timestamptz, text) from public, anon, authenticated;
revoke all on function app_private.weekly_report_guard_immutable() from public, anon, authenticated;
revoke all on function app_private.weekly_report_guard_final_child() from public, anon, authenticated;
comment on table public.weekly_report_habit_config_versions is 'Feature-scoped effective habit snapshots from activation onward; not global event sourcing.';
comment on column public.weekly_report_habit_config_versions.effective_from is 'Canonical primary ordering key; future reads order by effective_from, source_updated_at NULLS LAST, created_at, source_mutation_id NULLS LAST, id.';
comment on column public.weekly_report_habit_config_versions.observed_at is 'Server arrival/observation time, intentionally distinct from effective_from.';
comment on column public.weekly_report_habit_config_versions.source_mutation_id is 'Scoped idempotency key unique per user and habit when supplied.';
comment on table public.weekly_reports is 'Historical Weekly Report snapshots. Direct API table access is denied; future RPCs expose entitlement-shaped reads.';
comment on column public.weekly_report_habit_config_versions.source_updated_at is 'Source mutation timestamp when available; trigger fallback is server-observed updated_at.';

commit;
