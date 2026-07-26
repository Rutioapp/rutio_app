import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_dtos.dart';
import 'package:rutio/features/shop/data/cloud/shop_utilities_catalog_resolver.dart';
import 'package:rutio/features/shop/data/shop_catalog.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';

void main() {
  group('ShopUtilitiesCatalogResolver', () {
    test('hydrates utilities with remote price rarity and order', () {
      final catalog = const ShopUtilitiesCatalogResolver().resolve(
        localItems: ShopCatalog.allItems,
        remoteItems: <RemoteShopItemDto>[
          _utility(
            'utility_xp_boost_1d',
            rarity: 'common',
            priceCoins: 777,
            sortOrder: 20,
          ),
          _utility(
            'utility_coin_boost_1d',
            rarity: 'epic',
            priceCoins: 888,
            sortOrder: 10,
          ),
        ],
      );

      expect(
        catalog.items.map((item) => item.id),
        <String>['utility_coin_boost_1d', 'utility_xp_boost_1d'],
      );
      expect(catalog.items.first.priceCoins, 888);
      expect(catalog.items.first.rarity, ShopItemRarity.epic);
      expect(catalog.items.first.title, 'Coin Boost 1 Day');
      expect(catalog.items.first.type, ShopItemType.coinBoost);
    });

    test('filters inactive local-only and unknown remote utilities', () {
      final catalog = const ShopUtilitiesCatalogResolver().resolve(
        localItems: ShopCatalog.allItems,
        remoteItems: <RemoteShopItemDto>[
          _utility('utility_xp_boost_1d', isActive: false),
          _utility('utility_remote_only'),
          _utility('utility_unknown_supported'),
        ],
      );

      expect(catalog.items, isEmpty);
    });

    test('ignores non-utility remote rows and empty remote catalog', () {
      final resolver = const ShopUtilitiesCatalogResolver();

      final empty = resolver.resolve(
        localItems: ShopCatalog.allItems,
        remoteItems: const <RemoteShopItemDto>[],
      );
      expect(empty.items, isEmpty);

      final cosmetics = resolver.resolve(
        localItems: ShopCatalog.allItems,
        remoteItems: <RemoteShopItemDto>[
          _cosmetic('wallpaper_mist_blue'),
        ],
      );
      expect(cosmetics.items, isEmpty);
    });
  });
}

RemoteShopItemDto _utility(
  String id, {
  String rarity = 'rare',
  int priceCoins = 75,
  int sortOrder = 0,
  bool isActive = true,
}) {
  return RemoteShopItemDto.fromJson(<String, dynamic>{
    'id': id,
    'category': 'utility',
    'subtype': 'xpBoost',
    'rarity': rarity,
    'priceCoins': priceCoins,
    'isConsumable': true,
    'isStackable': true,
    'maxQuantity': null,
    'equipSlot': null,
    'assetKey': 'assets/shop/utilities/$id.png',
    'localizationKey': id,
    'isActive': isActive,
    'sortOrder': sortOrder,
    'catalogVersion': 1,
    'createdAt': '2026-07-25T00:00:00Z',
    'updatedAt': '2026-07-25T00:00:00Z',
  });
}

RemoteShopItemDto _cosmetic(String id) {
  return RemoteShopItemDto.fromJson(<String, dynamic>{
    'id': id,
    'category': 'screen_background',
    'subtype': null,
    'rarity': 'common',
    'priceCoins': 50,
    'isConsumable': false,
    'isStackable': false,
    'maxQuantity': 1,
    'equipSlot': 'screen_background',
    'assetKey': id,
    'localizationKey': id,
    'isActive': true,
    'sortOrder': 0,
    'catalogVersion': 1,
    'createdAt': '2026-07-25T00:00:00Z',
    'updatedAt': '2026-07-25T00:00:00Z',
  });
}
