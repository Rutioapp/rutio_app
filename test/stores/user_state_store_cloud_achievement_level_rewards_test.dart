import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/constants/reward_constants.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/data/services/user_progress_sync_service.dart';
import 'package:rutio/features/achievements/application/achievement_level_reward_coordinator.dart';
import 'package:rutio/features/achievements/data/cloud/achievement_level_reward_errors.dart';
import 'package:rutio/features/achievements/data/cloud/achievement_level_reward_ledger.dart';
import 'package:rutio/features/achievements/data/cloud/achievement_level_reward_repository.dart';
import 'package:rutio/features/achievements/domain/models/pending_reward_claim.dart';
import 'package:rutio/features/achievements/domain/pending_reward_claim_store.dart';
import 'package:rutio/features/gamification/domain/level_progression.dart';
import 'package:rutio/features/global_wallet/application/global_wallet_controller.dart';
import 'package:rutio/features/global_wallet/application/global_wallet_state.dart';
import 'package:rutio/features/global_wallet/data/cloud/cloud_wallet_errors.dart';
import 'package:rutio/features/global_wallet/data/cloud/cloud_wallet_snapshot.dart';
import 'package:rutio/features/global_wallet/data/cloud/cloud_wallet_repository.dart';
import 'package:rutio/features/global_wallet/data/cloud/wallet_cache.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserStateStore cloud achievement and level rewards', () {
    test('cloud achievement reward refreshes the global wallet once', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final fakeCoordinator = _FakeAchievementLevelRewardCoordinator();
      final fakeWallet = _FakeGlobalWalletController();
      final progressSync = _RecordingUserProgressSyncService();
      final store = await _buildStore(
        achievementLevelRewardCoordinator: fakeCoordinator,
        globalWalletController: fakeWallet,
        userProgressSyncService: progressSync,
      );
      await store.save(
        _baseState(
          userId: 'user-1',
          habits: List<Map<String, dynamic>>.generate(
            8,
            (index) => _habit(id: 'flash-$index'),
          ),
          completionsByDay: <String, Map<String, dynamic>>{
            _dateKey(DateTime.now()): <String, dynamic>{
              for (final habit in List<Map<String, dynamic>>.generate(
                8,
                (index) => _habit(id: 'flash-$index'),
              ))
                habit['id'] as String: true,
            },
          },
        ),
      );

      await store.load();

      expect(fakeCoordinator.achievementCallCount, 1);
      expect(fakeWallet.refreshCallCount, greaterThanOrEqualTo(1));
      expect(progressSync.currencyEventCallCount, 0);
      expect(_rewardAppliedIds(store), contains('special:flash'));
      expect(_walletCoins(store), 0);
    });

    test('level reward claims once and closing the modal does not duplicate',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final fakeCoordinator = _FakeAchievementLevelRewardCoordinator();
      final fakeWallet = _FakeGlobalWalletController();
      final store = await _buildStore(
        achievementLevelRewardCoordinator: fakeCoordinator,
        globalWalletController: fakeWallet,
      );
      await store.save(
        _baseState(
          userId: 'user-1',
          xp: 0,
          habits: [_habitCheck('habit_one')],
        ),
      );

      final thresholdLevel2 = LevelProgression.xpToReachLevel(5).toInt();
      await store.save(
        _baseState(
          userId: 'user-1',
          xp: thresholdLevel2 - RewardConstants.habitCheckXpReward,
          habits: [_habitCheck('habit_one')],
        ),
      );

      await store.completeHabit(habitId: 'habit_one');
      expect(fakeCoordinator.levelRequests, contains(5));
      expect(fakeCoordinator.levelChargeCount, 1);

      await store.markLevelCelebrationAsCelebrated(level: 5);
      expect(fakeCoordinator.levelChargeCount, 1);
      expect(fakeWallet.refreshCallCount, greaterThanOrEqualTo(1));
    });

    test('feature flag disabled keeps the legacy reward path', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final fakeCoordinator =
          _FakeAchievementLevelRewardCoordinator(enabled: false);
      final fakeWallet = _FakeGlobalWalletController();
      final store = await _buildStore(
        achievementLevelRewardCoordinator: fakeCoordinator,
        globalWalletController: fakeWallet,
      );
      await store.save(
        _baseState(
          userId: 'user-1',
          habits: List<Map<String, dynamic>>.generate(
            8,
            (index) => _habit(id: 'legacy-$index'),
          ),
          completionsByDay: <String, Map<String, dynamic>>{
            _dateKey(DateTime.now()): <String, dynamic>{
              for (final habit in List<Map<String, dynamic>>.generate(
                8,
                (index) => _habit(id: 'legacy-$index'),
              ))
                habit['id'] as String: true,
            },
          },
        ),
      );

      await store.load();

      expect(fakeCoordinator.achievementCallCount, 0);
      expect(progressCoins(store), 100);
      expect(fakeWallet.refreshCallCount, 0);
    });
  });
}

Future<UserStateStore> _buildStore({
  AchievementLevelRewardCoordinator? achievementLevelRewardCoordinator,
  GlobalWalletController? globalWalletController,
  UserProgressSyncService? userProgressSyncService,
}) async {
  final repo = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope('user-1');
  final store = UserStateStore(
    repo,
    journalEntrySyncService: JournalEntrySyncService(),
    achievementLevelRewardCoordinator: achievementLevelRewardCoordinator,
    globalWalletController: globalWalletController,
    userProgressSyncService:
        userProgressSyncService ?? _RecordingUserProgressSyncService(),
  );
  return store;
}

Map<String, dynamic> _baseState({
  required String userId,
  required List<Map<String, dynamic>> habits,
  int xp = 0,
  Map<String, Map<String, dynamic>> completionsByDay =
      const <String, Map<String, dynamic>>{},
}) {
  final mutableCompletions =
      Map<String, Map<String, dynamic>>.from(completionsByDay);
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
        'lastResetDate': _dateKey(DateTime.now()),
        'xpEarnedToday': 0,
        'coinsEarnedToday': 0,
        'habitsCompletedToday': <String, dynamic>{},
      },
      'history': <String, dynamic>{
        'habitCompletions': mutableCompletions,
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
      'activeHabits': habits,
    },
  };
}

Map<String, dynamic> _habit({required String id}) {
  return <String, dynamic>{
    'id': id,
    'createdAt': '2026-01-01',
    'name': 'Habit $id',
    'emoji': '*',
    'familyId': 'mind',
    'type': 'check',
    'target': 1,
    'progress': 0,
    'doneToday': false,
    'skippedToday': false,
    'schedule': const <String, dynamic>{'type': 'daily'},
    'archived': false,
    'isCustom': true,
    'reminderEnabled': false,
    'reminderTime': null,
  };
}

Map<String, dynamic> _habitCheck(String id) {
  return _habit(id: id);
}

String _dateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

int progressCoins(UserStateStore store) {
  final root = store.state as Map<String, dynamic>;
  final userState = root['userState'] as Map<String, dynamic>;
  final wallet = userState['wallet'] as Map<String, dynamic>;
  return (wallet['coins'] as num).toInt();
}

List<String> _rewardAppliedIds(UserStateStore store) {
  final root = store.state as Map<String, dynamic>;
  final userState = root['userState'] as Map<String, dynamic>;
  final profile = userState['profile'] as Map<String, dynamic>;
  final achievements = profile['achievements'] as Map<String, dynamic>;
  return (achievements['rewardAppliedAchievementIds'] as List<dynamic>)
      .map((entry) => entry.toString())
      .toList(growable: false);
}

int _walletCoins(UserStateStore store) => progressCoins(store);

class _FakeAchievementLevelRewardCoordinator
    extends AchievementLevelRewardCoordinator {
  _FakeAchievementLevelRewardCoordinator({
    bool enabled = true,
  })
      : super(
          rewardRepository: _NoopRewardRepository(),
          pendingClaimStore: _NoopPendingRewardClaimStore(),
          currentUserIdProvider: () => 'user-1',
          enabled: enabled,
        );

  int achievementCallCount = 0;
  int levelChargeCount = 0;
  final List<int> levelRequests = <int>[];

  @override
  Future<AchievementLevelRewardResult<AchievementLevelRewardLedgerEntry>>
      claimAchievementReward({
    required String achievementId,
    String? requestId,
  }) async {
    achievementCallCount += 1;
    return AchievementLevelRewardResult<AchievementLevelRewardLedgerEntry>
        .success(
      data: AchievementLevelRewardLedgerEntry(
        id: 'achievement_$achievementId',
        userId: 'user-1',
        requestId: requestId ??
            'reward:user-1:achievement:$achievementId',
        operationType: 'claim',
        sourceType: 'achievement_reward',
        sourceId: achievementId,
        coinDelta: 25,
        balanceAfter: 25,
        createdAt: DateTime(2026, 7, 19),
        isIdempotent: false,
      ),
    );
  }

  @override
  Future<AchievementLevelRewardResult<AchievementLevelRewardLedgerEntry>>
      claimLevelReward({
    required int level,
    String? requestId,
  }) async {
    levelRequests.add(level);
    if (level >= 5) {
      levelChargeCount += 1;
    }
    return AchievementLevelRewardResult<AchievementLevelRewardLedgerEntry>
        .success(
      data: AchievementLevelRewardLedgerEntry(
        id: 'level_$level',
        userId: 'user-1',
        requestId: requestId ?? 'reward:user-1:level:$level',
        operationType: 'claim',
        sourceType: 'level_reward',
        sourceId: level.toString(),
        coinDelta: 50,
        balanceAfter: 50,
        createdAt: DateTime(2026, 7, 19),
        isIdempotent: false,
      ),
    );
  }

  @override
  Future<List<AchievementLevelRewardResult<AchievementLevelRewardLedgerEntry>>>
      resolvePendingForCurrentUser({
    int maxOperations = 5,
  }) async {
    return const <AchievementLevelRewardResult<AchievementLevelRewardLedgerEntry>>[];
  }
}

class _FakeGlobalWalletController extends GlobalWalletController {
  _FakeGlobalWalletController()
      : super(
          repository: _NoopCloudWalletRepository(),
          cache: _NoopWalletCache(),
          currentUserIdProvider: () => 'user-1',
          enabled: true,
        );

  int refreshCallCount = 0;

  @override
  Future<GlobalWalletState> refresh({bool force = false}) async {
    refreshCallCount += 1;
    return GlobalWalletState.ready(
      userId: 'user-1',
      snapshot: CloudWalletSnapshot(
        userId: 'user-1',
        coins: 0,
        version: 0,
        createdAt: DateTime(2026, 7, 19),
        updatedAt: DateTime(2026, 7, 19),
        fetchedAt: DateTime(2026, 7, 19),
      ),
      cache: WalletCacheEntry(
        userId: 'user-1',
        coins: 0,
        version: 0,
        updatedAt: DateTime(2026, 7, 19),
        cachedAt: DateTime(2026, 7, 19),
      ),
    );
  }
}

class _RecordingUserProgressSyncService extends UserProgressSyncService {
  _RecordingUserProgressSyncService();

  int progressSyncCallCount = 0;
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

class _NoopRewardRepository implements AchievementLevelRewardRepository {
  @override
  Future<AchievementLevelRewardResult<AchievementLevelRewardLedgerEntry>>
      claimAchievementReward({
    required String requestId,
    required String achievementId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<AchievementLevelRewardResult<AchievementLevelRewardLedgerEntry>>
      claimLevelReward({
    required String requestId,
    required int level,
  }) async {
    throw UnimplementedError();
  }
}

class _NoopPendingRewardClaimStore implements PendingRewardClaimStore {
  @override
  Future<List<PendingRewardClaim>> loadPendingClaims(String userId) async =>
      const <PendingRewardClaim>[];

  @override
  Future<void> savePendingClaims(
    String userId,
    List<PendingRewardClaim> claims,
  ) async {}

  @override
  Future<void> clearPendingClaims(String userId) async {}
}

class _NoopCloudWalletRepository implements CloudWalletRepository {
  @override
  Future<WalletReadResult<CloudWalletSnapshot>> fetchWallet() async {
    return const WalletReadResult<CloudWalletSnapshot>.failure(
      failure: WalletFailure(
        code: WalletFailureCode.walletMissing,
        message: 'noop',
      ),
    );
  }
}

class _NoopWalletCache implements WalletCache {
  @override
  Future<WalletCacheEntry?> read(String userId) async => null;

  @override
  Future<WalletCacheEntry?> save(CloudWalletSnapshot snapshot) async => null;

  @override
  Future<void> clearForUser(String userId) async {}
}
