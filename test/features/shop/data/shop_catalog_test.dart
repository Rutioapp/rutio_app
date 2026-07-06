import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/data/shop_catalog.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';

void main() {
  group('ShopCatalog integrity', () {
    test('has no duplicate item ids', () {
      final ids = ShopCatalog.allItems.map((item) => item.id).toList(growable: false);
      final uniqueIds = ids.toSet();

      expect(uniqueIds.length, ids.length);
    });

    test('enabled items have non-negative prices', () {
      final enabledItems = ShopCatalog.allItems.where((item) => item.isEnabled);

      expect(enabledItems, isNotEmpty);
      for (final item in enabledItems) {
        expect(item.priceCoins, greaterThanOrEqualTo(0), reason: item.id);
      }
    });

    test('items with collectionId point to an existing collection', () {
      final collectionIds = ShopCatalog.allCollections
          .map((collection) => collection.id)
          .toSet();

      final itemsWithCollection = ShopCatalog.allItems.where((item) => item.collectionId != null);

      for (final item in itemsWithCollection) {
        expect(collectionIds.contains(item.collectionId), isTrue, reason: item.id);
      }
    });
  });

  group('ShopCatalog queries', () {
    test('getItemById returns the matching item', () {
      final item = ShopCatalog.getItemById('wallpaper_warm_beige');

      expect(item, isNotNull);
      expect(item!.title, 'Warm Beige Wallpaper');
      expect(ShopCatalog.getItemById('missing_item'), isNull);
    });

    test('filters by category', () {
      final cosmeticItems = ShopCatalog.itemsByCategory(ShopItemCategory.cosmetic);
      final utilityItems = ShopCatalog.itemsByCategory(ShopItemCategory.utility);

      expect(cosmeticItems, hasLength(30));
      expect(utilityItems, hasLength(5));
      expect(cosmeticItems.every((item) => item.category == ShopItemCategory.cosmetic), isTrue);
      expect(utilityItems.every((item) => item.category == ShopItemCategory.utility), isTrue);
    });

    test('filters by type', () {
      final backgroundItems = ShopCatalog.itemsByType(ShopItemType.background);
      final habitCardItems = ShopCatalog.itemsByType(ShopItemType.habitCard);
      final userCardItems = ShopCatalog.itemsByType(ShopItemType.userCard);
      final mysteryBoxes = ShopCatalog.itemsByType(ShopItemType.mysteryBox);

      expect(backgroundItems, hasLength(10));
      expect(habitCardItems, hasLength(10));
      expect(userCardItems, hasLength(10));
      expect(mysteryBoxes.map((item) => item.id), <String>['utility_mystery_box_basic']);
    });

    test('filters by collection', () {
      final minimalItems = ShopCatalog.itemsByCollection('minimal');
      final gradientItems = ShopCatalog.itemsByCollection('gradient');
      final landscapeItems = ShopCatalog.itemsByCollection('landscape');

      expect(minimalItems, hasLength(12));
      expect(gradientItems, hasLength(12));
      expect(landscapeItems, hasLength(6));
      expect(minimalItems.every((item) => item.collectionId == 'minimal'), isTrue);
      expect(gradientItems.every((item) => item.collectionId == 'gradient'), isTrue);
      expect(landscapeItems.every((item) => item.collectionId == 'landscape'), isTrue);
    });
  });
}
