import 'models/habit_reward_transaction.dart';

abstract interface class HabitRewardTransactionRepository {
  Future<HabitRewardTransaction?> findByCompletion({
    required String userScope,
    required String habitId,
    required String localDateKey,
  });

  Future<void> saveTransaction(
    String userScope,
    HabitRewardTransaction transaction,
  );

  Future<List<HabitRewardTransaction>> loadTransactions(
    String userScope,
  );
}
