import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_dtos.dart';

void main() {
  group('RemoteShopItemDto', () {
    test('parses a valid utility row', () {
      final dto = RemoteShopItemDto.fromJson(<String, dynamic>{
        'id': 'utility_xp_boost_1d',
        'category': 'utility',
        'subtype': 'xpBoost',
        'rarity': null,
        'price_coins': 75,
        'is_consumable': true,
        'is_stackable': true,
        'max_quantity': null,
        'equip_slot': null,
        'asset_key': 'assets/shop/utilities/boost_xp.png',
        'localization_key': 'shopXpBoostTitle',
        'is_active': true,
        'sort_order': 0,
        'catalog_version': 1,
        'created_at': '2026-07-17T00:00:00Z',
        'updated_at': '2026-07-17T00:00:00Z',
      });

      expect(dto.id, 'utility_xp_boost_1d');
      expect(dto.category, RemoteShopItemCategory.utility);
      expect(dto.rarity, isNull);
      expect(dto.equipSlot, isNull);
      expect(dto.priceCoins, 75);
      expect(dto.isConsumable, isTrue);
      expect(dto.isStackable, isTrue);
    });

    test('preserves nullable fields and unknown category values safely', () {
      final dto = RemoteShopItemDto.fromJson(<String, dynamic>{
        'id': 'mystery_remote_item',
        'category': 'future_category',
        'subtype': 'futureSubtype',
        'rarity': 'future_rarity',
        'priceCoins': 10,
        'isConsumable': false,
        'isStackable': false,
        'maxQuantity': 1,
        'equipSlot': 'future_slot',
        'assetKey': 'assets/shop/placeholder.png',
        'localizationKey': null,
        'isActive': false,
        'sortOrder': 3,
        'catalogVersion': 2,
        'createdAt': '2026-07-17T00:00:00Z',
        'updatedAt': '2026-07-17T00:00:00Z',
      });

      expect(dto.category, RemoteShopItemCategory.unknown);
      expect(dto.rarity, RemoteShopItemRarity.unknown);
      expect(dto.equipSlot, RemoteShopEquipSlot.unknown);
      expect(dto.localizationKey, isNull);
    });

    test('rejects negative prices', () {
      expect(
        () => RemoteShopItemDto.fromJson(<String, dynamic>{
          'id': 'utility_coin_boost_1d',
          'category': 'utility',
          'subtype': 'coinBoost',
          'price_coins': -1,
          'is_consumable': true,
          'is_stackable': true,
          'asset_key': 'assets/shop/utilities/boost_coins.png',
          'is_active': true,
          'sort_order': 1,
          'catalog_version': 1,
          'created_at': '2026-07-17T00:00:00Z',
          'updated_at': '2026-07-17T00:00:00Z',
        }),
        throwsFormatException,
      );
    });

    test('rejects invalid dates and incomplete json', () {
      expect(
        () => RemoteShopItemDto.fromJson(<String, dynamic>{
          'id': 'utility_coin_boost_1d',
          'category': 'utility',
          'subtype': 'coinBoost',
          'price_coins': 100,
          'is_consumable': true,
          'is_stackable': true,
          'asset_key': 'assets/shop/utilities/boost_coins.png',
          'is_active': true,
          'sort_order': 1,
          'catalog_version': 1,
          'created_at': 'not-a-date',
          'updated_at': '2026-07-17T00:00:00Z',
        }),
        throwsFormatException,
      );

      expect(
        () => RemoteShopItemDto.fromJson(<String, dynamic>{
          'category': 'utility',
          'price_coins': 100,
          'is_consumable': true,
          'is_stackable': true,
          'asset_key': 'assets/shop/utilities/boost_coins.png',
          'is_active': true,
          'sort_order': 1,
          'catalog_version': 1,
          'created_at': '2026-07-17T00:00:00Z',
          'updated_at': '2026-07-17T00:00:00Z',
        }),
        throwsFormatException,
      );
    });
  });

  group('RemoteWalletDto', () {
    test('parses and rejects negative values', () {
      final dto = RemoteWalletDto.fromJson(<String, dynamic>{
        'user_id': 'user-1',
        'coins': 123,
        'version': 7,
        'created_at': '2026-07-17T00:00:00Z',
        'updated_at': '2026-07-17T00:00:00Z',
      }, expectedUserId: 'user-1');

      expect(dto.userId, 'user-1');
      expect(dto.coins, 123);

      expect(
        () => RemoteWalletDto.fromJson(<String, dynamic>{
          'user_id': 'user-1',
          'coins': -1,
          'version': 7,
          'created_at': '2026-07-17T00:00:00Z',
          'updated_at': '2026-07-17T00:00:00Z',
        }, expectedUserId: 'user-1'),
        throwsFormatException,
      );
    });
  });

  group('RemoteInventoryItemDto', () {
    test('parses and rejects invalid quantity', () {
      final dto = RemoteInventoryItemDto.fromJson(<String, dynamic>{
        'id': 'inv-1',
        'user_id': 'user-1',
        'item_id': 'utility_xp_boost_1d',
        'quantity': 2,
        'acquisition_source': 'purchase',
        'acquired_at': '2026-07-17T00:00:00Z',
        'updated_at': '2026-07-17T00:00:00Z',
      }, expectedUserId: 'user-1');

      expect(dto.quantity, 2);

      expect(
        () => RemoteInventoryItemDto.fromJson(<String, dynamic>{
          'id': 'inv-1',
          'user_id': 'user-1',
          'item_id': 'utility_xp_boost_1d',
          'quantity': 0,
          'acquisition_source': 'purchase',
          'acquired_at': '2026-07-17T00:00:00Z',
          'updated_at': '2026-07-17T00:00:00Z',
        }, expectedUserId: 'user-1'),
        throwsFormatException,
      );
    });
  });

  group('RemoteEquippedCosmeticDto', () {
    test('parses and rejects invalid slot or dates', () {
      final dto = RemoteEquippedCosmeticDto.fromJson(<String, dynamic>{
        'user_id': 'user-1',
        'slot': 'screen_background',
        'item_id': 'wallpaper_mist_blue',
        'equipped_at': '2026-07-17T00:00:00Z',
      }, expectedUserId: 'user-1');

      expect(dto.slot, RemoteShopEquipSlot.screenBackground);

      expect(
        () => RemoteEquippedCosmeticDto.fromJson(<String, dynamic>{
          'user_id': 'user-1',
          'slot': 'future_slot',
          'item_id': 'wallpaper_mist_blue',
          'equipped_at': '2026-07-17T00:00:00Z',
        }, expectedUserId: 'user-1'),
        throwsFormatException,
      );
    });
  });

  group('RemoteShopBundleDto', () {
    test('parses a valid bundle row', () {
      final dto = RemoteShopBundleDto.fromJson(<String, dynamic>{
        'id': 'pack_beige_rutio',
        'family_id': 'pack_beige_rutio',
        'rarity': 'common',
        'price_coins': 300,
        'original_price_coins': 330,
        'is_active': true,
        'sort_order': 0,
        'catalog_version': 2,
        'created_at': '2026-07-17T00:00:00Z',
        'updated_at': '2026-07-17T00:00:00Z',
      });

      expect(dto.id, 'pack_beige_rutio');
      expect(dto.familyId, 'pack_beige_rutio');
      expect(dto.rarity, RemoteShopItemRarity.common);
      expect(dto.priceCoins, 300);
      expect(dto.originalPriceCoins, 330);
      expect(dto.isActive, isTrue);
      expect(dto.catalogVersion, 2);
    });

    test('rejects a negative price', () {
      expect(
        () => RemoteShopBundleDto.fromJson(<String, dynamic>{
          'id': 'pack_beige_rutio',
          'family_id': 'pack_beige_rutio',
          'rarity': 'common',
          'price_coins': -1,
          'original_price_coins': 330,
          'is_active': true,
          'sort_order': 0,
          'catalog_version': 2,
          'created_at': '2026-07-17T00:00:00Z',
          'updated_at': '2026-07-17T00:00:00Z',
        }),
        throwsFormatException,
      );
    });

    test('rejects when original price is below the final price', () {
      expect(
        () => RemoteShopBundleDto.fromJson(<String, dynamic>{
          'id': 'pack_beige_rutio',
          'family_id': 'pack_beige_rutio',
          'rarity': 'common',
          'price_coins': 330,
          'original_price_coins': 300,
          'is_active': true,
          'sort_order': 0,
          'catalog_version': 2,
          'created_at': '2026-07-17T00:00:00Z',
          'updated_at': '2026-07-17T00:00:00Z',
        }),
        throwsFormatException,
      );
    });

    test('rejects an unknown rarity', () {
      expect(
        () => RemoteShopBundleDto.fromJson(<String, dynamic>{
          'id': 'pack_beige_rutio',
          'family_id': 'pack_beige_rutio',
          'rarity': 'future_rarity',
          'price_coins': 300,
          'original_price_coins': 330,
          'is_active': true,
          'sort_order': 0,
          'catalog_version': 2,
          'created_at': '2026-07-17T00:00:00Z',
          'updated_at': '2026-07-17T00:00:00Z',
        }),
        throwsFormatException,
      );
    });
  });

  group('RemoteShopBundleItemDto', () {
    test('parses a valid bundle item row', () {
      final dto = RemoteShopBundleItemDto.fromJson(<String, dynamic>{
        'bundle_id': 'pack_beige_rutio',
        'item_id': 'wallpaper_rutio_beige',
        'slot': 'screen_background',
      });

      expect(dto.bundleId, 'pack_beige_rutio');
      expect(dto.itemId, 'wallpaper_rutio_beige');
      expect(dto.slot, RemoteShopEquipSlot.screenBackground);
    });

    test('rejects an invalid slot', () {
      expect(
        () => RemoteShopBundleItemDto.fromJson(<String, dynamic>{
          'bundle_id': 'pack_beige_rutio',
          'item_id': 'wallpaper_rutio_beige',
          'slot': 'future_slot',
        }),
        throwsFormatException,
      );
    });
  });
}
