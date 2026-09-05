do $$
begin
  if to_regprocedure('public.get_published_phrase_catalog_release(text)') is null
     or to_regprocedure(
       'public.get_completed_day_phrase_catalog_snapshot(text,integer)'
     ) is null then
    raise exception 'Completed Day Phrase catalog read RPCs are missing.';
  end if;

  if not has_function_privilege(
    'authenticated',
    'public.get_published_phrase_catalog_release(text)',
    'EXECUTE'
  ) or not has_function_privilege(
    'authenticated',
    'public.get_completed_day_phrase_catalog_snapshot(text,integer)',
    'EXECUTE'
  ) then
    raise exception 'Authenticated RPC grants are missing.';
  end if;

  if has_table_privilege('anon', 'public.motivational_phrases', 'SELECT')
     or has_table_privilege('anon', 'public.motivational_phrase_translations', 'SELECT')
     or has_table_privilege('anon', 'public.phrase_catalog_releases', 'SELECT')
     or has_table_privilege('anon', 'public.phrase_catalog_release_entries', 'SELECT')
     or has_table_privilege('authenticated', 'public.motivational_phrases', 'SELECT')
     or has_table_privilege('authenticated', 'public.motivational_phrase_translations', 'SELECT')
     or has_table_privilege('authenticated', 'public.phrase_catalog_releases', 'SELECT')
     or has_table_privilege('authenticated', 'public.phrase_catalog_release_entries', 'SELECT') then
    raise exception 'Catalog tables must not be directly readable by authenticated.';
  end if;
end;
$$;
