import 'models/pending_currency_operation.dart';
import '../../../core/storage/pending_queue_storage.dart';

abstract interface class PendingCurrencyOperationStore {
  Future<List<PendingCurrencyOperation>> loadPendingOperations(String userId);

  Future<void> savePendingOperations(
    String userId,
    List<PendingCurrencyOperation> operations,
  );

  Future<void> clearPendingOperations(String userId);
}

abstract interface class PendingCurrencyOperationStoreWithStatus {
  Future<PendingQueueReadResult<PendingCurrencyOperation>>
      loadPendingOperationsWithStatus(String userId);
  Future<bool> savePendingOperationsConfirmed(
    String userId,
    List<PendingCurrencyOperation> operations,
  );
}

extension PendingCurrencyOperationStoreStatusAccess
    on PendingCurrencyOperationStore {
  Future<PendingQueueReadResult<PendingCurrencyOperation>>
      loadPendingOperationsWithStatus(String userId) {
    final store = this;
    if (store is PendingCurrencyOperationStoreWithStatus) {
      return (store as PendingCurrencyOperationStoreWithStatus)
          .loadPendingOperationsWithStatus(userId);
    }
    return loadPendingOperations(userId).then(
      (values) => PendingQueueReadResult<PendingCurrencyOperation>(
        status: PendingQueueReadStatus.valid,
        values: values,
      ),
    );
  }

  Future<bool> savePendingOperationsConfirmed(
    String userId,
    List<PendingCurrencyOperation> operations,
  ) {
    final store = this;
    if (store is PendingCurrencyOperationStoreWithStatus) {
      return (store as PendingCurrencyOperationStoreWithStatus)
          .savePendingOperationsConfirmed(userId, operations);
    }
    return savePendingOperations(userId, operations)
        .then((_) => true)
        .catchError((_) => false);
  }
}
