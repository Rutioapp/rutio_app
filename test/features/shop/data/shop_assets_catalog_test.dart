import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/data/shop_assets_catalog.dart';
import 'package:rutio/features/shop/domain/models/shop_asset_enums.dart';

void main() {
  test('shop cosmetics catalog keeps unique ids and local asset paths', () {
    final assets = ShopAssetsCatalog.allAssets;
    final ids = assets.map((asset) => asset.id).toList(growable: false);

    expect(assets, hasLength(61));
    expect(ids.toSet().length, ids.length);

    for (final asset in assets) {
      expect(asset.assetPath, startsWith('assets/shop/'));
      expect(asset.previewAssetPath, asset.assetPath);
      expect(asset.assetPath, contains('/${asset.rarity.key}/'));

      switch (asset.category) {
        case ShopAssetCategory.wallpaper:
          expect(asset.assetPath, contains('/wallpapers/'));
          break;
        case ShopAssetCategory.habitCard:
          expect(asset.assetPath, contains('/habit_cards/'));
          break;
        case ShopAssetCategory.userCard:
          expect(asset.assetPath, contains('/user_cards/'));
          break;
      }
    }

    expect(
      ShopAssetsCatalog.getAssetById('habit_card_warm_beige')!.assetPath,
      'assets/shop/habit_cards/common/habit_card_rutio_beige.webp',
    );
    expect(
      ShopAssetsCatalog.getAssetById('user_card_cream_light')!.assetPath,
      'assets/shop/user_cards/common/user_card_cream_yellow.webp',
    );
  });
}
