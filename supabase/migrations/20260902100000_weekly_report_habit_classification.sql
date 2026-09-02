begin;

-- Phase 8A: deterministic, versionable classification policy for habit snapshots.
create or replace function app_private.weekly_report_habit_classification(
  p_scheduled_count integer,
  p_completion_rate numeric
)
returns text
language sql
immutable
set search_path = ''
as $$
  select case
    when p_scheduled_count = 0 or p_completion_rate is null
      or p_completion_rate < 0 or p_completion_rate > 1 then 'unavailable'
    when p_completion_rate >= 0.80 then 'highlighted'
    when p_completion_rate < 0.50 then 'needs_attention'
    else 'stable'
  end
$$;

alter table public.weekly_report_habits
  add column if not exists classification text not null default 'unavailable';

alter table public.weekly_report_habits
  drop constraint if exists weekly_report_habits_classification_check;
alter table public.weekly_report_habits
  add constraint weekly_report_habits_classification_check
  check (classification in ('highlighted', 'stable', 'needs_attention', 'unavailable'));

-- The generator inserts fresh child snapshots on every refresh/finalization.
-- Computing at insert keeps classification inside the authoritative backend
-- boundary while the stored value remains protected by the existing final guard.
create or replace function app_private.weekly_report_habits_set_classification()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.classification := app_private.weekly_report_habit_classification(
    new.scheduled_count, new.completion_rate);
  return new;
end;
$$;

drop trigger if exists trg_weekly_report_habits_set_classification
  on public.weekly_report_habits;
create trigger trg_weekly_report_habits_set_classification
before insert on public.weekly_report_habits
for each row execute function app_private.weekly_report_habits_set_classification();

revoke all on function app_private.weekly_report_habit_classification(integer, numeric)
  from public, anon, authenticated;
revoke all on function app_private.weekly_report_habits_set_classification()
  from public, anon, authenticated;

comment on column public.weekly_report_habits.classification is
  'Phase 8A V1 snapshot classification: highlighted, stable, needs_attention, or unavailable.';

-- Additively replace the private builder so the public RPC signatures remain
-- unchanged while returning the authoritative snapshot order and field.
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
      'contentVersion', r.content_version, 'messageKeys', r.message_keys,
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
      'completionRate', h.completion_rate, 'classification', h.classification,
      'occurrences', h.occurrences, 'streakSnapshot', h.streak_snapshot
    ) order by case h.classification
      when 'highlighted' then 1 when 'stable' then 2
      when 'needs_attention' then 3 else 4 end,
      case when h.classification in ('highlighted', 'stable')
        then h.completion_rate end desc nulls last,
      case when h.classification = 'needs_attention'
        then h.completion_rate end asc nulls last,
      case when h.classification = 'needs_attention'
        then h.scheduled_count end desc nulls last,
      case when h.classification in ('highlighted', 'stable')
        then h.completed_count end desc nulls last,
      h.name asc, h.habit_id asc) from public.weekly_report_habits h
      where h.report_id = r.id and h.user_id = p_user_id), '[]'::jsonb),
    'recommendations', coalesce((select jsonb_agg(jsonb_build_object(
      'type', n.recommendation_type, 'reason', n.reason_code
    ) order by n.created_at) from public.weekly_report_recommendations n
      where n.report_id = r.id and n.user_id = p_user_id and n.status = 'proposed'), '[]'::jsonb)
  )
  from public.weekly_reports r
  where r.id = p_report_id and r.user_id = p_user_id
$$;

commit;
