import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/rutio_supabase_client.dart';
import 'habit_currency_rewards_config.dart';
import 'habit_currency_reward_errors.dart';
import 'habit_currency_reward_ledger.dart';
import 'habit_currency_reward_remote_data_source.dart';

abstract class HabitCurrencyRewardRepository {
  Future<HabitCurrencyRewardResult<HabitCurrencyRewardLedgerEntry>>
      applyHabitCompletionReward({
    required String requestId,
    required String habitId,
    required String logicalDateKey,
    required String completionEventId,
  });

  Future<HabitCurrencyRewardResult<HabitCurrencyRewardLedgerEntry>>
      reverseHabitCompletionReward({
    required String requestId,
    required String habitId,
    required String logicalDateKey,
    required String completionEventId,
  });
}

class SupabaseHabitCurrencyRewardRepository
    implements HabitCurrencyRewardRepository {
  SupabaseHabitCurrencyRewardRepository({
    HabitCurrencyRewardRemoteDataSource? remoteDataSource,
    bool? enabled,
    String? Function()? currentUserIdProvider,
    Duration timeout = const Duration(seconds: 12),
  })  : _remoteDataSource =
            remoteDataSource ?? SupabaseHabitCurrencyRewardRemoteDataSource(),
        _enabled = HabitCurrencyRewardsConfig.resolveEnabled(override: enabled),
        _currentUserIdProvider =
            currentUserIdProvider ?? _defaultCurrentUserIdProvider,
        _timeout = timeout;

  final HabitCurrencyRewardRemoteDataSource _remoteDataSource;
  final bool _enabled;
  final String? Function() _currentUserIdProvider;
  final Duration _timeout;

  @override
  Future<HabitCurrencyRewardResult<HabitCurrencyRewardLedgerEntry>>
      applyHabitCompletionReward({
    required String requestId,
    required String habitId,
    required String logicalDateKey,
    required String completionEventId,
  }) async {
    return _execute(
      operationType: 'apply',
      requestId: requestId,
      habitId: habitId,
      logicalDateKey: logicalDateKey,
      completionEventId: completionEventId,
    );
  }

  @override
  Future<HabitCurrencyRewardResult<HabitCurrencyRewardLedgerEntry>>
      reverseHabitCompletionReward({
    required String requestId,
    required String habitId,
    required String logicalDateKey,
    required String completionEventId,
  }) async {
    return _execute(
      operationType: 'reverse',
      requestId: requestId,
      habitId: habitId,
      logicalDateKey: logicalDateKey,
      completionEventId: completionEventId,
    );
  }

  Future<HabitCurrencyRewardResult<HabitCurrencyRewardLedgerEntry>> _execute({
    required String operationType,
    required String requestId,
    required String habitId,
    required String logicalDateKey,
    required String completionEventId,
  }) async {
    if (!_enabled) {
      return const HabitCurrencyRewardResult<
          HabitCurrencyRewardLedgerEntry>.failure(
        failure: HabitCurrencyRewardFailure(
          code: HabitCurrencyRewardFailureCode.featureDisabled,
          message: 'Habit cloud rewards are disabled.',
          definitive: true,
        ),
      );
    }

    final userId = _currentUserId();
    if (userId == null) {
      return const HabitCurrencyRewardResult<
          HabitCurrencyRewardLedgerEntry>.failure(
        failure: HabitCurrencyRewardFailure(
          code: HabitCurrencyRewardFailureCode.unauthenticated,
          message: 'No authenticated user session is available.',
          definitive: true,
        ),
      );
    }

    try {
      final response = await _callRemote(
        operationType: operationType,
        requestId: requestId,
        habitId: habitId,
        logicalDateKey: logicalDateKey,
        completionEventId: completionEventId,
      ).timeout(_timeout);

      final entry = _decodeLedgerEntry(
        response,
        expectedRequestId: requestId,
        expectedHabitId: habitId,
        expectedLogicalDateKey: logicalDateKey,
        expectedOperationType: operationType,
      );

      if (entry.userId != userId) {
        return const HabitCurrencyRewardResult<
            HabitCurrencyRewardLedgerEntry>.failure(
          failure: HabitCurrencyRewardFailure(
            code: HabitCurrencyRewardFailureCode.sessionChanged,
            message: 'Authentication session changed during habit reward.',
            definitive: true,
          ),
        );
      }

      return HabitCurrencyRewardResult<HabitCurrencyRewardLedgerEntry>.success(
        data: entry,
      );
    } on TimeoutException catch (error) {
      return HabitCurrencyRewardResult<HabitCurrencyRewardLedgerEntry>.failure(
        failure: HabitCurrencyRewardFailure(
          code: HabitCurrencyRewardFailureCode.timeout,
          message: 'Habit reward RPC timed out.',
          cause: error,
          retryable: true,
        ),
      );
    } on SocketException catch (error) {
      return HabitCurrencyRewardResult<HabitCurrencyRewardLedgerEntry>.failure(
        failure: HabitCurrencyRewardFailure(
          code: HabitCurrencyRewardFailureCode.networkUnavailable,
          message: 'Network unavailable while syncing habit reward.',
          cause: error,
          retryable: true,
        ),
      );
    } on PostgrestException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[habit_currency_reward] postgrest error '
          'code=${error.code} '
          'message=${error.message} '
          'details=${error.details} '
          'hint=${error.hint}',
        );
      }
      return HabitCurrencyRewardResult<HabitCurrencyRewardLedgerEntry>.failure(
        failure: _mapPostgrestError(error),
      );
    } on FormatException catch (error) {
      if (kDebugMode) {
        debugPrint(
            '[habit_currency_reward] malformed response: ${error.message}');
      }
      return HabitCurrencyRewardResult<HabitCurrencyRewardLedgerEntry>.failure(
        failure: HabitCurrencyRewardFailure(
          code: HabitCurrencyRewardFailureCode.invalidResponse,
          message: 'Habit reward response was malformed.',
          cause: error,
          definitive: true,
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[habit_currency_reward] unexpected error: $error');
      }
      return HabitCurrencyRewardResult<HabitCurrencyRewardLedgerEntry>.failure(
        failure: HabitCurrencyRewardFailure(
          code: HabitCurrencyRewardFailureCode.unknown,
          message: 'Unexpected habit reward error.',
          cause: error,
        ),
      );
    }
  }

  Future<Object?> _callRemote({
    required String operationType,
    required String requestId,
    required String habitId,
    required String logicalDateKey,
    required String completionEventId,
  }) {
    if (kDebugMode) {
      debugPrint(
        '[habit_currency_reward] rpc call '
        'operationType=$operationType '
        'requestId=$requestId '
        'habitId=$habitId '
        'logicalDateKey=$logicalDateKey '
        'completionEventId=$completionEventId',
      );
    }
    if (operationType == 'reverse') {
      return _remoteDataSource.reverseHabitCompletionReward(
        requestId: requestId,
        habitId: habitId,
        logicalDateKey: logicalDateKey,
        completionEventId: completionEventId,
      );
    }

    return _remoteDataSource.applyHabitCompletionReward(
      requestId: requestId,
      habitId: habitId,
      logicalDateKey: logicalDateKey,
      completionEventId: completionEventId,
    );
  }

  HabitCurrencyRewardLedgerEntry _decodeLedgerEntry(
    Object? response, {
    required String expectedRequestId,
    required String expectedHabitId,
    required String expectedLogicalDateKey,
    required String expectedOperationType,
  }) {
    if (response is! Map) {
      throw const FormatException('Unexpected habit reward RPC response.');
    }

    final entry =
        HabitCurrencyRewardLedgerEntry.fromMap(Map<String, dynamic>.from(
      response.cast<String, dynamic>(),
    ));

    if (entry.requestId != expectedRequestId ||
        entry.habitId != expectedHabitId ||
        entry.logicalDateKey != expectedLogicalDateKey ||
        entry.operationType != expectedOperationType) {
      throw const FormatException('Habit reward RPC response mismatch.');
    }

    return entry;
  }

  HabitCurrencyRewardFailure _mapPostgrestError(PostgrestException error) {
    final normalizedMessage = error.message.toLowerCase();
    final normalizedCode = (error.code ?? '').trim().toUpperCase();

    if (normalizedMessage.contains('request_id is required')) {
      return const HabitCurrencyRewardFailure(
        code: HabitCurrencyRewardFailureCode.requestConflict,
        message: 'request_id is required.',
        definitive: true,
      );
    }
    if (normalizedMessage.contains('habit not found') ||
        normalizedMessage.contains('unknown habit')) {
      return const HabitCurrencyRewardFailure(
        code: HabitCurrencyRewardFailureCode.habitMissing,
        message: 'Habit not found or inactive.',
        definitive: true,
      );
    }
    if (normalizedMessage.contains('insufficient') ||
        normalizedMessage.contains('negative balance')) {
      return const HabitCurrencyRewardFailure(
        code: HabitCurrencyRewardFailureCode.negativeBalance,
        message: 'Wallet cannot go negative.',
        definitive: true,
      );
    }
    if (normalizedCode == '23505' ||
        normalizedMessage.contains('already used') ||
        normalizedMessage.contains('duplicate')) {
      return const HabitCurrencyRewardFailure(
        code: HabitCurrencyRewardFailureCode.requestConflict,
        message: 'request_id or completion_event_id is already in use.',
        definitive: true,
      );
    }
    if (normalizedMessage.contains('timeout')) {
      return const HabitCurrencyRewardFailure(
        code: HabitCurrencyRewardFailureCode.timeout,
        message: 'Habit reward timed out.',
        retryable: true,
      );
    }
    if (normalizedMessage.contains('network') ||
        normalizedMessage.contains('socket') ||
        normalizedMessage.contains('connection')) {
      return const HabitCurrencyRewardFailure(
        code: HabitCurrencyRewardFailureCode.networkUnavailable,
        message: 'Network unavailable while syncing habit reward.',
        retryable: true,
      );
    }
    if (normalizedMessage.contains('wallet') &&
        normalizedMessage.contains('missing')) {
      return const HabitCurrencyRewardFailure(
        code: HabitCurrencyRewardFailureCode.walletMissing,
        message: 'Wallet row is missing for the authenticated user.',
        definitive: true,
      );
    }

    return HabitCurrencyRewardFailure(
      code: HabitCurrencyRewardFailureCode.unknown,
      message: error.message,
      cause: error,
    );
  }

  String? _currentUserId() {
    try {
      final userId = _currentUserIdProvider()?.trim();
      if (userId == null || userId.isEmpty) return null;
      return userId;
    } catch (_) {
      return null;
    }
  }

  static String? _defaultCurrentUserIdProvider() {
    try {
      final userId = RutioSupabaseClient.instance.auth.currentUser?.id.trim();
      if (userId == null || userId.isEmpty) return null;
      return userId;
    } catch (_) {
      return null;
    }
  }
}
