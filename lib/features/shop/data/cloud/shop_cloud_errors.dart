import 'package:flutter/foundation.dart';

enum ShopCloudErrorCode {
  featureDisabled,
  unauthenticated,
  sessionChanged,
  networkUnavailable,
  timeout,
  malformedResponse,
  invalidRemoteItem,
  walletMissing,
  unknown,
}

enum ShopCloudWarningCode {
  invalidRemoteItem,
  remoteUnknownCatalogId,
  localCatalogMissingRemoteId,
  priceMismatch,
  configMismatch,
  walletMissing,
  malformedResponse,
  sessionChanged,
  unauthenticated,
  unknown,
}

@immutable
class ShopCloudReadError {
  const ShopCloudReadError({
    required this.code,
    required this.message,
    this.cause,
  });

  final ShopCloudErrorCode code;
  final String message;
  final Object? cause;
}

@immutable
class ShopCloudWarning {
  const ShopCloudWarning({
    required this.code,
    required this.message,
    this.itemId,
    this.details = const <String, Object?>{},
  });

  final ShopCloudWarningCode code;
  final String message;
  final String? itemId;
  final Map<String, Object?> details;
}

@immutable
class ShopCloudReadResult<T> {
  const ShopCloudReadResult.success({
    required this.data,
    this.warnings = const <ShopCloudWarning>[],
  }) : error = null;

  const ShopCloudReadResult.failure({
    required this.error,
    this.warnings = const <ShopCloudWarning>[],
  }) : data = null;

  final T? data;
  final ShopCloudReadError? error;
  final List<ShopCloudWarning> warnings;

  bool get isSuccess => error == null;
}

class ShopCloudReadException implements Exception {
  const ShopCloudReadException({
    required this.code,
    required this.message,
    this.cause,
  });

  final ShopCloudErrorCode code;
  final String message;
  final Object? cause;

  @override
  String toString() => 'ShopCloudReadException($code, $message)';
}

void shopCloudDebugLog(String message) {
  if (!kDebugMode) return;
  debugPrint('[shop_cloud_read] $message');
}
