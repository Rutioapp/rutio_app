begin;

-- Hybrid D: webhook signal + bounded positive extension + identity-scoped
-- RevenueCat v2 reconciliation. This migration supersedes the rejected local
-- proposal 20261013100000; that file must not be included in a deploy plan.

alter table public.revenuecat_entitlement_state
  add column if not exists revenuecat_app_id text,
  add column if not exists provisional boolean not null default false,
  add column if not exists provisional_until timestamptz,
  add column if not exists reconciliation_blocked boolean not null default false;

create table if not exists public.revenuecat_premium_sync_queue (
  scope_key text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  app_id text not null,
  environment text not null,
  pending boolean not null default true,
  reconciliation_blocked boolean not null default false,
  priority integer not null default 0,
  next_at timestamptz not null default now(),
  lease_until timestamptz,
  lease_token uuid,
  attempt_count integer not null default 0,
  last_event_id text,
  last_error_code text,
  updated_at timestamptz not null default now(),
  constraint revenuecat_sync_queue_environment_check
    check (environment in ('SANDBOX', 'PRODUCTION')),
  constraint revenuecat_sync_queue_priority_check
    check (priority between 0 and 100)
);

create unique index if not exists uq_revenuecat_sync_queue_scope
  on public.revenuecat_premium_sync_queue(user_id, app_id, environment);
create index if not exists idx_revenuecat_sync_queue_ready
  on public.revenuecat_premium_sync_queue(priority desc, next_at, updated_at)
  where pending;

create table if not exists public.revenuecat_premium_subscription_state (
  scope_key text not null references public.revenuecat_premium_sync_queue(scope_key) on delete cascade,
  subscription_key text not null,
  product_id text,
  store text,
  is_active boolean not null default false,
  starts_at timestamptz,
  expires_at timestamptz,
  last_event_id text,
  last_event_at timestamptz,
  source text not null,
  updated_at timestamptz not null default now(),
  primary key (scope_key, subscription_key),
  constraint revenuecat_subscription_source_check
    check (source in ('webhook', 'reconciliation')),
  constraint revenuecat_subscription_expiry_check
    check (expires_at is null or starts_at is null or expires_at >= starts_at)
);

alter table public.revenuecat_premium_sync_queue enable row level security;
alter table public.revenuecat_premium_subscription_state enable row level security;
revoke all on public.revenuecat_premium_sync_queue,
  public.revenuecat_premium_subscription_state from public, anon, authenticated;
grant all on public.revenuecat_premium_sync_queue,
  public.revenuecat_premium_subscription_state to service_role;

-- The caller must prove allowlist membership before a claim. The SQL function
-- still requires an explicit true flag, so a missing validation cannot claim.
create or replace function public.enqueue_revenuecat_premium_sync(
  p_user_id uuid, p_app_id text, p_environment text, p_event_id text,
  p_priority integer, p_allowlisted boolean
)
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare
  v_scope text;
begin
  if not coalesce(p_allowlisted, false) then
    raise exception 'identity is not allowlisted';
  end if;
  if p_user_id is null or p_app_id is null or btrim(p_app_id) = ''
     or p_environment not in ('SANDBOX', 'PRODUCTION') then
    raise exception 'invalid RevenueCat scope';
  end if;
  v_scope := p_user_id::text || ':' || p_app_id || ':' || p_environment;
  insert into public.revenuecat_premium_sync_queue
    (scope_key, user_id, app_id, environment, pending, priority, next_at,
     last_event_id, updated_at)
  values
    (v_scope, p_user_id, p_app_id, p_environment, true,
     greatest(0, least(coalesce(p_priority, 0), 100)), now(), p_event_id, now())
  on conflict (scope_key) do update set
    pending = true,
    priority = greatest(public.revenuecat_premium_sync_queue.priority, excluded.priority),
    next_at = least(public.revenuecat_premium_sync_queue.next_at, now()),
    last_event_id = coalesce(excluded.last_event_id, public.revenuecat_premium_sync_queue.last_event_id),
    updated_at = now();
  if coalesce(p_priority, 0) >= 80 then
    update public.revenuecat_premium_sync_queue
       set reconciliation_blocked = true,
           updated_at = now()
     where scope_key = v_scope;
    update public.revenuecat_entitlement_state
       set reconciliation_required = true,
           reconciliation_blocked = true,
           updated_at = now()
     where user_id = p_user_id
       and (revenuecat_app_id is null or revenuecat_app_id = p_app_id)
       and (environment is null or environment = p_environment);
  end if;
  return jsonb_build_object('status', 'queued', 'scope_key', v_scope);
end;
$$;

-- Positive event path: only extends access, never reduces expiry, and is
-- blocked after a negative/revocation signal until v2 reconciliation succeeds.
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
  v_effective_expires_at timestamptz;
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
  if not found then
    raise exception 'sync queue missing';
  end if;
  if v_queue.lease_token is not null
     and v_queue.lease_until is not null
     and v_queue.lease_until > clock_timestamp() then
    -- A reconciler owns the scope. Do not let a webhook extend state from a
    -- response that races with the complete v2 read.
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
  v_effective_expires_at := least(
    p_expires_at,
    coalesce(v_state.provisional_until, clock_timestamp() + interval '24 hours')
  );
  if v_effective_expires_at <= clock_timestamp() then return false; end if;
  insert into public.revenuecat_premium_subscription_state
    (scope_key, subscription_key, product_id, store, is_active, starts_at,
     expires_at, last_event_id, last_event_at, source, updated_at)
  values (v_scope, p_subscription_key, p_product_id, p_store, true, null,
          v_effective_expires_at, p_event_id, p_event_at, 'webhook', now())
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
  values (p_user_id, p_revenuecat_app_user_id, p_app_id, true, v_effective_expires_at,
          p_product_id, p_store, p_environment, p_event_at, p_event_id,
          now(), now(), 'webhook', true,
          coalesce(v_state.provisional_until, clock_timestamp() + interval '24 hours'),
          true, false)
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
    provisional_until = coalesce(public.revenuecat_entitlement_state.provisional_until, excluded.provisional_until),
    reconciliation_required = true,
    reconciliation_blocked = false;
  return true;
end;
$$;

create or replace function public.claim_revenuecat_premium_sync(
  p_user_id uuid, p_app_id text, p_environment text, p_allowlisted boolean
)
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare
  v_queue public.revenuecat_premium_sync_queue%rowtype;
  v_token uuid;
begin
  if not coalesce(p_allowlisted, false) then raise exception 'identity is not allowlisted'; end if;
  select * into v_queue from public.revenuecat_premium_sync_queue
   where user_id = p_user_id and app_id = p_app_id and environment = p_environment
   for update;
  if not found then return jsonb_build_object('status', 'not_found'); end if;
  if v_queue.lease_until is not null and v_queue.lease_until > clock_timestamp() then
    return jsonb_build_object('status', 'in_progress');
  end if;
  v_token := extensions.gen_random_uuid();
  update public.revenuecat_premium_sync_queue
     set pending = false, lease_until = clock_timestamp() + interval '10 minutes',
         lease_token = v_token, attempt_count = attempt_count + 1,
         updated_at = now()
   where scope_key = v_queue.scope_key;
  return jsonb_build_object('status', 'claimed', 'scope_key', v_queue.scope_key,
    'lease_token', v_token, 'user_id', p_user_id, 'app_id', p_app_id,
    'environment', p_environment);
end;
$$;

create or replace function public.apply_revenuecat_v2_reconciliation(
  p_user_id uuid, p_app_id text, p_environment text, p_lease_token uuid,
  p_subscriptions jsonb, p_read_complete boolean
)
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare
  v_queue public.revenuecat_premium_sync_queue%rowtype;
  v_state public.revenuecat_entitlement_state%rowtype;
  v_scope text := p_user_id::text || ':' || p_app_id || ':' || p_environment;
  v_active boolean := false;
  v_expires timestamptz;
  v_product text;
  v_store text;
begin
  select * into v_queue from public.revenuecat_premium_sync_queue
   where scope_key = v_scope for update;
  if not found or v_queue.lease_token <> p_lease_token
     or v_queue.lease_until is null or v_queue.lease_until <= clock_timestamp() then
    raise exception 'reconciliation lease lost';
  end if;
  if not coalesce(p_read_complete, false) or jsonb_typeof(p_subscriptions) <> 'array' then
    raise exception 'incomplete RevenueCat v2 reconciliation';
  end if;
  delete from public.revenuecat_premium_subscription_state where scope_key = v_scope;
  insert into public.revenuecat_premium_subscription_state
    (scope_key, subscription_key, product_id, store, is_active, starts_at,
     expires_at, source, updated_at)
  select v_scope, x.subscription_key, x.product_id, x.store, x.is_active,
         x.starts_at, x.expires_at, 'reconciliation', now()
    from jsonb_to_recordset(p_subscriptions) as x(
      subscription_key text, product_id text, store text, is_active boolean,
      starts_at timestamptz, expires_at timestamptz);
  select coalesce(bool_or(is_active and (expires_at is null or expires_at > now())), false),
         max(expires_at) filter (where is_active),
         (array_agg(product_id order by expires_at desc nulls last))[1],
         (array_agg(store order by expires_at desc nulls last))[1]
    into v_active, v_expires, v_product, v_store
    from public.revenuecat_premium_subscription_state
   where scope_key = v_scope;
  select * into v_state from public.revenuecat_entitlement_state
   where user_id = p_user_id for update;
  if found and ((v_state.revenuecat_app_id is not null and v_state.revenuecat_app_id <> p_app_id)
                or (v_state.environment is not null and v_state.environment <> p_environment)) then
    raise exception 'RevenueCat app/environment scope mismatch';
  end if;
  insert into public.revenuecat_entitlement_state
    (user_id, revenuecat_app_user_id, revenuecat_app_id, is_active, expires_at,
     product_id, store, environment, last_synced_at, updated_at, last_source,
     provisional, reconciliation_required, reconciliation_blocked)
  values (p_user_id, coalesce(v_state.revenuecat_app_user_id, p_user_id::text),
          p_app_id, v_active, v_expires, v_product, v_store, p_environment,
          now(), now(), 'reconciliation', false, false, false)
  on conflict (user_id) do update set
    revenuecat_app_id = excluded.revenuecat_app_id, is_active = excluded.is_active,
    starts_at = null,
    provisional_until = null,
    expires_at = excluded.expires_at, product_id = excluded.product_id,
    store = excluded.store, environment = excluded.environment,
    last_synced_at = now(), updated_at = now(), last_source = 'reconciliation',
    provisional = false, reconciliation_required = false,
    reconciliation_blocked = false;
  update public.revenuecat_premium_sync_queue
     set reconciliation_blocked = false, updated_at = now()
   where scope_key = v_scope;
  return jsonb_build_object('status', 'applied', 'is_active', v_active,
    'expires_at', v_expires);
end;
$$;

create or replace function public.complete_revenuecat_premium_sync(
  p_user_id uuid, p_app_id text, p_environment text, p_lease_token uuid,
  p_success boolean, p_error_code text default null
)
returns boolean language plpgsql security definer set search_path = ''
as $$
begin
  update public.revenuecat_premium_sync_queue
     set lease_until = null, lease_token = null,
         pending = case when not p_success and left(coalesce(p_error_code, ''), 10) = 'PERMANENT:'
                        then false else pending end,
         next_at = case when p_success and not pending then now() + interval '365 days'
           when not p_success and left(coalesce(p_error_code, ''), 10) = 'PERMANENT:' then now() + interval '365 days'
           else now() + make_interval(secs => case when p_success then 0 else
             least(3600, 300 * power(2::numeric, least(greatest(attempt_count - 1, 0), 4))) end) end,
         last_error_code = case when p_success then null else nullif(left(coalesce(p_error_code, 'SYNC_FAILED'), 80), '') end,
         updated_at = now()
   where user_id = p_user_id and app_id = p_app_id and environment = p_environment
     and lease_token = p_lease_token;
  if not found then raise exception 'reconciliation lease lost'; end if;
  return true;
end;
$$;

revoke all on function public.enqueue_revenuecat_premium_sync(uuid,text,text,text,integer,boolean),
  public.apply_revenuecat_positive_event(text,uuid,uuid,text,timestamptz,text,text,text,timestamptz,text,text,boolean),
  public.claim_revenuecat_premium_sync(uuid,text,text,boolean),
  public.apply_revenuecat_v2_reconciliation(uuid,text,text,uuid,jsonb,boolean),
  public.complete_revenuecat_premium_sync(uuid,text,text,uuid,boolean,text)
  from public, anon, authenticated;
grant execute on function public.enqueue_revenuecat_premium_sync(uuid,text,text,text,integer,boolean),
  public.apply_revenuecat_positive_event(text,uuid,uuid,text,timestamptz,text,text,text,timestamptz,text,text,boolean),
  public.claim_revenuecat_premium_sync(uuid,text,text,boolean),
  public.apply_revenuecat_v2_reconciliation(uuid,text,text,uuid,jsonb,boolean),
  public.complete_revenuecat_premium_sync(uuid,text,text,uuid,boolean,text)
  to service_role;

comment on table public.revenuecat_premium_sync_queue is
  'Identity-scoped durable Premium reconciliation queue. No global backfill claim is provided by Hybrid D.';
comment on column public.revenuecat_entitlement_state.provisional is
  'Positive webhook extension awaiting complete v2 reconciliation; bounded by expires_at.';
comment on column public.revenuecat_entitlement_state.provisional_until is
  'Hard upper bound for webhook-only provisional access; complete reconciliation clears it.';

commit;
