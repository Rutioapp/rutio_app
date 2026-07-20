import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/rutio_supabase_client.dart';
import 'mystery_box_cloud_config.dart';
import 'mystery_box_opening_errors.dart';

abstract class MysteryBoxOpeningRemoteDataSource {
  Future<Object?> openMysteryBox({
    required String requestId,
  });
}

class SupabaseMysteryBoxOpeningRemoteDataSource
    implements MysteryBoxOpeningRemoteDataSource {
  SupabaseMysteryBoxOpeningRemoteDataSource({SupabaseClient? client})
      : _client = client;

  final SupabaseClient? _client;

  SupabaseClient get _clientOrInstance =>
      _client ?? RutioSupabaseClient.instance;

  @override
  Future<Object?> openMysteryBox({
    required String requestId,
  }) async {
    if (!MysteryBoxCloudConfig.resolveEnabled()) {
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
      final response = await _clientOrInstance.rpc(
        'open_mystery_box',
        params: <String, dynamic>{
          'p_request_id': requestId,
        },
      );
      return response;
    } on PostgrestException catch (error) {
      throw _mapPostgrestException(error);
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[mystery_box_cloud] unexpected open RPC error: $error',
        );
      }
      throw MysteryBoxOpeningCloudException(
        code: MysteryBoxOpeningCloudErrorCode.unknown,
        message: 'Unexpected mystery box opening error.',
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
      normalizedMessage.contains('inventory')) {
    return const MysteryBoxOpeningCloudException(
      code: MysteryBoxOpeningCloudErrorCode.noInventory,
      message: 'No mystery boxes are available.',
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
  if (normalizedMessage.contains('authentication') ||
      normalizedMessage.contains('auth.uid') ||
      normalizedMessage.contains('user_id is required')) {
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
