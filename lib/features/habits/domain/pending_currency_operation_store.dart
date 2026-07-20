import 'models/pending_currency_operation.dart';

abstract interface class PendingCurrencyOperationStore {
  Future<List<PendingCurrencyOperation>> loadPendingOperations(String userId);

  Future<void> savePendingOperations(
    String userId,
    List<PendingCurrencyOperation> operations,
  );

  Future<void> clearPendingOperations(String userId);
}
