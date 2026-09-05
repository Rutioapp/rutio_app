begin;

create or replace function public.get_published_phrase_catalog_release(p_locale text)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'releaseId', r.id::text,
    'locale', r.locale,
    'releaseVersion', r.release_version,
    'schemaVersion', r.schema_version,
    'publishedAt', r.published_at
  )
  from public.phrase_catalog_releases r
  where r.locale = btrim(p_locale)
    and r.status = 'published'
    and r.is_current = true;
$$;

create or replace function public.get_completed_day_phrase_catalog_snapshot(
  p_locale text,
  p_release_version integer
)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'releaseId', r.id::text,
    'schemaVersion', r.schema_version,
    'catalogVersion', r.release_version::text,
    'locale', r.locale,
    'phrases', coalesce(
      jsonb_agg(
        jsonb_build_object(
          'id', e.phrase_id,
          'category', e.category,
          'tone', e.tone,
          'sourceType', e.source_type,
          'author', e.author,
          'template', e.template,
          'requiredTokens', to_jsonb(e.required_tokens),
          'weight', e.weight,
          'enabled', e.enabled,
          'contentVersion', e.content_version
        ) order by e.phrase_id
      ) filter (where e.phrase_id is not null),
      '[]'::jsonb
    )
  )
  from public.phrase_catalog_releases r
  left join public.phrase_catalog_release_entries e on e.release_id = r.id
  where r.locale = btrim(p_locale)
    and r.release_version = p_release_version
    and r.status = 'published'
  group by r.id, r.schema_version, r.release_version, r.locale;
$$;

revoke all on function public.get_published_phrase_catalog_release(text)
  from public, anon;
grant execute on function public.get_published_phrase_catalog_release(text)
  to authenticated;

revoke all on function public.get_completed_day_phrase_catalog_snapshot(text, integer)
  from public, anon;
grant execute on function public.get_completed_day_phrase_catalog_snapshot(text, integer)
  to authenticated;

comment on function public.get_published_phrase_catalog_release(text) is
  'Returns only current published release metadata for an exact locale.';
comment on function public.get_completed_day_phrase_catalog_snapshot(text, integer) is
  'Returns one immutable published phrase catalog snapshot by exact locale and release version.';

commit;
