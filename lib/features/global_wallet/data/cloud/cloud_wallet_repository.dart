import 'package:flutter/foundation.dart';

import 'cloud_wallet_errors.dart';
import 'cloud_wallet_remote_data_sources.dart';
import 'cloud_wallet_snapshot.dart';
import 'global_cloud_wallet_config.dart';
import '../../../../core/supabase/rutio_supabase_client.dart';

abstract class CloudWalletRepository {
  Future<WalletReadResult<CloudWalletSnapshot>> fetchWallet();
}

class SupabaseCloudWalletRepository implements CloudWalletRepository {
  SupabaseCloudWalletRepository({
    CloudWalletRemoteDataSource? remoteDataSource,
    bool? enabled,
    String? Function()? currentUserIdProvider,
    DateTime Function()? nowProvider,
  })  : _remoteDataSource =
            remoteDataSource ?? SupabaseCloudWalletRemoteDataSource(),
        _enabled = GlobalCloudWalletConfig.resolveEnabled(override: enabled),
        _currentUserIdProvider =
            currentUserIdProvider ?? _defaultCurrentUserIdProvider,
        _nowProvider = nowProvider ?? DateTime.now;

  final CloudWalletRemoteDataSource _remoteDataSource;
  final bool _enabled;
  final String? Function() _currentUserIdProvider;
  final DateTime Function() _nowProvider;

  @override
  Future<WalletReadResult<CloudWalletSnapshot>> fetchWallet() async {
    if (!_enabled) {
      return const WalletReadResult<CloudWalletSnapshot>.failure(
        failure: WalletFailure(
          code: WalletFailureCode.featureDisabled,
          message: 'Global cloud wallet is disabled.',
        ),
      );
    }

    final userId = _currentUserId();
    if (userId == null) {
      return const WalletReadResult<CloudWalletSnapshot>.failure(
        failure: WalletFailure(
          code: WalletFailureCode.unauthenticated,
          message: 'No authenticated user session is available.',
        ),
      );
    }

    try {
      final row = await _remoteDataSource.fetchWalletRow();
      if (!_isCurrentSession(userId)) {
        return const WalletReadResult<CloudWalletSnapshot>.failure(
          failure: WalletFailure(
            code: WalletFailureCode.sessionChanged,
            message: 'Authentication session changed during wallet fetch.',
          ),
        );
      }

      if (row == null) {
        return const WalletReadResult<CloudWalletSnapshot>.failure(
          failure: WalletFailure(
            code: WalletFailureCode.walletMissing,
            message: 'Wallet row is missing for the authenticated user.',
          ),
        );
      }

      final snapshot = CloudWalletSnapshot.fromMap(
        row,
        expectedUserId: userId,
        fetchedAt: _nowProvider().toUtc(),
      );
      return WalletReadResult<CloudWalletSnapshot>.success(data: snapshot);
    } on WalletReadException catch (error) {
      return WalletReadResult<CloudWalletSnapshot>.failure(
        failure: WalletFailure(
          code: error.code,
          message: error.message,
          cause: error.cause,
        ),
      );
    } on FormatException catch (error) {
      if (kDebugMode) {
        debugPrint('[global_wallet] wallet row rejected: ${error.message}');
      }
      return WalletReadResult<CloudWalletSnapshot>.failure(
        failure: WalletFailure(
          code: WalletFailureCode.invalidResponse,
          message: 'Wallet row could not be parsed.',
          cause: error,
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[global_wallet] unexpected wallet read error: $error');
      }
      return WalletReadResult<CloudWalletSnapshot>.failure(
        failure: WalletFailure(
          code: WalletFailureCode.unknown,
          message: 'Could not fetch global wallet.',
          cause: error,
        ),
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

  bool _isCurrentSession(String userId) {
    final current = _currentUserId();
    if (current == null) return false;
    return current == userId;
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
