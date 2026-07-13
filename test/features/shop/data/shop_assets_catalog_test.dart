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
          ShopAssetRarity.legendary,
        }),
      );
      expect(ShopAssetsCatalog.assetsByRarity(ShopAssetRarity.common),
          hasLength(18));
      expect(
          ShopAssetsCatalog.assetsByRarity(ShopAssetRarity.rare),
          hasLength(10));
      expect(ShopAssetsCatalog.assetsByRarity(ShopAssetRarity.epic),
          hasLength(11));
      expect(ShopAssetsCatalog.assetsByRarity(ShopAssetRarity.legendary),
          hasLength(3));
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
          hasLength(21));
      expect(ShopAssetsCatalog.assetsByCategory(ShopAssetCategory.habitCard),
          hasLength(11));
      expect(ShopAssetsCatalog.assetsByCategory(ShopAssetCategory.userCard),
          hasLength(10));
    });

    test('contains exactly 42 assets', () {
      expect(ShopAssetsCatalog.allAssets, hasLength(42));
    });

    test('contains exactly 10 bundles', () {
      expect(ShopAssetsCatalog.allBundles, hasLength(10));
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

    test('family groupings stay coherent after replacing common wallpapers',
        () {
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
          'calm_sand',
          'soft_linen',
          'paper_dawn',
          'violet_flame',
          'starry_sky',
          'mint_abstract',
          'zebra_minimal',
          'wild_stripes',
          'cow_spots',
          'city_sunrise',
          'ocean_depth',
          'lavender_mist',
          'dune_layers',
          'golden_dawn',
        }),
      );

      for (final familyId in const <String>[
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
        'jungle_sunrise',
        'carnival_pastel',
        'strawberry_pastel',
        'starry_sky',
        'mint_abstract',
        'zebra_minimal',
        'wild_stripes',
        'cow_spots',
        'city_sunrise',
        'ocean_depth',
      ]) {
        final familyAssets = ShopAssetsCatalog.assetsByFamily(familyId);
        expect(familyAssets, hasLength(1), reason: familyId);
        expect(familyAssets.single.category, ShopAssetCategory.wallpaper,
            reason: familyId);
        expect(ShopAssetsCatalog.bundlesByFamily(familyId), isEmpty,
            reason: familyId);
      }

      for (final familyId in const <String>[
        'warm_beige',
        'soft_camel',
        'sand_plain',
        'cream_light',
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
        expect(ShopAssetsCatalog.bundlesByFamily(familyId), hasLength(1),
            reason: familyId);
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

    test('bundle prices match rarity', () {
      for (final bundle in ShopAssetsCatalog.allBundles) {
        final expectedPrice = switch (bundle.rarity) {
          ShopAssetRarity.common => ShopAssetsCatalog.commonBundlePrice,
          ShopAssetRarity.rare => ShopAssetsCatalog.rareBundlePrice,
          ShopAssetRarity.epic => ShopAssetsCatalog.epicBundlePrice,
          ShopAssetRarity.legendary => ShopAssetsCatalog.legendaryBundlePrice,
        };
        expect(bundle.priceAmber, expectedPrice, reason: bundle.id);
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
          'assets/shop/habit_cards/rare/habit_card_stone_gray.webp',
          'assets/shop/habit_cards/rare/habit_card_soft_terracotta.webp',
          'assets/shop/habit_cards/rare/habit_card_clay_rose.webp',
          'assets/shop/habit_cards/rare/habit_card_violet_flame.webp',
          'assets/shop/habit_cards/epic/habit_card_dusty_lilac.webp',
          'assets/shop/habit_cards/epic/habit_card_mist_blue.webp',
          'assets/shop/habit_cards/legendary/habit_card_soft_sage.webp',
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
      expect(
        habitCards,
        isNot(contains(
            'assets/shop/habit_cards/legendary/habit_card_golden_dawn.webp')),
      );
    });

    test('bundle prices match expected family rarity tiers', () {
      for (final bundle in ShopAssetsCatalog.allBundles) {
        final assets = bundle.assetIds
            .map(ShopAssetsCatalog.getAssetById)
            .whereType<ShopAsset>()
            .toList(growable: false);

        expect(assets, anyOf(hasLength(2), hasLength(3)), reason: bundle.id);
        expect(
          assets.every((asset) => asset.familyId == bundle.familyId),
          isTrue,
          reason: bundle.id,
        );
        expect(
          assets.every((asset) => asset.rarity == bundle.rarity),
          isTrue,
          reason: bundle.id,
        );
      }
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
      expect(ShopAssetsCatalog.getBundleById('bundle_golden_dawn')?.familyId,
          'golden_dawn');
      expect(ShopAssetsCatalog.getAssetById('missing_asset'), isNull);
      expect(ShopAssetsCatalog.getBundleById('missing_bundle'), isNull);
    });

    test('filters by category family and rarity', () {
      expect(ShopAssetsCatalog.assetsByCategory(ShopAssetCategory.wallpaper),
          hasLength(21));
      expect(ShopAssetsCatalog.assetsByCategory(ShopAssetCategory.habitCard),
          hasLength(11));
      expect(ShopAssetsCatalog.assetsByFamily('lavender_mist'), hasLength(2));
      expect(ShopAssetsCatalog.assetsByFamily('violet_flame'), hasLength(1));
      expect(ShopAssetsCatalog.bundlesByFamily('lavender_mist'), hasLength(1));
      expect(ShopAssetsCatalog.assetsByRarity(ShopAssetRarity.legendary),
          hasLength(3));
    });

    test('rare habit card catalog contains violet flame visual config', () {
      final asset = ShopAssetsCatalog.getAssetById('habit_card_violet_flame');

      expect(asset, isNotNull);
      expect(asset?.rarity, ShopAssetRarity.rare);
      expect(asset?.priceAmber, ShopAssetsCatalog.rareAssetPrice);
      expect(asset?.category, ShopAssetCategory.habitCard);
      expect(
        asset?.assetPath,
        'assets/shop/habit_cards/rare/habit_card_violet_flame.webp',
      );
      expect(asset?.imageFit, BoxFit.cover);
      expect(asset?.imageAlignmentX, 0.65);
      expect(asset?.imageAlignmentY, 0);
      expect(asset?.overlayColorValue, 0xCCFFFFFF);
      expect(asset?.overlayOpacity, 0.18);
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
