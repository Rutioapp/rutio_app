-- Phase 9: link the canonical DiaryEntry to a Weekly Report.
-- Additive only; weekly report snapshots remain immutable.
begin;

alter table public.diary_entries
  add column if not exists weekly_report_id uuid;

alter table public.diary_entries
  drop constraint if exists diary_entries_weekly_report_fk;
alter table public.diary_entries
  add constraint diary_entries_weekly_report_fk
  foreign key (weekly_report_id) references public.weekly_reports(id)
  on delete set null;

create index if not exists idx_diary_entries_user_weekly_report
  on public.diary_entries (user_id, weekly_report_id)
  where weekly_report_id is not null;

create unique index if not exists idx_diary_entries_one_weekly_reflection
  on public.diary_entries (user_id, weekly_report_id)
  where weekly_report_id is not null and entry_type = 'reflection';

create or replace function app_private.validate_diary_weekly_report_owner()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.weekly_report_id is not null and not exists (
    select 1 from public.weekly_reports r
    where r.id = new.weekly_report_id and r.user_id = new.user_id
  ) then
    raise exception 'weekly report does not belong to diary entry owner';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_diary_entries_validate_weekly_report_owner
  on public.diary_entries;
create trigger trg_diary_entries_validate_weekly_report_owner
before insert or update of user_id, weekly_report_id on public.diary_entries
for each row execute function app_private.validate_diary_weekly_report_owner();

commit;
