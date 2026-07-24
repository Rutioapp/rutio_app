begin;

update public.habits
set schedule = '{"type":"daily"}'::jsonb
where schedule is null;

alter table public.habits
  alter column schedule set default '{"type":"daily"}'::jsonb,
  alter column schedule set not null;

commit;
