begin;

-- Later activation calls preserve the original boundary and update only the
-- timezone used by future automation.
-- The original date check tied the activation boundary to the mutable timezone;
-- the boundary is activated_at, so retaining that check would reject a valid
-- timezone change.
alter table public.weekly_report_activations drop constraint if exists weekly_report_activations_date_check;

create or replace function public.activate_weekly_report(p_activation_local_date date, p_timezone_name text)
returns public.weekly_report_activations language plpgsql security definer set search_path = ''
as $$
declare v_user_id uuid := auth.uid(); v_now timestamptz := now(); v_activation public.weekly_report_activations%rowtype;
begin
  if v_user_id is null then raise exception 'authentication required'; end if;
  if p_timezone_name is null or not exists (select 1 from pg_catalog.pg_timezone_names where name = btrim(p_timezone_name)) then raise exception 'timezone_name must be a valid IANA time zone'; end if;
  if p_activation_local_date is distinct from (v_now at time zone btrim(p_timezone_name))::date then raise exception 'activation_local_date must be today in timezone_name'; end if;
  insert into public.weekly_report_activations (user_id, activated_at, activation_local_date, timezone_name)
  values (v_user_id, v_now, p_activation_local_date, btrim(p_timezone_name))
  on conflict (user_id) do update set timezone_name = excluded.timezone_name
  returning * into v_activation;
  if v_activation.activated_at = v_now then
    insert into public.weekly_report_habit_config_versions (user_id, habit_id, effective_from, effective_local_date, effective_timezone_name, name, emoji, habit_type, target_count, schedule, is_archived, source_event, source_updated_at)
    select h.user_id, h.id, v_activation.activated_at, v_activation.activation_local_date, v_activation.timezone_name, h.name, h.emoji, h.habit_type, h.target_count, h.schedule, h.is_archived, 'activation', h.updated_at
    from public.habits h where h.user_id = v_user_id;
  end if;
  return v_activation;
end;
$$;

create or replace function public.get_my_weekly_report_by_week_start(p_week_start_date date)
returns jsonb language plpgsql stable security definer set search_path = ''
as $$
declare v_user_id uuid := auth.uid(); v_report_id uuid;
begin
  if v_user_id is null then raise exception 'authentication required'; end if;
  select r.id into v_report_id from public.weekly_reports r where r.user_id = v_user_id and r.week_start_date = p_week_start_date;
  return app_private.weekly_report_payload(v_report_id, v_user_id);
end;
$$;

create or replace function app_private.process_weekly_report_automation()
returns void language plpgsql security definer set search_path = ''
as $$
declare a record; local_now timestamp; week_start date; local_minute integer;
begin
  for a in select user_id, timezone_name from public.weekly_report_activations order by user_id loop
    begin
      local_now := now() at time zone a.timezone_name;
      week_start := local_now::date - (extract(isodow from local_now)::int - 1);
      local_minute := extract(hour from local_now)::int * 60 + extract(minute from local_now)::int;
      if extract(isodow from local_now)::int = 7 and local_minute >= 19 * 60 then
        if not exists (select 1 from public.weekly_reports r where r.user_id = a.user_id and r.week_start_date = week_start) then perform app_private.generate_or_refresh_weekly_report(a.user_id, week_start); end if;
      end if;
      if extract(isodow from local_now)::int = 1 and local_minute >= 10 then perform app_private.finalize_weekly_report(a.user_id, week_start - 7); end if;
    exception when others then raise warning '[WEEKLY_REPORT_AUTOMATION] user % failed: %', a.user_id, sqlerrm;
    end;
  end loop;
end;
$$;

revoke all on function public.get_my_weekly_report_by_week_start(date) from public, anon;
grant execute on function public.get_my_weekly_report_by_week_start(date) to authenticated;
revoke all on function app_private.process_weekly_report_automation() from public, anon, authenticated;

create extension if not exists pg_cron with schema extensions;
select cron.unschedule(jobid) from cron.job where jobname = 'weekly-report-automation-15m';
select cron.schedule('weekly-report-automation-15m', '*/15 * * * *', $$select app_private.process_weekly_report_automation();$$);

comment on function public.get_my_weekly_report_by_week_start(date) is 'Owner-scoped read-only exact week resolution; never generates.';
comment on function app_private.process_weekly_report_automation() is 'Phase 12 worker: Sunday 19:00 provisional, Monday 00:10 final, IANA/DST safe.';
commit;
