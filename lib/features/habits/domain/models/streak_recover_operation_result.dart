import 'recoverable_streak_break.dart';

enum StreakRecoverOperationStatus {
  success,
  noInventory,
  noRecoverableBreak,
  recoveryExpired,
  alreadyRecovered,
  habitNotFound,
  persistenceFailure,
  operationAlreadyProcessed,
}

class StreakRecoverOperationResult {
  const StreakRecoverOperationResult({
    required this.status,
    this.recoveredBreak,
    this.errorMessage,
  });

  final StreakRecoverOperationStatus status;
  final RecoverableStreakBreak? recoveredBreak;
  final String? errorMessage;

  bool get isSuccess => status == StreakRecoverOperationStatus.success;
}
