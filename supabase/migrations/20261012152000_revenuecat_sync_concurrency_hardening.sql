begin;

-- Post-Stage-A reliability hardening. This migration does not grant or revoke
-- Weekly Report access and is safe to apply before the pending Stage-B gate.
alter table public.revenuecat_webhook_events
  add column if not exists processing_lease_until timestamptz,
  add column if not exists processing_lease_token uuid,
  add column if not exists attempt_count integer not null default 0,
  add column if not exists last_error_code text;

alter table public.revenuecat_backfill_runs
  add column if not exists processing_lease_until timestamptz,
  add column if not exists processing_lease_token uuid,
  add column if not exists attempt_count integer not null default 0;

create index if not exists idx_revenuecat_webhook_processing_lease
  on public.revenuecat_webhook_events (processing_lease_until)
  where status = 'processing';
create index if not exists idx_revenuecat_backfill_processing_lease
  on public.revenuecat_backfill_runs (processing_lease_until)
  where status = 'running';

-- Atomically claim a webhook. A live lease is never processed twice; a failed
-- event or an abandoned lease can be claimed again after the lease expires.
create or replace function public.claim_revenuecat_webhook_event(
  p_event_id text,
  p_event_type text,
  p_app_user_id text default null,
  p_event_at timestamptz default null,
  p_environment text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_event public.revenuecat_webhook_events%rowtype;
  v_inserted_lease_token uuid;
begin
  if p_event_id is null or btrim(p_event_id) = '' then
    raise exception 'event_id is required';
  end if;

  insert into public.revenuecat_webhook_events
    (event_id, event_type, app_user_id, event_at, environment, status,
     processing_lease_until, processing_lease_token, attempt_count)
  values
    (p_event_id, coalesce(nullif(btrim(p_event_type), ''), 'UNKNOWN'),
     p_app_user_id, p_event_at, p_environment, 'processing',
     now() + interval '10 minutes', extensions.gen_random_uuid(), 1)
  on conflict (event_id) do nothing
  returning processing_lease_token into v_inserted_lease_token;

  -- The INSERT path owns the first lease. It must not fall through to the
  -- duplicate/live-lease branch below, which is for later callers only.
  if found then
    return jsonb_build_object(
      'status', 'claimed',
      'lease_token', v_inserted_lease_token,
      'attempt_count', 1
    );
  end if;

  select * into v_event
  from public.revenuecat_webhook_events
  where event_id = p_event_id
  for update;

  if v_event.status in ('processed', 'ignored') then
    return jsonb_build_object('status', v_event.status);
  end if;

  if v_event.status = 'processing'
     and v_event.processing_lease_until is not null
     and v_event.processing_lease_until > now() then
    return jsonb_build_object('status', 'in_progress');
  end if;

  update public.revenuecat_webhook_events
  set status = 'processing',
      processing_lease_until = now() + interval '10 minutes',
      processing_lease_token = extensions.gen_random_uuid(),
      attempt_count = v_event.attempt_count + 1,
      last_error_code = null
  where event_id = p_event_id
  returning * into v_event;

  return jsonb_build_object(
    'status', 'claimed',
    'lease_token', v_event.processing_lease_token,
    'attempt_count', v_event.attempt_count
  );
end;
$$;

create or replace function public.finalize_revenuecat_webhook_event(
  p_event_id text,
  p_lease_token uuid,
  p_status text,
  p_error_code text default null
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_status not in ('processed', 'ignored', 'failed') then
    raise exception 'invalid webhook final status';
  end if;
  update public.revenuecat_webhook_events
  set status = p_status,
      processed_at = case when p_status in ('processed', 'ignored') then now() else null end,
      processing_lease_until = null,
      processing_lease_token = null,
      last_error_code = nullif(left(coalesce(p_error_code, ''), 80), '')
  where event_id = p_event_id
    and status = 'processing'
    and processing_lease_token = p_lease_token;
  if not found then
    raise exception 'webhook lease lost';
  end if;
  return true;
end;
$$;

revoke all on function public.claim_revenuecat_webhook_event(text, text, text, timestamptz, text),
  public.finalize_revenuecat_webhook_event(text, uuid, text, text)
  from public, anon, authenticated;
grant execute on function public.claim_revenuecat_webhook_event(text, text, text, timestamptz, text),
  public.finalize_revenuecat_webhook_event(text, uuid, text, text)
  to service_role;

-- A backfill page is committed only after every customer in that page has been
-- reconciled. Re-running a failed page reuses its cursor and is idempotent.
create or replace function public.claim_revenuecat_backfill_run(p_run_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare v_run public.revenuecat_backfill_runs%rowtype;
begin
  select * into v_run from public.revenuecat_backfill_runs where run_id = p_run_id for update;
  if not found then raise exception 'backfill run not found'; end if;
  if v_run.status = 'completed' then return jsonb_build_object('status', 'completed'); end if;
  if v_run.status = 'running'
     and v_run.processing_lease_until is not null
     and v_run.processing_lease_until > now() then
    return jsonb_build_object('status', 'in_progress');
  end if;
  update public.revenuecat_backfill_runs
  set status = 'running',
      processing_lease_until = now() + interval '30 minutes',
      processing_lease_token = extensions.gen_random_uuid(),
      attempt_count = v_run.attempt_count + 1,
      updated_at = now()
  where run_id = p_run_id
  returning * into v_run;
  return jsonb_build_object(
    'status', 'claimed', 'lease_token', v_run.processing_lease_token,
    'next_starting_after', v_run.next_starting_after,
    'examined_count', v_run.examined_count, 'updated_count', v_run.updated_count
  );
end;
$$;

create or replace function public.advance_revenuecat_backfill_run(
  p_run_id uuid,
  p_lease_token uuid,
  p_next_starting_after text,
  p_examined_delta integer,
  p_updated_delta integer
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.revenuecat_backfill_runs
  set status = case when p_next_starting_after is null then 'completed' else 'running' end,
      next_starting_after = p_next_starting_after,
      examined_count = examined_count + greatest(coalesce(p_examined_delta, 0), 0),
      updated_count = updated_count + greatest(coalesce(p_updated_delta, 0), 0),
      processing_lease_until = null,
      processing_lease_token = null,
      completed_at = case when p_next_starting_after is null then now() else null end,
      updated_at = now()
  where run_id = p_run_id and status = 'running' and processing_lease_token = p_lease_token;
  if not found then raise exception 'backfill lease lost'; end if;
  return true;
end;
$$;

create or replace function public.fail_revenuecat_backfill_run(
  p_run_id uuid,
  p_lease_token uuid,
  p_error_code text
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.revenuecat_backfill_runs
  set status = 'failed',
      last_error_code = nullif(left(coalesce(p_error_code, ''), 80), ''),
      processing_lease_until = null,
      processing_lease_token = null,
      updated_at = now()
  where run_id = p_run_id and status = 'running' and processing_lease_token = p_lease_token;
  if not found then raise exception 'backfill lease lost'; end if;
  return true;
end;
$$;

revoke all on function public.claim_revenuecat_backfill_run(uuid),
  public.advance_revenuecat_backfill_run(uuid, uuid, text, integer, integer),
  public.fail_revenuecat_backfill_run(uuid, uuid, text)
  from public, anon, authenticated;
grant execute on function public.claim_revenuecat_backfill_run(uuid),
  public.advance_revenuecat_backfill_run(uuid, uuid, text, integer, integer),
  public.fail_revenuecat_backfill_run(uuid, uuid, text)
  to service_role;

comment on function public.claim_revenuecat_webhook_event(text, text, text, timestamptz, text) is 'Service-only atomic RevenueCat webhook claim with retry lease.';
comment on function public.claim_revenuecat_backfill_run(uuid) is 'Service-only atomic backfill run claim with recovery lease.';

commit;
