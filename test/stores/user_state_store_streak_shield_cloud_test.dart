import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/features/habits/domain/models/streak_shield_operation_result.dart';
import 'package:rutio/features/shop/data/cloud/utility_consumption_ledger.dart';
import 'package:rutio/features/shop/data/cloud/utility_consumption_repository.dart';
import 'package:rutio/features/shop/domain/models/active_utility_effect.dart';
import 'package:rutio/stores/user_state_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserStateStore streak shield cloud', () {
    test('sends the remote habit UUID and keeps the local habit ID', () async {
      final utilityRepo = _RecordingUtilityConsumptionRepository();
      final store = await _createStore(
        utilityConsumptionRepository: utilityRepo,
        habits: const <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'habit-1',
            'title': 'Leer',
            'remoteId': '11111111-1111-4111-8111-111111111111',
          },
        ],
      );

      final result = await store.activateStreakShield(
        habitId: 'habit-1',
        operationId: 'shield-op-1',
      );

      expect(result.status, StreakShieldOperationStatus.success);
      expect(utilityRepo.calls, 1);
      expect(utilityRepo.requests.single['p_habit_id'],
          '11111111-1111-4111-8111-111111111111');
      expect(utilityRepo.requests.single['p_request_id'],
          'utility_activate:cloud-user:shield-op-1');
      expect(result.shield, isNotNull);
      expect(result.shield?.habitId, 'habit-1');
      expect(store.activeStreakShieldForHabit('habit-1'), isNotNull);
      expect(store.activeStreakShieldForHabit('habit-1')?.habitId, 'habit-1');
      expect(store.activeStreakShields.single.id,
          'streak_shield_habit-1_shield-op-1');
    });

    test('missing remote UUID skips the RPC call', () async {
      final utilityRepo = _RecordingUtilityConsumptionRepository();
      final store = await _createStore(
        utilityConsumptionRepository: utilityRepo,
        habits: const <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'habit-1',
            'title': 'Leer',
          },
        ],
      );

      final result = await store.activateStreakShield(
        habitId: 'habit-1',
        operationId: 'shield-op-2',
      );

      expect(result.status, StreakShieldOperationStatus.persistenceFailure);
      expect(
          result.errorMessage,
          contains(
              'Missing remote habit UUID for cloud streak shield activation'));
      expect(utilityRepo.calls, 0);
      expect(store.activeStreakShieldForHabit('habit-1'), isNull);
    });
  });
}

Future<UserStateStore> _createStore({
  required _RecordingUtilityConsumptionRepository utilityConsumptionRepository,
  required List<Map<String, dynamic>> habits,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final mutableHabits = habits
      .map((habit) => Map<String, dynamic>.from(habit))
      .toList(growable: false);

  final repo = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope('cloud-user');
  final store = UserStateStore(
    repo,
    journalEntrySyncService: JournalEntrySyncService(),
    utilityConsumptionRepository: utilityConsumptionRepository,
    utilityConsumptionEnabledOverride: true,
  );
  await store.save(
    <String, dynamic>{
      'userState': <String, dynamic>{
        'userId': 'cloud-user',
        'meta': <String, dynamic>{
          'schemaVersion': 1,
          'lastSavedAt': '2026-07-21T12:00:00.000Z',
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
          'lastResetDate': '2026-07-21',
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
        'activeHabits': mutableHabits,
      },
    },
  );

  return store;
}

class _RecordingUtilityConsumptionRepository
    implements UtilityConsumptionRepository {
  int calls = 0;
  final List<Map<String, dynamic>> requests = <Map<String, dynamic>>[];

  @override
  Future<List<ActiveUtilityEffect>> loadEffects(String userScope) async {
    return const <ActiveUtilityEffect>[];
  }

  @override
  Future<void> saveEffects(
    String userScope,
    List<ActiveUtilityEffect> effects,
  ) async {}

  @override
  Future<UtilityConsumptionLedgerEntry> activateUtilityEffect({
    required String requestId,
    required String utilityId,
    required String operationType,
    required String sourceType,
    required String sourceId,
    String? habitId,
    String? breakId,
  }) async {
    calls += 1;
    requests.add(<String, dynamic>{
      'p_request_id': requestId,
      'p_utility_id': utilityId,
      'p_operation_type': operationType,
      'p_source_type': sourceType,
      'p_source_id': sourceId,
      if (habitId != null) 'p_habit_id': habitId,
      if (breakId != null) 'p_break_id': breakId,
    });
    return UtilityConsumptionLedgerEntry(
      id: 'ledger-$calls',
      userId: 'cloud-user',
      requestId: requestId,
      operationType: operationType,
      sourceType: sourceType,
      sourceId: sourceId,
      utilityId: utilityId,
      utilityType: ActiveUtilityEffectType.streakShield,
      effectId: 'effect-$calls',
      totalUses: 1,
      remainingUses: 1,
      createdAt: DateTime.utc(2026, 7, 21, 12),
      isIdempotent: false,
    );
  }

  @override
  Future<UtilityConsumptionLedgerEntry> consumeUtilityUse({
    required String requestId,
    required String utilityId,
    required String operationType,
    required String sourceType,
    required String sourceId,
    String? habitId,
    String? breakId,
  }) {
    return activateUtilityEffect(
      requestId: requestId,
      utilityId: utilityId,
      operationType: operationType,
      sourceType: sourceType,
      sourceId: sourceId,
      habitId: habitId,
      breakId: breakId,
    );
  }

  @override
  Future<UtilityConsumptionLedgerEntry> applyStreakRecover({
    required String requestId,
    required String utilityId,
    required String operationType,
    required String breakId,
  }) {
    return activateUtilityEffect(
      requestId: requestId,
      utilityId: utilityId,
      operationType: operationType,
      sourceType: 'streak_recover',
      sourceId: breakId,
      breakId: breakId,
    );
  }
}
