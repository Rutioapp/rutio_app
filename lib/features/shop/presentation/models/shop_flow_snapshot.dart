import 'package:rutio/features/shop/data/shop_catalog.dart';
import 'package:rutio/features/shop/domain/models/backpack_item.dart';
import 'package:rutio/features/shop/domain/models/equipped_cosmetics.dart';
import 'package:rutio/features/shop/domain/models/owned_shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_collection.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/domain/shop_state.dart';
import 'package:rutio/features/shop/presentation/models/backpack_item_view_model.dart';

class ShopFlowSnapshot {
  const ShopFlowSnapshot({
    required this.walletCoins,
    required this.shopState,
    required this.collections,
    required this.catalogItems,
  });

  final int walletCoins;
  final ShopState shopState;
  final List<ShopCollection> collections;
  final List<ShopItem> catalogItems;

  factory ShopFlowSnapshot.fromStore({
    required int walletCoins,
    required ShopState shopState,
  }) {
    return ShopFlowSnapshot(
      walletCoins: walletCoins,
      shopState: shopState,
      collections: ShopCatalog.allCollections,
      catalogItems: ShopCatalog.allItems,
    );
  }

  List<OwnedShopItem> get inventory => shopState.inventory;

  List<BackpackItem> get backpackItems => shopState.backpackItems;

  EquippedCosmetics get equippedCosmetics => shopState.equippedCosmetics;

  Set<String> get ownedItemIds =>
      inventory.map((OwnedShopItem item) => item.itemId).toSet();

  List<ShopItem> get ownedCosmeticItems {
    return inventory
        .map((OwnedShopItem entry) => ShopCatalog.getItemById(entry.itemId))
        .whereType<ShopItem>()
        .where((ShopItem item) => item.category == ShopItemCategory.cosmetic)
        .toList(growable: false);
  }

  List<BackpackItemViewModel> get backpackViewModels {
    return backpackItems.map((BackpackItem item) {
      final ShopItem? catalogItem = ShopCatalog.getItemById(item.itemId);
      return BackpackItemViewModel(
        itemId: item.itemId,
        title: catalogItem?.title ?? item.itemId,
        description: catalogItem?.description ?? 'Utilidad disponible en la mochila.',
        quantity: item.quantity,
        rarity: catalogItem?.rarity ?? ShopItemRarity.common,
        type: catalogItem?.type ?? ShopItemType.mysteryBox,
        collectionName: catalogItem?.collectionId,
      );
    }).toList(growable: false);
  }

  List<ShopItem> get cosmeticCatalogItems {
    return catalogItems
        .where((ShopItem item) => item.category == ShopItemCategory.cosmetic)
        .toList(growable: false);
  }

  List<ShopItem> get utilityCatalogItems {
    return catalogItems
        .where((ShopItem item) => item.category == ShopItemCategory.utility)
        .toList(growable: false);
  }

  ShopCollection? collectionById(String collectionId) {
    for (final ShopCollection collection in collections) {
      if (collection.id == collectionId) {
        return collection;
      }
    }
    return null;
  }
}
