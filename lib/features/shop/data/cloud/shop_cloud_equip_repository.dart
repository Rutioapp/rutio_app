import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'shop_cloud_equip_data_sources.dart';
import 'shop_cloud_equip_dtos.dart';

enum ShopCosmeticsOperationFailureCode {
  requestIdRequired,
  requestConflict,
  itemNotFound,
  itemInactive,
  itemNotOwned,
  itemNotEquippable,
  invalidEquipSlot,
  unauthenticated,
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
    required String slot,
    required String requestId,
  }) async {
    try {
      final response = await _dataSource
          .equipShopCosmetic(itemId: itemId, slot: slot, requestId: requestId)
          .timeout(_timeout);
      return RemoteShopEquipResultDto.fromRpcResponse(
        response,
        requestedItemId: itemId,
        requestedSlot: slot,
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
      code: ShopCosmeticsOperationFailureCode.requestConflict,
      message: 'request_id already used by another user.',
      definitive: true,
    );
  }
  if (normalizedCode == 'ITEM_NOT_FOUND' ||
      normalizedMessage.contains('item not found')) {
    return const ShopCloudEquipException(
      code: ShopCosmeticsOperationFailureCode.itemNotFound,
      message: 'Shop item not found.',
      definitive: true,
    );
  }
  if (normalizedCode == 'ITEM_INACTIVE' ||
      normalizedMessage.contains('item inactive') ||
      normalizedMessage.contains('inactive')) {
    return const ShopCloudEquipException(
      code: ShopCosmeticsOperationFailureCode.itemInactive,
      message: 'Shop item is inactive.',
      definitive: true,
    );
  }
  if (normalizedMessage.contains('item must be owned before equip') ||
      normalizedMessage.contains('item is not owned') ||
      normalizedCode == 'ITEM_NOT_OWNED') {
    return const ShopCloudEquipException(
      code: ShopCosmeticsOperationFailureCode.itemNotOwned,
      message: 'Item must be owned before equip.',
      definitive: true,
    );
  }
  if (normalizedMessage.contains('item cannot be equipped') ||
      normalizedMessage.contains('configuration invalid') ||
      normalizedCode == 'ITEM_NOT_EQUIPPABLE') {
    return const ShopCloudEquipException(
      code: ShopCosmeticsOperationFailureCode.itemNotEquippable,
      message: 'Item configuration is invalid.',
      definitive: true,
    );
  }
  if (normalizedMessage.contains('invalid equip slot') ||
      normalizedMessage.contains('invalid_equip_slot') ||
      normalizedMessage.contains('slot mismatch') ||
      normalizedCode == 'INVALID_EQUIP_SLOT') {
    return const ShopCloudEquipException(
      code: ShopCosmeticsOperationFailureCode.invalidEquipSlot,
      message: 'Invalid equip slot.',
      definitive: true,
    );
  }
  if (normalizedMessage.contains('unauthenticated') ||
      normalizedCode == 'UNAUTHENTICATED' ||
      normalizedMessage.contains('user_id is required') ||
      normalizedMessage.contains('authenticated user does not match')) {
    return const ShopCloudEquipException(
      code: ShopCosmeticsOperationFailureCode.unauthenticated,
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
