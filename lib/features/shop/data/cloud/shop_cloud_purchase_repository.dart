import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/shop_purchase_failure.dart';
import 'shop_cloud_purchase_data_sources.dart';
import 'shop_cloud_purchase_dtos.dart';

class ShopCloudPurchaseException implements Exception {
  const ShopCloudPurchaseException({
    required this.code,
    required this.message,
    this.cause,
    this.retryable = false,
    this.definitive = false,
  });

  final ShopPurchaseFailureCode code;
  final String message;
  final Object? cause;
  final bool retryable;
  final bool definitive;

  bool get keepPending => !definitive;

  @override
  String toString() => 'ShopCloudPurchaseException($code, $message)';
}

class ShopCloudPurchaseRepository {
  ShopCloudPurchaseRepository({
    ShopCloudPurchaseDataSource? dataSource,
    Duration timeout = const Duration(seconds: 12),
  })  : _dataSource = dataSource ?? SupabaseShopCloudPurchaseDataSource(),
        _timeout = timeout;

  final ShopCloudPurchaseDataSource _dataSource;
  final Duration _timeout;

  Future<RemoteShopPurchaseResultDto> purchaseShopItem({
    required String itemId,
    required String requestId,
  }) async {
    try {
      final response = await _dataSource
          .purchaseShopItem(itemId: itemId, requestId: requestId)
          .timeout(_timeout);
      return RemoteShopPurchaseResultDto.fromRpcResponse(
        response,
        requestedItemId: itemId,
        requestId: requestId,
      );
    } on TimeoutException catch (error) {
      throw ShopCloudPurchaseException(
        code: ShopPurchaseFailureCode.timeout,
        message: 'Shop purchase timed out.',
        cause: error,
        retryable: true,
      );
    } on SocketException catch (error) {
      throw ShopCloudPurchaseException(
        code: ShopPurchaseFailureCode.networkUnavailable,
        message: 'Network unavailable while purchasing shop item.',
        cause: error,
        retryable: true,
      );
    } on PostgrestException catch (error) {
      throw _mapPostgrestException(error);
    } on FormatException catch (error) {
      throw ShopCloudPurchaseException(
        code: ShopPurchaseFailureCode.malformedResponse,
        message: 'The shop purchase response was malformed.',
        cause: error,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[shop_cloud_purchase] unexpected repository error: $error');
      }
      throw ShopCloudPurchaseException(
        code: ShopPurchaseFailureCode.unknown,
        message: 'Unexpected shop purchase error.',
        cause: error,
      );
    }
  }

  Future<RemoteShopBundlePurchaseResultDto> purchaseShopBundle({
    required String bundleId,
    required String requestId,
  }) async {
    try {
      final response = await _dataSource
          .purchaseShopBundle(bundleId: bundleId, requestId: requestId)
          .timeout(_timeout);
      return RemoteShopBundlePurchaseResultDto.fromRpcResponse(
        response,
        requestedBundleId: bundleId,
        requestId: requestId,
      );
    } on TimeoutException catch (error) {
      throw ShopCloudPurchaseException(
        code: ShopPurchaseFailureCode.timeout,
        message: 'Shop bundle purchase timed out.',
        cause: error,
        retryable: true,
      );
    } on SocketException catch (error) {
      throw ShopCloudPurchaseException(
        code: ShopPurchaseFailureCode.networkUnavailable,
        message: 'Network unavailable while purchasing shop bundle.',
        cause: error,
        retryable: true,
      );
    } on PostgrestException catch (error) {
      throw _mapBundlePostgrestException(error);
    } on FormatException catch (error) {
      throw ShopCloudPurchaseException(
        code: ShopPurchaseFailureCode.malformedResponse,
        message: 'The shop bundle purchase response was malformed.',
        cause: error,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
            '[shop_cloud_purchase] unexpected bundle repository error: $error');
      }
      throw ShopCloudPurchaseException(
        code: ShopPurchaseFailureCode.unknown,
        message: 'Unexpected shop bundle purchase error.',
        cause: error,
      );
    }
  }
}

ShopCloudPurchaseException _mapPostgrestException(PostgrestException error) {
  final normalizedMessage = error.message.toLowerCase();
  final normalizedCode = (error.code ?? '').trim().toUpperCase();

  if (normalizedMessage.contains('request_id is required') ||
      normalizedMessage.contains('request id is required')) {
    return const ShopCloudPurchaseException(
      code: ShopPurchaseFailureCode.requestIdRequired,
      message: 'request_id is required.',
      definitive: true,
    );
  }
  if (normalizedMessage.contains('item_id is required') ||
      normalizedMessage.contains('item id is required')) {
    return const ShopCloudPurchaseException(
      code: ShopPurchaseFailureCode.itemIdRequired,
      message: 'item_id is required.',
      definitive: true,
    );
  }
  if (normalizedMessage.contains('request_id already used') ||
      normalizedMessage.contains('already used by another user') ||
      normalizedCode == '23505') {
    return const ShopCloudPurchaseException(
      code: ShopPurchaseFailureCode.requestIdConflict,
      message: 'request_id already used by another user.',
      definitive: true,
    );
  }
  if (normalizedMessage.contains('shop item not found') ||
      normalizedMessage.contains('inactive')) {
    return const ShopCloudPurchaseException(
      code: ShopPurchaseFailureCode.itemNotFoundOrInactive,
      message: 'Shop item not found or inactive.',
      definitive: true,
    );
  }
  if (normalizedMessage.contains('wallet not found') ||
      normalizedMessage.contains('wallet not initialized')) {
    return const ShopCloudPurchaseException(
      code: ShopPurchaseFailureCode.walletNotInitialized,
      message: 'Wallet not initialized.',
      definitive: true,
    );
  }
  if (normalizedMessage.contains('insufficient wallet balance') ||
      normalizedMessage.contains('insufficient funds')) {
    return const ShopCloudPurchaseException(
      code: ShopPurchaseFailureCode.insufficientFunds,
      message: 'Insufficient wallet balance.',
      definitive: true,
    );
  }
  if (normalizedMessage.contains('quantity limit reached')) {
    return const ShopCloudPurchaseException(
      code: ShopPurchaseFailureCode.maxQuantityReached,
      message: 'Maximum quantity reached.',
      definitive: true,
    );
  }
  if (normalizedMessage.contains('item already owned')) {
    return const ShopCloudPurchaseException(
      code: ShopPurchaseFailureCode.itemAlreadyOwned,
      message: 'Item already owned.',
      definitive: true,
    );
  }
  if (normalizedMessage.contains('item cannot be equipped') ||
      normalizedMessage.contains('configuration invalid')) {
    return const ShopCloudPurchaseException(
      code: ShopPurchaseFailureCode.itemConfigurationInvalid,
      message: 'Item configuration is invalid.',
      definitive: true,
    );
  }
  if (normalizedMessage.contains('user_id is required') ||
      normalizedMessage.contains('authenticated user does not match')) {
    return const ShopCloudPurchaseException(
      code: ShopPurchaseFailureCode.authRequired,
      message: 'Authentication is required.',
      definitive: true,
    );
  }
  if (normalizedMessage.contains('timeout')) {
    return const ShopCloudPurchaseException(
      code: ShopPurchaseFailureCode.timeout,
      message: 'Shop purchase timed out.',
      retryable: true,
    );
  }
  if (normalizedCode == '42702') {
    return const ShopCloudPurchaseException(
      code: ShopPurchaseFailureCode.databaseQueryFailed,
      message: 'Database query failed while purchasing shop item.',
      retryable: true,
      definitive: true,
    );
  }
  if (normalizedMessage.contains('network') ||
      normalizedMessage.contains('socket') ||
      normalizedMessage.contains('connection')) {
    return const ShopCloudPurchaseException(
      code: ShopPurchaseFailureCode.networkUnavailable,
      message: 'Network unavailable while purchasing shop item.',
      retryable: true,
    );
  }

  if (kDebugMode) {
    debugPrint(
      '[shop_cloud_purchase] unmapped PostgrestException '
      '(${error.code}): ${error.message}',
    );
  }

  return ShopCloudPurchaseException(
    code: ShopPurchaseFailureCode.unknown,
    message: error.message,
    cause: error,
  );
}

ShopCloudPurchaseException _mapBundlePostgrestException(
  PostgrestException error,
) {
  final normalizedMessage = error.message.toLowerCase();
  final normalizedCode = (error.code ?? '').trim().toUpperCase();

  if (normalizedMessage.contains('request_id is required') ||
      normalizedMessage.contains('request id is required')) {
    return const ShopCloudPurchaseException(
      code: ShopPurchaseFailureCode.requestIdRequired,
      message: 'request_id is required.',
      definitive: true,
    );
  }
  if (normalizedMessage.contains('bundle_id is required') ||
      normalizedMessage.contains('bundle id is required')) {
    return const ShopCloudPurchaseException(
      code: ShopPurchaseFailureCode.bundleIdRequired,
      message: 'bundle_id is required.',
      definitive: true,
    );
  }
  if (normalizedMessage.contains('request_id already used') ||
      normalizedMessage.contains('already used by another user') ||
      normalizedCode == '23505') {
    return const ShopCloudPurchaseException(
      code: ShopPurchaseFailureCode.requestIdConflict,
      message: 'request_id already used by another user.',
      definitive: true,
    );
  }
  if (normalizedMessage.contains('bundle not found or inactive')) {
    return const ShopCloudPurchaseException(
      code: ShopPurchaseFailureCode.bundleNotFoundOrInactive,
      message: 'bundle not found or inactive.',
      definitive: true,
    );
  }
  if (normalizedMessage.contains('bundle configuration invalid')) {
    return const ShopCloudPurchaseException(
      code: ShopPurchaseFailureCode.bundleConfigurationInvalid,
      message: 'bundle configuration invalid.',
      definitive: true,
    );
  }
  if (normalizedMessage.contains('bundle already owned')) {
    return const ShopCloudPurchaseException(
      code: ShopPurchaseFailureCode.bundleAlreadyOwned,
      message: 'bundle already owned.',
      definitive: true,
    );
  }
  if (normalizedMessage.contains('bundle contains owned items')) {
    return const ShopCloudPurchaseException(
      code: ShopPurchaseFailureCode.bundleContainsOwnedItems,
      message: 'bundle contains owned items.',
      definitive: true,
    );
  }
  if (normalizedMessage.contains('wallet not found for user') ||
      normalizedMessage.contains('wallet not initialized')) {
    return const ShopCloudPurchaseException(
      code: ShopPurchaseFailureCode.walletNotFoundForUser,
      message: 'wallet not found for user.',
      definitive: true,
    );
  }
  if (normalizedMessage.contains('insufficient wallet balance') ||
      normalizedMessage.contains('insufficient funds')) {
    return const ShopCloudPurchaseException(
      code: ShopPurchaseFailureCode.insufficientFunds,
      message: 'Insufficient wallet balance.',
      definitive: true,
    );
  }
  if (normalizedMessage.contains('user_id is required') ||
      normalizedMessage.contains('authenticated user does not match')) {
    return const ShopCloudPurchaseException(
      code: ShopPurchaseFailureCode.authRequired,
      message: 'Authentication is required.',
      definitive: true,
    );
  }
  if (normalizedMessage.contains('timeout')) {
    return const ShopCloudPurchaseException(
      code: ShopPurchaseFailureCode.timeout,
      message: 'Shop bundle purchase timed out.',
      retryable: true,
    );
  }
  if (normalizedCode == '42702') {
    return const ShopCloudPurchaseException(
      code: ShopPurchaseFailureCode.databaseQueryFailed,
      message: 'Database query failed while purchasing shop bundle.',
      retryable: true,
      definitive: true,
    );
  }
  if (normalizedMessage.contains('network') ||
      normalizedMessage.contains('socket') ||
      normalizedMessage.contains('connection')) {
    return const ShopCloudPurchaseException(
      code: ShopPurchaseFailureCode.networkUnavailable,
      message: 'Network unavailable while purchasing shop bundle.',
      retryable: true,
    );
  }

  if (kDebugMode) {
    debugPrint(
      '[shop_cloud_purchase] unmapped bundle PostgrestException '
      '(${error.code}): ${error.message}',
    );
  }

  return ShopCloudPurchaseException(
    code: ShopPurchaseFailureCode.unknown,
    message: error.message,
    cause: error,
  );
}
