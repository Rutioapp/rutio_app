import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/data/shop_assets_catalog.dart';

import 'shop_asset_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Shop asset bundle load', () {
    test('rootBundle loads every catalog assetPath', () async {
      for (final asset in ShopAssetsCatalog.allAssets) {
        final byteData = await rootBundle.load(asset.assetPath);
        expect(byteData.lengthInBytes, greaterThan(0), reason: asset.assetPath);
      }
    });

    test('rootBundle loads every catalog previewAssetPath', () async {
      for (final asset in ShopAssetsCatalog.allAssets) {
        final byteData = await rootBundle.load(asset.previewAssetPath);
        expect(
          byteData.lengthInBytes,
          greaterThan(0),
          reason: asset.previewAssetPath,
        );
      }
    });

    test('rootBundle loads the runtime-reported common wallpapers', () async {
      final softSage = await rootBundle.load(
        'assets/shop/wallpapers/common/wallpaper_soft_sage.webp',
      );
      final offWhite = await rootBundle.load(
        'assets/shop/wallpapers/common/wallpaper_off_white.webp',
      );

      expect(
        softSage.lengthInBytes,
        greaterThan(0),
        reason: 'assets/shop/wallpapers/common/wallpaper_soft_sage.webp',
      );
      expect(
        offWhite.lengthInBytes,
        greaterThan(0),
        reason: 'assets/shop/wallpapers/common/wallpaper_off_white.webp',
      );
    });

    test('rootBundle loads auxiliary mystery box assets', () async {
      for (final assetPath in explicitlyRegisteredAuxiliaryShopAssets) {
        final byteData = await rootBundle.load(assetPath);
        expect(byteData.lengthInBytes, greaterThan(0), reason: assetPath);
      }
    });
  });
}
