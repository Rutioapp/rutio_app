import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/data/cloud/utility_consumption_remote_data_source.dart';
import 'package:rutio/features/shop/data/cloud/utility_consumption_repository.dart';
import 'package:rutio/features/shop/domain/models/active_utility_effect.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SupabaseUtilityConsumptionRepository', () {
    test('loads active effects from remote rows', () async {
      final remote = _FakeUtilityConsumptionRemoteDataSource();
      remote.activeRows = <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'effect-1',
          'user_id': 'user-1',
          'utility_id': 'utility_xp_boost_1d',
          'utility_type': 'xpBoost',
          'activated_at_millis': 1000,
          'remaining_uses': 9,
          'total_uses': 10,
          'status': 'active',
          'habit_id': '',
        },
      ];
      final repo = SupabaseUtilityConsumptionRepository(
        remoteDataSource: remote,
        enabled: true,
        currentUserIdProvider: () => 'user-1',
      );

      final effects = await repo.loadEffects('user-1');

      expect(effects, hasLength(1));
      expect(effects.first.type, ActiveUtilityEffectType.xpBoost);
      expect(effects.first.remainingUses, 9);
    });

    test('drops stale streak shields from a previous local day', () async {
      final remote = _FakeUtilityConsumptionRemoteDataSource();
      remote.activeRows = <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'shield-old',
          'user_id': 'user-1',
          'utility_id': 'utility_streak_shield_1',
          'utility_type': 'streakShield',
          'activated_at_millis':
              DateTime(2026, 7, 23, 10).millisecondsSinceEpoch,
          'remaining_uses': 1,
          'total_uses': 1,
          'status': 'active',
          'habit_id': 'habit-1',
        },
        <String, dynamic>{
          'id': 'effect-keep',
          'user_id': 'user-1',
          'utility_id': 'utility_xp_boost_1d',
          'utility_type': 'xpBoost',
          'activated_at_millis': 1000,
          'remaining_uses': 9,
          'total_uses': 10,
          'status': 'active',
          'habit_id': '',
        },
      ];
      final repo = SupabaseUtilityConsumptionRepository(
        remoteDataSource: remote,
        enabled: true,
        currentUserIdProvider: () => 'user-1',
        nowProvider: () => DateTime(2026, 7, 24, 10),
      );

      final effects = await repo.loadEffects('user-1');

      expect(effects, hasLength(1));
      expect(effects.single.id, 'effect-keep');
    });

    test('saveEffects activates a missing effect once', () async {
      final remote = _FakeUtilityConsumptionRemoteDataSource();
      final repo = SupabaseUtilityConsumptionRepository(
        remoteDataSource: remote,
        enabled: true,
        currentUserIdProvider: () => 'user-1',
      );

      await repo.saveEffects(
        'user-1',
        <ActiveUtilityEffect>[
          const ActiveUtilityEffect(
            id: 'effect-activate',
            utilityId: 'utility_coin_boost_1d',
            type: ActiveUtilityEffectType.coinBoost,
            activatedAtMillis: 1000,
            remainingUses: 10,
            totalUses: 10,
          ),
        ],
      );

      expect(remote.activateRequests, hasLength(1));
      expect(remote.activateRequests.single['p_operation_type'], 'activate');
    });

    test('applyStreakRecover forwards the operation type', () async {
      final remote = _FakeUtilityConsumptionRemoteDataSource();
      final repo = SupabaseUtilityConsumptionRepository(
        remoteDataSource: remote,
        enabled: true,
        currentUserIdProvider: () => 'user-1',
      );

      try {
        await repo.applyStreakRecover(
          requestId: 'recover-1',
          utilityId: 'utility_streak_recover_1',
          operationType: 'recover',
          breakId: 'break-1',
        );
      } catch (_) {}

      expect(remote.activateRequests, isNotEmpty);
      expect(remote.activateRequests.single['p_operation_type'], 'recover');
    });
  });
}

class _FakeUtilityConsumptionRemoteDataSource
    implements UtilityConsumptionRemoteDataSource {
  List<Map<String, dynamic>> activeRows = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> activateRequests = <Map<String, dynamic>>[];

  @override
  Future<List<Map<String, dynamic>>> fetchActiveEffectRows({
    required String userId,
  }) async {
    return activeRows;
  }

  @override
  Future<Object?> activateUtilityEffect({
    required String requestId,
    required String utilityId,
    required String operationType,
    required String sourceType,
    required String sourceId,
    String? habitId,
    String? breakId,
  }) async {
    activateRequests.add(<String, dynamic>{
      'p_request_id': requestId,
      'p_utility_id': utilityId,
      'p_operation_type': operationType,
      'p_source_type': sourceType,
      'p_source_id': sourceId,
      if (habitId != null) 'p_habit_id': habitId,
      if (breakId != null) 'p_break_id': breakId,
    });
    return <String, dynamic>{
      'id': 'ledger-${activateRequests.length}',
      'user_id': 'user-1',
      'request_id': requestId,
      'operation_type': operationType,
      'source_type': sourceType,
      'source_id': sourceId,
      'utility_id': utilityId,
      'utility_type': utilityId.contains('coin')
          ? 'coinBoost'
          : utilityId.contains('shield')
              ? 'streakShield'
              : 'xpBoost',
      'effect_id': 'effect-${activateRequests.length}',
      'total_uses': 10,
      'remaining_uses': 10,
      'created_at': DateTime(2026, 7, 19).toIso8601String(),
      'is_idempotent': false,
    };
  }

  @override
  Future<Object?> consumeUtilityUse({
    required String requestId,
    required String utilityId,
    required String operationType,
    required String sourceType,
    required String sourceId,
    String? habitId,
    String? breakId,
  }) async {
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
  Future<Object?> applyStreakRecover({
    required String requestId,
    required String utilityId,
    required String operationType,
    required String breakId,
  }) async {
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
