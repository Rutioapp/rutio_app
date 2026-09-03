begin;

-- Phase 10: keys are the snapshot contract; localized text stays in Flutter.
create table if not exists app_private.weekly_report_copy_catalog (
  message_key text primary key,
  family text not null,
  content_version integer not null,
  sort_order integer not null,
  constraint weekly_report_copy_catalog_key_check check (btrim(message_key) <> ''),
  constraint weekly_report_copy_catalog_version_check check (content_version > 0)
);

insert into app_private.weekly_report_copy_catalog
  (message_key, family, content_version, sort_order)
select 'weekly_report_' || f.family_key || '_' || lpad(v.n::text, 2, '0'),
       f.family, 1, v.n
from (values
 ('summary_first_partial','summary_first_partial'),
 ('summary_provisional','summary_provisional'),
 ('summary_no_schedule','summary_no_schedule'),
 ('summary_strong','summary_strong'), ('summary_good','summary_good'),
 ('summary_mixed','summary_mixed'), ('summary_needs_recovery','summary_needs_recovery'),
 ('summary_improved','summary_improved'), ('summary_declined','summary_declined'),
 ('habit_highlighted','habit_highlighted'), ('habit_stable','habit_stable'),
 ('habit_needs_attention','habit_needs_attention')) as f(family_key, family)
cross join lateral generate_series(1, 5) as v(n)
on conflict (message_key) do nothing;

revoke all on app_private.weekly_report_copy_catalog from public, anon, authenticated;

alter table public.weekly_report_habits
  add column if not exists observation_key text null;

create or replace function app_private.weekly_report_summary_family(
  p_status text, p_first_partial boolean, p_scheduled integer,
  p_rate numeric, p_trend text
) returns text language sql immutable set search_path = '' as $$
  select case
    when p_scheduled = 0 then 'summary_no_schedule'
    when p_first_partial then 'summary_first_partial'
    when p_status = 'provisional' then 'summary_provisional'
    when p_trend = 'improved' and coalesce(p_rate, 0) < .80 then 'summary_improved'
    when p_trend = 'declined' and coalesce(p_rate, 0) >= .80 then 'summary_strong'
    when p_rate >= .80 then 'summary_strong'
    when p_rate >= .60 then 'summary_good'
    when p_rate >= .40 then 'summary_mixed'
    else 'summary_needs_recovery'
  end
$$;

create or replace function app_private.weekly_report_pick_copy_key(
  p_user_id uuid, p_week_start date, p_family text, p_content_version integer,
  p_habit_id text default null
) returns text language plpgsql stable security definer set search_path = '' as $$
declare v_key text; v_seed text;
begin
  v_seed := p_user_id::text || ':' || p_week_start::text || ':' || p_family || ':' || p_content_version::text || ':' || coalesce(p_habit_id,'');
  select c.message_key into v_key
  from app_private.weekly_report_copy_catalog c
  where c.family = p_family and c.content_version = p_content_version
    and not exists (
      select 1 from public.weekly_reports r
      where r.user_id = p_user_id and r.status = 'final'
        and r.week_start_date < p_week_start
        and (r.message_keys @> jsonb_build_array(c.message_key)
          or (p_habit_id is not null and exists (
            select 1 from public.weekly_report_habits h
            where h.report_id = r.id and h.habit_id = p_habit_id
              and h.observation_key = c.message_key)))
      order by r.week_start_date desc limit 4
    )
  order by md5(v_seed || ':' || c.sort_order), c.sort_order limit 1;
  if v_key is null then
    select c.message_key into v_key from app_private.weekly_report_copy_catalog c
    where c.family = p_family and c.content_version = p_content_version
    order by md5(v_seed || ':' || c.sort_order), c.sort_order limit 1;
  end if;
  return v_key;
end;
$$;

create or replace function app_private.weekly_report_set_summary_copy()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_family text; v_key text;
begin
  v_family := app_private.weekly_report_summary_family(new.status,new.is_first_partial_week,new.scheduled_count,new.completion_rate,new.trend_kind);
  v_key := app_private.weekly_report_pick_copy_key(new.user_id,new.week_start_date,v_family,new.content_version);
  new.message_keys := case when v_key is null then '[]'::jsonb else jsonb_build_array(v_key) end;
  return new;
end;
$$;

create or replace function app_private.weekly_report_set_habit_observation()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_family text;
begin
  v_family := case new.classification
    when 'highlighted' then 'habit_highlighted'
    when 'stable' then 'habit_stable'
    when 'needs_attention' then 'habit_needs_attention'
    else null end;
  new.observation_key := case when v_family is null then null else
    app_private.weekly_report_pick_copy_key(
      new.user_id, (select week_start_date from public.weekly_reports where id = new.report_id),
      v_family, (select content_version from public.weekly_reports where id = new.report_id), new.habit_id) end;
  return new;
end;
$$;

drop trigger if exists trg_weekly_report_set_summary_copy on public.weekly_reports;
create trigger trg_weekly_report_set_summary_copy
before insert or update of status, is_first_partial_week, scheduled_count, completion_rate, trend_kind
on public.weekly_reports for each row execute function app_private.weekly_report_set_summary_copy();
drop trigger if exists trg_weekly_report_set_habit_observation on public.weekly_report_habits;
create trigger trg_weekly_report_set_habit_observation
before insert or update of classification, scheduled_count, completion_rate
on public.weekly_report_habits for each row execute function app_private.weekly_report_set_habit_observation();

-- Re-declare only the private read builder so the public RPC signatures remain unchanged.
create or replace function app_private.weekly_report_payload(p_report_id uuid, p_user_id uuid)
returns jsonb language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'schemaVersion', r.schema_version, 'metricsPolicyVersion', r.metrics_policy_version, 'contentVersion', r.content_version,
    'report', jsonb_build_object('id',r.id,'userId',r.user_id,'weekStartDate',r.week_start_date,'weekEndDate',r.week_end_date,'timezoneId',r.timezone_name,'status',r.status,'firstPartialWeek',r.is_first_partial_week,'scheduledCount',r.scheduled_count,'completedCount',r.completed_count,'completionRate',r.completion_rate,'bestDay',r.best_day,'trendKind',r.trend_kind,'trendDelta',r.trend_delta,'comparabilityReason',r.comparability_reason,'schemaVersion',r.schema_version,'metricsPolicyVersion',r.metrics_policy_version,'contentVersion',r.content_version,'messageKeys',r.message_keys,'generatedAt',r.generated_at,'refreshedAt',r.refreshed_at,'finalizedAt',r.finalized_at),
    'days', coalesce((select jsonb_agg(jsonb_build_object('date',d.local_date,'scheduledCount',d.scheduled_count,'completedCount',d.completed_count,'skippedCount',d.skipped_count,'completionRate',d.completion_rate,'state',d.day_state) order by d.local_date) from public.weekly_report_days d where d.report_id=r.id and d.user_id=p_user_id),'[]'::jsonb),
    'habits', coalesce((select jsonb_agg(jsonb_build_object('habitId',h.habit_id,'name',h.name,'emoji',h.emoji,'type',h.habit_type,'target',h.target_count,'familyId',null,'schedule',h.schedule,'scheduledCount',h.scheduled_count,'completedCount',h.completed_count,'skippedCount',h.skipped_count,'completionRate',h.completion_rate,'classification',h.classification,'observationKey',h.observation_key,'occurrences',h.occurrences,'streakSnapshot',h.streak_snapshot) order by h.name,h.habit_id) from public.weekly_report_habits h where h.report_id=r.id and h.user_id=p_user_id),'[]'::jsonb),
    'recommendations', coalesce((select jsonb_agg(jsonb_build_object('type',n.recommendation_type,'reason',n.reason_code,'habitId',n.habit_id,'habitName',n.habit_name,'emoji',n.habit_emoji,'currentConfig',n.current_config,'proposedPatch',n.proposed_patch,'policyVersion',n.recommendation_policy_version) order by n.created_at) from public.weekly_report_recommendations n where n.report_id=r.id and n.user_id=p_user_id and r.status='final' and n.status='proposed'),'[]'::jsonb)
  ) from public.weekly_reports r where r.id=p_report_id and r.user_id=p_user_id
$$;

revoke all on function app_private.weekly_report_pick_copy_key(uuid,date,text,integer,text) from public,anon,authenticated;
revoke all on function app_private.weekly_report_summary_family(text,boolean,integer,numeric,text) from public,anon,authenticated;
revoke all on function app_private.weekly_report_set_summary_copy() from public,anon,authenticated;
revoke all on function app_private.weekly_report_set_habit_observation() from public,anon,authenticated;
comment on column public.weekly_report_habits.observation_key is 'Phase 10 localized snapshot key; null for unavailable classification.';

commit;
