import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/rutio_supabase_client.dart';
import 'mystery_box_cloud_config.dart';
import 'mystery_box_opening_dtos.dart';
import 'mystery_box_opening_errors.dart';
import 'mystery_box_opening_remote_data_sources.dart';

abstract interface class CloudMysteryBoxOpeningRepository {
  Future<RemoteMysteryBoxOpeningResultDto> openMysteryBox({
    required String requestId,
  });
}

class SupabaseCloudMysteryBoxOpeningRepository
    implements CloudMysteryBoxOpeningRepository {
  SupabaseCloudMysteryBoxOpeningRepository({
    MysteryBoxOpeningRemoteDataSource? remoteDataSource,
    bool? enabled,
    String? Function()? currentUserIdProvider,
    Duration timeout = const Duration(seconds: 12),
  })  : _remoteDataSource =
            remoteDataSource ?? SupabaseMysteryBoxOpeningRemoteDataSource(),
        _enabled = MysteryBoxCloudConfig.resolveEnabled(override: enabled),
        _currentUserIdProvider =
            currentUserIdProvider ?? _defaultCurrentUserIdProvider,
        _timeout = timeout;

  final MysteryBoxOpeningRemoteDataSource _remoteDataSource;
  final bool _enabled;
  final String? Function() _currentUserIdProvider;
  final Duration _timeout;

  @override
  Future<RemoteMysteryBoxOpeningResultDto> openMysteryBox({
    required String requestId,
  }) async {
    if (!_enabled) {
      throw const MysteryBoxOpeningCloudException(
        code: MysteryBoxOpeningCloudErrorCode.featureDisabled,
        message: 'Mystery box cloud opening is disabled.',
      );
    }

    final userId = _currentUserId();
    if (userId == null) {
      throw const MysteryBoxOpeningCloudException(
        code: MysteryBoxOpeningCloudErrorCode.unauthenticated,
        message: 'No authenticated user session is available.',
      );
    }

    try {
      final response = await _remoteDataSource
          .openMysteryBox(requestId: requestId)
          .timeout(_timeout);
      final dto = RemoteMysteryBoxOpeningResultDto.fromRpcResponse(
        response,
        requestId: requestId,
        expectedUserId: userId,
      );
      if (dto.userId != userId) {
        throw const MysteryBoxOpeningCloudException(
          code: MysteryBoxOpeningCloudErrorCode.sessionChanged,
          message: 'Authentication session changed during mystery box open.',
        );
      }
      return dto;
    } on TimeoutException catch (error) {
      throw MysteryBoxOpeningCloudException(
        code: MysteryBoxOpeningCloudErrorCode.timeout,
        message: 'Mystery box opening timed out.',
        cause: error,
        retryable: true,
      );
    } on SocketException catch (error) {
      throw MysteryBoxOpeningCloudException(
        code: MysteryBoxOpeningCloudErrorCode.networkUnavailable,
        message: 'Network unavailable while opening mystery box.',
        cause: error,
        retryable: true,
      );
    } on PostgrestException catch (error) {
      throw _mapPostgrestException(error);
    } on FormatException catch (error) {
      throw MysteryBoxOpeningCloudException(
        code: MysteryBoxOpeningCloudErrorCode.malformedResponse,
        message: 'Mystery box response could not be parsed.',
        cause: error,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[mystery_box_cloud] unexpected repository error: $error');
      }
      throw MysteryBoxOpeningCloudException(
        code: MysteryBoxOpeningCloudErrorCode.unknown,
        message: 'Unexpected mystery box opening error.',
        cause: error,
      );
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

  String? _currentUserId() {
    try {
      final userId = _currentUserIdProvider()?.trim();
      if (userId == null || userId.isEmpty) return null;
      return userId;
    } catch (_) {
      return null;
    }
  }
}

MysteryBoxOpeningCloudException _mapPostgrestException(
  PostgrestException error,
) {
  final normalizedMessage = error.message.toLowerCase();
  final normalizedCode = (error.code ?? '').trim().toUpperCase();

  if (normalizedMessage.contains('request_id is required') ||
      normalizedMessage.contains('request id is required')) {
    return const MysteryBoxOpeningCloudException(
      code: MysteryBoxOpeningCloudErrorCode.requestConflict,
      message: 'request_id is required.',
      definitive: true,
    );
  }
  if (normalizedMessage.contains('request_id already used') ||
      normalizedMessage.contains('already used by another user') ||
      normalizedCode == '23505') {
    return const MysteryBoxOpeningCloudException(
      code: MysteryBoxOpeningCloudErrorCode.requestConflict,
      message: 'request_id already used.',
      definitive: true,
    );
  }
  if (normalizedMessage.contains('wallet missing') ||
      normalizedMessage.contains('wallet not found') ||
      normalizedMessage.contains('wallet not initialized')) {
    return const MysteryBoxOpeningCloudException(
      code: MysteryBoxOpeningCloudErrorCode.walletMissing,
      message: 'Wallet row is missing for the authenticated user.',
      definitive: true,
    );
  }
  if (normalizedMessage.contains('no mystery box') ||
      normalizedMessage.contains('no boxes') ||
      normalizedMessage.contains('insufficient inventory')) {
    return const MysteryBoxOpeningCloudException(
      code: MysteryBoxOpeningCloudErrorCode.noInventory,
      message: 'No mystery boxes are available.',
      definitive: true,
    );
  }
  if (normalizedMessage.contains('unauthenticated') ||
      normalizedMessage.contains('authentication') ||
      normalizedMessage.contains('auth.uid')) {
    return const MysteryBoxOpeningCloudException(
      code: MysteryBoxOpeningCloudErrorCode.unauthenticated,
      message: 'Authentication is required.',
      definitive: true,
    );
  }
  if (normalizedMessage.contains('timeout')) {
    return const MysteryBoxOpeningCloudException(
      code: MysteryBoxOpeningCloudErrorCode.timeout,
      message: 'Mystery box opening timed out.',
      retryable: true,
    );
  }
  if (normalizedMessage.contains('network') ||
      normalizedMessage.contains('socket') ||
      normalizedMessage.contains('connection')) {
    return const MysteryBoxOpeningCloudException(
      code: MysteryBoxOpeningCloudErrorCode.networkUnavailable,
      message: 'Network unavailable while opening mystery box.',
      retryable: true,
    );
  }

  if (kDebugMode) {
    debugPrint(
      '[mystery_box_cloud] unmapped PostgrestException '
      '(${error.code}): ${error.message}',
    );
  }

  return MysteryBoxOpeningCloudException(
    code: MysteryBoxOpeningCloudErrorCode.unknown,
    message: error.message,
    cause: error,
  );
}
