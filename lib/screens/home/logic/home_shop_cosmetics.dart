part of 'package:rutio/screens/home/home_screen.dart';

extension _HomeScreenShopCosmetics on _HomeScreenState {
  Future<String?> _equippedHabitCardBackgroundAssetPath() async {
    try {
      final controller = ShopCosmeticsController(
        userStateStore: context.read<UserStateStore>(),
      );
      final asset = await controller.getEquippedHabitCardAssetOrNull();
      if (kDebugMode) {
        debugPrint(
          '[ShopCosmetics] HomeHabitCard assetPath=${asset?.assetPath} fallback=${asset == null}',
        );
      }
      return asset?.assetPath;
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
