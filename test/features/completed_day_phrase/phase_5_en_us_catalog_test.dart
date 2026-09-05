import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/completed_day_phrase/data/remote/phrase_catalog_dto.dart';
import 'package:rutio/features/completed_day_phrase/domain/phrase_catalog_validator.dart';

void main() {
  test('en-US v1 has the complete validated catalog', () {
    final catalog =
        _read('supabase/catalog/completed_day_phrase/en-US.v1.json');
    final phrases = _phrases(catalog);
    final parsed = PhraseCatalogJson.fromJson(catalog);

    expect(catalog['schemaVersion'], 1);
    expect(catalog['catalogVersion'], '1');
    expect(catalog['releaseVersion'], 1);
    expect(catalog['locale'], 'en-US');
    expect(phrases, hasLength(300));
    expect(parsed.phrases, hasLength(300));
    const PhraseCatalogValidator().validateCatalog(parsed);
    expect(_ids(phrases), _expectedIds());
    expect(
      {
        for (final phrase in phrases)
          phrase['category']: phrases
              .where((item) => item['category'] == phrase['category'])
              .length
      },
      {'personal': 50, 'consistency': 100, 'motivation': 150},
    );
    expect(
      phrases.every((phrase) =>
          (phrase['template'] as String).trim().isNotEmpty &&
          phrase['contentVersion'] == 1),
      isTrue,
    );
  });

  test('en-US keeps the es-ES structural contract and localized attributions',
      () {
    final es =
        _phrases(_read('supabase/catalog/completed_day_phrase/es-ES.v1.json'));
    final en =
        _phrases(_read('supabase/catalog/completed_day_phrase/en-US.v1.json'));
    const fields = <String>[
      'id',
      'category',
      'tone',
      'sourceType',
      'requiredTokens',
      'weight',
    ];
    expect(en, hasLength(es.length));
    for (var index = 0; index < es.length; index++) {
      for (final field in fields) {
        expect(en[index][field], es[index][field],
            reason: 'index=$index field=$field');
      }
    }
    expect(en[288]['author'], 'Popular proverb');
    expect(en[289]['author'], 'Traditional proverb');
    expect(en[291]['author'], 'Latin proverb');
    expect(en[298]['author'], 'Antonio Machado');
    expect(en[299]['author'], 'Delphic maxim');
    expect(
        en.sublist(0, 288).every((phrase) => phrase['author'] == null), isTrue);
  });

  test('en-US generated SQL is deterministic and has no final VALUES comma',
      () {
    final seed = File(
      'supabase/seeds/completed_day_phrase_en_us_v1.sql',
    ).readAsStringSync();
    final migration = File(
      'supabase/migrations/20260905130000_publish_completed_day_phrase_en_us_v1.sql',
    ).readAsStringSync();
    expect(seed, migration);
    final match = RegExp(
      r'insert into _completed_day_phrase_expected \([\s\S]*?\) values\n'
      r'([\s\S]*?)\n;',
      caseSensitive: false,
    ).firstMatch(seed);
    expect(match, isNotNull);
    final rows = match!
        .group(1)!
        .trimRight()
        .split('\n')
        .where((line) => line.trimLeft().startsWith('('))
        .toList(growable: false);
    expect(rows, hasLength(300));
    expect(rows.last.trimRight().endsWith(','), isFalse);
  });
}

Map<String, dynamic> _read(String path) =>
    Map<String, dynamic>.from(jsonDecode(File(path).readAsStringSync()) as Map);

List<Map<String, dynamic>> _phrases(Map<String, dynamic> catalog) =>
    (catalog['phrases'] as List)
        .cast<Object?>()
        .map((value) =>
            Map<String, dynamic>.from((value as Map).cast<String, dynamic>()))
        .toList(growable: false);

List<String> _ids(List<Map<String, dynamic>> phrases) =>
    phrases.map((phrase) => phrase['id'] as String).toList(growable: false);

List<String> _expectedIds() => [
      for (var index = 1; index <= 50; index++)
        'personal_${index.toString().padLeft(3, '0')}',
      for (var index = 1; index <= 100; index++)
        'consistency_${index.toString().padLeft(3, '0')}',
      for (var index = 1; index <= 150; index++)
        'motivation_${index.toString().padLeft(3, '0')}',
    ];
