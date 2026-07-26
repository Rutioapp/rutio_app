import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/data/cloud/shop_cosmetics_catalog_resolver.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_dtos.dart';
import 'package:rutio/features/shop/data/shop_assets_catalog.dart';
import 'package:rutio/features/shop/domain/models/shop_asset_enums.dart';

void main() {
  group('ShopCosmeticsCatalogResolver', () {
    test('hydrates assets with remote price rarity and order', () {
      final resolver = ShopCosmeticsCatalogResolver();

      final catalog = resolver.resolve(
        localAssets: ShopAssetsCatalog.allAssets,
        localBundles: ShopAssetsCatalog.allBundles,
        remoteItems: <RemoteShopItemDto>[
          _cosmetic(
            'wallpaper_mist_blue',
            category: 'screen_background',
            rarity: 'epic',
            priceCoins: 777,
            sortOrder: 91,
          ),
        ],
        remoteBundles: const <RemoteShopBundleDto>[],
      );

      expect(catalog.assets, hasLength(1));
      expect(catalog.assets.single.id, 'wallpaper_mist_blue');
      expect(catalog.assets.single.priceAmber, 777);
      expect(catalog.assets.single.rarity, ShopAssetRarity.epic);
      expect(catalog.assets.single.sortOrder, 91);
    });

    test('ignores remote utilities and items without local metadata', () {
      final resolver = ShopCosmeticsCatalogResolver();

      final catalog = resolver.resolve(
        localAssets: ShopAssetsCatalog.allAssets,
        localBundles: ShopAssetsCatalog.allBundles,
        remoteItems: <RemoteShopItemDto>[
          _utility('utility_xp_boost_1d'),
          _cosmetic(
            'remote_only_asset',
            category: 'screen_background',
            rarity: 'common',
            priceCoins: 50,
            sortOrder: 5,
          ),
        ],
        remoteBundles: const <RemoteShopBundleDto>[],
      );

      expect(catalog.assets, isEmpty);
    });

    test('hydrates bundles with remote price and composition', () {
      final resolver = ShopCosmeticsCatalogResolver();

      final catalog = resolver.resolve(
        localAssets: ShopAssetsCatalog.allAssets,
        localBundles: ShopAssetsCatalog.allBundles,
        remoteItems: const <RemoteShopItemDto>[],
        remoteBundles: <RemoteShopBundleDto>[
          _bundle(
            'pack_beige_rutio',
            familyId: 'pack_beige_remote',
            rarity: 'epic',
            priceCoins: 300,
            originalPriceCoins: 330,
            sortOrder: 44,
          ),
        ],
        remoteBundleItems: <RemoteShopBundleItemDto>[
          _bundleItem(
            'pack_beige_rutio',
            'wallpaper_rutio_beige',
            'screen_background',
          ),
          _bundleItem(
            'pack_beige_rutio',
            'habit_card_warm_beige',
            'habit_card_background',
          ),
          _bundleItem(
            'pack_beige_rutio',
            'user_card_warm_beige',
            'user_card_background',
          ),
        ],
      );

      expect(catalog.bundles, hasLength(1));
      final bundle = catalog.bundles.single;
      expect(bundle.id, 'pack_beige_rutio');
      expect(bundle.familyId, 'pack_beige_remote');
      expect(bundle.priceAmber, 300);
      expect(bundle.originalPriceAmber, 330);
      expect(bundle.discountPercentage, 9);
      expect(bundle.sortOrder, 44);
      expect(bundle.wallpaperItemId, 'wallpaper_rutio_beige');
      expect(bundle.habitCardItemId, 'habit_card_warm_beige');
      expect(bundle.userCardItemId, 'user_card_warm_beige');
    });
  });
}

RemoteShopItemDto _cosmetic(
  String id, {
  required String category,
  required String rarity,
  required int priceCoins,
  required int sortOrder,
}) {
  return RemoteShopItemDto.fromJson(<String, dynamic>{
    'id': id,
    'category': category,
    'subtype': null,
    'rarity': rarity,
    'priceCoins': priceCoins,
    'isConsumable': false,
    'isStackable': false,
    'maxQuantity': 1,
    'equipSlot': category,
    'assetKey': id,
    'localizationKey': id,
    'isActive': true,
    'sortOrder': sortOrder,
    'catalogVersion': 1,
    'createdAt': '2026-07-25T00:00:00Z',
    'updatedAt': '2026-07-25T00:00:00Z',
  });
}

RemoteShopItemDto _utility(String id) {
  return RemoteShopItemDto.fromJson(<String, dynamic>{
    'id': id,
    'category': 'utility',
    'subtype': 'xpBoost',
    'rarity': null,
    'priceCoins': 75,
    'isConsumable': true,
    'isStackable': true,
    'maxQuantity': null,
    'equipSlot': null,
    'assetKey': 'assets/shop/utilities/$id.png',
    'localizationKey': id,
    'isActive': true,
    'sortOrder': 1,
    'catalogVersion': 1,
    'createdAt': '2026-07-25T00:00:00Z',
    'updatedAt': '2026-07-25T00:00:00Z',
  });
}

RemoteShopBundleDto _bundle(
  String id, {
  required String familyId,
  required String rarity,
  required int priceCoins,
  required int originalPriceCoins,
  required int sortOrder,
}) {
  return RemoteShopBundleDto.fromJson(<String, dynamic>{
    'id': id,
    'familyId': familyId,
    'rarity': rarity,
    'priceCoins': priceCoins,
    'originalPriceCoins': originalPriceCoins,
    'isActive': true,
    'sortOrder': sortOrder,
    'catalogVersion': 1,
    'createdAt': '2026-07-25T00:00:00Z',
    'updatedAt': '2026-07-25T00:00:00Z',
  });
}

RemoteShopBundleItemDto _bundleItem(
  String bundleId,
  String itemId,
  String slot,
) {
  return RemoteShopBundleItemDto.fromJson(<String, dynamic>{
    'bundleId': bundleId,
    'itemId': itemId,
    'slot': slot,
  });
}
