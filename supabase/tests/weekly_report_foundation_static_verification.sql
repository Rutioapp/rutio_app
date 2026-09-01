begin;
do $$
declare
  v_report text := pg_get_constraintdef((select oid from pg_constraint where conname = 'weekly_reports_week_start_check' and conrelid = 'public.weekly_reports'::regclass));
  v_guard text := pg_get_functiondef('app_private.weekly_report_guard_immutable()'::regprocedure);
  v_activation text := pg_get_functiondef('public.activate_weekly_report(date, text)'::regprocedure);
  v_config text := pg_get_functiondef('app_private.record_weekly_report_habit_config_version(uuid, uuid, timestamptz, date, text, text, text, text, numeric, jsonb, boolean, timestamptz, text)'::regprocedure);
  v_capture text := pg_get_functiondef('app_private.weekly_report_capture_habit_config()'::regprocedure);
begin
  if not exists (select 1 from pg_class where oid = 'public.weekly_reports'::regclass and relrowsecurity) then raise exception 'weekly_reports RLS must be enabled'; end if;
  if not exists (select 1 from pg_class where oid = 'public.weekly_report_habit_config_versions'::regclass and relrowsecurity) then raise exception 'config history RLS must be enabled'; end if;
  if not exists (select 1 from pg_constraint where conname = 'weekly_reports_user_week_unique' and conrelid = 'public.weekly_reports'::regclass) then raise exception 'user/week uniqueness missing'; end if;
  if not exists (select 1 from pg_constraint where conname = 'weekly_report_days_report_user_fk' and conrelid = 'public.weekly_report_days'::regclass) then raise exception 'days ownership FK missing'; end if;
  if not exists (select 1 from pg_constraint where conname = 'weekly_report_habits_report_user_fk' and conrelid = 'public.weekly_report_habits'::regclass) then raise exception 'habits ownership FK missing'; end if;
  if not exists (select 1 from pg_trigger where tgname = 'trg_weekly_report_capture_habit_config' and tgrelid = 'public.habits'::regclass) then raise exception 'habit config capture trigger missing'; end if;
  if not exists (select 1 from pg_trigger where tgname = 'trg_weekly_reports_guard_immutable' and tgrelid = 'public.weekly_reports'::regclass) then raise exception 'report immutability trigger missing'; end if;
  if (select count(*) from pg_trigger where tgname in ('trg_weekly_report_days_guard_final', 'trg_weekly_report_habits_guard_final', 'trg_weekly_report_recommendations_guard_final')) <> 3 then raise exception 'all child immutability triggers missing'; end if;
  if not exists (select 1 from pg_indexes where indexname = 'idx_weekly_report_config_source_mutation' and indexdef like '%(user_id, habit_id, source_mutation_id)%') then raise exception 'scoped source mutation uniqueness missing'; end if;
  if v_report not like '%isodow%' then raise exception 'Monday week boundary constraint missing'; end if;
  if not exists (select 1 from pg_constraint where conname = 'weekly_reports_rate_check' and conrelid = 'public.weekly_reports'::regclass and pg_get_constraintdef(oid) like '%completion_rate is null%') then raise exception 'zero-scheduled NULL rate constraint missing'; end if;
  if v_guard not like '%final weekly reports are immutable%' then raise exception 'final immutability guard missing'; end if;
  if v_capture not like '%tg_op = ''DELETE''%' or v_capture not like '%old.id%' then raise exception 'habit delete capture must use OLD'; end if;
  if v_config not like '%p_effective_from%' or v_config not like '%p_source_mutation_id%' then raise exception 'late mutation seam missing'; end if;
  if v_activation not like '%auth.uid()%' or v_activation not like '%pg_catalog.pg_timezone_names%' or v_activation not like '%on conflict (user_id) do nothing%' then raise exception 'activation security/idempotency contract missing'; end if;
  if position('search_path' in lower(v_activation)) = 0 then raise exception 'activation search_path must be fixed'; end if;
  if not has_function_privilege('authenticated', 'public.activate_weekly_report(date, text)'::regprocedure, 'EXECUTE') then raise exception 'authenticated activation execute grant missing'; end if;
  if has_function_privilege('anon', 'public.activate_weekly_report(date, text)'::regprocedure, 'EXECUTE') then raise exception 'anon must not activate weekly reports'; end if;
  if not exists (select 1 from pg_constraint where conname = 'weekly_report_habits_occurrences_check' and conrelid = 'public.weekly_report_habits'::regclass and pg_get_constraintdef(oid) like '%is_valid_weekly_report_occurrences%') then raise exception 'occurrences structural validation missing'; end if;
  if has_table_privilege('authenticated', 'public.weekly_reports', 'SELECT') then raise exception 'authenticated must not select internal snapshots directly'; end if;
  if has_table_privilege('authenticated', 'public.weekly_reports', 'INSERT') then raise exception 'authenticated must not insert snapshots directly'; end if;
  if has_function_privilege('authenticated', 'app_private.record_weekly_report_habit_config_version(uuid, uuid, timestamptz, date, text, text, text, text, numeric, jsonb, boolean, timestamptz, text)'::regprocedure, 'EXECUTE') then raise exception 'authenticated must not assert effective config history'; end if;
  if has_function_privilege('authenticated', 'app_private.weekly_report_capture_habit_config()'::regprocedure, 'EXECUTE') or has_function_privilege('anon', 'app_private.weekly_report_capture_habit_config()'::regprocedure, 'EXECUTE') then raise exception 'capture helper must be internal'; end if;
  if has_function_privilege('authenticated', 'app_private.is_valid_weekly_report_occurrences(jsonb)'::regprocedure, 'EXECUTE') or has_function_privilege('anon', 'app_private.is_valid_weekly_report_occurrences(jsonb)'::regprocedure, 'EXECUTE') then raise exception 'occurrence helper must be internal'; end if;
  if has_function_privilege('authenticated', 'app_private.weekly_report_guard_immutable()'::regprocedure, 'EXECUTE') or has_function_privilege('anon', 'app_private.weekly_report_guard_final_child()'::regprocedure, 'EXECUTE') then raise exception 'immutability helpers must be internal'; end if;
end $$;
rollback;
