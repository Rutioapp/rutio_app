begin;

-- One-shot repair for a legacy pg_net response that was marked observed before
-- timeout metadata was available. This migration does not requeue work and does
-- not write Premium or entitlement state.

do $$
begin
  if current_user <> 'postgres' then
    raise exception 'dispatcher audit repair must be installed by postgres';
  end if;
  if to_regclass('app_private.revenuecat_reconcile_dispatch_log') is null
     or to_regclass('public.revenuecat_premium_sync_queue') is null
     or to_regclass('public.revenuecat_entitlement_state') is null then
    raise exception 'Hybrid D dispatcher contract is required';
  end if;
  if to_regclass('net._http_response') is null then
    raise exception 'pg_net response table is required';
  end if;
end;
$$;

create or replace function app_private.repair_revenuecat_reconcile_timeout_audit_staging(
  p_request_id bigint
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_dispatch app_private.revenuecat_reconcile_dispatch_log%rowtype;
  v_response net._http_response%rowtype;
  v_final boolean := false;
begin
  if p_request_id is null then
    raise exception 'request id is required';
  end if;

  select d.*
    into v_dispatch
    from app_private.revenuecat_reconcile_dispatch_log as d
   where d.request_id = p_request_id
   for update;
  if not found then
    raise exception 'dispatcher request not found';
  end if;

  select r.*
    into v_response
    from net._http_response as r
   where r.id = p_request_id;
  if not found then
    raise exception 'pg_net response not found';
  end if;
  if v_response.status_code is not null
     or (not coalesce(v_response.timed_out, false)
         and v_response.error_msg is null) then
    raise exception 'request is not an unclassified transport failure';
  end if;

  select exists (
    select 1
      from public.revenuecat_premium_sync_queue as q
      join public.revenuecat_entitlement_state as e
        on e.user_id = q.user_id
       and e.revenuecat_app_id = q.app_id
       and e.environment = q.environment
     where q.scope_key = v_dispatch.scope_key
       and q.app_id = 'app9a0fbde423'
       and q.environment = 'SANDBOX'
       and q.pending = false
       and (q.lease_until is null or q.lease_until <= pg_catalog.clock_timestamp())
       and q.reconciliation_blocked = false
       and e.reconciliation_required = false
       and e.reconciliation_blocked = false
       and e.provisional = false
  ) into v_final;

  update app_private.revenuecat_reconcile_dispatch_log
     set http_status = null,
         timed_out = coalesce(v_response.timed_out, false),
         transport_error = (v_response.error_msg is not null
                            or coalesce(v_response.timed_out, false)),
         http_error = case
           when v_response.timed_out then 'pg_net_timeout'
           else 'pg_net_transport_error'
         end,
         observed_at = coalesce(observed_at, pg_catalog.now()),
         completed_at = case when v_final then coalesce(completed_at, pg_catalog.now()) else completed_at end,
         completion_reason = case
           when v_final then 'state_confirmed_after_transport_error'
           else completion_reason
         end
   where dispatch_id = v_dispatch.dispatch_id;

  return jsonb_build_object(
    'request_id', p_request_id,
    'http_status', null,
    'timed_out', coalesce(v_response.timed_out, false),
    'transport_error', (v_response.error_msg is not null
                        or coalesce(v_response.timed_out, false)),
    'reconciliation_confirmed', v_final,
    'completed', v_final,
    'requeued', false
  );
end;
$$;

revoke all on function app_private.repair_revenuecat_reconcile_timeout_audit_staging(bigint)
  from public, anon, authenticated, service_role;

comment on function app_private.repair_revenuecat_reconcile_timeout_audit_staging(bigint) is
  'Staging-only, request-scoped repair of a pg_net timeout audit row; never requeues or writes Premium state.';

commit;
