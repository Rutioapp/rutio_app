begin;

create schema if not exists app_private;

create or replace function app_private.bootstrap_user_wallet_on_auth_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.user_wallets (
    user_id,
    coins,
    version
  ) values (
    new.id,
    0,
    0
  )
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists trg_auth_users_bootstrap_user_wallet
  on auth.users;
create trigger trg_auth_users_bootstrap_user_wallet
after insert on auth.users
for each row
execute function app_private.bootstrap_user_wallet_on_auth_insert();

insert into public.user_wallets (
  user_id,
  coins,
  version
)
select
  auth_user.id,
  0,
  0
from auth.users as auth_user
on conflict (user_id) do nothing;

revoke execute on function app_private.bootstrap_user_wallet_on_auth_insert()
from public;
revoke execute on function app_private.bootstrap_user_wallet_on_auth_insert()
from anon;
revoke execute on function app_private.bootstrap_user_wallet_on_auth_insert()
from authenticated;

commit;
