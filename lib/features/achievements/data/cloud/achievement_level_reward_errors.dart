import 'package:flutter/foundation.dart';

enum AchievementLevelRewardFailureCode {
  featureDisabled,
  unauthenticated,
  sessionChanged,
  walletMissing,
  achievementMissing,
  levelMissing,
  invalidResponse,
  requestConflict,
  timeout,
  networkUnavailable,
  negativeBalance,
  unknown,
}

@immutable
class AchievementLevelRewardFailure {
  const AchievementLevelRewardFailure({
    required this.code,
    required this.message,
    this.cause,
    this.definitive = false,
    this.retryable = false,
  });

  final AchievementLevelRewardFailureCode code;
  final String message;
  final Object? cause;
  final bool definitive;
  final bool retryable;
}

@immutable
class AchievementLevelRewardResult<T> {
  const AchievementLevelRewardResult.success({required this.data})
      : failure = null;

  const AchievementLevelRewardResult.failure({required this.failure})
      : data = null;

  final T? data;
  final AchievementLevelRewardFailure? failure;

  bool get isSuccess => failure == null;
}
