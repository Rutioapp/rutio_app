begin;

-- Archiving must stop new rewards, but it must not make a previously granted
-- reward irreversible. The public RPC remains the only entry point: archived
-- habits are accepted only for a reversal of an existing completed log.
create or replace function public.complete_habit_economy_v1(
  p_request_id text,
  p_habit_id uuid,
  p_logical_date date,
  p_is_completed boolean,
  p_value integer default 0,
  p_note text default null,
  p_client_version text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_request_id text := pg_catalog.btrim(coalesce(p_request_id, ''));
  v_habit public.habits%rowtype;
  v_log public.habit_logs%rowtype;
  v_transition public.economy_habit_transition_ledger%rowtype;
  v_reward public.habit_currency_reward_ledger%rowtype;
  v_xp_ledger public.economy_xp_ledger%rowtype;
  v_event_id text;
  v_transition_no integer;
  v_reward_xp integer;
  v_logical_today date;
  v_max_backfill integer;
  v_timezone text;
begin
  if v_user_id is null then raise exception 'authentication required'; end if;
  if v_request_id = '' then raise exception 'request_id is required'; end if;
  if p_habit_id is null or p_logical_date is null or p_is_completed is null then
    raise exception 'habit and logical date are required';
  end if;
  perform app_private.economy_assert_client_version(p_client_version);

  select h.* into v_habit
  from public.habits h
  where h.id = p_habit_id and h.user_id = v_user_id
  for update;
  if not found then raise exception 'habit not found'; end if;
  if coalesce(v_habit.is_archived, false) and p_is_completed then
    raise exception 'habit is archived';
  end if;

  select coalesce(pr.habit_time_zone, 'UTC') into v_timezone
  from public.profiles pr where pr.id = v_user_id;
  v_timezone := coalesce(v_timezone, 'UTC');
  select max_habit_backfill_days into v_max_backfill
  from public.economy_runtime_policy where policy_id = true and enabled = true;
  v_logical_today := (pg_catalog.now() at time zone v_timezone)::date;
  if p_logical_date > v_logical_today
     or p_logical_date < v_logical_today - v_max_backfill
     or p_logical_date < (v_habit.created_at at time zone v_timezone)::date then
    raise exception 'logical date is outside the allowed completion window';
  end if;
  if not app_private.is_habit_scheduled_on(v_habit.schedule, p_logical_date) then
    raise exception 'habit is not scheduled on this date';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtext(v_user_id::text || ':habit:' || p_habit_id::text || ':' || p_logical_date::text)
  );

  select * into v_transition from public.economy_habit_transition_ledger
  where request_id = v_request_id;
  if found then
    if v_transition.user_id <> v_user_id then
      raise exception 'request_id belongs to another user';
    end if;
    return jsonb_build_object(
      'request_id', v_transition.request_id,
      'is_completed', v_transition.is_completed,
      'transition_no', v_transition.transition_no,
      'idempotent', true,
      'progress', row_to_json(app_private.refresh_authoritative_user_progress(v_user_id))
    );
  end if;

  select * into v_log from public.habit_logs
  where user_id = v_user_id and habit_id = p_habit_id and log_date = p_logical_date
  for update;
  if found and v_log.is_completed = p_is_completed then
    raise exception 'requested habit state is already current';
  end if;
  if not p_is_completed and (not found or not v_log.is_completed) then
    raise exception 'cannot reverse an incomplete habit';
  end if;
  if p_is_completed and v_habit.habit_type = 'count'
     and (p_value < 1 or p_value > coalesce(v_habit.target_count, 0)) then
    raise exception 'count value is invalid';
  end if;

  select coalesce(max(transition_no), 0) + 1 into v_transition_no
  from public.economy_habit_transition_ledger
  where user_id = v_user_id and habit_id = p_habit_id and logical_date = p_logical_date;
  v_event_id := 'habit-cycle:' || v_user_id::text || ':' || p_habit_id::text
    || ':' || p_logical_date::text || ':' || v_transition_no::text;

  insert into public.habit_logs (
    user_id, habit_id, log_date, value, is_completed, note, source
  ) values (
    v_user_id, p_habit_id, p_logical_date, greatest(coalesce(p_value, 0), 0),
    p_is_completed, p_note, 'manual'
  ) on conflict (user_id, habit_id, log_date) do update set
    value = excluded.value, is_completed = excluded.is_completed,
    note = excluded.note, source = excluded.source, updated_at = pg_catalog.now();

  if p_is_completed then
    v_reward := public.apply_habit_completion_reward(
      v_request_id || ':coins', p_habit_id, p_logical_date::text, v_event_id, 'apply'
    );
    v_reward_xp := coalesce(v_reward.base_xp, 0) + coalesce(v_reward.bonus_xp, 0);
  else
    v_reward := public.reverse_habit_completion_reward(
      v_request_id || ':coins', p_habit_id, p_logical_date::text, v_event_id, 'reverse'
    );
    v_reward_xp := -(coalesce(v_reward.base_xp, 0) + coalesce(v_reward.bonus_xp, 0));
  end if;

  insert into public.economy_xp_ledger (
    request_id, user_id, source_type, source_id, operation_type, xp_delta, related_ledger_id
  ) values (
    v_request_id || ':xp', v_user_id, 'habit_completion', v_event_id,
    case when p_is_completed then 'apply' else 'reverse' end, v_reward_xp, null
  ) returning * into v_xp_ledger;

  insert into public.economy_habit_transition_ledger (
    request_id, user_id, habit_id, logical_date, transition_no, is_completed,
    habit_family_id, habit_type, target_count, value, completion_event_id,
    reward_ledger_id, xp_ledger_id
  ) values (
    v_request_id, v_user_id, p_habit_id, p_logical_date, v_transition_no,
    p_is_completed, v_habit.family_id, v_habit.habit_type, v_habit.target_count,
    greatest(coalesce(p_value, 0), 0), v_event_id, v_reward.id, v_xp_ledger.id
  );

  return jsonb_build_object(
    'request_id', v_request_id, 'is_completed', p_is_completed,
    'transition_no', v_transition_no, 'idempotent', false,
    'progress', row_to_json(app_private.refresh_authoritative_user_progress(v_user_id))
  );
end;
$$;

alter function public.complete_habit_economy_v1(text, uuid, date, boolean, integer, text, text)
  owner to postgres;
revoke all on function public.complete_habit_economy_v1(text, uuid, date, boolean, integer, text, text)
  from public, anon, authenticated;
grant execute on function public.complete_habit_economy_v1(text, uuid, date, boolean, integer, text, text)
  to authenticated;

commit;
