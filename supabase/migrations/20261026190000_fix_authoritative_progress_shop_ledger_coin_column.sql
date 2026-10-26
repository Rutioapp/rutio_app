begin;

do $$
begin
  if to_regprocedure(
    'app_private.refresh_authoritative_user_progress(uuid)'
  ) is null then
    raise exception
      'Expected function app_private.refresh_authoritative_user_progress(uuid) is missing';
  end if;

  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'shop_ledger'
      and column_name = 'coin_delta'
  ) then
    raise exception
      'Expected public.shop_ledger.coin_delta column is missing';
  end if;

  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'shop_bundle_ledger'
      and column_name = 'coins_delta'
  ) then
    raise exception
      'Expected public.shop_bundle_ledger.coins_delta column is missing';
  end if;
end;
$$;

create or replace function app_private.refresh_authoritative_user_progress(
  p_user_id uuid
)
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

  select coins
    into v_coins
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

    select coin_delta
    from public.shop_ledger
    where user_id = p_user_id

    union all

    select coins_delta
    from public.shop_bundle_ledger
    where user_id = p_user_id
  ) deltas;

  select *
    into v_progress
  from app_private.economy_level_progress(v_total_xp);

  insert into public.user_progress (
    user_id,
    level,
    total_xp,
    current_level_xp,
    next_level_xp,
    ambar_balance,
    total_ambar_earned,
    total_ambar_spent,
    updated_at
  )
  values (
    p_user_id,
    v_progress.level,
    v_progress.total_xp,
    v_progress.current_level_xp,
    v_progress.next_level_xp,
    greatest(v_coins, 0),
    greatest(v_earned, 0),
    greatest(v_spent, 0),
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
  returning *
    into v_result;

  return v_result;
end;
$$;

alter function app_private.refresh_authoritative_user_progress(uuid)
  owner to postgres;

revoke all on function app_private.refresh_authoritative_user_progress(uuid)
  from public, anon, authenticated;

commit;
