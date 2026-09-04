begin;

do $$
declare
  v_source text;
begin
  perform 'app_private.generate_or_refresh_weekly_report(uuid,date)'::regprocedure;
  select prosrc into v_source
  from pg_proc
  where oid = 'app_private.generate_or_refresh_weekly_report(uuid,date)'::regprocedure;

  if v_source not like '%v_local_today := (now() at time zone%'
     or v_source not like '%d::date <= v_local_today%'
     or v_source not like '%l.log_date = v_day%' then
    raise exception 'live provisional generator must cap days at local today and read exact log dates';
  end if;

  -- Reproducible Friday fixture contract:
  -- week 2026-08-31..2026-09-06, local today 2026-09-04,
  -- completed logs on Thursday 2026-09-03 and Friday 2026-09-04.
  if v_source not like '%delete from public.weekly_report_days%'
     or v_source not like '%delete from public.weekly_report_habits%'
     or v_source not like '%if found and v_existing.status = ''final''%' then
    raise exception 'refresh must replace provisional children and preserve final snapshots';
  end if;
end;
$$;

rollback;
