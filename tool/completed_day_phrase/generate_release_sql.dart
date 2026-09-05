import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final input = args.isEmpty
      ? 'supabase/catalog/completed_day_phrase/es-ES.v1.json'
      : args[0];
  final catalog = Map<String, dynamic>.from(
    jsonDecode(File(input).readAsStringSync()) as Map,
  );
  final locale = _string(catalog, 'locale');
  final output = args.length < 2
      ? 'supabase/seeds/completed_day_phrase_${locale.toLowerCase().replaceAll('-', '_')}_v1.sql'
      : args[1];
  final phrases = _phrases(catalog);
  _expect(catalog['schemaVersion'] == 1, 'schemaVersion must be 1');
  _expect(catalog['catalogVersion'] == '1', 'catalogVersion must be 1');
  _expect(catalog['releaseVersion'] == 1, 'releaseVersion must be 1');
  _expect(phrases.length == 300, 'expected 300 phrases');

  final expectedRows = phrases.map(_expectedRow).toList(growable: false);
  final buffer = StringBuffer()
    ..writeln('-- GENERATED FILE. Do not edit manually.')
    ..writeln('-- Source: $input')
    ..writeln(
        '-- Regenerate: dart run tool/completed_day_phrase/generate_release_sql.dart $input')
    ..writeln(
        '-- This file never calls Supabase remotely; apply it only after the migrations.')
    ..writeln()
    ..writeln('begin;')
    ..writeln()
    ..writeln(
        '-- A published v1 is immutable. Re-running fails as a controlled no-op.')
    ..writeln('do \$\$')
    ..writeln('declare')
    ..writeln('  v_status text;')
    ..writeln('  v_entry_count integer;')
    ..writeln('begin')
    ..writeln('  select status into v_status')
    ..writeln('  from public.phrase_catalog_releases')
    ..writeln('  where locale = ${_sqlString(locale)} and release_version = 1;')
    ..writeln("  if v_status = 'published' then")
    ..writeln('    select count(*) into v_entry_count')
    ..writeln('    from public.phrase_catalog_release_entries e')
    ..writeln(
        '    join public.phrase_catalog_releases r on r.id = e.release_id')
    ..writeln(
        '    where r.locale = ${_sqlString(locale)} and r.release_version = 1;')
    ..writeln('    if v_entry_count = 300 then')
    ..writeln(
        "      raise exception 'completed_day_phrase $locale v1 is already published; seed aborted as a controlled no-op check';")
    ..writeln('    end if;')
    ..writeln(
        "    raise exception 'completed_day_phrase $locale v1 is published but incomplete; refusing to mutate it';")
    ..writeln('  end if;')
    ..writeln('end;')
    ..writeln('\$\$;')
    ..writeln()
    ..writeln('-- Expected locale-specific release payload.')
    ..writeln('create temporary table _completed_day_phrase_expected (')
    ..writeln('  id text primary key,')
    ..writeln('  category text not null,')
    ..writeln('  tone text not null,')
    ..writeln('  source_type text not null,')
    ..writeln('  author text,')
    ..writeln('  required_tokens text[] not null,')
    ..writeln('  weight numeric not null,')
    ..writeln('  enabled boolean not null,')
    ..writeln('  template text not null,')
    ..writeln('  content_version integer not null')
    ..writeln(') on commit drop;')
    ..writeln()
    ..writeln('insert into _completed_day_phrase_expected (')
    ..writeln('  id, category, tone, source_type, author, required_tokens,')
    ..writeln('  weight, enabled, template, content_version')
    ..writeln(') values');
  buffer
    ..writeln(joinSqlValues(expectedRows))
    ..writeln(';')
    ..writeln()
    ..writeln('-- Existing base metadata must match; it is never overwritten.')
    ..writeln('do \$\$')
    ..writeln('begin')
    ..writeln('  if exists (')
    ..writeln('    select 1')
    ..writeln('    from _completed_day_phrase_expected e')
    ..writeln('    left join public.motivational_phrases p on p.id = e.id')
    ..writeln('    where p.id is null')
    ..writeln('  ) then')
    ..writeln(
        "    raise exception 'Missing motivational phrase base metadata.';")
    ..writeln('  end if;')
    ..writeln('  if exists (')
    ..writeln('    select 1')
    ..writeln('    from _completed_day_phrase_expected e')
    ..writeln('    join public.motivational_phrases p on p.id = e.id')
    ..writeln('    where p.category is distinct from e.category')
    ..writeln('       or p.tone is distinct from e.tone')
    ..writeln('       or p.source_type is distinct from e.source_type')
    ..writeln('       or p.required_tokens is distinct from e.required_tokens')
    ..writeln('       or p.weight is distinct from e.weight')
    ..writeln('  ) then')
    ..writeln(
        "    raise exception 'Motivational phrase structural metadata mismatch.';")
    ..writeln('  end if;')
    ..writeln('end;')
    ..writeln('\$\$;')
    ..writeln()
    ..writeln('insert into public.motivational_phrases (')
    ..writeln(
        '  id, category, tone, source_type, author, required_tokens, weight, enabled')
    ..writeln(')')
    ..writeln(
        'select id, category, tone, source_type, author, required_tokens, weight, enabled')
    ..writeln('from _completed_day_phrase_expected')
    ..writeln('on conflict (id) do nothing;')
    ..writeln()
    ..writeln('insert into public.motivational_phrase_translations (')
    ..writeln(
        '  phrase_id, locale, template, review_status, translator_note, content_version')
    ..writeln(')')
    ..writeln(
        'select id, ${_sqlString(locale)}, template, \'reviewed\', null, content_version')
    ..writeln('from _completed_day_phrase_expected')
    ..writeln('on conflict (phrase_id, locale) do update set')
    ..writeln('  template = excluded.template,')
    ..writeln('  review_status = excluded.review_status,')
    ..writeln('  translator_note = excluded.translator_note,')
    ..writeln('  content_version = excluded.content_version;')
    ..writeln()
    ..writeln('create temporary table _completed_day_phrase_seed_release (')
    ..writeln('  release_id uuid primary key')
    ..writeln(') on commit drop;')
    ..writeln()
    ..writeln('do \$\$')
    ..writeln('declare')
    ..writeln('  v_release_id uuid;')
    ..writeln('begin')
    ..writeln('  select id into v_release_id')
    ..writeln('  from public.phrase_catalog_releases')
    ..writeln('  where locale = ${_sqlString(locale)} and release_version = 1;')
    ..writeln('  if v_release_id is null then')
    ..writeln(
        '    insert into public.phrase_catalog_releases (locale, release_version, schema_version, status, is_current)')
    ..writeln('    values (${_sqlString(locale)}, 1, 1, \'draft\', false)')
    ..writeln('    returning id into v_release_id;')
    ..writeln('  else')
    ..writeln('    update public.phrase_catalog_releases')
    ..writeln(
        "    set schema_version = 1, status = 'draft', is_current = false, published_at = null")
    ..writeln('    where id = v_release_id;')
    ..writeln('  end if;')
    ..writeln(
        '  insert into _completed_day_phrase_seed_release values (v_release_id);')
    ..writeln('end;')
    ..writeln('\$\$;')
    ..writeln()
    ..writeln('delete from public.phrase_catalog_release_entries')
    ..writeln(
        'where release_id = (select release_id from _completed_day_phrase_seed_release);')
    ..writeln()
    ..writeln('insert into public.phrase_catalog_release_entries (')
    ..writeln(
        '  release_id, phrase_id, category, tone, source_type, author, template,')
    ..writeln('  required_tokens, weight, enabled, content_version')
    ..writeln(')')
    ..writeln('select')
    ..writeln(
        '  s.release_id, e.id, e.category, e.tone, e.source_type, e.author, e.template,')
    ..writeln('  e.required_tokens, e.weight, e.enabled, e.content_version')
    ..writeln('from _completed_day_phrase_seed_release s')
    ..writeln('join _completed_day_phrase_expected e on true;')
    ..writeln()
    ..writeln('-- Pre-publication integrity checks.')
    ..writeln('do \$\$')
    ..writeln('declare')
    ..writeln('  v_release_id uuid;')
    ..writeln('  v_count integer;')
    ..writeln('begin')
    ..writeln(
        '  select release_id into v_release_id from _completed_day_phrase_seed_release;')
    ..writeln(
        '  select count(*) into v_count from public.motivational_phrase_translations t')
    ..writeln('    join _completed_day_phrase_expected e on e.id = t.phrase_id')
    ..writeln('    where t.locale = ${_sqlString(locale)};')
    ..writeln(
        "  if v_count <> 300 then raise exception 'Expected 300 $locale translations, got %', v_count; end if;")
    ..writeln(
        '  select count(*) into v_count from public.phrase_catalog_release_entries where release_id = v_release_id;')
    ..writeln(
        "  if v_count <> 300 then raise exception 'Expected 300 $locale release entries, got %', v_count; end if;")
    ..writeln(
        "  if (select count(*) from public.phrase_catalog_release_entries where release_id = v_release_id and category = 'personal') <> 50 then raise exception 'Expected 50 personal entries'; end if;")
    ..writeln(
        "  if (select count(*) from public.phrase_catalog_release_entries where release_id = v_release_id and category = 'consistency') <> 100 then raise exception 'Expected 100 consistency entries'; end if;")
    ..writeln(
        "  if (select count(*) from public.phrase_catalog_release_entries where release_id = v_release_id and category = 'motivation') <> 150 then raise exception 'Expected 150 motivation entries'; end if;")
    ..writeln(
        "  if exists (select 1 from public.phrase_catalog_release_entries where release_id = v_release_id and btrim(template) = '') then raise exception 'Empty release template'; end if;")
    ..writeln(
        "  if exists (select 1 from public.phrase_catalog_release_entries where release_id = v_release_id and weight <= 0) then raise exception 'Invalid release weight'; end if;")
    ..writeln(
        "  if exists (select 1 from public.phrase_catalog_release_entries where release_id = v_release_id and content_version <= 0) then raise exception 'Invalid release content version'; end if;")
    ..writeln(
        "  if exists (select 1 from public.phrase_catalog_release_entries where release_id = v_release_id and not (required_tokens <@ array['name', 'streak_label', 'progress']::text[])) then raise exception 'Invalid required token'; end if;")
    ..writeln(
        "  if (select count(distinct phrase_id) from public.phrase_catalog_release_entries where release_id = v_release_id) <> 300 then raise exception 'Duplicate release phrase IDs'; end if;")
    ..writeln('end;')
    ..writeln('\$\$;')
    ..writeln()
    ..writeln(
        "update public.phrase_catalog_releases set is_current = false where locale = ${_sqlString(locale)} and status = 'published' and is_current = true and id <> (select release_id from _completed_day_phrase_seed_release);")
    ..writeln(
        "update public.phrase_catalog_releases set status = 'published', published_at = now(), is_current = true where id = (select release_id from _completed_day_phrase_seed_release);")
    ..writeln()
    ..writeln('commit;');

  final file = File(output);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(buffer.toString());
  stdout.writeln('WROTE $output locale=$locale entries=${phrases.length}');
}

List<Map<String, dynamic>> _phrases(Map<String, dynamic> catalog) {
  final raw = catalog['phrases'];
  _expect(raw is List, 'phrases must be an array');
  return raw
      .cast<Object?>()
      .map<Map<String, dynamic>>((value) =>
          Map<String, dynamic>.from((value as Map).cast<String, dynamic>()))
      .toList(growable: false);
}

Map<String, dynamic> _expectedRow(Map<String, dynamic> phrase) =>
    <String, dynamic>{
      'id': phrase['id'],
      'category': phrase['category'],
      'tone': phrase['tone'],
      'sourceType': phrase['sourceType'],
      'author': phrase['author'],
      'requiredTokens': phrase['requiredTokens'],
      'weight': phrase['weight'],
      'enabled': phrase['enabled'],
      'template': phrase['template'],
      'contentVersion': phrase['contentVersion'],
    };

String _string(Map<String, dynamic> value, String key) {
  final result = value[key];
  _expect(result is String && result.trim().isNotEmpty, 'invalid $key');
  return result as String;
}

String _sqlString(Object? value) {
  if (value is! String) {
    throw FormatException('Expected SQL string, got $value');
  }
  return "'${value.replaceAll("'", "''")}'";
}

String _nullableSqlString(Object? value) =>
    value == null ? 'null' : _sqlString(value);

String _sqlTextArray(Object? value) {
  if (value is! List) throw FormatException('Expected token array');
  if (value.isEmpty) return "'{}'::text[]";
  return "array[${value.map(_sqlString).join(', ')}]::text[]";
}

String _sqlBoolean(Object? value) {
  if (value is! bool) throw FormatException('Expected boolean');
  return value ? 'true' : 'false';
}

String _sqlExpectedRow(Map<String, dynamic> row) =>
    '  (${_sqlString(row['id'])}, ${_sqlString(row['category'])}, '
    '${_sqlString(row['tone'])}, ${_sqlString(row['sourceType'])}, '
    '${_nullableSqlString(row['author'])}, ${_sqlTextArray(row['requiredTokens'])}, '
    '${row['weight']}, ${_sqlBoolean(row['enabled'])}, '
    '${_sqlString(row['template'])}, ${row['contentVersion']})';

String joinSqlValues(Iterable<Map<String, dynamic>> rows) {
  final values = rows.map(_sqlExpectedRow).toList(growable: false);
  if (values.isEmpty) throw StateError('A VALUES block must contain rows.');
  return values
      .asMap()
      .entries
      .map((entry) =>
          '${entry.value}${entry.key == values.length - 1 ? '' : ','}')
      .join('\n');
}

void _expect(bool condition, String message) {
  if (!condition) throw FormatException(message);
}
