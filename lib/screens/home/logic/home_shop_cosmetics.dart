part of 'package:rutio/screens/home/home_screen.dart';

extension _HomeScreenShopCosmetics on _HomeScreenState {
  Future<String?> _equippedHabitCardBackgroundAssetPath() async {
    try {
      final controller = ShopCosmeticsController(
        userStateStore: context.read<UserStateStore>(),
      );
      final asset = await controller.getEquippedHabitCardAssetOrNull();
      return asset?.assetPath;
    } catch (_) {
      return null;
    }
  }
}
