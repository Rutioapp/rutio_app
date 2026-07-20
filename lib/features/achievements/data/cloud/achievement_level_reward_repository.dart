import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/rutio_supabase_client.dart';
import 'achievement_level_reward_config.dart';
import 'achievement_level_reward_errors.dart';
import 'achievement_level_reward_ledger.dart';
import 'achievement_level_reward_remote_data_source.dart';

abstract class AchievementLevelRewardRepository {
  Future<AchievementLevelRewardResult<AchievementLevelRewardLedgerEntry>>
      claimAchievementReward({
    required String requestId,
    required String achievementId,
  });

  Future<AchievementLevelRewardResult<AchievementLevelRewardLedgerEntry>>
      claimLevelReward({
    required String requestId,
    required int level,
  });
}

class SupabaseAchievementLevelRewardRepository
    implements AchievementLevelRewardRepository {
  SupabaseAchievementLevelRewardRepository({
    AchievementLevelRewardRemoteDataSource? remoteDataSource,
    bool? enabled,
    String? Function()? currentUserIdProvider,
    Duration timeout = const Duration(seconds: 12),
  })  : _remoteDataSource =
            remoteDataSource ?? SupabaseAchievementLevelRewardRemoteDataSource(),
        _enabled =
            AchievementLevelRewardConfig.resolveEnabled(override: enabled),
        _currentUserIdProvider =
            currentUserIdProvider ?? _defaultCurrentUserIdProvider,
        _timeout = timeout;

  final AchievementLevelRewardRemoteDataSource _remoteDataSource;
  final bool _enabled;
  final String? Function() _currentUserIdProvider;
  final Duration _timeout;

  @override
  Future<AchievementLevelRewardResult<AchievementLevelRewardLedgerEntry>>
      claimAchievementReward({
    required String requestId,
    required String achievementId,
  }) {
    return _execute(
      operationType: 'claim',
      sourceType: 'achievement_reward',
      requestId: requestId,
      sourceId: achievementId,
      callRemote: () => _remoteDataSource.claimAchievementReward(
        requestId: requestId,
        achievementId: achievementId,
      ),
    );
  }

  @override
  Future<AchievementLevelRewardResult<AchievementLevelRewardLedgerEntry>>
      claimLevelReward({
    required String requestId,
    required int level,
  }) {
    return _execute(
      operationType: 'claim',
      sourceType: 'level_reward',
      requestId: requestId,
      sourceId: level.toString(),
      callRemote: () => _remoteDataSource.claimLevelReward(
        requestId: requestId,
        level: level,
      ),
    );
  }

  Future<AchievementLevelRewardResult<AchievementLevelRewardLedgerEntry>>
      _execute({
    required String operationType,
    required String sourceType,
    required String requestId,
    required String sourceId,
    required Future<Map<String, dynamic>?> Function() callRemote,
  }) async {
    if (!_enabled) {
      return const AchievementLevelRewardResult<
          AchievementLevelRewardLedgerEntry>.failure(
        failure: AchievementLevelRewardFailure(
          code: AchievementLevelRewardFailureCode.featureDisabled,
          message: 'Achievement and level cloud rewards are disabled.',
          definitive: true,
        ),
      );
    }

    final userId = _currentUserId();
    if (userId == null) {
      return const AchievementLevelRewardResult<
          AchievementLevelRewardLedgerEntry>.failure(
        failure: AchievementLevelRewardFailure(
          code: AchievementLevelRewardFailureCode.unauthenticated,
          message: 'No authenticated user session is available.',
          definitive: true,
        ),
      );
    }

    try {
      final response = await callRemote().timeout(_timeout);
      final entry = _decodeLedgerEntry(
        response,
        expectedRequestId: requestId,
        expectedSourceType: sourceType,
        expectedSourceId: sourceId,
        expectedOperationType: operationType,
      );

      if (entry.userId != userId) {
        return const AchievementLevelRewardResult<
            AchievementLevelRewardLedgerEntry>.failure(
          failure: AchievementLevelRewardFailure(
            code: AchievementLevelRewardFailureCode.sessionChanged,
            message: 'Authentication session changed during reward claim.',
            definitive: true,
          ),
        );
      }

      return AchievementLevelRewardResult<
          AchievementLevelRewardLedgerEntry>.success(data: entry);
    } on TimeoutException catch (error) {
      return AchievementLevelRewardResult<AchievementLevelRewardLedgerEntry>
          .failure(
        failure: AchievementLevelRewardFailure(
          code: AchievementLevelRewardFailureCode.timeout,
          message: 'Cloud reward RPC timed out.',
          cause: error,
          retryable: true,
        ),
      );
    } on SocketException catch (error) {
      return AchievementLevelRewardResult<AchievementLevelRewardLedgerEntry>
          .failure(
        failure: AchievementLevelRewardFailure(
          code: AchievementLevelRewardFailureCode.networkUnavailable,
          message: 'Network unavailable while syncing cloud reward.',
          cause: error,
          retryable: true,
        ),
      );
    } on AchievementLevelRewardReadException catch (error) {
      return AchievementLevelRewardResult<AchievementLevelRewardLedgerEntry>
          .failure(
        failure: AchievementLevelRewardFailure(
          code: error.code,
          message: error.message,
          cause: error.cause,
          definitive: error.code == AchievementLevelRewardFailureCode
                  .achievementMissing ||
              error.code == AchievementLevelRewardFailureCode.levelMissing ||
              error.code == AchievementLevelRewardFailureCode.walletMissing ||
              error.code == AchievementLevelRewardFailureCode.invalidResponse,
          retryable: error.code ==
              AchievementLevelRewardFailureCode.networkUnavailable ||
              error.code == AchievementLevelRewardFailureCode.timeout,
        ),
      );
    } on FormatException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[achievement_reward] malformed response: ${error.message}',
        );
      }
      return AchievementLevelRewardResult<AchievementLevelRewardLedgerEntry>
          .failure(
        failure: AchievementLevelRewardFailure(
          code: AchievementLevelRewardFailureCode.invalidResponse,
          message: 'Cloud reward response was malformed.',
          cause: error,
          definitive: true,
        ),
      );
    } on PostgrestException catch (error) {
      return AchievementLevelRewardResult<AchievementLevelRewardLedgerEntry>
          .failure(
        failure: _mapPostgrestErrorAsFailure(error),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[achievement_reward] unexpected error: $error');
      }
      return AchievementLevelRewardResult<AchievementLevelRewardLedgerEntry>
          .failure(
        failure: AchievementLevelRewardFailure(
          code: AchievementLevelRewardFailureCode.unknown,
          message: 'Unexpected cloud reward error.',
          cause: error,
        ),
      );
    }
  }

  AchievementLevelRewardLedgerEntry _decodeLedgerEntry(
    Map<String, dynamic>? response, {
    required String expectedRequestId,
    required String expectedSourceType,
    required String expectedSourceId,
    required String expectedOperationType,
  }) {
    if (response == null) {
      throw const FormatException('Unexpected cloud reward response.');
    }

    final entry = AchievementLevelRewardLedgerEntry.fromMap(response);
    if (entry.requestId != expectedRequestId ||
        entry.sourceType != expectedSourceType ||
        entry.sourceId != expectedSourceId ||
        entry.operationType != expectedOperationType) {
      throw const FormatException('Cloud reward response mismatch.');
    }
    return entry;
  }

  AchievementLevelRewardFailure _mapPostgrestErrorAsFailure(
    PostgrestException error,
  ) {
    final normalizedMessage = error.message.toLowerCase();
    final normalizedCode = (error.code ?? '').trim().toUpperCase();

    if (normalizedMessage.contains('achievement not found') ||
        normalizedMessage.contains('unknown achievement')) {
      return const AchievementLevelRewardFailure(
        code: AchievementLevelRewardFailureCode.achievementMissing,
        message: 'Achievement not found or not eligible.',
        definitive: true,
      );
    }
    if (normalizedMessage.contains('level not found') ||
        normalizedMessage.contains('level reward not found')) {
      return const AchievementLevelRewardFailure(
        code: AchievementLevelRewardFailureCode.levelMissing,
        message: 'Level reward not found or not eligible.',
        definitive: true,
      );
    }
    if (normalizedMessage.contains('wallet') &&
        normalizedMessage.contains('missing')) {
      return const AchievementLevelRewardFailure(
        code: AchievementLevelRewardFailureCode.walletMissing,
        message: 'Wallet row is missing for the authenticated user.',
        definitive: true,
      );
    }
    if (normalizedMessage.contains('insufficient') ||
        normalizedMessage.contains('negative balance')) {
      return const AchievementLevelRewardFailure(
        code: AchievementLevelRewardFailureCode.negativeBalance,
        message: 'Wallet cannot go negative.',
        definitive: true,
      );
    }
    if (normalizedCode == '23505' ||
        normalizedMessage.contains('already used') ||
        normalizedMessage.contains('duplicate')) {
      return const AchievementLevelRewardFailure(
        code: AchievementLevelRewardFailureCode.requestConflict,
        message: 'request_id or source_id is already in use.',
        definitive: true,
      );
    }
    if (normalizedMessage.contains('timeout')) {
      return const AchievementLevelRewardFailure(
        code: AchievementLevelRewardFailureCode.timeout,
        message: 'Cloud reward timed out.',
        retryable: true,
      );
    }
    if (normalizedMessage.contains('network') ||
        normalizedMessage.contains('socket') ||
        normalizedMessage.contains('connection')) {
      return const AchievementLevelRewardFailure(
        code: AchievementLevelRewardFailureCode.networkUnavailable,
        message: 'Network unavailable while syncing cloud reward.',
        retryable: true,
      );
    }

    return AchievementLevelRewardFailure(
      code: AchievementLevelRewardFailureCode.unknown,
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
