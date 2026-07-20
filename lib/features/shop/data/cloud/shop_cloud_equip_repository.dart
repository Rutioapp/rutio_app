import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'shop_cloud_equip_data_sources.dart';
import 'shop_cloud_equip_dtos.dart';

enum ShopCosmeticsOperationFailureCode {
  requestIdRequired,
  requestIdConflict,
  itemNotFoundOrInactive,
  itemNotOwned,
  itemConfigurationInvalid,
  authRequired,
  timeout,
  networkUnavailable,
  malformedResponse,
  unknown,
}

class ShopCloudEquipException implements Exception {
  const ShopCloudEquipException({
    required this.code,
    required this.message,
    this.cause,
    this.retryable = false,
    this.definitive = false,
  });

  final ShopCosmeticsOperationFailureCode code;
  final String message;
  final Object? cause;
  final bool retryable;
  final bool definitive;

  bool get keepPending => !definitive;
}

class ShopCloudEquipRepository {
  ShopCloudEquipRepository({
    ShopCloudEquipDataSource? dataSource,
    Duration timeout = const Duration(seconds: 12),
  })  : _dataSource = dataSource ?? SupabaseShopCloudEquipDataSource(),
        _timeout = timeout;

  final ShopCloudEquipDataSource _dataSource;
  final Duration _timeout;

  Future<RemoteShopEquipResultDto> equipShopCosmetic({
    required String itemId,
    required String requestId,
  }) async {
    try {
      final response = await _dataSource
          .equipShopCosmetic(itemId: itemId, requestId: requestId)
          .timeout(_timeout);
      return RemoteShopEquipResultDto.fromRpcResponse(
        response,
        requestedItemId: itemId,
        requestId: requestId,
      );
    } on TimeoutException catch (error) {
      throw ShopCloudEquipException(
        code: ShopCosmeticsOperationFailureCode.timeout,
        message: 'Shop cosmetic equip timed out.',
        cause: error,
        retryable: true,
      );
    } on SocketException catch (error) {
      throw ShopCloudEquipException(
        code: ShopCosmeticsOperationFailureCode.networkUnavailable,
        message: 'Network unavailable while equipping cosmetic.',
        cause: error,
        retryable: true,
      );
    } on PostgrestException catch (error) {
      throw _mapPostgrestException(error);
    } on FormatException catch (error) {
      throw ShopCloudEquipException(
        code: ShopCosmeticsOperationFailureCode.malformedResponse,
        message: 'The shop equip response was malformed.',
        cause: error,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[shop_cloud_equip] unexpected repository error: $error');
      }
      throw ShopCloudEquipException(
        code: ShopCosmeticsOperationFailureCode.unknown,
        message: 'Unexpected shop equip error.',
        cause: error,
      );
    }
  }
}

ShopCloudEquipException _mapPostgrestException(PostgrestException error) {
  final normalizedMessage = error.message.toLowerCase();
  final normalizedCode = (error.code ?? '').trim().toUpperCase();

  if (normalizedMessage.contains('request_id is required') ||
      normalizedMessage.contains('request id is required')) {
    return const ShopCloudEquipException(
      code: ShopCosmeticsOperationFailureCode.requestIdRequired,
      message: 'request_id is required.',
      definitive: true,
    );
  }
  if (normalizedMessage.contains('request_id already used') ||
      normalizedMessage.contains('already used by another user') ||
      normalizedCode == '23505') {
    return const ShopCloudEquipException(
      code: ShopCosmeticsOperationFailureCode.requestIdConflict,
      message: 'request_id already used by another user.',
      definitive: true,
    );
  }
  if (normalizedMessage.contains('shop item not found') ||
      normalizedMessage.contains('inactive')) {
    return const ShopCloudEquipException(
      code: ShopCosmeticsOperationFailureCode.itemNotFoundOrInactive,
      message: 'Shop item not found or inactive.',
      definitive: true,
    );
  }
  if (normalizedMessage.contains('item must be owned before equip') ||
      normalizedMessage.contains('item is not owned')) {
    return const ShopCloudEquipException(
      code: ShopCosmeticsOperationFailureCode.itemNotOwned,
      message: 'Item must be owned before equip.',
      definitive: true,
    );
  }
  if (normalizedMessage.contains('item cannot be equipped') ||
      normalizedMessage.contains('configuration invalid')) {
    return const ShopCloudEquipException(
      code: ShopCosmeticsOperationFailureCode.itemConfigurationInvalid,
      message: 'Item configuration is invalid.',
      definitive: true,
    );
  }
  if (normalizedMessage.contains('user_id is required') ||
      normalizedMessage.contains('authenticated user does not match')) {
    return const ShopCloudEquipException(
      code: ShopCosmeticsOperationFailureCode.authRequired,
      message: 'Authentication is required.',
      definitive: true,
    );
  }
  if (normalizedMessage.contains('timeout')) {
    return const ShopCloudEquipException(
      code: ShopCosmeticsOperationFailureCode.timeout,
      message: 'Shop cosmetic equip timed out.',
      retryable: true,
    );
  }
  if (normalizedMessage.contains('network') ||
      normalizedMessage.contains('socket') ||
      normalizedMessage.contains('connection')) {
    return const ShopCloudEquipException(
      code: ShopCosmeticsOperationFailureCode.networkUnavailable,
      message: 'Network unavailable while equipping cosmetic.',
      retryable: true,
    );
  }

  if (kDebugMode) {
    debugPrint(
      '[shop_cloud_equip] unmapped PostgrestException '
      '(${error.code}): ${error.message}',
    );
  }

  return ShopCloudEquipException(
    code: ShopCosmeticsOperationFailureCode.unknown,
    message: error.message,
    cause: error,
  );
}
