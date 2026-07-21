import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/rutio_supabase_client.dart';

abstract class UtilityConsumptionRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchActiveEffectRows({
    required String userId,
  });

  Future<Object?> activateUtilityEffect({
    required String requestId,
    required String utilityId,
    required String operationType,
    required String sourceType,
    required String sourceId,
    String? habitId,
    String? breakId,
  });

  Future<Object?> consumeUtilityUse({
    required String requestId,
    required String utilityId,
    required String operationType,
    required String sourceType,
    required String sourceId,
    String? habitId,
    String? breakId,
  });

  Future<Object?> applyStreakRecover({
    required String requestId,
    required String utilityId,
    required String operationType,
    required String breakId,
  });
}

class SupabaseUtilityConsumptionRemoteDataSource
    implements UtilityConsumptionRemoteDataSource {
  SupabaseUtilityConsumptionRemoteDataSource({SupabaseClient? client})
      : _client = client;

  final SupabaseClient? _client;

  SupabaseClient get _clientOrInstance =>
      _client ?? RutioSupabaseClient.instance;

  @override
  Future<List<Map<String, dynamic>>> fetchActiveEffectRows({
    required String userId,
  }) async {
    final rows = await _clientOrInstance
        .from('user_utility_effects')
        .select()
        .eq('user_id', userId)
        .eq('status', 'active')
        .order('activated_at', ascending: false);
    return (rows as List)
        .whereType<Map>()
        .map((row) => row.cast<String, dynamic>())
        .toList(growable: false);
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
  }) {
    return _clientOrInstance.rpc(
      'activate_utility_effect',
      params: <String, dynamic>{
        'p_request_id': requestId,
        'p_utility_id': utilityId,
        'p_operation_type': operationType,
        'p_source_type': sourceType,
        'p_source_id': sourceId,
        if (habitId != null) 'p_habit_id': habitId,
        if (breakId != null) 'p_break_id': breakId,
      },
    );
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
  }) {
    return _clientOrInstance.rpc(
      'consume_utility_use',
      params: <String, dynamic>{
        'p_request_id': requestId,
        'p_utility_id': utilityId,
        'p_operation_type': operationType,
        'p_source_type': sourceType,
        'p_source_id': sourceId,
        if (habitId != null) 'p_habit_id': habitId,
        if (breakId != null) 'p_break_id': breakId,
      },
    );
  }

  @override
  Future<Object?> applyStreakRecover({
    required String requestId,
    required String utilityId,
    required String operationType,
    required String breakId,
  }) {
    return _clientOrInstance.rpc(
      'apply_streak_recover',
      params: <String, dynamic>{
        'p_request_id': requestId,
        'p_utility_id': utilityId,
        'p_operation_type': operationType,
        'p_break_id': breakId,
      },
    );
  }
}
