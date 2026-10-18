begin;

-- Phase 1: server-authoritative economy foundation.
-- This migration is intentionally additive. It does not revoke legacy client
-- writes yet; that remains a separate migration after the mandatory Android
-- client transition.

create extension if not exists pgcrypto;
create schema if not exists app_private;

create table if not exists public.economy_runtime_policy (
  policy_id boolean primary key default true check (policy_id),
  minimum_android_version text not null default '0.0.0',
  -- 31 days covers offline delivery and the existing calendar/backfill flow;
  -- this remains server-configurable without a client write path.
  max_habit_backfill_days integer not null default 31
    check (max_habit_backfill_days >= 0 and max_habit_backfill_days <= 31),
  enabled boolean not null default true,
  updated_at timestamptz not null default now()
);

insert into public.economy_runtime_policy (
  policy_id, minimum_android_version, max_habit_backfill_days, enabled
)
values (true, '0.0.0', 31, true)
on conflict (policy_id) do nothing;

alter table public.economy_runtime_policy enable row level security;
revoke all on public.economy_runtime_policy from public, anon, authenticated;

create table if not exists public.economy_xp_ledger (
  id uuid primary key default gen_random_uuid(),
  request_id text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  source_type text not null,
  source_id text not null,
  operation_type text not null,
  xp_delta integer not null,
  related_ledger_id uuid references public.economy_xp_ledger(id) on delete set null,
  created_at timestamptz not null default now(),
  constraint economy_xp_ledger_request_id_check check (btrim(request_id) <> ''),
  constraint economy_xp_ledger_source_id_check check (btrim(source_id) <> ''),
  constraint economy_xp_ledger_source_type_check check (
    source_type in ('habit_completion', 'achievement_reward', 'level_reward')
  ),
  constraint economy_xp_ledger_operation_type_check check (
    operation_type in ('apply', 'reverse', 'claim')
  ),
  constraint economy_xp_ledger_request_id_unique unique (request_id)
);

create index if not exists idx_economy_xp_ledger_user_created_at
  on public.economy_xp_ledger (user_id, created_at desc);
create index if not exists idx_economy_xp_ledger_user_source
  on public.economy_xp_ledger (user_id, source_type, source_id);

alter table public.economy_xp_ledger enable row level security;
revoke all on public.economy_xp_ledger from public, anon, authenticated;
create policy economy_xp_ledger_select_own
  on public.economy_xp_ledger
  for select to authenticated
  using ((select auth.uid()) = user_id);

create table if not exists public.economy_habit_transition_ledger (
  id uuid primary key default gen_random_uuid(),
  request_id text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  habit_id uuid not null references public.habits(id) on delete cascade,
  logical_date date not null,
  transition_no integer not null check (transition_no > 0),
  is_completed boolean not null,
  habit_family_id text,
  habit_type text not null,
  target_count integer,
  value integer not null default 0 check (value >= 0),
  completion_event_id text not null,
  reward_ledger_id uuid,
  xp_ledger_id uuid references public.economy_xp_ledger(id) on delete set null,
  created_at timestamptz not null default now(),
  constraint economy_habit_transition_request_unique unique (request_id),
  constraint economy_habit_transition_cycle_unique unique (
    user_id, habit_id, logical_date, transition_no
  ),
  constraint economy_habit_transition_event_unique unique (completion_event_id)
);

create index if not exists idx_economy_habit_transition_user_date
  on public.economy_habit_transition_ledger (user_id, habit_id, logical_date, created_at);

alter table public.economy_habit_transition_ledger enable row level security;
revoke all on public.economy_habit_transition_ledger from public, anon, authenticated;
create policy economy_habit_transition_select_own
  on public.economy_habit_transition_ledger
  for select to authenticated
  using ((select auth.uid()) = user_id);

create or replace view app_private.authoritative_habit_completion_events as
select user_id, habit_id, logical_date, habit_family_id, habit_type,
       target_count, value, created_at
from (
  select distinct on (user_id, habit_id, logical_date)
    user_id, habit_id, logical_date, is_completed, habit_family_id,
    habit_type, target_count, value, created_at, transition_no
  from public.economy_habit_transition_ledger
  order by user_id, habit_id, logical_date, transition_no desc, created_at desc
) latest
where is_completed;

revoke all on app_private.authoritative_habit_completion_events
from public, anon, authenticated;

create or replace function app_private.economy_xp_required_for_level(p_level integer)
returns integer
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_offset integer := greatest(coalesce(p_level, 1), 1) - 1;
begin
  return 80 + (v_offset * 35)
    + round(18 * pg_catalog.power(v_offset::numeric, 1.65))::integer;
end;
$$;

create or replace function app_private.economy_xp_to_reach_level(p_level integer)
returns integer
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_level integer := greatest(coalesce(p_level, 1), 1);
  v_total integer := 0;
  v_current integer;
begin
  if v_level > 10000 then
    raise exception 'level exceeds supported economy range';
  end if;

  for v_current in 1..(v_level - 1) loop
    v_total := v_total + app_private.economy_xp_required_for_level(v_current);
  end loop;
  return v_total;
end;
$$;

create or replace function app_private.economy_level_progress(p_total_xp integer)
returns table (
  level integer,
  total_xp integer,
  current_level_xp integer,
  next_level_xp integer
)
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_total integer := greatest(coalesce(p_total_xp, 0), 0);
  v_level integer := 1;
  v_next integer;
begin
  if v_total > 2147480000 then
    raise exception 'total XP exceeds supported economy range';
  end if;

  loop
    v_next := app_private.economy_xp_to_reach_level(v_level + 1);
    exit when v_next > v_total;
    v_level := v_level + 1;
  end loop;

  level := v_level;
  total_xp := v_total;
  current_level_xp := v_total - app_private.economy_xp_to_reach_level(v_level);
  next_level_xp := app_private.economy_xp_required_for_level(v_level);
  return next;
end;
$$;

create or replace function app_private.economy_assert_client_version(p_version text)
returns void
language plpgsql
stable
set search_path = ''
as $$
declare
  v_min text;
  v_actual text := pg_catalog.btrim(coalesce(p_version, ''));
  v_min_parts integer[];
  v_actual_parts integer[];
  v_index integer;
begin
  if v_actual !~ '^\d+(\.\d+){0,3}$' then
    raise exception 'client version is required';
  end if;

  select minimum_android_version
    into v_min
  from public.economy_runtime_policy
  where policy_id = true and enabled = true;

  if not found then
    raise exception 'authoritative economy is disabled';
  end if;

  v_min_parts := regexp_split_to_array(v_min, '\.')::integer[];
  v_actual_parts := regexp_split_to_array(v_actual, '\.')::integer[];
  for v_index in 1..greatest(array_length(v_min_parts, 1), array_length(v_actual_parts, 1)) loop
    if coalesce(v_actual_parts[v_index], 0) < coalesce(v_min_parts[v_index], 0) then
      raise exception 'client version is not supported';
    elsif coalesce(v_actual_parts[v_index], 0) > coalesce(v_min_parts[v_index], 0) then
      return;
    end if;
  end loop;
end;
$$;

create or replace function app_private.refresh_authoritative_user_progress(p_user_id uuid)
returns public.user_progress
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_total_xp integer;
  v_progress record;
  v_coins bigint;
  v_earned bigint;
  v_spent bigint;
  v_result public.user_progress%rowtype;
begin
  if p_user_id is null then
    raise exception 'user_id is required';
  end if;

  select coalesce(sum(xp_delta), 0)::integer
    into v_total_xp
  from public.economy_xp_ledger
  where user_id = p_user_id;

  select coins into v_coins
  from public.user_wallets
  where user_id = p_user_id
  for update;
  if not found then
    raise exception 'wallet missing for user';
  end if;

  select
    coalesce(sum(delta) filter (where delta > 0), 0)::bigint,
    coalesce(abs(sum(delta) filter (where delta < 0)), 0)::bigint
    into v_earned, v_spent
  from (
    select coin_delta as delta
    from public.habit_currency_reward_ledger
    where user_id = p_user_id
    union all
    select coin_delta
    from public.achievement_level_reward_ledger
    where user_id = p_user_id
    union all
    select coins_delta
    from public.shop_ledger
    where user_id = p_user_id
    union all
    select coins_delta
    from public.shop_bundle_ledger
    where user_id = p_user_id
  ) deltas;

  select * into v_progress
  from app_private.economy_level_progress(v_total_xp);

  insert into public.user_progress (
    user_id, level, total_xp, current_level_xp, next_level_xp,
    ambar_balance, total_ambar_earned, total_ambar_spent, updated_at
  ) values (
    p_user_id, v_progress.level, v_progress.total_xp,
    v_progress.current_level_xp, v_progress.next_level_xp,
    greatest(v_coins, 0), greatest(v_earned, 0), greatest(v_spent, 0),
    pg_catalog.now()
  )
  on conflict (user_id) do update set
    level = excluded.level,
    total_xp = excluded.total_xp,
    current_level_xp = excluded.current_level_xp,
    next_level_xp = excluded.next_level_xp,
    ambar_balance = excluded.ambar_balance,
    total_ambar_earned = excluded.total_ambar_earned,
    total_ambar_spent = excluded.total_ambar_spent,
    updated_at = pg_catalog.now()
  returning * into v_result;

  return v_result;
end;
$$;

create or replace function public.complete_habit_economy_v1(
  p_request_id text,
  p_habit_id uuid,
  p_logical_date date,
  p_is_completed boolean,
  p_value integer default 0,
  p_note text default null,
  p_client_version text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_request_id text := pg_catalog.btrim(coalesce(p_request_id, ''));
  v_habit public.habits%rowtype;
  v_log public.habit_logs%rowtype;
  v_transition public.economy_habit_transition_ledger%rowtype;
  v_reward public.habit_currency_reward_ledger%rowtype;
  v_xp_ledger public.economy_xp_ledger%rowtype;
  v_event_id text;
  v_transition_no integer;
  v_reward_xp integer;
  v_logical_today date;
  v_max_backfill integer;
  v_timezone text;
begin
  if v_user_id is null then raise exception 'authentication required'; end if;
  if v_request_id = '' then raise exception 'request_id is required'; end if;
  if p_habit_id is null or p_logical_date is null or p_is_completed is null then
    raise exception 'habit and logical date are required';
  end if;
  perform app_private.economy_assert_client_version(p_client_version);

  select h.*
    into v_habit
  from public.habits h
  where h.id = p_habit_id and h.user_id = v_user_id and not h.is_archived
  for update;
  if not found then raise exception 'habit not found'; end if;

  select coalesce(pr.habit_time_zone, 'UTC') into v_timezone
  from public.profiles pr
  where pr.id = v_user_id;
  v_timezone := coalesce(v_timezone, 'UTC');

  select max_habit_backfill_days into v_max_backfill
  from public.economy_runtime_policy where policy_id = true and enabled = true;
  v_logical_today := (pg_catalog.now() at time zone v_timezone)::date;
  if p_logical_date > v_logical_today
     or p_logical_date < v_logical_today - v_max_backfill
     or p_logical_date < (v_habit.created_at at time zone v_timezone)::date then
    raise exception 'logical date is outside the allowed completion window';
  end if;
  if not app_private.is_habit_scheduled_on(v_habit.schedule, p_logical_date) then
    raise exception 'habit is not scheduled on this date';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtext(v_user_id::text || ':habit:' || p_habit_id::text || ':' || p_logical_date::text)
  );

  select * into v_transition
  from public.economy_habit_transition_ledger
  where request_id = v_request_id;
  if found then
    if v_transition.user_id <> v_user_id then
      raise exception 'request_id belongs to another user';
    end if;
    return jsonb_build_object(
      'request_id', v_transition.request_id,
      'is_completed', v_transition.is_completed,
      'transition_no', v_transition.transition_no,
      'idempotent', true,
      'progress', row_to_json(app_private.refresh_authoritative_user_progress(v_user_id))
    );
  end if;

  select * into v_log
  from public.habit_logs
  where user_id = v_user_id and habit_id = p_habit_id and log_date = p_logical_date
  for update;

  if found and v_log.is_completed = p_is_completed then
    raise exception 'requested habit state is already current';
  end if;
  if not p_is_completed and (not found or not v_log.is_completed) then
    raise exception 'cannot reverse an incomplete habit';
  end if;
  if p_is_completed and v_habit.habit_type = 'count'
     and (p_value < 1 or p_value > coalesce(v_habit.target_count, 0)) then
    raise exception 'count value is invalid';
  end if;

  select coalesce(max(transition_no), 0) + 1 into v_transition_no
  from public.economy_habit_transition_ledger
  where user_id = v_user_id and habit_id = p_habit_id and logical_date = p_logical_date;
  v_event_id := 'habit-cycle:' || v_user_id::text || ':' || p_habit_id::text
    || ':' || p_logical_date::text || ':' || v_transition_no::text;

  insert into public.habit_logs (
    user_id, habit_id, log_date, value, is_completed, note, source
  ) values (
    v_user_id, p_habit_id, p_logical_date, greatest(coalesce(p_value, 0), 0),
    p_is_completed, p_note, 'manual'
  )
  on conflict (user_id, habit_id, log_date) do update set
    value = excluded.value,
    is_completed = excluded.is_completed,
    note = excluded.note,
    source = excluded.source,
    updated_at = pg_catalog.now();

  if p_is_completed then
    v_reward := public.apply_habit_completion_reward(
      v_request_id || ':coins', p_habit_id, p_logical_date::text,
      v_event_id, 'apply'
    );
    v_reward_xp := coalesce(v_reward.base_xp, 0) + coalesce(v_reward.bonus_xp, 0);
  else
    v_reward := public.reverse_habit_completion_reward(
      v_request_id || ':coins', p_habit_id, p_logical_date::text,
      v_event_id, 'reverse'
    );
    v_reward_xp := -(coalesce(v_reward.base_xp, 0) + coalesce(v_reward.bonus_xp, 0));
  end if;

  insert into public.economy_xp_ledger (
    request_id, user_id, source_type, source_id, operation_type,
    xp_delta, related_ledger_id
  ) values (
    v_request_id || ':xp', v_user_id, 'habit_completion', v_event_id,
    case when p_is_completed then 'apply' else 'reverse' end,
    v_reward_xp, null
  ) returning * into v_xp_ledger;

  insert into public.economy_habit_transition_ledger (
    request_id, user_id, habit_id, logical_date, transition_no,
    is_completed, habit_family_id, habit_type, target_count, value,
    completion_event_id, reward_ledger_id, xp_ledger_id
  ) values (
    v_request_id, v_user_id, p_habit_id, p_logical_date, v_transition_no,
    p_is_completed, v_habit.family_id, v_habit.habit_type, v_habit.target_count,
    greatest(coalesce(p_value, 0), 0), v_event_id, v_reward.id, v_xp_ledger.id
  );

  return jsonb_build_object(
    'request_id', v_request_id,
    'is_completed', p_is_completed,
    'transition_no', v_transition_no,
    'idempotent', false,
    'progress', row_to_json(app_private.refresh_authoritative_user_progress(v_user_id))
  );
end;
$$;

-- The old function used user_progress.level as authority. Keep its public
-- signature for compatibility, but derive eligibility from the XP ledger.
create or replace function public.claim_level_reward(
  p_request_id text,
  p_level integer,
  p_operation_type text
)
returns public.achievement_level_reward_ledger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_request_id text := pg_catalog.btrim(coalesce(p_request_id, ''));
  v_level integer := coalesce(p_level, 0);
  v_existing public.achievement_level_reward_ledger%rowtype;
  v_wallet public.user_wallets%rowtype;
  v_reward_ambar bigint;
  v_balance_after bigint;
  v_total_xp integer;
  v_authoritative_level integer;
  v_ledger public.achievement_level_reward_ledger%rowtype;
begin
  if v_user_id is null then raise exception 'authentication required'; end if;
  if v_request_id = '' or v_level < 1 then raise exception 'request and level are required'; end if;
  if lower(btrim(coalesce(p_operation_type, ''))) <> 'claim' then
    raise exception 'operation_type must be claim';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext(v_user_id::text));
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext('level_reward_request:' || v_request_id));

  select * into v_existing from public.achievement_level_reward_ledger where request_id = v_request_id;
  if found then
    if v_existing.user_id <> v_user_id or v_existing.source_type <> 'level_reward'
       or v_existing.source_id <> v_level::text then
      raise exception 'request_id already used by another reward claim';
    end if;
    update public.achievement_level_reward_ledger set is_idempotent = true
    where id = v_existing.id and not is_idempotent;
    select * into v_existing from public.achievement_level_reward_ledger where id = v_existing.id;
    return v_existing;
  end if;

  select * into v_existing
  from public.achievement_level_reward_ledger
  where user_id = v_user_id and source_type = 'level_reward' and source_id = v_level::text;
  if found then
    update public.achievement_level_reward_ledger set is_idempotent = true
    where id = v_existing.id and not is_idempotent;
    return v_existing;
  end if;

  select coalesce(sum(xp_delta), 0)::integer into v_total_xp
  from public.economy_xp_ledger where user_id = v_user_id;
  select level into v_authoritative_level
  from app_private.economy_level_progress(v_total_xp);
  if v_authoritative_level < v_level then raise exception 'level not reached'; end if;

  v_reward_ambar := app_private.level_reward_ambar_for_level(v_level);
  if v_reward_ambar <= 0 then raise exception 'level reward not configured'; end if;

  select * into v_wallet from public.user_wallets where user_id = v_user_id for update;
  if not found then raise exception 'wallet missing for user'; end if;
  v_balance_after := v_wallet.coins + v_reward_ambar;
  if v_balance_after < 0 then raise exception 'wallet would go negative'; end if;

  update public.user_wallets set coins = v_balance_after, version = version + 1
  where user_id = v_user_id;
  insert into public.achievement_level_reward_ledger (
    request_id, user_id, operation_type, source_type, source_id,
    coin_delta, balance_after, related_ledger_id, is_idempotent
  ) values (
    v_request_id, v_user_id, 'claim', 'level_reward', v_level::text,
    v_reward_ambar, v_balance_after, null, false
  ) returning * into v_ledger;
  return v_ledger;
end;
$$;

create or replace function app_private.authoritative_achievement_tier(p_achievement_id text)
returns text
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_id text := pg_catalog.btrim(coalesce(p_achievement_id, ''));
  v_tier text;
begin
  if v_id like 'family_consistency:%:%' then
    v_tier := split_part(v_id, ':', 3);
    case v_tier
      when 'madera_vieja' then return 'oldwood';
      when 'madera' then return 'wood';
      when 'piedra' then return 'stone';
      when 'bronce' then return 'bronze';
      when 'plata' then return 'silver';
      when 'oro' then return 'gold';
      when 'diamante' then return 'diamond';
      when 'diamante_prismatico' then return 'prismaticdiamond';
    end case;
  end if;

  case v_id
    when 'special:madrugador', 'special:buho_nocturno' then return 'silver';
    when 'special:flash' then return 'bronze';
    when 'special:guerrero_del_finde' then return 'gold';
    when 'special:el_arquitecto' then return 'gold';
    when 'special:turista' then return 'silver';
    when 'special:polimota' then return 'gold';
    when 'special:hay_alguien_ahi' then return 'wood';
    when 'special:ave_fenix' then return 'gold';
    when 'special:perfeccionista' then return 'diamond';
    when 'special:el_centurion' then return 'diamond';
    when 'special:imparable' then return 'diamond';
    when 'special:coleccionista' then return 'diamond';
    when 'special:leyenda_viva' then return 'prismaticdiamond';
    when 'special:francotirados' then return 'silver';
    when 'special:plusmarquista' then return 'diamond';
    when 'special:reloj_suizo' then return 'gold';
    when 'special:veterano' then return 'diamond';
  end case;

  return null;
end;
$$;

create or replace function app_private.authoritative_achievement_unlocked(
  p_user_id uuid,
  p_achievement_id text
)
returns boolean
language plpgsql
stable
set search_path = ''
as $$
declare
  v_id text := pg_catalog.btrim(coalesce(p_achievement_id, ''));
  v_family text;
  v_tier text;
  v_target integer;
  v_count integer;
  v_unlocked boolean;
begin
  if p_user_id is null or v_id = '' then return false; end if;

  -- Only transitions written by the authoritative habit RPC count. The
  -- latest transition for each habit/date determines its canonical state.
  if v_id like 'family_consistency:%:%' then
    v_family := split_part(v_id, ':', 2);
    v_tier := split_part(v_id, ':', 3);
    v_target := case v_tier
      when 'madera_vieja' then 1
      when 'madera' then 7
      when 'piedra' then 15
      when 'bronce' then 30
      when 'plata' then 45
      when 'oro' then 60
      when 'diamante' then 90
      when 'diamante_prismatico' then 150
      else 0
    end;
    if v_target = 0 then return false; end if;
    select count(distinct logical_date)::integer into v_count
    from (
      select distinct on (habit_id, logical_date)
        habit_id, logical_date, is_completed, habit_family_id
      from public.economy_habit_transition_ledger
      where user_id = p_user_id
      order by habit_id, logical_date, transition_no desc, created_at desc
    ) latest
    where is_completed and habit_family_id = v_family;
    return v_count >= v_target;
  end if;

  if v_id = 'special:flash' then
    return exists (
      select 1 from (
        select logical_date
        from (
          select distinct on (habit_id, logical_date)
            habit_id, logical_date, is_completed
          from public.economy_habit_transition_ledger
          where user_id = p_user_id
          order by habit_id, logical_date, transition_no desc, created_at desc
        ) latest
        where is_completed
        group by logical_date
        having count(distinct habit_id) >= 8
      ) days
    );
  elsif v_id = 'special:guerrero_del_finde' then
    select count(distinct logical_date)::integer into v_count
    from (
      select distinct on (habit_id, logical_date)
        habit_id, logical_date, is_completed
      from public.economy_habit_transition_ledger
      where user_id = p_user_id
      order by habit_id, logical_date, transition_no desc, created_at desc
    ) latest
    where is_completed and extract(isodow from logical_date) in (6, 7);
    return v_count >= 30;
  elsif v_id in ('special:turista', 'special:polimota') then
    v_target := case when v_id = 'special:turista' then 6 else 7 end;
    select exists (
      select 1
      from (
        select distinct logical_date
        from public.economy_habit_transition_ledger
        where user_id = p_user_id
      ) starts
      where (
        select count(distinct x.habit_family_id)
        from (
          select distinct on (habit_id, logical_date)
            habit_id, logical_date, is_completed, habit_family_id
          from public.economy_habit_transition_ledger
          where user_id = p_user_id
          order by habit_id, logical_date, transition_no desc, created_at desc
        ) x
        where x.is_completed
          and x.logical_date between starts.logical_date
            and starts.logical_date + case when v_target = 6 then 6 else 20 end
          and x.habit_family_id is not null
      ) >= v_target
    ) into v_unlocked;
    return coalesce(v_unlocked, false);
  elsif v_id = 'special:hay_alguien_ahi' then
    select count(*)::integer into v_count
    from (
      select distinct on (habit_id, logical_date)
        habit_id, logical_date, is_completed, habit_family_id
      from public.economy_habit_transition_ledger
      where user_id = p_user_id
      order by habit_id, logical_date, transition_no desc, created_at desc
    ) latest
    where is_completed and habit_family_id = 'social';
    return v_count >= 15;
  elsif v_id = 'special:el_arquitecto' then
    select count(*)::integer into v_count
    from app_private.authoritative_habit_completion_events
    where user_id = p_user_id;
    return v_count >= 750;
  elsif v_id = 'special:leyenda_viva' then
    select count(*)::integer into v_count
    from (
      select distinct on (habit_id, logical_date)
        habit_id, logical_date, is_completed
      from public.economy_habit_transition_ledger
      where user_id = p_user_id
      order by habit_id, logical_date, transition_no desc, created_at desc
    ) latest
    where is_completed;
    return v_count >= 1500;
  elsif v_id = 'special:francotirados' then
    select count(*)::integer into v_count
    from (
      select distinct on (habit_id, logical_date)
        habit_id, logical_date, is_completed, value, target_count, habit_type
      from public.economy_habit_transition_ledger
      where user_id = p_user_id
      order by habit_id, logical_date, transition_no desc, created_at desc
    ) latest
    where is_completed and habit_type = 'count'
      and value = target_count;
    return v_count >= 100;
  elsif v_id = 'special:veterano' then
    select count(distinct logical_date)::integer into v_count
    from (
      select distinct on (habit_id, logical_date)
        habit_id, logical_date, is_completed
      from public.economy_habit_transition_ledger
      where user_id = p_user_id
      order by habit_id, logical_date, transition_no desc, created_at desc
    ) latest
    where is_completed;
    return v_count >= 240;
  elsif v_id = 'special:ave_fenix' then
    return exists (
      select 1
      from app_private.authoritative_habit_completion_events current_event
      where current_event.user_id = p_user_id
        and not exists (
          select 1
          from app_private.authoritative_habit_completion_events previous_event
          where previous_event.user_id = current_event.user_id
            and previous_event.habit_id = current_event.habit_id
            and previous_event.logical_date < current_event.logical_date
            and previous_event.logical_date >= current_event.logical_date - 2
        )
        and exists (
          select 1
          from app_private.authoritative_habit_completion_events older_event
          where older_event.user_id = current_event.user_id
            and older_event.habit_id = current_event.habit_id
            and older_event.logical_date < current_event.logical_date - 2
        )
    );
  elsif v_id = 'special:imparable' then
    return exists (
      select 1
      from (
        select logical_date,
          logical_date - row_number() over (order by logical_date)::integer as streak_group
        from (
          select distinct logical_date
          from app_private.authoritative_habit_completion_events
          where user_id = p_user_id
        ) days
      ) streaks
      group by streak_group
      having count(*) >= 30
    );
  elsif v_id = 'special:plusmarquista' then
    return exists (
      select 1
      from (
        select habit_id, logical_date,
          logical_date - row_number() over (
            partition by habit_id order by logical_date
          )::integer as streak_group
        from app_private.authoritative_habit_completion_events
        where user_id = p_user_id
      ) streaks
      group by habit_id, streak_group
      having count(*) >= 100
    );
  elsif v_id = 'special:coleccionista' then
    select count(distinct source_id)::integer into v_count
    from public.achievement_level_reward_ledger
    where user_id = p_user_id and source_type = 'achievement_reward';
    return v_count >= 40;
  end if;

  -- The remaining achievements require server-side event timestamps,
  -- historical schedule versions, or an authoritative achievement graph.
  return false;
end;
$$;

create or replace function app_private.achievement_reward_xp_for_tier(p_tier text)
returns integer
language plpgsql
immutable
set search_path = ''
as $$
begin
  case lower(pg_catalog.btrim(coalesce(p_tier, '')))
    when 'oldwood', 'wood' then return 50;
    when 'stone' then return 100;
    when 'bronze' then return 200;
    when 'silver' then return 400;
    when 'gold' then return 800;
    when 'diamond' then return 1600;
    when 'prismaticdiamond' then return 3500;
  end case;
  raise exception 'unsupported achievement tier %', p_tier;
end;
$$;

-- Eligibility is derived from authoritative habit transitions, never from a
-- user_achievements row supplied by Flutter.
create or replace function public.claim_achievement_reward(
  p_request_id text,
  p_achievement_id text,
  p_operation_type text
)
returns public.achievement_level_reward_ledger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_request_id text := pg_catalog.btrim(coalesce(p_request_id, ''));
  v_achievement_id text := pg_catalog.btrim(coalesce(p_achievement_id, ''));
  v_tier text;
  v_family_id text;
  v_reward_xp integer;
  v_reward_ambar bigint;
  v_wallet public.user_wallets%rowtype;
  v_existing public.achievement_level_reward_ledger%rowtype;
  v_ledger public.achievement_level_reward_ledger%rowtype;
  v_balance_after bigint;
begin
  if v_user_id is null then raise exception 'authentication required'; end if;
  if v_request_id = '' or v_achievement_id = '' then
    raise exception 'request and achievement are required';
  end if;
  if lower(pg_catalog.btrim(coalesce(p_operation_type, ''))) <> 'claim' then
    raise exception 'operation_type must be claim';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext(v_user_id::text));
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtext('achievement_reward_request:' || v_request_id)
  );

  select * into v_existing
  from public.achievement_level_reward_ledger
  where request_id = v_request_id;
  if found then
    if v_existing.user_id <> v_user_id
       or v_existing.source_type <> 'achievement_reward'
       or v_existing.source_id <> v_achievement_id then
      raise exception 'request_id already used by another reward claim';
    end if;
    update public.achievement_level_reward_ledger set is_idempotent = true
    where id = v_existing.id and not is_idempotent;
    return v_existing;
  end if;

  select * into v_existing
  from public.achievement_level_reward_ledger
  where user_id = v_user_id and source_type = 'achievement_reward'
    and source_id = v_achievement_id;
  if found then
    update public.achievement_level_reward_ledger set is_idempotent = true
    where id = v_existing.id and not is_idempotent;
    return v_existing;
  end if;

  if not app_private.authoritative_achievement_unlocked(v_user_id, v_achievement_id) then
    raise exception 'achievement is not authoritatively unlocked';
  end if;
  v_tier := app_private.authoritative_achievement_tier(v_achievement_id);
  if v_tier is null then raise exception 'achievement is not supported'; end if;
  v_reward_xp := app_private.achievement_reward_xp_for_tier(v_tier);
  v_reward_ambar := app_private.achievement_reward_ambar_for_tier(v_tier);
  v_family_id := case when v_achievement_id like 'family_consistency:%:%'
    then split_part(v_achievement_id, ':', 2) else 'special' end;

  select * into v_wallet from public.user_wallets
  where user_id = v_user_id for update;
  if not found then raise exception 'wallet missing for user'; end if;
  v_balance_after := v_wallet.coins + v_reward_ambar;

  update public.user_wallets
  set coins = v_balance_after, version = version + 1
  where user_id = v_user_id;

  insert into public.user_achievements (
    user_id, achievement_id, family_id, tier, unlocked_at,
    reward_xp, reward_ambar, reward_applied, updated_at
  ) values (
    v_user_id, v_achievement_id, v_family_id, v_tier, pg_catalog.now(),
    v_reward_xp, v_reward_ambar, true, pg_catalog.now()
  )
  on conflict (user_id, achievement_id) do update set
    family_id = excluded.family_id,
    tier = excluded.tier,
    reward_xp = excluded.reward_xp,
    reward_ambar = excluded.reward_ambar,
    reward_applied = true,
    updated_at = pg_catalog.now();

  insert into public.achievement_level_reward_ledger (
    request_id, user_id, operation_type, source_type, source_id,
    coin_delta, balance_after, related_ledger_id, is_idempotent
  ) values (
    v_request_id, v_user_id, 'claim', 'achievement_reward', v_achievement_id,
    v_reward_ambar, v_balance_after, null, false
  ) returning * into v_ledger;

  insert into public.economy_xp_ledger (
    request_id, user_id, source_type, source_id, operation_type, xp_delta
  ) values (
    v_request_id || ':xp', v_user_id, 'achievement_reward',
    v_achievement_id, 'claim', v_reward_xp
  );

  perform app_private.refresh_authoritative_user_progress(v_user_id);
  return v_ledger;
end;
$$;

revoke all on function public.complete_habit_economy_v1(text, uuid, date, boolean, integer, text, text)
from public, anon, authenticated;
grant execute on function public.complete_habit_economy_v1(text, uuid, date, boolean, integer, text, text)
to authenticated;

revoke all on function public.claim_level_reward(text, integer, text)
from public, anon;
grant execute on function public.claim_level_reward(text, integer, text)
to authenticated;

revoke all on function public.claim_achievement_reward(text, text, text)
from public, anon;
grant execute on function public.claim_achievement_reward(text, text, text)
to authenticated;

-- Achievement rows are server-owned. Authenticated clients retain SELECT via
-- the existing RLS policy, but cannot manufacture eligibility records.
revoke insert, update, delete on table public.user_achievements
from public, anon, authenticated;
grant select on table public.user_achievements to authenticated;

revoke all on function app_private.economy_xp_required_for_level(integer)
from public, anon, authenticated;
revoke all on function app_private.economy_xp_to_reach_level(integer)
from public, anon, authenticated;
revoke all on function app_private.economy_level_progress(integer)
from public, anon, authenticated;
revoke all on function app_private.economy_assert_client_version(text)
from public, anon, authenticated;
revoke all on function app_private.refresh_authoritative_user_progress(uuid)
from public, anon, authenticated;

alter function public.complete_habit_economy_v1(text, uuid, date, boolean, integer, text, text)
  owner to postgres;
alter function public.claim_level_reward(text, integer, text) owner to postgres;
alter function public.claim_achievement_reward(text, text, text) owner to postgres;

commit;
