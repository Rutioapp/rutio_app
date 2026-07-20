import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/rutio_supabase_client.dart';
import 'cloud_wallet_errors.dart';

abstract class CloudWalletRemoteDataSource {
  Future<Map<String, dynamic>?> fetchWalletRow();
}

class SupabaseCloudWalletRemoteDataSource
    implements CloudWalletRemoteDataSource {
  SupabaseCloudWalletRemoteDataSource({SupabaseClient? client})
      : _client = client;

  final SupabaseClient? _client;

  SupabaseClient get _clientOrInstance =>
      _client ?? RutioSupabaseClient.instance;

  @override
  Future<Map<String, dynamic>?> fetchWalletRow() async {
    final userId = _currentUserId();
    if (userId == null) {
      throw const WalletReadException(
        code: WalletFailureCode.unauthenticated,
        message: 'No authenticated user session is available.',
      );
    }

    try {
      final row = await _clientOrInstance
          .from('user_wallets')
          .select('user_id, coins, version, created_at, updated_at')
          .eq('user_id', userId)
          .maybeSingle();

      if (row == null) return null;
      return Map<String, dynamic>.from(row);
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(
        error,
        fallbackMessage: 'Could not fetch global wallet.',
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[global_wallet] unexpected wallet fetch error: $error');
      }
      throw WalletReadException(
        code: WalletFailureCode.unknown,
        message: 'Could not fetch global wallet.',
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

WalletReadException _mapPostgrestError(
  PostgrestException error, {
  required String fallbackMessage,
}) {
  if (kDebugMode) {
    debugPrint(
      '[global_wallet] postgrest error (${error.code}): ${error.message}',
    );
  }

  final code = (error.code ?? '').trim().toUpperCase();
  if (code == '42501') {
    return WalletReadException(
      code: WalletFailureCode.invalidResponse,
      message: fallbackMessage,
      cause: error,
    );
  }
  if (code == 'PGRST116') {
    return WalletReadException(
      code: WalletFailureCode.walletMissing,
      message: 'Wallet row is missing for the authenticated user.',
      cause: error,
    );
  }
  if (code == 'PGRST204' || code == '42703' || code == '42P01') {
    return WalletReadException(
      code: WalletFailureCode.invalidResponse,
      message: fallbackMessage,
      cause: error,
    );
  }

  final rawMessage = error.message.toLowerCase();
  if (rawMessage.contains('timeout')) {
    return WalletReadException(
      code: WalletFailureCode.timeout,
      message: fallbackMessage,
      cause: error,
    );
  }
  if (rawMessage.contains('network') ||
      rawMessage.contains('socket') ||
      rawMessage.contains('connection')) {
    return WalletReadException(
      code: WalletFailureCode.networkUnavailable,
      message: fallbackMessage,
      cause: error,
    );
  }

  return WalletReadException(
    code: WalletFailureCode.unknown,
    message: fallbackMessage,
    cause: error,
  );
}

class WalletReadException implements Exception {
  const WalletReadException({
    required this.code,
    required this.message,
    this.cause,
  });

  final WalletFailureCode code;
  final String message;
  final Object? cause;

  @override
  String toString() => 'WalletReadException($code, $message)';
}
