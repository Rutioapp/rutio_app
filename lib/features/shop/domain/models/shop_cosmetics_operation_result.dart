import 'package:rutio/features/shop/domain/models/shop_cosmetics_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_state.dart';

class ShopCosmeticsOperationResult {
  const ShopCosmeticsOperationResult({
    required this.status,
    required this.state,
    required this.walletCoins,
    this.assetId,
    this.bundleId,
  });

  final ShopCosmeticsOperationStatus status;
  final ShopCosmeticsState state;
  final int walletCoins;
  final String? assetId;
  final String? bundleId;

  bool get isSuccess => status == ShopCosmeticsOperationStatus.success;
}
