begin;

-- Phase 4A: extend the existing canonical habit/log paths.  This is deliberately
-- feature-scoped; it is not a general sync or event-sourcing framework.
alter table public.habit_logs
  add column if not exists is_skipped boolean not null default false;

-- habit_id remains the logical identity after a live habit is deleted.  Remove
-- only the activity FK; user ownership and RLS remain enforced below.
do $$
declare
  constraint_name text;
begin
  for constraint_name in
    select c.conname
    from pg_constraint c
    where c.conrelid = 'public.habit_logs'::regclass
      and c.contype = 'f'
      and c.confrelid = 'public.habits'::regclass
  loop
    execute format('alter table public.habit_logs drop constraint %I', constraint_name);
  end loop;
end;
$$;

create index if not exists idx_habit_logs_user_habit_date
  on public.habit_logs (user_id, habit_id, log_date);

alter table public.habits
  add column if not exists source_mutation_id text,
  add column if not exists effective_from timestamptz,
  add column if not exists effective_timezone_name text;

create or replace function app_private.weekly_report_capture_habit_config()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  v_activation public.weekly_report_activations%rowtype;
  v_event text;
  v_effective_at timestamptz;
  v_timezone text;
  v_mutation_id text;
  v_candidate timestamptz;
begin
  select * into v_activation
    from public.weekly_report_activations
   where user_id = coalesce(new.user_id, old.user_id);
  if not found then
    if tg_op = 'DELETE' then return old; else return new; end if;
  end if;

  if tg_op = 'DELETE' then
    v_event := 'delete';
    v_effective_at := statement_timestamp();
    v_timezone := v_activation.timezone_name;
    v_mutation_id := null;
  elsif tg_op = 'INSERT' then
    v_event := 'insert';
    v_candidate := new.effective_from;
    v_timezone := nullif(btrim(new.effective_timezone_name), '');
    v_mutation_id := nullif(btrim(new.source_mutation_id), '');
    if v_candidate is not null
       and v_timezone is not null
       and exists (select 1 from pg_catalog.pg_timezone_names where name = v_timezone)
       and v_candidate <= statement_timestamp() + interval '5 minutes' then
      v_effective_at := v_candidate;
    else
      v_effective_at := coalesce(new.updated_at, statement_timestamp());
      v_timezone := v_activation.timezone_name;
      v_mutation_id := null;
    end if;
  elsif old.name is distinct from new.name
     or old.emoji is distinct from new.emoji
     or old.habit_type is distinct from new.habit_type
     or old.target_count is distinct from new.target_count
     or old.schedule is distinct from new.schedule
     or old.is_archived is distinct from new.is_archived then
    v_event := case when new.is_archived then 'archive' else 'update' end;
    v_candidate := new.effective_from;
    v_timezone := nullif(btrim(new.effective_timezone_name), '');
    v_mutation_id := nullif(btrim(new.source_mutation_id), '');
    if v_candidate is not null
       and v_timezone is not null
       and exists (select 1 from pg_catalog.pg_timezone_names where name = v_timezone)
       and v_candidate <= statement_timestamp() + interval '5 minutes' then
      v_effective_at := v_candidate;
    else
      v_effective_at := coalesce(new.updated_at, statement_timestamp());
      v_timezone := v_activation.timezone_name;
      v_mutation_id := null;
    end if;
  else
    return new;
  end if;

  insert into public.weekly_report_habit_config_versions
    (user_id, habit_id, effective_from, effective_local_date,
     effective_timezone_name, name, emoji, habit_type, target_count, schedule,
     is_archived, source_event, source_updated_at, source_mutation_id,
     observed_at)
  values
    (coalesce(new.user_id, old.user_id), coalesce(new.id, old.id),
     v_effective_at, (v_effective_at at time zone v_timezone)::date,
     v_timezone, coalesce(new.name, old.name), coalesce(new.emoji, old.emoji),
     coalesce(new.habit_type, old.habit_type),
     coalesce(new.target_count, old.target_count),
     coalesce(new.schedule, old.schedule), coalesce(new.is_archived, true),
     v_event, coalesce(new.updated_at, old.updated_at), v_mutation_id,
     statement_timestamp())
  on conflict (user_id, habit_id, source_mutation_id)
    where source_mutation_id is not null
    do update set observed_at = excluded.observed_at;

  if tg_op = 'DELETE' then return old; else return new; end if;
end;
$$;

alter table public.habit_logs enable row level security;
revoke all on public.habit_logs from anon;
grant select, insert, update, delete on public.habit_logs to authenticated;

commit;
