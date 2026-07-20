begin;

create extension if not exists pgcrypto;
create schema if not exists app_private;

create table if not exists public.achievement_level_reward_ledger (
  id uuid primary key default gen_random_uuid(),
  request_id text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  operation_type text not null,
  source_type text not null,
  source_id text not null,
  coin_delta bigint not null,
  balance_after bigint not null,
  related_ledger_id uuid references public.achievement_level_reward_ledger(id) on delete set null,
  is_idempotent boolean not null default false,
  created_at timestamptz not null default now(),
  constraint achievement_level_reward_ledger_request_id_check check (btrim(request_id) <> ''),
  constraint achievement_level_reward_ledger_operation_type_check check (
    operation_type = 'claim'
  ),
  constraint achievement_level_reward_ledger_source_type_check check (
    source_type in ('achievement_reward', 'level_reward')
  ),
  constraint achievement_level_reward_ledger_source_id_check check (btrim(source_id) <> ''),
  constraint achievement_level_reward_ledger_balance_after_check check (balance_after >= 0),
  constraint achievement_level_reward_ledger_request_id_unique unique (request_id),
  constraint achievement_level_reward_ledger_operation_source_unique unique (
    user_id,
    operation_type,
    source_type,
    source_id
  )
);

create index if not exists idx_achievement_level_reward_ledger_user_created_at
  on public.achievement_level_reward_ledger (user_id, created_at desc);
create index if not exists idx_achievement_level_reward_ledger_user_request_id
  on public.achievement_level_reward_ledger (user_id, request_id);
create index if not exists idx_achievement_level_reward_ledger_user_source
  on public.achievement_level_reward_ledger (user_id, operation_type, source_type, source_id);

alter table public.achievement_level_reward_ledger enable row level security;

revoke all on public.achievement_level_reward_ledger from public, anon, authenticated;

drop policy if exists achievement_level_reward_ledger_select_own
  on public.achievement_level_reward_ledger;
create policy achievement_level_reward_ledger_select_own
  on public.achievement_level_reward_ledger
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create or replace function app_private.achievement_reward_ambar_for_tier(
  p_tier text
)
returns integer
language plpgsql
stable
set search_path = ''
as $$
declare
  v_tier text := lower(btrim(coalesce(p_tier, '')));
begin
  case v_tier
    when 'oldwood' then return 25;
    when 'wood' then return 25;
    when 'stone' then return 50;
    when 'bronze' then return 100;
    when 'silver' then return 200;
    when 'gold' then return 400;
    when 'diamond' then return 750;
    when 'prismaticdiamond' then return 1500;
  end case;

  raise exception 'unsupported achievement tier %', p_tier;
end;
$$;

create or replace function app_private.level_reward_ambar_for_level(
  p_level integer
)
returns integer
language plpgsql
stable
set search_path = ''
as $$
begin
  if p_level <= 1 then
    return 0;
  elsif p_level = 5 then
    return 50;
  elsif p_level = 10 then
    return 150;
  elsif p_level = 20 then
    return 300;
  elsif p_level = 30 then
    return 500;
  elsif p_level = 40 then
    return 750;
  elsif p_level = 50 then
    return 1000;
  elsif p_level > 50 and p_level % 10 = 0 then
    return p_level * 20;
  end if;

  return 0;
end;
$$;

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
  v_request_id text := btrim(coalesce(p_request_id, ''));
  v_achievement_id text := btrim(coalesce(p_achievement_id, ''));
  v_operation_type text := lower(btrim(coalesce(p_operation_type, '')));
  v_existing public.achievement_level_reward_ledger%rowtype;
  v_achievement public.user_achievements%rowtype;
  v_wallet public.user_wallets%rowtype;
  v_reward_ambar bigint;
  v_balance_after bigint;
  v_ledger public.achievement_level_reward_ledger%rowtype;
begin
  if v_request_id = '' then
    raise exception 'request_id is required';
  end if;
  if v_achievement_id = '' then
    raise exception 'achievement_id is required';
  end if;
  if v_operation_type <> 'claim' then
    raise exception 'operation_type must be claim';
  end if;
  if v_user_id is null then
    raise exception 'authentication required';
  end if;

  perform pg_advisory_xact_lock(hashtext(v_user_id::text));
  perform pg_advisory_xact_lock(hashtext('achievement_reward_request:' || v_request_id));
  perform pg_advisory_xact_lock(
    hashtext(
      'achievement_reward_source:' ||
      v_user_id::text ||
      ':' ||
      v_operation_type ||
      ':' ||
      v_achievement_id
    )
  );

  select *
    into v_existing
  from public.achievement_level_reward_ledger
  where request_id = v_request_id;

  if found then
    if v_existing.user_id <> v_user_id
       or v_existing.operation_type <> 'claim'
       or v_existing.source_type <> 'achievement_reward'
       or v_existing.source_id <> v_achievement_id then
      raise exception 'request_id already used by another reward claim';
    end if;

    update public.achievement_level_reward_ledger
       set is_idempotent = true
     where id = v_existing.id
       and is_idempotent = false;

    select *
      into v_existing
    from public.achievement_level_reward_ledger
    where id = v_existing.id;
    return v_existing;
  end if;

  select *
    into v_existing
  from public.achievement_level_reward_ledger
  where user_id = v_user_id
    and operation_type = 'claim'
    and source_type = 'achievement_reward'
    and source_id = v_achievement_id;

  if found then
    update public.achievement_level_reward_ledger
       set is_idempotent = true
     where id = v_existing.id
       and is_idempotent = false;

    select *
      into v_existing
    from public.achievement_level_reward_ledger
    where id = v_existing.id;
    return v_existing;
  end if;

  select *
    into v_achievement
  from public.user_achievements
  where user_id = v_user_id
    and achievement_id = v_achievement_id
  for update;

  if not found then
    raise exception 'achievement not found or not eligible';
  end if;

  if v_achievement.reward_applied = true then
    raise exception 'achievement reward already claimed';
  end if;

  v_reward_ambar := app_private.achievement_reward_ambar_for_tier(v_achievement.tier);

  select *
    into v_wallet
  from public.user_wallets
  where user_id = v_user_id
  for update;

  if not found then
    raise exception 'wallet missing for user';
  end if;

  v_balance_after := v_wallet.coins + v_reward_ambar;
  if v_balance_after < 0 then
    raise exception 'wallet would go negative';
  end if;

  update public.user_wallets
     set coins = v_balance_after,
         version = version + 1
   where user_id = v_user_id;

  update public.user_achievements
     set reward_applied = true,
         reward_ambar = v_reward_ambar,
         updated_at = now()
   where user_id = v_user_id
     and achievement_id = v_achievement_id;

  insert into public.achievement_level_reward_ledger (
    request_id,
    user_id,
    operation_type,
    source_type,
    source_id,
    coin_delta,
    balance_after,
    related_ledger_id,
    is_idempotent,
    created_at
  ) values (
    v_request_id,
    v_user_id,
    'claim',
    'achievement_reward',
    v_achievement_id,
    v_reward_ambar,
    v_balance_after,
    null,
    false,
    now()
  )
  returning * into v_ledger;

  return v_ledger;
end;
$$;

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
  v_request_id text := btrim(coalesce(p_request_id, ''));
  v_level integer := coalesce(p_level, 0);
  v_operation_type text := lower(btrim(coalesce(p_operation_type, '')));
  v_existing public.achievement_level_reward_ledger%rowtype;
  v_progress public.user_progress%rowtype;
  v_wallet public.user_wallets%rowtype;
  v_reward_ambar bigint;
  v_balance_after bigint;
  v_ledger public.achievement_level_reward_ledger%rowtype;
begin
  if v_request_id = '' then
    raise exception 'request_id is required';
  end if;
  if v_level is null or v_level < 1 then
    raise exception 'level is required';
  end if;
  if v_operation_type <> 'claim' then
    raise exception 'operation_type must be claim';
  end if;
  if v_user_id is null then
    raise exception 'authentication required';
  end if;

  perform pg_advisory_xact_lock(hashtext(v_user_id::text));
  perform pg_advisory_xact_lock(hashtext('level_reward_request:' || v_request_id));
  perform pg_advisory_xact_lock(
    hashtext(
      'level_reward_source:' ||
      v_user_id::text ||
      ':' ||
      v_operation_type ||
      ':' ||
      v_level::text
    )
  );

  select *
    into v_existing
  from public.achievement_level_reward_ledger
  where request_id = v_request_id;

  if found then
    if v_existing.user_id <> v_user_id
       or v_existing.operation_type <> 'claim'
       or v_existing.source_type <> 'level_reward'
       or v_existing.source_id <> v_level::text then
      raise exception 'request_id already used by another reward claim';
    end if;

    update public.achievement_level_reward_ledger
       set is_idempotent = true
     where id = v_existing.id
       and is_idempotent = false;

    select *
      into v_existing
    from public.achievement_level_reward_ledger
    where id = v_existing.id;
    return v_existing;
  end if;

  select *
    into v_existing
  from public.achievement_level_reward_ledger
  where user_id = v_user_id
    and operation_type = 'claim'
    and source_type = 'level_reward'
    and source_id = v_level::text;

  if found then
    update public.achievement_level_reward_ledger
       set is_idempotent = true
     where id = v_existing.id
       and is_idempotent = false;

    select *
      into v_existing
    from public.achievement_level_reward_ledger
    where id = v_existing.id;
    return v_existing;
  end if;

  select *
    into v_progress
  from public.user_progress
  where user_id = v_user_id
  for update;

  if not found then
    raise exception 'progress row missing for user';
  end if;

  if v_progress.level < v_level then
    raise exception 'level not reached';
  end if;

  v_reward_ambar := app_private.level_reward_ambar_for_level(v_level);
  if v_reward_ambar <= 0 then
    raise exception 'level reward not configured';
  end if;

  select *
    into v_wallet
  from public.user_wallets
  where user_id = v_user_id
  for update;

  if not found then
    raise exception 'wallet missing for user';
  end if;

  v_balance_after := v_wallet.coins + v_reward_ambar;
  if v_balance_after < 0 then
    raise exception 'wallet would go negative';
  end if;

  update public.user_wallets
     set coins = v_balance_after,
         version = version + 1
   where user_id = v_user_id;

  insert into public.achievement_level_reward_ledger (
    request_id,
    user_id,
    operation_type,
    source_type,
    source_id,
    coin_delta,
    balance_after,
    related_ledger_id,
    is_idempotent,
    created_at
  ) values (
    v_request_id,
    v_user_id,
    'claim',
    'level_reward',
    v_level::text,
    v_reward_ambar,
    v_balance_after,
    null,
    false,
    now()
  )
  returning * into v_ledger;

  return v_ledger;
end;
$$;

grant execute on function public.claim_achievement_reward(
  text,
  text,
  text
) to authenticated;

grant execute on function public.claim_level_reward(
  text,
  integer,
  text
) to authenticated;

commit;
