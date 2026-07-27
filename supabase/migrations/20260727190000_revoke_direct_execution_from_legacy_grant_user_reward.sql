begin;

revoke execute
on function public.grant_user_reward(integer, integer, text, uuid, text)
from public;

revoke execute
on function public.grant_user_reward(integer, integer, text, uuid, text)
from anon;

revoke execute
on function public.grant_user_reward(integer, integer, text, uuid, text)
from authenticated;

grant execute
on function public.grant_user_reward(integer, integer, text, uuid, text)
to service_role;

commit;
