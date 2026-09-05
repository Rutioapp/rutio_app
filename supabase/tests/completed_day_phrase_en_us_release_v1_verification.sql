-- Local/manual verification for en-US v1. Do not run against production from this task.
begin;

do $$
declare
  v_release_id uuid;
  v_count integer;
begin
  select id into v_release_id
  from public.phrase_catalog_releases
  where locale = 'en-US'
    and release_version = 1
    and status = 'published'
    and is_current = true;

  if v_release_id is null then
    raise exception 'Published current en-US v1 release not found';
  end if;

  select count(*) into v_count
  from public.phrase_catalog_release_entries
  where release_id = v_release_id;
  if v_count <> 300 then
    raise exception 'Expected 300 en-US release entries, got %', v_count;
  end if;

  if (select count(*) from public.phrase_catalog_release_entries
      where release_id = v_release_id and category = 'personal') <> 50 then
    raise exception 'Expected 50 personal entries';
  end if;
  if (select count(*) from public.phrase_catalog_release_entries
      where release_id = v_release_id and category = 'consistency') <> 100 then
    raise exception 'Expected 100 consistency entries';
  end if;
  if (select count(*) from public.phrase_catalog_release_entries
      where release_id = v_release_id and category = 'motivation') <> 150 then
    raise exception 'Expected 150 motivation entries';
  end if;

  if exists (
    select 1 from public.phrase_catalog_release_entries
    where release_id = v_release_id
      and (btrim(template) = '' or weight <= 0 or content_version <= 0)
  ) then
    raise exception 'Invalid en-US release entry';
  end if;

  if exists (
    select 1 from public.phrase_catalog_release_entries
    where release_id = v_release_id
      and ((source_type = 'original' and author is not null)
        or (source_type in ('quote', 'proverb') and author is null))
  ) then
    raise exception 'Invalid en-US attribution metadata';
  end if;

  if not exists (select 1 from public.phrase_catalog_release_entries
      where release_id = v_release_id and phrase_id = 'personal_001'
        and required_tokens = array['name']::text[]) then
    raise exception 'personal_001 token metadata mismatch';
  end if;
  if not exists (select 1 from public.phrase_catalog_release_entries
      where release_id = v_release_id and phrase_id = 'personal_050') then
    raise exception 'personal_050 missing';
  end if;
  if not exists (select 1 from public.phrase_catalog_release_entries
      where release_id = v_release_id and phrase_id = 'consistency_001') then
    raise exception 'consistency_001 missing';
  end if;
  if not exists (select 1 from public.phrase_catalog_release_entries
      where release_id = v_release_id and phrase_id = 'consistency_100') then
    raise exception 'consistency_100 missing';
  end if;
  if not exists (select 1 from public.phrase_catalog_release_entries
      where release_id = v_release_id and phrase_id = 'motivation_001') then
    raise exception 'motivation_001 missing';
  end if;
  if not exists (select 1 from public.phrase_catalog_release_entries
      where release_id = v_release_id and phrase_id = 'motivation_150'
        and author = 'Delphic maxim') then
    raise exception 'motivation_150 attribution mismatch';
  end if;

  if exists (
    select 1
    from public.phrase_catalog_release_entries e
    where e.release_id = v_release_id
      and exists (
        select 1
        from regexp_matches(e.template, '\\{([a-z_]+)\\}', 'g') m(token)
        where (m.token)[1] <> all (array['name', 'streak_label', 'progress']::text[])
      )
  ) then
    raise exception 'Unknown en-US template token';
  end if;

  raise notice 'en-US v1 verified: schema=1 release=1 entries=300';
end;
$$;

rollback;
