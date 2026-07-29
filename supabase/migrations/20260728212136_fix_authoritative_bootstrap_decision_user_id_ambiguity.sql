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
  from app_private.user_bootstrap_state as s
  where s.user_id = p_user_id;

  select *
    into v_policy
  from app_private.bootstrap_policy as policy
  where policy.singleton = true;

  select *
    into v_profile
  from public.profiles as p
  where p.id = p_user_id;

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

revoke all on function app_private.get_current_user_bootstrap_decision_row(uuid)
from public, anon, authenticated;
