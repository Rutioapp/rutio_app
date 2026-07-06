import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/domain/models/shop_asset.dart';
import 'package:rutio/features/shop/domain/models/shop_asset_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_bundle.dart';

void main() {
  group('ShopAsset', () {
    test('serializes and deserializes safely', () {
      const asset = ShopAsset(
        id: 'wallpaper_warm_beige',
        familyId: 'warm_beige',
        category: ShopAssetCategory.wallpaper,
        rarity: ShopAssetRarity.common,
        nameEs: 'Fondo Beige calido',
        nameEn: 'Warm Beige Wallpaper',
        priceAmber: 120,
        assetPath: 'assets/shop/wallpapers/common/wallpaper_warm_beige.webp',
        previewAssetPath: 'assets/shop/wallpapers/common/wallpaper_warm_beige.webp',
        sortOrder: 1,
      );

      final restored = ShopAsset.fromJson(asset.toJson());

      expect(restored, asset);
    });

    test('copyWith updates fields safely', () {
      const asset = ShopAsset(
        id: 'wallpaper_warm_beige',
        familyId: 'warm_beige',
        category: ShopAssetCategory.wallpaper,
        rarity: ShopAssetRarity.common,
        nameEs: 'Fondo Beige calido',
        nameEn: 'Warm Beige Wallpaper',
        priceAmber: 120,
        assetPath: 'assets/shop/wallpapers/common/wallpaper_warm_beige.webp',
        previewAssetPath: 'assets/shop/wallpapers/common/wallpaper_warm_beige.webp',
      );

      final updated = asset.copyWith(
        rarity: ShopAssetRarity.rare,
        priceAmber: 250,
        sortOrder: 4,
      );

      expect(updated.rarity, ShopAssetRarity.rare);
      expect(updated.priceAmber, 250);
      expect(updated.sortOrder, 4);
      expect(updated.id, asset.id);
    });
  });

  group('ShopBundle', () {
    test('serializes and deserializes safely', () {
      final bundle = ShopBundle(
        id: 'bundle_warm_beige',
        familyId: 'warm_beige',
        rarity: ShopAssetRarity.common,
        nameEs: 'Pack Beige calido',
        nameEn: 'Warm Beige Bundle',
        priceAmber: 300,
        assetIds: const <String>[
          'wallpaper_warm_beige',
          'habit_card_warm_beige',
          'user_card_warm_beige',
        ],
        sortOrder: 2,
      );

      final restored = ShopBundle.fromJson(bundle.toJson());

      expect(restored, bundle);
    });

    test('copyWith preserves immutability', () {
      final bundle = ShopBundle(
        id: 'bundle_warm_beige',
        familyId: 'warm_beige',
        rarity: ShopAssetRarity.common,
        nameEs: 'Pack Beige calido',
        nameEn: 'Warm Beige Bundle',
        priceAmber: 300,
        assetIds: const <String>[
          'wallpaper_warm_beige',
          'habit_card_warm_beige',
          'user_card_warm_beige',
        ],
      );

      final updated = bundle.copyWith(
        priceAmber: 650,
        rarity: ShopAssetRarity.rare,
      );

      expect(updated.priceAmber, 650);
      expect(updated.rarity, ShopAssetRarity.rare);
      expect(() => updated.assetIds.add('extra'), throwsUnsupportedError);
    });
  });
}
