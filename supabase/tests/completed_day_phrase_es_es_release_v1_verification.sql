-- Run after the Phase 3A migrations and the es-ES v1 seed, with a role that
-- can execute the catalog RPCs. This does not apply migrations or seed data.
do $$
declare
  v_release jsonb;
  v_snapshot jsonb;
  v_phrase jsonb;
  v_expected record;
begin
  v_release := public.get_published_phrase_catalog_release('es-ES');
  if v_release is null
     or v_release->>'locale' <> 'es-ES'
     or (v_release->>'releaseVersion')::integer <> 1
     or (v_release->>'schemaVersion')::integer <> 1 then
    raise exception 'Unexpected es-ES v1 release metadata: %', v_release;
  end if;

  v_snapshot := public.get_completed_day_phrase_catalog_snapshot('es-ES', 1);
  if v_snapshot is null
     or v_snapshot->>'locale' <> 'es-ES'
     or v_snapshot->>'catalogVersion' <> '1'
     or jsonb_array_length(v_snapshot->'phrases') <> 300 then
    raise exception 'Unexpected es-ES v1 snapshot metadata or count: %', v_snapshot;
  end if;

  for v_expected in
    select * from (values
      ('personal_001', 'personal', 'original', null::text, array['name']::text[], '{name}, hoy te has demostrado que puedes contar contigo.'),
      ('personal_050', 'personal', 'original', null::text, array['name']::text[], 'Hoy has cumplido contigo, {name}. Mañana será una nueva elección.'),
      ('consistency_001', 'consistency', 'original', null::text, '{}'::text[], 'La constancia no hace ruido, pero deja huella.'),
      ('consistency_100', 'consistency', 'original', null::text, '{}'::text[], 'Lo construido poco a poco suele resistir mejor.'),
      ('motivation_001', 'motivation', 'original', null::text, '{}'::text[], 'Hoy también puede ser un buen punto de partida.'),
      ('motivation_150', 'motivation', 'quote', 'Máxima délfica', '{}'::text[], 'Conócete a ti mismo.')
    ) as samples(id, category, source_type, author, required_tokens, template)
  loop
    select phrase into v_phrase
    from jsonb_array_elements(v_snapshot->'phrases') phrase
    where phrase->>'id' = v_expected.id;
    if v_phrase is null
       or v_phrase->>'category' <> v_expected.category
       or v_phrase->>'sourceType' <> v_expected.source_type
       or v_phrase->>'template' <> v_expected.template
       or (v_phrase->'requiredTokens') <> to_jsonb(v_expected.required_tokens)
       or (v_expected.author is null and v_phrase->'author' <> 'null'::jsonb)
       or (v_expected.author is not null and v_phrase->>'author' <> v_expected.author) then
      raise exception 'Unexpected snapshot sample %: %', v_expected.id, v_phrase;
    end if;
  end loop;
end;
$$;
