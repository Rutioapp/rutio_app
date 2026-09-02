begin;

-- Repair classification values already persisted by
-- 20260902100000_weekly_report_habit_classification.sql.  The metrics in the
-- child snapshot are authoritative; live habits, stats, and occurrences are
-- intentionally not consulted.
--
-- The child immutability trigger is removed only after taking an
-- ACCESS EXCLUSIVE lock and only inside this transaction.  It is recreated
-- before commit, so this deterministic migration-only repair does not create
-- a product/client path for editing final snapshots.
lock table public.weekly_report_habits in access exclusive mode;

do $$
declare
  v_provisional bigint;
  v_final bigint;
  v_affected bigint;
begin
  select count(*) filter (where r.status = 'provisional'),
         count(*) filter (where r.status = 'final'),
         count(*)
    into v_provisional, v_final, v_affected
  from public.weekly_report_habits h
  join public.weekly_reports r on r.id = h.report_id
  where h.classification is distinct from
    app_private.weekly_report_habit_classification(
      h.scheduled_count, h.completion_rate);

  raise notice 'weekly report classification backfill: provisional rows affected = %, final rows affected = %, total rows affected = %',
    v_provisional, v_final, v_affected;
end;
$$;

drop trigger if exists trg_weekly_report_habits_guard_final
  on public.weekly_report_habits;

update public.weekly_report_habits h
set classification = app_private.weekly_report_habit_classification(
  h.scheduled_count, h.completion_rate)
where h.classification is distinct from
  app_private.weekly_report_habit_classification(
    h.scheduled_count, h.completion_rate);

create trigger trg_weekly_report_habits_guard_final
before insert or update or delete on public.weekly_report_habits
for each row execute function app_private.weekly_report_guard_final_child();

-- Classification is derived by the BEFORE INSERT trigger.  Keeping NOT NULL
-- while removing the silent fallback prevents future omissions from being
-- masked as 'unavailable'.
alter table public.weekly_report_habits
  alter column classification drop default;

comment on column public.weekly_report_habits.classification is
  'Phase 8A V1 snapshot classification, derived from scheduled_count and completion_rate; no silent default.';

commit;
