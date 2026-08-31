begin;

create schema if not exists app_private;

alter table public.profiles
  add column if not exists pillar_habit_ids uuid[];

update public.profiles
set pillar_habit_ids = coalesce(pillar_habit_ids, '{}'::uuid[]);

alter table public.profiles
  alter column pillar_habit_ids set default '{}'::uuid[],
  alter column pillar_habit_ids set not null;

alter table if exists public.profiles
  drop constraint if exists profiles_pillar_habit_ids_limit_check;
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'profiles_pillar_habit_ids_limit_check'
      and conrelid = 'public.profiles'::regclass
  ) then
    alter table public.profiles
      add constraint profiles_pillar_habit_ids_limit_check
      check (cardinality(pillar_habit_ids) <= 3);
  end if;
end
$$;

create or replace function app_private.validate_profile_pillar_habit_ids()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_total integer;
  v_unique integer;
begin
  if tg_op = 'UPDATE'
    and new.pillar_habit_ids is not distinct from old.pillar_habit_ids then
    return new;
  end if;

  new.pillar_habit_ids := coalesce(new.pillar_habit_ids, '{}'::uuid[]);

  if exists (
    select 1
    from unnest(new.pillar_habit_ids) as selected_habit_id(habit_id)
    where habit_id is null
  ) then
    raise exception 'pillar habits must not contain null values';
  end if;

  select count(*), count(distinct habit_id)
    into v_total, v_unique
  from unnest(new.pillar_habit_ids) as selected_habit_id(habit_id);

  if v_total > 3 then
    raise exception 'pillar habits may contain at most 3 items';
  end if;

  if v_total <> v_unique then
    raise exception 'pillar habits must be unique';
  end if;

  if exists (
    select 1
    from unnest(new.pillar_habit_ids) as selected_habit_id(habit_id)
    where not exists (
      select 1
      from public.habits as habit
      where habit.id = habit_id
        and habit.user_id = new.id
    )
  ) then
    raise exception 'pillar habits must belong to the profile owner';
  end if;

  return new;
end;
$$;

alter function app_private.validate_profile_pillar_habit_ids()
  owner to postgres;

drop trigger if exists trg_profiles_validate_pillar_habit_ids
  on public.profiles;
create trigger trg_profiles_validate_pillar_habit_ids
before insert or update of pillar_habit_ids on public.profiles
for each row
execute function app_private.validate_profile_pillar_habit_ids();

revoke all on function app_private.validate_profile_pillar_habit_ids()
from public, anon, authenticated;

comment on column public.profiles.pillar_habit_ids is
  'Ordered list of up to 3 habit UUIDs chosen as pillar habits for the profile surface.';

commit;
