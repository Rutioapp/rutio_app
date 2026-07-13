import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/domain/models/backpack_item.dart';
import 'package:rutio/features/shop/domain/models/equipped_cosmetics.dart';
import 'package:rutio/features/shop/domain/models/owned_shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_collection.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_item_price.dart';

void main() {
  group('ShopItem', () {
    test('serializes and deserializes safely', () {
      final item = ShopItem(
        id: 'bg_sky_01',
        title: 'Cielo sereno',
        description: 'Un fondo azul suave.',
        category: ShopItemCategory.cosmetic,
        type: ShopItemType.background,
        rarity: ShopItemRarity.rare,
        collectionId: 'skyline',
        priceCoins: 250,
        assetRef: 'assets/shop/backgrounds/sky.png',
        metadata: const <String, dynamic>{
          'colors': <String>['blue', 'white'],
          'variants': <String, dynamic>{'day': true},
        },
      );

      final restored = ShopItem.fromJson(item.toJson());

      expect(restored, item);
      expect(restored.price, const ShopItemPrice(coins: 250));
      expect(restored.cosmeticSlot, CosmeticSlot.background);
      expect(restored.consumableType, isNull);
    });

    test('copyWith allows clearing nullable fields', () {
      const item = ShopItem(
        id: 'utility_01',
        title: 'Boost XP',
        category: ShopItemCategory.utility,
        type: ShopItemType.xpBoost,
        collectionId: 'season_1',
        assetRef: 'assets/shop/xp_boost.png',
      );

      final updated = item.copyWith(
        collectionId: null,
        assetRef: null,
        priceCoins: 90,
        metadata: const <String, dynamic>{'durationMinutes': 30},
      );

      expect(updated.collectionId, isNull);
      expect(updated.assetRef, isNull);
      expect(updated.priceCoins, 90);
      expect(updated.metadata['durationMinutes'], 30);
      expect(updated.consumableType, ConsumableType.xpBoost);
    });

    test('fromJson accepts nested price fallback', () {
      final restored = ShopItem.fromJson(const <String, dynamic>{
        'id': 'coins_boost',
        'title': 'Doble moneda',
        'category': 'utility',
        'type': 'coinBoost',
        'rarity': 'epic',
        'price': <String, dynamic>{'coins': 600},
      });

      expect(restored.priceCoins, 600);
      expect(restored.category, ShopItemCategory.utility);
      expect(restored.type, ShopItemType.coinBoost);
      expect(restored.rarity, ShopItemRarity.epic);
    });
  });

  group('ShopCollection', () {
    test('serializes and deserializes safely', () {
      const collection = ShopCollection(
        id: 'skyline',
        title: 'Skyline',
        description: 'Coleccion inspirada en cielos.',
        themeKey: 'sky',
        isEnabled: false,
        sortOrder: 3,
      );

      final restored = ShopCollection.fromJson(collection.toJson());

      expect(restored, collection);
    });

    test('copyWith updates mutable fields', () {
      const collection = ShopCollection(
        id: 'base',
        title: 'Base',
      );

      final updated = collection.copyWith(
        description: 'Inicial',
        isEnabled: false,
        sortOrder: 1,
      );

      expect(updated.description, 'Inicial');
      expect(updated.isEnabled, isFalse);
      expect(updated.sortOrder, 1);
    });
  });

  group('ShopItemPrice', () {
    test('serializes and deserializes safely', () {
      const price = ShopItemPrice(coins: 120);

      final restored = ShopItemPrice.fromJson(price.toJson());

      expect(restored, price);
    });

    test('copyWith updates coins', () {
      const price = ShopItemPrice(coins: 120);

      expect(price.copyWith(coins: 150), const ShopItemPrice(coins: 150));
    });
  });

  group('OwnedShopItem', () {
    test('serializes and deserializes safely', () {
      const item = OwnedShopItem(
        itemId: 'bg_sky_01',
        quantity: 2,
        acquiredAtMillis: 1710000000000,
        source: 'shop_purchase',
        metadata: <String, dynamic>{
          'origin': <String, dynamic>{'season': 1},
        },
      );

      final restored = OwnedShopItem.fromJson(item.toJson());

      expect(restored, item);
    });

    test('copyWith allows clearing optional fields', () {
      const item = OwnedShopItem(
        itemId: 'bg_sky_01',
        acquiredAtMillis: 1710000000000,
        source: 'reward',
      );

      final updated = item.copyWith(
        acquiredAtMillis: null,
        source: null,
        quantity: 4,
      );

      expect(updated.acquiredAtMillis, isNull);
      expect(updated.source, isNull);
      expect(updated.quantity, 4);
    });
  });

  group('EquippedCosmetics', () {
    test('serializes and deserializes safely', () {
      const equipped = EquippedCosmetics(
        backgroundItemId: 'bg_sky_01',
        habitCardItemId: 'habit_card_sand_01',
        userCardItemId: 'user_card_gold_01',
      );

      final restored = EquippedCosmetics.fromJson(equipped.toJson());

      expect(restored, equipped);
    });

    test('copyWith allows unequipping a slot', () {
      const equipped = EquippedCosmetics(
        backgroundItemId: 'bg_sky_01',
        habitCardItemId: 'habit_card_sand_01',
      );

      final updated = equipped.copyWith(habitCardItemId: null);

      expect(updated.backgroundItemId, 'bg_sky_01');
      expect(updated.habitCardItemId, isNull);
    });
  });

  group('BackpackItem', () {
    test('serializes and deserializes safely', () {
      const item = BackpackItem(
        itemId: 'xp_boost_small',
        quantity: 3,
      );

      final restored = BackpackItem.fromJson(item.toJson());

      expect(restored, item);
    });

    test('copyWith updates quantity', () {
      const item = BackpackItem(
        itemId: 'xp_boost_small',
        quantity: 3,
      );

      expect(item.copyWith(quantity: 5),
          const BackpackItem(itemId: 'xp_boost_small', quantity: 5));
    });
  });
}
