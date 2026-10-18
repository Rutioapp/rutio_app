import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/habits/data/cloud/habit_currency_reward_remote_data_source.dart';
import 'package:rutio/features/habits/data/cloud/habit_currency_reward_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('maps the authoritative progress returned by the economy RPC', () async {
    final remote = _FakeRewardRemoteDataSource(
      response: <String, dynamic>{
        'request_id': 'request-1',
        'transition_no': 7,
        'idempotent': false,
        'progress': <String, dynamic>{
          'user_id': 'user-1',
          'level': 2,
          'total_xp': 125,
          'current_level_xp': 25,
          'next_level_xp': 100,
          'ambar_balance': 42,
        },
      },
    );
    final repository = SupabaseHabitCurrencyRewardRepository(
      remoteDataSource: remote,
      currentUserIdProvider: () => 'user-1',
      enabled: true,
    );

    final result = await repository.applyHabitCompletionRewardWithValue(
      requestId: 'request-1',
      habitId: 'habit-1',
      logicalDateKey: '2026-07-18',
      completionEventId: 'event-1',
      value: 1,
    );

    expect(result.isSuccess, isTrue);
    expect(result.data?.balanceAfter, 42);
    expect(result.data?.authoritativeProgress['total_xp'], 125);
    expect(result.data?.authoritativeProgress['ambar_balance'], 42);
    expect(remote.lastValue, 1);
  });

  test(
      'classifies client version rejection as definitive but retryable by queue',
      () async {
    final repository = SupabaseHabitCurrencyRewardRepository(
      remoteDataSource: _FakeRewardRemoteDataSource(
        error: const PostgrestException(
          code: 'P0001',
          message: 'client version is required',
        ),
      ),
      currentUserIdProvider: () => 'user-1',
      enabled: true,
    );

    final result = await repository.applyHabitCompletionRewardWithValue(
      requestId: 'request-1',
      habitId: 'habit-1',
      logicalDateKey: '2026-10-18',
      completionEventId: 'event-1',
      value: 1,
    );

    expect(result.failure?.code.name, 'clientVersionRejected');
    expect(result.failure?.definitive, isTrue);
    expect(result.failure?.retryable, isFalse);
  });
}

class _FakeRewardRemoteDataSource
    implements HabitCurrencyRewardRemoteDataSource {
  _FakeRewardRemoteDataSource({this.response, this.error});

  final Object? response;
  final Object? error;
  int? lastValue;

  @override
  Future<Object?> applyHabitCompletionReward({
    required String requestId,
    required String habitId,
    required String logicalDateKey,
    required String completionEventId,
    int value = 0,
  }) async {
    if (error != null) throw error!;
    lastValue = value;
    return response;
  }

  @override
  Future<Object?> reverseHabitCompletionReward({
    required String requestId,
    required String habitId,
    required String logicalDateKey,
    required String completionEventId,
    int value = 0,
  }) async {
    if (error != null) throw error!;
    lastValue = value;
    return response;
  }
}
