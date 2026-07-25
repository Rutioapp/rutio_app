import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/features/achievements/application/achievement_level_reward_coordinator.dart';
import 'package:rutio/features/achievements/data/cloud/achievement_level_reward_errors.dart';
import 'package:rutio/features/achievements/data/cloud/achievement_level_reward_ledger.dart';
import 'package:rutio/features/achievements/data/cloud/achievement_level_reward_repository.dart';
import 'package:rutio/features/achievements/domain/models/pending_reward_claim.dart';
import 'package:rutio/features/achievements/domain/pending_reward_claim_store.dart';
import 'package:rutio/stores/user_state_store.dart';

void main() {
  group('UserStateStore calendar clock split', () {
    test('reset daily uses calendar clock while technical timestamps stay real',
        () async {
      final calendarNow = DateTime(2026, 7, 26, 10, 0);
      final technicalNow = DateTime(2026, 7, 30, 18, 45);
      final store = await _loadStore(
        calendarNowProvider: () => calendarNow,
        nowProvider: () => technicalNow,
      );

      final root = store.state!;
      final userState = root['userState'] as Map<String, dynamic>;
      final meta = userState['meta'] as Map<String, dynamic>;
      final daily = userState['daily'] as Map<String, dynamic>;

      expect(daily['lastResetDate'], '2026-07-26');
      expect(meta['lastSavedAt'], technicalNow.toUtc().toIso8601String());
    });

    test('calendarNow and simulation flag stay independent from technical now',
        () async {
      final calendarNow = DateTime(2026, 7, 26, 10, 0);
      final technicalNow = DateTime(2026, 7, 25, 18, 45);
      final store = await _loadStore(
        calendarNowProvider: () => calendarNow,
        nowProvider: () => technicalNow,
      );

      expect(store.calendarNow, calendarNow);
      expect(store.isCalendarSimulated, isTrue);
    });

    test(
        'nowProvider remains a compatible fallback when no calendar clock is injected',
        () async {
      final nowProvider = DateTime(2026, 7, 26, 15, 30);
      final store = await _loadStore(
        nowProvider: () => nowProvider,
      );

      final root = store.state!;
      final userState = root['userState'] as Map<String, dynamic>;
      final meta = userState['meta'] as Map<String, dynamic>;
      final daily = userState['daily'] as Map<String, dynamic>;

      expect(daily['lastResetDate'], '2026-07-26');
      expect(meta['lastSavedAt'], nowProvider.toUtc().toIso8601String());
    });
  });
}

Future<UserStateStore> _loadStore({
  required DateTime Function() nowProvider,
  DateTime Function()? calendarNowProvider,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});

  final userId = 'calendar-user';
  final storage = UserStateStorage();
  await storage.write(
    _seededState(
      userId: userId,
      lastResetDate: '2026-07-25',
      lastSavedAt: '2026-07-25T08:00:00.000Z',
    ),
    userId: userId,
  );

  final repo = UserStateRepository(storage: storage)
    ..setActiveUserScope(userId);
  final store = UserStateStore(
    repo,
    achievementLevelRewardCoordinator: _disabledAchievementCoordinator(),
    currentSupabaseUserIdProvider: () => null,
    journalEntrySyncService: JournalEntrySyncService(),
    nowProvider: nowProvider,
    calendarNowProvider: calendarNowProvider,
    utilityConsumptionEnabledOverride: false,
    cloudHabitRewardsEnabledOverride: false,
  );
  await store.load();
  return store;
}

Map<String, dynamic> _seededState({
  required String userId,
  required String lastResetDate,
  required String lastSavedAt,
}) {
  return <String, dynamic>{
    'userState': <String, dynamic>{
      'userId': userId,
      'meta': <String, dynamic>{
        'schemaVersion': 1,
        'lastSavedAt': lastSavedAt,
        'activeViewDateKey': '2026-07-25',
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
        'lastResetDate': lastResetDate,
        'xpEarnedToday': 0,
        'coinsEarnedToday': 0,
        'habitsCompletedToday': <String, dynamic>{},
      },
      'history': <String, dynamic>{
        'habitCompletions': <String, dynamic>{},
        'habitCountValues': <String, dynamic>{},
        'habitSkips': <String, dynamic>{},
        'habitCompletionTimes': <String, dynamic>{},
        'habitOccurrenceStatuses': <String, dynamic>{},
        'habitStreakBreaks': <String, dynamic>{},
        'habitStreakShields': <String, dynamic>{},
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

AchievementLevelRewardCoordinator _disabledAchievementCoordinator() {
  return AchievementLevelRewardCoordinator(
    rewardRepository: _NoopAchievementLevelRewardRepository(),
    pendingClaimStore: _NoopPendingRewardClaimStore(),
    currentUserIdProvider: () => null,
    enabled: false,
  );
}

class _NoopAchievementLevelRewardRepository
    implements AchievementLevelRewardRepository {
  @override
  Future<AchievementLevelRewardResult<AchievementLevelRewardLedgerEntry>>
      claimAchievementReward({
    required String requestId,
    required String achievementId,
  }) async =>
          throw UnimplementedError();

  @override
  Future<AchievementLevelRewardResult<AchievementLevelRewardLedgerEntry>>
      claimLevelReward({
    required String requestId,
    required int level,
  }) async =>
          throw UnimplementedError();
}

class _NoopPendingRewardClaimStore implements PendingRewardClaimStore {
  @override
  Future<List<PendingRewardClaim>> loadPendingClaims(String userId) async =>
      throw UnimplementedError();

  @override
  Future<void> savePendingClaims(
    String userId,
    List<PendingRewardClaim> claims,
  ) async =>
      throw UnimplementedError();

  @override
  Future<void> clearPendingClaims(String userId) async =>
      throw UnimplementedError();
}
