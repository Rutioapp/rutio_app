import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:rutio/features/shop/domain/models/habit_card_content_tone.dart';
import 'package:rutio/features/shop/domain/models/shop_asset.dart';
import 'package:rutio/features/shop/domain/models/shop_asset_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_bundle.dart';

void main() {
  group('ShopAsset', () {
    test('serializes and deserializes safely', () {
      const asset = ShopAsset(
        id: 'wallpaper_mist_blue',
        familyId: 'mist_blue',
        category: ShopAssetCategory.wallpaper,
        rarity: ShopAssetRarity.common,
        nameEs: 'Fondo Beige calido',
        nameEn: 'Mist Blue Wallpaper',
        priceAmber: 120,
        assetPath: 'assets/shop/wallpapers/common/wallpaper_mist_blue.webp',
        previewAssetPath:
            'assets/shop/wallpapers/common/wallpaper_mist_blue.webp',
        imageAlignmentX: 0.5,
        overlayColorValue: 0xCCFFFFFF,
        overlayOpacity: 0.2,
        contentTone: HabitCardContentTone.light,
        useContentScrim: true,
        sortOrder: 1,
      );

      final restored = ShopAsset.fromJson(asset.toJson());

      expect(restored, asset);
    });

    test('copyWith updates fields safely', () {
      const asset = ShopAsset(
        id: 'wallpaper_mist_blue',
        familyId: 'mist_blue',
        category: ShopAssetCategory.wallpaper,
        rarity: ShopAssetRarity.common,
        nameEs: 'Fondo Beige calido',
        nameEn: 'Mist Blue Wallpaper',
        priceAmber: 120,
        assetPath: 'assets/shop/wallpapers/common/wallpaper_mist_blue.webp',
        previewAssetPath:
            'assets/shop/wallpapers/common/wallpaper_mist_blue.webp',
      );

      final updated = asset.copyWith(
        rarity: ShopAssetRarity.rare,
        priceAmber: 250,
        imageFit: BoxFit.contain,
        imageAlignmentX: 0.25,
        overlayColorValue: 0x99FFFFFF,
        overlayOpacity: 0.12,
        contentTone: HabitCardContentTone.light,
        useContentScrim: true,
        sortOrder: 4,
      );

      expect(updated.rarity, ShopAssetRarity.rare);
      expect(updated.priceAmber, 250);
      expect(updated.sortOrder, 4);
      expect(updated.imageFit, BoxFit.contain);
      expect(updated.imageAlignmentX, 0.25);
      expect(updated.overlayColorValue, 0x99FFFFFF);
      expect(updated.overlayOpacity, 0.12);
      expect(updated.contentTone, HabitCardContentTone.light);
      expect(updated.useContentScrim, isTrue);
      expect(updated.id, asset.id);
    });

    test('uses dark tone and no scrim as safe defaults', () {
      final restored = ShopAsset.fromJson(<String, dynamic>{
        'id': 'habit_card_safe_default',
        'familyId': 'safe_default',
        'category': 'habitCard',
        'rarity': 'common',
        'nameEs': 'Default',
        'nameEn': 'Default',
        'priceAmber': 100,
        'assetPath': 'assets/shop/habit_cards/common/default.webp',
        'previewAssetPath': 'assets/shop/habit_cards/common/default.webp',
      });

      expect(restored.contentTone, HabitCardContentTone.dark);
      expect(restored.useContentScrim, isFalse);
    });
  });

  group('ShopBundle', () {
    test('serializes and deserializes safely', () {
      final bundle = ShopBundle(
        id: 'pack_beige_rutio',
        familyId: 'pack_beige_rutio',
        rarity: ShopAssetRarity.common,
        nameEs: 'Pack Beige Rutio',
        nameEn: 'Rutio Beige Pack',
        descriptionEs: 'Un trio neutro y sereno.',
        descriptionEn: 'A neutral and serene trio.',
        wallpaperItemId: 'wallpaper_rutio_beige',
        habitCardItemId: 'habit_card_warm_beige',
        userCardItemId: 'user_card_warm_beige',
        originalPriceAmber: 360,
        priceAmber: 325,
        discountPercentage: 10,
        isFeatured: true,
        sortOrder: 2,
      );

      final restored = ShopBundle.fromJson(bundle.toJson());

      expect(restored, bundle);
    });

    test('copyWith preserves immutability', () {
      final bundle = ShopBundle(
        id: 'pack_beige_rutio',
        familyId: 'pack_beige_rutio',
        rarity: ShopAssetRarity.common,
        nameEs: 'Pack Beige Rutio',
        nameEn: 'Rutio Beige Pack',
        descriptionEs: 'Un trio neutro y sereno.',
        descriptionEn: 'A neutral and serene trio.',
        wallpaperItemId: 'wallpaper_rutio_beige',
        habitCardItemId: 'habit_card_warm_beige',
        userCardItemId: 'user_card_warm_beige',
        originalPriceAmber: 360,
        priceAmber: 325,
        discountPercentage: 10,
      );

      final updated = bundle.copyWith(
        priceAmber: 545,
        rarity: ShopAssetRarity.rare,
      );

      expect(updated.priceAmber, 545);
      expect(updated.rarity, ShopAssetRarity.rare);
      expect(() => updated.assetIds.add('extra'), throwsUnsupportedError);
    });
  });
}
