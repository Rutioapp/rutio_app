import 'package:flutter/foundation.dart';

enum HabitCurrencyRewardFailureCode {
  featureDisabled,
  unauthenticated,
  sessionChanged,
  walletMissing,
  habitMissing,
  invalidResponse,
  requestConflict,
  timeout,
  networkUnavailable,
  negativeBalance,
  unknown,
}

@immutable
class HabitCurrencyRewardFailure {
  const HabitCurrencyRewardFailure({
    required this.code,
    required this.message,
    this.cause,
    this.definitive = false,
    this.retryable = false,
  });

  final HabitCurrencyRewardFailureCode code;
  final String message;
  final Object? cause;
  final bool definitive;
  final bool retryable;
}

@immutable
class HabitCurrencyRewardResult<T> {
  const HabitCurrencyRewardResult.success({required this.data})
      : failure = null;

  const HabitCurrencyRewardResult.failure({required this.failure})
      : data = null;

  final T? data;
  final HabitCurrencyRewardFailure? failure;

  bool get isSuccess => failure == null;
}
