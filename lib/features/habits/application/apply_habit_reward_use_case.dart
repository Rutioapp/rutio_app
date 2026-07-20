import 'habit_currency_reward_coordinator.dart';
import 'habit_currency_reward_result.dart';

class ApplyHabitRewardUseCase {
  ApplyHabitRewardUseCase({required HabitCurrencyRewardCoordinator coordinator})
      : _coordinator = coordinator;

  final HabitCurrencyRewardCoordinator _coordinator;

  Future<HabitCurrencyRewardOperationResult> call({
    required String habitId,
    required String logicalDateKey,
    String? completionEventId,
    String? requestId,
  }) {
    return _coordinator.applyHabitReward(
      habitId: habitId,
      logicalDateKey: logicalDateKey,
      completionEventId: completionEventId,
      requestId: requestId,
    );
  }
}
