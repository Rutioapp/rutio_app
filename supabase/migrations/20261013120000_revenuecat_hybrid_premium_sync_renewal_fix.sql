begin;

-- Corrective migration for Hybrid D renewal handling.
-- 13110000 incorrectly used provisional_until as the stored expires_at.
-- Keep the remote subscription expiry in expires_at, and enforce the bounded
-- webhook-only access window in the Premium access helper.

create or replace function app_private.is_weekly_report_premium(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
      from public.revenuecat_entitlement_state s
     where s.user_id = p_user_id
       and s.entitlement_id = 'premium'
       and s.is_active
       and (s.expires_at is null or s.expires_at > now())
       and (not s.provisional or s.provisional_until is null or s.provisional_until > now())
  )
$$;

revoke all on function app_private.is_weekly_report_premium(uuid)
  from public, anon, authenticated;

create or replace function public.apply_revenuecat_positive_event(
  p_event_id text, p_lease_token uuid, p_user_id uuid,
  p_revenuecat_app_user_id text, p_expires_at timestamptz,
  p_product_id text, p_store text, p_environment text, p_event_at timestamptz,
  p_app_id text, p_subscription_key text, p_allowlisted boolean
)
returns boolean language plpgsql security definer set search_path = ''
as $$
declare
  v_event public.revenuecat_webhook_events%rowtype;
  v_queue public.revenuecat_premium_sync_queue%rowtype;
  v_state public.revenuecat_entitlement_state%rowtype;
  v_scope text;
  v_provisional_until timestamptz;
begin
  if not coalesce(p_allowlisted, false) then raise exception 'identity is not allowlisted'; end if;
  if p_expires_at is null or p_expires_at <= clock_timestamp()
     or p_subscription_key is null or btrim(p_subscription_key) = '' then
    return false;
  end if;
  select * into v_event from public.revenuecat_webhook_events
   where event_id = p_event_id for update;
  if not found or v_event.status <> 'processing'
     or v_event.processing_lease_token <> p_lease_token
     or v_event.processing_lease_until is null
     or v_event.processing_lease_until <= clock_timestamp() then
    raise exception 'webhook lease lost';
  end if;
  v_scope := p_user_id::text || ':' || p_app_id || ':' || p_environment;
  select * into v_queue from public.revenuecat_premium_sync_queue
   where scope_key = v_scope for update;
  if not found then raise exception 'sync queue missing'; end if;
  if v_queue.lease_token is not null
     and v_queue.lease_until is not null
     and v_queue.lease_until > clock_timestamp() then
    return false;
  end if;
  if v_queue.reconciliation_blocked then return false; end if;
  select * into v_state from public.revenuecat_entitlement_state
   where user_id = p_user_id for update;
  if found then
    if v_state.revenuecat_app_id is not null and v_state.revenuecat_app_id <> p_app_id then
      raise exception 'RevenueCat app scope mismatch';
    end if;
    if v_state.environment is not null and v_state.environment <> p_environment then
      raise exception 'RevenueCat environment scope mismatch';
    end if;
    if v_state.reconciliation_blocked then return false; end if;
    if v_state.provisional and v_state.provisional_until is not null
       and v_state.provisional_until <= clock_timestamp() then
      return false;
    end if;
    if v_state.expires_at is not null and p_expires_at <= v_state.expires_at then
      return false;
    end if;
  end if;

  -- The webhook may extend its bounded provisional window, but it must not
  -- replace the remote expiry with that bounded window.
  v_provisional_until := least(p_expires_at, clock_timestamp() + interval '24 hours');
  if found and v_state.provisional_until is not null then
    v_provisional_until := greatest(v_state.provisional_until, v_provisional_until);
  end if;

  insert into public.revenuecat_premium_subscription_state
    (scope_key, subscription_key, product_id, store, is_active, starts_at,
     expires_at, last_event_id, last_event_at, source, updated_at)
  values (v_scope, p_subscription_key, p_product_id, p_store, true, null,
          p_expires_at, p_event_id, p_event_at, 'webhook', now())
  on conflict (scope_key, subscription_key) do update set
    product_id = excluded.product_id, store = excluded.store,
    is_active = true, expires_at = greatest(
      public.revenuecat_premium_subscription_state.expires_at,
      excluded.expires_at), last_event_id = excluded.last_event_id,
    last_event_at = excluded.last_event_at, source = 'webhook', updated_at = now();

  insert into public.revenuecat_entitlement_state
    (user_id, revenuecat_app_user_id, revenuecat_app_id, is_active, expires_at,
     product_id, store, environment, last_event_at, last_event_id,
     last_synced_at, updated_at, last_source, provisional,
     provisional_until, reconciliation_required, reconciliation_blocked)
  values (p_user_id, p_revenuecat_app_user_id, p_app_id, true, p_expires_at,
          p_product_id, p_store, p_environment, p_event_at, p_event_id,
          now(), now(), 'webhook', true, v_provisional_until, true, false)
  on conflict (user_id) do update set
    revenuecat_app_user_id = excluded.revenuecat_app_user_id,
    revenuecat_app_id = excluded.revenuecat_app_id,
    is_active = true,
    starts_at = null,
    expires_at = greatest(public.revenuecat_entitlement_state.expires_at, excluded.expires_at),
    product_id = excluded.product_id, store = excluded.store,
    environment = excluded.environment, last_event_at = excluded.last_event_at,
    last_event_id = excluded.last_event_id, last_synced_at = now(), updated_at = now(),
    last_source = 'webhook', provisional = true,
    provisional_until = greatest(
      public.revenuecat_entitlement_state.provisional_until,
      excluded.provisional_until),
    reconciliation_required = true,
    reconciliation_blocked = false;
  return true;
end;
$$;

revoke all on function public.apply_revenuecat_positive_event(
  text, uuid, uuid, text, timestamptz, text, text, text, timestamptz,
  text, text, boolean)
  from public, anon, authenticated;
grant execute on function public.apply_revenuecat_positive_event(
  text, uuid, uuid, text, timestamptz, text, text, text, timestamptz,
  text, text, boolean)
  to service_role;

commit;
