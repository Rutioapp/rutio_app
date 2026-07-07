import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/data/shop_assets_catalog.dart';

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
      final sandPlain = await rootBundle.load(
        'assets/shop/wallpapers/common/wallpaper_sand_plain.webp',
      );
      final creamLight = await rootBundle.load(
        'assets/shop/wallpapers/common/wallpaper_cream_light.webp',
      );

      expect(
        sandPlain.lengthInBytes,
        greaterThan(0),
        reason: 'assets/shop/wallpapers/common/wallpaper_sand_plain.webp',
      );
      expect(
        creamLight.lengthInBytes,
        greaterThan(0),
        reason: 'assets/shop/wallpapers/common/wallpaper_cream_light.webp',
      );
    });
  });
}
