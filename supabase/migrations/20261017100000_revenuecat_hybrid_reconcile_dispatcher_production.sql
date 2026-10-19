begin;

-- Production-only Hybrid D dispatcher.
-- The dispatcher submits asynchronous HTTP work and observes metadata only.
-- Premium state remains exclusively owned by the reconciliation RPCs.
-- Required external objects are preflighted, never enabled here:
--   pg_net net.http_post and net._http_response
--   Supabase Vault vault.decrypted_secrets
-- Vault secret: REVENUECAT_RECONCILE_AUTHORIZATION_PRODUCTION.

create schema if not exists app_private;
revoke all on schema app_private from public, anon, authenticated;

do $$
begin
  if current_user <> 'postgres' then
    raise exception 'dispatcher must be installed by postgres';
  end if;
  if to_regclass('public.revenuecat_premium_sync_queue') is null
     or to_regclass('public.revenuecat_entitlement_state') is null then
    raise exception 'Hybrid D tables are required';
  end if;
  if to_regprocedure('public.claim_revenuecat_premium_sync(uuid,text,text,boolean)') is null
     or to_regprocedure('public.apply_revenuecat_v2_reconciliation(uuid,text,text,uuid,jsonb,boolean)') is null
     or to_regprocedure('public.complete_revenuecat_premium_sync(uuid,text,text,uuid,boolean,text)') is null then
    raise exception 'Hybrid D RPC contract is required';
  end if;
  if to_regprocedure('net.http_post(text,jsonb,jsonb,jsonb,integer)') is null
     or to_regclass('net._http_response') is null then
    raise exception 'pg_net is required; enable it before applying this migration';
  end if;
  if to_regclass('vault.decrypted_secrets') is null then
    raise exception 'Supabase Vault is required';
  end if;
end;
$$;

create table if not exists app_private.revenuecat_reconcile_dispatch_log (
  dispatch_id bigint generated always as identity primary key,
  request_id bigint unique,
  scope_key text not null,
  sent_at timestamptz not null default now(),
  http_status integer,
  http_error text,
  timed_out boolean not null default false,
  transport_error boolean not null default false,
  permanent_failure boolean not null default false,
  submission_error text,
  observed_at timestamptz,
  completed_at timestamptz,
  completion_reason text,
  requeued_at timestamptz,
  released_at timestamptz,
  release_code text,
  constraint revenuecat_dispatch_log_result_check check (
    (http_status is null or http_status between 100 and 599)
    and not (http_error is not null and submission_error is not null)
    and (completion_reason is null or completion_reason in (
      'http_2xx', 'state_confirmed_after_transport_error'
    ))
    and (release_code is null or release_code in (
      'AUTH_ROTATED', 'ENDPOINT_FIXED', 'ALLOWLIST_FIXED'
    ))
  )
);

alter table app_private.revenuecat_reconcile_dispatch_log
  add column if not exists timed_out boolean not null default false,
  add column if not exists transport_error boolean not null default false,
  add column if not exists completion_reason text,
  add column if not exists requeued_at timestamptz;

create index if not exists idx_revenuecat_dispatch_log_open
  on app_private.revenuecat_reconcile_dispatch_log(scope_key, sent_at)
  where completed_at is null and http_status is null and submission_error is null;

create or replace function app_private.dispatch_revenuecat_reconcile_production()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_auth text;
  v_request_id bigint;
  v_observed integer := 0;
  v_completed integer := 0;
  v_requeued integer := 0;
  v_sent integer := 0;
  v_submit_failed integer := 0;
  v_selected integer := 0;
  v_row_count integer;
  v_item record;
begin
  if not pg_catalog.pg_try_advisory_xact_lock(
    pg_catalog.hashtextextended('rutio:revenuecat-reconcile:PRODUCTION', 0)
  ) then
    return jsonb_build_object('status', 'already_running');
  end if;

  select ds.decrypted_secret
    into v_auth
    from vault.decrypted_secrets as ds
   where ds.name = 'REVENUECAT_RECONCILE_AUTHORIZATION_PRODUCTION'
   limit 1;
  if v_auth is null or pg_catalog.btrim(v_auth) = '' then
    raise exception 'Production reconcile authorization is missing from Vault';
  end if;

  -- pg_net is asynchronous. Persist metadata only, never bodies, headers or
  -- credentials. A timeout is not treated as HTTP success.
  update app_private.revenuecat_reconcile_dispatch_log as d
     set http_status = r.status_code,
         http_error = case
           when r.timed_out then 'pg_net_timeout'
           when r.status_code >= 400 then 'http_' || r.status_code::text
           when r.error_msg is not null then 'pg_net_error'
           else null
         end,
         timed_out = coalesce(r.timed_out, false),
         transport_error = (r.error_msg is not null or coalesce(r.timed_out, false)),
         permanent_failure = case
           when r.status_code between 400 and 499
            and r.status_code not in (408, 429) then true
           else false
         end,
         observed_at = pg_catalog.now()
    from net._http_response as r
   where d.request_id = r.id
     and d.http_status is null
     and d.submission_error is null
     and d.observed_at is null;
  get diagnostics v_row_count = row_count;
  v_observed := v_row_count;

  -- Final state is proven by Hybrid D, not merely by a 2xx response.
  update app_private.revenuecat_reconcile_dispatch_log as d
     set completed_at = pg_catalog.now(),
         completion_reason = case
           when d.http_status between 200 and 299 then 'http_2xx'
           else 'state_confirmed_after_transport_error'
         end
    from public.revenuecat_premium_sync_queue as q
    join public.revenuecat_entitlement_state as e
      on e.user_id = q.user_id
     and e.revenuecat_app_id = q.app_id
     and e.environment = q.environment
   where d.scope_key = q.scope_key
     and d.observed_at is not null
     and (d.http_status between 200 and 299
       or (d.http_status is null and (d.timed_out or d.transport_error)))
     and d.completed_at is null
     and d.submission_error is null
     and q.pending = false
     and (q.lease_until is null or q.lease_until <= pg_catalog.clock_timestamp())
     and q.reconciliation_blocked = false
     and e.reconciliation_required = false
     and e.reconciliation_blocked = false
     and e.provisional = false;
  get diagnostics v_row_count = row_count;
  v_completed := v_row_count;

  -- Requeue only incomplete transport failures. Final projections are never
  -- requeued and permanent HTTP failures remain stopped.
  update public.revenuecat_premium_sync_queue as q
     set pending = true,
         next_at = pg_catalog.now() + make_interval(secs => least(
           3600,
           300 * power(2::numeric, least(greatest(q.attempt_count - 1, 0), 4))
         )),
         last_error_code = case
           when d.timed_out then 'PGNET_TIMEOUT'
           else 'PGNET_TRANSPORT_ERROR'
         end,
         updated_at = pg_catalog.now()
    from app_private.revenuecat_reconcile_dispatch_log as d
   where d.scope_key = q.scope_key
     and d.completed_at is null
     and d.requeued_at is null
     and d.observed_at is not null
     and d.http_status is null
     and (d.timed_out or d.transport_error)
     and q.pending = false
     and (q.lease_until is null or q.lease_until <= pg_catalog.clock_timestamp())
     and not exists (
       select 1
         from public.revenuecat_entitlement_state as e
        where e.user_id = q.user_id
          and e.revenuecat_app_id = q.app_id
          and e.environment = q.environment
          and e.reconciliation_required = false
          and e.reconciliation_blocked = false
          and e.provisional = false
     );
  get diagnostics v_row_count = row_count;
  v_requeued := v_row_count;

  update app_private.revenuecat_reconcile_dispatch_log as d
     set requeued_at = pg_catalog.now()
    from public.revenuecat_premium_sync_queue as q
   where d.scope_key = q.scope_key
     and d.requeued_at is null
     and d.completed_at is null
     and d.observed_at is not null
     and d.http_status is null
     and (d.timed_out or d.transport_error)
     and q.pending = true
     and q.last_error_code in ('PGNET_TIMEOUT', 'PGNET_TRANSPORT_ERROR');

  for v_item in
    select q.scope_key, q.user_id
      from public.revenuecat_premium_sync_queue as q
     where q.pending = true
       and q.next_at <= pg_catalog.now()
       and q.environment = 'PRODUCTION'
       and (q.lease_until is null or q.lease_until <= pg_catalog.clock_timestamp())
       and not exists (
         select 1
           from app_private.revenuecat_reconcile_dispatch_log as d
          where d.scope_key = q.scope_key
            and d.sent_at > pg_catalog.now() - interval '15 minutes'
            and d.completed_at is null
            and d.permanent_failure = false
            and d.submission_error is null
       )
       and not exists (
         select 1
           from app_private.revenuecat_reconcile_dispatch_log as d
          where d.scope_key = q.scope_key
            and d.permanent_failure = true
       )
     order by q.priority desc, q.next_at asc
     limit 20
  loop
    v_selected := v_selected + 1;
    begin
      select net.http_post(
        url := 'https://kbjecrepjnmucljrpnlp.supabase.co/functions/v1/revenuecat-reconcile',
        body := jsonb_build_object('user_id', v_item.user_id::text),
        headers := jsonb_build_object(
          'Authorization', v_auth,
          'Content-Type', 'application/json'
        ),
        timeout_milliseconds := 30000
      ) into v_request_id;

      insert into app_private.revenuecat_reconcile_dispatch_log
        (request_id, scope_key, sent_at)
      values (v_request_id, v_item.scope_key, pg_catalog.now());
      v_sent := v_sent + 1;
    exception when others then
      insert into app_private.revenuecat_reconcile_dispatch_log
        (scope_key, sent_at, submission_error)
      values (v_item.scope_key, pg_catalog.now(), 'pg_net_submit_error');
      v_submit_failed := v_submit_failed + 1;
    end;
  end loop;

  return jsonb_build_object(
    'status', 'ok',
    'selected', v_selected,
    'sent', v_sent,
    'submission_failed', v_submit_failed,
    'http_observed', v_observed,
    'reconciliations_completed', v_completed,
    'transport_requeued', v_requeued
  );
end;
$$;

create or replace function app_private.release_revenuecat_reconcile_permanent_failure_production(
  p_scope_key text,
  p_release_code text
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_scope text;
begin
  if p_scope_key is null or p_release_code is null or p_release_code not in (
    'AUTH_ROTATED', 'ENDPOINT_FIXED', 'ALLOWLIST_FIXED'
  ) then
    raise exception 'invalid selective dispatcher release';
  end if;

  select q.scope_key into v_scope
    from public.revenuecat_premium_sync_queue as q
   where q.scope_key = p_scope_key
     and q.environment = 'PRODUCTION';
  if not found then
    raise exception 'scope is not a Production queue entry';
  end if;

  update app_private.revenuecat_reconcile_dispatch_log
     set permanent_failure = false,
         released_at = pg_catalog.now(),
         release_code = p_release_code
   where scope_key = v_scope
     and permanent_failure = true;

  return found;
end;
$$;

revoke all on table app_private.revenuecat_reconcile_dispatch_log
  from public, anon, authenticated, service_role;
revoke all on function app_private.dispatch_revenuecat_reconcile_production()
  from public, anon, authenticated, service_role;
revoke all on function app_private.release_revenuecat_reconcile_permanent_failure_production(text,text)
  from public, anon, authenticated, service_role;

comment on function app_private.dispatch_revenuecat_reconcile_production() is
  'Production-only Hybrid D dispatcher. Sends at most 20 ready Production jobs through pg_net; does not write Premium state.';
comment on function app_private.release_revenuecat_reconcile_permanent_failure_production(text,text) is
  'Selective Production release of a permanent dispatcher guard after an operator fix; preserves audit and Premium state.';

commit;
