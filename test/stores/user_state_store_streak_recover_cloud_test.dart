import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/features/habits/domain/models/streak_recover_operation_result.dart';
import 'package:rutio/features/shop/data/cloud/utility_consumption_ledger.dart';
import 'package:rutio/features/shop/data/cloud/utility_consumption_repository.dart';
import 'package:rutio/features/shop/domain/models/active_utility_effect.dart';
import 'package:rutio/stores/user_state_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserStateStore streak recover cloud', () {
    test('valid recovery calls the RPC and marks the break recovered',
        () async {
      final utilityRepo = _RecordingUtilityConsumptionRepository();
      final store = await _createStore(
        utilityConsumptionRepository: utilityRepo,
        recoverableBreaks: const <String, dynamic>{
          'break-1': <String, dynamic>{
            'id': 'break-1',
            'userId': 'cloud-user',
            'habitId': 'habit-1',
            'brokenAtMillis': 1,
            'missedOccurrenceDateKey': '2026-07-21',
            'previousStreak': 5,
            'currentStreakAfterBreak': 0,
            'status': 'recoverable',
            'shieldProtected': false,
          },
        },
      );

      final result = await store.recoverStreakBreak(
        breakId: 'break-1',
        operationId: 'recover-op-1',
      );

      expect(result.status, StreakRecoverOperationStatus.success);
      expect(result.isSuccess, isTrue);
      expect(utilityRepo.calls, 1);
      expect(utilityRepo.requests.single['p_break_id'], 'break-1');
      expect(utilityRepo.requests.single['p_request_id'],
          'utility_recover:cloud-user:break-1:recover-op-1');
      expect(store.recoverableStreakBreaks.single.isRecovered, isTrue);
      expect(store.recoverableStreakBreaks.single.recoveryOperationId,
          'recover-op-1');
    });

    test('expired breaks skip the RPC and become expired locally', () async {
      final utilityRepo = _RecordingUtilityConsumptionRepository();
      final store = await _createStore(
        utilityConsumptionRepository: utilityRepo,
        recoverableBreaks: const <String, dynamic>{
          'break-1': <String, dynamic>{
            'id': 'break-1',
            'userId': 'cloud-user',
            'habitId': 'habit-1',
            'brokenAtMillis': 1,
            'missedOccurrenceDateKey': '2026-07-18',
            'previousStreak': 5,
            'currentStreakAfterBreak': 0,
            'status': 'recoverable',
            'shieldProtected': false,
          },
        },
      );

      final result = await store.recoverStreakBreak(
        breakId: 'break-1',
        operationId: 'recover-op-expired',
      );

      expect(result.status, StreakRecoverOperationStatus.recoveryExpired);
      expect(result.isSuccess, isFalse);
      expect(utilityRepo.calls, 0);
      expect(_breakStatus(store, 'break-1'), 'expired');
    });

    test('already recovered breaks do not consume another unit', () async {
      final utilityRepo = _RecordingUtilityConsumptionRepository();
      final store = await _createStore(
        utilityConsumptionRepository: utilityRepo,
        recoverableBreaks: const <String, dynamic>{
          'break-1': <String, dynamic>{
            'id': 'break-1',
            'userId': 'cloud-user',
            'habitId': 'habit-1',
            'brokenAtMillis': 1,
            'missedOccurrenceDateKey': '2026-07-21',
            'previousStreak': 5,
            'currentStreakAfterBreak': 0,
            'status': 'recoverable',
            'shieldProtected': false,
          },
        },
      );

      final first = await store.recoverStreakBreak(
        breakId: 'break-1',
        operationId: 'recover-op-1',
      );
      final second = await store.recoverStreakBreak(
        breakId: 'break-1',
        operationId: 'recover-op-2',
      );

      expect(first.status, StreakRecoverOperationStatus.success);
      expect(second.status, StreakRecoverOperationStatus.alreadyRecovered);
      expect(utilityRepo.calls, 1);
    });

    test('same operation is idempotent and only calls the RPC once', () async {
      final utilityRepo = _RecordingUtilityConsumptionRepository();
      final store = await _createStore(
        utilityConsumptionRepository: utilityRepo,
        recoverableBreaks: const <String, dynamic>{
          'break-1': <String, dynamic>{
            'id': 'break-1',
            'userId': 'cloud-user',
            'habitId': 'habit-1',
            'brokenAtMillis': 1,
            'missedOccurrenceDateKey': '2026-07-21',
            'previousStreak': 5,
            'currentStreakAfterBreak': 0,
            'status': 'recoverable',
            'shieldProtected': false,
          },
        },
      );

      final first = await store.recoverStreakBreak(
        breakId: 'break-1',
        operationId: 'recover-op-same',
      );
      final second = await store.recoverStreakBreak(
        breakId: 'break-1',
        operationId: 'recover-op-same',
      );

      expect(first.status, StreakRecoverOperationStatus.success);
      expect(second.status, StreakRecoverOperationStatus.success);
      expect(utilityRepo.calls, 1);
      expect(store.recoverableStreakBreaks.single.recoveryOperationId,
          'recover-op-same');
    });
  });
}

Future<UserStateStore> _createStore({
  required _RecordingUtilityConsumptionRepository utilityConsumptionRepository,
  required Map<String, dynamic> recoverableBreaks,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final mutableRecoverableBreaks = recoverableBreaks.map(
    (key, value) => MapEntry(
      key,
      value is Map ? Map<String, dynamic>.from(value) : value,
    ),
  );

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
          'habitStreakBreaks': mutableRecoverableBreaks,
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
        'activeHabits': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'habit-1',
            'title': 'Leer',
          },
        ],
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
    throw UnimplementedError();
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
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<UtilityConsumptionLedgerEntry> applyStreakRecover({
    required String requestId,
    required String utilityId,
    required String operationType,
    required String breakId,
  }) async {
    calls += 1;
    requests.add(<String, dynamic>{
      'p_request_id': requestId,
      'p_utility_id': utilityId,
      'p_operation_type': operationType,
      'p_break_id': breakId,
    });
    return UtilityConsumptionLedgerEntry(
      id: 'ledger-$calls',
      userId: 'cloud-user',
      requestId: requestId,
      operationType: operationType,
      sourceType: 'streak_recover',
      sourceId: breakId,
      utilityId: utilityId,
      utilityType: ActiveUtilityEffectType.streakShield,
      effectId: 'effect-$calls',
      totalUses: 1,
      remainingUses: 1,
      createdAt: DateTime.utc(2026, 7, 21, 12),
      isIdempotent: false,
    );
  }
}

String? _breakStatus(UserStateStore store, String breakId) {
  final dynamic root = store.state;
  if (root is! Map) return null;
  final userState = root['userState'];
  if (userState is! Map) return null;
  final history = userState['history'];
  if (history is! Map) return null;
  final breaks = history['habitStreakBreaks'];
  if (breaks is! Map) return null;
  final breakRecord = breaks[breakId];
  if (breakRecord is! Map) return null;
  return breakRecord['status']?.toString();
}
