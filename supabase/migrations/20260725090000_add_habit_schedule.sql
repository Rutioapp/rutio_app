begin;

alter table if exists public.habits
  add column if not exists schedule jsonb;

create or replace function public.is_valid_habit_schedule(value jsonb)
returns boolean
language plpgsql
immutable
set search_path = ''
as $$
declare
  schedule_type text;
  item jsonb;
  date_text text;
begin
  if jsonb_typeof(value) is distinct from 'object' then
    return false;
  end if;

  schedule_type := value->>'type';
  if schedule_type not in ('daily', 'weekly', 'once', 'timesPerWeek') then
    return false;
  end if;

  if value ? 'weekStartsOn' then
    if jsonb_typeof(value->'weekStartsOn') is distinct from 'number'
      or (value->>'weekStartsOn')::numeric <> trunc((value->>'weekStartsOn')::numeric)
      or (value->>'weekStartsOn')::int < 1
      or (value->>'weekStartsOn')::int > 7 then
      return false;
    end if;
  end if;

  if schedule_type = 'weekly' then
    if jsonb_typeof(value->'weekdays') is distinct from 'array' then
      return false;
    end if;

    if jsonb_array_length(value->'weekdays') = 0 then
      return false;
    end if;

    for item in select * from jsonb_array_elements(value->'weekdays') loop
      if jsonb_typeof(item) is distinct from 'number'
        or (item #>> '{}')::numeric <> trunc((item #>> '{}')::numeric)
        or (item #>> '{}')::int < 1
        or (item #>> '{}')::int > 7 then
        return false;
      end if;
    end loop;
  end if;

  if schedule_type = 'once' then
    date_text := value->>'date';
    if date_text is null
      or date_text !~ '^\d{4}-\d{2}-\d{2}$'
      or to_char(to_date(date_text, 'YYYY-MM-DD'), 'YYYY-MM-DD') <> date_text then
      return false;
    end if;
  end if;

  if schedule_type = 'timesPerWeek' then
    if not value ? 'timesPerWeek'
      or jsonb_typeof(value->'timesPerWeek') is distinct from 'number'
      or (value->>'timesPerWeek')::numeric <= 0
      or (value->>'timesPerWeek')::numeric <> trunc((value->>'timesPerWeek')::numeric) then
      return false;
    end if;
  end if;

  return true;
exception
  when others then
    return false;
end;
$$;

alter table if exists public.habits
  drop constraint if exists habits_schedule_shape_check;

alter table if exists public.habits
  add constraint habits_schedule_shape_check
  check (
    schedule is null
    or public.is_valid_habit_schedule(schedule)
  );

comment on column public.habits.schedule is
  'Canonical habit schedule JSON. NULL means legacy remote habit pending controlled Flutter backfill.';

commit;
