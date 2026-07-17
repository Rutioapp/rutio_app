import 'package:rutio/features/shop/domain/models/mystery_box_opening_transaction.dart';
import 'package:rutio/features/shop/domain/shop_state.dart';

enum MysteryBoxOperationStatus {
  success,
  invalidTransactionId,
  unavailableState,
  noBoxes,
  invalidConfiguration,
  persistenceError,
  duplicateTransaction,
  transactionNotFound,
}

class MysteryBoxOperationResult {
  const MysteryBoxOperationResult({
    required this.status,
    this.transaction,
    this.shopState,
    this.walletCoins,
    this.errorMessage,
  });

  final MysteryBoxOperationStatus status;
  final MysteryBoxOpeningTransaction? transaction;
  final ShopState? shopState;
  final int? walletCoins;
  final String? errorMessage;

  bool get isSuccess => status == MysteryBoxOperationStatus.success;
}
