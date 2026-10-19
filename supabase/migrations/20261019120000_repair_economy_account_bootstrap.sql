begin;

-- Repair the account invariant required by the authoritative economy RPC.
-- This creates only a zero-balance wallet; it never grants XP or coins.
-- user_progress remains a server-owned projection and is created/refreshed by
-- app_private.refresh_authoritative_user_progress after a valid RPC operation.

create or replace function app_private.bootstrap_user_wallet_on_auth_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.user_wallets (user_id, coins, version)
  values (new.id, 0, 0)
  on conflict (user_id) do nothing;

  perform app_private.ensure_user_bootstrap_state_row(new.id);
  return new;
end;
$$;

alter function app_private.bootstrap_user_wallet_on_auth_insert()
  owner to postgres;

drop trigger if exists trg_auth_users_bootstrap_user_wallet on auth.users;
create trigger trg_auth_users_bootstrap_user_wallet
after insert on auth.users
for each row
execute function app_private.bootstrap_user_wallet_on_auth_insert();

-- Idempotent repair for auth accounts created while the trigger was absent or
-- incomplete. Existing balances and versions are never changed.
insert into public.user_wallets (user_id, coins, version)
select u.id, 0, 0
from auth.users u
where not exists (
  select 1
  from public.user_wallets existing_wallet
  where existing_wallet.user_id = u.id
)
on conflict (user_id) do nothing;

revoke execute on function app_private.bootstrap_user_wallet_on_auth_insert()
from public, anon, authenticated, service_role;

commit;
