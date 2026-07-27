begin;

create or replace function public.record_habit_log(
  habit_id_input uuid,
  log_date_input date default current_date,
  value_input integer default null,
  is_completed_input boolean default null,
  note_input text default null
)
returns table (
  habit_log_id uuid,
  habit_id uuid,
  log_date date,
  final_value integer,
  final_is_completed boolean,
  reward_was_granted boolean,
  xp_granted integer,
  ambar_granted integer,
  new_level integer,
  new_total_xp integer,
  new_ambar_balance integer
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_habit public.habits%rowtype;
  v_existing_log public.habit_logs%rowtype;
  v_saved_log public.habit_logs%rowtype;
  v_progress public.user_progress%rowtype;
  v_target_count integer;
  v_computed_value integer;
  v_computed_is_completed boolean;
begin
  if v_user_id is null then
    raise exception 'authentication required';
  end if;

  if habit_id_input is null then
    raise exception 'habit_id is required';
  end if;

  if log_date_input is null then
    raise exception 'log_date is required';
  end if;

  if value_input is not null and value_input < 0 then
    raise exception 'value cannot be negative';
  end if;

  select *
    into v_habit
  from public.habits as h
  where h.id = habit_id_input;

  if not found then
    raise exception 'habit not found';
  end if;

  if v_habit.user_id <> v_user_id then
    raise exception 'habit not found';
  end if;

  if coalesce(v_habit.is_archived, false) then
    raise exception 'habit is archived';
  end if;

  select *
    into v_existing_log
  from public.habit_logs as hl
  where hl.user_id = v_user_id
    and hl.habit_id = habit_id_input
    and hl.log_date = log_date_input
  for update;

  if v_habit.habit_type = 'check' then
    v_computed_is_completed := coalesce(is_completed_input, true);
    v_computed_value := case when v_computed_is_completed then 1 else 0 end;
  else
    v_target_count := greatest(coalesce(v_habit.target_count, 1), 1);
    v_computed_value := coalesce(value_input, v_existing_log.value, 0);
    v_computed_is_completed := coalesce(
      is_completed_input,
      v_computed_value >= v_target_count
    );
  end if;

  insert into public.habit_logs (
    user_id,
    habit_id,
    log_date,
    value,
    is_completed,
    note,
    completed_at,
    source
  ) values (
    v_user_id,
    habit_id_input,
    log_date_input,
    v_computed_value,
    v_computed_is_completed,
    note_input,
    case when v_computed_is_completed then now() else null end,
    'manual'
  )
  on conflict (user_id, habit_id, log_date)
  do update
     set value = excluded.value,
         is_completed = excluded.is_completed,
         note = coalesce(excluded.note, public.habit_logs.note),
         completed_at = case
           when excluded.is_completed and public.habit_logs.completed_at is null then now()
           when not excluded.is_completed then null
           else public.habit_logs.completed_at
         end,
         source = 'manual'
  returning * into v_saved_log;

  select *
    into v_progress
  from public.user_progress as up
  where up.user_id = v_user_id;

  habit_log_id := v_saved_log.id;
  habit_id := v_saved_log.habit_id;
  log_date := v_saved_log.log_date;
  final_value := v_saved_log.value;
  final_is_completed := v_saved_log.is_completed;
  reward_was_granted := false;
  xp_granted := 0;
  ambar_granted := 0;
  new_level := coalesce(v_progress.level, 1);
  new_total_xp := coalesce(v_progress.total_xp, 0);
  new_ambar_balance := coalesce(v_progress.ambar_balance, 0);

  return next;
end;
$$;

alter function public.record_habit_log(uuid, date, integer, boolean, text)
owner to postgres;

revoke execute
on function public.record_habit_log(uuid, date, integer, boolean, text)
from public;

revoke execute
on function public.record_habit_log(uuid, date, integer, boolean, text)
from anon;

grant execute
on function public.record_habit_log(uuid, date, integer, boolean, text)
to authenticated;

grant execute
on function public.record_habit_log(uuid, date, integer, boolean, text)
to service_role;

commit;
