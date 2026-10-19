begin;

-- These SECURITY DEFINER functions are internal helpers called by
-- complete_habit_economy_v1. Direct client execution would allow a caller to
-- mint or reverse a reward without creating the authoritative habit
-- transition, so keep execution behind the public orchestration RPC only.
revoke all on function public.apply_habit_completion_reward(
  text, uuid, text, text, text
) from public, anon, authenticated, service_role;

revoke all on function public.reverse_habit_completion_reward(
  text, uuid, text, text, text
) from public, anon, authenticated, service_role;

alter function public.apply_habit_completion_reward(
  text, uuid, text, text, text
) owner to postgres;
alter function public.reverse_habit_completion_reward(
  text, uuid, text, text, text
) owner to postgres;

commit;
