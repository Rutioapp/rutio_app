begin;

do $$
declare
  v_activate text := pg_get_functiondef(
    'public.activate_streak_shield(text, uuid, date, text, text)'::regprocedure
  );
  v_close text := pg_get_functiondef(
    'public.close_missed_habit_occurrence(text, uuid, date, text)'::regprocedure
  );
  v_recover text := pg_get_functiondef(
    'public.recover_streak_break(text, text, text)'::regprocedure
  );
  v_set_time_zone text := pg_get_functiondef(
    'public.set_habit_time_zone(text)'::regprocedure
  );
  v_get_time_zone text := pg_get_functiondef(
    'app_private.get_habit_time_zone(uuid)'::regprocedure
  );
  v_validate_time_zone text := pg_get_functiondef(
    'app_private.validate_profile_habit_time_zone()'::regprocedure
  );
  v_streak_before text := pg_get_functiondef(
    'app_private.habit_streak_before_date(uuid, uuid, date)'::regprocedure
  );
begin
  if not exists (
    select 1
    from pg_attribute
    where attrelid = 'public.profiles'::regclass
      and attname = 'habit_time_zone'
      and not attisdropped
  ) then
    raise exception 'profiles.habit_time_zone must exist';
  end if;

  if v_set_time_zone not like '%from pg_catalog.pg_timezone_names%'
     or v_get_time_zone not like '%from pg_catalog.pg_timezone_names%'
     or v_validate_time_zone not like '%from pg_catalog.pg_timezone_names%' then
    raise exception 'habit time zone RPC/helper/trigger must validate against pg_timezone_names';
  end if;

  if not exists (
    select 1
    from pg_trigger
    where tgrelid = 'public.profiles'::regclass
      and tgname = 'trg_profiles_validate_habit_time_zone'
      and not tgisinternal
  ) then
    raise exception 'profiles.habit_time_zone validation trigger must exist';
  end if;

  if lower(v_validate_time_zone) not like '%security definer%'
     or lower(v_validate_time_zone) not like '%set search_path to ''''%'
     or v_validate_time_zone not like '%new.habit_time_zone is null%'
     or v_validate_time_zone not like '%btrim(new.habit_time_zone)%'
     or v_validate_time_zone not like '%habit time zone is not a valid IANA time zone%' then
    raise exception 'habit_time_zone trigger must trim, allow null, and reject invalid values';
  end if;

  if has_function_privilege(
    'authenticated',
    'app_private.validate_profile_habit_time_zone()'::regprocedure,
    'EXECUTE'
  ) then
    raise exception 'authenticated must not execute app_private.validate_profile_habit_time_zone directly';
  end if;

  if v_set_time_zone like '%p_user_id%'
     or v_set_time_zone not like '%v_user_id uuid := auth.uid()%'
     or v_set_time_zone not like '%where id = v_user_id%' then
    raise exception 'set_habit_time_zone must use auth.uid() only and update only the authenticated profile';
  end if;

  if has_function_privilege(
    'anon',
    'public.set_habit_time_zone(text)'::regprocedure,
    'EXECUTE'
  ) then
    raise exception 'anon must not execute set_habit_time_zone';
  end if;

  if not has_function_privilege(
    'authenticated',
    'public.set_habit_time_zone(text)'::regprocedure,
    'EXECUTE'
  ) then
    raise exception 'authenticated must execute set_habit_time_zone';
  end if;

  if not has_function_privilege(
    'service_role',
    'public.set_habit_time_zone(text)'::regprocedure,
    'EXECUTE'
  ) then
    raise exception 'service_role must execute set_habit_time_zone';
  end if;

  if has_function_privilege(
    'authenticated',
    'app_private.get_habit_time_zone(uuid)'::regprocedure,
    'EXECUTE'
  ) then
    raise exception 'authenticated must not execute app_private.get_habit_time_zone directly';
  end if;

  if not exists (
    select 1
    from pg_attribute
    where attrelid = 'public.habit_streak_shields'::regclass
      and attname = 'effect_id'
      and attnotnull
  ) then
    raise exception 'habit_streak_shields.effect_id must be required';
  end if;

  if not exists (
    select 1
    from pg_attribute
    where attrelid = 'public.habit_streak_shields'::regclass
      and attname = 'logical_time_zone'
      and attnotnull
  ) or not exists (
    select 1
    from pg_attribute
    where attrelid = 'public.habit_streak_breaks'::regclass
      and attname = 'logical_time_zone'
      and attnotnull
  ) then
    raise exception 'streak shield and break rows must store logical_time_zone';
  end if;

  if v_activate like '%v_today_utc%'
     or v_close like '%v_today_utc%' then
    raise exception 'streak RPCs must not use v_today_utc';
  end if;

  if v_activate not like '%app_private.get_habit_time_zone(v_user_id)%'
     or v_close not like '%app_private.get_habit_time_zone(v_user_id)%' then
    raise exception 'streak RPCs must load persisted habit time zone';
  end if;

  if v_activate not like '%now() at time zone v_time_zone%'
     or v_close not like '%now() at time zone v_time_zone%' then
    raise exception 'streak RPCs must compute current logical date using the persisted zone';
  end if;

  if v_activate not like '%streak_shield_operation:%'
     or v_activate not like '%v_user_id::text%'
     or v_activate not like '%v_operation_id%' then
    raise exception 'activate_streak_shield must lock user_id + operation_id';
  end if;

  if v_close not like '%streak_close_break:%'
     or v_close not like '%v_user_id::text%'
     or v_close not like '%v_break_id%' then
    raise exception 'close_missed_habit_occurrence must lock user_id + break_id';
  end if;

  if v_activate like '%request_id = v_request_id or operation_id = v_operation_id%' then
    raise exception 'activate_streak_shield must not use a combined OR lookup for request_id/operation_id';
  end if;

  if v_activate not like '%into v_existing_by_request%'
     or v_activate not like '%and request_id = v_request_id%'
     or v_activate not like '%into v_existing_by_operation%'
     or v_activate not like '%and operation_id = v_operation_id%' then
    raise exception 'activate_streak_shield must query request_id and operation_id separately';
  end if;

  if v_activate not like '%request_id and operation_id refer to different streak shield operations%' then
    raise exception 'activate_streak_shield must detect request_id/operation_id collisions across different rows';
  end if;

  if v_activate not like '%request_id or operation_id reused for a different streak shield operation%' then
    raise exception 'activate_streak_shield must reject cross-operation idempotency reuse';
  end if;

  if v_close like '%request_id = v_request_id%or%break_id = v_break_id%'
     or v_close like '%or (habit_id = p_habit_id and missed_occurrence_date = p_logical_date)%' then
    raise exception 'close_missed_habit_occurrence must not use combined OR lookup for break idempotency';
  end if;

  if v_close not like '%into v_existing_by_request%'
     or v_close not like '%and request_id = v_request_id%'
     or v_close not like '%into v_existing_by_break%'
     or v_close not like '%and break_id = v_break_id%'
     or v_close not like '%into v_existing_by_occurrence%'
     or v_close not like '%and habit_id = p_habit_id%'
     or v_close not like '%and missed_occurrence_date = p_logical_date%' then
    raise exception 'close_missed_habit_occurrence must query break idempotency keys separately';
  end if;

  if v_close not like '%request_id and break_id refer to different streak break operations%'
     or v_close not like '%request_id and occurrence refer to different streak break operations%'
     or v_close not like '%break_id and occurrence refer to different streak break operations%' then
    raise exception 'close_missed_habit_occurrence must detect collisions between break idempotency keys';
  end if;

  if v_close not like '%request_id, break_id, or occurrence reused for a different streak break operation%' then
    raise exception 'close_missed_habit_occurrence must reject cross-operation break idempotency reuse';
  end if;

  if v_activate not like '%protected_occurrence_date < p_protected_occurrence_date%' then
    raise exception 'activate_streak_shield must expire older armed shields for the same habit';
  end if;

  if v_activate not like '%shield.effect_id = effect.id%' then
    raise exception 'activate_streak_shield must complete the utility effect associated with expired shields';
  end if;

  if v_close not like '%where id = v_shield.effect_id%' then
    raise exception 'close_missed_habit_occurrence must consume the exact shield effect_id';
  end if;

  if v_close like '%order by activated_at desc%' then
    raise exception 'close_missed_habit_occurrence must not pick the latest active effect';
  end if;

  if v_activate not like '%cannot protect a past date%' then
    raise exception 'activate_streak_shield must reject past protected dates';
  end if;

  if v_close not like '%p_logical_date >= v_today_local%'
     or v_close not like '%cannot close today or a future missed occurrence%' then
    raise exception 'close_missed_habit_occurrence must explicitly reject today and future missed occurrences';
  end if;

  if v_activate not like '%protected_occurrence_date is before habit creation date%'
     or v_close not like '%logical_date is before habit creation date%'
     or v_activate not like '%v_habit.created_at at time zone v_time_zone%'
     or v_close not like '%v_habit.created_at at time zone v_time_zone%' then
    raise exception 'shield activation and missed occurrence close must reject dates before logical habit creation';
  end if;

  if v_close not like '%p_logical_date::timestamp at time zone v_time_zone%' then
    raise exception 'recoverable_until must be calculated from missed_occurrence_date at local midnight in persisted zone';
  end if;

  if v_streak_before like '%created_at::date%' then
    raise exception 'habit_streak_before_date must not use UTC/default created_at::date';
  end if;

  if v_streak_before not like '%app_private.get_habit_time_zone(p_user_id)%'
     or v_streak_before not like '%v_habit.created_at at time zone v_time_zone%'
     or v_streak_before not like '%exit when v_cursor < v_created_local_date%' then
    raise exception 'habit_streak_before_date must stop at logical creation date in persisted zone';
  end if;

  if v_close not like '%v_break_status := case%'
     or v_close not like '%when now() > v_recoverable_until then ''expired''%'
     or v_close not like '%else ''recoverable''%'
     or v_close not like '%break_expired%' then
    raise exception 'close_missed_habit_occurrence must create already-expired breaks directly as expired';
  end if;

  if v_close like '%now() + interval ''48 hours''%' then
    raise exception 'recoverable_until must not be calculated from close time';
  end if;

  if v_recover not like '%if v_break.status = ''recovered'' then%return v_break;%' then
    raise exception 'recover_streak_break must return duplicate recovered breaks without consuming utility again';
  end if;

  if not exists (
    select 1
    from pg_indexes
    where schemaname = 'public'
      and tablename = 'habit_streak_shields'
      and indexname = 'idx_habit_streak_shields_effect_id_unique'
      and indexdef ilike '%unique%'
  ) then
    raise exception 'habit_streak_shields.effect_id must be unique';
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.habit_streak_shields'::regclass
      and conname = 'habit_streak_shields_consumed_at_check'
      and pg_get_constraintdef(oid) like '%consumed_at IS NOT NULL%'
      and pg_get_constraintdef(oid) like '%consumed_at IS NULL%'
  ) then
    raise exception 'habit_streak_shields consumed_at constraint must be strict by status';
  end if;

  if not exists (
    select 1
    from pg_indexes
    where schemaname = 'public'
      and tablename = 'habit_streak_breaks'
      and indexname = 'idx_habit_streak_breaks_recovery_request_unique'
  ) then
    raise exception 'habit_streak_breaks must keep recovery_request_id unique for idempotent recovery';
  end if;
end;
$$;

rollback;
