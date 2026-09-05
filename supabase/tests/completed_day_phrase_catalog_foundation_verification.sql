do $$
begin
  if to_regclass('public.motivational_phrases') is null
     or to_regclass('public.motivational_phrase_translations') is null
     or to_regclass('public.phrase_catalog_releases') is null
     or to_regclass('public.phrase_catalog_release_entries') is null then
    raise exception 'Completed Day Phrase catalog tables are missing.';
  end if;

  if not (select relrowsecurity from pg_class where oid = 'public.motivational_phrases'::regclass)
     or not (select relrowsecurity from pg_class where oid = 'public.motivational_phrase_translations'::regclass)
     or not (select relrowsecurity from pg_class where oid = 'public.phrase_catalog_releases'::regclass)
     or not (select relrowsecurity from pg_class where oid = 'public.phrase_catalog_release_entries'::regclass) then
    raise exception 'Completed Day Phrase catalog tables must have RLS enabled.';
  end if;

  if not exists (
    select 1 from pg_indexes
    where schemaname = 'public'
      and indexname = 'phrase_catalog_releases_current_locale_idx'
  ) then
    raise exception 'Current locale unique index is missing.';
  end if;

  if not exists (
    select 1 from pg_trigger
    where tgname = 'phrase_catalog_releases_immutable'
  ) or not exists (
    select 1 from pg_trigger
    where tgname = 'phrase_catalog_release_entries_immutable'
  ) then
    raise exception 'Completed Day Phrase immutability triggers are missing.';
  end if;
end;
$$;

select
  'release_integrity' as check_name,
  count(*) filter (where status = 'published' and published_at is null) as published_without_timestamp,
  count(*) filter (where status = 'draft' and published_at is not null) as draft_with_timestamp,
  count(*) filter (where status <> 'published' and is_current) as non_published_current
from public.phrase_catalog_releases;

select
  'snapshot_duplicates' as check_name,
  release_id,
  phrase_id,
  count(*) as occurrences
from public.phrase_catalog_release_entries
group by release_id, phrase_id
having count(*) > 1;
