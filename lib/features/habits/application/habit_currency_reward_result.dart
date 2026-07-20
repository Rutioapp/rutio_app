import '../data/cloud/habit_currency_reward_errors.dart';
import '../data/cloud/habit_currency_reward_ledger.dart';
import '../domain/models/pending_currency_operation.dart';
import '../domain/models/habit_reward_transaction.dart';

enum HabitCurrencyRewardState {
  success,
  pending,
  skipped,
  failure,
}

class HabitCurrencyRewardOperationResult {
  const HabitCurrencyRewardOperationResult({
    required this.state,
    this.ledger,
    this.pendingOperation,
    this.failure,
    this.transaction,
  });

  final HabitCurrencyRewardState state;
  final HabitCurrencyRewardLedgerEntry? ledger;
  final PendingCurrencyOperation? pendingOperation;
  final HabitCurrencyRewardFailure? failure;
  final HabitRewardTransaction? transaction;

  bool get isSuccess => state == HabitCurrencyRewardState.success;
  bool get isPending => state == HabitCurrencyRewardState.pending;
  bool get isSkipped => state == HabitCurrencyRewardState.skipped;
}
