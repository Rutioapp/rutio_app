import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/data/shop_assets_catalog.dart';
import 'package:rutio/features/shop/domain/models/shop_asset_enums.dart';

void main() {
  group('ShopAssetsCatalog integrity', () {
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

      for (final familyId in familyIds) {
        final familyAssets = ShopAssetsCatalog.assetsByFamily(familyId);
        expect(familyAssets, hasLength(3), reason: familyId);
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
