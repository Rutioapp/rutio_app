begin;

-- WR-FLEX-1: keep the existing legacy fields as bounded compatibility fields,
-- while storing the canonical raw flexible-weekly metrics additively.  This
-- migration is intentionally prepared locally; it is not a deployment step.
alter table public.weekly_reports
  add column if not exists completed_count_raw integer,
  add column if not exists raw_completion_rate numeric,
  add column if not exists capped_completion_rate numeric,
  add column if not exists metrics_data_quality text not null default 'legacy';

alter table public.weekly_report_habits
  add column if not exists completed_count_raw integer,
  add column if not exists raw_completion_rate numeric,
  add column if not exists capped_completion_rate numeric,
  add column if not exists metrics_data_quality text not null default 'legacy';

alter table public.weekly_reports
  drop constraint if exists weekly_reports_completed_count_raw_check,
  drop constraint if exists weekly_reports_raw_completion_rate_check,
  drop constraint if exists weekly_reports_capped_completion_rate_check,
  drop constraint if exists weekly_reports_metrics_data_quality_check;
alter table public.weekly_reports
  add constraint weekly_reports_completed_count_raw_check
    check (completed_count_raw is null or completed_count_raw >= 0),
  add constraint weekly_reports_raw_completion_rate_check
    check (raw_completion_rate is null or raw_completion_rate >= 0),
  add constraint weekly_reports_capped_completion_rate_check
    check (capped_completion_rate is null or capped_completion_rate between 0 and 1),
  add constraint weekly_reports_metrics_data_quality_check
    check (metrics_data_quality in ('legacy', 'verified', 'partial', 'unverifiable'));

alter table public.weekly_report_habits
  drop constraint if exists weekly_report_habits_completed_count_raw_check,
  drop constraint if exists weekly_report_habits_raw_completion_rate_check,
  drop constraint if exists weekly_report_habits_capped_completion_rate_check,
  drop constraint if exists weekly_report_habits_metrics_data_quality_check;
alter table public.weekly_report_habits
  add constraint weekly_report_habits_completed_count_raw_check
    check (completed_count_raw is null or completed_count_raw >= 0),
  add constraint weekly_report_habits_raw_completion_rate_check
    check (raw_completion_rate is null or raw_completion_rate >= 0),
  add constraint weekly_report_habits_capped_completion_rate_check
    check (capped_completion_rate is null or capped_completion_rate between 0 and 1),
  add constraint weekly_report_habits_metrics_data_quality_check
    check (metrics_data_quality in ('legacy', 'verified', 'partial', 'unverifiable'));

create or replace function app_private.weekly_report_capped_rate(
  p_completed_raw numeric,
  p_scheduled_quota integer
)
returns numeric
language sql
immutable
set search_path = ''
as $$
  select case
    when coalesce(p_scheduled_quota, 0) <= 0 then null
    else least(greatest(coalesce(p_completed_raw, 0)::numeric
                        / p_scheduled_quota::numeric, 0), 1)
  end
$$;

create or replace function app_private.weekly_report_flexible_activity(
  p_completed boolean,
  p_skipped boolean
)
returns text
language sql
immutable
set search_path = ''
as $$
  select case
    when coalesce(p_skipped, false) then 'skipped'
    when coalesce(p_completed, false) then 'completed'
    else 'neutral'
  end
$$;

-- The public report generator remains backend-authoritative.  The important
-- distinction from the previous body is that observed dates are used for
-- activity/log reads, while eligible dates are used for a flexible quota.
create or replace function app_private.generate_or_refresh_weekly_report(
  p_user_id uuid,
  p_week_start_date date
)
returns public.weekly_reports
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_activation public.weekly_report_activations%rowtype;
  v_report public.weekly_reports%rowtype;
  v_existing public.weekly_reports%rowtype;
  v_bounds record;
  v_local_today date;
  v_day date;
  v_cfg public.weekly_report_habit_config_versions%rowtype;
  v_habit_id uuid;
  v_log public.habit_logs%rowtype;
  v_scheduled boolean;
  v_completed boolean;
  v_skipped boolean;
  v_previous public.weekly_reports%rowtype;
  v_current_rate numeric;
  v_previous_rate numeric;
  v_report_scheduled integer;
  v_report_completed_raw integer;
  v_report_completed integer;
  v_report_quality text;
begin
  select * into v_activation
  from public.weekly_report_activations
  where user_id = p_user_id;
  if not found then raise exception 'weekly report is not activated'; end if;

  select * into v_bounds
  from app_private.weekly_report_week_bounds(
    p_week_start_date, v_activation.timezone_name);
  if v_bounds.end_instant <= v_activation.activated_at then
    raise exception 'week is before weekly report activation';
  end if;
  v_local_today := (now() at time zone v_activation.timezone_name)::date;

  select * into v_existing
  from public.weekly_reports
  where user_id = p_user_id and week_start_date = p_week_start_date
  for update;
  if found and v_existing.status = 'final' then return v_existing; end if;

  create temporary table if not exists pg_temp.wr_days (
    local_date date primary key,
    observed boolean not null,
    eligible boolean not null,
    scheduled_count integer not null default 0,
    completed_count integer not null default 0,
    skipped_count integer not null default 0
  ) on commit drop;
  truncate pg_temp.wr_days;
  insert into pg_temp.wr_days(local_date, observed, eligible)
  select d::date,
    d::date >= v_activation.activation_local_date
      and d::date <= v_local_today,
    d::date >= v_activation.activation_local_date
  from generate_series(p_week_start_date, p_week_start_date + 6,
                       interval '1 day') d;

  -- One row per eligible local date.  This deliberately includes future
  -- eligible dates in an open week, but those dates are never read as logs or
  -- emitted as occurrences below.  SUM + one CEIL is the canonical segment
  -- policy and avoids rounding each configuration segment independently.
  create temporary table if not exists pg_temp.wr_quota_segments (
    habit_id uuid not null,
    local_date date not null,
    config_id uuid not null,
    schedule jsonb not null,
    configured_quota numeric not null,
    primary key (habit_id, local_date)
  ) on commit drop;
  truncate pg_temp.wr_quota_segments;

  for v_habit_id in
    select distinct c.habit_id
    from public.weekly_report_habit_config_versions c
    where c.user_id = p_user_id
      and c.effective_from < v_bounds.end_instant
  loop
    for v_day in
      select local_date from pg_temp.wr_days where eligible order by local_date
    loop
      select * into v_cfg
      from app_private.weekly_report_effective_config(
        p_user_id, v_habit_id,
        ((v_day + 1)::timestamp at time zone v_activation.timezone_name));
      if not found or v_cfg.effective_local_date > v_day
         or v_cfg.is_archived
         or v_cfg.schedule->>'type' <> 'timesPerWeek' then
        continue;
      end if;
      insert into pg_temp.wr_quota_segments
        (habit_id, local_date, config_id, schedule, configured_quota)
      values
        (v_habit_id, v_day, v_cfg.id, v_cfg.schedule,
         (v_cfg.schedule->>'timesPerWeek')::numeric)
      on conflict (habit_id, local_date) do update set
        config_id = excluded.config_id,
        schedule = excluded.schedule,
        configured_quota = excluded.configured_quota;
    end loop;
  end loop;

  create temporary table if not exists pg_temp.wr_occurrences (
    habit_id uuid not null,
    local_date date not null,
    config_id uuid not null,
    habit_type text not null,
    name text not null,
    emoji text,
    target_count numeric,
    schedule jsonb not null,
    scheduled boolean not null,
    completed boolean not null,
    skipped boolean not null,
    progress numeric,
    primary key (habit_id, local_date)
  ) on commit drop;
  truncate pg_temp.wr_occurrences;

  for v_habit_id in
    select distinct c.habit_id
    from public.weekly_report_habit_config_versions c
    where c.user_id = p_user_id
      and c.effective_from < v_bounds.end_instant
  loop
    -- Activity is observed only through the current local date.  Future
    -- eligible dates contribute to quota, never to daily obligations.
    for v_day in
      select local_date from pg_temp.wr_days where observed order by local_date
    loop
      select * into v_cfg
      from app_private.weekly_report_effective_config(
        p_user_id, v_habit_id,
        ((v_day + 1)::timestamp at time zone v_activation.timezone_name));
      if not found or v_cfg.effective_local_date > v_day
         or v_cfg.is_archived then
        continue;
      end if;

      select * into v_log
      from public.habit_logs l
      where l.user_id = p_user_id
        and l.habit_id = v_habit_id
        and l.log_date = v_day;
      if not found then
        v_log.is_completed := false;
        v_log.is_skipped := false;
        v_log.value := 0;
      end if;
      v_skipped := coalesce(v_log.is_skipped, false);
      v_completed := case when v_cfg.habit_type = 'count'
        then coalesce(v_log.value, 0) >= coalesce(v_cfg.target_count, 1)
        else coalesce(v_log.is_completed, false)
      end;
      v_completed := v_completed and not v_skipped;
      v_scheduled := case when v_cfg.schedule->>'type' = 'timesPerWeek'
        then false
        else app_private.weekly_report_schedule_matches(v_cfg.schedule, v_day)
      end;

      insert into pg_temp.wr_occurrences
        (habit_id, local_date, config_id, habit_type, name, emoji, target_count,
         schedule, scheduled, completed, skipped, progress)
      values
        (v_habit_id, v_day, v_cfg.id, v_cfg.habit_type, v_cfg.name, v_cfg.emoji,
         v_cfg.target_count, v_cfg.schedule, v_scheduled, v_completed,
         case when v_scheduled
                   or v_cfg.schedule->>'type' = 'timesPerWeek'
              then v_skipped else false end,
         v_log.value)
      on conflict (habit_id, local_date) do update set
        config_id = excluded.config_id,
        habit_type = excluded.habit_type,
        name = excluded.name,
        emoji = excluded.emoji,
        target_count = excluded.target_count,
        schedule = excluded.schedule,
        scheduled = excluded.scheduled,
        completed = excluded.completed,
        skipped = excluded.skipped,
        progress = excluded.progress;
    end loop;
  end loop;

  update pg_temp.wr_days d set
    scheduled_count = x.scheduled_count,
    completed_count = x.completed_count,
    skipped_count = x.skipped_count
  from (
    select local_date,
      count(*) filter (where scheduled)::int scheduled_count,
      count(*) filter (where scheduled and completed)::int completed_count,
      count(*) filter (where scheduled and skipped)::int skipped_count
    from pg_temp.wr_occurrences
    group by local_date
  ) x
  where x.local_date = d.local_date;

  create temporary table if not exists pg_temp.wr_habits (
    habit_id uuid primary key,
    name text not null,
    emoji text,
    habit_type text not null,
    target_count numeric,
    schedule jsonb not null,
    scheduled_count integer not null,
    completed_count integer not null,
    completed_count_raw integer not null,
    skipped_count integer not null,
    occurrences jsonb not null
  ) on commit drop;
  truncate pg_temp.wr_habits;

  insert into pg_temp.wr_habits
  select o.habit_id,
    (array_agg(o.name order by o.local_date desc))[1],
    (array_agg(o.emoji order by o.local_date desc))[1],
    (array_agg(o.habit_type order by o.local_date desc))[1],
    (array_agg(o.target_count order by o.local_date desc))[1],
    (array_agg(o.schedule order by o.local_date desc))[1],
    count(*) filter (where o.scheduled)::int + coalesce(q.weekly_quota, 0),
    least(
      count(*) filter (where o.scheduled and o.completed)::int
        + count(*) filter (
            where o.schedule->>'type' = 'timesPerWeek' and o.completed)::int,
      count(*) filter (where o.scheduled)::int + coalesce(q.weekly_quota, 0)),
    count(*) filter (where o.scheduled and o.completed)::int
      + count(*) filter (
          where o.schedule->>'type' = 'timesPerWeek' and o.completed)::int,
    count(*) filter (where o.skipped)::int,
    jsonb_agg(jsonb_build_object(
      'date', o.local_date::text,
      'scope', case when o.schedule->>'type' = 'timesPerWeek'
        then 'weeklyQuota' else 'date' end,
      'scheduleType', o.schedule->>'type',
      'scheduled', o.scheduled,
      'completed', o.completed,
      'skipped', o.skipped,
      'activity', app_private.weekly_report_flexible_activity(
        o.completed, o.skipped),
      'progress', o.progress,
      'target', o.target_count,
      'weeklyQuota', case when o.schedule->>'type' = 'timesPerWeek'
        then (o.schedule->>'timesPerWeek')::int else null end
    ) order by o.local_date)
  from pg_temp.wr_occurrences o
  left join lateral (
    select case when count(*) = 0 then 0
      else ceil(sum(s.configured_quota) / 7.0)::int end weekly_quota
    from pg_temp.wr_quota_segments s
    where s.habit_id = o.habit_id
  ) q on true
  group by o.habit_id, q.weekly_quota;

  create temporary table if not exists pg_temp.wr_report_totals (
    scheduled_count integer not null,
    completed_count_raw integer not null
  ) on commit drop;
  truncate pg_temp.wr_report_totals;
  insert into pg_temp.wr_report_totals
  select
    (select coalesce(sum(scheduled_count), 0) from pg_temp.wr_days)
      + (select coalesce(sum(h.scheduled_count - coalesce(x.date_scheduled, 0)), 0)
         from pg_temp.wr_habits h left join (
           select habit_id, count(*) filter (where scheduled)::int date_scheduled
           from pg_temp.wr_occurrences group by habit_id
         ) x on x.habit_id = h.habit_id),
    (select coalesce(sum(completed_count), 0) from pg_temp.wr_days)
      + (select coalesce(sum(h.completed_count_raw
                            - coalesce(x.date_completed, 0)), 0)
         from pg_temp.wr_habits h left join (
           select habit_id,
             count(*) filter (where scheduled and completed)::int date_completed
           from pg_temp.wr_occurrences group by habit_id
         ) x on x.habit_id = h.habit_id);

  select scheduled_count, completed_count_raw into
    v_report_scheduled, v_report_completed_raw
  from pg_temp.wr_report_totals;
  v_report_completed := least(v_report_completed_raw, v_report_scheduled);
  v_report_quality := case when v_activation.activation_local_date > p_week_start_date
    then 'partial' else 'verified' end;

  insert into public.weekly_reports
    (user_id, week_start_date, week_end_date, timezone_name,
     is_first_partial_week, scheduled_count, completed_count,
     completed_count_raw, completion_rate, raw_completion_rate,
     capped_completion_rate, metrics_data_quality, metrics_policy_version,
     generated_at, refreshed_at)
  values
    (p_user_id, p_week_start_date, v_bounds.week_end_date,
     v_activation.timezone_name,
     v_activation.activation_local_date > p_week_start_date,
     v_report_scheduled, v_report_completed, v_report_completed_raw,
     app_private.weekly_report_capped_rate(
       v_report_completed_raw, v_report_scheduled),
     case when v_report_scheduled <= 0 then null
       else v_report_completed_raw::numeric / v_report_scheduled end,
     app_private.weekly_report_capped_rate(
       v_report_completed_raw, v_report_scheduled),
     v_report_quality, 2, now(), now())
  on conflict (user_id, week_start_date) do update set
    week_end_date = excluded.week_end_date,
    timezone_name = excluded.timezone_name,
    is_first_partial_week = excluded.is_first_partial_week,
    scheduled_count = excluded.scheduled_count,
    completed_count = excluded.completed_count,
    completed_count_raw = excluded.completed_count_raw,
    completion_rate = excluded.completion_rate,
    raw_completion_rate = excluded.raw_completion_rate,
    capped_completion_rate = excluded.capped_completion_rate,
    metrics_data_quality = excluded.metrics_data_quality,
    metrics_policy_version = excluded.metrics_policy_version,
    refreshed_at = now();

  select * into v_report
  from public.weekly_reports
  where user_id = p_user_id and week_start_date = p_week_start_date
  for update;

  delete from public.weekly_report_days where report_id = v_report.id;
  delete from public.weekly_report_habits where report_id = v_report.id;

  insert into public.weekly_report_days
    (report_id, user_id, local_date, scheduled_count, completed_count,
     skipped_count, completion_rate, day_state)
  select v_report.id, p_user_id, local_date, scheduled_count, completed_count,
    skipped_count,
    case when scheduled_count = 0 then null
      else completed_count::numeric / scheduled_count end,
    case when not eligible or scheduled_count = 0 then 'noPlan'
      when skipped_count > 0 and completed_count = 0 then 'skipped'
      when completed_count = scheduled_count then 'completed'
      when completed_count > 0 then 'partial'
      else 'scheduledIncomplete' end
  from pg_temp.wr_days;

  insert into public.weekly_report_habits
    (report_id, user_id, habit_id, name, emoji, habit_type, target_count,
     schedule, scheduled_count, completed_count, completed_count_raw,
     skipped_count, completion_rate, raw_completion_rate,
     capped_completion_rate, metrics_data_quality, occurrences)
  select v_report.id, p_user_id, habit_id::text, name, emoji, habit_type,
    target_count, schedule, scheduled_count, completed_count,
    completed_count_raw, skipped_count,
    app_private.weekly_report_capped_rate(
      completed_count_raw, scheduled_count),
    case when scheduled_count <= 0 then null
      else completed_count_raw::numeric / scheduled_count end,
    app_private.weekly_report_capped_rate(
      completed_count_raw, scheduled_count),
    v_report_quality, occurrences
  from pg_temp.wr_habits;

  select * into v_previous
  from public.weekly_reports p
  where p.user_id = p_user_id
    and p.status = 'final'
    and p.week_start_date < p_week_start_date
  order by p.week_start_date desc
  limit 1;
  v_current_rate := app_private.weekly_report_capped_rate(
    v_report_completed_raw, v_report_scheduled);
  v_previous_rate := case when not found or v_previous.scheduled_count = 0
    then null
    else v_previous.completed_count::numeric / v_previous.scheduled_count end;

  update public.weekly_reports r set
    completion_rate = v_current_rate,
    raw_completion_rate = case when v_report_scheduled <= 0 then null
      else v_report_completed_raw::numeric / v_report_scheduled end,
    capped_completion_rate = v_current_rate,
    best_day = (select local_date from pg_temp.wr_days
      where scheduled_count > 0
      order by completed_count::numeric / scheduled_count desc,
               completed_count desc, local_date limit 1),
    previous_report_id = case when v_previous_rate is null then null
      else v_previous.id end,
    trend_kind = case when v_report.is_first_partial_week
        or v_current_rate is null or v_previous_rate is null then 'unavailable'
      when v_current_rate > v_previous_rate then 'improved'
      when v_current_rate < v_previous_rate then 'declined'
      else 'stable' end,
    trend_delta = case when v_report.is_first_partial_week
        or v_current_rate is null or v_previous_rate is null then null
      else v_current_rate - v_previous_rate end,
    comparability_reason = case when v_report.is_first_partial_week
        then 'first_partial_week'
      when v_current_rate is null then 'current_zero_scheduled'
      when v_previous_rate is null and not found then 'no_previous_final'
      when v_previous_rate is null then 'previous_zero_scheduled'
      else null end,
    metrics_policy_version = 2,
    refreshed_at = now()
  where r.id = v_report.id;

  select * into v_report from public.weekly_reports where id = v_report.id;
  return v_report;
end;
$$;

revoke all on function app_private.weekly_report_capped_rate(numeric, integer)
  from public, anon, authenticated;
revoke all on function app_private.weekly_report_flexible_activity(boolean, boolean)
  from public, anon, authenticated;
revoke all on function app_private.generate_or_refresh_weekly_report(uuid, date)
  from public, anon, authenticated;

-- Additive payload cutover.  Legacy completedCount/completionRate remain
-- bounded for the current mapper; WR-FLEX-2 will consume the new fields.
create or replace function app_private.weekly_report_payload(
  p_report_id uuid,
  p_user_id uuid
)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'schemaVersion', r.schema_version,
    'metricsPolicyVersion', r.metrics_policy_version,
    'contentVersion', r.content_version,
    'report', jsonb_build_object(
      'id', r.id, 'userId', r.user_id,
      'weekStartDate', r.week_start_date, 'weekEndDate', r.week_end_date,
      'timezoneId', r.timezone_name, 'status', r.status,
      'firstPartialWeek', r.is_first_partial_week,
      'scheduledCount', r.scheduled_count,
      'completedCount', r.completed_count,
      'completionRate', r.completion_rate,
      'completedRaw', r.completed_count_raw,
      'scheduledQuota', r.scheduled_count,
      'rawRatio', r.raw_completion_rate,
      'cappedRatio', r.capped_completion_rate,
      'dataQuality', r.metrics_data_quality,
      'bestDay', r.best_day, 'trendKind', r.trend_kind,
      'trendDelta', r.trend_delta,
      'comparabilityReason', r.comparability_reason,
      'schemaVersion', r.schema_version,
      'metricsPolicyVersion', r.metrics_policy_version,
      'contentVersion', r.content_version,
      'messageKeys', r.message_keys,
      'generatedAt', r.generated_at, 'refreshedAt', r.refreshed_at,
      'finalizedAt', r.finalized_at
    ),
    'days', coalesce((select jsonb_agg(jsonb_build_object(
      'date', d.local_date, 'scheduledCount', d.scheduled_count,
      'completedCount', d.completed_count, 'skippedCount', d.skipped_count,
      'completionRate', d.completion_rate, 'state', d.day_state
    ) order by d.local_date)
      from public.weekly_report_days d
      where d.report_id = r.id and d.user_id = p_user_id), '[]'::jsonb),
    'habits', coalesce((select jsonb_agg(jsonb_build_object(
      'habitId', h.habit_id, 'name', h.name, 'emoji', h.emoji,
      'type', h.habit_type, 'target', h.target_count, 'familyId', null,
      'schedule', h.schedule, 'scheduledCount', h.scheduled_count,
      'completedCount', h.completed_count, 'skippedCount', h.skipped_count,
      'completionRate', h.completion_rate,
      'completedRaw', h.completed_count_raw,
      'scheduledQuota', h.scheduled_count,
      'rawRatio', h.raw_completion_rate,
      'cappedRatio', h.capped_completion_rate,
      'dataQuality', h.metrics_data_quality,
      'classification', h.classification,
      'observationKey', h.observation_key,
      'occurrences', h.occurrences,
      'streakSnapshot', h.streak_snapshot
    ) order by h.name, h.habit_id)
      from public.weekly_report_habits h
      where h.report_id = r.id and h.user_id = p_user_id), '[]'::jsonb),
    'recommendations', coalesce((select jsonb_agg(jsonb_build_object(
      'type', n.recommendation_type, 'reason', n.reason_code,
      'habitId', n.habit_id, 'habitName', n.habit_name, 'emoji', n.habit_emoji,
      'currentConfig', n.current_config, 'proposedPatch', n.proposed_patch,
      'policyVersion', n.recommendation_policy_version
    ) order by n.created_at)
      from public.weekly_report_recommendations n
      where n.report_id = r.id and n.user_id = p_user_id
        and r.status = 'final' and n.status = 'proposed'), '[]'::jsonb)
  )
  from public.weekly_reports r
  where r.id = p_report_id and r.user_id = p_user_id
$$;

create or replace function public.list_my_weekly_reports(
  p_before_week_start date default null,
  p_limit integer default 20
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_limit integer := least(greatest(coalesce(p_limit, 20), 1), 50);
begin
  if v_user_id is null then raise exception 'authentication required'; end if;
  return coalesce((select jsonb_agg(jsonb_build_object(
    'reportId', x.id, 'weekStartDate', x.week_start_date,
    'weekEndDate', x.week_end_date, 'status', x.status,
    'completionRate', x.completion_rate,
    'completedCount', x.completed_count,
    'scheduledCount', x.scheduled_count,
    'completedRaw', x.completed_count_raw,
    'scheduledQuota', x.scheduled_count,
    'rawRatio', x.raw_completion_rate,
    'cappedRatio', x.capped_completion_rate,
    'dataQuality', x.metrics_data_quality,
    'firstPartialWeek', x.is_first_partial_week,
    'refreshedAt', x.refreshed_at, 'finalizedAt', x.finalized_at
  ) order by x.week_start_date desc, x.id desc) from (
    select r.* from public.weekly_reports r
    where r.user_id = v_user_id
      and (p_before_week_start is null
        or r.week_start_date < p_before_week_start)
    order by r.week_start_date desc, r.id desc
    limit v_limit
  ) x), '[]'::jsonb);
end;
$$;

revoke all on function app_private.weekly_report_payload(uuid, uuid)
  from public, anon, authenticated;
revoke all on function public.list_my_weekly_reports(date, integer)
  from public, anon;
grant execute on function public.list_my_weekly_reports(date, integer)
  to authenticated;

comment on column public.weekly_reports.completed_count is
  'Legacy bounded count retained for pre-WR-FLEX-2 clients.';
comment on column public.weekly_reports.completed_count_raw is
  'Canonical unbounded completed-day count for the report.';
comment on column public.weekly_report_habits.completed_count is
  'Legacy bounded count retained for pre-WR-FLEX-2 clients.';
comment on column public.weekly_report_habits.completed_count_raw is
  'Canonical unbounded completed-day count for the habit snapshot.';

commit;
