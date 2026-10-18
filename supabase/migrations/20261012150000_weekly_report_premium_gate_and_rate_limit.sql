begin;

-- ETAPA B: apply after 20261012145000_revenuecat_premium_projection_stage_a.sql.
-- The defensive CREATE IF NOT EXISTS / CREATE OR REPLACE statements below make
-- the migration reviewable and retry-safe; this file is the first one that
-- changes Weekly Report authorization and refresh behavior.

-- Server projection of RevenueCat's premium entitlement. These tables live in
-- public only because Supabase Edge Functions access PostgREST; all client
-- privileges are revoked and the RPC below is service_role-only.
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
  constraint revenuecat_entitlement_state_entitlement_check
    check (entitlement_id = 'premium'),
  constraint revenuecat_entitlement_state_expiry_check
    check (expires_at is null or starts_at is null or expires_at >= starts_at)
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
  constraint revenuecat_webhook_events_status_check
    check (status in ('processing', 'processed', 'ignored', 'failed'))
);

create index if not exists idx_revenuecat_entitlement_active
  on public.revenuecat_entitlement_state (user_id)
  where is_active;
create index if not exists idx_revenuecat_webhook_events_user
  on public.revenuecat_webhook_events (app_user_id, event_at desc);

alter table public.revenuecat_entitlement_state enable row level security;
alter table public.revenuecat_webhook_events enable row level security;
revoke all on public.revenuecat_entitlement_state,
  public.revenuecat_webhook_events from public, anon, authenticated;
grant all on public.revenuecat_entitlement_state,
  public.revenuecat_webhook_events to service_role;

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
  )
$$;

revoke all on function app_private.is_weekly_report_premium(uuid)
  from public, anon, authenticated;

-- The webhook function is the only writer. A previous event timestamp wins
-- over an older, delayed delivery; equal timestamps are idempotent by event ID.
create or replace function public.apply_revenuecat_entitlement(
  p_user_id uuid,
  p_revenuecat_app_user_id text,
  p_is_active boolean,
  p_starts_at timestamptz default null,
  p_expires_at timestamptz default null,
  p_product_id text default null,
  p_store text default null,
  p_environment text default null,
  p_event_at timestamptz default null,
  p_event_id text default null,
  p_synced_at timestamptz default now(),
  p_app_id text default null
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_existing public.revenuecat_entitlement_state%rowtype;
begin
  if p_user_id is null or p_revenuecat_app_user_id is null
     or btrim(p_revenuecat_app_user_id) = '' then
    raise exception 'invalid RevenueCat identity';
  end if;
  if p_app_id is null or btrim(p_app_id) = '' then
    raise exception 'invalid RevenueCat app';
  end if;

  select * into v_existing
  from public.revenuecat_entitlement_state
  where user_id = p_user_id
  for update;

  if found and v_existing.revenuecat_app_user_id <> p_revenuecat_app_user_id then
    raise exception 'RevenueCat identity is already bound to another app user';
  end if;

  if found and v_existing.last_event_at is not null
     and (p_event_at is null or p_event_at < v_existing.last_event_at) then
    return false;
  end if;

  insert into public.revenuecat_entitlement_state (
    user_id, revenuecat_app_user_id, is_active, starts_at, expires_at,
    product_id, store, environment, last_event_at, last_event_id,
    last_synced_at, updated_at
  ) values (
    p_user_id, p_revenuecat_app_user_id, p_is_active, p_starts_at, p_expires_at,
    p_product_id, p_store, p_environment, p_event_at, p_event_id,
    coalesce(p_synced_at, now()), now()
  )
  on conflict (user_id) do update set
    is_active = excluded.is_active,
    starts_at = excluded.starts_at,
    expires_at = excluded.expires_at,
    product_id = excluded.product_id,
    store = excluded.store,
    environment = excluded.environment,
    last_event_at = excluded.last_event_at,
    last_event_id = excluded.last_event_id,
    last_synced_at = excluded.last_synced_at,
    updated_at = now();
  return true;
end;
$$;

revoke all on function public.apply_revenuecat_entitlement(
  uuid, text, boolean, timestamptz, timestamptz, text, text, text,
  timestamptz, text, timestamptz, text
) from public, anon, authenticated;
grant execute on function public.apply_revenuecat_entitlement(
  uuid, text, boolean, timestamptz, timestamptz, text, text, text,
  timestamptz, text, timestamptz, text
) to service_role;

create or replace function app_private.require_weekly_report_premium(p_user_id uuid)
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if p_user_id is null then raise exception 'authentication required'; end if;
  if not app_private.is_weekly_report_premium(p_user_id) then
    raise exception 'weekly report premium required' using errcode = 'P0001';
  end if;
end;
$$;
revoke all on function app_private.require_weekly_report_premium(uuid)
  from public, anon, authenticated;

create table if not exists app_private.weekly_report_refresh_limits (
  user_id uuid not null references auth.users(id) on delete cascade,
  week_start_date date not null,
  successful_refresh_count integer not null default 0,
  last_success_at timestamptz,
  primary key (user_id, week_start_date),
  constraint weekly_report_refresh_count_check
    check (successful_refresh_count between 0 and 3)
);
revoke all on app_private.weekly_report_refresh_limits from public, anon, authenticated;

-- Re-define every public Weekly Report boundary so the historical snapshots
-- remain stored but are unreadable and ungeneratable by Free users.
create or replace function public.activate_weekly_report(p_activation_local_date date, p_timezone_name text)
returns public.weekly_report_activations language plpgsql security definer set search_path = ''
as $$
declare v_user_id uuid := auth.uid(); v_now timestamptz := now(); v_activation public.weekly_report_activations%rowtype;
begin
  if v_user_id is null then raise exception 'authentication required'; end if;
  perform app_private.require_weekly_report_premium(v_user_id);
  if p_timezone_name is null or not exists (select 1 from pg_catalog.pg_timezone_names where name = btrim(p_timezone_name)) then raise exception 'timezone_name must be a valid IANA time zone'; end if;
  if p_activation_local_date is distinct from (v_now at time zone btrim(p_timezone_name))::date then raise exception 'activation_local_date must be today in timezone_name'; end if;
  insert into public.weekly_report_activations (user_id, activated_at, activation_local_date, timezone_name)
  values (v_user_id, v_now, p_activation_local_date, btrim(p_timezone_name))
  on conflict (user_id) do update set timezone_name = excluded.timezone_name
  returning * into v_activation;
  if v_activation.activated_at = v_now then
    insert into public.weekly_report_habit_config_versions (user_id, habit_id, effective_from, effective_local_date, effective_timezone_name, name, emoji, habit_type, target_count, schedule, is_archived, source_event, source_updated_at)
    select h.user_id, h.id, v_activation.activated_at, v_activation.activation_local_date, v_activation.timezone_name, h.name, h.emoji, h.habit_type, h.target_count, h.schedule, h.is_archived, 'activation', h.updated_at
    from public.habits h where h.user_id = v_user_id;
  end if;
  return v_activation;
end;
$$;

create or replace function public.get_my_weekly_report(p_report_id uuid)
returns jsonb language plpgsql stable security definer set search_path = ''
as $$
declare v_user_id uuid := auth.uid(); v_payload jsonb;
begin
  if v_user_id is null then raise exception 'authentication required'; end if;
  perform app_private.require_weekly_report_premium(v_user_id);
  select app_private.weekly_report_payload(p_report_id, v_user_id) into v_payload;
  return v_payload;
end;
$$;

create or replace function public.get_my_latest_weekly_report()
returns jsonb language plpgsql stable security definer set search_path = ''
as $$
declare v_user_id uuid := auth.uid(); v_report_id uuid;
begin
  if v_user_id is null then raise exception 'authentication required'; end if;
  perform app_private.require_weekly_report_premium(v_user_id);
  select r.id into v_report_id from public.weekly_reports r where r.user_id = v_user_id order by case when r.status = 'provisional' then 0 else 1 end, r.week_start_date desc, r.updated_at desc, r.id desc limit 1;
  return app_private.weekly_report_payload(v_report_id, v_user_id);
end;
$$;

create or replace function public.get_my_weekly_report_by_week_start(p_week_start_date date)
returns jsonb language plpgsql stable security definer set search_path = ''
as $$
declare v_user_id uuid := auth.uid(); v_report_id uuid;
begin
  if v_user_id is null then raise exception 'authentication required'; end if;
  perform app_private.require_weekly_report_premium(v_user_id);
  select r.id into v_report_id from public.weekly_reports r where r.user_id = v_user_id and r.week_start_date = p_week_start_date;
  return app_private.weekly_report_payload(v_report_id, v_user_id);
end;
$$;

create or replace function public.list_my_weekly_reports(p_before_week_start date default null, p_limit integer default 20)
returns jsonb language plpgsql stable security definer set search_path = ''
as $$
declare v_user_id uuid := auth.uid(); v_limit integer := least(greatest(coalesce(p_limit, 20), 1), 50);
begin
  if v_user_id is null then raise exception 'authentication required'; end if;
  perform app_private.require_weekly_report_premium(v_user_id);
  return coalesce((select jsonb_agg(jsonb_build_object('reportId', x.id, 'weekStartDate', x.week_start_date, 'weekEndDate', x.week_end_date, 'status', x.status, 'completionRate', x.completion_rate, 'completedCount', x.completed_count, 'scheduledCount', x.scheduled_count, 'completedRaw', x.completed_count_raw, 'scheduledQuota', x.scheduled_count, 'rawRatio', x.raw_completion_rate, 'cappedRatio', x.capped_completion_rate, 'dataQuality', x.metrics_data_quality, 'firstPartialWeek', x.is_first_partial_week, 'refreshedAt', x.refreshed_at, 'finalizedAt', x.finalized_at) order by x.week_start_date desc, x.id desc) from (select r.* from public.weekly_reports r where r.user_id = v_user_id and (p_before_week_start is null or r.week_start_date < p_before_week_start) order by r.week_start_date desc, r.id desc limit v_limit) x), '[]'::jsonb);
end;
$$;

create or replace function public.refresh_my_weekly_report(p_week_start_date date)
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_activation public.weekly_report_activations%rowtype;
  v_report public.weekly_reports%rowtype;
  v_week_start date;
  v_limit app_private.weekly_report_refresh_limits%rowtype;
begin
  if v_user_id is null then raise exception 'authentication required'; end if;
  perform app_private.require_weekly_report_premium(v_user_id);
  select * into v_activation from public.weekly_report_activations where user_id = v_user_id for update;
  if not found then raise exception 'weekly report is not activated'; end if;
  v_week_start := ((now() at time zone v_activation.timezone_name)::date - (extract(isodow from (now() at time zone v_activation.timezone_name)::date)::int - 1));
  if p_week_start_date is distinct from v_week_start then raise exception 'only the current eligible week may be refreshed'; end if;

  insert into app_private.weekly_report_refresh_limits (user_id, week_start_date)
  values (v_user_id, v_week_start) on conflict (user_id, week_start_date) do nothing;
  select * into v_limit from app_private.weekly_report_refresh_limits where user_id = v_user_id and week_start_date = v_week_start for update;
  if v_limit.successful_refresh_count >= 3 then raise exception 'weekly report refresh limit reached'; end if;
  if v_limit.last_success_at is not null and v_limit.last_success_at > now() - interval '15 minutes' then raise exception 'weekly report refresh cooldown active'; end if;

  -- The slot is incremented only after generation returns successfully. Any
  -- generator exception rolls back the row insert/update and consumes nothing.
  v_report := app_private.generate_or_refresh_weekly_report(v_user_id, v_week_start);
  update app_private.weekly_report_refresh_limits
  set successful_refresh_count = successful_refresh_count + 1, last_success_at = now()
  where user_id = v_user_id and week_start_date = v_week_start;
  return app_private.weekly_report_payload(v_report.id, v_user_id);
end;
$$;

-- The scheduled worker is an alternate generation route, so it must enforce
-- the same gate even though it does not run with auth.uid().
create or replace function app_private.process_weekly_report_automation()
returns void language plpgsql security definer set search_path = ''
as $$
declare a record; local_now timestamp; week_start date; local_minute integer;
begin
  for a in select user_id, timezone_name from public.weekly_report_activations order by user_id loop
    begin
      if not app_private.is_weekly_report_premium(a.user_id) then continue; end if;
      local_now := now() at time zone a.timezone_name;
      week_start := local_now::date - (extract(isodow from local_now)::int - 1);
      local_minute := extract(hour from local_now)::int * 60 + extract(minute from local_now)::int;
      if extract(isodow from local_now)::int = 7 and local_minute >= 19 * 60 then
        if not exists (select 1 from public.weekly_reports r where r.user_id = a.user_id and r.week_start_date = week_start) then perform app_private.generate_or_refresh_weekly_report(a.user_id, week_start); end if;
      end if;
      if extract(isodow from local_now)::int = 1 and local_minute >= 10 then perform app_private.finalize_weekly_report(a.user_id, week_start - 7); end if;
    exception when others then raise warning '[WEEKLY_REPORT_AUTOMATION] user % failed: %', a.user_id, sqlerrm;
    end;
  end loop;
end;
$$;

revoke all on function public.activate_weekly_report(date, text), public.get_my_weekly_report(uuid), public.get_my_latest_weekly_report(), public.list_my_weekly_reports(date, integer), public.refresh_my_weekly_report(date), public.get_my_weekly_report_by_week_start(date) from public, anon;
grant execute on function public.activate_weekly_report(date, text), public.get_my_weekly_report(uuid), public.get_my_latest_weekly_report(), public.list_my_weekly_reports(date, integer), public.refresh_my_weekly_report(date), public.get_my_weekly_report_by_week_start(date) to authenticated;
revoke all on function app_private.process_weekly_report_automation() from public, anon, authenticated;

comment on table public.revenuecat_entitlement_state is 'Server-only projection of RevenueCat premium; clients have no privileges.';
comment on table public.revenuecat_webhook_events is 'Minimal server-only RevenueCat webhook idempotency ledger; no raw payloads.';
comment on function public.refresh_my_weekly_report(date) is 'Owner-scoped Premium refresh; max 3 successful refreshes per user/week and 15 minute cooldown.';

commit;
