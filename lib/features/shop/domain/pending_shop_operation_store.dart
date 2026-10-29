import 'models/pending_shop_purchase.dart';
import '../../../core/storage/pending_queue_storage.dart';

abstract class PendingShopOperationStore {
  Future<List<PendingShopPurchase>> loadPendingPurchases(String userId);

  Future<void> savePendingPurchases(
    String userId,
    List<PendingShopPurchase> purchases,
  );

  Future<void> clearPendingPurchases(String userId);
}

abstract interface class PendingShopOperationStoreWithStatus {
  Future<PendingQueueReadResult<PendingShopPurchase>>
      loadPendingPurchasesWithStatus(String userId);
  Future<bool> savePendingPurchasesConfirmed(
    String userId,
    List<PendingShopPurchase> purchases,
  );
}

extension PendingShopOperationStoreStatusAccess on PendingShopOperationStore {
  Future<PendingQueueReadResult<PendingShopPurchase>>
      loadPendingPurchasesWithStatus(String userId) {
    final store = this;
    if (store is PendingShopOperationStoreWithStatus) {
      return (store as PendingShopOperationStoreWithStatus)
          .loadPendingPurchasesWithStatus(userId);
    }
    return loadPendingPurchases(userId).then(
      (values) => PendingQueueReadResult<PendingShopPurchase>(
        status: PendingQueueReadStatus.valid,
        values: values,
      ),
    );
  }

  Future<bool> savePendingPurchasesConfirmed(
    String userId,
    List<PendingShopPurchase> purchases,
  ) {
    final store = this;
    if (store is PendingShopOperationStoreWithStatus) {
      return (store as PendingShopOperationStoreWithStatus)
          .savePendingPurchasesConfirmed(userId, purchases);
    }
    return savePendingPurchases(userId, purchases)
        .then((_) => true)
        .catchError((_) => false);
  }
}
