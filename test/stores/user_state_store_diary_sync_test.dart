import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/diary_v2_supabase_repository.dart';
import 'package:rutio/data/repositories/repository_result.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
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

      final updated = store.diaryEntries.singleWhere((item) => item.id == 'entry-1');
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
    });
  });
}

Future<UserStateStore> _buildStore({
  required _FakeDiaryV2SupabaseRepository diaryV2SupabaseRepository,
  required String? authenticatedUserId,
  List<DiaryEntry> entries = const <DiaryEntry>[],
}) async {
  final repo = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope('user-1');
  final store = UserStateStore(
    repo,
    journalEntrySyncService: JournalEntrySyncService(),
    diaryV2SupabaseRepository: diaryV2SupabaseRepository,
    currentSupabaseUserIdProvider: () => authenticatedUserId,
  );
  await store.save(
    _baseState(
      userId: 'user-1',
      entries: entries,
    ),
  );
  return store;
}

Map<String, dynamic> _baseState({
  required String userId,
  required List<DiaryEntry> entries,
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
      'diaryEntries': entries.map((entry) => entry.toJson()).toList(growable: false),
      'dailyMoods': <String, dynamic>{},
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
  })  : _upsertResult = upsertResult,
        _deleteResult = deleteResult,
        super(
          client: SupabaseClient('https://example.com', 'anon-key'),
          currentUserIdProvider: () => 'user-1',
        );

  final RepositoryResult<DiaryEntry>? _upsertResult;
  final RepositoryResult<void>? _deleteResult;

  int upsertCalls = 0;
  int deleteCalls = 0;
  DiaryEntry? lastUpsertedEntry;
  String? lastDeletedLocalId;
  String? lastDeletedRemoteId;

  @override
  Future<RepositoryResult<DiaryEntry>> upsertDiaryEntry(DiaryEntry entry) async {
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
  Future<RepositoryResult<void>> deleteDiaryEntryByLocalId(String localId) async {
    deleteCalls += 1;
    lastDeletedLocalId = localId;
    lastDeletedRemoteId = null;
    return _deleteResult ?? const RepositoryResult<void>.success();
  }
}
