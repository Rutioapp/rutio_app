import '../data/cloud/shop_cloud_purchase_dtos.dart';
import 'models/pending_shop_purchase.dart';
import 'shop_purchase_failure.dart';

enum ShopPurchaseStatus {
  success,
  pendingResolution,
  failure,
}

class ShopPurchaseResult {
  const ShopPurchaseResult._({
    required this.status,
    required this.itemId,
    required this.requestId,
    required this.failure,
    required this.remoteResult,
    required this.pendingOperation,
    required this.refreshFailed,
  });

  factory ShopPurchaseResult.success({
    required String itemId,
    required String requestId,
    required RemoteShopPurchaseResultDto remoteResult,
    bool refreshFailed = false,
  }) {
    return ShopPurchaseResult._(
      status: ShopPurchaseStatus.success,
      itemId: itemId,
      requestId: requestId,
      failure: null,
      remoteResult: remoteResult,
      pendingOperation: null,
      refreshFailed: refreshFailed,
    );
  }

  factory ShopPurchaseResult.pendingResolution({
    required String itemId,
    required String requestId,
    required ShopPurchaseFailure failure,
    PendingShopPurchase? pendingOperation,
  }) {
    return ShopPurchaseResult._(
      status: ShopPurchaseStatus.pendingResolution,
      itemId: itemId,
      requestId: requestId,
      failure: failure,
      remoteResult: null,
      pendingOperation: pendingOperation,
      refreshFailed: true,
    );
  }

  factory ShopPurchaseResult.failure({
    required String itemId,
    required String requestId,
    required ShopPurchaseFailure failure,
  }) {
    return ShopPurchaseResult._(
      status: ShopPurchaseStatus.failure,
      itemId: itemId,
      requestId: requestId,
      failure: failure,
      remoteResult: null,
      pendingOperation: null,
      refreshFailed: false,
    );
  }

  final ShopPurchaseStatus status;
  final String itemId;
  final String requestId;
  final ShopPurchaseFailure? failure;
  final RemoteShopPurchaseResultDto? remoteResult;
  final PendingShopPurchase? pendingOperation;
  final bool refreshFailed;

  bool get isSuccess => status == ShopPurchaseStatus.success;

  bool get isPending => status == ShopPurchaseStatus.pendingResolution;
}
