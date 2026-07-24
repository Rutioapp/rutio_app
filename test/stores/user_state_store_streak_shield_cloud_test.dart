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

    test('is active on the activation day', () async {
      final utilityRepo = _RecordingUtilityConsumptionRepository();
      final now = DateTime(2026, 7, 24, 10);
      final store = await _createStore(
        utilityConsumptionRepository: utilityRepo,
        nowProvider: () => now,
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
        operationId: 'shield-op-day-1',
      );

      expect(result.status, StreakShieldOperationStatus.success);
      expect(store.activeStreakShieldForHabit('habit-1'), isNotNull);
      expect(store.activeStreakShields, hasLength(1));
      expect(store.activeStreakShields.single.isActive, isTrue);
    });

    test('expires on the next local day even when the habit was completed',
        () async {
      final utilityRepo = _RecordingUtilityConsumptionRepository();
      var now = DateTime(2026, 7, 24, 10);
      final store = await _createStore(
        utilityConsumptionRepository: utilityRepo,
        nowProvider: () => now,
        habits: const <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'habit-1',
            'title': 'Leer',
            'remoteId': '11111111-1111-4111-8111-111111111111',
          },
        ],
      );

      await store.activateStreakShield(
        habitId: 'habit-1',
        operationId: 'shield-op-day-2',
      );
      await store.completeHabit(habitId: 'habit-1');

      now = DateTime(2026, 7, 25, 0, 1);
      await store.load();

      expect(store.activeStreakShieldForHabit('habit-1'), isNull);
      expect(store.activeStreakShields, isEmpty);
    });

    test('protects the streak when the habit is missed the same day',
        () async {
      final utilityRepo = _RecordingUtilityConsumptionRepository();
      var now = DateTime(2026, 7, 23, 10);
      final store = await _createStore(
        utilityConsumptionRepository: utilityRepo,
        nowProvider: () => now,
        habits: const <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'habit-1',
            'title': 'Leer',
            'remoteId': '11111111-1111-4111-8111-111111111111',
          },
        ],
      );

      await store.completeHabit(habitId: 'habit-1');
      now = DateTime(2026, 7, 24, 10);
      await store.activateStreakShield(
        habitId: 'habit-1',
        operationId: 'shield-op-day-3',
      );

      now = DateTime(2026, 7, 25, 0, 1);
      await store.load();

      expect(store.activeStreakShieldForHabit('habit-1'), isNull);
      expect(store.activeStreakShields, isEmpty);
      expect(store.recoverableStreakBreaks, isEmpty);
      expect(
        store.habitStreakSnapshotForHabitId('habit-1').currentStreak,
        2,
      );
    });

    test('expired shield does not protect a later rupture', () async {
      final utilityRepo = _RecordingUtilityConsumptionRepository();
      var now = DateTime(2026, 7, 23, 10);
      final store = await _createStore(
        utilityConsumptionRepository: utilityRepo,
        nowProvider: () => now,
        habits: const <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'habit-1',
            'title': 'Leer',
            'remoteId': '11111111-1111-4111-8111-111111111111',
          },
        ],
      );

      await store.completeHabit(habitId: 'habit-1');
      now = DateTime(2026, 7, 24, 10);
      await store.activateStreakShield(
        habitId: 'habit-1',
        operationId: 'shield-op-day-4',
      );
      await store.completeHabit(habitId: 'habit-1');

      now = DateTime(2026, 7, 25, 0, 1);
      await store.load();
      now = DateTime(2026, 7, 26, 0, 1);
      await store.load();

      expect(store.activeStreakShieldForHabit('habit-1'), isNull);
      expect(store.activeStreakShields, isEmpty);
      expect(store.recoverableStreakBreaks, hasLength(1));
      expect(store.recoverableStreakBreaks.single.shieldProtected, isFalse);
      expect(
        store.recoverableStreakBreaks.single.missedOccurrenceDateKey,
        '2026-07-25',
      );
    });

    test('restarting the app does not reactivate an expired shield',
        () async {
      final utilityRepo = _RecordingUtilityConsumptionRepository();
      var now = DateTime(2026, 7, 24, 10);
      final store = await _createStore(
        utilityConsumptionRepository: utilityRepo,
        nowProvider: () => now,
        habits: const <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'habit-1',
            'title': 'Leer',
            'remoteId': '11111111-1111-4111-8111-111111111111',
          },
        ],
      );

      await store.activateStreakShield(
        habitId: 'habit-1',
        operationId: 'shield-op-day-5',
      );
      await store.completeHabit(habitId: 'habit-1');

      now = DateTime(2026, 7, 25, 0, 1);
      await store.load();

      final restartedStore = await _createStore(
        utilityConsumptionRepository: utilityRepo,
        nowProvider: () => now,
        habits: const <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'habit-1',
            'title': 'Leer',
            'remoteId': '11111111-1111-4111-8111-111111111111',
          },
        ],
        resetPrefs: false,
        seedState: false,
      );
      await restartedStore.load();

      expect(restartedStore.activeStreakShieldForHabit('habit-1'), isNull);
      expect(restartedStore.activeStreakShields, isEmpty);
    });

    test('two users keep independent shield state', () async {
      final utilityRepo = _RecordingUtilityConsumptionRepository();
      final now = DateTime(2026, 7, 24, 10);
      final storeA = await _createStore(
        utilityConsumptionRepository: utilityRepo,
        nowProvider: () => now,
        userId: 'cloud-user-a',
        habits: const <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'habit-1',
            'title': 'Leer',
            'remoteId': '11111111-1111-4111-8111-111111111111',
          },
        ],
      );
      await storeA.activateStreakShield(
        habitId: 'habit-1',
        operationId: 'shield-op-user-a',
      );

      final storeB = await _createStore(
        utilityConsumptionRepository: utilityRepo,
        nowProvider: () => now,
        userId: 'cloud-user-b',
        resetPrefs: false,
        habits: const <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'habit-1',
            'title': 'Leer',
            'remoteId': '22222222-2222-4222-8222-222222222222',
          },
        ],
      );

      expect(storeA.activeStreakShieldForHabit('habit-1'), isNotNull);
      expect(storeB.activeStreakShieldForHabit('habit-1'), isNull);
      expect(storeB.activeStreakShields, isEmpty);
    });
  });
}

Future<UserStateStore> _createStore({
  required _RecordingUtilityConsumptionRepository utilityConsumptionRepository,
  required List<Map<String, dynamic>> habits,
  DateTime Function()? nowProvider,
  String userId = 'cloud-user',
  bool resetPrefs = true,
  bool seedState = true,
}) async {
  if (resetPrefs) {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  }
  final currentNowProvider = nowProvider ?? DateTime.now;
  final mutableHabits = habits
      .map((habit) => Map<String, dynamic>.from(habit))
      .toList(growable: false);

  final repo = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope(userId);
  final store = UserStateStore(
    repo,
    journalEntrySyncService: JournalEntrySyncService(),
    utilityConsumptionRepository: utilityConsumptionRepository,
    utilityConsumptionEnabledOverride: true,
    nowProvider: currentNowProvider,
  );
  if (!seedState) {
    return store;
  }
  await store.save(
    <String, dynamic>{
      'userState': <String, dynamic>{
        'userId': userId,
        'meta': <String, dynamic>{
          'schemaVersion': 1,
          'lastSavedAt':
              currentNowProvider().toUtc().toIso8601String(),
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
          'lastResetDate':
              _dateKey(currentNowProvider().toLocal()),
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

String _dateKey(DateTime date) {
  final local = date.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
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
