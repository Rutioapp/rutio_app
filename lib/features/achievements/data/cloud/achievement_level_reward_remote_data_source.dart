import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/rutio_supabase_client.dart';
import 'achievement_level_reward_errors.dart';

abstract class AchievementLevelRewardRemoteDataSource {
  Future<Map<String, dynamic>?> claimAchievementReward({
    required String requestId,
    required String achievementId,
  });

  Future<Map<String, dynamic>?> claimLevelReward({
    required String requestId,
    required int level,
  });
}

class SupabaseAchievementLevelRewardRemoteDataSource
    implements AchievementLevelRewardRemoteDataSource {
  SupabaseAchievementLevelRewardRemoteDataSource({SupabaseClient? client})
      : _client = client;

  final SupabaseClient? _client;

  SupabaseClient get _clientOrInstance =>
      _client ?? RutioSupabaseClient.instance;

  @override
  Future<Map<String, dynamic>?> claimAchievementReward({
    required String requestId,
    required String achievementId,
  }) {
    return _rpc(
      'claim_achievement_reward',
      <String, dynamic>{
        'p_request_id': requestId,
        'p_achievement_id': achievementId,
        'p_operation_type': 'claim',
      },
    );
  }

  @override
  Future<Map<String, dynamic>?> claimLevelReward({
    required String requestId,
    required int level,
  }) {
    return _rpc(
      'claim_level_reward',
      <String, dynamic>{
        'p_request_id': requestId,
        'p_level': level,
        'p_operation_type': 'claim',
      },
    );
  }

  Future<Map<String, dynamic>?> _rpc(
    String fn,
    Map<String, dynamic> params,
  ) async {
    final userId = _currentUserId();
    if (userId == null) {
      throw const AchievementLevelRewardReadException(
        code: AchievementLevelRewardFailureCode.unauthenticated,
        message: 'No authenticated user session is available.',
      );
    }

    try {
      final response = await _clientOrInstance.rpc(fn, params: params);
      if (response == null) return null;
      if (response is Map) {
        return Map<String, dynamic>.from(response.cast<String, dynamic>());
      }
      throw const FormatException('Unexpected RPC response.');
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(
        error,
        fallbackMessage: 'Could not claim cloud reward.',
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[achievement_reward] unexpected rpc error: $error');
      }
      throw AchievementLevelRewardReadException(
        code: AchievementLevelRewardFailureCode.unknown,
        message: 'Could not claim cloud reward.',
        cause: error,
      );
    }
  }

  String? _currentUserId() {
    final userId = _clientOrInstance.auth.currentUser?.id.trim();
    if (userId == null || userId.isEmpty) return null;
    return userId;
  }
}

AchievementLevelRewardReadException _mapPostgrestError(
  PostgrestException error, {
  required String fallbackMessage,
}) {
  if (kDebugMode) {
    debugPrint(
      '[achievement_reward] postgrest error (${error.code}): ${error.message}',
    );
  }

  final code = (error.code ?? '').trim().toUpperCase();
  if (code == '42501') {
    return AchievementLevelRewardReadException(
      code: AchievementLevelRewardFailureCode.invalidResponse,
      message: fallbackMessage,
      cause: error,
    );
  }
  if (code == 'PGRST116') {
    return AchievementLevelRewardReadException(
      code: AchievementLevelRewardFailureCode.walletMissing,
      message: 'Wallet row is missing for the authenticated user.',
      cause: error,
    );
  }
  if (code == 'PGRST204' || code == '42703' || code == '42P01') {
    return AchievementLevelRewardReadException(
      code: AchievementLevelRewardFailureCode.invalidResponse,
      message: fallbackMessage,
      cause: error,
    );
  }

  final rawMessage = error.message.toLowerCase();
  if (rawMessage.contains('timeout')) {
    return AchievementLevelRewardReadException(
      code: AchievementLevelRewardFailureCode.timeout,
      message: fallbackMessage,
      cause: error,
    );
  }
  if (rawMessage.contains('network') ||
      rawMessage.contains('socket') ||
      rawMessage.contains('connection')) {
    return AchievementLevelRewardReadException(
      code: AchievementLevelRewardFailureCode.networkUnavailable,
      message: fallbackMessage,
      cause: error,
    );
  }

  return AchievementLevelRewardReadException(
    code: AchievementLevelRewardFailureCode.unknown,
    message: fallbackMessage,
    cause: error,
  );
}

class AchievementLevelRewardReadException implements Exception {
  const AchievementLevelRewardReadException({
    required this.code,
    required this.message,
    this.cause,
  });

  final AchievementLevelRewardFailureCode code;
  final String message;
  final Object? cause;
}
