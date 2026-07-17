import 'active_streak_shield.dart';

enum StreakShieldOperationStatus {
  success,
  noInventory,
  habitNotEligible,
  shieldAlreadyActive,
  habitNotFound,
  persistenceFailure,
  operationAlreadyProcessed,
}

extension StreakShieldOperationStatusX on StreakShieldOperationStatus {
  bool get isSuccess => this == StreakShieldOperationStatus.success;
}

class StreakShieldOperationResult {
  const StreakShieldOperationResult({
    required this.status,
    this.shield,
    this.errorMessage,
  });

  final StreakShieldOperationStatus status;
  final ActiveStreakShield? shield;
  final String? errorMessage;

  bool get isSuccess => status == StreakShieldOperationStatus.success;
}
