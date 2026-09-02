begin;

do $$
declare
  v_guard text := pg_get_functiondef(
    'app_private.weekly_report_guard_final_child()'::regprocedure);
  v_trigger text;
begin
  if app_private.weekly_report_habit_classification(5, 1.00) <> 'highlighted'
     or app_private.weekly_report_habit_classification(5, .80) <> 'highlighted'
     or app_private.weekly_report_habit_classification(5, .79) <> 'stable'
     or app_private.weekly_report_habit_classification(5, .50) <> 'stable'
     or app_private.weekly_report_habit_classification(5, .49) <> 'needs_attention'
     or app_private.weekly_report_habit_classification(5, .00) <> 'needs_attention'
     or app_private.weekly_report_habit_classification(0, null) <> 'unavailable'
     or app_private.weekly_report_habit_classification(5, null) <> 'unavailable' then
    raise exception 'classification V1 thresholds changed';
  end if;

  -- Legacy row contract: scheduled=5, rate=1, stale unavailable -> highlighted.
  if app_private.weekly_report_habit_classification(5, 1) <> 'highlighted' then
    raise exception 'legacy unavailable classification must backfill to highlighted';
  end if;

  select pg_get_triggerdef(oid) into v_trigger
  from pg_trigger
  where tgname = 'trg_weekly_report_habits_guard_final'
    and tgrelid = 'public.weekly_report_habits'::regclass
    and not tgisinternal;
  if v_trigger is null
     or v_trigger not like '%BEFORE INSERT OR DELETE OR UPDATE%'
     or v_trigger not like '%weekly_report_guard_final_child%' then
    raise exception 'weekly report habit final guard must remain installed';
  end if;
  if v_guard not like '%children of final weekly reports are immutable%' then
    raise exception 'final child immutability guard changed';
  end if;
  if has_table_privilege('authenticated', 'public.weekly_report_habits', 'UPDATE')
     or has_table_privilege('authenticated', 'public.weekly_report_habits', 'DELETE')
     or has_table_privilege('authenticated', 'public.weekly_report_habits', 'INSERT') then
    raise exception 'authenticated must not mutate weekly report habit snapshots';
  end if;
end;
$$;

rollback;
