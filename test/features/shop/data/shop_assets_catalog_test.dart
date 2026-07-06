import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/data/shop_assets_catalog.dart';
import 'package:rutio/features/shop/domain/models/shop_asset.dart';
import 'package:rutio/features/shop/domain/models/shop_asset_enums.dart';

void main() {
  group('ShopAssetsCatalog integrity', () {
    test('uses the expected rarity set and counts', () {
      final rarities = ShopAssetsCatalog.allAssets
          .map((asset) => asset.rarity)
          .toSet();

      expect(
        rarities,
        equals(<ShopAssetRarity>{
          ShopAssetRarity.common,
          ShopAssetRarity.rare,
          ShopAssetRarity.epic,
          ShopAssetRarity.legendary,
        }),
      );
      expect(ShopAssetsCatalog.assetsByRarity(ShopAssetRarity.common), hasLength(12));
      expect(ShopAssetsCatalog.assetsByRarity(ShopAssetRarity.rare), hasLength(9));
      expect(ShopAssetsCatalog.assetsByRarity(ShopAssetRarity.epic), hasLength(6));
      expect(ShopAssetsCatalog.assetsByRarity(ShopAssetRarity.legendary), hasLength(3));
    });

    test('uses the expected category set and counts', () {
      final categories = ShopAssetsCatalog.allAssets
          .map((asset) => asset.category)
          .toSet();

      expect(
        categories,
        equals(<ShopAssetCategory>{
          ShopAssetCategory.wallpaper,
          ShopAssetCategory.habitCard,
          ShopAssetCategory.userCard,
        }),
      );
      expect(ShopAssetsCatalog.assetsByCategory(ShopAssetCategory.wallpaper), hasLength(10));
      expect(ShopAssetsCatalog.assetsByCategory(ShopAssetCategory.habitCard), hasLength(10));
      expect(ShopAssetsCatalog.assetsByCategory(ShopAssetCategory.userCard), hasLength(10));
    });

    test('contains exactly 30 assets', () {
      expect(ShopAssetsCatalog.allAssets, hasLength(30));
    });

    test('contains exactly 10 bundles', () {
      expect(ShopAssetsCatalog.allBundles, hasLength(10));
    });

    test('all asset ids are unique', () {
      final ids = ShopAssetsCatalog.allAssets.map((asset) => asset.id).toList(growable: false);
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('all bundle ids are unique', () {
      final ids = ShopAssetsCatalog.allBundles.map((bundle) => bundle.id).toList(growable: false);
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('all bundles reference existing asset ids', () {
      final assetIds = ShopAssetsCatalog.allAssets.map((asset) => asset.id).toSet();

      for (final bundle in ShopAssetsCatalog.allBundles) {
        for (final assetId in bundle.assetIds) {
          expect(assetIds.contains(assetId), isTrue, reason: '${bundle.id}: $assetId');
        }
      }
    });

    test('each family has wallpaper habit card and user card', () {
      final familyIds = ShopAssetsCatalog.allAssets.map((asset) => asset.familyId).toSet();

      expect(
        familyIds,
        equals(<String>{
          'warm_beige',
          'soft_camel',
          'sand_plain',
          'cream_light',
          'calm_sand',
          'soft_linen',
          'paper_dawn',
          'lavender_mist',
          'dune_layers',
          'golden_dawn',
        }),
      );

      for (final familyId in familyIds) {
        final familyAssets = ShopAssetsCatalog.assetsByFamily(familyId);
        final familyBundles = ShopAssetsCatalog.bundlesByFamily(familyId);
        expect(familyAssets, hasLength(3), reason: familyId);
        expect(familyBundles, hasLength(1), reason: familyId);
        expect(
          familyAssets.map((asset) => asset.category).toSet(),
          equals(<ShopAssetCategory>{
            ShopAssetCategory.wallpaper,
            ShopAssetCategory.habitCard,
            ShopAssetCategory.userCard,
          }),
          reason: familyId,
        );
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

    test('bundle prices match expected family rarity tiers', () {
      for (final bundle in ShopAssetsCatalog.allBundles) {
        final assets = bundle.assetIds
            .map(ShopAssetsCatalog.getAssetById)
            .whereType<ShopAsset>()
            .toList(growable: false);

        expect(assets, hasLength(3), reason: bundle.id);
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
      final assetSortOrders = ShopAssetsCatalog.allAssets.map((asset) => asset.sortOrder).toList(growable: false);
      final bundleSortOrders = ShopAssetsCatalog.allBundles.map((bundle) => bundle.sortOrder).toList(growable: false);

      expect(assetSortOrders, orderedEquals(assetSortOrders.toList()..sort()));
      expect(bundleSortOrders, orderedEquals(bundleSortOrders.toList()..sort()));
      expect(assetSortOrders.toSet(), hasLength(assetSortOrders.length));
      expect(bundleSortOrders.toSet(), hasLength(bundleSortOrders.length));
    });
  });

  group('ShopAssetsCatalog helpers', () {
    test('getAssetById and getBundleById return matches', () {
      expect(ShopAssetsCatalog.getAssetById('wallpaper_warm_beige')?.familyId, 'warm_beige');
      expect(ShopAssetsCatalog.getBundleById('bundle_golden_dawn')?.familyId, 'golden_dawn');
      expect(ShopAssetsCatalog.getAssetById('missing_asset'), isNull);
      expect(ShopAssetsCatalog.getBundleById('missing_bundle'), isNull);
    });

    test('filters by category family and rarity', () {
      expect(ShopAssetsCatalog.assetsByCategory(ShopAssetCategory.wallpaper), hasLength(10));
      expect(ShopAssetsCatalog.assetsByFamily('lavender_mist'), hasLength(3));
      expect(ShopAssetsCatalog.bundlesByFamily('lavender_mist'), hasLength(1));
      expect(ShopAssetsCatalog.assetsByRarity(ShopAssetRarity.legendary), hasLength(3));
    });
  });
}
