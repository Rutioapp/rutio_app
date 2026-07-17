import 'package:rutio/features/shop/data/shop_assets_catalog.dart';
import 'package:rutio/features/shop/data/shop_catalog.dart';
import 'package:rutio/features/shop/domain/models/backpack_item.dart';
import 'package:rutio/features/shop/domain/models/active_utility_effect.dart';
import 'package:rutio/features/shop/domain/models/mystery_box_opening_transaction.dart';
import 'package:rutio/features/shop/domain/models/equipped_cosmetics.dart';
import 'package:rutio/features/shop/domain/models/owned_shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_asset.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_state.dart';
import 'package:rutio/features/shop/domain/models/shop_collection.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/domain/shop_state.dart';
import 'package:rutio/features/shop/presentation/models/backpack_item_view_model.dart';

class ShopFlowSnapshot {
  const ShopFlowSnapshot({
    required this.walletCoins,
    required this.shopState,
    required this.cosmeticsState,
    required this.activeUtilityEffects,
    required this.pendingMysteryBoxOpenings,
    required this.collections,
    required this.catalogItems,
  });

  final int walletCoins;
  final ShopState shopState;
  final ShopCosmeticsState cosmeticsState;
  final List<ActiveUtilityEffect> activeUtilityEffects;
  final List<MysteryBoxOpeningTransaction> pendingMysteryBoxOpenings;
  final List<ShopCollection> collections;
  final List<ShopItem> catalogItems;

  factory ShopFlowSnapshot.fromStore({
    required int walletCoins,
    required ShopState shopState,
    required ShopCosmeticsState cosmeticsState,
    required List<ActiveUtilityEffect> activeUtilityEffects,
    required List<MysteryBoxOpeningTransaction> pendingMysteryBoxOpenings,
  }) {
    return ShopFlowSnapshot(
      walletCoins: walletCoins,
      shopState: shopState,
      cosmeticsState: cosmeticsState,
      activeUtilityEffects: activeUtilityEffects,
      pendingMysteryBoxOpenings: pendingMysteryBoxOpenings,
      collections: ShopCatalog.allCollections,
      catalogItems: ShopCatalog.allItems,
    );
  }

  List<OwnedShopItem> get inventory => shopState.inventory;

  List<BackpackItem> get backpackItems => shopState.backpackItems;

  EquippedCosmetics get equippedCosmetics => EquippedCosmetics(
        backgroundItemId: cosmeticsState.equippedWallpaperId,
        habitCardItemId: cosmeticsState.equippedHabitCardSkinId,
        userCardItemId: cosmeticsState.equippedUserCardSkinId,
      );

  Set<String> get ownedItemIds =>
      inventory.map((OwnedShopItem item) => item.itemId).toSet();

  List<ShopItem> get ownedCosmeticItems {
    final ownedCosmeticIds = ShopAssetsCatalog.allAssets
        .where(
          (ShopAsset asset) => cosmeticsState.isAssetOwned(
            asset.id,
            bundles: ShopAssetsCatalog.allBundles,
          ),
        )
        .map((ShopAsset asset) => asset.id)
        .toList(growable: false);

    return ownedCosmeticIds
        .map(ShopCatalog.getItemById)
        .whereType<ShopItem>()
        .where((ShopItem item) => item.category == ShopItemCategory.cosmetic)
        .toList(growable: false);
  }

  List<BackpackItemViewModel> get backpackViewModels {
    final hasPendingMysteryBoxOpening = pendingMysteryBoxOpenings
        .any((transaction) => transaction.isPendingPresentation);
    return backpackItems.map((BackpackItem item) {
      final ShopItem? catalogItem = ShopCatalog.getItemById(item.itemId);
      final activeEffect = _activeEffectForItem(item.itemId);
      return BackpackItemViewModel(
        itemId: item.itemId,
        title: catalogItem?.title ?? item.itemId,
        description:
            catalogItem?.description ?? 'Utilidad disponible en la mochila.',
        quantity: item.quantity,
        rarity: catalogItem?.rarity ?? ShopItemRarity.common,
        type: catalogItem?.type ?? ShopItemType.mysteryBox,
        collectionName: catalogItem?.collectionId,
        activeEffect: activeEffect,
        hasMysteryBoxPendingRecovery:
            catalogItem?.type == ShopItemType.mysteryBox &&
                hasPendingMysteryBoxOpening,
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

  ActiveUtilityEffect? _activeEffectForItem(String utilityId) {
    final catalogItem = ShopCatalog.getItemById(utilityId);
    if (catalogItem == null) return null;
    final effectType = switch (catalogItem.type) {
      ShopItemType.xpBoost => ActiveUtilityEffectType.xpBoost,
      ShopItemType.coinBoost => ActiveUtilityEffectType.coinBoost,
      ShopItemType.streakShield => ActiveUtilityEffectType.streakShield,
      _ => null,
    };
    if (effectType == null) return null;

    final matches = activeUtilityEffects
        .where((effect) => effect.type == effectType)
        .toList(growable: false)
      ..sort((a, b) {
        final byActivated = b.activatedAtMillis.compareTo(a.activatedAtMillis);
        if (byActivated != 0) return byActivated;
        return b.id.compareTo(a.id);
      });
    if (matches.isEmpty) return null;
    return matches.first;
  }
}
