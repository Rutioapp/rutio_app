begin;

create temp table _rutio_remote_onboarding_state_migration_context (
  migrated_at timestamptz not null
) on commit drop;

insert into _rutio_remote_onboarding_state_migration_context (migrated_at)
values (statement_timestamp());

alter table public.profiles
  add column onboarding_status text,
  add column onboarding_version integer,
  add column onboarding_completed_at timestamptz;

update public.profiles
set
  onboarding_status = 'completed',
  onboarding_version = 1,
  onboarding_completed_at = (
    select migrated_at
    from _rutio_remote_onboarding_state_migration_context
  );

alter table public.profiles
  alter column onboarding_status set default 'pending',
  alter column onboarding_version set default 1;

alter table public.profiles
  alter column onboarding_status set not null,
  alter column onboarding_version set not null;

alter table public.profiles
  add constraint profiles_onboarding_status_check
  check (onboarding_status in ('pending', 'in_progress', 'completed')),
  add constraint profiles_onboarding_version_check
  check (onboarding_version >= 1),
  add constraint profiles_onboarding_completed_at_consistency_check
  check (
    (
      onboarding_status = 'completed'
      and onboarding_completed_at is not null
    )
    or (
      onboarding_status in ('pending', 'in_progress')
      and onboarding_completed_at is null
    )
  );

comment on column public.profiles.onboarding_status is
  'Remote onboarding state for startup/bootstrap decisions. Valid values: pending, in_progress, completed.';
comment on column public.profiles.onboarding_version is
  'Version of the remote onboarding contract understood by the app.';
comment on column public.profiles.onboarding_completed_at is
  'Timestamp when onboarding was marked completed. Backfilled rows use the migration timestamp, not the historical onboarding date.';

commit;
