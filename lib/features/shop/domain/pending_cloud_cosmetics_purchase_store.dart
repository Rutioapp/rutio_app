import 'models/pending_cloud_cosmetics_purchase.dart';

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
