import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/data/shop_catalog.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';

void main() {
  group('ShopCatalog integrity', () {
    test('has no duplicate item ids', () {
      final ids =
          ShopCatalog.allItems.map((item) => item.id).toList(growable: false);
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
      final collectionIds =
          ShopCatalog.allCollections.map((collection) => collection.id).toSet();

      final itemsWithCollection =
          ShopCatalog.allItems.where((item) => item.collectionId != null);

      for (final item in itemsWithCollection) {
        expect(collectionIds.contains(item.collectionId), isTrue,
            reason: item.id);
      }
    });
  });

  group('ShopCatalog queries', () {
    test('getItemById returns the matching item', () {
      final item = ShopCatalog.getItemById('wallpaper_mist_blue');

      expect(item, isNotNull);
      expect(item!.title, 'Mist Blue Wallpaper');
      expect(ShopCatalog.getItemById('missing_item'), isNull);
    });

    test('filters by category', () {
      final cosmeticItems =
          ShopCatalog.itemsByCategory(ShopItemCategory.cosmetic);
      final utilityItems =
          ShopCatalog.itemsByCategory(ShopItemCategory.utility);

      expect(cosmeticItems, hasLength(62));
      expect(utilityItems, hasLength(5));
      expect(
          cosmeticItems
              .every((item) => item.category == ShopItemCategory.cosmetic),
          isTrue);
      expect(
          utilityItems
              .every((item) => item.category == ShopItemCategory.utility),
          isTrue);
    });

    test('filters by type', () {
      final backgroundItems = ShopCatalog.itemsByType(ShopItemType.background);
      final habitCardItems = ShopCatalog.itemsByType(ShopItemType.habitCard);
      final userCardItems = ShopCatalog.itemsByType(ShopItemType.userCard);
      final mysteryBoxes = ShopCatalog.itemsByType(ShopItemType.mysteryBox);

      expect(backgroundItems, hasLength(21));
      expect(habitCardItems, hasLength(23));
      expect(userCardItems, hasLength(18));
      expect(mysteryBoxes.map((item) => item.id),
          <String>['utility_mystery_box_basic']);
    });

    test('habit card items reference the new definitive filenames', () {
      final habitCardAssetRefs = ShopCatalog.itemsByType(ShopItemType.habitCard)
          .map((item) => item.assetRef)
          .toList(growable: false);

      expect(
        habitCardAssetRefs,
        orderedEquals(<String>[
          'assets/shop/habit_cards/common/habit_card_rutio_beige.webp',
          'assets/shop/habit_cards/common/habit_card_soft_camel.webp',
          'assets/shop/habit_cards/common/habit_card_off_white.webp',
          'assets/shop/habit_cards/common/habit_card_cream_yellow.webp',
          'assets/shop/habit_cards/common/habit_card_mist_blue.webp',
          'assets/shop/habit_cards/common/habit_card_stone_gray.webp',
          'assets/shop/habit_cards/common/habit_card_dusty_lilac.webp',
          'assets/shop/habit_cards/common/habit_card_clay_rose.webp',
          'assets/shop/habit_cards/common/habit_card_soft_terracotta.webp',
          'assets/shop/habit_cards/common/habit_card_soft_sage.webp',
          'assets/shop/habit_cards/rare/habit_card_lilac_dawn.webp',
          'assets/shop/habit_cards/rare/habit_card_lavender_blue.webp',
          'assets/shop/habit_cards/rare/habit_card_golden_camel.webp',
          'assets/shop/habit_cards/rare/habit_card_sage_bloom.webp',
          'assets/shop/habit_cards/rare/habit_card_dusty_rose.webp',
          'assets/shop/habit_cards/rare/habit_card_pastel_sky.webp',
          'assets/shop/habit_cards/rare/habit_card_soft_peach.webp',
          'assets/shop/habit_cards/epic/habit_card_ocean_depth.webp',
          'assets/shop/habit_cards/epic/habit_card_city_sunrise.webp',
          'assets/shop/habit_cards/epic/habit_card_leopard.webp',
          'assets/shop/habit_cards/epic/habit_card_full_moon.webp',
          'assets/shop/habit_cards/epic/habit_card_golden_clouds.webp',
          'assets/shop/habit_cards/epic/habit_card_zebra_minimal.webp',
        ]),
      );
    });

    test('user card items reference the new definitive filenames', () {
      final userCardAssetRefs = ShopCatalog.itemsByType(ShopItemType.userCard)
          .map((item) => item.assetRef)
          .toList(growable: false);

      expect(
        userCardAssetRefs,
        orderedEquals(<String>[
          'assets/shop/user_cards/common/user_card_rutio_beige.webp',
          'assets/shop/user_cards/common/user_card_soft_camel.webp',
          'assets/shop/user_cards/common/user_card_off_white.webp',
          'assets/shop/user_cards/common/user_card_cream_yellow.webp',
          'assets/shop/user_cards/common/user_card_mist_blue.webp',
          'assets/shop/user_cards/common/user_card_stone_gray.webp',
          'assets/shop/user_cards/common/user_card_dusty_lilac.webp',
          'assets/shop/user_cards/common/user_card_clay_rose.webp',
          'assets/shop/user_cards/common/user_card_soft_terracotta.webp',
          'assets/shop/user_cards/common/user_card_soft_sage.webp',
          'assets/shop/user_cards/rare/user_card_lilac_dawn.webp',
          'assets/shop/user_cards/rare/user_card_dusty_rose.webp',
          'assets/shop/user_cards/rare/user_card_golden_camel.webp',
          'assets/shop/user_cards/rare/user_card_pastel_sky.webp',
          'assets/shop/user_cards/rare/user_card_soft_peach.webp',
          'assets/shop/user_cards/epic/user_card_ocean_depth.webp',
          'assets/shop/user_cards/epic/user_card_city_sunrise.webp',
          'assets/shop/user_cards/epic/user_card_full_moon.webp',
        ]),
      );
    });

    test('filters by collection', () {
      final minimalItems = ShopCatalog.itemsByCollection('minimal');
      final gradientItems = ShopCatalog.itemsByCollection('gradient');
      final landscapeItems = ShopCatalog.itemsByCollection('landscape');

      expect(minimalItems, hasLength(30));
      expect(gradientItems, hasLength(15));
      expect(landscapeItems, hasLength(17));
      expect(
          minimalItems.every((item) => item.collectionId == 'minimal'), isTrue);
      expect(gradientItems.every((item) => item.collectionId == 'gradient'),
          isTrue);
      expect(landscapeItems.every((item) => item.collectionId == 'landscape'),
          isTrue);
    });

    test('common backgrounds were fully replaced with the 10 new wallpapers',
        () {
      final commonBackgroundIds =
          ShopCatalog.itemsByType(ShopItemType.background)
              .where((item) => item.rarity == ShopItemRarity.common)
              .map((item) => item.id)
              .toList(growable: false);

      expect(
        commonBackgroundIds,
        orderedEquals(<String>[
          'wallpaper_mist_blue',
          'wallpaper_rutio_beige',
          'wallpaper_off_white',
          'wallpaper_mellow_camel',
          'wallpaper_stone_gray',
          'wallpaper_dusty_lilac',
          'wallpaper_clay_rose',
          'wallpaper_soft_terracotta',
          'wallpaper_soft_sage',
          'wallpaper_cream_yellow',
        ]),
      );
      expect(
        commonBackgroundIds,
        isNot(contains(anyOf(
          'wallpaper_warm_beige',
          'wallpaper_soft_camel',
          'wallpaper_sand_plain',
          'wallpaper_cream_light',
        ))),
      );
    });

    test('common habit cards were restored as the full 10-color set', () {
      final commonHabitCardIds = ShopCatalog.itemsByType(ShopItemType.habitCard)
          .where((item) => item.rarity == ShopItemRarity.common)
          .map((item) => item.id)
          .toList(growable: false);

      expect(
        commonHabitCardIds,
        orderedEquals(<String>[
          'habit_card_warm_beige',
          'habit_card_soft_camel',
          'habit_card_sand_plain',
          'habit_card_cream_light',
          'habit_card_mist_blue',
          'habit_card_stone_gray',
          'habit_card_dusty_lilac',
          'habit_card_clay_rose',
          'habit_card_soft_terracotta',
          'habit_card_soft_sage',
        ]),
      );
    });

    test('user cards were integrated across common rare and epic sets', () {
      final userCards = ShopCatalog.itemsByType(ShopItemType.userCard);
      final commonIds = userCards
          .where((item) => item.rarity == ShopItemRarity.common)
          .map((item) => item.id)
          .toList(growable: false);
      final rareIds = userCards
          .where((item) => item.rarity == ShopItemRarity.rare)
          .map((item) => item.id)
          .toList(growable: false);
      final epicIds = userCards
          .where((item) => item.rarity == ShopItemRarity.epic)
          .map((item) => item.id)
          .toList(growable: false);

      expect(
        commonIds,
        orderedEquals(<String>[
          'user_card_warm_beige',
          'user_card_soft_camel',
          'user_card_sand_plain',
          'user_card_cream_light',
          'user_card_mist_blue',
          'user_card_stone_gray',
          'user_card_dusty_lilac',
          'user_card_clay_rose',
          'user_card_soft_terracotta',
          'user_card_soft_sage',
        ]),
      );
      expect(
        rareIds,
        orderedEquals(<String>[
          'user_card_lilac_dawn',
          'user_card_dusty_rose',
          'user_card_golden_camel',
          'user_card_pastel_sky',
          'user_card_soft_peach',
        ]),
      );
      expect(
        epicIds,
        orderedEquals(<String>[
          'user_card_ocean_depth',
          'user_card_city_sunrise',
          'user_card_full_moon',
        ]),
      );
    });

    test('rare and epic backgrounds match the new wallpaper rollout', () {
      final backgrounds = ShopCatalog.itemsByType(ShopItemType.background);
      final rareIds = backgrounds
          .where((item) => item.rarity == ShopItemRarity.rare)
          .map((item) => item.id)
          .toList(growable: false);
      final epicIds = backgrounds
          .where((item) => item.rarity == ShopItemRarity.epic)
          .map((item) => item.id)
          .toList(growable: false);

      expect(
        rareIds,
        orderedEquals(<String>[
          'wallpaper_jungle_sunrise',
          'wallpaper_carnival_pastel',
          'wallpaper_strawberry_pastel',
        ]),
      );
      expect(
        epicIds,
        orderedEquals(<String>[
          'wallpaper_starry_sky',
          'wallpaper_mint_abstract',
          'wallpaper_zebra_minimal',
          'wallpaper_wild_stripes',
          'wallpaper_cow_spots',
          'wallpaper_city_sunrise',
          'wallpaper_ocean_depth',
        ]),
      );
      expect(
        rareIds.followedBy(epicIds),
        isNot(contains(anyOf(
          'wallpaper_calm_sand',
          'wallpaper_soft_linen',
          'wallpaper_paper_dawn',
          'wallpaper_lavender_mist',
          'wallpaper_dune_layers',
        ))),
      );
    });

    test('epic habit cards match the new rollout', () {
      final epicHabitCardIds = ShopCatalog.itemsByType(ShopItemType.habitCard)
          .where((item) => item.rarity == ShopItemRarity.epic)
          .map((item) => item.id)
          .toList(growable: false);

      expect(
        epicHabitCardIds,
        orderedEquals(<String>[
          'habit_card_ocean_depth',
          'habit_card_city_sunrise',
          'habit_card_leopard',
          'habit_card_full_moon',
          'habit_card_golden_clouds',
          'habit_card_zebra_minimal',
        ]),
      );
    });
  });
}
