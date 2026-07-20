import 'package:flutter/foundation.dart';

enum WalletFailureCode {
  featureDisabled,
  unauthenticated,
  sessionChanged,
  walletMissing,
  invalidResponse,
  networkUnavailable,
  timeout,
  unknown,
}

@immutable
class WalletFailure {
  const WalletFailure({
    required this.code,
    required this.message,
    this.cause,
  });

  final WalletFailureCode code;
  final String message;
  final Object? cause;
}

@immutable
class WalletReadResult<T> {
  const WalletReadResult.success({required this.data}) : failure = null;

  const WalletReadResult.failure({required this.failure}) : data = null;

  final T? data;
  final WalletFailure? failure;

  bool get isSuccess => failure == null;
}
