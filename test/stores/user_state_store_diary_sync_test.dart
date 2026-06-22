import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/diary_v2_supabase_repository.dart';
import 'package:rutio/data/repositories/repository_result.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/models/daily_mood.dart';
import 'package:rutio/models/diary_entry.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserStateStore Diary V2 sync', () {
    test('create keeps local state even if Diary V2 upsert fails', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final fakeRepository = _FakeDiaryV2SupabaseRepository(
        upsertResult: RepositoryResult<DiaryEntry>.failure(
          const RepositoryError(
            code: RepositoryErrorCode.network,
            message: 'offline',
          ),
        ),
      );
      final store = await _buildStore(
        diaryV2SupabaseRepository: fakeRepository,
        authenticatedUserId: 'user-1',
      );
      const entry = DiaryEntry(
        id: 'entry-1',
        createdAt: 1718445600123,
        text: 'Morning reset',
      );

      await store.addDiaryEntry(entry);
      await _flushAsyncWork();

      expect(store.diaryEntries.map((item) => item.id), contains('entry-1'));
      expect(fakeRepository.upsertCalls, 1);
      expect(fakeRepository.lastUpsertedEntry?.id, 'entry-1');
    });

    test('edit updates local state and calls Diary V2 upsert', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final fakeRepository = _FakeDiaryV2SupabaseRepository();
      final store = await _buildStore(
        diaryV2SupabaseRepository: fakeRepository,
        authenticatedUserId: 'user-1',
        entries: const <DiaryEntry>[
          DiaryEntry(
            id: 'entry-1',
            createdAt: 1718445600123,
            text: 'Old text',
            title: 'Old title',
            body: 'Old body',
          ),
        ],
      );

      await store.updateDiaryEntry(
        const DiaryEntry(
          id: 'entry-1',
          createdAt: 1718445600123,
          text: 'New text',
          title: 'New title',
          body: 'New body',
          mood: 2,
          tags: <String>['focus'],
        ),
      );
      await _flushAsyncWork();

      final updated =
          store.diaryEntries.singleWhere((item) => item.id == 'entry-1');
      expect(updated.title, 'New title');
      expect(updated.body, 'New body');
      expect(updated.mood, 2);
      expect(updated.tags, <String>['focus']);
      expect(fakeRepository.upsertCalls, 1);
      expect(fakeRepository.lastUpsertedEntry?.title, 'New title');
    });

    test('delete removes local state and calls Diary V2 delete', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final fakeRepository = _FakeDiaryV2SupabaseRepository();
      final store = await _buildStore(
        diaryV2SupabaseRepository: fakeRepository,
        authenticatedUserId: 'user-1',
        entries: const <DiaryEntry>[
          DiaryEntry(
            id: 'entry-1',
            createdAt: 1718445600123,
            text: 'Morning reset',
            remoteId: '550e8400-e29b-41d4-a716-446655440000',
          ),
        ],
      );

      await store.deleteDiaryEntry('entry-1');
      await _flushAsyncWork();

      expect(store.diaryEntries, isEmpty);
      expect(fakeRepository.deleteCalls, 1);
      expect(fakeRepository.lastDeletedLocalId, 'entry-1');
      expect(fakeRepository.lastDeletedRemoteId, isNull);
    });

    test('delete keeps local removal even if Diary V2 remote delete fails',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final fakeRepository = _FakeDiaryV2SupabaseRepository(
        deleteResult: RepositoryResult<void>.failure(
          const RepositoryError(
            code: RepositoryErrorCode.network,
            message: 'offline',
          ),
        ),
      );
      final store = await _buildStore(
        diaryV2SupabaseRepository: fakeRepository,
        authenticatedUserId: 'user-1',
        entries: const <DiaryEntry>[
          DiaryEntry(
            id: 'entry-1',
            createdAt: 1718445600123,
            text: 'Morning reset',
          ),
        ],
      );

      await store.deleteDiaryEntry('entry-1');
      await _flushAsyncWork();

      expect(store.diaryEntries, isEmpty);
      expect(fakeRepository.deleteCalls, 1);
      expect(fakeRepository.lastDeletedLocalId, 'entry-1');
    });

    test('no-auth skips Diary V2 sync and keeps local behavior unchanged',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final fakeRepository = _FakeDiaryV2SupabaseRepository();
      final store = await _buildStore(
        diaryV2SupabaseRepository: fakeRepository,
        authenticatedUserId: null,
      );
      const entry = DiaryEntry(
        id: 'entry-1',
        createdAt: 1718445600123,
        text: 'Morning reset',
      );

      await store.addDiaryEntry(entry);
      await store.updateDiaryEntry(
        const DiaryEntry(
          id: 'entry-1',
          createdAt: 1718445600123,
          text: 'Updated text',
        ),
      );
      await store.deleteDiaryEntry('entry-1');
      await _flushAsyncWork();

      expect(store.diaryEntries, isEmpty);
      expect(fakeRepository.upsertCalls, 0);
      expect(fakeRepository.deleteCalls, 0);
      expect(fakeRepository.dailyMoodUpsertCalls, 0);
    });

    test('setDailyMood keeps local state even if daily mood upsert fails',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final fakeRepository = _FakeDiaryV2SupabaseRepository(
        dailyMoodUpsertResult: RepositoryResult<DailyMood>.failure(
          const RepositoryError(
            code: RepositoryErrorCode.network,
            message: 'offline',
          ),
        ),
      );
      final store = await _buildStore(
        diaryV2SupabaseRepository: fakeRepository,
        authenticatedUserId: 'user-1',
      );
      final dailyMood = DailyMood(
        date: DateTime(2026, 6, 22, 18, 30),
        mood: 2,
        createdAt: 0,
        updatedAt: 0,
      );

      await store.setDailyMood(dailyMood);
      await _flushAsyncWork();

      final persisted = store.dailyMoodForDate(DateTime(2026, 6, 22));
      expect(persisted, isNotNull);
      expect(persisted?.mood, 2);
      expect(fakeRepository.dailyMoodUpsertCalls, 1);
      expect(fakeRepository.lastUpsertedDailyMood?.dateKey, '2026-06-22');
      expect(fakeRepository.lastUpsertedDailyMood?.mood, 2);
      expect(fakeRepository.upsertCalls, 0);
    });

    test('setDailyMood calls daily mood upsert with persisted date and mood',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final fakeRepository = _FakeDiaryV2SupabaseRepository();
      final store = await _buildStore(
        diaryV2SupabaseRepository: fakeRepository,
        authenticatedUserId: 'user-1',
      );

      await store.setDailyMood(
        DailyMood(
          date: DateTime(2026, 6, 22, 23, 59),
          mood: 1,
          note: 'steady',
          createdAt: 0,
          updatedAt: 0,
        ),
      );
      await _flushAsyncWork();

      expect(fakeRepository.dailyMoodUpsertCalls, 1);
      expect(fakeRepository.lastUpsertedDailyMood?.date, DateTime(2026, 6, 22));
      expect(fakeRepository.lastUpsertedDailyMood?.mood, 1);
      expect(fakeRepository.lastUpsertedDailyMood?.note, 'steady');
      expect(fakeRepository.upsertCalls, 0);
    });

    test(
        'changing DailyMood for the same day upserts updates without duplicates',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final fakeRepository = _FakeDiaryV2SupabaseRepository();
      final store = await _buildStore(
        diaryV2SupabaseRepository: fakeRepository,
        authenticatedUserId: 'user-1',
      );

      await store.setDailyMood(
        DailyMood(
          date: DateTime(2026, 6, 22, 9),
          mood: 0,
          createdAt: 0,
          updatedAt: 0,
        ),
      );
      await store.setDailyMood(
        DailyMood(
          date: DateTime(2026, 6, 22, 20),
          mood: 2,
          createdAt: 0,
          updatedAt: 0,
        ),
      );
      await _flushAsyncWork();

      expect(store.dailyMoods, hasLength(1));
      expect(store.dailyMoods.single.dateKey, '2026-06-22');
      expect(store.dailyMoods.single.mood, 2);
      expect(fakeRepository.dailyMoodUpsertCalls, 2);
      expect(
        fakeRepository.upsertedDailyMoods.map((item) => item.dateKey).toList(),
        <String>['2026-06-22', '2026-06-22'],
      );
      expect(fakeRepository.upsertCalls, 0);
    });

    test('no-auth skips daily mood remote sync safely', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final fakeRepository = _FakeDiaryV2SupabaseRepository();
      final store = await _buildStore(
        diaryV2SupabaseRepository: fakeRepository,
        authenticatedUserId: null,
      );

      await store.setDailyMood(
        DailyMood(
          date: DateTime(2026, 6, 22),
          mood: -1,
          createdAt: 0,
          updatedAt: 0,
        ),
      );
      await _flushAsyncWork();

      expect(store.dailyMoods, hasLength(1));
      expect(store.dailyMoods.single.mood, -1);
      expect(fakeRepository.dailyMoodUpsertCalls, 0);
      expect(fakeRepository.upsertCalls, 0);
    });

    test('remote diary entry with new local id is added locally on pull',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final fakeRepository = _FakeDiaryV2SupabaseRepository(
        fetchedDiaryEntries: const <DiaryEntry>[
          DiaryEntry(
            id: 'remote-entry-1',
            createdAt: 1718445600123,
            text: 'Pulled from remote',
            mood: 2,
          ),
        ],
      );
      final store = await _buildStore(
        diaryV2SupabaseRepository: fakeRepository,
        authenticatedUserId: 'user-1',
      );

      await store.syncDiaryV2FromRemoteBestEffort();

      expect(store.diaryEntries, hasLength(1));
      expect(store.diaryEntries.single.id, 'remote-entry-1');
      expect(store.diaryEntries.single.text, 'Pulled from remote');
      expect(store.diaryEntries.single.mood, 2);
      expect(fakeRepository.fetchDiaryEntriesCalls, 1);
      expect(fakeRepository.fetchDailyMoodsCalls, 1);
    });

    test('controlled auto sync triggers remote pull when allowed', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      var now = DateTime(2026, 6, 22, 10, 0);

      final fakeRepository = _FakeDiaryV2SupabaseRepository(
        fetchedDiaryEntries: const <DiaryEntry>[
          DiaryEntry(
            id: 'remote-entry-1',
            createdAt: 1718445600123,
            text: 'Pulled on open',
          ),
        ],
      );
      final store = await _buildStore(
        diaryV2SupabaseRepository: fakeRepository,
        authenticatedUserId: 'user-1',
        nowProvider: () => now,
      );

      await store.autoSyncDiaryV2FromRemoteIfNeeded();

      expect(fakeRepository.fetchDiaryEntriesCalls, 1);
      expect(fakeRepository.fetchDailyMoodsCalls, 1);
      expect(store.lastDiaryV2RemotePullAttemptAt, now);
      expect(store.lastDiaryV2RemotePullSuccessAt, now);
      expect(store.diaryEntries.single.id, 'remote-entry-1');
    });

    test('controlled auto sync does not trigger repeatedly inside cooldown',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      var now = DateTime(2026, 6, 22, 10, 0);

      final fakeRepository = _FakeDiaryV2SupabaseRepository();
      final store = await _buildStore(
        diaryV2SupabaseRepository: fakeRepository,
        authenticatedUserId: 'user-1',
        nowProvider: () => now,
      );

      await store.autoSyncDiaryV2FromRemoteIfNeeded();
      now = now.add(const Duration(minutes: 5));
      await store.autoSyncDiaryV2FromRemoteIfNeeded();
      now = now.add(UserStateStore.diaryV2AutoPullCooldown);
      await store.autoSyncDiaryV2FromRemoteIfNeeded();

      expect(fakeRepository.fetchDiaryEntriesCalls, 2);
      expect(fakeRepository.fetchDailyMoodsCalls, 2);
    });

    test('controlled auto sync does not start if a sync is already in progress',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final fetchCompleter = Completer<RepositoryResult<List<DiaryEntry>>>();

      final fakeRepository = _FakeDiaryV2SupabaseRepository(
        fetchDiaryEntriesHandler: () => fetchCompleter.future,
      );
      final store = await _buildStore(
        diaryV2SupabaseRepository: fakeRepository,
        authenticatedUserId: 'user-1',
      );

      final firstSync = store.autoSyncDiaryV2FromRemoteIfNeeded();
      await Future<void>.delayed(Duration.zero);
      expect(store.isDiaryV2RemotePullRunning, isTrue);

      await store.autoSyncDiaryV2FromRemoteIfNeeded();

      expect(fakeRepository.fetchDiaryEntriesCalls, 1);
      expect(fakeRepository.fetchDailyMoodsCalls, 0);

      fetchCompleter.complete(
        const RepositoryResult<List<DiaryEntry>>.success(data: <DiaryEntry>[]),
      );
      await firstSync;

      expect(store.isDiaryV2RemotePullRunning, isFalse);
      expect(fakeRepository.fetchDailyMoodsCalls, 1);
    });

    test('remote diary entry with existing local id does not duplicate on pull',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final fakeRepository = _FakeDiaryV2SupabaseRepository(
        fetchedDiaryEntries: const <DiaryEntry>[
          DiaryEntry(
            id: 'entry-1',
            createdAt: 1718445600123,
            text: 'Remote copy',
          ),
        ],
      );
      final store = await _buildStore(
        diaryV2SupabaseRepository: fakeRepository,
        authenticatedUserId: 'user-1',
        entries: const <DiaryEntry>[
          DiaryEntry(
            id: 'entry-1',
            createdAt: 1718445600123,
            text: 'Local copy',
          ),
        ],
      );

      await store.syncDiaryV2FromRemoteBestEffort();

      expect(store.diaryEntries, hasLength(1));
      expect(store.diaryEntries.single.id, 'entry-1');
    });

    test('local diary entry is not removed if missing remotely on pull',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final fakeRepository = _FakeDiaryV2SupabaseRepository(
        fetchedDiaryEntries: const <DiaryEntry>[],
      );
      final store = await _buildStore(
        diaryV2SupabaseRepository: fakeRepository,
        authenticatedUserId: 'user-1',
        entries: const <DiaryEntry>[
          DiaryEntry(
            id: 'entry-1',
            createdAt: 1718445600123,
            text: 'Keep me local',
          ),
        ],
      );

      await store.syncDiaryV2FromRemoteBestEffort();

      expect(store.diaryEntries, hasLength(1));
      expect(store.diaryEntries.single.id, 'entry-1');
      expect(store.diaryEntries.single.text, 'Keep me local');
    });

    test('diary entry conflict keeps local when local timestamp is newer',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final fakeRepository = _FakeDiaryV2SupabaseRepository(
        fetchedDiaryEntries: const <DiaryEntry>[
          DiaryEntry(
            id: 'entry-1',
            createdAt: 100,
            text: 'Older remote text',
          ),
        ],
      );
      final store = await _buildStore(
        diaryV2SupabaseRepository: fakeRepository,
        authenticatedUserId: 'user-1',
        entries: const <DiaryEntry>[
          DiaryEntry(
            id: 'entry-1',
            createdAt: 200,
            text: 'Newer local text',
          ),
        ],
      );

      await store.syncDiaryV2FromRemoteBestEffort();

      expect(store.diaryEntries.single.text, 'Newer local text');
      expect(store.diaryEntries.single.createdAt, 200);
    });

    test('diary entry conflict keeps local when timestamp certainty is weak',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final fakeRepository = _FakeDiaryV2SupabaseRepository(
        fetchedDiaryEntries: const <DiaryEntry>[
          DiaryEntry(
            id: 'entry-1',
            createdAt: 0,
            text: 'Remote uncertain text',
          ),
        ],
      );
      final store = await _buildStore(
        diaryV2SupabaseRepository: fakeRepository,
        authenticatedUserId: 'user-1',
        entries: const <DiaryEntry>[
          DiaryEntry(
            id: 'entry-1',
            createdAt: 0,
            text: 'Local uncertain text',
          ),
        ],
      );

      await store.syncDiaryV2FromRemoteBestEffort();

      expect(store.diaryEntries.single.text, 'Local uncertain text');
    });

    test('remote newer diary entry updates local when timestamp is clear',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final fakeRepository = _FakeDiaryV2SupabaseRepository(
        fetchedDiaryEntries: const <DiaryEntry>[
          DiaryEntry(
            id: 'entry-1',
            createdAt: 300,
            text: 'Remote newer text',
            mood: -1,
          ),
        ],
      );
      final store = await _buildStore(
        diaryV2SupabaseRepository: fakeRepository,
        authenticatedUserId: 'user-1',
        entries: const <DiaryEntry>[
          DiaryEntry(
            id: 'entry-1',
            createdAt: 100,
            text: 'Old local text',
            mood: 2,
          ),
        ],
      );

      await store.syncDiaryV2FromRemoteBestEffort();

      expect(store.diaryEntries.single.text, 'Remote newer text');
      expect(store.diaryEntries.single.createdAt, 300);
      expect(store.diaryEntries.single.mood, -1);
    });

    test('remote daily mood with new date is added locally on pull', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final fakeRepository = _FakeDiaryV2SupabaseRepository(
        fetchedDailyMoods: <DailyMood>[
          DailyMood(
            date: DateTime(2026, 6, 22),
            mood: 1,
            createdAt: 10,
            updatedAt: 20,
          ),
        ],
      );
      final store = await _buildStore(
        diaryV2SupabaseRepository: fakeRepository,
        authenticatedUserId: 'user-1',
      );

      await store.syncDiaryV2FromRemoteBestEffort();

      expect(store.dailyMoods, hasLength(1));
      expect(store.dailyMoods.single.dateKey, '2026-06-22');
      expect(store.dailyMoods.single.mood, 1);
    });

    test('daily mood with same date does not duplicate on pull', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final fakeRepository = _FakeDiaryV2SupabaseRepository(
        fetchedDailyMoods: <DailyMood>[
          DailyMood(
            date: DateTime(2026, 6, 22),
            mood: 1,
            createdAt: 10,
            updatedAt: 20,
          ),
        ],
      );
      final store = await _buildStore(
        diaryV2SupabaseRepository: fakeRepository,
        authenticatedUserId: 'user-1',
        dailyMoods: <DailyMood>[
          DailyMood(
            date: DateTime(2026, 6, 22),
            mood: -1,
            createdAt: 15,
            updatedAt: 30,
          ),
        ],
      );

      await store.syncDiaryV2FromRemoteBestEffort();

      expect(store.dailyMoods, hasLength(1));
      expect(store.dailyMoods.single.dateKey, '2026-06-22');
    });

    test('local daily mood is not removed if missing remotely on pull',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final fakeRepository = _FakeDiaryV2SupabaseRepository(
        fetchedDailyMoods: const <DailyMood>[],
      );
      final store = await _buildStore(
        diaryV2SupabaseRepository: fakeRepository,
        authenticatedUserId: 'user-1',
        dailyMoods: <DailyMood>[
          DailyMood(
            date: DateTime(2026, 6, 22),
            mood: 2,
            createdAt: 10,
            updatedAt: 20,
          ),
        ],
      );

      await store.syncDiaryV2FromRemoteBestEffort();

      expect(store.dailyMoods, hasLength(1));
      expect(store.dailyMoods.single.mood, 2);
    });

    test('DiaryEntry mood and DailyMood mood remain separated after pull',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final fakeRepository = _FakeDiaryV2SupabaseRepository(
        fetchedDiaryEntries: const <DiaryEntry>[
          DiaryEntry(
            id: 'entry-1',
            createdAt: 1718445600123,
            text: 'Entry mood stays entry-scoped',
            mood: -2,
          ),
        ],
        fetchedDailyMoods: <DailyMood>[
          DailyMood(
            date: DateTime(2026, 6, 22),
            mood: 2,
            createdAt: 10,
            updatedAt: 20,
          ),
        ],
      );
      final store = await _buildStore(
        diaryV2SupabaseRepository: fakeRepository,
        authenticatedUserId: 'user-1',
      );

      await store.syncDiaryV2FromRemoteBestEffort();

      expect(store.diaryEntries.single.mood, -2);
      expect(store.dailyMoods.single.mood, 2);
    });

    test('no-auth pull is safe and keeps local state unchanged', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final fakeRepository = _FakeDiaryV2SupabaseRepository(
        fetchedDiaryEntries: const <DiaryEntry>[
          DiaryEntry(
            id: 'remote-entry-1',
            createdAt: 1718445600123,
            text: 'Should not be pulled',
          ),
        ],
        fetchedDailyMoods: <DailyMood>[
          DailyMood(
            date: DateTime(2026, 6, 22),
            mood: 1,
            createdAt: 10,
            updatedAt: 20,
          ),
        ],
      );
      final store = await _buildStore(
        diaryV2SupabaseRepository: fakeRepository,
        authenticatedUserId: null,
        entries: const <DiaryEntry>[
          DiaryEntry(
            id: 'entry-1',
            createdAt: 100,
            text: 'Local only',
          ),
        ],
      );

      await store.syncDiaryV2FromRemoteBestEffort();

      expect(store.diaryEntries, hasLength(1));
      expect(store.diaryEntries.single.id, 'entry-1');
      expect(store.dailyMoods, isEmpty);
      expect(fakeRepository.fetchDiaryEntriesCalls, 0);
      expect(fakeRepository.fetchDailyMoodsCalls, 0);
    });

    test('no-auth controlled auto sync is safe and keeps local state unchanged',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final fakeRepository = _FakeDiaryV2SupabaseRepository(
        fetchedDiaryEntries: const <DiaryEntry>[
          DiaryEntry(
            id: 'remote-entry-1',
            createdAt: 1718445600123,
            text: 'Should not be pulled',
          ),
        ],
      );
      final store = await _buildStore(
        diaryV2SupabaseRepository: fakeRepository,
        authenticatedUserId: null,
        entries: const <DiaryEntry>[
          DiaryEntry(
            id: 'entry-1',
            createdAt: 100,
            text: 'Local only',
          ),
        ],
      );

      await store.autoSyncDiaryV2FromRemoteIfNeeded();

      expect(store.diaryEntries.single.id, 'entry-1');
      expect(fakeRepository.fetchDiaryEntriesCalls, 0);
      expect(fakeRepository.fetchDailyMoodsCalls, 0);
      expect(store.lastDiaryV2RemotePullAttemptAt, isNull);
      expect(store.lastDiaryV2RemotePullSuccessAt, isNull);
    });

    test('remote fetch error is best effort and keeps local state unchanged',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final fakeRepository = _FakeDiaryV2SupabaseRepository(
        fetchDiaryEntriesResult: RepositoryResult<List<DiaryEntry>>.failure(
          const RepositoryError(
            code: RepositoryErrorCode.network,
            message: 'offline',
          ),
        ),
      );
      final store = await _buildStore(
        diaryV2SupabaseRepository: fakeRepository,
        authenticatedUserId: 'user-1',
        entries: const <DiaryEntry>[
          DiaryEntry(
            id: 'entry-1',
            createdAt: 100,
            text: 'Local only',
          ),
        ],
        dailyMoods: <DailyMood>[
          DailyMood(
            date: DateTime(2026, 6, 22),
            mood: 2,
            createdAt: 10,
            updatedAt: 20,
          ),
        ],
      );

      await store.syncDiaryV2FromRemoteBestEffort();

      expect(store.diaryEntries, hasLength(1));
      expect(store.diaryEntries.single.text, 'Local only');
      expect(store.dailyMoods, hasLength(1));
      expect(store.dailyMoods.single.mood, 2);
      expect(fakeRepository.fetchDiaryEntriesCalls, 1);
      expect(fakeRepository.fetchDailyMoodsCalls, 1);
    });

    test('controlled auto sync fetch error keeps local state intact', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final now = DateTime(2026, 6, 22, 10, 0);

      final fakeRepository = _FakeDiaryV2SupabaseRepository(
        fetchDiaryEntriesResult: RepositoryResult<List<DiaryEntry>>.failure(
          const RepositoryError(
            code: RepositoryErrorCode.network,
            message: 'offline',
          ),
        ),
      );
      final store = await _buildStore(
        diaryV2SupabaseRepository: fakeRepository,
        authenticatedUserId: 'user-1',
        nowProvider: () => now,
        entries: const <DiaryEntry>[
          DiaryEntry(
            id: 'entry-1',
            createdAt: 100,
            text: 'Local only',
          ),
        ],
      );

      await store.autoSyncDiaryV2FromRemoteIfNeeded();

      expect(store.diaryEntries.single.text, 'Local only');
      expect(store.lastDiaryV2RemotePullAttemptAt, now);
      expect(store.lastDiaryV2RemotePullSuccessAt, isNull);
      expect(store.isDiaryV2RemotePullRunning, isFalse);
    });
  });
}

Future<UserStateStore> _buildStore({
  required _FakeDiaryV2SupabaseRepository diaryV2SupabaseRepository,
  required String? authenticatedUserId,
  List<DiaryEntry> entries = const <DiaryEntry>[],
  List<DailyMood> dailyMoods = const <DailyMood>[],
  DateTime Function()? nowProvider,
}) async {
  final repo = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope('user-1');
  final store = UserStateStore(
    repo,
    journalEntrySyncService: JournalEntrySyncService(),
    diaryV2SupabaseRepository: diaryV2SupabaseRepository,
    currentSupabaseUserIdProvider: () => authenticatedUserId,
    nowProvider: nowProvider,
  );
  await store.save(
    _baseState(
      userId: 'user-1',
      entries: entries,
      dailyMoods: dailyMoods,
    ),
  );
  return store;
}

Map<String, dynamic> _baseState({
  required String userId,
  required List<DiaryEntry> entries,
  required List<DailyMood> dailyMoods,
}) {
  return <String, dynamic>{
    'userState': <String, dynamic>{
      'userId': userId,
      'meta': <String, dynamic>{
        'schemaVersion': 1,
        'lastSavedAt': DateTime.now().toUtc().toIso8601String(),
        'diaryRewardAppliedDateKeys': <dynamic>[],
      },
      'progression': <String, dynamic>{
        'level': 1,
        'xp': 0,
        'prestige': 0,
      },
      'wallet': <String, dynamic>{'coins': 0},
      'inventory': <String, dynamic>{'items': <dynamic>[]},
      'profile': <String, dynamic>{
        'equipped': <String, dynamic>{},
        'badges': <String, dynamic>{'owned': <dynamic>[], 'shown': null},
        'achievements': <String, dynamic>{
          'unlocked': <dynamic>[],
          'featured': <dynamic>[],
          'rewardAppliedAchievementIds': <dynamic>[],
          'progress': <String, dynamic>{},
        },
      },
      'claims': <String, dynamic>{
        'milestonesClaimed': <dynamic>[],
        'achievementRewardsClaimed': <dynamic>[],
        'prestigeClaimed': <dynamic>[],
      },
      'daily': <String, dynamic>{
        'lastResetDate': _todayKey(),
        'xpEarnedToday': 0,
        'coinsEarnedToday': 0,
        'habitsCompletedToday': <String, dynamic>{},
      },
      'history': <String, dynamic>{
        'habitCompletions': <String, dynamic>{},
        'habitCountValues': <String, dynamic>{},
        'habitSkips': <String, dynamic>{},
        'habitCompletionTimes': <String, dynamic>{},
      },
      'familyXp': <String, dynamic>{
        'mind': 0,
        'spirit': 0,
        'body': 0,
        'emotional': 0,
        'social': 0,
        'discipline': 0,
        'professional': 0,
      },
      'activeHabits': <dynamic>[],
      'diaryEntries':
          entries.map((entry) => entry.toJson()).toList(growable: false),
      'dailyMoods': <String, dynamic>{
        for (final dailyMood in dailyMoods)
          dailyMood.dateKey: dailyMood.toJson(),
      },
    },
  };
}

Future<void> _flushAsyncWork() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

String _todayKey() {
  final now = DateTime.now();
  final y = now.year.toString().padLeft(4, '0');
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

class _FakeDiaryV2SupabaseRepository extends DiaryV2SupabaseRepository {
  _FakeDiaryV2SupabaseRepository({
    RepositoryResult<DiaryEntry>? upsertResult,
    RepositoryResult<void>? deleteResult,
    RepositoryResult<DailyMood>? dailyMoodUpsertResult,
    RepositoryResult<List<DiaryEntry>>? fetchDiaryEntriesResult,
    RepositoryResult<List<DailyMood>>? fetchDailyMoodsResult,
    List<DiaryEntry> fetchedDiaryEntries = const <DiaryEntry>[],
    List<DailyMood> fetchedDailyMoods = const <DailyMood>[],
    Future<RepositoryResult<List<DiaryEntry>>> Function()?
        fetchDiaryEntriesHandler,
    Future<RepositoryResult<List<DailyMood>>> Function()?
        fetchDailyMoodsHandler,
  })  : _upsertResult = upsertResult,
        _deleteResult = deleteResult,
        _dailyMoodUpsertResult = dailyMoodUpsertResult,
        _fetchDiaryEntriesResult = fetchDiaryEntriesResult,
        _fetchDailyMoodsResult = fetchDailyMoodsResult,
        _fetchedDiaryEntries = fetchedDiaryEntries,
        _fetchDiaryEntriesHandler = fetchDiaryEntriesHandler,
        _fetchDailyMoodsHandler = fetchDailyMoodsHandler,
        _fetchedDailyMoods = fetchedDailyMoods,
        super(
          client: SupabaseClient('https://example.com', 'anon-key'),
          currentUserIdProvider: () => 'user-1',
        );

  final RepositoryResult<DiaryEntry>? _upsertResult;
  final RepositoryResult<void>? _deleteResult;
  final RepositoryResult<DailyMood>? _dailyMoodUpsertResult;
  final RepositoryResult<List<DiaryEntry>>? _fetchDiaryEntriesResult;
  final RepositoryResult<List<DailyMood>>? _fetchDailyMoodsResult;
  final List<DiaryEntry> _fetchedDiaryEntries;
  final List<DailyMood> _fetchedDailyMoods;
  final Future<RepositoryResult<List<DiaryEntry>>> Function()?
      _fetchDiaryEntriesHandler;
  final Future<RepositoryResult<List<DailyMood>>> Function()?
      _fetchDailyMoodsHandler;

  int upsertCalls = 0;
  int deleteCalls = 0;
  int dailyMoodUpsertCalls = 0;
  int fetchDiaryEntriesCalls = 0;
  int fetchDailyMoodsCalls = 0;
  DiaryEntry? lastUpsertedEntry;
  DailyMood? lastUpsertedDailyMood;
  String? lastDeletedLocalId;
  String? lastDeletedRemoteId;
  final List<DailyMood> upsertedDailyMoods = <DailyMood>[];

  @override
  Future<RepositoryResult<DiaryEntry>> upsertDiaryEntry(
      DiaryEntry entry) async {
    upsertCalls += 1;
    lastUpsertedEntry = entry;
    return _upsertResult ?? RepositoryResult<DiaryEntry>.success(data: entry);
  }

  @override
  Future<RepositoryResult<void>> deleteDiaryEntry({
    String? localId,
    String? remoteId,
  }) async {
    deleteCalls += 1;
    lastDeletedLocalId = localId;
    lastDeletedRemoteId = remoteId;
    return _deleteResult ?? const RepositoryResult<void>.success();
  }

  @override
  Future<RepositoryResult<void>> deleteDiaryEntryByLocalId(
      String localId) async {
    deleteCalls += 1;
    lastDeletedLocalId = localId;
    lastDeletedRemoteId = null;
    return _deleteResult ?? const RepositoryResult<void>.success();
  }

  @override
  Future<RepositoryResult<DailyMood>> upsertDailyMood(
      DailyMood dailyMood) async {
    dailyMoodUpsertCalls += 1;
    lastUpsertedDailyMood = dailyMood;
    upsertedDailyMoods.add(dailyMood);
    return _dailyMoodUpsertResult ??
        RepositoryResult<DailyMood>.success(data: dailyMood);
  }

  @override
  Future<RepositoryResult<List<DiaryEntry>>> fetchDiaryEntriesForCurrentUser({
    DateTime? start,
    DateTime? end,
  }) async {
    fetchDiaryEntriesCalls += 1;
    final handler = _fetchDiaryEntriesHandler;
    if (handler != null) {
      return handler();
    }
    return _fetchDiaryEntriesResult ??
        RepositoryResult<List<DiaryEntry>>.success(data: _fetchedDiaryEntries);
  }

  @override
  Future<RepositoryResult<List<DailyMood>>> fetchDailyMoodsForCurrentUser({
    DateTime? start,
    DateTime? end,
  }) async {
    fetchDailyMoodsCalls += 1;
    final handler = _fetchDailyMoodsHandler;
    if (handler != null) {
      return handler();
    }
    return _fetchDailyMoodsResult ??
        RepositoryResult<List<DailyMood>>.success(data: _fetchedDailyMoods);
  }
}
