begin;

create extension if not exists pgcrypto;

alter table if exists public.habit_currency_reward_ledger
  add column if not exists base_xp integer not null default 0,
  add column if not exists bonus_xp integer not null default 0,
  add column if not exists bonus_coins bigint not null default 0,
  add column if not exists applied_effect_ids uuid[] not null default '{}'::uuid[];

do $$
begin
  if not exists (
    select 1
      from pg_constraint
     where conname = 'habit_currency_reward_ledger_base_xp_check'
       and conrelid = 'public.habit_currency_reward_ledger'::regclass
  ) then
    alter table public.habit_currency_reward_ledger
      add constraint habit_currency_reward_ledger_base_xp_check
      check (base_xp >= 0);
  end if;

  if not exists (
    select 1
      from pg_constraint
     where conname = 'habit_currency_reward_ledger_bonus_xp_check'
       and conrelid = 'public.habit_currency_reward_ledger'::regclass
  ) then
    alter table public.habit_currency_reward_ledger
      add constraint habit_currency_reward_ledger_bonus_xp_check
      check (bonus_xp >= 0);
  end if;

  if not exists (
    select 1
      from pg_constraint
     where conname = 'habit_currency_reward_ledger_bonus_coins_check'
       and conrelid = 'public.habit_currency_reward_ledger'::regclass
  ) then
    alter table public.habit_currency_reward_ledger
      add constraint habit_currency_reward_ledger_bonus_coins_check
      check (bonus_coins >= 0);
  end if;
end;
$$;

create index if not exists idx_habit_currency_reward_ledger_user_operation_source
  on public.habit_currency_reward_ledger (user_id, operation_type, source_type, source_id);
create index if not exists idx_habit_currency_reward_ledger_user_habit_operation
  on public.habit_currency_reward_ledger (user_id, habit_id, operation_type, created_at desc);

alter table public.habit_currency_reward_ledger enable row level security;

revoke all on public.habit_currency_reward_ledger from public, anon, authenticated;
drop policy if exists habit_currency_reward_ledger_select_own on public.habit_currency_reward_ledger;
create policy habit_currency_reward_ledger_select_own
  on public.habit_currency_reward_ledger
  for select
  to authenticated
  using ((select auth.uid()) = user_id);
grant select on public.habit_currency_reward_ledger to authenticated;

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
set search_path = public
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
  v_xp_effect public.user_utility_effects%rowtype;
  v_coin_effect public.user_utility_effects%rowtype;
  v_xp_source_id text;
  v_coin_source_id text;
  v_xp_request_id text;
  v_coin_request_id text;
  v_applied_effect_ids uuid[] := '{}'::uuid[];
  v_base_xp integer := 0;
  v_bonus_xp integer := 0;
  v_base_coins integer := 0;
  v_bonus_coins bigint := 0;
  v_coin_delta bigint := 0;
  v_balance_after bigint;
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
    and user_id = v_user_id
  for update;

  if not found then
    raise exception 'habit not found';
  end if;

  select *
    into v_wallet
  from public.user_wallets
  where user_id = v_user_id
  for update;

  if not found then
    raise exception 'wallet missing for user';
  end if;

  select *
    into v_reward
  from app_private.habit_completion_base_reward(v_habit.habit_type, v_habit.target_count);

  v_base_xp := coalesce(v_reward.base_xp, 0);
  v_base_coins := coalesce(v_reward.base_coins, 0);

  select *
    into v_xp_effect
  from public.user_utility_effects
  where user_id = v_user_id
    and utility_id = 'utility_xp_boost_1d'
    and status = 'active'
    and remaining_uses > 0
  order by activated_at desc, id desc
  limit 1
  for update;

  if found and v_base_xp > 0 then
    v_bonus_xp := round(v_base_xp::numeric * 0.5)::integer;
    v_xp_source_id := v_completion_event_id || ':utility_xp_boost_1d';
    v_xp_request_id := v_request_id || ':utility_xp_boost_1d';
    v_applied_effect_ids := array_append(v_applied_effect_ids, v_xp_effect.id);

    update public.user_utility_effects
       set remaining_uses = v_xp_effect.remaining_uses - 1,
           status = case
             when (v_xp_effect.remaining_uses - 1) = 0 then 'completed'
             else 'active'
           end,
           completed_at = case
             when (v_xp_effect.remaining_uses - 1) = 0 then now()
             else completed_at
           end,
           updated_at = now()
     where id = v_xp_effect.id;

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
      v_xp_request_id,
      v_xp_effect.utility_id,
      v_xp_effect.utility_type,
      'consume',
      'habit_completion',
      v_xp_source_id,
      v_xp_effect.id,
      v_habit_id,
      null,
      v_xp_effect.remaining_uses,
      v_xp_effect.remaining_uses - 1,
      v_xp_effect.total_uses,
      v_xp_effect.total_uses,
      null,
      false,
      now()
    );
  end if;

  select *
    into v_coin_effect
  from public.user_utility_effects
  where user_id = v_user_id
    and utility_id = 'utility_coin_boost_1d'
    and status = 'active'
    and remaining_uses > 0
  order by activated_at desc, id desc
  limit 1
  for update;

  if found and v_base_coins > 0 then
    v_bonus_coins := ceil(v_base_coins::numeric * 0.5)::bigint;
    v_coin_source_id := v_completion_event_id || ':utility_coin_boost_1d';
    v_coin_request_id := v_request_id || ':utility_coin_boost_1d';
    v_applied_effect_ids := array_append(v_applied_effect_ids, v_coin_effect.id);

    update public.user_utility_effects
       set remaining_uses = v_coin_effect.remaining_uses - 1,
           status = case
             when (v_coin_effect.remaining_uses - 1) = 0 then 'completed'
             else 'active'
           end,
           completed_at = case
             when (v_coin_effect.remaining_uses - 1) = 0 then now()
             else completed_at
           end,
           updated_at = now()
     where id = v_coin_effect.id;

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
      v_coin_request_id,
      v_coin_effect.utility_id,
      v_coin_effect.utility_type,
      'consume',
      'habit_completion',
      v_coin_source_id,
      v_coin_effect.id,
      v_habit_id,
      null,
      v_coin_effect.remaining_uses,
      v_coin_effect.remaining_uses - 1,
      v_coin_effect.total_uses,
      v_coin_effect.total_uses,
      null,
      false,
      now()
    );
  end if;

  v_coin_delta := v_base_coins::bigint + v_bonus_coins;
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
    created_at,
    base_xp,
    bonus_xp,
    bonus_coins,
    applied_effect_ids
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
    now(),
    v_base_xp,
    v_bonus_xp,
    v_bonus_coins,
    coalesce(v_applied_effect_ids, '{}'::uuid[])
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
set search_path = public
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
  v_habit public.habits%rowtype;
  v_wallet public.user_wallets%rowtype;
  v_effect public.user_utility_effects%rowtype;
  v_effect_id uuid;
  v_restore_source_id text;
  v_restore_request_id text;
  v_related_ledger_id uuid;
  v_remaining_before integer;
  v_remaining_after integer;
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
    into v_habit
  from public.habits
  where id = v_habit_id
    and user_id = v_user_id
  for update;

  if not found then
    raise exception 'habit not found';
  end if;

  select *
    into v_wallet
  from public.user_wallets
  where user_id = v_user_id
  for update;

  if not found then
    raise exception 'wallet missing for user';
  end if;

  v_coin_delta := -coalesce(v_apply_ledger.coin_delta, 0);
  v_balance_after := v_wallet.coins + v_coin_delta;
  if v_balance_after < 0 then
    raise exception 'wallet would go negative on reverse';
  end if;

  update public.user_wallets
     set coins = v_balance_after,
         version = version + 1
   where user_id = v_user_id;

  foreach v_effect_id in array coalesce(v_apply_ledger.applied_effect_ids, '{}'::uuid[]) loop
    select *
      into v_effect
    from public.user_utility_effects
    where id = v_effect_id
      and user_id = v_user_id
    for update;

    if not found then
      raise exception 'utility effect not found';
    end if;

    if v_effect.utility_id not in ('utility_xp_boost_1d', 'utility_coin_boost_1d') then
      raise exception 'utility effect cannot be restored';
    end if;

    v_remaining_before := v_effect.remaining_uses;
    v_remaining_after := least(v_effect.total_uses, v_remaining_before + 1);
    v_restore_source_id := v_completion_event_id || ':' || v_effect.utility_id;
    v_restore_request_id := v_request_id || ':' || v_effect.utility_id;
    v_related_ledger_id := null;

    update public.user_utility_effects
       set remaining_uses = v_remaining_after,
           status = case
             when v_remaining_after = 0 then 'completed'
             else 'active'
           end,
           completed_at = case
             when v_remaining_after = 0 then coalesce(v_effect.completed_at, now())
             else null
           end,
           updated_at = now()
     where id = v_effect.id;

    select id
      into v_related_ledger_id
    from public.utility_consumption_ledger
    where user_id = v_user_id
      and operation_type = 'consume'
      and source_type = 'habit_completion'
      and source_id = v_restore_source_id
      and utility_id = v_effect.utility_id
    order by created_at desc
    limit 1;

    if not found then
      v_related_ledger_id := null;
    end if;

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
      v_restore_request_id,
      v_effect.utility_id,
      v_effect.utility_type,
      'recover',
      'habit_completion',
      v_restore_source_id,
      v_effect.id,
      coalesce(v_effect.habit_id, v_apply_ledger.habit_id),
      null,
      v_remaining_before,
      v_remaining_after,
      v_effect.total_uses,
      v_effect.total_uses,
      v_related_ledger_id,
      false,
      now()
    );
  end loop;

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
    created_at,
    base_xp,
    bonus_xp,
    bonus_coins,
    applied_effect_ids
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
    now(),
    coalesce(v_apply_ledger.base_xp, 0),
    coalesce(v_apply_ledger.bonus_xp, 0),
    coalesce(v_apply_ledger.bonus_coins, 0),
    coalesce(v_apply_ledger.applied_effect_ids, '{}'::uuid[])
  )
  returning * into v_ledger;

  return v_ledger;
end;
$$;

revoke all on function public.apply_habit_completion_reward(
  text,
  uuid,
  text,
  text,
  text
) from public, anon, authenticated;

revoke all on function public.reverse_habit_completion_reward(
  text,
  uuid,
  text,
  text,
  text
) from public, anon, authenticated;

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
