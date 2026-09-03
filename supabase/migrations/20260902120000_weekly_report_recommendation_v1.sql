begin;

-- Phase 8B: the recommendation is historical snapshot data.  The existing
-- final-child guard protects these columns together with the other children.
alter table public.weekly_report_recommendations
  add column if not exists habit_name text,
  add column if not exists habit_emoji text,
  add column if not exists habit_type text,
  add column if not exists current_config jsonb,
  add column if not exists recommendation_policy_version integer not null default 1;

alter table public.weekly_report_recommendations
  drop constraint if exists weekly_report_recommendations_type_check,
  drop constraint if exists weekly_report_recommendations_policy_check,
  drop constraint if exists weekly_report_recommendations_config_check;
alter table public.weekly_report_recommendations
  add constraint weekly_report_recommendations_type_check
    check (recommendation_type in ('reduceFrequency')),
  add constraint weekly_report_recommendations_policy_check
    check (recommendation_policy_version = 1),
  add constraint weekly_report_recommendations_config_check check (
    current_config is not null
    and jsonb_typeof(current_config) = 'object'
    and jsonb_typeof(proposed_patch) = 'object'
    and proposed_patch->>'version' = '1'
    and proposed_patch->>'type' = 'reduceFrequency'
    and jsonb_typeof(proposed_patch->'current'->'schedule') = 'object'
    and jsonb_typeof(proposed_patch->'proposed'->'schedule') = 'object'
    and (proposed_patch->'proposed'->'schedule'->>'type') = 'timesPerWeek'
    and ((proposed_patch->'proposed'->'schedule'->>'timesPerWeek')::int between 1 and 6)
  );

create unique index if not exists weekly_report_one_proposed_recommendation
  on public.weekly_report_recommendations (report_id)
  where status = 'proposed';

-- The project keeps the generator body in the preceding migration. This
-- migration is intentionally additive; recommendation generation is attached
-- by the companion trigger below to the same authoritative child insertion.
-- Trigger table: weekly_reports. Event: AFTER UPDATE of refreshed_at or
-- completion_rate. NEW is public.weekly_reports, so its key is NEW.id.
create or replace function app_private.weekly_report_recommendation_from_snapshot()
returns trigger language plpgsql security definer set search_path = '' as $$
declare r public.weekly_reports%rowtype; h public.weekly_report_habits%rowtype;
begin
  r := new;
  if r.status = 'provisional' and r.is_first_partial_week then
    delete from public.weekly_report_recommendations where report_id = r.id and status = 'proposed';
    return new;
  end if;
  if r.status = 'final' then return new; end if;
  delete from public.weekly_report_recommendations where report_id = r.id and status = 'proposed';
  select * into h from public.weekly_report_habits x
   where x.report_id = new.id
     and x.user_id = r.user_id
     and x.classification = 'needs_attention'
     and x.scheduled_count > 0
     and x.schedule->>'type' = 'timesPerWeek'
     and (x.schedule->>'timesPerWeek')::int >= 2
   order by x.completion_rate asc nulls last,
            x.scheduled_count desc,
            x.habit_id asc
   limit 1;
  if not found then return new; end if;
  insert into public.weekly_report_recommendations
    (report_id, user_id, habit_id, habit_name, habit_emoji, habit_type,
     recommendation_type, reason_code, current_config, proposed_patch)
  values (
    h.report_id, r.user_id, h.habit_id, h.name, h.emoji, h.habit_type,
    'reduceFrequency',
    'weekly_report_recommendation_reduce_frequency_v1',
    jsonb_build_object(
      'schedule', h.schedule,
      'target', h.target_count,
      'habitType', h.habit_type
    ),
    jsonb_build_object(
      'version', 1,
      'type', 'reduceFrequency',
      'current', jsonb_build_object('schedule', h.schedule),
      'proposed', jsonb_build_object(
        'schedule', jsonb_build_object(
          'type', 'timesPerWeek',
          'timesPerWeek', (h.schedule->>'timesPerWeek')::int - 1,
          'weekStartsOn', coalesce((h.schedule->>'weekStartsOn')::int, 1)
        )
      )
    )
  );
  return new;
end; $$;

drop trigger if exists trg_weekly_report_recommendation_from_snapshot on public.weekly_reports;
create trigger trg_weekly_report_recommendation_from_snapshot
after update of refreshed_at, completion_rate on public.weekly_reports
for each row execute function app_private.weekly_report_recommendation_from_snapshot();

revoke all on function app_private.weekly_report_recommendation_from_snapshot() from public, anon, authenticated;

-- The payload exposes only final recommendations. Provisional refreshes may
-- calculate a candidate internally but never present it as actionable.
create or replace function app_private.weekly_report_payload(p_report_id uuid, p_user_id uuid)
returns jsonb language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'schemaVersion', r.schema_version, 'metricsPolicyVersion', r.metrics_policy_version,
    'contentVersion', r.content_version,
    'report', jsonb_build_object('id', r.id, 'userId', r.user_id, 'weekStartDate', r.week_start_date,
      'weekEndDate', r.week_end_date, 'timezoneId', r.timezone_name, 'status', r.status,
      'firstPartialWeek', r.is_first_partial_week, 'scheduledCount', r.scheduled_count,
      'completedCount', r.completed_count, 'completionRate', r.completion_rate, 'bestDay', r.best_day,
      'trendKind', r.trend_kind, 'trendDelta', r.trend_delta, 'comparabilityReason', r.comparability_reason,
      'schemaVersion', r.schema_version, 'metricsPolicyVersion', r.metrics_policy_version,
      'contentVersion', r.content_version, 'messageKeys', r.message_keys,
      'generatedAt', r.generated_at, 'refreshedAt', r.refreshed_at, 'finalizedAt', r.finalized_at),
    'days', coalesce((select jsonb_agg(jsonb_build_object('date', d.local_date, 'scheduledCount', d.scheduled_count,
      'completedCount', d.completed_count, 'skippedCount', d.skipped_count, 'completionRate', d.completion_rate, 'state', d.day_state) order by d.local_date)
      from public.weekly_report_days d where d.report_id = r.id and d.user_id = p_user_id), '[]'::jsonb),
    'habits', coalesce((select jsonb_agg(jsonb_build_object('habitId', h.habit_id, 'name', h.name, 'emoji', h.emoji,
      'type', h.habit_type, 'target', h.target_count, 'familyId', null, 'schedule', h.schedule,
      'scheduledCount', h.scheduled_count, 'completedCount', h.completed_count, 'skippedCount', h.skipped_count,
      'completionRate', h.completion_rate, 'occurrences', h.occurrences, 'streakSnapshot', h.streak_snapshot)
      order by h.name, h.habit_id) from public.weekly_report_habits h where h.report_id = r.id and h.user_id = p_user_id), '[]'::jsonb),
    'recommendations', coalesce((select jsonb_agg(jsonb_build_object('type', n.recommendation_type,
      'reason', n.reason_code, 'habitId', n.habit_id, 'habitName', n.habit_name, 'emoji', n.habit_emoji,
      'currentConfig', n.current_config, 'proposedPatch', n.proposed_patch,
      'policyVersion', n.recommendation_policy_version) order by n.created_at)
      from public.weekly_report_recommendations n where n.report_id = r.id and n.user_id = p_user_id
        and r.status = 'final' and n.status = 'proposed'), '[]'::jsonb)
  ) from public.weekly_reports r where r.id = p_report_id and r.user_id = p_user_id
$$;

commit;
