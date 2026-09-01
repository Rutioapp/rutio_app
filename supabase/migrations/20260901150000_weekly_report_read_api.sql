begin;

-- Phase 5: owner-scoped read/refresh boundary. Snapshot tables remain private.
-- Final snapshots (status = 'final') are never downgraded by this boundary.
create or replace function app_private.weekly_report_payload(p_report_id uuid, p_user_id uuid)
returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'schemaVersion', r.schema_version,
    'metricsPolicyVersion', r.metrics_policy_version,
    'contentVersion', r.content_version,
    'report', jsonb_build_object(
      'id', r.id, 'userId', r.user_id, 'weekStartDate', r.week_start_date,
      'weekEndDate', r.week_end_date, 'timezoneId', r.timezone_name,
      'status', r.status, 'firstPartialWeek', r.is_first_partial_week,
      'scheduledCount', r.scheduled_count, 'completedCount', r.completed_count,
      'completionRate', r.completion_rate, 'bestDay', r.best_day,
      'trendKind', r.trend_kind, 'trendDelta', r.trend_delta,
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
    ) order by d.local_date) from public.weekly_report_days d
      where d.report_id = r.id and d.user_id = p_user_id), '[]'::jsonb),
    'habits', coalesce((select jsonb_agg(jsonb_build_object(
      'habitId', h.habit_id, 'name', h.name, 'emoji', h.emoji,
      'type', h.habit_type, 'target', h.target_count, 'familyId', null,
      'schedule', h.schedule, 'scheduledCount', h.scheduled_count,
      'completedCount', h.completed_count, 'skippedCount', h.skipped_count,
      'completionRate', h.completion_rate, 'occurrences', h.occurrences,
      'streakSnapshot', h.streak_snapshot
    ) order by h.name, h.habit_id) from public.weekly_report_habits h
      where h.report_id = r.id and h.user_id = p_user_id), '[]'::jsonb),
    'recommendations', coalesce((select jsonb_agg(jsonb_build_object(
      'type', n.recommendation_type, 'reason', n.reason_code
    ) order by n.created_at) from public.weekly_report_recommendations n
      where n.report_id = r.id and n.user_id = p_user_id and n.status = 'proposed'), '[]'::jsonb)
  )
  from public.weekly_reports r
  where r.id = p_report_id and r.user_id = p_user_id
$$;

create or replace function public.get_my_weekly_report(p_report_id uuid)
returns jsonb language plpgsql stable security definer set search_path = ''
as $$
declare v_user_id uuid := auth.uid(); v_payload jsonb;
begin
  if v_user_id is null then raise exception 'authentication required'; end if;
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
  select r.id into v_report_id from public.weekly_reports r
  where r.user_id = v_user_id
  order by case when r.status = 'provisional' then 0 else 1 end,
           r.week_start_date desc, r.updated_at desc, r.id desc limit 1;
  return app_private.weekly_report_payload(v_report_id, v_user_id);
end;
$$;

create or replace function public.list_my_weekly_reports(
  p_before_week_start date default null, p_limit integer default 20
)
returns jsonb language plpgsql stable security definer set search_path = ''
as $$
declare v_user_id uuid := auth.uid(); v_limit integer := least(greatest(coalesce(p_limit, 20), 1), 50);
begin
  if v_user_id is null then raise exception 'authentication required'; end if;
  return coalesce((select jsonb_agg(jsonb_build_object(
    'reportId', r.id, 'weekStartDate', r.week_start_date, 'weekEndDate', r.week_end_date,
    'status', r.status, 'completionRate', r.completion_rate,
    'completedCount', r.completed_count, 'scheduledCount', r.scheduled_count,
    'firstPartialWeek', r.is_first_partial_week,
    'refreshedAt', r.refreshed_at, 'finalizedAt', r.finalized_at
  ) order by x.week_start_date desc, x.id desc) from (
    select r.* from public.weekly_reports r
    where r.user_id = v_user_id
      and (p_before_week_start is null or r.week_start_date < p_before_week_start)
    order by r.week_start_date desc, r.id desc
    limit v_limit
  ) x), '[]'::jsonb);
end;
$$;

create or replace function public.refresh_my_weekly_report(p_week_start_date date)
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare v_user_id uuid := auth.uid(); v_activation public.weekly_report_activations%rowtype; v_report public.weekly_reports%rowtype;
begin
  if v_user_id is null then raise exception 'authentication required'; end if;
  select * into v_activation from public.weekly_report_activations where user_id = v_user_id;
  if not found then raise exception 'weekly report is not activated'; end if;
  if p_week_start_date <> ((now() at time zone v_activation.timezone_name)::date
      - (extract(isodow from (now() at time zone v_activation.timezone_name)::date)::int - 1))
  then raise exception 'only the current eligible week may be refreshed'; end if;
  v_report := app_private.generate_or_refresh_weekly_report(v_user_id, p_week_start_date);
  return app_private.weekly_report_payload(v_report.id, v_user_id);
end;
$$;

revoke all on function app_private.weekly_report_payload(uuid, uuid) from public, anon, authenticated;
revoke all on function public.get_my_weekly_report(uuid), public.get_my_latest_weekly_report(), public.list_my_weekly_reports(date, integer), public.refresh_my_weekly_report(date) from public, anon;
grant execute on function public.get_my_weekly_report(uuid), public.get_my_latest_weekly_report(), public.list_my_weekly_reports(date, integer), public.refresh_my_weekly_report(date) to authenticated;

comment on function public.get_my_weekly_report(uuid) is 'Owner-scoped, versioned Weekly Report payload; future entitlement shaping belongs here.';
comment on function public.refresh_my_weekly_report(date) is 'Owner-scoped provisional refresh boundary; final snapshots remain immutable.';

commit;
