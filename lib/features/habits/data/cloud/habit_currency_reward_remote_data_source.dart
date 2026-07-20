import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/rutio_supabase_client.dart';

abstract class HabitCurrencyRewardRemoteDataSource {
  Future<Object?> applyHabitCompletionReward({
    required String requestId,
    required String habitId,
    required String logicalDateKey,
    required String completionEventId,
  });

  Future<Object?> reverseHabitCompletionReward({
    required String requestId,
    required String habitId,
    required String logicalDateKey,
    required String completionEventId,
  });
}

class SupabaseHabitCurrencyRewardRemoteDataSource
    implements HabitCurrencyRewardRemoteDataSource {
  SupabaseHabitCurrencyRewardRemoteDataSource({SupabaseClient? client})
      : _client = client;

  final SupabaseClient? _client;

  SupabaseClient get _clientOrInstance =>
      _client ?? RutioSupabaseClient.instance;

  @override
  Future<Object?> applyHabitCompletionReward({
    required String requestId,
    required String habitId,
    required String logicalDateKey,
    required String completionEventId,
  }) {
    return _clientOrInstance.rpc(
      'apply_habit_completion_reward',
      params: <String, dynamic>{
        'p_request_id': requestId,
        'p_habit_id': habitId,
        'p_logical_date': logicalDateKey,
        'p_completion_event_id': completionEventId,
        'p_operation_type': 'apply',
      },
    );
  }

  @override
  Future<Object?> reverseHabitCompletionReward({
    required String requestId,
    required String habitId,
    required String logicalDateKey,
    required String completionEventId,
  }) {
    return _clientOrInstance.rpc(
      'reverse_habit_completion_reward',
      params: <String, dynamic>{
        'p_request_id': requestId,
        'p_habit_id': habitId,
        'p_logical_date': logicalDateKey,
        'p_completion_event_id': completionEventId,
        'p_operation_type': 'reverse',
      },
    );
  }
}
