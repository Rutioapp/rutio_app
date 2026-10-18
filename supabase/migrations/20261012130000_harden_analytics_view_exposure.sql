begin;

-- Phase 9B analytics and cloud-economy rollout views are internal/admin
-- surfaces. They contain global aggregates, auth-derived counts, or
-- user-identifiable economic balances. Do not expose them through the
-- anon/authenticated PostgREST roles.
--
-- Keep the view definitions and security_invoker setting unchanged. The
-- service_role grant is the existing administrative access path; no client
-- role receives a replacement grant here.
do $$
declare
  v_view record;
begin
  for v_view in
    select *
    from (values
      ('public'::name, 'analytics_total_users'::name),
      ('public'::name, 'analytics_new_users_by_day'::name),
      ('public'::name, 'analytics_daily_active_users'::name),
      ('public'::name, 'analytics_habits_created_by_day'::name),
      ('public'::name, 'analytics_habit_logs_completed_by_day'::name),
      ('public'::name, 'analytics_journal_entries_by_day'::name),
      ('public'::name, 'analytics_achievement_unlocks_by_day'::name),
      ('public'::name, 'analytics_xp_generated_by_day'::name),
      ('public'::name, 'analytics_ambar_by_day'::name),
      ('public'::name, 'analytics_daily_summary'::name),
      ('public'::name, 'analytics_economic_movements'::name),
      ('public'::name, 'global_cloud_economy_rollout_status'::name)
    ) as views(schema_name, view_name)
  loop
    if to_regclass(format('%I.%I', v_view.schema_name, v_view.view_name)) is null then
      raise exception 'required analytics view is missing: %.%',
        v_view.schema_name,
        v_view.view_name;
    end if;

    execute format(
      'revoke all on table %I.%I from public, anon, authenticated',
      v_view.schema_name,
      v_view.view_name
    );
    execute format(
      'grant select on table %I.%I to service_role',
      v_view.schema_name,
      v_view.view_name
    );
  end loop;
end;
$$;

comment on view public.global_cloud_economy_rollout_status is
  'Internal/admin rollout comparison. Client roles have no SELECT grant; use an approved administrative path.';

commit;
