part of 'package:rutio/screens/home/home_screen.dart';

extension _HomeScreenShopCosmetics on _HomeScreenState {
  ShopAsset? _equippedHabitCardAsset() {
    try {
      final asset = context.select<ShopCosmeticsController, ShopAsset?>(
        (ShopCosmeticsController controller) =>
            controller.getEquippedHabitCardAssetOrNullSync(),
      );
      if (kDebugMode) {
        debugPrint(
          '[ShopCosmetics] HomeHabitCard assetPath=${asset?.assetPath} '
          'fallback=${asset == null}',
        );
      }
      return asset;
    } catch (_) {
      if (kDebugMode) {
        debugPrint(
          '[ShopCosmetics] HomeHabitCard failed to resolve background image, using fallback',
        );
      }
      return null;
    }
  }
}
