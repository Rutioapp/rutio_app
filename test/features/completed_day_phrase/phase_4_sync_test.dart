import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rutio/features/completed_day_phrase/application/completed_day_phrase_service.dart';
import 'package:rutio/features/completed_day_phrase/application/phrase_catalog_sync_coordinator.dart';
import 'package:rutio/features/completed_day_phrase/data/local/shared_preferences_completed_day_phrase_store.dart';
import 'package:rutio/features/completed_day_phrase/data/local/shared_preferences_phrase_catalog_cache_store.dart';
import 'package:rutio/features/completed_day_phrase/data/phrase_catalog_repository.dart';
import 'package:rutio/features/completed_day_phrase/data/remote/phrase_catalog_dto.dart';
import 'package:rutio/features/completed_day_phrase/data/remote/supabase_phrase_catalog_data_source.dart';
import 'package:rutio/features/completed_day_phrase/domain/motivational_phrase.dart';
import 'package:rutio/features/completed_day_phrase/domain/phrase_catalog_validator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('remote es-ES v1 snapshot validates and caches all 300 entries',
      () async {
    final raw = jsonDecode(
      File('supabase/catalog/completed_day_phrase/es-ES.v1.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    final catalog = PhraseCatalogJson.fromJson(raw);
    final cache = _MemoryCache();
    final logs = <String>[];
    final repository = PhraseCatalogRepository(
      cache: cache,
      remote: _FakeRemote(
        release: _release(),
        snapshot: PhraseCatalogSnapshotDto(
          releaseId: 'release-1',
          catalog: catalog,
        ),
      ),
      logger: logs.add,
    );

    expect(await repository.sync('es'), isTrue);
    expect(cache.value?.catalog.phrases, hasLength(300));
    expect(
      logs,
      contains(
          '[COMPLETED_DAY_PHRASE] catalog_snapshot_downloaded entries=300'),
    );
    expect(
      logs,
      contains('[COMPLETED_DAY_PHRASE] catalog_snapshot_validated entries=300'),
    );
  });

  test('Spanish sync resolves es and es_ES to remote es-ES release', () async {
    final cache = _MemoryCache();
    final logs = <String>[];
    final remote = _FakeRemote(
      release: _release(),
      snapshot: _snapshot(),
    );
    final repository = PhraseCatalogRepository(
      cache: cache,
      remote: remote,
      logger: logs.add,
    );

    expect(await repository.sync('es'), isTrue);
    expect(remote.releaseRequests.single, 'es-ES');
    expect(remote.snapshotCalls, 1);
    expect(cache.value?.locale, 'es-ES');
    expect(
        logs, contains('[COMPLETED_DAY_PHRASE] catalog_sync_start locale=es'));
    expect(
      logs,
      contains('[COMPLETED_DAY_PHRASE] catalog_snapshot_validated entries=1'),
    );

    remote.releaseRequests.clear();
    expect(await repository.sync('es_ES'), isFalse);
    expect(remote.releaseRequests.single, 'es-ES');
    expect(remote.snapshotCalls, 1);
    expect(
      logs,
      contains('[COMPLETED_DAY_PHRASE] catalog_release_unchanged version=1'),
    );
  });

  test('invalid snapshot and future schema keep the active cache intact',
      () async {
    final cache = _MemoryCache()..value = _entry('old', '1');
    final invalidRepository = PhraseCatalogRepository(
      cache: cache,
      remote: _FakeRemote(
        release: _release(id: 'invalid'),
        snapshot: PhraseCatalogSnapshotDto(
          releaseId: 'invalid',
          catalog: PhraseCatalog(
            schemaVersion: 1,
            catalogVersion: '1',
            locale: 'es-ES',
            phrases: <MotivationalPhrase>[
              _phrase(template: '{unknown}', requiredTokens: const ['unknown']),
            ],
          ),
        ),
      ),
    );
    await expectLater(
      invalidRepository.sync('es'),
      throwsA(isA<PhraseCatalogValidationException>()),
    );
    expect(cache.value?.releaseId, 'old');

    final futureRemote = _FakeRemote(
      release: _release(id: 'future', schemaVersion: 2),
      snapshot: _snapshot(),
    );
    final futureRepository = PhraseCatalogRepository(
      cache: cache,
      remote: futureRemote,
    );
    await expectLater(
      futureRepository.sync('es'),
      throwsA(isA<PhraseCatalogValidationException>()),
    );
    expect(cache.value?.releaseId, 'old');
    expect(futureRemote.snapshotCalls, 0);
  });

  test('bundled selection keeps its ID after remote cache sync and restart',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final cache = SharedPreferencesPhraseCatalogCacheStore(
      sharedPreferencesProvider: () async => prefs,
    );
    final history = SharedPreferencesCompletedDayPhraseStore(
      sharedPreferencesProvider: () async => prefs,
    );
    final date = DateTime(2026, 9, 5);
    await history.saveDailySelection(
      'user-1',
      date,
      PhraseDailySelection(
        phraseId: 'motivation_015',
        localDate: DateTime(2026, 9, 5),
        locale: 'es-ES',
        catalogVersion: 'fallback-es-v1',
      ),
    );
    final remote = _FakeRemote(
      release: _release(),
      snapshot: _snapshot(id: 'motivation_015'),
    );
    final repository = PhraseCatalogRepository(cache: cache, remote: remote);
    final service = CompletedDayPhraseService(
      catalogSource: repository,
      historyStore: history,
    );
    final context = _context(date);

    expect((await service.resolvePhrase(context))?.phrase.id, 'motivation_015');
    expect(await repository.sync('es'), isTrue);
    expect((await service.resolvePhrase(context))?.phrase.id, 'motivation_015');

    final restartedRemote = _FakeRemote(
      release: _release(),
      snapshot: _snapshot(id: 'motivation_015'),
    );
    final restartedRepository = PhraseCatalogRepository(
      cache: SharedPreferencesPhraseCatalogCacheStore(
        sharedPreferencesProvider: () async => prefs,
      ),
      remote: restartedRemote,
    );
    final restartedService = CompletedDayPhraseService(
      catalogSource: restartedRepository,
      historyStore: history,
    );
    expect(await restartedRepository.sync('es'), isFalse);
    expect(restartedRemote.snapshotCalls, 0);
    expect(
      (await restartedService.resolvePhrase(context))?.phrase.id,
      'motivation_015',
    );
  });

  test('coordinator deduplicates simultaneous sync triggers', () async {
    final gate = Completer<void>();
    final remote = _FakeRemote(
      release: _release(),
      snapshot: _snapshot(),
      snapshotGate: gate,
    );
    final coordinator = PhraseCatalogSyncCoordinator(
      repository: PhraseCatalogRepository(
        cache: _MemoryCache(),
        remote: remote,
      ),
      currentUserIdProvider: () => 'user-1',
      localeProvider: () => 'es',
      scopeProvider: () => (userId: 'user-1', epoch: 1),
    );

    final first = coordinator.syncAfterBootstrap(
      userId: 'user-1',
      scopeUserId: 'user-1',
      scopeEpoch: 1,
    );
    await Future<void>.delayed(Duration.zero);
    final second = coordinator.syncAfterBootstrap(
      userId: 'user-1',
      scopeUserId: 'user-1',
      scopeEpoch: 1,
    );
    gate.complete();
    await Future.wait(<Future<void>>[first, second]);

    expect(remote.snapshotCalls, 1);
    coordinator.dispose();
  });

  test('cache logs inactive-slot write and active-slot switch', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final logs = <String>[];
    final cache = SharedPreferencesPhraseCatalogCacheStore(
      sharedPreferencesProvider: () async => prefs,
      logger: logs.add,
    );

    await cache.save(_entry('release-1', '1'));
    await cache.save(_entry('release-2', '2'));

    expect(
      logs,
      contains(
        '[COMPLETED_DAY_PHRASE] catalog_cache_write_start '
        'active_slot=none inactive_slot=a release=1',
      ),
    );
    expect(
      logs,
      contains(
        '[COMPLETED_DAY_PHRASE] catalog_cache_write_start '
        'active_slot=a inactive_slot=b release=2',
      ),
    );
    expect(
      logs,
      contains(
        '[COMPLETED_DAY_PHRASE] catalog_cache_write_success '
        'release=2 active_slot=a->b',
      ),
    );
    expect(
      prefs.getString(
        SharedPreferencesPhraseCatalogCacheStore.activeSlotKey('es-ES'),
      ),
      'b',
    );
  });
}

PhraseCatalogReleaseDto _release({
  String id = 'release-1',
  int schemaVersion = 1,
}) =>
    PhraseCatalogReleaseDto(
      releaseId: id,
      locale: 'es-ES',
      releaseVersion: '1',
      schemaVersion: schemaVersion,
    );

PhraseCatalogSnapshotDto _snapshot({String id = 'personal_001'}) =>
    PhraseCatalogSnapshotDto(
      releaseId: 'release-1',
      catalog: PhraseCatalog(
        schemaVersion: 1,
        catalogVersion: '1',
        locale: 'es-ES',
        phrases: <MotivationalPhrase>[_phrase(id: id)],
      ),
    );

MotivationalPhrase _phrase({
  String id = 'personal_001',
  String template = 'Cierre del día',
  List<String> requiredTokens = const <String>[],
}) =>
    MotivationalPhrase(
      id: id,
      category: id.startsWith('motivation_')
          ? PhraseCategory.motivation
          : PhraseCategory.personal,
      tone: PhraseTone.gentle,
      sourceType: PhraseSourceType.original,
      author: null,
      template: template,
      requiredTokens: requiredTokens,
      weight: 10,
      enabled: true,
      contentVersion: 1,
    );

PhraseCatalogCacheEntry _entry(String releaseId, String version) =>
    PhraseCatalogCacheEntry(
      releaseId: releaseId,
      releaseVersion: version,
      locale: 'es-ES',
      downloadedAt: DateTime(2026, 9, 5),
      catalog: PhraseCatalog(
        schemaVersion: 1,
        catalogVersion: version,
        locale: 'es-ES',
        phrases: <MotivationalPhrase>[_phrase()],
      ),
    );

PhraseContext _context(DateTime date) => PhraseContext(
      userId: 'user-1',
      localDate: date,
      locale: 'es',
      name: null,
      streak: 1,
      streakLabel: '1 día',
      progressLabel: '100 %',
    );

class _MemoryCache implements PhraseCatalogCacheStore {
  PhraseCatalogCacheEntry? value;

  @override
  Future<PhraseCatalogCacheEntry?> load(String locale) async =>
      value?.locale == locale ? value : null;

  @override
  Future<void> save(PhraseCatalogCacheEntry entry) async => value = entry;
}

class _FakeRemote implements PhraseCatalogRemoteDataSource {
  _FakeRemote({
    required this.release,
    required this.snapshot,
    this.snapshotGate,
  });

  final PhraseCatalogReleaseDto release;
  final PhraseCatalogSnapshotDto snapshot;
  final Completer<void>? snapshotGate;
  final List<String> releaseRequests = <String>[];
  int snapshotCalls = 0;

  @override
  Future<PhraseCatalogReleaseDto?> fetchPublishedRelease(String locale) async {
    releaseRequests.add(locale);
    return locale == 'es-ES' ? release : null;
  }

  @override
  Future<PhraseCatalogSnapshotDto> fetchSnapshot(
    String locale,
    int releaseVersion,
  ) async {
    snapshotCalls++;
    if (snapshotGate != null) await snapshotGate!.future;
    return snapshot;
  }
}
