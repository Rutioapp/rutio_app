begin;

-- Live provisional reports are evaluated only through the current local day.
-- This forward migration keeps final snapshots immutable while allowing the
-- public current-week refresh boundary to be used from Monday through Sunday.
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
begin
  select * into v_activation
  from public.weekly_report_activations
  where user_id = p_user_id;
  if not found then raise exception 'weekly report is not activated'; end if;

  select * into v_bounds
  from app_private.weekly_report_week_bounds(p_week_start_date, v_activation.timezone_name);
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
    eligible boolean not null,
    scheduled_count integer not null default 0,
    completed_count integer not null default 0,
    skipped_count integer not null default 0
  ) on commit drop;
  truncate pg_temp.wr_days;
  insert into pg_temp.wr_days(local_date, eligible)
  select d::date,
    d::date >= v_activation.activation_local_date
      and d::date <= v_local_today
  from generate_series(p_week_start_date, p_week_start_date + 6, interval '1 day') d;

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
    where c.user_id = p_user_id and c.effective_from < v_bounds.end_instant
  loop
    for v_day in select local_date from pg_temp.wr_days order by local_date loop
      select * into v_cfg
      from app_private.weekly_report_effective_config(
        p_user_id, v_habit_id,
        ((v_day + 1)::timestamp at time zone v_activation.timezone_name)
      );
      if not found or not exists (
        select 1 from pg_temp.wr_days where local_date = v_day and eligible
      ) or v_cfg.effective_local_date > v_day or v_cfg.is_archived then
        continue;
      end if;

      select * into v_log
      from public.habit_logs l
      where l.user_id = p_user_id and l.habit_id = v_habit_id and l.log_date = v_day;
      if not found then
        v_log.is_completed := false; v_log.is_skipped := false; v_log.value := 0;
      end if;
      v_skipped := coalesce(v_log.is_skipped, false);
      v_completed := case when v_cfg.habit_type = 'count'
        then coalesce(v_log.value, 0) >= coalesce(v_cfg.target_count, 1)
        else coalesce(v_log.is_completed, false)
      end;
      v_completed := v_completed and not v_skipped;
      v_scheduled := case when v_cfg.schedule->>'type' = 'timesPerWeek'
        then false else app_private.weekly_report_schedule_matches(v_cfg.schedule, v_day) end;

      insert into pg_temp.wr_occurrences
        (habit_id, local_date, config_id, habit_type, name, emoji, target_count,
         schedule, scheduled, completed, skipped, progress)
      values (v_habit_id, v_day, v_cfg.id, v_cfg.habit_type, v_cfg.name, v_cfg.emoji,
              v_cfg.target_count, v_cfg.schedule, v_scheduled, v_completed,
              case when v_scheduled then v_skipped else false end, v_log.value)
      on conflict (habit_id, local_date) do update set
        config_id = excluded.config_id, habit_type = excluded.habit_type,
        name = excluded.name, emoji = excluded.emoji, target_count = excluded.target_count,
        schedule = excluded.schedule, scheduled = excluded.scheduled,
        completed = excluded.completed, skipped = excluded.skipped,
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
    from pg_temp.wr_occurrences group by local_date
  ) x where x.local_date = d.local_date;

  create temporary table if not exists pg_temp.wr_habits (
    habit_id uuid primary key, name text not null, emoji text, habit_type text not null,
    target_count numeric, schedule jsonb not null, scheduled_count integer not null,
    completed_count integer not null, skipped_count integer not null, occurrences jsonb not null
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
    least(count(*) filter (where o.scheduled and o.completed)::int
      + least(count(*) filter (where not o.scheduled and o.completed)::int,
              coalesce(q.weekly_quota, 0)),
          count(*) filter (where o.scheduled)::int + coalesce(q.weekly_quota, 0)),
    count(*) filter (where o.scheduled and o.skipped)::int,
    jsonb_agg(jsonb_build_object(
      'date', o.local_date::text,
      'scope', case when o.schedule->>'type' = 'timesPerWeek' then 'weeklyQuota' else 'date' end,
      'scheduleType', o.schedule->>'type',
      'scheduled', o.scheduled,
      'completed', o.completed,
      'skipped', o.skipped,
      'progress', o.progress,
      'target', o.target_count,
      'weeklyQuota', case when o.schedule->>'type' = 'timesPerWeek'
        then (o.schedule->>'timesPerWeek')::int else null end
    ) order by o.local_date)
  from pg_temp.wr_occurrences o
  left join lateral (
    -- One rounding operation for the whole eligible window. Rounding each
    -- config segment independently would inflate a flexible weekly quota.
    select ceil(sum(e.configured_quota * e.eligible_days) / 7.0)::int weekly_quota
    from (
      select config_id, schedule,
        (schedule->>'timesPerWeek')::numeric configured_quota,
        count(*)::int eligible_days
      from pg_temp.wr_occurrences s
      where s.habit_id = o.habit_id and s.schedule->>'type' = 'timesPerWeek'
      group by config_id, schedule, (schedule->>'timesPerWeek')::numeric
    ) e
  ) q on true
  group by o.habit_id, q.weekly_quota;

  insert into public.weekly_reports
    (user_id, week_start_date, week_end_date, timezone_name, is_first_partial_week,
     scheduled_count, completed_count, completion_rate, generated_at, refreshed_at)
  values (p_user_id, p_week_start_date, v_bounds.week_end_date, v_activation.timezone_name,
    v_activation.activation_local_date > p_week_start_date,
    (select coalesce(sum(scheduled_count), 0) from pg_temp.wr_days)
      + (select coalesce(sum(h.scheduled_count - coalesce(x.date_scheduled, 0)), 0)
         from pg_temp.wr_habits h left join (
           select habit_id, count(*) filter (where scheduled)::int date_scheduled
           from pg_temp.wr_occurrences group by habit_id
         ) x on x.habit_id = h.habit_id),
    (select coalesce(sum(completed_count), 0) from pg_temp.wr_days)
      + (select coalesce(sum(h.completed_count - coalesce(x.date_completed, 0)), 0)
         from pg_temp.wr_habits h left join (
           select habit_id, count(*) filter (where scheduled and completed)::int date_completed
           from pg_temp.wr_occurrences group by habit_id
         ) x on x.habit_id = h.habit_id),
    case when (
      (select coalesce(sum(scheduled_count), 0) from pg_temp.wr_days)
      + (select coalesce(sum(h.scheduled_count - coalesce(x.date_scheduled, 0)), 0)
         from pg_temp.wr_habits h left join (
           select habit_id, count(*) filter (where scheduled)::int date_scheduled
           from pg_temp.wr_occurrences group by habit_id
         ) x on x.habit_id = h.habit_id)
    ) = 0 then null else 0 end, now(), now())
  on conflict (user_id, week_start_date) do update set
    week_end_date = excluded.week_end_date, timezone_name = excluded.timezone_name,
    is_first_partial_week = excluded.is_first_partial_week,
    scheduled_count = excluded.scheduled_count, completed_count = excluded.completed_count,
    completion_rate = excluded.completion_rate, refreshed_at = now();

  select * into v_report from public.weekly_reports
  where user_id = p_user_id and week_start_date = p_week_start_date for update;

  delete from public.weekly_report_days where report_id = v_report.id;
  delete from public.weekly_report_habits where report_id = v_report.id;

  insert into public.weekly_report_days
    (report_id, user_id, local_date, scheduled_count, completed_count, skipped_count,
     completion_rate, day_state)
  select v_report.id, p_user_id, local_date, scheduled_count, completed_count, skipped_count,
    case when scheduled_count = 0 then null else completed_count::numeric / scheduled_count end,
    case when not eligible or scheduled_count = 0 then 'noPlan'
      when skipped_count > 0 and completed_count = 0 then 'skipped'
      when completed_count = scheduled_count then 'completed'
      when completed_count > 0 then 'partial' else 'scheduledIncomplete' end
  from pg_temp.wr_days;

  insert into public.weekly_report_habits
    (report_id, user_id, habit_id, name, emoji, habit_type, target_count, schedule,
     scheduled_count, completed_count, skipped_count, completion_rate, occurrences)
  select v_report.id, p_user_id, habit_id::text, name, emoji, habit_type, target_count, schedule,
    scheduled_count, completed_count, skipped_count,
    case when scheduled_count = 0 then null else completed_count::numeric / scheduled_count end,
    occurrences
  from pg_temp.wr_habits;

  select * into v_previous from public.weekly_reports p
  where p.user_id = p_user_id and p.status = 'final' and p.week_start_date < p_week_start_date
  order by p.week_start_date desc limit 1;
  v_current_rate := case when v_report.scheduled_count = 0 then null
    else v_report.completed_count::numeric / v_report.scheduled_count end;
  v_previous_rate := case when not found or v_previous.scheduled_count = 0 then null
    else v_previous.completed_count::numeric / v_previous.scheduled_count end;

  update public.weekly_reports r set
    completion_rate = v_current_rate,
    best_day = (select local_date from pg_temp.wr_days where scheduled_count > 0
      order by completed_count::numeric / scheduled_count desc, completed_count desc, local_date limit 1),
    previous_report_id = case when v_previous_rate is null then null else v_previous.id end,
    trend_kind = case when v_report.is_first_partial_week or v_current_rate is null
        or v_previous_rate is null then 'unavailable'
      when v_current_rate > v_previous_rate then 'improved'
      when v_current_rate < v_previous_rate then 'declined' else 'stable' end,
    trend_delta = case when v_report.is_first_partial_week or v_current_rate is null
        or v_previous_rate is null then null else v_current_rate - v_previous_rate end,
    comparability_reason = case when v_report.is_first_partial_week then 'first_partial_week'
      when v_current_rate is null then 'current_zero_scheduled'
      when v_previous_rate is null and not found then 'no_previous_final'
      when v_previous_rate is null then 'previous_zero_scheduled'
      else null end,
    refreshed_at = now()
  where r.id = v_report.id;
  select * into v_report from public.weekly_reports where id = v_report.id;
  return v_report;
end;
$$;

revoke all on function app_private.generate_or_refresh_weekly_report(uuid, date)
  from public, anon, authenticated;

comment on function app_private.generate_or_refresh_weekly_report(uuid, date) is
  'Authoritative transactional generator. Provisional snapshots include eligible logs through the current local date; final snapshots are immutable.';

commit;
