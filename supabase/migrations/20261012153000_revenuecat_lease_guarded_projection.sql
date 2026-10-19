begin;

-- Lease-guarded projection and deterministic RevenueCat snapshot precedence.
-- This migration is separate from 152000 and must remain unapplied until the
-- matching Edge Functions have been deployed and verified.
alter table public.revenuecat_backfill_runs
  add column if not exists last_advanced_page_key text;

alter table public.revenuecat_entitlement_state
  add column if not exists last_source text not null default 'unknown',
  add column if not exists last_observed_at timestamptz,
  add column if not exists last_observed_reliable boolean not null default false,
  add column if not exists reconciliation_required boolean not null default false,
  add column if not exists last_conflict_code text,
  add column if not exists reconciliation_lease_until timestamptz,
  add column if not exists reconciliation_lease_token uuid,
  add column if not exists reconciliation_attempt_count integer not null default 0,
  add column if not exists reconciliation_next_at timestamptz,
  add column if not exists reconciliation_last_error text;

create index if not exists idx_revenuecat_reconciliation_candidates
  on public.revenuecat_entitlement_state (reconciliation_next_at, updated_at)
  where reconciliation_required;

create or replace function public.apply_revenuecat_entitlement_v2(
  p_user_id uuid, p_revenuecat_app_user_id text, p_is_active boolean,
  p_starts_at timestamptz, p_expires_at timestamptz, p_product_id text, p_store text,
  p_environment text, p_event_at timestamptz, p_event_id text,
  p_synced_at timestamptz, p_app_id text, p_source text,
  p_observed_at timestamptz, p_observed_reliable boolean
)
returns boolean language plpgsql security definer set search_path = ''
as $$
declare
  v_existing public.revenuecat_entitlement_state%rowtype;
  v_conflict boolean := false;
begin
  if p_user_id is null or p_revenuecat_app_user_id is null
     or btrim(p_revenuecat_app_user_id) = '' then raise exception 'invalid RevenueCat identity'; end if;
  if p_app_id is null or btrim(p_app_id) = '' then raise exception 'invalid RevenueCat app'; end if;
  if p_source not in ('webhook', 'backfill', 'reconciliation') then raise exception 'invalid RevenueCat source'; end if;

  select * into v_existing from public.revenuecat_entitlement_state where user_id = p_user_id for update;
  if found and v_existing.revenuecat_app_user_id <> p_revenuecat_app_user_id then
    raise exception 'RevenueCat identity is already bound to another app user';
  end if;

  if found then
    if not coalesce(p_observed_reliable, false) or p_observed_at is null then
      v_conflict := true;
    elsif p_source = 'webhook' and v_existing.last_source = 'webhook' then
      -- request_date is the comparable snapshot clock. event_timestamp_ms is
      -- the webhook generation clock and must not allow an older snapshot to
      -- overwrite a newer observation.
      if v_existing.last_observed_at is not null
         and p_observed_at < v_existing.last_observed_at then
        return false;
      elsif v_existing.last_observed_at is not null
            and p_observed_at = v_existing.last_observed_at then
        if p_event_id is not null and p_event_id = v_existing.last_event_id then return false; end if;
        v_conflict := true;
      elsif p_event_at is null then
        v_conflict := true;
      elsif v_existing.last_event_at is null then
        null; -- reliable reconciliation can recover an uncertain prior row
      elsif p_event_at < v_existing.last_event_at then
        return false;
      elsif p_event_at = v_existing.last_event_at then
        if p_event_id is not null and p_event_id = v_existing.last_event_id then return false; end if;
        v_conflict := true;
      end if;
    elsif p_source = 'backfill' and v_existing.last_source = 'backfill' then
      if v_existing.last_observed_at is null then
        null; -- reliable reconciliation can recover an uncertain prior row
      elsif p_observed_at < v_existing.last_observed_at then
        return false;
      elsif p_observed_at = v_existing.last_observed_at then
        if p_event_id is not null and p_event_id = v_existing.last_event_id then return false; end if;
        v_conflict := true;
      end if;
    elsif p_source = 'reconciliation' and v_existing.last_source = 'unknown' then
      null; -- a reliable manual/server reconciliation can seed legacy metadata
    elsif v_existing.last_observed_at is not null and p_observed_at < v_existing.last_observed_at then
      return false;
    elsif v_existing.last_observed_at is null or p_observed_at = v_existing.last_observed_at then
      -- Webhook event time and API observation time are different clocks.
      -- Cross-source equality or reversal is never ordered optimistically.
      v_conflict := true;
    end if;
  end if;

  if v_conflict then
    update public.revenuecat_entitlement_state
       set is_active = case when v_existing.last_source = 'unknown' then v_existing.is_active else false end,
           reconciliation_required = true,
           last_conflict_code = 'TEMPORAL_CONFLICT', updated_at = now()
     where user_id = p_user_id;
    if found then return false; end if;
    -- An uncertain first snapshot may create only a fail-closed inactive row.
    p_is_active := false;
  end if;

  insert into public.revenuecat_entitlement_state
    (user_id, revenuecat_app_user_id, is_active, starts_at, expires_at,
     product_id, store, environment, last_event_at, last_event_id,
     last_synced_at, updated_at, last_source, last_observed_at,
     last_observed_reliable, reconciliation_required, last_conflict_code)
  values
    (p_user_id, p_revenuecat_app_user_id, p_is_active, p_starts_at, p_expires_at,
     p_product_id, p_store, p_environment,
     case when p_source = 'webhook' then p_event_at else null end,
     p_event_id, coalesce(p_synced_at, now()), now(), p_source,
     p_observed_at, coalesce(p_observed_reliable, false), v_conflict,
     case when v_conflict then 'TEMPORAL_CONFLICT' else null end)
  on conflict (user_id) do update set
    is_active = excluded.is_active, starts_at = excluded.starts_at,
    expires_at = excluded.expires_at, product_id = excluded.product_id,
    store = excluded.store, environment = excluded.environment,
    last_event_at = excluded.last_event_at, last_event_id = excluded.last_event_id,
    last_synced_at = excluded.last_synced_at, updated_at = now(),
    last_source = excluded.last_source, last_observed_at = excluded.last_observed_at,
    last_observed_reliable = excluded.last_observed_reliable,
    reconciliation_required = excluded.reconciliation_required,
    last_conflict_code = excluded.last_conflict_code;
  return not v_conflict;
end;
$$;

create or replace function public.apply_revenuecat_entitlement(
  p_user_id uuid, p_revenuecat_app_user_id text, p_is_active boolean,
  p_starts_at timestamptz default null, p_expires_at timestamptz default null,
  p_product_id text default null, p_store text default null,
  p_environment text default null, p_event_at timestamptz default null,
  p_event_id text default null, p_synced_at timestamptz default now(),
  p_app_id text default null
)
returns boolean language plpgsql security definer set search_path = ''
as $$
begin
  return public.apply_revenuecat_entitlement_v2(
    p_user_id, p_revenuecat_app_user_id, p_is_active, p_starts_at, p_expires_at,
    p_product_id, p_store, p_environment, p_event_at, p_event_id,
    p_synced_at, p_app_id, 'webhook', p_event_at, p_event_at is not null);
end;
$$;

create or replace function public.apply_revenuecat_entitlement_for_webhook(
  p_event_id text, p_lease_token uuid, p_user_id uuid,
  p_revenuecat_app_user_id text, p_is_active boolean, p_expires_at timestamptz,
  p_product_id text, p_store text, p_environment text,
  p_event_at timestamptz, p_projection_event_id text, p_app_id text,
  p_observed_at timestamptz, p_observed_reliable boolean
)
returns boolean language plpgsql security definer set search_path = ''
as $$
declare v_event public.revenuecat_webhook_events%rowtype;
begin
  select * into v_event from public.revenuecat_webhook_events where event_id = p_event_id for update;
  if not found or v_event.status <> 'processing' or v_event.processing_lease_token <> p_lease_token
     or v_event.processing_lease_until is null or v_event.processing_lease_until <= clock_timestamp() then
    raise exception 'webhook lease lost';
  end if;
  return public.apply_revenuecat_entitlement_v2(
    p_user_id, p_revenuecat_app_user_id, p_is_active, null, p_expires_at,
    p_product_id, p_store, p_environment, p_event_at, p_projection_event_id,
    now(), p_app_id, 'webhook', p_observed_at, p_observed_reliable);
end;
$$;

create or replace function public.apply_revenuecat_entitlement_for_backfill(
  p_run_id uuid, p_lease_token uuid, p_user_id uuid,
  p_revenuecat_app_user_id text, p_is_active boolean, p_expires_at timestamptz,
  p_product_id text, p_environment text, p_event_at timestamptz,
  p_projection_event_id text, p_app_id text,
  p_observed_at timestamptz, p_observed_reliable boolean
)
returns boolean language plpgsql security definer set search_path = ''
as $$
declare v_run public.revenuecat_backfill_runs%rowtype;
begin
  select * into v_run from public.revenuecat_backfill_runs where run_id = p_run_id for update;
  if not found or v_run.status <> 'running' or v_run.processing_lease_token <> p_lease_token
     or v_run.processing_lease_until is null or v_run.processing_lease_until <= clock_timestamp() then
    raise exception 'backfill lease lost';
  end if;
  return public.apply_revenuecat_entitlement_v2(
    p_user_id, p_revenuecat_app_user_id, p_is_active, null, p_expires_at,
    p_product_id, null, p_environment, p_event_at, p_projection_event_id,
    now(), p_app_id, 'backfill', p_observed_at, p_observed_reliable);
end;
$$;

create or replace function public.claim_revenuecat_backfill_run(p_run_id uuid)
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare v_run public.revenuecat_backfill_runs%rowtype;
begin
  select * into v_run from public.revenuecat_backfill_runs where run_id = p_run_id for update;
  if not found then raise exception 'backfill run not found'; end if;
  if v_run.status = 'completed' then return jsonb_build_object('status', 'completed'); end if;
  if v_run.status = 'running' and v_run.processing_lease_until is not null and v_run.processing_lease_until > now() then
    return jsonb_build_object('status', 'in_progress');
  end if;
  update public.revenuecat_backfill_runs
     set status = 'running', processing_lease_until = now() + interval '30 minutes',
         processing_lease_token = extensions.gen_random_uuid(), attempt_count = v_run.attempt_count + 1, updated_at = now()
   where run_id = p_run_id returning * into v_run;
  return jsonb_build_object('status', 'claimed', 'lease_token', v_run.processing_lease_token,
    'next_starting_after', v_run.next_starting_after, 'examined_count', v_run.examined_count,
    'updated_count', v_run.updated_count, 'started_at', v_run.started_at);
end;
$$;

create or replace function public.advance_revenuecat_backfill_run_v2(
  p_run_id uuid, p_lease_token uuid, p_page_key text,
  p_next_starting_after text, p_examined_delta integer, p_updated_delta integer
)
returns boolean language plpgsql security definer set search_path = ''
as $$
declare v_run public.revenuecat_backfill_runs%rowtype;
begin
  select * into v_run from public.revenuecat_backfill_runs where run_id = p_run_id for update;
  if not found or v_run.status <> 'running' or v_run.processing_lease_token <> p_lease_token
     or v_run.processing_lease_until is null or v_run.processing_lease_until <= clock_timestamp() then
    raise exception 'backfill lease lost';
  end if;
  if p_page_key is null or btrim(p_page_key) = '' then raise exception 'backfill page key is required'; end if;
  if v_run.last_advanced_page_key = p_page_key then return true; end if;
  update public.revenuecat_backfill_runs
     set status = case when p_next_starting_after is null then 'completed' else 'running' end,
         next_starting_after = p_next_starting_after, last_advanced_page_key = p_page_key,
         examined_count = examined_count + greatest(coalesce(p_examined_delta, 0), 0),
         updated_count = updated_count + greatest(coalesce(p_updated_delta, 0), 0),
         processing_lease_until = null, processing_lease_token = null,
         completed_at = case when p_next_starting_after is null then now() else null end, updated_at = now()
   where run_id = p_run_id;
  return true;
end;
$$;

create or replace function public.advance_revenuecat_backfill_run(
  p_run_id uuid, p_lease_token uuid, p_next_starting_after text,
  p_examined_delta integer, p_updated_delta integer
)
returns boolean language plpgsql security definer set search_path = ''
as $$
begin
  return public.advance_revenuecat_backfill_run_v2(
    p_run_id, p_lease_token, coalesce(p_next_starting_after, '__initial__'),
    p_next_starting_after, p_examined_delta, p_updated_delta);
end;
$$;

-- Claim a small batch of conflict rows. SKIP LOCKED prevents two
-- reconciliators from selecting the same user, while the lease allows recovery
-- after a crashed Edge Function.
create or replace function public.claim_revenuecat_reconciliation_batch(p_limit integer default 10)
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare
  v_row record;
  v_token uuid;
  v_claim jsonb;
  v_items jsonb := '[]'::jsonb;
begin
  if p_limit is null or p_limit < 1 or p_limit > 25 then
    raise exception 'invalid reconciliation batch size';
  end if;
  for v_row in
    select user_id
      from public.revenuecat_entitlement_state
     where reconciliation_required
       and (reconciliation_next_at is null or reconciliation_next_at <= clock_timestamp())
       and (reconciliation_lease_until is null or reconciliation_lease_until <= clock_timestamp())
     order by updated_at, user_id
     for update skip locked
     limit p_limit
  loop
    v_token := extensions.gen_random_uuid();
    update public.revenuecat_entitlement_state
       set reconciliation_lease_until = now() + interval '10 minutes',
           reconciliation_lease_token = v_token,
           reconciliation_attempt_count = reconciliation_attempt_count + 1,
           reconciliation_last_error = null,
           updated_at = now()
     where user_id = v_row.user_id
     returning jsonb_build_object(
       'user_id', user_id,
       'revenuecat_app_user_id', revenuecat_app_user_id,
       'lease_token', reconciliation_lease_token,
       'attempt_count', reconciliation_attempt_count
     ) into v_claim;
    v_items := v_items || jsonb_build_array(v_claim);
  end loop;
  return v_items;
end;
$$;

create or replace function public.fail_revenuecat_reconciliation(
  p_user_id uuid, p_lease_token uuid, p_error_code text,
  p_retry_after_seconds integer default 3600
)
returns boolean language plpgsql security definer set search_path = ''
as $$
begin
  update public.revenuecat_entitlement_state
     set reconciliation_lease_until = null,
         reconciliation_lease_token = null,
         reconciliation_next_at = now() + make_interval(secs => greatest(60, least(coalesce(p_retry_after_seconds, 3600), 86400))),
         reconciliation_last_error = nullif(left(coalesce(p_error_code, 'RECONCILIATION_FAILED'), 80), ''),
         updated_at = now()
   where user_id = p_user_id
     and reconciliation_required
     and reconciliation_lease_token = p_lease_token;
  if not found then raise exception 'reconciliation lease lost'; end if;
  return true;
end;
$$;

-- Apply a fresh authoritative API observation and clear the conflict only if
-- the projection transaction succeeds. A stale worker cannot do either.
create or replace function public.apply_revenuecat_reconciliation(
  p_user_id uuid, p_lease_token uuid, p_is_active boolean,
  p_expires_at timestamptz, p_product_id text, p_observed_at timestamptz,
  p_observed_reliable boolean, p_event_id text, p_app_id text
)
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare
  v_state public.revenuecat_entitlement_state%rowtype;
  v_applied boolean;
begin
  select * into v_state from public.revenuecat_entitlement_state
   where user_id = p_user_id for update;
  if not found or not v_state.reconciliation_required
     or v_state.reconciliation_lease_token <> p_lease_token
     or v_state.reconciliation_lease_until is null
     or v_state.reconciliation_lease_until <= clock_timestamp() then
    raise exception 'reconciliation lease lost';
  end if;
  v_applied := public.apply_revenuecat_entitlement_v2(
    p_user_id, v_state.revenuecat_app_user_id, p_is_active, null,
    p_expires_at, p_product_id, null, v_state.environment, null, p_event_id,
    now(), p_app_id, 'reconciliation', p_observed_at, p_observed_reliable);
  if v_applied then
    update public.revenuecat_entitlement_state
       set reconciliation_required = false,
           reconciliation_lease_until = null,
           reconciliation_lease_token = null,
           reconciliation_next_at = null,
           reconciliation_last_error = null,
           last_conflict_code = null,
           updated_at = now()
     where user_id = p_user_id;
    return jsonb_build_object('status', 'applied');
  end if;
  update public.revenuecat_entitlement_state
     set reconciliation_lease_until = null,
         reconciliation_lease_token = null,
         reconciliation_next_at = now() + interval '1 hour',
         reconciliation_last_error = 'TEMPORAL_CONFLICT',
         updated_at = now()
   where user_id = p_user_id;
  return jsonb_build_object('status', 'conflict');
end;
$$;

revoke all on function public.apply_revenuecat_entitlement_v2(uuid,text,boolean,timestamptz,timestamptz,text,text,text,timestamptz,text,timestamptz,text,text,timestamptz,boolean),
  public.apply_revenuecat_entitlement_for_webhook(text,uuid,uuid,text,boolean,timestamptz,text,text,text,timestamptz,text,text,timestamptz,boolean),
  public.apply_revenuecat_entitlement_for_backfill(uuid,uuid,uuid,text,boolean,timestamptz,text,text,timestamptz,text,text,timestamptz,boolean),
  public.advance_revenuecat_backfill_run_v2(uuid,uuid,text,text,integer,integer),
  public.claim_revenuecat_reconciliation_batch(integer),
  public.fail_revenuecat_reconciliation(uuid,uuid,text,integer),
  public.apply_revenuecat_reconciliation(uuid,uuid,boolean,timestamptz,text,timestamptz,boolean,text,text)
  from public, anon, authenticated;
grant execute on function public.apply_revenuecat_entitlement_v2(uuid,text,boolean,timestamptz,timestamptz,text,text,text,timestamptz,text,timestamptz,text,text,timestamptz,boolean),
  public.apply_revenuecat_entitlement_for_webhook(text,uuid,uuid,text,boolean,timestamptz,text,text,text,timestamptz,text,text,timestamptz,boolean),
  public.apply_revenuecat_entitlement_for_backfill(uuid,uuid,uuid,text,boolean,timestamptz,text,text,timestamptz,text,text,timestamptz,boolean),
  public.advance_revenuecat_backfill_run_v2(uuid,uuid,text,text,integer,integer),
  public.claim_revenuecat_reconciliation_batch(integer),
  public.fail_revenuecat_reconciliation(uuid,uuid,text,integer),
  public.apply_revenuecat_reconciliation(uuid,uuid,boolean,timestamptz,text,timestamptz,boolean,text,text)
  to service_role;

commit;
