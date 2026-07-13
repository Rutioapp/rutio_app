import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/data/shop_cosmetics_repository.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ShopCosmeticsRepository', () {
    test('persists and restores state per scope', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final demoRepository = ShopCosmeticsRepository(
        scopeResolver: () => 'demo_user',
      );
      final otherRepository = ShopCosmeticsRepository(
        scopeResolver: () => 'other_user',
      );

      await demoRepository.save(
        ShopCosmeticsState(
          ownedAssetIds: const <String>['wallpaper_mist_blue'],
          ownedBundleIds: const <String>[],
          equippedWallpaperId: 'wallpaper_mist_blue',
        ),
      );

      final demoState = await demoRepository.load();
      final otherState = await otherRepository.load();

      expect(demoState.equippedWallpaperId, 'wallpaper_mist_blue');
      expect(demoState.ownedAssetIds, contains('wallpaper_mist_blue'));
      expect(otherState, const ShopCosmeticsState.initial());
    });

    test('migrates legacy data into active scope once', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        ShopCosmeticsRepository.legacyStorageKey:
            '{"ownedAssetIds":["habit_card_warm_beige"],"ownedBundleIds":[],"equippedWallpaperId":null,"equippedHabitCardSkinId":"habit_card_warm_beige","equippedUserCardSkinId":null}',
      });
      final repository = ShopCosmeticsRepository(
        scopeResolver: () => 'demo_user',
      );

      final state = await repository.load();
      final reloaded = await repository.load();

      expect(state.equippedHabitCardSkinId, 'habit_card_warm_beige');
      expect(reloaded.equippedHabitCardSkinId, 'habit_card_warm_beige');
    });

    test('sanitizes obsolete rare wallpaper ids safely', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        ShopCosmeticsRepository.legacyStorageKey:
            '{"ownedAssetIds":["wallpaper_calm_sand","wallpaper_mist_blue"],"ownedBundleIds":[],"equippedWallpaperId":"wallpaper_calm_sand","equippedHabitCardSkinId":null,"equippedUserCardSkinId":null}',
      });
      final repository =
          ShopCosmeticsRepository(scopeResolver: () => 'demo_user');

      final state = await repository.load();

      expect(state.ownedAssetIds, equals(<String>['wallpaper_mist_blue']));
      expect(state.equippedWallpaperId, isNull);
    });
  });
}
