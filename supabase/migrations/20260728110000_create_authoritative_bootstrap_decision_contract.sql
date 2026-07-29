begin;

create schema if not exists app_private;

revoke all on schema app_private from public;
revoke all on schema app_private from anon;
revoke all on schema app_private from authenticated;

create table if not exists app_private.user_bootstrap_state (
  user_id uuid primary key references auth.users(id) on delete cascade,
  account_status text not null,
  profile_state text not null,
  profile_revision bigint not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint user_bootstrap_state_account_status_check
    check (account_status in ('active', 'suspended', 'pending_deletion')),
  constraint user_bootstrap_state_profile_state_check
    check (profile_state in ('uninitialized', 'ready', 'deleted')),
  constraint user_bootstrap_state_profile_revision_check
    check (profile_revision >= 0)
);

comment on table app_private.user_bootstrap_state is
  'Authoritative per-user bootstrap state. Separates account lifecycle and profile lifecycle so bootstrap can distinguish new users, ready profiles, and intentionally deleted profiles.';
comment on column app_private.user_bootstrap_state.account_status is
  'Authoritative account lifecycle for bootstrap. active is the normal state. suspended and pending_deletion are reserved for internal/admin workflows and must never unlock Home from cache.';
comment on column app_private.user_bootstrap_state.profile_state is
  'Authoritative profile lifecycle for bootstrap. uninitialized means the user exists but no confirmed profile row is ready. ready means a valid profile row exists. deleted means a profile existed and was later removed intentionally or authoritatively.';
comment on column app_private.user_bootstrap_state.profile_revision is
  'Monotonic revision for bootstrap-relevant changes: profile creation, profile deletion, onboarding state fields, account_status, and profile_state.';

drop trigger if exists trg_user_bootstrap_state_set_updated_at
  on app_private.user_bootstrap_state;
create trigger trg_user_bootstrap_state_set_updated_at
before update on app_private.user_bootstrap_state
for each row
execute function app_private.set_updated_at();

revoke all on table app_private.user_bootstrap_state from public;
revoke all on table app_private.user_bootstrap_state from anon;
revoke all on table app_private.user_bootstrap_state from authenticated;

create table if not exists app_private.bootstrap_policy (
  singleton boolean primary key default true,
  required_onboarding_version integer not null,
  onboarding_enforcement text not null,
  policy_revision bigint not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint bootstrap_policy_singleton_check
    check (singleton = true),
  constraint bootstrap_policy_required_onboarding_version_check
    check (required_onboarding_version >= 1),
  constraint bootstrap_policy_onboarding_enforcement_check
    check (onboarding_enforcement in ('advisory', 'required')),
  constraint bootstrap_policy_revision_check
    check (policy_revision >= 1)
);

comment on table app_private.bootstrap_policy is
  'Singleton authoritative bootstrap policy. advisory preserves current behavior. required is reserved for future mandatory onboarding upgrades.';
comment on column app_private.bootstrap_policy.required_onboarding_version is
  'Minimum onboarding contract version recognized by the remote bootstrap contract.';
comment on column app_private.bootstrap_policy.onboarding_enforcement is
  'advisory allows completed users with older versions to continue to Home. required forces onboarding when the completed remote version is lower than required_onboarding_version.';
comment on column app_private.bootstrap_policy.policy_revision is
  'Monotonic revision for bootstrap policy changes that affect the authoritative decision.';

drop trigger if exists trg_bootstrap_policy_set_updated_at
  on app_private.bootstrap_policy;
create trigger trg_bootstrap_policy_set_updated_at
before update on app_private.bootstrap_policy
for each row
execute function app_private.set_updated_at();

revoke all on table app_private.bootstrap_policy from public;
revoke all on table app_private.bootstrap_policy from anon;
revoke all on table app_private.bootstrap_policy from authenticated;

insert into app_private.bootstrap_policy (
  singleton,
  required_onboarding_version,
  onboarding_enforcement,
  policy_revision
)
values (
  true,
  1,
  'advisory',
  1
)
on conflict (singleton) do nothing;

create or replace function app_private.ensure_user_bootstrap_state_row(
  p_user_id uuid
)
returns app_private.user_bootstrap_state
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_state app_private.user_bootstrap_state%rowtype;
begin
  if p_user_id is null then
    raise exception 'user id is required';
  end if;

  insert into app_private.user_bootstrap_state (
    user_id,
    account_status,
    profile_state,
    profile_revision
  )
  values (
    p_user_id,
    'active',
    'uninitialized',
    0
  )
  on conflict (user_id) do nothing;

  select *
    into v_state
  from app_private.user_bootstrap_state as s
  where s.user_id = p_user_id;

  return v_state;
end;
$$;

comment on function app_private.ensure_user_bootstrap_state_row(uuid) is
  'Internal helper that guarantees an authoritative bootstrap state row exists for an auth user. Used by signup/bootstrap triggers. Not callable from Flutter clients.';

create or replace function app_private.set_user_bootstrap_account_status(
  p_user_id uuid,
  p_account_status text
)
returns app_private.user_bootstrap_state
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_state app_private.user_bootstrap_state%rowtype;
begin
  if p_user_id is null then
    raise exception 'user id is required';
  end if;

  if p_account_status not in ('active', 'suspended', 'pending_deletion') then
    raise exception 'invalid account_status: %', p_account_status;
  end if;

  perform app_private.ensure_user_bootstrap_state_row(p_user_id);

  update app_private.user_bootstrap_state
     set account_status = p_account_status,
         profile_revision = case
           when account_status is distinct from p_account_status
             then profile_revision + 1
           else profile_revision
         end,
         updated_at = case
           when account_status is distinct from p_account_status
             then now()
           else updated_at
         end
   where user_id = p_user_id
   returning * into v_state;

  return v_state;
end;
$$;

comment on function app_private.set_user_bootstrap_account_status(uuid, text) is
  'Internal-only helper reserved for future administrative workflows. Changes account_status and bumps profile_revision only when the state actually changes.';

create or replace function app_private.set_bootstrap_policy(
  p_required_onboarding_version integer,
  p_onboarding_enforcement text
)
returns app_private.bootstrap_policy
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_policy app_private.bootstrap_policy%rowtype;
begin
  if p_required_onboarding_version is null
     or p_required_onboarding_version < 1 then
    raise exception 'required_onboarding_version must be >= 1';
  end if;

  if p_onboarding_enforcement not in ('advisory', 'required') then
    raise exception 'invalid onboarding_enforcement: %', p_onboarding_enforcement;
  end if;

  insert into app_private.bootstrap_policy (
    singleton,
    required_onboarding_version,
    onboarding_enforcement,
    policy_revision
  )
  values (
    true,
    p_required_onboarding_version,
    p_onboarding_enforcement,
    1
  )
  on conflict (singleton) do update
    set required_onboarding_version = excluded.required_onboarding_version,
        onboarding_enforcement = excluded.onboarding_enforcement,
        policy_revision = case
          when app_private.bootstrap_policy.required_onboarding_version is distinct from excluded.required_onboarding_version
             or app_private.bootstrap_policy.onboarding_enforcement is distinct from excluded.onboarding_enforcement
            then app_private.bootstrap_policy.policy_revision + 1
          else app_private.bootstrap_policy.policy_revision
        end,
        updated_at = case
          when app_private.bootstrap_policy.required_onboarding_version is distinct from excluded.required_onboarding_version
             or app_private.bootstrap_policy.onboarding_enforcement is distinct from excluded.onboarding_enforcement
            then now()
          else app_private.bootstrap_policy.updated_at
        end
  returning * into v_policy;

  return v_policy;
end;
$$;

comment on function app_private.set_bootstrap_policy(integer, text) is
  'Internal-only helper reserved for future administrative workflows. Updates the singleton bootstrap policy and bumps policy_revision only when the policy actually changes.';

create or replace function app_private.bootstrap_profile_state_on_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into app_private.user_bootstrap_state (
    user_id,
    account_status,
    profile_state,
    profile_revision
  )
  values (
    new.id,
    'active',
    'ready',
    1
  )
  on conflict (user_id) do update
    set profile_state = 'ready',
        profile_revision = greatest(
          app_private.user_bootstrap_state.profile_revision + 1,
          1
        ),
        updated_at = now();

  return new;
end;
$$;

comment on function app_private.bootstrap_profile_state_on_insert() is
  'Trigger helper that marks a profile row as ready and bumps profile_revision when a profile is inserted or re-created.';

create or replace function app_private.bootstrap_profile_state_on_update()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if old.onboarding_status is not distinct from new.onboarding_status
     and old.onboarding_version is not distinct from new.onboarding_version
     and old.onboarding_completed_at is not distinct from new.onboarding_completed_at then
    return new;
  end if;

  insert into app_private.user_bootstrap_state (
    user_id,
    account_status,
    profile_state,
    profile_revision
  )
  values (
    new.id,
    'active',
    'ready',
    1
  )
  on conflict (user_id) do update
    set profile_state = 'ready',
        profile_revision = greatest(
          app_private.user_bootstrap_state.profile_revision + 1,
          1
        ),
        updated_at = now();

  return new;
end;
$$;

comment on function app_private.bootstrap_profile_state_on_update() is
  'Trigger helper that bumps profile_revision only for bootstrap-relevant profile changes: onboarding_status, onboarding_version, and onboarding_completed_at.';

create or replace function app_private.bootstrap_profile_state_on_delete()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update app_private.user_bootstrap_state
     set profile_state = 'deleted',
         profile_revision = greatest(profile_revision + 1, 1),
         updated_at = now()
   where user_id = old.id;

  return old;
end;
$$;

comment on function app_private.bootstrap_profile_state_on_delete() is
  'Trigger helper that marks the profile lifecycle as deleted and bumps profile_revision when a profile row is removed. It does not recreate profiles and does nothing if the authoritative state row is already absent.';

create or replace function app_private.get_current_user_bootstrap_decision_row(
  p_user_id uuid
)
returns table (
  user_id uuid,
  decision text,
  account_status text,
  profile_state text,
  onboarding_status text,
  completed_onboarding_version integer,
  required_onboarding_version integer,
  onboarding_enforcement text,
  onboarding_completed_at timestamptz,
  profile_revision bigint,
  policy_revision bigint
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_state app_private.user_bootstrap_state%rowtype;
  v_policy app_private.bootstrap_policy%rowtype;
  v_profile public.profiles%rowtype;
begin
  if p_user_id is null then
    return;
  end if;

  select *
    into v_state
  from app_private.user_bootstrap_state
  where user_id = p_user_id;

  select *
    into v_policy
  from app_private.bootstrap_policy
  where singleton = true;

  select *
    into v_profile
  from public.profiles
  where id = p_user_id;

  if v_state.user_id is null or v_policy.singleton is distinct from true then
    return query
    select
      p_user_id,
      'invalid_profile',
      v_state.account_status,
      v_state.profile_state,
      null::text,
      null::integer,
      v_policy.required_onboarding_version,
      v_policy.onboarding_enforcement,
      null::timestamptz,
      v_state.profile_revision,
      v_policy.policy_revision;
    return;
  end if;

  if v_state.account_status = 'suspended' then
    return query
    select
      p_user_id,
      'account_suspended',
      v_state.account_status,
      v_state.profile_state,
      null::text,
      null::integer,
      v_policy.required_onboarding_version,
      v_policy.onboarding_enforcement,
      null::timestamptz,
      v_state.profile_revision,
      v_policy.policy_revision;
    return;
  end if;

  if v_state.account_status = 'pending_deletion' then
    return query
    select
      p_user_id,
      'account_pending_deletion',
      v_state.account_status,
      v_state.profile_state,
      null::text,
      null::integer,
      v_policy.required_onboarding_version,
      v_policy.onboarding_enforcement,
      null::timestamptz,
      v_state.profile_revision,
      v_policy.policy_revision;
    return;
  end if;

  if v_state.account_status <> 'active' then
    return query
    select
      p_user_id,
      'invalid_profile',
      v_state.account_status,
      v_state.profile_state,
      null::text,
      null::integer,
      v_policy.required_onboarding_version,
      v_policy.onboarding_enforcement,
      null::timestamptz,
      v_state.profile_revision,
      v_policy.policy_revision;
    return;
  end if;

  if v_state.profile_state = 'deleted' then
    return query
    select
      p_user_id,
      'profile_deleted',
      v_state.account_status,
      v_state.profile_state,
      null::text,
      null::integer,
      v_policy.required_onboarding_version,
      v_policy.onboarding_enforcement,
      null::timestamptz,
      v_state.profile_revision,
      v_policy.policy_revision;
    return;
  end if;

  if v_state.profile_state = 'uninitialized' then
    return query
    select
      p_user_id,
      'profile_uninitialized',
      v_state.account_status,
      v_state.profile_state,
      null::text,
      null::integer,
      v_policy.required_onboarding_version,
      v_policy.onboarding_enforcement,
      null::timestamptz,
      v_state.profile_revision,
      v_policy.policy_revision;
    return;
  end if;

  if v_state.profile_state <> 'ready'
     or v_profile.id is null
     or v_profile.id <> p_user_id
     or v_profile.onboarding_status is null
     or v_profile.onboarding_version is null
     or (
       v_profile.onboarding_status = 'completed'
       and v_profile.onboarding_completed_at is null
     )
     or (
       v_profile.onboarding_status in ('pending', 'in_progress')
       and v_profile.onboarding_completed_at is not null
     ) then
    return query
    select
      p_user_id,
      'invalid_profile',
      v_state.account_status,
      v_state.profile_state,
      v_profile.onboarding_status,
      case
        when v_profile.onboarding_status = 'completed'
          then v_profile.onboarding_version
        else null
      end,
      v_policy.required_onboarding_version,
      v_policy.onboarding_enforcement,
      v_profile.onboarding_completed_at,
      v_state.profile_revision,
      v_policy.policy_revision;
    return;
  end if;

  if v_profile.onboarding_status in ('pending', 'in_progress') then
    return query
    select
      p_user_id,
      'onboarding',
      v_state.account_status,
      v_state.profile_state,
      v_profile.onboarding_status,
      null::integer,
      v_policy.required_onboarding_version,
      v_policy.onboarding_enforcement,
      v_profile.onboarding_completed_at,
      v_state.profile_revision,
      v_policy.policy_revision;
    return;
  end if;

  if v_profile.onboarding_status = 'completed' then
    return query
    select
      p_user_id,
      case
        when v_policy.onboarding_enforcement = 'required'
         and v_profile.onboarding_version < v_policy.required_onboarding_version
          then 'onboarding'
        else 'home'
      end,
      v_state.account_status,
      v_state.profile_state,
      v_profile.onboarding_status,
      v_profile.onboarding_version,
      v_policy.required_onboarding_version,
      v_policy.onboarding_enforcement,
      v_profile.onboarding_completed_at,
      v_state.profile_revision,
      v_policy.policy_revision;
    return;
  end if;

  return query
  select
    p_user_id,
    'invalid_profile',
    v_state.account_status,
    v_state.profile_state,
    v_profile.onboarding_status,
    case
      when v_profile.onboarding_status = 'completed'
        then v_profile.onboarding_version
      else null
    end,
    v_policy.required_onboarding_version,
    v_policy.onboarding_enforcement,
    v_profile.onboarding_completed_at,
    v_state.profile_revision,
    v_policy.policy_revision;
end;
$$;

comment on function app_private.get_current_user_bootstrap_decision_row(uuid) is
  'Internal authoritative bootstrap decision helper. Fail-closed: inconsistencies never return home. Reserved for the public auth.uid()-scoped RPC.';

create or replace function public.get_current_user_bootstrap_decision()
returns table (
  user_id uuid,
  decision text,
  account_status text,
  profile_state text,
  onboarding_status text,
  completed_onboarding_version integer,
  required_onboarding_version integer,
  onboarding_enforcement text,
  onboarding_completed_at timestamptz,
  profile_revision bigint,
  policy_revision bigint
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    return;
  end if;

  return query
  select *
  from app_private.get_current_user_bootstrap_decision_row(v_user_id);
end;
$$;

comment on function public.get_current_user_bootstrap_decision() is
  'Returns the authoritative bootstrap decision for auth.uid() only. Does not recreate profiles, does not accept a client-supplied user id, and exposes no sensitive profile fields.';

insert into app_private.user_bootstrap_state (
  user_id,
  account_status,
  profile_state,
  profile_revision
)
select
  auth_user.id,
  'active',
  case
    when profile.id is not null then 'ready'
    else 'uninitialized'
  end,
  case
    when profile.id is not null then 1
    else 0
  end
from auth.users as auth_user
left join public.profiles as profile
  on profile.id = auth_user.id
on conflict (user_id) do nothing;

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

  perform app_private.ensure_user_bootstrap_state_row(new.id);

  return new;
end;
$$;

comment on function app_private.bootstrap_user_wallet_on_auth_insert() is
  'Auth signup bootstrap trigger helper. Keeps the existing wallet bootstrap behavior and also guarantees an initial authoritative bootstrap state row for each new auth user.';

drop trigger if exists trg_profiles_bootstrap_state_on_insert
  on public.profiles;
create trigger trg_profiles_bootstrap_state_on_insert
after insert on public.profiles
for each row
execute function app_private.bootstrap_profile_state_on_insert();

drop trigger if exists trg_profiles_bootstrap_state_on_update
  on public.profiles;
create trigger trg_profiles_bootstrap_state_on_update
after update of onboarding_status, onboarding_version, onboarding_completed_at
on public.profiles
for each row
execute function app_private.bootstrap_profile_state_on_update();

drop trigger if exists trg_profiles_bootstrap_state_on_delete
  on public.profiles;
create trigger trg_profiles_bootstrap_state_on_delete
after delete on public.profiles
for each row
execute function app_private.bootstrap_profile_state_on_delete();

comment on trigger trg_profiles_bootstrap_state_on_insert
on public.profiles is
  'Marks the authoritative bootstrap profile lifecycle as ready and bumps profile_revision when a profile row is inserted.';
comment on trigger trg_profiles_bootstrap_state_on_update
on public.profiles is
  'Bumps the authoritative bootstrap profile_revision only for onboarding_status, onboarding_version, and onboarding_completed_at changes.';
comment on trigger trg_profiles_bootstrap_state_on_delete
on public.profiles is
  'Marks the authoritative bootstrap profile lifecycle as deleted and bumps profile_revision when a profile row is removed.';

revoke execute on function app_private.ensure_user_bootstrap_state_row(uuid)
from public;
revoke execute on function app_private.ensure_user_bootstrap_state_row(uuid)
from anon;
revoke execute on function app_private.ensure_user_bootstrap_state_row(uuid)
from authenticated;

revoke execute on function app_private.set_user_bootstrap_account_status(uuid, text)
from public;
revoke execute on function app_private.set_user_bootstrap_account_status(uuid, text)
from anon;
revoke execute on function app_private.set_user_bootstrap_account_status(uuid, text)
from authenticated;

revoke execute on function app_private.set_bootstrap_policy(integer, text)
from public;
revoke execute on function app_private.set_bootstrap_policy(integer, text)
from anon;
revoke execute on function app_private.set_bootstrap_policy(integer, text)
from authenticated;

revoke execute on function app_private.bootstrap_profile_state_on_insert()
from public;
revoke execute on function app_private.bootstrap_profile_state_on_insert()
from anon;
revoke execute on function app_private.bootstrap_profile_state_on_insert()
from authenticated;

revoke execute on function app_private.bootstrap_profile_state_on_update()
from public;
revoke execute on function app_private.bootstrap_profile_state_on_update()
from anon;
revoke execute on function app_private.bootstrap_profile_state_on_update()
from authenticated;

revoke execute on function app_private.bootstrap_profile_state_on_delete()
from public;
revoke execute on function app_private.bootstrap_profile_state_on_delete()
from anon;
revoke execute on function app_private.bootstrap_profile_state_on_delete()
from authenticated;

revoke execute on function app_private.get_current_user_bootstrap_decision_row(uuid)
from public;
revoke execute on function app_private.get_current_user_bootstrap_decision_row(uuid)
from anon;
revoke execute on function app_private.get_current_user_bootstrap_decision_row(uuid)
from authenticated;

revoke execute on function app_private.bootstrap_user_wallet_on_auth_insert()
from public;
revoke execute on function app_private.bootstrap_user_wallet_on_auth_insert()
from anon;
revoke execute on function app_private.bootstrap_user_wallet_on_auth_insert()
from authenticated;

revoke execute on function public.get_current_user_bootstrap_decision()
from public;
revoke execute on function public.get_current_user_bootstrap_decision()
from anon;
grant execute on function public.get_current_user_bootstrap_decision()
to authenticated;

commit;
