-- RUTIO — restore the level-reward amount helper omitted from the Staging bootstrap.
-- This restores the existing product contract; it does not change claim RPCs,
-- tables, permissions, RLS, or any user data.

create or replace function app_private.level_reward_ambar_for_level(
  p_level integer
)
returns integer
language plpgsql
stable
set search_path = ''
as $$
begin
  if p_level is null or p_level <= 1 then
    return 0;
  elsif p_level = 5 then
    return 50;
  elsif p_level = 10 then
    return 150;
  elsif p_level = 20 then
    return 300;
  elsif p_level = 30 then
    return 500;
  elsif p_level = 40 then
    return 750;
  elsif p_level = 50 then
    return 1000;
  elsif p_level > 50 and p_level % 10 = 0 then
    return p_level * 20;
  end if;

  return 0;
end;
$$;
