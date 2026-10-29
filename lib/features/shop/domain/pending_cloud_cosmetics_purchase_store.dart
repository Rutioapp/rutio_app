import 'models/pending_cloud_cosmetics_purchase.dart';
import '../../../core/storage/pending_queue_storage.dart';

abstract interface class PendingCloudCosmeticsPurchaseStore {
  Future<List<PendingCloudCosmeticsPurchase>> loadPendingPurchases(
    String userId,
  );

  Future<void> savePendingPurchases(
    String userId,
    List<PendingCloudCosmeticsPurchase> purchases,
  );

  Future<void> clearPendingPurchases(String userId);
}

abstract interface class PendingCloudCosmeticsPurchaseStoreWithStatus {
  Future<PendingQueueReadResult<PendingCloudCosmeticsPurchase>>
      loadPendingPurchasesWithStatus(String userId);
  Future<bool> savePendingPurchasesConfirmed(
    String userId,
    List<PendingCloudCosmeticsPurchase> purchases,
  );
}

extension PendingCloudCosmeticsPurchaseStoreStatusAccess
    on PendingCloudCosmeticsPurchaseStore {
  Future<PendingQueueReadResult<PendingCloudCosmeticsPurchase>>
      loadPendingPurchasesWithStatus(String userId) {
    final store = this;
    if (store is PendingCloudCosmeticsPurchaseStoreWithStatus) {
      return (store as PendingCloudCosmeticsPurchaseStoreWithStatus)
          .loadPendingPurchasesWithStatus(userId);
    }
    return loadPendingPurchases(userId).then(
      (values) => PendingQueueReadResult<PendingCloudCosmeticsPurchase>(
        status: PendingQueueReadStatus.valid,
        values: values,
      ),
    );
  }

  Future<bool> savePendingPurchasesConfirmed(
    String userId,
    List<PendingCloudCosmeticsPurchase> purchases,
  ) {
    final store = this;
    if (store is PendingCloudCosmeticsPurchaseStoreWithStatus) {
      return (store as PendingCloudCosmeticsPurchaseStoreWithStatus)
          .savePendingPurchasesConfirmed(userId, purchases);
    }
    return savePendingPurchases(userId, purchases)
        .then((_) => true)
        .catchError((_) => false);
  }
}
