import 'package:flutter/foundation.dart';

enum MysteryBoxOpeningCloudErrorCode {
  featureDisabled,
  unauthenticated,
  sessionChanged,
  noInventory,
  requestConflict,
  walletMissing,
  malformedResponse,
  networkUnavailable,
  timeout,
  unknown,
}

@immutable
class MysteryBoxOpeningCloudException implements Exception {
  const MysteryBoxOpeningCloudException({
    required this.code,
    required this.message,
    this.cause,
    this.retryable = false,
    this.definitive = false,
  });

  final MysteryBoxOpeningCloudErrorCode code;
  final String message;
  final Object? cause;
  final bool retryable;
  final bool definitive;

  bool get keepPending => !definitive;

  @override
  String toString() =>
      'MysteryBoxOpeningCloudException($code, $message)';
}
