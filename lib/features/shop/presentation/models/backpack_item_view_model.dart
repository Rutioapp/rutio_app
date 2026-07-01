import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';

class BackpackItemViewModel {
  const BackpackItemViewModel({
    required this.itemId,
    required this.title,
    required this.description,
    required this.quantity,
    required this.rarity,
    required this.type,
    this.collectionName,
  });

  final String itemId;
  final String title;
  final String description;
  final int quantity;
  final ShopItemRarity rarity;
  final ShopItemType type;
  final String? collectionName;

  bool get hasQuantity => quantity > 0;

  factory BackpackItemViewModel.fromItem(
    ShopItem item, {
    required int quantity,
    String? collectionName,
  }) {
    return BackpackItemViewModel(
      itemId: item.id,
      title: item.title,
      description: item.description,
      quantity: quantity,
      rarity: item.rarity,
      type: item.type,
      collectionName: collectionName ?? item.collectionId,
    );
  }
}
