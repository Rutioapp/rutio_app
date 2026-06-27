import 'package:rutio/features/shop/domain/shop_state.dart';

enum ShopOperationStatus {
  success,
  insufficientCoins,
  alreadyOwned,
  itemNotOwned,
  invalidItemType,
  invalidQuantity,
  backpackItemNotFound,
}

class ShopOperationResult {
  const ShopOperationResult({
    required this.status,
    required this.state,
    required this.walletCoins,
    this.itemId,
  });

  final ShopOperationStatus status;
  final ShopState state;
  final int walletCoins;
  final String? itemId;

  bool get isSuccess => status == ShopOperationStatus.success;

  ShopOperationResult copyWith({
    ShopOperationStatus? status,
    ShopState? state,
    int? walletCoins,
    Object? itemId = _resultUnset,
  }) {
    return ShopOperationResult(
      status: status ?? this.status,
      state: state ?? this.state,
      walletCoins: walletCoins ?? this.walletCoins,
      itemId: identical(itemId, _resultUnset) ? this.itemId : itemId as String?,
    );
  }
}

const Object _resultUnset = Object();
