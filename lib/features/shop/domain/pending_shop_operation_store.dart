import 'models/pending_shop_purchase.dart';

abstract class PendingShopOperationStore {
  Future<List<PendingShopPurchase>> loadPendingPurchases(String userId);

  Future<void> savePendingPurchases(
    String userId,
    List<PendingShopPurchase> purchases,
  );

  Future<void> clearPendingPurchases(String userId);
}
