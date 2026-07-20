begin;

create extension if not exists pgcrypto;

create or replace function app_private.habit_completion_base_reward(
  p_habit_type text,
  p_target_count integer
)
returns table (
  base_xp integer,
  base_coins integer
)
language plpgsql
stable
set search_path = ''
as $$
declare
  v_habit_type text := lower(btrim(coalesce(p_habit_type, '')));
  v_target_count integer := coalesce(p_target_count, 0);
  v_xp integer;
begin
  if v_habit_type = 'check' then
    base_xp := 10;
    base_coins := 5;
    return next;
  elsif v_habit_type = 'count' then
    if v_target_count <= 0 then
      raise exception 'count habit target is required';
    end if;

    v_xp := greatest(
      5,
      least(15, ((ceiling(v_target_count::numeric / 5.0) * 2) + 5)::integer)
    );
    base_xp := v_xp;
    base_coins := greatest(0, least(10, floor(v_xp::numeric / 2.0)::integer));
    return next;
  end if;

  raise exception 'unsupported habit type %', p_habit_type;
end;
$$;

create table if not exists public.habit_currency_reward_ledger (
  id uuid primary key default gen_random_uuid(),
  request_id text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  operation_type text not null,
  source_type text not null,
  source_id text not null,
  habit_id uuid not null references public.habits(id) on delete cascade,
  logical_date_key text not null,
  completion_event_id text not null,
  coin_delta bigint not null,
  balance_after bigint not null,
  related_ledger_id uuid references public.habit_currency_reward_ledger(id) on delete set null,
  is_idempotent boolean not null default false,
  created_at timestamptz not null default now(),
  constraint habit_currency_reward_ledger_request_id_check check (btrim(request_id) <> ''),
  constraint habit_currency_reward_ledger_operation_type_check check (
    operation_type in ('apply', 'reverse')
  ),
  constraint habit_currency_reward_ledger_source_type_check check (
    source_type = 'habit_completion'
  ),
  constraint habit_currency_reward_ledger_source_id_check check (btrim(source_id) <> ''),
  constraint habit_currency_reward_ledger_logical_date_key_check check (btrim(logical_date_key) <> ''),
  constraint habit_currency_reward_ledger_completion_event_id_check check (
    btrim(completion_event_id) <> ''
  ),
  constraint habit_currency_reward_ledger_balance_after_check check (balance_after >= 0),
  constraint habit_currency_reward_ledger_request_id_unique unique (request_id),
  constraint habit_currency_reward_ledger_operation_source_unique unique (
    user_id,
    operation_type,
    source_type,
    source_id
  )
);

create index if not exists idx_habit_currency_reward_ledger_user_created_at
  on public.habit_currency_reward_ledger (user_id, created_at desc);
create index if not exists idx_habit_currency_reward_ledger_user_request_id
  on public.habit_currency_reward_ledger (user_id, request_id);
create index if not exists idx_habit_currency_reward_ledger_user_source
  on public.habit_currency_reward_ledger (user_id, operation_type, source_type, source_id);
create index if not exists idx_habit_currency_reward_ledger_user_habit_date
  on public.habit_currency_reward_ledger (user_id, habit_id, logical_date_key);

alter table public.habit_currency_reward_ledger enable row level security;

revoke all on public.habit_currency_reward_ledger from public, anon, authenticated;

drop policy if exists habit_currency_reward_ledger_select_own on public.habit_currency_reward_ledger;
create policy habit_currency_reward_ledger_select_own
  on public.habit_currency_reward_ledger
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create or replace function public.apply_habit_completion_reward(
  p_request_id text,
  p_habit_id uuid,
  p_logical_date text,
  p_completion_event_id text,
  p_operation_type text
)
returns public.habit_currency_reward_ledger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_request_id text := btrim(coalesce(p_request_id, ''));
  v_habit_id uuid := p_habit_id;
  v_logical_date_key text := btrim(coalesce(p_logical_date, ''));
  v_completion_event_id text := btrim(coalesce(p_completion_event_id, ''));
  v_operation_type text := lower(btrim(coalesce(p_operation_type, '')));
  v_existing public.habit_currency_reward_ledger%rowtype;
  v_habit public.habits%rowtype;
  v_reward record;
  v_wallet public.user_wallets%rowtype;
  v_balance_after bigint;
  v_coin_delta bigint;
  v_ledger public.habit_currency_reward_ledger%rowtype;
begin
  if v_request_id = '' then
    raise exception 'request_id is required';
  end if;
  if v_habit_id is null then
    raise exception 'habit_id is required';
  end if;
  if v_logical_date_key = '' then
    raise exception 'logical_date is required';
  end if;
  if v_completion_event_id = '' then
    raise exception 'completion_event_id is required';
  end if;
  if v_operation_type <> 'apply' then
    raise exception 'operation_type must be apply';
  end if;
  if v_user_id is null then
    raise exception 'authentication required';
  end if;

  perform pg_advisory_xact_lock(hashtext(v_user_id::text));
  perform pg_advisory_xact_lock(hashtext('habit_currency_reward_request:' || v_request_id));
  perform pg_advisory_xact_lock(
    hashtext(
      'habit_currency_reward_source:' ||
      v_user_id::text ||
      ':' ||
      v_operation_type ||
      ':' ||
      v_completion_event_id
    )
  );

  begin
    perform v_logical_date_key::date;
  exception
    when others then
      raise exception 'logical_date must be an ISO date';
  end;

  select *
    into v_existing
  from public.habit_currency_reward_ledger
  where request_id = v_request_id;

  if found then
    if v_existing.user_id <> v_user_id
       or v_existing.operation_type <> 'apply'
       or v_existing.source_type <> 'habit_completion'
       or v_existing.source_id <> v_completion_event_id then
      raise exception 'request_id already used by another habit reward';
    end if;

    update public.habit_currency_reward_ledger
       set is_idempotent = true
     where id = v_existing.id
       and is_idempotent = false;

    select *
      into v_existing
    from public.habit_currency_reward_ledger
    where id = v_existing.id;
    return v_existing;
  end if;

  select *
    into v_existing
  from public.habit_currency_reward_ledger
  where user_id = v_user_id
    and operation_type = 'apply'
    and source_type = 'habit_completion'
    and source_id = v_completion_event_id;

  if found then
    update public.habit_currency_reward_ledger
       set is_idempotent = true
     where id = v_existing.id
       and is_idempotent = false;

    select *
      into v_existing
    from public.habit_currency_reward_ledger
    where id = v_existing.id;
    return v_existing;
  end if;

  select *
    into v_habit
  from public.habits
  where id = v_habit_id
    and user_id = v_user_id;

  if not found then
    raise exception 'habit not found';
  end if;

  select *
    into v_reward
  from app_private.habit_completion_base_reward(v_habit.habit_type, v_habit.target_count);

  v_coin_delta := v_reward.base_coins::bigint;

  select *
    into v_wallet
  from public.user_wallets
  where user_id = v_user_id
  for update;

  if not found then
    raise exception 'wallet missing for user';
  end if;

  v_balance_after := v_wallet.coins + v_coin_delta;
  if v_balance_after < 0 then
    raise exception 'wallet would go negative';
  end if;

  update public.user_wallets
     set coins = v_balance_after,
         version = version + 1
   where user_id = v_user_id;

  insert into public.habit_currency_reward_ledger (
    request_id,
    user_id,
    operation_type,
    source_type,
    source_id,
    habit_id,
    logical_date_key,
    completion_event_id,
    coin_delta,
    balance_after,
    related_ledger_id,
    is_idempotent,
    created_at
  ) values (
    v_request_id,
    v_user_id,
    'apply',
    'habit_completion',
    v_completion_event_id,
    v_habit_id,
    v_logical_date_key,
    v_completion_event_id,
    v_coin_delta,
    v_balance_after,
    null,
    false,
    now()
  )
  returning * into v_ledger;

  return v_ledger;
end;
$$;

create or replace function public.reverse_habit_completion_reward(
  p_request_id text,
  p_habit_id uuid,
  p_logical_date text,
  p_completion_event_id text,
  p_operation_type text
)
returns public.habit_currency_reward_ledger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_request_id text := btrim(coalesce(p_request_id, ''));
  v_habit_id uuid := p_habit_id;
  v_logical_date_key text := btrim(coalesce(p_logical_date, ''));
  v_completion_event_id text := btrim(coalesce(p_completion_event_id, ''));
  v_operation_type text := lower(btrim(coalesce(p_operation_type, '')));
  v_existing public.habit_currency_reward_ledger%rowtype;
  v_apply_ledger public.habit_currency_reward_ledger%rowtype;
  v_wallet public.user_wallets%rowtype;
  v_balance_after bigint;
  v_coin_delta bigint;
  v_ledger public.habit_currency_reward_ledger%rowtype;
begin
  if v_request_id = '' then
    raise exception 'request_id is required';
  end if;
  if v_habit_id is null then
    raise exception 'habit_id is required';
  end if;
  if v_logical_date_key = '' then
    raise exception 'logical_date is required';
  end if;
  if v_completion_event_id = '' then
    raise exception 'completion_event_id is required';
  end if;
  if v_operation_type <> 'reverse' then
    raise exception 'operation_type must be reverse';
  end if;
  if v_user_id is null then
    raise exception 'authentication required';
  end if;

  perform pg_advisory_xact_lock(hashtext(v_user_id::text));
  perform pg_advisory_xact_lock(hashtext('habit_currency_reward_request:' || v_request_id));
  perform pg_advisory_xact_lock(
    hashtext(
      'habit_currency_reward_source:' ||
      v_user_id::text ||
      ':' ||
      v_operation_type ||
      ':' ||
      v_completion_event_id
    )
  );

  begin
    perform v_logical_date_key::date;
  exception
    when others then
      raise exception 'logical_date must be an ISO date';
  end;

  select *
    into v_existing
  from public.habit_currency_reward_ledger
  where request_id = v_request_id;

  if found then
    if v_existing.user_id <> v_user_id
       or v_existing.operation_type <> 'reverse'
       or v_existing.source_type <> 'habit_completion'
       or v_existing.source_id <> v_completion_event_id then
      raise exception 'request_id already used by another habit reward';
    end if;

    update public.habit_currency_reward_ledger
       set is_idempotent = true
     where id = v_existing.id
       and is_idempotent = false;

    select *
      into v_existing
    from public.habit_currency_reward_ledger
    where id = v_existing.id;
    return v_existing;
  end if;

  select *
    into v_existing
  from public.habit_currency_reward_ledger
  where user_id = v_user_id
    and operation_type = 'reverse'
    and source_type = 'habit_completion'
    and source_id = v_completion_event_id;

  if found then
    update public.habit_currency_reward_ledger
       set is_idempotent = true
     where id = v_existing.id
       and is_idempotent = false;

    select *
      into v_existing
    from public.habit_currency_reward_ledger
    where id = v_existing.id;
    return v_existing;
  end if;

  select *
    into v_apply_ledger
  from public.habit_currency_reward_ledger
  where user_id = v_user_id
    and operation_type = 'apply'
    and source_type = 'habit_completion'
    and source_id = v_completion_event_id;

  if not found then
    raise exception 'original habit completion not found';
  end if;

  select *
    into v_wallet
  from public.user_wallets
  where user_id = v_user_id
  for update;

  if not found then
    raise exception 'wallet missing for user';
  end if;

  v_coin_delta := -v_apply_ledger.coin_delta;
  v_balance_after := v_wallet.coins + v_coin_delta;
  if v_balance_after < 0 then
    raise exception 'wallet would go negative on reverse';
  end if;

  update public.user_wallets
     set coins = v_balance_after,
         version = version + 1
   where user_id = v_user_id;

  insert into public.habit_currency_reward_ledger (
    request_id,
    user_id,
    operation_type,
    source_type,
    source_id,
    habit_id,
    logical_date_key,
    completion_event_id,
    coin_delta,
    balance_after,
    related_ledger_id,
    is_idempotent,
    created_at
  ) values (
    v_request_id,
    v_user_id,
    'reverse',
    'habit_completion',
    v_completion_event_id,
    v_habit_id,
    v_logical_date_key,
    v_completion_event_id,
    v_coin_delta,
    v_balance_after,
    v_apply_ledger.id,
    false,
    now()
  )
  returning * into v_ledger;

  return v_ledger;
end;
$$;

grant execute on function public.apply_habit_completion_reward(
  text,
  uuid,
  text,
  text,
  text
) to authenticated;

grant execute on function public.reverse_habit_completion_reward(
  text,
  uuid,
  text,
  text,
  text
) to authenticated;

commit;
