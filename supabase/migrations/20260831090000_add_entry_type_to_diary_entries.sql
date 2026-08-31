alter table if exists public.diary_entries
  add column if not exists entry_type text;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'diary_entries_entry_type_check'
      and conrelid = 'public.diary_entries'::regclass
  ) then
    alter table public.diary_entries
      add constraint diary_entries_entry_type_check
      check (
        entry_type is null
        or entry_type in (
          'learning',
          'reflection',
          'moment',
          'gratitude'
        )
      );
  end if;
end
$$;
