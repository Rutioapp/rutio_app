begin;

create or replace function app_private.habit_completion_base_reward(
  p_habit_type text,
  p_target_count integer
)
returns table (
  base_xp integer,
  base_coins integer
)
language plpgsql
stable
set search_path = ''
as $$
declare
  v_habit_type text := lower(btrim(coalesce(p_habit_type, '')));
  v_target_count integer := coalesce(p_target_count, 0);
  v_xp integer;
begin
  if v_habit_type = 'check' then
    base_xp := 10;
    base_coins := 5;
    return next;
    return;
  elsif v_habit_type = 'count' then
    if v_target_count <= 0 then
      raise exception 'count habit target is required';
    end if;

    v_xp := greatest(
      5,
      least(
        15,
        ((ceiling(v_target_count::numeric / 5.0) * 2) + 5)::integer
      )
    );

    base_xp := v_xp;
    base_coins := greatest(
      0,
      least(10, floor(v_xp::numeric / 2.0)::integer)
    );

    return next;
    return;
  end if;

  raise exception 'unsupported habit type %', p_habit_type;
end;
$$;

commit;
