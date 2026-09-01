begin;

do $$
declare
  v_source text;
  v_config text[];
begin
  perform 'app_private.generate_or_refresh_weekly_report(uuid,date)'::regprocedure;
  perform 'app_private.finalize_weekly_report(uuid,date)'::regprocedure;
  perform 'app_private.weekly_report_effective_config(uuid,uuid,timestamptz)'::regprocedure;
  perform 'app_private.weekly_report_week_bounds(date,text)'::regprocedure;
  perform 'app_private.weekly_report_prorated_quota(numeric,integer)'::regprocedure;

  select prosrc into v_source from pg_proc
  where oid = 'app_private.generate_or_refresh_weekly_report(uuid,date)'::regprocedure;
  if v_source not like '%source_updated_at desc nulls last%'
     or v_source not like '%effective_from%'
     or v_source not like '%timesPerWeek%'
     or v_source not like '%ceil(sum(e.configured_quota * e.eligible_days) / 7.0)%' then
    raise exception 'generator must use effective history and timesPerWeek';
  end if;

  select prosrc into v_source from pg_proc
  where oid = 'app_private.finalize_weekly_report(uuid,date)'::regprocedure;
  if v_source not like '%status = ''final''%'
     or v_source not like '%v_boundary%' then
    raise exception 'finalization must enforce local boundary and final transition';
  end if;

  select proconfig into v_config from pg_proc
  where oid = 'app_private.generate_or_refresh_weekly_report(uuid,date)'::regprocedure;
  if not ('search_path=""' = any(v_config)) then
    raise exception 'generator must pin search_path to empty';
  end if;

  if has_function_privilege('anon', 'app_private.generate_or_refresh_weekly_report(uuid,date)', 'execute')
     or has_function_privilege('authenticated', 'app_private.generate_or_refresh_weekly_report(uuid,date)', 'execute')
     or has_function_privilege('authenticated', 'app_private.finalize_weekly_report(uuid,date)', 'execute') then
    raise exception 'internal generator functions must not be client executable';
  end if;
end;
$$;

select app_private.weekly_report_schedule_matches('{"type":"daily"}'::jsonb, date '2026-09-01') as daily,
       app_private.weekly_report_schedule_matches('{"type":"weekly","weekdays":[1,3]}'::jsonb, date '2026-09-01') as weekly_hit,
       not app_private.weekly_report_schedule_matches('{"type":"weekly","weekdays":[1,3]}'::jsonb, date '2026-09-02') as weekly_miss,
       app_private.weekly_report_schedule_matches('{"type":"once","date":"2026-09-01"}'::jsonb, date '2026-09-01') as once_exact;

select app_private.weekly_report_prorated_quota(3, 0) = 0 as quota_3_0,
       app_private.weekly_report_prorated_quota(3, 1) = 1 as quota_3_1,
       app_private.weekly_report_prorated_quota(3, 2) = 1 as quota_3_2,
       app_private.weekly_report_prorated_quota(3, 3) = 2 as quota_3_3,
       app_private.weekly_report_prorated_quota(3, 7) = 3 as quota_3_7,
       app_private.weekly_report_prorated_quota(7, 4) = 4 as quota_7_4,
       app_private.weekly_report_prorated_quota(1, 1) = 1 as quota_1_1;

-- Midweek weighted-quota contract: one weekly rounding operation.
select ceil((3 * 7) / 7.0) = 3 as constant_3_full,
       ceil((3 * 4) / 7.0) = 2 as constant_3_partial,
       ceil((5 * 3 + 3 * 4) / 7.0) = 4 as mon_wed_5_thu_sun_3,
       ceil((3 * 1 + 3 * 1 + 3 * 1 + 3 * 1 + 3 * 1 + 3 * 1 + 3 * 1) / 7.0) = 3 as seven_segments_3,
       ceil((1 * 1 + 7 * 6) / 7.0) = 7 as mon_1_tue_sun_7,
       ceil((3 * 2 + 3 * 5) / 7.0) = 3 as non_schedule_config_change;

rollback;
