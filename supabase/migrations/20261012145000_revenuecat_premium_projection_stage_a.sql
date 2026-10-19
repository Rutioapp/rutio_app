begin;

-- ETAPA A: server-only RevenueCat projection, webhook idempotency and
-- resumable backfill bookkeeping. This migration intentionally does not gate
-- or rate-limit any Weekly Report RPC.
create table if not exists public.revenuecat_entitlement_state (
  user_id uuid primary key references auth.users(id) on delete cascade,
  revenuecat_app_user_id text not null unique,
  entitlement_id text not null default 'premium',
  is_active boolean not null default false,
  starts_at timestamptz,
  expires_at timestamptz,
  product_id text,
  store text,
  environment text,
  last_event_at timestamptz,
  last_event_id text,
  last_synced_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint revenuecat_entitlement_state_entitlement_check check (entitlement_id = 'premium'),
  constraint revenuecat_entitlement_state_expiry_check check (expires_at is null or starts_at is null or expires_at >= starts_at)
);

create table if not exists public.revenuecat_webhook_events (
  event_id text primary key,
  event_type text not null,
  app_user_id text,
  event_at timestamptz,
  environment text,
  status text not null default 'processing',
  processed_at timestamptz,
  created_at timestamptz not null default now(),
  constraint revenuecat_webhook_events_status_check check (status in ('processing', 'processed', 'ignored', 'failed'))
);

create table if not exists public.revenuecat_backfill_runs (
  run_id uuid primary key default gen_random_uuid(),
  status text not null default 'running',
  next_starting_after text,
  examined_count integer not null default 0,
  updated_count integer not null default 0,
  last_error_code text,
  started_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz,
  constraint revenuecat_backfill_runs_status_check check (status in ('running', 'completed', 'failed'))
);

create index if not exists idx_revenuecat_entitlement_active on public.revenuecat_entitlement_state (user_id) where is_active;
create index if not exists idx_revenuecat_webhook_events_user on public.revenuecat_webhook_events (app_user_id, event_at desc);
alter table public.revenuecat_entitlement_state enable row level security;
alter table public.revenuecat_webhook_events enable row level security;
alter table public.revenuecat_backfill_runs enable row level security;
revoke all on public.revenuecat_entitlement_state, public.revenuecat_webhook_events, public.revenuecat_backfill_runs from public, anon, authenticated;
grant all on public.revenuecat_entitlement_state, public.revenuecat_webhook_events, public.revenuecat_backfill_runs to service_role;

create or replace function app_private.is_weekly_report_premium(p_user_id uuid)
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists (select 1 from public.revenuecat_entitlement_state s where s.user_id = p_user_id and s.entitlement_id = 'premium' and s.is_active and (s.expires_at is null or s.expires_at > now()))
$$;
revoke all on function app_private.is_weekly_report_premium(uuid) from public, anon, authenticated;

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
declare v_existing public.revenuecat_entitlement_state%rowtype;
begin
  if p_user_id is null or p_revenuecat_app_user_id is null or btrim(p_revenuecat_app_user_id) = '' then raise exception 'invalid RevenueCat identity'; end if;
  if p_app_id is null or btrim(p_app_id) = '' then raise exception 'invalid RevenueCat app'; end if;
  select * into v_existing from public.revenuecat_entitlement_state where user_id = p_user_id for update;
  if found and v_existing.revenuecat_app_user_id <> p_revenuecat_app_user_id then raise exception 'RevenueCat identity is already bound to another app user'; end if;
  if found and v_existing.last_event_at is not null and (p_event_at is null or p_event_at < v_existing.last_event_at) then return false; end if;
  insert into public.revenuecat_entitlement_state (user_id, revenuecat_app_user_id, is_active, starts_at, expires_at, product_id, store, environment, last_event_at, last_event_id, last_synced_at, updated_at)
  values (p_user_id, p_revenuecat_app_user_id, p_is_active, p_starts_at, p_expires_at, p_product_id, p_store, p_environment, p_event_at, p_event_id, coalesce(p_synced_at, now()), now())
  on conflict (user_id) do update set is_active = excluded.is_active, starts_at = excluded.starts_at, expires_at = excluded.expires_at, product_id = excluded.product_id, store = excluded.store, environment = excluded.environment, last_event_at = excluded.last_event_at, last_event_id = excluded.last_event_id, last_synced_at = excluded.last_synced_at, updated_at = now();
  return true;
end;
$$;
revoke all on function public.apply_revenuecat_entitlement(uuid, text, boolean, timestamptz, timestamptz, text, text, text, timestamptz, text, timestamptz, text) from public, anon, authenticated;
grant execute on function public.apply_revenuecat_entitlement(uuid, text, boolean, timestamptz, timestamptz, text, text, text, timestamptz, text, timestamptz, text) to service_role;

commit;
