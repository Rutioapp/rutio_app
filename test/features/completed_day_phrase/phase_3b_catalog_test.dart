import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rutio/features/completed_day_phrase/data/local/shared_preferences_phrase_catalog_cache_store.dart';
import 'package:rutio/features/completed_day_phrase/data/phrase_catalog_repository.dart';
import 'package:rutio/features/completed_day_phrase/data/remote/phrase_catalog_dto.dart';
import 'package:rutio/features/completed_day_phrase/data/remote/supabase_phrase_catalog_data_source.dart';
import 'package:rutio/features/completed_day_phrase/domain/motivational_phrase.dart';
import 'package:rutio/features/completed_day_phrase/domain/phrase_catalog_validator.dart';

const _catalogPath = 'supabase/catalog/completed_day_phrase/es-ES.v1.json';

void main() {
  late Map<String, dynamic> raw;
  late PhraseCatalog catalog;

  setUpAll(() {
    raw = jsonDecode(File(_catalogPath).readAsStringSync())
        as Map<String, dynamic>;
    catalog = PhraseCatalogJson.fromJson(raw);
  });

  test('loads the master catalog with exact distribution and IDs', () {
    expect(catalog.locale, 'es-ES');
    expect(catalog.catalogVersion, '1');
    expect(catalog.schemaVersion, 1);
    expect(catalog.phrases, hasLength(300));
    expect(
      catalog.phrases
          .where((phrase) => phrase.category == PhraseCategory.personal),
      hasLength(50),
    );
    expect(
      catalog.phrases
          .where((phrase) => phrase.category == PhraseCategory.consistency),
      hasLength(100),
    );
    expect(
      catalog.phrases
          .where((phrase) => phrase.category == PhraseCategory.motivation),
      hasLength(150),
    );

    final ids = catalog.phrases.map((phrase) => phrase.id).toList();
    expect(ids.take(50), contains('personal_001'));
    expect(ids.take(50), contains('personal_050'));
    expect(ids.skip(50).take(100), contains('consistency_001'));
    expect(ids.skip(50).take(100), contains('consistency_100'));
    expect(ids.skip(150).take(150), contains('motivation_001'));
    expect(ids.skip(150).take(150), contains('motivation_150'));
  });

  test('DTO and domain validator accept the complete RPC-shaped snapshot', () {
    final snapshot = PhraseCatalogSnapshotDto.fromJson(<String, dynamic>{
      'releaseId': 'release-es-es-v1',
      ...raw,
    });
    expect(snapshot.releaseId, 'release-es-es-v1');
    expect(snapshot.catalog.phrases, hasLength(300));
    const PhraseCatalogValidator().validateCatalog(snapshot.catalog);
  });

  test('master samples preserve templates, tokens and attribution separation',
      () {
    final byId = <String, MotivationalPhrase>{
      for (final phrase in catalog.phrases) phrase.id: phrase,
    };
    expect(byId['personal_001']!.template,
        '{name}, hoy te has demostrado que puedes contar contigo.');
    expect(byId['personal_001']!.requiredTokens, ['name']);
    expect(byId['personal_001']!.author, isNull);
    expect(byId['motivation_150']!.template, 'Conócete a ti mismo.');
    expect(byId['motivation_150']!.author, 'Máxima délfica');
    expect(byId['motivation_150']!.sourceType, PhraseSourceType.quote);
    expect(byId['motivation_149']!.template,
        'Caminante, no hay camino, se hace camino al andar.');
    expect(byId['motivation_149']!.author, 'Antonio Machado');
    expect(
        byId['motivation_149']!.template, isNot(contains('Antonio Machado')));
  });

  test('cache stores and reloads the complete catalog payload', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final store = SharedPreferencesPhraseCatalogCacheStore(
      sharedPreferencesProvider: () async => prefs,
    );
    await store.save(
      PhraseCatalogCacheEntry(
        releaseId: 'release-es-es-v1',
        releaseVersion: '1',
        locale: 'es-ES',
        downloadedAt: DateTime.utc(2026, 9, 5),
        catalog: catalog,
      ),
    );
    final activeSlot = prefs.getString(
      SharedPreferencesPhraseCatalogCacheStore.activeSlotKey('es-ES'),
    );
    final slot = prefs.getString(
      'completed_day_phrase_catalog_v1/es-ES/slot_$activeSlot',
    );
    final loaded = await store.load('es-ES');
    expect(loaded, isNotNull);
    expect(loaded!.catalog.phrases, hasLength(300));
    expect(slot, isNotNull);
    final bytes = utf8.encode(slot!);
    stdout.writeln(
        '[COMPLETED_DAY_PHRASE] cache_size single_slot_bytes=${bytes.length} double_slot_bytes=${bytes.length * 2}');
    expect(bytes.length, greaterThan(70000));
    expect(bytes.length * 2, lessThan(250000));
  });

  test('repository returns the complete cached catalog without remote access',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final store = SharedPreferencesPhraseCatalogCacheStore(
      sharedPreferencesProvider: () async => prefs,
    );
    await store.save(
      PhraseCatalogCacheEntry(
        releaseId: 'release-es-es-v1',
        releaseVersion: '1',
        locale: 'es-ES',
        downloadedAt: DateTime.utc(2026, 9, 5),
        catalog: catalog,
      ),
    );
    final remote = _FailingRemote();
    final repository = PhraseCatalogRepository(cache: store, remote: remote);

    final loaded = await repository.load('es-ES');
    expect(loaded.phrases, hasLength(300));
    expect(remote.called, isFalse);
  });
}

class _FailingRemote implements PhraseCatalogRemoteDataSource {
  bool called = false;

  @override
  Future<PhraseCatalogReleaseDto?> fetchPublishedRelease(String locale) async {
    called = true;
    throw StateError('remote should not be used by cached load');
  }

  @override
  Future<PhraseCatalogSnapshotDto> fetchSnapshot(
    String locale,
    int releaseVersion,
  ) async {
    called = true;
    throw StateError('remote should not be used by cached load');
  }
}
