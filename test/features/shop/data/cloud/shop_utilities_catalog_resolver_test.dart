import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_dtos.dart';
import 'package:rutio/features/shop/data/cloud/shop_utilities_catalog_resolver.dart';
import 'package:rutio/features/shop/data/shop_catalog.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';

void main() {
  group('ShopUtilitiesCatalogResolver', () {
    test(
      'accepts utility rows with null remote rarity and uses local rarity',
      () {
        final catalog = const ShopUtilitiesCatalogResolver().resolve(
          localItems: ShopCatalog.allItems,
          remoteItems: <RemoteShopItemDto>[
            _utility(
              'utility_xp_boost_1d',
              priceCoins: 777,
              sortOrder: 20,
            ),
            _utility(
              'utility_streak_shield_1',
              priceCoins: 333,
              sortOrder: 10,
            ),
          ],
        );

        expect(
          catalog.items.map((item) => item.id),
          <String>['utility_streak_shield_1', 'utility_xp_boost_1d'],
        );

        final xpBoost = catalog.items.singleWhere(
          (item) => item.id == 'utility_xp_boost_1d',
        );
        final streakShield = catalog.items.singleWhere(
          (item) => item.id == 'utility_streak_shield_1',
        );

        expect(xpBoost.priceCoins, 777);
        expect(
          xpBoost.rarity,
          ShopCatalog.getItemById('utility_xp_boost_1d')!.rarity,
        );
        expect(xpBoost.category, ShopItemCategory.utility);
        expect(xpBoost.title, 'XP Boost 1 Day');
        expect(xpBoost.type, ShopItemType.xpBoost);
        expect(xpBoost.assetRef, 'assets/shop/utilities/boost_xp.png');

        expect(streakShield.priceCoins, 333);
        expect(
          streakShield.rarity,
          ShopCatalog.getItemById('utility_streak_shield_1')!.rarity,
        );
        expect(streakShield.category, ShopItemCategory.utility);
        expect(streakShield.title, 'Streak Shield');
        expect(streakShield.type, ShopItemType.streakShield);
        expect(
          streakShield.assetRef,
          'assets/shop/utilities/streak_shield.png',
        );
      },
    );

    test('keeps common and rare utility rarities from local catalog', () {
      final catalog = const ShopUtilitiesCatalogResolver().resolve(
        localItems: ShopCatalog.allItems,
        remoteItems: <RemoteShopItemDto>[
          _utility(
            'utility_coin_boost_1d',
            rarity: 'epic',
            priceCoins: 888,
            sortOrder: 10,
          ),
          _utility(
            'utility_streak_shield_1',
            rarity: 'legendary',
            priceCoins: 999,
            sortOrder: 20,
          ),
        ],
      );

      final coinBoost = catalog.items.singleWhere(
        (item) => item.id == 'utility_coin_boost_1d',
      );
      final streakShield = catalog.items.singleWhere(
        (item) => item.id == 'utility_streak_shield_1',
      );

      expect(coinBoost.rarity, ShopItemRarity.common);
      expect(streakShield.rarity, ShopItemRarity.rare);
      expect(coinBoost.priceCoins, 888);
      expect(streakShield.priceCoins, 999);
    });

    test('filters inactive and unknown remote utilities', () {
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
          _cosmetic('wallpaper_mist_blue', rarity: null),
        ],
      );
      expect(cosmetics.items, isEmpty);
    });
  });
}

RemoteShopItemDto _utility(
  String id, {
  String? rarity,
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

RemoteShopItemDto _cosmetic(
  String id, {
  String? rarity = 'common',
}) {
  return RemoteShopItemDto.fromJson(<String, dynamic>{
    'id': id,
    'category': 'screen_background',
    'subtype': null,
    'rarity': rarity,
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
