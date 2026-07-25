begin;

create extension if not exists pgcrypto;
create schema if not exists app_private;

alter table public.profiles
  add column if not exists habit_time_zone text;

create table if not exists public.habit_streak_shields (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  habit_id uuid not null references public.habits(id) on delete cascade,
  utility_id text not null references public.shop_items(id) on delete restrict,
  effect_id uuid not null references public.user_utility_effects(id) on delete restrict,
  logical_time_zone text not null,
  request_id text not null,
  operation_id text not null,
  protected_occurrence_date date not null,
  status text not null default 'armed',
  activated_at timestamptz not null default now(),
  consumed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint habit_streak_shields_request_id_check check (btrim(request_id) <> ''),
  constraint habit_streak_shields_operation_id_check check (btrim(operation_id) <> ''),
  constraint habit_streak_shields_logical_time_zone_check check (
    btrim(logical_time_zone) <> ''
  ),
  constraint habit_streak_shields_status_check check (
    status in ('armed', 'consumed', 'cancelled', 'expired')
  ),
  constraint habit_streak_shields_consumed_at_check check (
    (status = 'consumed' and consumed_at is not null)
    or (status <> 'consumed' and consumed_at is null)
  )
);

create unique index if not exists idx_habit_streak_shields_user_request_unique
  on public.habit_streak_shields (user_id, request_id);
create unique index if not exists idx_habit_streak_shields_user_operation_unique
  on public.habit_streak_shields (user_id, operation_id);
create unique index if not exists idx_habit_streak_shields_one_active_per_habit
  on public.habit_streak_shields (user_id, habit_id)
  where status = 'armed';
create unique index if not exists idx_habit_streak_shields_habit_date_unique
  on public.habit_streak_shields (user_id, habit_id, protected_occurrence_date);
create index if not exists idx_habit_streak_shields_user_status
  on public.habit_streak_shields (user_id, status, activated_at desc);
create index if not exists idx_habit_streak_shields_habit_date_status
  on public.habit_streak_shields (user_id, habit_id, protected_occurrence_date, status);
create unique index if not exists idx_habit_streak_shields_effect_id_unique
  on public.habit_streak_shields (effect_id);

drop trigger if exists trg_habit_streak_shields_set_updated_at
  on public.habit_streak_shields;
create trigger trg_habit_streak_shields_set_updated_at
before update on public.habit_streak_shields
for each row
execute function public.set_updated_at();

alter table public.habit_streak_shields enable row level security;

drop policy if exists habit_streak_shields_select_own
  on public.habit_streak_shields;
create policy habit_streak_shields_select_own
  on public.habit_streak_shields
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

revoke all on public.habit_streak_shields from public, anon, authenticated;
grant select on public.habit_streak_shields to authenticated;

create table if not exists public.habit_streak_breaks (
  id uuid primary key default gen_random_uuid(),
  request_id text not null,
  break_id text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  habit_id uuid not null references public.habits(id) on delete cascade,
  logical_time_zone text not null,
  missed_occurrence_date date not null,
  previous_streak integer not null,
  current_streak_after_break integer not null default 0,
  status text not null default 'recoverable',
  broken_at timestamptz not null default now(),
  recoverable_until timestamptz not null,
  recovered_at timestamptz,
  recovery_request_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint habit_streak_breaks_request_id_check check (btrim(request_id) <> ''),
  constraint habit_streak_breaks_break_id_check check (btrim(break_id) <> ''),
  constraint habit_streak_breaks_logical_time_zone_check check (
    btrim(logical_time_zone) <> ''
  ),
  constraint habit_streak_breaks_previous_streak_check check (previous_streak >= 0),
  constraint habit_streak_breaks_current_streak_after_break_check check (
    current_streak_after_break >= 0
  ),
  constraint habit_streak_breaks_status_check check (
    status in ('recoverable', 'recovered', 'expired')
  ),
  constraint habit_streak_breaks_recovered_at_check check (
    (status = 'recovered' and recovered_at is not null and recovery_request_id is not null)
    or (status <> 'recovered' and recovered_at is null and recovery_request_id is null)
  ),
  constraint habit_streak_breaks_recovery_request_id_check check (
    recovery_request_id is null or btrim(recovery_request_id) <> ''
  )
);

create unique index if not exists idx_habit_streak_breaks_user_break_unique
  on public.habit_streak_breaks (user_id, break_id);
create unique index if not exists idx_habit_streak_breaks_user_request_unique
  on public.habit_streak_breaks (user_id, request_id);
create unique index if not exists idx_habit_streak_breaks_user_habit_date_unique
  on public.habit_streak_breaks (user_id, habit_id, missed_occurrence_date);
create unique index if not exists idx_habit_streak_breaks_recovery_request_unique
  on public.habit_streak_breaks (user_id, recovery_request_id)
  where recovery_request_id is not null;
create index if not exists idx_habit_streak_breaks_user_status
  on public.habit_streak_breaks (user_id, status, broken_at desc);
create index if not exists idx_habit_streak_breaks_habit_date_status
  on public.habit_streak_breaks (user_id, habit_id, missed_occurrence_date, status);

drop trigger if exists trg_habit_streak_breaks_set_updated_at
  on public.habit_streak_breaks;
create trigger trg_habit_streak_breaks_set_updated_at
before update on public.habit_streak_breaks
for each row
execute function public.set_updated_at();

alter table public.habit_streak_breaks enable row level security;

drop policy if exists habit_streak_breaks_select_own
  on public.habit_streak_breaks;
create policy habit_streak_breaks_select_own
  on public.habit_streak_breaks
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

revoke all on public.habit_streak_breaks from public, anon, authenticated;
grant select on public.habit_streak_breaks to authenticated;

comment on column public.profiles.habit_time_zone is
  'IANA time zone used to compute the habit logical day, for example Europe/Madrid or Asia/Tokyo. UTC offsets such as +02:00 are not valid.';
comment on column public.habit_streak_shields.logical_time_zone is
  'IANA time zone used to evaluate this shield operation logical date.';
comment on column public.habit_streak_breaks.logical_time_zone is
  'IANA time zone used to evaluate this streak break logical date.';
comment on column public.habit_streak_breaks.recoverable_until is
  'Instant for missed_occurrence_date 00:00:00 in logical_time_zone + 48 hours. This preserves Flutter''s date-anchored recovery window and does not extend it when the backend closes the occurrence later.';

create or replace function app_private.get_habit_time_zone(
  p_user_id uuid
)
returns text
language plpgsql
stable
set search_path = ''
as $$
declare
  v_time_zone text;
begin
  select btrim(coalesce(profile.habit_time_zone, ''))
    into v_time_zone
  from public.profiles as profile
  where profile.id = p_user_id;

  if v_time_zone is null or v_time_zone = '' then
    raise exception 'habit time zone is not configured';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_timezone_names
    where name = v_time_zone
  ) then
    raise exception 'habit time zone is not a valid IANA time zone';
  end if;

  return v_time_zone;
end;
$$;

create or replace function public.set_habit_time_zone(
  p_time_zone text
)
returns public.profiles
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_time_zone text := btrim(coalesce(p_time_zone, ''));
  v_profile public.profiles%rowtype;
begin
  if v_user_id is null then
    raise exception 'authentication required';
  end if;
  if v_time_zone = '' then
    raise exception 'habit time zone is required';
  end if;
  if not exists (
    select 1
    from pg_catalog.pg_timezone_names
    where name = v_time_zone
  ) then
    raise exception 'habit time zone is not a valid IANA time zone';
  end if;

  update public.profiles
     set habit_time_zone = v_time_zone,
         updated_at = now()
   where id = v_user_id
  returning * into v_profile;

  if not found then
    raise exception 'profile not found for authenticated user';
  end if;

  return v_profile;
end;
$$;

create or replace function app_private.validate_profile_habit_time_zone()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_time_zone text;
begin
  if new.habit_time_zone is null then
    return new;
  end if;

  v_time_zone := btrim(new.habit_time_zone);
  if v_time_zone = '' then
    raise exception 'habit time zone is not a valid IANA time zone';
  end if;
  if not exists (
    select 1
    from pg_catalog.pg_timezone_names
    where name = v_time_zone
  ) then
    raise exception 'habit time zone is not a valid IANA time zone';
  end if;

  new.habit_time_zone := v_time_zone;
  return new;
end;
$$;

drop trigger if exists trg_profiles_validate_habit_time_zone
  on public.profiles;
create trigger trg_profiles_validate_habit_time_zone
before insert or update of habit_time_zone on public.profiles
for each row
execute function app_private.validate_profile_habit_time_zone();

create or replace function app_private.is_habit_scheduled_on(
  p_schedule jsonb,
  p_logical_date date
)
returns boolean
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_schedule jsonb := coalesce(p_schedule, '{"type":"daily"}'::jsonb);
  v_type text := coalesce(v_schedule->>'type', 'daily');
begin
  if p_logical_date is null then
    return false;
  end if;

  if v_type = 'daily' then
    return true;
  end if;

  if v_type = 'weekly' then
    return exists (
      select 1
      from jsonb_array_elements_text(coalesce(v_schedule->'weekdays', '[]'::jsonb)) as weekday(value)
      where weekday.value ~ '^\d+$'
        and weekday.value::integer = extract(isodow from p_logical_date)::integer
    );
  end if;

  if v_type = 'once' then
    return v_schedule->>'date' = p_logical_date::text;
  end if;

  if v_type = 'timesPerWeek' then
    -- Flutter treats timesPerWeek as scheduled every day for streak continuity.
    -- The weekly target affects Home grouping only; it does not create automatic
    -- continuity for days without an individual completion/protection/recovery.
    return true;
  end if;

  return true;
end;
$$;

create or replace function app_private.habit_has_continuity_on(
  p_user_id uuid,
  p_habit_id uuid,
  p_logical_date date
)
returns boolean
language plpgsql
stable
set search_path = ''
as $$
declare
  v_habit public.habits%rowtype;
begin
  select *
    into v_habit
  from public.habits
  where id = p_habit_id
    and user_id = p_user_id;

  if not found then
    return false;
  end if;

  if not app_private.is_habit_scheduled_on(v_habit.schedule, p_logical_date) then
    return false;
  end if;

  if exists (
    select 1
    from public.habit_logs as log
    where log.user_id = p_user_id
      and log.habit_id = p_habit_id
      and log.log_date = p_logical_date
      and (
        (v_habit.habit_type = 'check' and log.is_completed = true)
        or (v_habit.habit_type = 'count' and log.value > 0)
      )
  ) then
    return true;
  end if;

  if exists (
    select 1
    from public.habit_streak_shields as shield
    where shield.user_id = p_user_id
      and shield.habit_id = p_habit_id
      and shield.protected_occurrence_date = p_logical_date
      and shield.status = 'consumed'
  ) then
    return true;
  end if;

  if exists (
    select 1
    from public.habit_streak_breaks as streak_break
    where streak_break.user_id = p_user_id
      and streak_break.habit_id = p_habit_id
      and streak_break.missed_occurrence_date = p_logical_date
      and streak_break.status = 'recovered'
  ) then
    return true;
  end if;

  return false;
end;
$$;

create or replace function app_private.habit_streak_before_date(
  p_user_id uuid,
  p_habit_id uuid,
  p_logical_date date
)
returns integer
language plpgsql
stable
set search_path = ''
as $$
declare
  v_habit public.habits%rowtype;
  v_time_zone text;
  v_created_local_date date;
  v_cursor date := p_logical_date - 1;
  v_streak integer := 0;
  v_guard integer := 0;
begin
  select *
    into v_habit
  from public.habits
  where id = p_habit_id
    and user_id = p_user_id;

  if not found or p_logical_date is null then
    return 0;
  end if;

  v_time_zone := app_private.get_habit_time_zone(p_user_id);
  v_created_local_date := (v_habit.created_at at time zone v_time_zone)::date;

  while v_guard < 3660 loop
    exit when v_cursor < v_created_local_date;
    v_guard := v_guard + 1;

    if not app_private.is_habit_scheduled_on(v_habit.schedule, v_cursor) then
      v_cursor := v_cursor - 1;
      continue;
    end if;

    if app_private.habit_has_continuity_on(p_user_id, p_habit_id, v_cursor) then
      v_streak := v_streak + 1;
      v_cursor := v_cursor - 1;
      continue;
    end if;

    exit;
  end loop;

  return v_streak;
end;
$$;

revoke all on function app_private.is_habit_scheduled_on(
  jsonb,
  date
) from public, anon, authenticated;
revoke all on function app_private.get_habit_time_zone(
  uuid
) from public, anon, authenticated;
revoke all on function app_private.validate_profile_habit_time_zone()
from public, anon, authenticated;
revoke all on function app_private.habit_has_continuity_on(
  uuid,
  uuid,
  date
) from public, anon, authenticated;
revoke all on function app_private.habit_streak_before_date(
  uuid,
  uuid,
  date
) from public, anon, authenticated;

create or replace function public.activate_streak_shield(
  p_request_id text,
  p_habit_id uuid,
  p_protected_occurrence_date date,
  p_operation_id text,
  p_utility_id text default 'utility_streak_shield_1'
)
returns public.habit_streak_shields
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_request_id text := btrim(coalesce(p_request_id, ''));
  v_operation_id text := btrim(coalesce(p_operation_id, ''));
  v_utility_id text := btrim(coalesce(p_utility_id, ''));
  v_time_zone text;
  v_today_local date;
  v_habit public.habits%rowtype;
  v_item public.shop_items%rowtype;
  v_existing_by_request public.habit_streak_shields%rowtype;
  v_existing_by_operation public.habit_streak_shields%rowtype;
  v_existing public.habit_streak_shields%rowtype;
  v_inventory_quantity integer;
  v_effect public.user_utility_effects%rowtype;
  v_shield public.habit_streak_shields%rowtype;
begin
  if v_user_id is null then
    raise exception 'authentication required';
  end if;
  if v_request_id = '' then
    raise exception 'request_id is required';
  end if;
  if p_habit_id is null then
    raise exception 'habit_id is required';
  end if;
  if p_protected_occurrence_date is null then
    raise exception 'protected_occurrence_date is required';
  end if;
  if v_operation_id = '' then
    raise exception 'operation_id is required';
  end if;
  if v_utility_id = '' then
    raise exception 'utility_id is required';
  end if;

  perform pg_advisory_xact_lock(hashtext(v_user_id::text));
  perform pg_advisory_xact_lock(hashtext('streak_shield_request:' || v_request_id));
  perform pg_advisory_xact_lock(
    hashtext('streak_shield_operation:' || v_user_id::text || ':' || v_operation_id)
  );
  perform pg_advisory_xact_lock(
    hashtext('streak_shield_habit:' || v_user_id::text || ':' || p_habit_id::text)
  );

  v_time_zone := app_private.get_habit_time_zone(v_user_id);
  v_today_local := (now() at time zone v_time_zone)::date;

  select *
    into v_existing_by_request
  from public.habit_streak_shields
  where user_id = v_user_id
    and request_id = v_request_id;

  select *
    into v_existing_by_operation
  from public.habit_streak_shields
  where user_id = v_user_id
    and operation_id = v_operation_id;

  if v_existing_by_request.id is not null
     and v_existing_by_operation.id is not null
     and v_existing_by_request.id <> v_existing_by_operation.id then
    raise exception 'request_id and operation_id refer to different streak shield operations';
  end if;

  if v_existing_by_request.id is not null then
    v_existing := v_existing_by_request;
  elsif v_existing_by_operation.id is not null then
    v_existing := v_existing_by_operation;
  end if;

  if v_existing.id is not null then
    if v_existing.habit_id <> p_habit_id
       or v_existing.utility_id <> v_utility_id
       or v_existing.request_id <> v_request_id
       or v_existing.operation_id <> v_operation_id
       or v_existing.protected_occurrence_date <> p_protected_occurrence_date then
      raise exception 'request_id or operation_id reused for a different streak shield operation';
    end if;

    return v_existing;
  end if;

  select *
    into v_habit
  from public.habits
  where id = p_habit_id
    and user_id = v_user_id
  for update;

  if not found then
    raise exception 'habit not found';
  end if;
  if v_habit.is_archived then
    raise exception 'habit is archived';
  end if;
  if p_protected_occurrence_date < (v_habit.created_at at time zone v_time_zone)::date then
    raise exception 'protected_occurrence_date is before habit creation date';
  end if;
  if p_protected_occurrence_date < v_today_local then
    raise exception 'cannot protect a past date';
  end if;
  if not app_private.is_habit_scheduled_on(v_habit.schedule, p_protected_occurrence_date) then
    raise exception 'habit is not scheduled on this date';
  end if;
  if exists (
    select 1
    from public.habit_streak_breaks as streak_break
    where streak_break.user_id = v_user_id
      and streak_break.habit_id = p_habit_id
      and streak_break.missed_occurrence_date = p_protected_occurrence_date
  ) then
    raise exception 'cannot protect a date with an existing streak break';
  end if;

  select *
    into v_item
  from public.shop_items
  where id = v_utility_id
    and is_active = true;

  if not found or v_item.category <> 'utility' or v_item.subtype <> 'streakShield' then
    raise exception 'utility must be an active streakShield';
  end if;

  update public.user_utility_effects as effect
     set remaining_uses = 0,
         status = 'completed',
         completed_at = coalesce(effect.completed_at, now()),
         updated_at = now()
    from public.habit_streak_shields as shield
   where shield.effect_id = effect.id
     and shield.user_id = v_user_id
     and shield.habit_id = p_habit_id
     and shield.status = 'armed'
     and shield.protected_occurrence_date < p_protected_occurrence_date;

  update public.habit_streak_shields
     set status = 'expired',
         updated_at = now()
   where user_id = v_user_id
     and habit_id = p_habit_id
     and status = 'armed'
     and protected_occurrence_date < p_protected_occurrence_date;

  if exists (
    select 1
    from public.habit_streak_shields as shield
    where shield.user_id = v_user_id
      and shield.habit_id = p_habit_id
      and shield.status = 'armed'
  ) then
    raise exception 'streak shield already active for habit';
  end if;

  select quantity
    into v_inventory_quantity
  from public.user_inventory
  where user_id = v_user_id
    and item_id = v_utility_id
  for update;

  if not found or v_inventory_quantity < 1 then
    raise exception 'utility inventory unavailable';
  end if;

  if v_inventory_quantity = 1 then
    delete from public.user_inventory
    where user_id = v_user_id
      and item_id = v_utility_id;
  else
    update public.user_inventory
       set quantity = quantity - 1,
           updated_at = now()
     where user_id = v_user_id
       and item_id = v_utility_id;
  end if;

  insert into public.user_utility_effects (
    user_id,
    utility_id,
    utility_type,
    activated_at,
    remaining_uses,
    total_uses,
    status,
    habit_id,
    completed_at,
    created_at,
    updated_at
  ) values (
    v_user_id,
    v_utility_id,
    v_item.subtype,
    now(),
    1,
    1,
    'active',
    p_habit_id,
    null,
    now(),
    now()
  )
  returning * into v_effect;

  insert into public.habit_streak_shields (
    user_id,
    habit_id,
    utility_id,
    effect_id,
    logical_time_zone,
    request_id,
    operation_id,
    protected_occurrence_date,
    status,
    activated_at,
    consumed_at,
    created_at,
    updated_at
  ) values (
    v_user_id,
    p_habit_id,
    v_utility_id,
    v_effect.id,
    v_time_zone,
    v_request_id,
    v_operation_id,
    p_protected_occurrence_date,
    'armed',
    now(),
    null,
    now(),
    now()
  )
  returning * into v_shield;

  insert into public.utility_consumption_ledger (
    user_id,
    request_id,
    utility_id,
    utility_type,
    operation_type,
    source_type,
    source_id,
    effect_id,
    habit_id,
    break_id,
    remaining_uses_before,
    remaining_uses_after,
    total_uses_before,
    total_uses_after,
    related_ledger_id,
    is_idempotent,
    created_at
  ) values (
    v_user_id,
    v_request_id,
    v_utility_id,
    v_item.subtype,
    'activate',
    'streak_shield',
    v_operation_id,
    v_effect.id,
    p_habit_id,
    null,
    0,
    1,
    0,
    1,
    null,
    false,
    now()
  );

  return v_shield;
end;
$$;

create or replace function public.close_missed_habit_occurrence(
  p_request_id text,
  p_habit_id uuid,
  p_logical_date date,
  p_break_id text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_request_id text := btrim(coalesce(p_request_id, ''));
  v_break_id text := btrim(coalesce(p_break_id, ''));
  v_time_zone text;
  v_today_local date;
  v_recoverable_until timestamptz;
  v_habit public.habits%rowtype;
  v_existing_by_request public.habit_streak_breaks%rowtype;
  v_existing_by_break public.habit_streak_breaks%rowtype;
  v_existing_by_occurrence public.habit_streak_breaks%rowtype;
  v_existing_break public.habit_streak_breaks%rowtype;
  v_shield public.habit_streak_shields%rowtype;
  v_effect public.user_utility_effects%rowtype;
  v_ledger public.utility_consumption_ledger%rowtype;
  v_break public.habit_streak_breaks%rowtype;
  v_previous_streak integer;
  v_break_status text;
  v_response_status text;
begin
  if v_user_id is null then
    raise exception 'authentication required';
  end if;
  if v_request_id = '' then
    raise exception 'request_id is required';
  end if;
  if p_habit_id is null then
    raise exception 'habit_id is required';
  end if;
  if p_logical_date is null then
    raise exception 'logical_date is required';
  end if;
  if v_break_id = '' then
    raise exception 'break_id is required';
  end if;

  perform pg_advisory_xact_lock(hashtext(v_user_id::text));
  perform pg_advisory_xact_lock(hashtext('streak_close_request:' || v_request_id));
  perform pg_advisory_xact_lock(
    hashtext('streak_close_break:' || v_user_id::text || ':' || v_break_id)
  );
  perform pg_advisory_xact_lock(
    hashtext(
      'streak_occurrence:' ||
      v_user_id::text ||
      ':' ||
      p_habit_id::text ||
      ':' ||
      p_logical_date::text
    )
  );

  v_time_zone := app_private.get_habit_time_zone(v_user_id);
  v_today_local := (now() at time zone v_time_zone)::date;

  if exists (
    select 1
    from public.utility_consumption_ledger as ledger
    where ledger.user_id = v_user_id
      and ledger.request_id = v_request_id
      and ledger.operation_type = 'consume'
      and ledger.source_type = 'streak_shield'
      and ledger.source_id = p_habit_id::text || ':' || p_logical_date::text
  ) then
    select *
      into v_shield
    from public.habit_streak_shields
    where user_id = v_user_id
      and habit_id = p_habit_id
      and protected_occurrence_date = p_logical_date;

    return jsonb_build_object(
      'status', 'shield_consumed',
      'shield', to_jsonb(v_shield),
      'break', null,
      'idempotent', true
    );
  end if;

  select *
    into v_existing_by_request
  from public.habit_streak_breaks
  where user_id = v_user_id
    and request_id = v_request_id;

  select *
    into v_existing_by_break
  from public.habit_streak_breaks
  where user_id = v_user_id
    and break_id = v_break_id;

  select *
    into v_existing_by_occurrence
  from public.habit_streak_breaks
  where user_id = v_user_id
    and habit_id = p_habit_id
    and missed_occurrence_date = p_logical_date;

  if v_existing_by_request.id is not null
     and v_existing_by_break.id is not null
     and v_existing_by_request.id <> v_existing_by_break.id then
    raise exception 'request_id and break_id refer to different streak break operations';
  end if;
  if v_existing_by_request.id is not null
     and v_existing_by_occurrence.id is not null
     and v_existing_by_request.id <> v_existing_by_occurrence.id then
    raise exception 'request_id and occurrence refer to different streak break operations';
  end if;
  if v_existing_by_break.id is not null
     and v_existing_by_occurrence.id is not null
     and v_existing_by_break.id <> v_existing_by_occurrence.id then
    raise exception 'break_id and occurrence refer to different streak break operations';
  end if;

  if v_existing_by_request.id is not null then
    v_existing_break := v_existing_by_request;
  elsif v_existing_by_break.id is not null then
    v_existing_break := v_existing_by_break;
  elsif v_existing_by_occurrence.id is not null then
    v_existing_break := v_existing_by_occurrence;
  end if;

  if v_existing_break.id is not null then
    if v_existing_break.habit_id <> p_habit_id
       or v_existing_break.missed_occurrence_date <> p_logical_date
       or v_existing_break.request_id <> v_request_id
       or v_existing_break.break_id <> v_break_id then
      raise exception 'request_id, break_id, or occurrence reused for a different streak break operation';
    end if;

    return jsonb_build_object(
      'status', case
        when v_existing_break.status = 'expired' then 'break_expired'
        else 'break_recorded'
      end,
      'shield', null,
      'break', to_jsonb(v_existing_break),
      'idempotent', true
    );
  end if;

  select *
    into v_habit
  from public.habits
  where id = p_habit_id
    and user_id = v_user_id
  for update;

  if not found then
    raise exception 'habit not found';
  end if;
  if v_habit.is_archived then
    raise exception 'habit is archived';
  end if;
  if p_logical_date >= v_today_local then
    raise exception 'cannot close today or a future missed occurrence';
  end if;
  if p_logical_date < (v_habit.created_at at time zone v_time_zone)::date then
    raise exception 'logical_date is before habit creation date';
  end if;
  if not app_private.is_habit_scheduled_on(v_habit.schedule, p_logical_date) then
    raise exception 'habit is not scheduled on this date';
  end if;

  if app_private.habit_has_continuity_on(v_user_id, p_habit_id, p_logical_date) then
    return jsonb_build_object(
      'status', 'already_continuous',
      'shield', null,
      'break', null,
      'idempotent', false
    );
  end if;

  select *
    into v_shield
  from public.habit_streak_shields
  where user_id = v_user_id
    and habit_id = p_habit_id
    and protected_occurrence_date = p_logical_date
    and status = 'armed'
  for update;

  if found then
    select *
      into v_effect
    from public.user_utility_effects
    where id = v_shield.effect_id
      and user_id = v_user_id
      and utility_id = v_shield.utility_id
      and utility_type = 'streakShield'
      and habit_id = p_habit_id
      and status = 'active'
    for update;

    if not found then
      raise exception 'active streak shield effect not found';
    end if;
    if v_effect.remaining_uses < 1 then
      raise exception 'streak shield effect is exhausted';
    end if;

    update public.user_utility_effects
       set remaining_uses = v_effect.remaining_uses - 1,
           status = case when v_effect.remaining_uses - 1 = 0 then 'completed' else 'active' end,
           completed_at = case
             when v_effect.remaining_uses - 1 = 0 then now()
             else completed_at
           end,
           updated_at = now()
     where id = v_effect.id;

    update public.habit_streak_shields
       set status = 'consumed',
           consumed_at = now(),
           updated_at = now()
     where id = v_shield.id
    returning * into v_shield;

    insert into public.utility_consumption_ledger (
      user_id,
      request_id,
      utility_id,
      utility_type,
      operation_type,
      source_type,
      source_id,
      effect_id,
      habit_id,
      break_id,
      remaining_uses_before,
      remaining_uses_after,
      total_uses_before,
      total_uses_after,
      related_ledger_id,
      is_idempotent,
      created_at
    ) values (
      v_user_id,
      v_request_id,
      v_shield.utility_id,
      'streakShield',
      'consume',
      'streak_shield',
      p_habit_id::text || ':' || p_logical_date::text,
      v_effect.id,
      p_habit_id,
      null,
      v_effect.remaining_uses,
      v_effect.remaining_uses - 1,
      v_effect.total_uses,
      v_effect.total_uses,
      null,
      false,
      now()
    )
    returning * into v_ledger;

    return jsonb_build_object(
      'status', 'shield_consumed',
      'shield', to_jsonb(v_shield),
      'break', null,
      'ledger', to_jsonb(v_ledger),
      'idempotent', false
    );
  end if;

  v_previous_streak :=
    app_private.habit_streak_before_date(v_user_id, p_habit_id, p_logical_date);
  v_recoverable_until :=
    (p_logical_date::timestamp at time zone v_time_zone) + interval '48 hours';
  v_break_status := case
    when now() > v_recoverable_until then 'expired'
    else 'recoverable'
  end;
  v_response_status := case
    when v_break_status = 'expired' then 'break_expired'
    else 'break_recorded'
  end;

  insert into public.habit_streak_breaks (
    request_id,
    break_id,
    user_id,
    habit_id,
    logical_time_zone,
    missed_occurrence_date,
    previous_streak,
    current_streak_after_break,
    status,
    broken_at,
    recoverable_until,
    recovered_at,
    recovery_request_id,
    created_at,
    updated_at
  ) values (
    v_request_id,
    v_break_id,
    v_user_id,
    p_habit_id,
    v_time_zone,
    p_logical_date,
    v_previous_streak,
    0,
    v_break_status,
    now(),
    v_recoverable_until,
    null,
    null,
    now(),
    now()
  )
  returning * into v_break;

  return jsonb_build_object(
    'status', v_response_status,
    'shield', null,
    'break', to_jsonb(v_break),
    'idempotent', false
  );
end;
$$;

create or replace function public.recover_streak_break(
  p_request_id text,
  p_break_id text,
  p_utility_id text default 'utility_streak_recover_1'
)
returns public.habit_streak_breaks
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_request_id text := btrim(coalesce(p_request_id, ''));
  v_break_id text := btrim(coalesce(p_break_id, ''));
  v_utility_id text := btrim(coalesce(p_utility_id, ''));
  v_item public.shop_items%rowtype;
  v_inventory_quantity integer;
  v_break public.habit_streak_breaks%rowtype;
  v_existing public.habit_streak_breaks%rowtype;
  v_effect public.user_utility_effects%rowtype;
begin
  if v_user_id is null then
    raise exception 'authentication required';
  end if;
  if v_request_id = '' then
    raise exception 'request_id is required';
  end if;
  if v_break_id = '' then
    raise exception 'break_id is required';
  end if;
  if v_utility_id = '' then
    raise exception 'utility_id is required';
  end if;

  perform pg_advisory_xact_lock(hashtext(v_user_id::text));
  perform pg_advisory_xact_lock(hashtext('streak_recover_request:' || v_request_id));
  perform pg_advisory_xact_lock(
    hashtext('streak_recover_break:' || v_user_id::text || ':' || v_break_id)
  );

  select *
    into v_existing
  from public.habit_streak_breaks
  where user_id = v_user_id
    and recovery_request_id = v_request_id;

  if found then
    if v_existing.break_id <> v_break_id then
      raise exception 'request_id already used by another streak recovery';
    end if;

    return v_existing;
  end if;

  select *
    into v_break
  from public.habit_streak_breaks
  where user_id = v_user_id
    and break_id = v_break_id
  for update;

  if not found then
    raise exception 'streak break not found';
  end if;

  if v_break.status = 'recovered' then
    return v_break;
  end if;

  if v_break.status = 'expired' then
    return v_break;
  end if;

  if now() > v_break.recoverable_until then
    update public.habit_streak_breaks
       set status = 'expired',
           updated_at = now()
     where id = v_break.id
    returning * into v_break;

    return v_break;
  end if;

  select *
    into v_item
  from public.shop_items
  where id = v_utility_id
    and is_active = true;

  if not found or v_item.category <> 'utility' or v_item.subtype <> 'streakRecover' then
    raise exception 'utility must be an active streakRecover';
  end if;

  select quantity
    into v_inventory_quantity
  from public.user_inventory
  where user_id = v_user_id
    and item_id = v_utility_id
  for update;

  if not found or v_inventory_quantity < 1 then
    raise exception 'utility inventory unavailable';
  end if;

  if v_inventory_quantity = 1 then
    delete from public.user_inventory
    where user_id = v_user_id
      and item_id = v_utility_id;
  else
    update public.user_inventory
       set quantity = quantity - 1,
           updated_at = now()
     where user_id = v_user_id
       and item_id = v_utility_id;
  end if;

  insert into public.user_utility_effects (
    user_id,
    utility_id,
    utility_type,
    activated_at,
    remaining_uses,
    total_uses,
    status,
    habit_id,
    completed_at,
    created_at,
    updated_at
  ) values (
    v_user_id,
    v_utility_id,
    v_item.subtype,
    now(),
    0,
    1,
    'completed',
    v_break.habit_id,
    now(),
    now(),
    now()
  )
  returning * into v_effect;

  update public.habit_streak_breaks
     set status = 'recovered',
         recovered_at = now(),
         recovery_request_id = v_request_id,
         updated_at = now()
   where id = v_break.id
  returning * into v_break;

  insert into public.utility_consumption_ledger (
    user_id,
    request_id,
    utility_id,
    utility_type,
    operation_type,
    source_type,
    source_id,
    effect_id,
    habit_id,
    break_id,
    remaining_uses_before,
    remaining_uses_after,
    total_uses_before,
    total_uses_after,
    related_ledger_id,
    is_idempotent,
    created_at
  ) values (
    v_user_id,
    v_request_id,
    v_utility_id,
    v_item.subtype,
    'recover',
    'streak_recover',
    v_break_id,
    v_effect.id,
    v_break.habit_id,
    v_break_id,
    1,
    0,
    1,
    1,
    null,
    false,
    now()
  );

  return v_break;
end;
$$;

revoke all on function public.activate_streak_shield(
  text,
  uuid,
  date,
  text,
  text
) from public, anon, authenticated;
revoke all on function public.close_missed_habit_occurrence(
  text,
  uuid,
  date,
  text
) from public, anon, authenticated;
revoke all on function public.recover_streak_break(
  text,
  text,
  text
) from public, anon, authenticated;
revoke all on function public.set_habit_time_zone(
  text
) from public, anon, authenticated;

grant execute on function public.activate_streak_shield(
  text,
  uuid,
  date,
  text,
  text
) to authenticated, service_role;
grant execute on function public.close_missed_habit_occurrence(
  text,
  uuid,
  date,
  text
) to authenticated, service_role;
grant execute on function public.recover_streak_break(
  text,
  text,
  text
) to authenticated, service_role;
grant execute on function public.set_habit_time_zone(
  text
) to authenticated, service_role;

commit;
