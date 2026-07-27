begin;

-- Enforces remote onboarding state transitions on public.profiles.
-- Flutter may request a state change, but PostgreSQL owns the completion
-- timestamp and rejects regressions or arbitrary contract version changes.
create function app_private.enforce_profile_onboarding_transition()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.onboarding_version is distinct from old.onboarding_version then
    raise exception 'onboarding_version cannot be changed by this operation';
  end if;

  if old.onboarding_status = 'pending'
     and new.onboarding_status in ('pending', 'in_progress') then
    new.onboarding_completed_at := null;
    return new;
  end if;

  if old.onboarding_status = 'pending'
     and new.onboarding_status = 'completed' then
    new.onboarding_completed_at := statement_timestamp();
    return new;
  end if;

  if old.onboarding_status = 'in_progress'
     and new.onboarding_status = 'pending' then
    raise exception 'invalid onboarding transition: in_progress to pending';
  end if;

  if old.onboarding_status = 'in_progress'
     and new.onboarding_status = 'in_progress' then
    new.onboarding_completed_at := null;
    return new;
  end if;

  if old.onboarding_status = 'in_progress'
     and new.onboarding_status = 'completed' then
    new.onboarding_completed_at := statement_timestamp();
    return new;
  end if;

  if old.onboarding_status = 'completed'
     and new.onboarding_status = 'completed' then
    new.onboarding_completed_at := old.onboarding_completed_at;
    new.onboarding_version := old.onboarding_version;
    return new;
  end if;

  if old.onboarding_status = 'completed'
     and new.onboarding_status in ('pending', 'in_progress') then
    raise exception 'invalid onboarding transition: completed to %', new.onboarding_status;
  end if;

  raise exception 'invalid onboarding transition: % to %',
    old.onboarding_status,
    new.onboarding_status;
end;
$$;

comment on function app_private.enforce_profile_onboarding_transition() is
  'Trigger-only guard for public.profiles onboarding transitions. Uses PostgreSQL statement_timestamp() for first completion and preserves completed timestamps idempotently.';

-- Runs only when onboarding state columns are part of an UPDATE statement.
create trigger trg_profiles_enforce_onboarding_transition
before update of onboarding_status, onboarding_version, onboarding_completed_at
on public.profiles
for each row
execute function app_private.enforce_profile_onboarding_transition();

comment on trigger trg_profiles_enforce_onboarding_transition
on public.profiles is
  'Before-update guard that blocks onboarding regressions, blocks client version changes, and assigns completion timestamps on the server.';

revoke execute on function app_private.enforce_profile_onboarding_transition()
from public;
revoke execute on function app_private.enforce_profile_onboarding_transition()
from anon;
revoke execute on function app_private.enforce_profile_onboarding_transition()
from authenticated;

commit;
