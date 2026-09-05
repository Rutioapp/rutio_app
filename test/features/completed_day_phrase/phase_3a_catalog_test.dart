import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rutio/features/completed_day_phrase/application/completed_day_phrase_service.dart';
import 'package:rutio/features/completed_day_phrase/data/local/shared_preferences_phrase_catalog_cache_store.dart';
import 'package:rutio/features/completed_day_phrase/data/phrase_catalog_repository.dart';
import 'package:rutio/features/completed_day_phrase/data/remote/phrase_catalog_dto.dart';
import 'package:rutio/features/completed_day_phrase/data/remote/supabase_phrase_catalog_data_source.dart';
import 'package:rutio/features/completed_day_phrase/domain/motivational_phrase.dart';
import 'package:rutio/features/completed_day_phrase/domain/phrase_catalog_locale_resolver.dart';
import 'package:rutio/features/completed_day_phrase/domain/phrase_catalog_validator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('locale resolution is exact, market-aware and duplicate-free', () {
    expect(PhraseCatalogLocaleResolver.normalize('es_ES'), 'es-ES');
    expect(PhraseCatalogLocaleResolver.normalize('en_us'), 'en-US');
    expect(
      PhraseCatalogLocaleResolver.candidates('es'),
      <String>['es-ES', 'es'],
    );
    expect(
      PhraseCatalogLocaleResolver.candidates('es-MX'),
      <String>['es-MX', 'es-ES', 'es'],
    );
    expect(
      PhraseCatalogLocaleResolver.candidates('en'),
      <String>['en-US', 'en'],
    );
  });

  test('shared preferences cache keeps a recoverable double slot', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final cache = SharedPreferencesPhraseCatalogCacheStore(
      sharedPreferencesProvider: () async => prefs,
    );
    final entry = _entry('release-1', 'es-ES', 'v1');

    await cache.save(entry);
    expect((await cache.load('es-ES'))?.releaseId, 'release-1');
    await cache.save(_entry('release-en', 'en-US', '1'));
    expect((await cache.load('es-ES'))?.releaseId, 'release-1');
    expect((await cache.load('en-US'))?.releaseId, 'release-en');

    await prefs.setString(
      SharedPreferencesPhraseCatalogCacheStore.activeSlotKey('es-ES'),
      'corrupt',
    );
    expect((await cache.load('es-ES'))?.releaseId, 'release-1');
  });

  test('repository downloads a new release once and skips an unchanged one',
      () async {
    final cache = _MemoryCache();
    final remote = _FakeRemote(
      release: const PhraseCatalogReleaseDto(
        releaseId: 'release-1',
        locale: 'es-ES',
        releaseVersion: '2',
        schemaVersion: 1,
      ),
      snapshot: PhraseCatalogSnapshotDto(
        releaseId: 'release-1',
        catalog: _catalog('es-ES', '2'),
      ),
    );
    final repository = PhraseCatalogRepository(
      cache: cache,
      remote: remote,
      nowProvider: () => DateTime(2026, 9, 5),
    );

    expect(await repository.sync('es'), isTrue);
    expect(remote.snapshotCalls, 1);
    expect(await repository.sync('es'), isFalse);
    expect(remote.snapshotCalls, 1);
    expect((await repository.load('es')).catalogVersion, '2');
  });

  test('repository local load never calls remote and falls back to bundled',
      () async {
    final remote = _FakeRemote(
      release: const PhraseCatalogReleaseDto(
        releaseId: 'unused',
        locale: 'es-ES',
        releaseVersion: '1',
        schemaVersion: 1,
      ),
      snapshot: PhraseCatalogSnapshotDto(
        releaseId: 'unused',
        catalog: _catalog('es-ES', '1'),
      ),
    );
    final repository = PhraseCatalogRepository(
      cache: _MemoryCache(),
      remote: remote,
    );

    final catalog = await repository.load('es-MX');

    expect(catalog.locale, 'es');
    expect(remote.releaseCalls, 0);
  });

  test('invalid snapshot never replaces the active cache', () async {
    final cache = _MemoryCache()..value = _entry('old', 'es-ES', '1');
    final remote = _FakeRemote(
      release: const PhraseCatalogReleaseDto(
        releaseId: 'new',
        locale: 'es-ES',
        releaseVersion: '2',
        schemaVersion: 2,
      ),
      snapshot: PhraseCatalogSnapshotDto(
        releaseId: 'new',
        catalog: PhraseCatalog(
          schemaVersion: 2,
          catalogVersion: '2',
          locale: 'es-ES',
          phrases: const <MotivationalPhrase>[],
        ),
      ),
    );
    final repository = PhraseCatalogRepository(cache: cache, remote: remote);

    await expectLater(
      repository.sync('es'),
      throwsA(isA<PhraseCatalogValidationException>()),
    );
    expect(cache.value?.releaseId, 'old');
  });

  test('daily selection keeps its stable id when catalog version changes',
      () async {
    final history = _FakeHistory(
      PhraseDailySelection(
        phraseId: 'personal_001',
        localDate: DateTime(2026, 9, 5),
        locale: 'es-ES',
        catalogVersion: '1',
      ),
    );
    final service = CompletedDayPhraseService(
      catalogSource: _FakeSource(_catalog('es-ES', '2')),
      historyStore: history,
    );

    final result = await service.resolvePhrase(
      PhraseContext(
        userId: 'user-1',
        localDate: DateTime(2026, 9, 5),
        locale: 'es',
        name: null,
        streak: 1,
        streakLabel: null,
        progressLabel: '100%',
      ),
    );

    expect(result?.phrase.id, 'personal_001');
    expect(result?.fromDailySelection, isTrue);
    expect(history.savedSelection?.catalogVersion, '2');
    expect(history.savedSelection?.phraseId, 'personal_001');
  });

  test('remote DTO preserves metadata and rejects invalid token contract', () {
    final valid = <String, dynamic>{
      'schemaVersion': 1,
      'catalogVersion': '2',
      'locale': 'es-ES',
      'phrases': <Object>[
        <String, dynamic>{
          'id': 'personal_001',
          'category': 'personal',
          'tone': 'gentle',
          'sourceType': 'original',
          'author': null,
          'template': 'Hola {name}',
          'requiredTokens': <String>['name'],
          'weight': 10,
          'enabled': true,
          'contentVersion': 3,
        },
      ],
    };
    expect(PhraseCatalogJson.fromJson(valid).phrases.single.contentVersion, 3);
    expect(
      () => PhraseCatalogJson.fromJson(<String, dynamic>{
        ...valid,
        'phrases': <Object>[
          <String, dynamic>{
            ...(valid['phrases'] as List).single as Map<String, dynamic>,
            'requiredTokens': <String>['streak_label'],
          },
        ],
      }),
      throwsA(isA<PhraseCatalogValidationException>()),
    );
  });
}

PhraseCatalogCacheEntry _entry(
  String releaseId,
  String locale,
  String version,
) {
  return PhraseCatalogCacheEntry(
    releaseId: releaseId,
    releaseVersion: version,
    locale: locale,
    downloadedAt: DateTime(2026, 9, 5),
    catalog: _catalog(locale, version),
  );
}

PhraseCatalog _catalog(String locale, String version) => PhraseCatalog(
      schemaVersion: 1,
      catalogVersion: version,
      locale: locale,
      phrases: const <MotivationalPhrase>[
        MotivationalPhrase(
          id: 'personal_001',
          category: PhraseCategory.personal,
          tone: PhraseTone.gentle,
          sourceType: PhraseSourceType.original,
          author: null,
          template: 'Cierre del día',
          requiredTokens: <String>[],
          weight: 10,
          enabled: true,
          contentVersion: 1,
        ),
      ],
    );

class _MemoryCache implements PhraseCatalogCacheStore {
  PhraseCatalogCacheEntry? value;

  @override
  Future<PhraseCatalogCacheEntry?> load(String locale) async {
    return value?.locale == locale ? value : null;
  }

  @override
  Future<void> save(PhraseCatalogCacheEntry entry) async {
    value = entry;
  }
}

class _FakeRemote implements PhraseCatalogRemoteDataSource {
  _FakeRemote({required this.release, required this.snapshot});

  final PhraseCatalogReleaseDto release;
  final PhraseCatalogSnapshotDto snapshot;
  int snapshotCalls = 0;
  int releaseCalls = 0;

  @override
  Future<PhraseCatalogReleaseDto?> fetchPublishedRelease(String locale) async {
    releaseCalls++;
    return locale == 'es-ES' ? release : null;
  }

  @override
  Future<PhraseCatalogSnapshotDto> fetchSnapshot(
    String locale,
    int releaseVersion,
  ) async {
    snapshotCalls++;
    return snapshot;
  }
}

class _FakeSource implements PhraseCatalogSource {
  const _FakeSource(this.catalog);
  final PhraseCatalog catalog;

  @override
  Future<PhraseCatalog> load(String locale) async => catalog;
}

class _FakeHistory implements PhraseHistoryStore {
  _FakeHistory(this.daily);
  final PhraseDailySelection daily;
  PhraseDailySelection? savedSelection;

  @override
  Future<PhraseHistory> loadHistory(String userId) async =>
      const PhraseHistory();

  @override
  Future<void> saveHistory(String userId, PhraseHistory history) async {}

  @override
  Future<PhraseDailySelection?> loadDailySelection(
    String userId,
    DateTime localDate, {
    String? locale,
  }) async =>
      daily;

  @override
  Future<void> saveDailySelection(
    String userId,
    DateTime localDate,
    PhraseDailySelection selection,
  ) async {
    savedSelection = selection;
  }
}
