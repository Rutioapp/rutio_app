import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/data/shop_assets_catalog.dart';
import 'package:rutio/features/shop/domain/models/shop_asset.dart';
import 'package:rutio/features/shop/domain/models/shop_asset_enums.dart';

void main() {
  group('ShopAssetsCatalog integrity', () {
    test('uses the expected rarity set and counts', () {
      final rarities =
          ShopAssetsCatalog.allAssets.map((asset) => asset.rarity).toSet();

      expect(
        rarities,
        equals(<ShopAssetRarity>{
          ShopAssetRarity.common,
          ShopAssetRarity.rare,
          ShopAssetRarity.epic,
        }),
      );
      expect(
        ShopAssetsCatalog.assetsByRarity(ShopAssetRarity.common),
        hasLength(30),
      );
      expect(
        ShopAssetsCatalog.assetsByRarity(ShopAssetRarity.rare),
        hasLength(15),
      );
      expect(
        ShopAssetsCatalog.assetsByRarity(ShopAssetRarity.epic),
        hasLength(16),
      );
      expect(
        ShopAssetsCatalog.assetsByRarity(ShopAssetRarity.legendary),
        hasLength(0),
      );
    });

    test('uses the expected category set and counts', () {
      final categories =
          ShopAssetsCatalog.allAssets.map((asset) => asset.category).toSet();

      expect(
        categories,
        equals(<ShopAssetCategory>{
          ShopAssetCategory.wallpaper,
          ShopAssetCategory.habitCard,
          ShopAssetCategory.userCard,
        }),
      );
      expect(ShopAssetsCatalog.assetsByCategory(ShopAssetCategory.wallpaper),
          hasLength(20));
      expect(ShopAssetsCatalog.assetsByCategory(ShopAssetCategory.habitCard),
          hasLength(23));
      expect(ShopAssetsCatalog.assetsByCategory(ShopAssetCategory.userCard),
          hasLength(18));
    });

    test('contains exactly 61 assets', () {
      expect(ShopAssetsCatalog.allAssets, hasLength(61));
    });

    test('contains the expected 22 bundle packs', () {
      expect(ShopAssetsCatalog.allBundles, hasLength(22));
    });

    test('all asset ids are unique', () {
      final ids = ShopAssetsCatalog.allAssets
          .map((asset) => asset.id)
          .toList(growable: false);
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('all bundle ids are unique', () {
      final ids = ShopAssetsCatalog.allBundles
          .map((bundle) => bundle.id)
          .toList(growable: false);
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('all bundles reference existing asset ids', () {
      final assetIds =
          ShopAssetsCatalog.allAssets.map((asset) => asset.id).toSet();

      for (final bundle in ShopAssetsCatalog.allBundles) {
        for (final assetId in bundle.assetIds) {
          expect(assetIds.contains(assetId), isTrue,
              reason: '${bundle.id}: $assetId');
        }
      }
    });

    test('family groupings stay coherent across assets and packs', () {
      final familyIds =
          ShopAssetsCatalog.allAssets.map((asset) => asset.familyId).toSet();

      expect(
        familyIds,
        equals(<String>{
          'mist_blue',
          'rutio_beige',
          'off_white',
          'mellow_camel',
          'stone_gray',
          'dusty_lilac',
          'clay_rose',
          'soft_terracotta',
          'soft_sage',
          'cream_yellow',
          'warm_beige',
          'soft_camel',
          'sand_plain',
          'cream_light',
          'jungle_sunrise',
          'carnival_pastel',
          'strawberry_pastel',
          'lilac_dawn',
          'lavender_blue',
          'golden_camel',
          'sage_bloom',
          'dusty_rose',
          'pastel_sky',
          'soft_peach',
          'ocean_depth',
          'city_sunrise',
          'leopard',
          'full_moon',
          'golden_clouds',
          'zebra_minimal',
          'starry_sky',
          'mint_abstract',
          'wild_stripes',
          'cow_spots',
        }),
      );

      for (final familyId in const <String>[
        'rutio_beige',
        'off_white',
        'mellow_camel',
        'cream_yellow',
        'jungle_sunrise',
        'carnival_pastel',
        'strawberry_pastel',
        'starry_sky',
        'mint_abstract',
        'wild_stripes',
        'cow_spots',
      ]) {
        final familyAssets = ShopAssetsCatalog.assetsByFamily(familyId);
        expect(familyAssets, hasLength(1), reason: familyId);
        expect(familyAssets.single.category, ShopAssetCategory.wallpaper,
            reason: familyId);
        expect(ShopAssetsCatalog.bundlesByFamily(familyId), isEmpty,
            reason: familyId);
      }

      for (final familyId in const <String>[
        'mist_blue',
        'stone_gray',
        'dusty_lilac',
        'clay_rose',
        'soft_terracotta',
        'soft_sage',
        'ocean_depth',
        'city_sunrise',
        'zebra_minimal',
      ]) {
        final familyAssets = ShopAssetsCatalog.assetsByFamily(familyId);
        final expectedCount = familyId == 'zebra_minimal' ? 2 : 3;
        expect(familyAssets, hasLength(expectedCount), reason: familyId);
        expect(
          familyAssets.map((asset) => asset.category).toSet(),
          familyId == 'zebra_minimal'
              ? equals(<ShopAssetCategory>{
                  ShopAssetCategory.wallpaper,
                  ShopAssetCategory.habitCard,
                })
              : equals(<ShopAssetCategory>{
                  ShopAssetCategory.wallpaper,
                  ShopAssetCategory.habitCard,
                  ShopAssetCategory.userCard,
                }),
          reason: familyId,
        );
        expect(ShopAssetsCatalog.bundlesByFamily(familyId), isEmpty,
            reason: familyId);
      }

      for (final familyId in const <String>[
        'warm_beige',
        'soft_camel',
        'sand_plain',
        'cream_light',
        'lilac_dawn',
        'dusty_rose',
        'golden_camel',
        'pastel_sky',
        'soft_peach',
        'full_moon',
      ]) {
        final familyAssets = ShopAssetsCatalog.assetsByFamily(familyId);
        expect(familyAssets, hasLength(2), reason: familyId);
        expect(
          familyAssets.map((asset) => asset.category).toSet(),
          equals(<ShopAssetCategory>{
            ShopAssetCategory.habitCard,
            ShopAssetCategory.userCard,
          }),
          reason: familyId,
        );
        expect(ShopAssetsCatalog.bundlesByFamily(familyId), isEmpty,
            reason: familyId);
      }

      for (final bundle in ShopAssetsCatalog.allBundles) {
        final bundles = ShopAssetsCatalog.bundlesByFamily(bundle.familyId);

        expect(bundles, hasLength(1), reason: bundle.familyId);
        expect(bundles.single.id, bundle.id, reason: bundle.familyId);
      }
    });

    test('asset prices match rarity', () {
      for (final asset in ShopAssetsCatalog.allAssets) {
        final expectedPrice = switch (asset.rarity) {
          ShopAssetRarity.common => ShopAssetsCatalog.commonAssetPrice,
          ShopAssetRarity.rare => ShopAssetsCatalog.rareAssetPrice,
          ShopAssetRarity.epic => ShopAssetsCatalog.epicAssetPrice,
          ShopAssetRarity.legendary => ShopAssetsCatalog.legendaryAssetPrice,
        };
        expect(asset.priceAmber, expectedPrice, reason: asset.id);
      }
    });

    test('bundle prices match the discounted trio formula', () {
      for (final bundle in ShopAssetsCatalog.allBundles) {
        final originalPrice = bundle.assetIds
            .map((assetId) => ShopAssetsCatalog.getAssetById(assetId)!)
            .fold<int>(0, (int total, ShopAsset asset) {
          return total + asset.priceAmber;
        });
        final expectedDiscount = switch (bundle.rarity) {
          ShopAssetRarity.common =>
            ShopAssetsCatalog.commonBundleDiscountPercentage,
          ShopAssetRarity.rare =>
            ShopAssetsCatalog.rareBundleDiscountPercentage,
          ShopAssetRarity.epic =>
            ShopAssetsCatalog.epicBundleDiscountPercentage,
          ShopAssetRarity.legendary =>
            ShopAssetsCatalog.epicBundleDiscountPercentage,
        };
        final expectedPrice =
            _discountedBundlePrice(originalPrice, expectedDiscount);

        expect(bundle.originalPriceAmber, originalPrice, reason: bundle.id);
        expect(bundle.discountPercentage, expectedDiscount, reason: bundle.id);
        expect(bundle.priceAmber, expectedPrice, reason: bundle.id);
        expect(bundle.savingsAmber, originalPrice - expectedPrice,
            reason: bundle.id);
      }
    });

    test('assetPath and previewAssetPath are not empty', () {
      for (final asset in ShopAssetsCatalog.allAssets) {
        expect(asset.assetPath, isNotEmpty, reason: asset.id);
        expect(asset.previewAssetPath, isNotEmpty, reason: asset.id);
        expect(asset.assetPath, asset.previewAssetPath, reason: asset.id);
      }
    });

    test('habit card assets point to the new definitive webp filenames', () {
      final habitCards =
          ShopAssetsCatalog.assetsByCategory(ShopAssetCategory.habitCard)
              .map((asset) => asset.assetPath)
              .toList(growable: false);

      expect(
        habitCards,
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
      expect(
        habitCards,
        isNot(contains(
            'assets/shop/habit_cards/common/habit_card_warm_beige.webp')),
      );
      expect(
        habitCards,
        isNot(contains(
            'assets/shop/habit_cards/common/habit_card_sand_plain.webp')),
      );
      expect(
        habitCards,
        isNot(contains(
            'assets/shop/habit_cards/common/habit_card_cream_light.webp')),
      );
      expect(
        habitCards,
        isNot(
            contains('assets/shop/habit_cards/rare/habit_card_calm_sand.webp')),
      );
      expect(
        habitCards,
        isNot(contains(
            'assets/shop/habit_cards/rare/habit_card_soft_linen.webp')),
      );
      expect(
        habitCards,
        isNot(contains(
            'assets/shop/habit_cards/rare/habit_card_paper_dawn.webp')),
      );
      expect(
        habitCards,
        isNot(contains(
            'assets/shop/habit_cards/epic/habit_card_lavender_mist.webp')),
      );
      expect(
        habitCards,
        isNot(contains(
            'assets/shop/habit_cards/epic/habit_card_dune_layers.webp')),
      );
    });

    test('user card assets point to the new definitive webp filenames', () {
      final userCards =
          ShopAssetsCatalog.assetsByCategory(ShopAssetCategory.userCard)
              .map((asset) => asset.assetPath)
              .toList(growable: false);

      expect(
        userCards,
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

    test('bundle catalog stays enabled with the curated production packs', () {
      expect(ShopAssetsCatalog.allBundles, hasLength(22));
    });

    test('sortOrder stays strictly increasing', () {
      final assetSortOrders = ShopAssetsCatalog.allAssets
          .map((asset) => asset.sortOrder)
          .toList(growable: false);
      final bundleSortOrders = ShopAssetsCatalog.allBundles
          .map((bundle) => bundle.sortOrder)
          .toList(growable: false);

      expect(assetSortOrders, orderedEquals(assetSortOrders.toList()..sort()));
      expect(
          bundleSortOrders, orderedEquals(bundleSortOrders.toList()..sort()));
      expect(assetSortOrders.toSet(), hasLength(assetSortOrders.length));
      expect(bundleSortOrders.toSet(), hasLength(bundleSortOrders.length));
    });
  });

  group('ShopAssetsCatalog helpers', () {
    test('getAssetById and getBundleById return matches', () {
      expect(ShopAssetsCatalog.getAssetById('wallpaper_mist_blue')?.familyId,
          'mist_blue');
      expect(ShopAssetsCatalog.getBundleById('pack_beige_rutio')?.id,
          'pack_beige_rutio');
      expect(ShopAssetsCatalog.getBundleById('pack_noche_lunar')?.id,
          'pack_noche_lunar');
      expect(ShopAssetsCatalog.getAssetById('missing_asset'), isNull);
      expect(ShopAssetsCatalog.getBundleById('missing_bundle'), isNull);
    });

    test('filters by category family and rarity', () {
      expect(ShopAssetsCatalog.assetsByCategory(ShopAssetCategory.wallpaper),
          hasLength(20));
      expect(ShopAssetsCatalog.assetsByCategory(ShopAssetCategory.habitCard),
          hasLength(23));
      expect(ShopAssetsCatalog.assetsByCategory(ShopAssetCategory.userCard),
          hasLength(18));
      expect(ShopAssetsCatalog.assetsByFamily('lavender_mist'), isEmpty);
      expect(ShopAssetsCatalog.assetsByFamily('mist_blue'), hasLength(3));
      expect(ShopAssetsCatalog.assetsByFamily('lilac_dawn'), hasLength(2));
      expect(ShopAssetsCatalog.assetsByFamily('ocean_depth'), hasLength(3));
      expect(ShopAssetsCatalog.assetsByFamily('city_sunrise'), hasLength(3));
      expect(ShopAssetsCatalog.assetsByFamily('zebra_minimal'), hasLength(2));
      expect(ShopAssetsCatalog.assetsByFamily('leopard'), hasLength(1));
      expect(ShopAssetsCatalog.assetsByFamily('full_moon'), hasLength(2));
      expect(ShopAssetsCatalog.assetsByFamily('golden_clouds'), hasLength(1));
      expect(ShopAssetsCatalog.bundlesByFamily('lavender_mist'), isEmpty);
      expect(ShopAssetsCatalog.assetsByRarity(ShopAssetRarity.legendary),
          hasLength(0));
    });

    test('common habit card catalog contains the restored production set', () {
      final commonHabitCards =
          ShopAssetsCatalog.assetsByCategory(ShopAssetCategory.habitCard)
              .where((asset) => asset.rarity == ShopAssetRarity.common)
              .map((asset) => asset.id)
              .toList(growable: false);

      expect(
        commonHabitCards,
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

    test('rare habit card catalog contains the new rare backgrounds', () {
      final asset = ShopAssetsCatalog.getAssetById('habit_card_lilac_dawn');

      expect(asset, isNotNull);
      expect(asset?.rarity, ShopAssetRarity.rare);
      expect(asset?.priceAmber, ShopAssetsCatalog.rareAssetPrice);
      expect(asset?.category, ShopAssetCategory.habitCard);
      expect(
        asset?.assetPath,
        'assets/shop/habit_cards/rare/habit_card_lilac_dawn.webp',
      );
      expect(asset?.imageFit, BoxFit.cover);
      expect(asset?.imageAlignmentX, 0);
      expect(asset?.imageAlignmentY, 0);
      expect(asset?.overlayColorValue, isNull);
      expect(asset?.overlayOpacity, 0);
    });

    test('epic habit card catalog contains the new epic backgrounds', () {
      final epicHabitCards =
          ShopAssetsCatalog.assetsByCategory(ShopAssetCategory.habitCard)
              .where((asset) => asset.rarity == ShopAssetRarity.epic)
              .map((asset) => asset.id)
              .toList(growable: false);

      expect(
        epicHabitCards,
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

    test('common wallpaper catalog contains only new webp wallpapers', () {
      final wallpapers =
          ShopAssetsCatalog.assetsByCategory(ShopAssetCategory.wallpaper)
              .where((asset) => asset.rarity == ShopAssetRarity.common)
              .toList(growable: false);

      expect(wallpapers, hasLength(10));
      expect(wallpapers.map((asset) => asset.id).toSet(), hasLength(10));
      expect(
        wallpapers.every((asset) => asset.assetPath.endsWith('.webp')),
        isTrue,
      );
      expect(
        wallpapers.map((asset) => asset.id),
        isNot(contains(anyOf(
          'wallpaper_warm_beige',
          'wallpaper_soft_camel',
          'wallpaper_sand_plain',
          'wallpaper_cream_light',
        ))),
      );
    });

    test('rare and epic wallpaper catalog matches the new production set', () {
      final rareWallpapers =
          ShopAssetsCatalog.assetsByCategory(ShopAssetCategory.wallpaper)
              .where((asset) => asset.rarity == ShopAssetRarity.rare)
              .map((asset) => asset.id)
              .toList(growable: false);
      final epicWallpapers =
          ShopAssetsCatalog.assetsByCategory(ShopAssetCategory.wallpaper)
              .where((asset) => asset.rarity == ShopAssetRarity.epic)
              .map((asset) => asset.id)
              .toList(growable: false);

      expect(
        rareWallpapers,
        orderedEquals(<String>[
          'wallpaper_jungle_sunrise',
          'wallpaper_carnival_pastel',
          'wallpaper_strawberry_pastel',
        ]),
      );
      expect(
        epicWallpapers,
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
        rareWallpapers.followedBy(epicWallpapers),
        isNot(contains(anyOf(
          'wallpaper_calm_sand',
          'wallpaper_soft_linen',
          'wallpaper_paper_dawn',
          'wallpaper_lavender_mist',
          'wallpaper_dune_layers',
        ))),
      );
    });
  });
}

int _discountedBundlePrice(int originalPrice, int discountPercentage) {
  if (originalPrice <= 0) return 0;
  final discounted = originalPrice * (100 - discountPercentage) / 100;
  final rounded = (discounted / 5).round() * 5;
  if (rounded <= 0) return 5;
  if (rounded >= originalPrice) {
    final fallback = originalPrice - 5;
    return fallback > 0 ? fallback : originalPrice;
  }
  return rounded;
}
