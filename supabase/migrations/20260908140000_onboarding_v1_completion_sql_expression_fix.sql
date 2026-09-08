begin;

-- AUTH-3 forward fix: NULLIF is SQL expression syntax, not a
-- pg_catalog.nullif(text, unknown) function. Keep the deployed RPC contract.
create or replace function public.complete_onboarding_v1(
  p_operation_id uuid,
  p_account_resolution text,
  p_prepared_habit_decision text,
  p_profile jsonb default '{}'::jsonb,
  p_prepared_habit jsonb default null,
  p_reminder jsonb default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_existing app_private.onboarding_completion_operations%rowtype;
  v_profile public.profiles%rowtype;
  v_profile_exists boolean := false;
  v_effective_resolution text;
  v_decision text := pg_catalog.lower(pg_catalog.btrim(coalesce(p_prepared_habit_decision, '')));
  v_client_resolution text := pg_catalog.lower(pg_catalog.btrim(coalesce(p_account_resolution, '')));
  v_name text;
  v_habit jsonb;
  v_reminder_enabled boolean := false;
  v_reminder_time text;
  v_habit_id uuid;
  v_inserted_profile_count integer;
  v_result jsonb;
  v_payload jsonb;
  v_fingerprint text;
begin
  if v_user_id is null then
    raise exception using errcode = '28000', message = 'auth_required';
  end if;

  if p_operation_id is null then
    raise exception using errcode = '22023', message = 'invalid_payload';
  end if;
  if v_client_resolution not in ('newaccount', 'existingaccountcompleted',
                                  'existingaccountincomplete') then
    raise exception using errcode = '22023', message = 'invalid_payload';
  end if;
  if v_decision not in ('keep', 'discard') then
    raise exception using errcode = '22023', message = 'invalid_payload';
  end if;
  if p_profile is null or pg_catalog.jsonb_typeof(p_profile) <> 'object' then
    raise exception using errcode = '22023', message = 'invalid_payload';
  end if;

  -- JSONB canonical text has deterministic object-key ordering in Postgres;
  -- md5 is built in and avoids adding an extension solely for fingerprints.
  v_payload := pg_catalog.jsonb_build_object(
    'accountResolution', v_client_resolution,
    'preparedHabitDecision', v_decision,
    'profile', p_profile,
    'preparedHabit', coalesce(p_prepared_habit, 'null'::jsonb),
    'reminder', coalesce(p_reminder, 'null'::jsonb)
  );
  v_fingerprint := pg_catalog.md5(v_payload::text);

  -- Reserve the operation before touching profile/habits. The primary-key
  -- conflict waits for a concurrent call, making double taps serialize.
  insert into app_private.onboarding_completion_operations (
    operation_id, user_id, payload, payload_fingerprint
  ) values (
    p_operation_id, v_user_id, v_payload, v_fingerprint
  ) on conflict (operation_id) do nothing;

  select * into v_existing
  from app_private.onboarding_completion_operations
  where operation_id = p_operation_id
  for update;

  if v_existing.user_id <> v_user_id
     or v_existing.payload_fingerprint <> v_fingerprint then
    raise exception using errcode = 'P0001', message = 'operation_conflict';
  end if;
  if v_existing.status = 'completed' then
    if v_existing.payload_fingerprint <> v_fingerprint then
      raise exception using errcode = 'P0001', message = 'operation_conflict';
    end if;
    return v_existing.result || pg_catalog.jsonb_build_object(
      'status', 'alreadyCompletedSameOperation'
    );
  end if;

  -- Revalidate account classification while holding the profile row lock.
  select * into v_profile
  from public.profiles
  where id = v_user_id
  for update;
  v_profile_exists := found;
  v_effective_resolution := case
    when not v_profile_exists then 'newAccount'
    when v_profile.onboarding_status = 'completed' then 'existingAccountCompleted'
    else 'existingAccountIncomplete'
  end;

  -- A stale client saying newAccount is never permission to overwrite a
  -- profile that appeared since resolution. Existing remote data wins.
  if v_profile_exists and v_client_resolution = 'newaccount' then
    null;
  elsif not v_profile_exists and v_client_resolution <> 'newaccount' then
    raise exception using errcode = 'P0001', message = 'remote_state_conflict';
  end if;

  if p_prepared_habit is not null then
    if pg_catalog.jsonb_typeof(p_prepared_habit) <> 'object'
       or nullif(pg_catalog.btrim(p_prepared_habit->>'name'), ''::text) is null
       or nullif(pg_catalog.btrim(p_prepared_habit->>'habit_type'), ''::text) is null
       or not public.is_valid_habit_schedule(p_prepared_habit->'schedule') then
      raise exception using errcode = '22023', message = 'invalid_payload';
    end if;
    if pg_catalog.lower(pg_catalog.btrim(p_prepared_habit->>'habit_type')) not in ('check', 'count') then
      raise exception using errcode = '22023', message = 'invalid_payload';
    end if;
    if pg_catalog.lower(pg_catalog.btrim(p_prepared_habit->>'habit_type')) = 'count'
       and ((p_prepared_habit->>'target_count') is null
         or (p_prepared_habit->>'target_count') !~ '^[1-9][0-9]*$') then
      raise exception using errcode = '22023', message = 'invalid_payload';
    end if;
    v_habit := pg_catalog.jsonb_build_object(
      'name', pg_catalog.btrim(p_prepared_habit->>'name'),
      'family_id', nullif(pg_catalog.btrim(p_prepared_habit->>'family_id'), ''::text),
      'emoji', nullif(pg_catalog.btrim(p_prepared_habit->>'emoji'), ''::text),
      'habit_type', pg_catalog.lower(pg_catalog.btrim(p_prepared_habit->>'habit_type')),
      'target_count', case when (p_prepared_habit->>'target_count') is null then null else (p_prepared_habit->>'target_count')::integer end,
      'unit', nullif(pg_catalog.btrim(p_prepared_habit->>'unit'), ''::text),
      'schedule', p_prepared_habit->'schedule'
    );
  end if;

  if p_reminder is not null and pg_catalog.jsonb_typeof(p_reminder) = 'object' then
    if coalesce(p_reminder->>'enabled', 'false') not in ('true', 'false') then
      raise exception using errcode = '22023', message = 'invalid_payload';
    end if;
    v_reminder_enabled := coalesce((p_reminder->>'enabled')::boolean, false);
    if v_reminder_enabled then
      if (p_reminder->>'hour') !~ '^[0-9]+$'
         or (p_reminder->>'minute') !~ '^[0-9]+$'
         or (p_reminder->>'hour')::integer not between 0 and 23
         or (p_reminder->>'minute')::integer not between 0 and 59 then
        raise exception using errcode = '22023', message = 'invalid_payload';
      end if;
      v_reminder_time := pg_catalog.lpad((p_reminder->>'hour')::text, 2, '0')
        || ':' || pg_catalog.lpad((p_reminder->>'minute')::text, 2, '0');
    end if;
  end if;

  v_name := nullif(pg_catalog.btrim(p_profile->>'name'), ''::text);
  if v_effective_resolution = 'newAccount' and v_name is not null
     and pg_catalog.char_length(v_name) > 30 then
    raise exception using errcode = '22023', message = 'invalid_payload';
  end if;

  if v_effective_resolution = 'newAccount' then
    insert into public.profiles (
      id, display_name, onboarding_status, onboarding_version,
      onboarding_completed_at
    ) values (
      v_user_id, v_name, 'completed', 1, pg_catalog.now()
    )
    on conflict (id) do nothing;
    get diagnostics v_inserted_profile_count = row_count;
    select * into v_profile from public.profiles where id = v_user_id for update;
    if v_inserted_profile_count = 0 then
      v_effective_resolution := case
        when v_profile.onboarding_status = 'completed' then 'existingAccountCompleted'
        else 'existingAccountIncomplete'
      end;
      update public.profiles
      set onboarding_status = 'completed', onboarding_version = greatest(onboarding_version, 1)
      where id = v_user_id;
    end if;
  else
    update public.profiles
    set onboarding_status = 'completed', onboarding_version = greatest(onboarding_version, 1)
    where id = v_user_id;
  end if;

  if v_decision = 'keep' and v_habit is not null then
    insert into public.habits (
      user_id, name, family_id, emoji, habit_type, target_count, unit,
      reminder_enabled, reminder_time, schedule, is_archived, sort_order
    ) values (
      v_user_id,
      v_habit->>'name',
      v_habit->>'family_id',
      v_habit->>'emoji',
      v_habit->>'habit_type',
      (v_habit->>'target_count')::integer,
      v_habit->>'unit',
      v_reminder_enabled,
      v_reminder_time::time,
      v_habit->'schedule',
      false,
      0
    ) returning id into v_habit_id;
  end if;

  v_result := pg_catalog.jsonb_build_object(
    'status', 'completed',
    'operationId', p_operation_id,
    'userId', v_user_id,
    'habitId', v_habit_id,
    'preparedHabitApplied', v_habit_id is not null,
    'accountResolution', v_effective_resolution,
    'completedAt', pg_catalog.now()
  );
  v_payload := pg_catalog.jsonb_build_object(
    'accountResolution', v_client_resolution,
    'preparedHabitDecision', v_decision,
    'profile', p_profile,
    'preparedHabit', coalesce(p_prepared_habit, 'null'::jsonb),
    'reminder', coalesce(p_reminder, 'null'::jsonb)
  );
  v_fingerprint := pg_catalog.md5(v_payload::text);

  update app_private.onboarding_completion_operations
  set status = 'completed', result = v_result, completed_at = pg_catalog.now()
  where operation_id = p_operation_id and user_id = v_user_id;

  return v_result;
end;
$$;

alter function public.complete_onboarding_v1(uuid, text, text, jsonb, jsonb, jsonb)
  owner to postgres;
revoke all on function public.complete_onboarding_v1(uuid, text, text, jsonb, jsonb, jsonb)
  from public, anon;
grant execute on function public.complete_onboarding_v1(uuid, text, text, jsonb, jsonb, jsonb)
  to authenticated;

comment on function public.complete_onboarding_v1(uuid, text, text, jsonb, jsonb, jsonb) is
  'AUTH-3 atomic/idempotent onboarding completion. The authenticated user is always derived from auth.uid(); client user_id is not accepted.';

commit;
