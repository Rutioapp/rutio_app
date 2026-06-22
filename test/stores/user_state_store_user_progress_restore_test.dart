import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/models/remote/remote_user_progress.dart';
import 'package:rutio/data/repositories/repository_result.dart';
import 'package:rutio/data/repositories/user_progress_repository.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/data/services/user_progress_sync_service.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserStateStore Supabase user progress restore', () {
    test('remote progress row restores local level xp and coins', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final fakeRepo = _FakeUserProgressRepository(
        result: RepositoryResult<RemoteUserProgress?>.success(
          data: _remoteProgress(
            level: 4,
            totalXp: 235,
            currentLevelXp: 35,
            nextLevelXp: 65,
            ambarBalance: 120,
          ),
        ),
      );
      final syncService = _RecordingUserProgressSyncService();
      final store = await _buildStore(
        userProgressRepository: fakeRepo,
        userProgressSyncService: syncService,
        currentSupabaseUserIdProvider: () => 'user-123',
      );

      final result = await store.restoreSupabaseUserProgressBestEffort();

      expect(result.status, SupabaseUserProgressRestoreStatus.restored);
      expect(_xp(store), 235);
      expect(_level(store), 4);
      expect(_coins(store), 120);
      expect(_lastCelebratedLevel(store), 4);
      expect(store.pendingLevelCelebrationCount, 0);
      expect(syncService.progressSyncCallCount, 0);
      expect(syncService.xpEventCallCount, 0);
      expect(syncService.currencyEventCallCount, 0);
    });

    test('no remote progress row leaves local state unchanged', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final store = await _buildStore(
        userProgressRepository: _FakeUserProgressRepository(
          result: const RepositoryResult<RemoteUserProgress?>.success(data: null),
        ),
        currentSupabaseUserIdProvider: () => 'user-123',
        initialXp: 18,
        initialCoins: 7,
      );

      final result = await store.restoreSupabaseUserProgressBestEffort();

      expect(result.status, SupabaseUserProgressRestoreStatus.skippedNoRemoteRow);
      expect(_xp(store), 18);
      expect(_level(store), 1);
      expect(_coins(store), 7);
    });

    test('no-auth restore is safe and skips fetch', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final fakeRepo = _FakeUserProgressRepository(
        result: RepositoryResult<RemoteUserProgress?>.success(
          data: _remoteProgress(
            level: 3,
            totalXp: 150,
            currentLevelXp: 50,
            nextLevelXp: 50,
            ambarBalance: 25,
          ),
        ),
      );
      final store = await _buildStore(
        userProgressRepository: fakeRepo,
        currentSupabaseUserIdProvider: () => null,
      );

      final result = await store.restoreSupabaseUserProgressBestEffort();

      expect(result.status, SupabaseUserProgressRestoreStatus.skippedNoAuthUser);
      expect(fakeRepo.fetchCallCount, 0);
      expect(_xp(store), 0);
      expect(_coins(store), 0);
    });

    test(
      'remote fetch error does not reset local and does not backfill template defaults',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{});

        final fakeRepo = _FakeUserProgressRepository(
          result: RepositoryResult<RemoteUserProgress?>.failure(
            const RepositoryError(
              code: RepositoryErrorCode.network,
              message: 'offline',
            ),
          ),
        );
        final syncService = _RecordingUserProgressSyncService();
        final store = await _buildStore(
          userProgressRepository: fakeRepo,
          userProgressSyncService: syncService,
          currentSupabaseUserIdProvider: () => 'user-123',
        );

        final result = await store.syncSupabaseUserProgressBootstrapBestEffort();

        expect(
          result.restoreResult.status,
          SupabaseUserProgressRestoreStatus.failedRemoteStateUnknown,
        );
        expect(result.backfillSynced, isFalse);
        expect(_xp(store), 0);
        expect(_level(store), 1);
        expect(_coins(store), 0);
        expect(syncService.progressSyncCallCount, 0);
      },
    );

    test('bootstrap calls restore before backfill', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final callLog = <String>[];
      final fakeRepo = _FakeUserProgressRepository(
        result: RepositoryResult<RemoteUserProgress?>.success(
          data: _remoteProgress(
            level: 6,
            totalXp: 410,
            currentLevelXp: 10,
            nextLevelXp: 90,
            ambarBalance: 88,
          ),
        ),
        callLog: callLog,
      );
      final syncService = _RecordingUserProgressSyncService(callLog: callLog);
      final store = await _buildStore(
        userProgressRepository: fakeRepo,
        userProgressSyncService: syncService,
        currentSupabaseUserIdProvider: () => 'user-123',
      );

      final result = await store.syncSupabaseUserProgressBootstrapBestEffort();

      expect(result.restoreResult.restored, isTrue);
      expect(result.backfillSynced, isTrue);
      expect(callLog, <String>['restore_fetch', 'backfill_push']);
      expect(_xp(store), 410);
      expect(_coins(store), 88);
    });

    test('clean template state with remote progress does not remain default', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final store = await _buildStore(
        userProgressRepository: _FakeUserProgressRepository(
          result: RepositoryResult<RemoteUserProgress?>.success(
            data: _remoteProgress(
              level: 7,
              totalXp: 540,
              currentLevelXp: 40,
              nextLevelXp: 60,
              ambarBalance: 230,
            ),
          ),
        ),
        currentSupabaseUserIdProvider: () => 'user-123',
      );

      await store.restoreSupabaseUserProgressBestEffort();

      expect(_level(store), isNot(1));
      expect(_xp(store), isNot(0));
      expect(_coins(store), isNot(0));
    });

    test('restore does not trigger reward or celebration side effects', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final syncService = _RecordingUserProgressSyncService();
      final store = await _buildStore(
        userProgressRepository: _FakeUserProgressRepository(
          result: RepositoryResult<RemoteUserProgress?>.success(
            data: _remoteProgress(
              level: 5,
              totalXp: 300,
              currentLevelXp: 0,
              nextLevelXp: 100,
              ambarBalance: 45,
            ),
          ),
        ),
        userProgressSyncService: syncService,
        currentSupabaseUserIdProvider: () => 'user-123',
      );

      final result = await store.restoreSupabaseUserProgressBestEffort();

      expect(result.status, SupabaseUserProgressRestoreStatus.restored);
      expect(store.pendingLevelCelebrationCount, 0);
      expect(store.peekNextPendingLevelCelebration(), isNull);
      expect(store.pendingAchievementUnlockCount, 0);
      expect(syncService.progressSyncCallCount, 0);
      expect(syncService.xpEventCallCount, 0);
      expect(syncService.currencyEventCallCount, 0);
    });

    test('conflicting non-template local progress skips destructive restore and backfill', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final syncService = _RecordingUserProgressSyncService();
      final store = await _buildStore(
        userProgressRepository: _FakeUserProgressRepository(
          result: RepositoryResult<RemoteUserProgress?>.success(
            data: _remoteProgress(
              level: 2,
              totalXp: 80,
              currentLevelXp: 80,
              nextLevelXp: 20,
              ambarBalance: 10,
            ),
          ),
        ),
        userProgressSyncService: syncService,
        currentSupabaseUserIdProvider: () => 'user-123',
        initialXp: 210,
        initialCoins: 55,
      );

      final result = await store.syncSupabaseUserProgressBootstrapBestEffort();

      expect(
        result.restoreResult.status,
        SupabaseUserProgressRestoreStatus.skippedLocalConflict,
      );
      expect(result.backfillSynced, isFalse);
      expect(_xp(store), 210);
      expect(_coins(store), 55);
      expect(syncService.progressSyncCallCount, 0);
    });
  });
}

Future<UserStateStore> _buildStore({
  required UserProgressRepository userProgressRepository,
  UserProgressSyncService? userProgressSyncService,
  required String? Function() currentSupabaseUserIdProvider,
  int initialXp = 0,
  int initialCoins = 0,
}) async {
  final repo = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope('user-123');
  final store = UserStateStore(
    repo,
    journalEntrySyncService: JournalEntrySyncService(),
    userProgressRepository: userProgressRepository,
    userProgressSyncService:
        userProgressSyncService ?? _RecordingUserProgressSyncService(),
    currentSupabaseUserIdProvider: currentSupabaseUserIdProvider,
  );
  await store.save(
    _baseState(
      userId: 'user-123',
      xp: initialXp,
      coins: initialCoins,
    ),
  );
  return store;
}

Map<String, dynamic> _baseState({
  required String userId,
  required int xp,
  required int coins,
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
        'xp': xp,
        'prestige': 0,
      },
      'wallet': <String, dynamic>{'coins': coins},
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
    },
  };
}

RemoteUserProgress _remoteProgress({
  required int level,
  required int totalXp,
  required int currentLevelXp,
  required int nextLevelXp,
  required int ambarBalance,
}) {
  return RemoteUserProgress(
    userId: 'user-123',
    level: level,
    totalXp: totalXp,
    currentLevelXp: currentLevelXp,
    nextLevelXp: nextLevelXp,
    ambarBalance: ambarBalance,
    totalAmbarEarned: ambarBalance,
    totalAmbarSpent: 0,
  );
}

int _xp(UserStateStore store) {
  final root = store.state as Map<String, dynamic>;
  final userState = root['userState'] as Map<String, dynamic>;
  final progression = userState['progression'] as Map<String, dynamic>;
  return (progression['xp'] as num).toInt();
}

int _level(UserStateStore store) {
  final root = store.state as Map<String, dynamic>;
  final userState = root['userState'] as Map<String, dynamic>;
  final progression = userState['progression'] as Map<String, dynamic>;
  return (progression['level'] as num).toInt();
}

int _coins(UserStateStore store) {
  final root = store.state as Map<String, dynamic>;
  final userState = root['userState'] as Map<String, dynamic>;
  final wallet = userState['wallet'] as Map<String, dynamic>;
  return (wallet['coins'] as num).toInt();
}

int _lastCelebratedLevel(UserStateStore store) {
  final root = store.state as Map<String, dynamic>;
  final userState = root['userState'] as Map<String, dynamic>;
  final meta = userState['meta'] as Map<String, dynamic>;
  return (meta['lastCelebratedLevel'] as num?)?.toInt() ?? 0;
}

String _todayKey() {
  final now = DateTime.now();
  final y = now.year.toString().padLeft(4, '0');
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

class _FakeUserProgressRepository extends UserProgressRepository {
  _FakeUserProgressRepository({
    required this.result,
    this.callLog,
  }) : super(
          client: SupabaseClient(
            'https://example.com',
            'anon-key',
          ),
        );

  final RepositoryResult<RemoteUserProgress?> result;
  final List<String>? callLog;
  int fetchCallCount = 0;

  @override
  Future<RepositoryResult<RemoteUserProgress?>> fetchCurrentProgress() async {
    fetchCallCount += 1;
    callLog?.add('restore_fetch');
    return result;
  }
}

class _RecordingUserProgressSyncService extends UserProgressSyncService {
  _RecordingUserProgressSyncService({this.callLog});

  final List<String>? callLog;
  int progressSyncCallCount = 0;
  int xpEventCallCount = 0;
  int currencyEventCallCount = 0;

  @override
  Future<bool> syncCurrentProgressFromLocalState({
    required int level,
    required int totalXp,
    required int currentLevelXp,
    required int nextLevelXp,
    required int ambarBalance,
    int ambarEarnedDelta = 0,
    int ambarSpentDelta = 0,
    String? expectedLocalUserId,
  }) async {
    progressSyncCallCount += 1;
    callLog?.add('backfill_push');
    return true;
  }

  @override
  Future<bool> recordXpEvent({
    required int amount,
    String? source,
    String? sourceId,
    String? description,
    String? expectedLocalUserId,
  }) async {
    xpEventCallCount += 1;
    return true;
  }

  @override
  Future<bool> recordCurrencyEvent({
    required int amount,
    String currency = 'ambar',
    String? source,
    String? sourceId,
    String? description,
    String? expectedLocalUserId,
  }) async {
    currencyEventCallCount += 1;
    return true;
  }
}
