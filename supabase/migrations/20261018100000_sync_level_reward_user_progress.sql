-- RUTIO — synchronize the legacy progress projection after level claims.
-- The wallet and reward ledger remain authoritative. This migration only
-- replaces the level-claim RPC; it does not modify data or permissions.

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
  if lower(pg_catalog.btrim(coalesce(p_operation_type, ''))) <> 'claim' then
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
    perform app_private.refresh_authoritative_user_progress(v_user_id);
    select * into v_existing from public.achievement_level_reward_ledger where id = v_existing.id;
    return v_existing;
  end if;

  select * into v_existing
  from public.achievement_level_reward_ledger
  where user_id = v_user_id and source_type = 'level_reward' and source_id = v_level::text;
  if found then
    update public.achievement_level_reward_ledger set is_idempotent = true
    where id = v_existing.id and not is_idempotent;
    perform app_private.refresh_authoritative_user_progress(v_user_id);
    select * into v_existing from public.achievement_level_reward_ledger where id = v_existing.id;
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

  -- The refresh is in the same transaction. Any failure rolls back both the
  -- authoritative wallet mutation and the projection update.
  perform app_private.refresh_authoritative_user_progress(v_user_id);
  return v_ledger;
end;
$$;

-- Ownership and existing authenticated EXECUTE grant are preserved by CREATE
-- OR REPLACE; no RLS or privilege change is needed.
