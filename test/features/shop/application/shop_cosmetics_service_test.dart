import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/application/shop_cosmetics_service.dart';
import 'package:rutio/features/shop/data/shop_assets_catalog.dart';
import 'package:rutio/features/shop/domain/models/shop_asset_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_state.dart';

void main() {
  group('ShopCosmeticsService purchase', () {
    test('purchaseAsset success deducts wallet and marks asset owned', () {
      final service = ShopCosmeticsService(
        state: const ShopCosmeticsState.initial(),
        walletCoins: 500,
      );

      final result = service.purchaseAsset('wallpaper_warm_beige');

      expect(result.status, ShopCosmeticsOperationStatus.success);
      expect(result.walletCoins, 380);
      expect(result.state.ownedAssetIds, contains('wallpaper_warm_beige'));
      expect(service.isAssetOwned('wallpaper_warm_beige'), isFalse);
      expect(
        result.state.assetOwnershipState(
          ShopAssetsCatalog.getAssetById('wallpaper_warm_beige')!,
          bundles: ShopAssetsCatalog.allBundles,
        ),
        ShopAssetOwnershipState.owned,
      );
    });

    test('purchaseAsset fails when balance is insufficient', () {
      final service = ShopCosmeticsService(
        state: const ShopCosmeticsState.initial(),
        walletCoins: 100,
      );

      final result = service.purchaseAsset('wallpaper_warm_beige');

      expect(result.status, ShopCosmeticsOperationStatus.insufficientCoins);
      expect(result.walletCoins, 100);
      expect(result.state, const ShopCosmeticsState.initial());
    });

    test('purchaseAsset fails when asset is already owned', () {
      final service = ShopCosmeticsService(
        state: ShopCosmeticsState(
          ownedAssetIds: <String>['wallpaper_warm_beige'],
          ownedBundleIds: <String>[],
        ),
        walletCoins: 500,
      );

      final result = service.purchaseAsset('wallpaper_warm_beige');

      expect(result.status, ShopCosmeticsOperationStatus.alreadyOwned);
      expect(result.walletCoins, 500);
    });

    test('purchaseAsset fails when asset does not exist', () {
      final service = ShopCosmeticsService(
        state: const ShopCosmeticsState.initial(),
        walletCoins: 500,
      );

      final result = service.purchaseAsset('missing_asset');

      expect(result.status, ShopCosmeticsOperationStatus.assetNotFound);
    });

    test('purchaseBundle unlocks included assets and deducts wallet', () {
      final service = ShopCosmeticsService(
        state: const ShopCosmeticsState.initial(),
        walletCoins: 1000,
      );

      final result = service.purchaseBundle('bundle_warm_beige');

      expect(result.status, ShopCosmeticsOperationStatus.success);
      expect(result.walletCoins, 700);
      expect(result.state.ownedBundleIds, contains('bundle_warm_beige'));
      expect(result.state.ownedAssetIds, isEmpty);
      expect(result.state.isAssetOwned(
        'habit_card_warm_beige',
        bundles: ShopAssetsCatalog.allBundles,
      ), isTrue);
      expect(result.state.assetOwnershipState(
        ShopAssetsCatalog.getAssetById('habit_card_warm_beige')!,
        bundles: ShopAssetsCatalog.allBundles,
      ), ShopAssetOwnershipState.includedInOwnedBundle);
    });

    test('purchaseBundle fails when balance is insufficient', () {
      final service = ShopCosmeticsService(
        state: const ShopCosmeticsState.initial(),
        walletCoins: 200,
      );

      final result = service.purchaseBundle('bundle_warm_beige');

      expect(result.status, ShopCosmeticsOperationStatus.insufficientCoins);
      expect(result.walletCoins, 200);
    });

    test('purchaseBundle fails when bundle is already owned', () {
      final service = ShopCosmeticsService(
        state: ShopCosmeticsState(
          ownedAssetIds: <String>[
            'wallpaper_warm_beige',
            'habit_card_warm_beige',
            'user_card_warm_beige',
          ],
          ownedBundleIds: <String>['bundle_warm_beige'],
        ),
        walletCoins: 1000,
      );

      final result = service.purchaseBundle('bundle_warm_beige');

      expect(result.status, ShopCosmeticsOperationStatus.alreadyOwned);
    });

    test('purchaseBundle fails when bundle does not exist', () {
      final service = ShopCosmeticsService(
        state: const ShopCosmeticsState.initial(),
        walletCoins: 1000,
      );

      final result = service.purchaseBundle('missing_bundle');

      expect(result.status, ShopCosmeticsOperationStatus.bundleNotFound);
    });
  });

  group('ShopCosmeticsService equip', () {
    test('equipAsset works for all categories and replaces previous asset', () {
      final service = ShopCosmeticsService(
        state: ShopCosmeticsState(
          ownedAssetIds: <String>[
            'wallpaper_warm_beige',
            'wallpaper_soft_camel',
            'habit_card_warm_beige',
            'habit_card_soft_camel',
            'user_card_warm_beige',
            'user_card_soft_camel',
          ],
          ownedBundleIds: <String>[],
          equippedWallpaperId: 'wallpaper_warm_beige',
          equippedHabitCardSkinId: 'habit_card_warm_beige',
          equippedUserCardSkinId: 'user_card_warm_beige',
        ),
        walletCoins: 0,
      );

      final wallpaper = service.equipAsset('wallpaper_soft_camel');
      final habitCard = ShopCosmeticsService(
        state: wallpaper.state,
        walletCoins: 0,
      ).equipAsset('habit_card_soft_camel');
      final userCard = ShopCosmeticsService(
        state: habitCard.state,
        walletCoins: 0,
      ).equipAsset('user_card_soft_camel');

      expect(wallpaper.status, ShopCosmeticsOperationStatus.success);
      expect(wallpaper.state.equippedWallpaperId, 'wallpaper_soft_camel');
      expect(wallpaper.state.ownedAssetIds, contains('wallpaper_warm_beige'));

      expect(habitCard.status, ShopCosmeticsOperationStatus.success);
      expect(habitCard.state.equippedHabitCardSkinId, 'habit_card_soft_camel');
      expect(habitCard.state.ownedAssetIds, contains('habit_card_warm_beige'));

      expect(userCard.status, ShopCosmeticsOperationStatus.success);
      expect(userCard.state.equippedUserCardSkinId, 'user_card_soft_camel');
      expect(userCard.state.ownedAssetIds, contains('user_card_warm_beige'));
    });

    test('equipAsset fails when asset is not owned', () {
      final service = ShopCosmeticsService(
        state: const ShopCosmeticsState.initial(),
        walletCoins: 0,
      );

      final result = service.equipAsset('wallpaper_warm_beige');

      expect(result.status, ShopCosmeticsOperationStatus.assetNotOwned);
    });

    test('unequipAsset clears the requested slot', () {
      final service = ShopCosmeticsService(
        state: ShopCosmeticsState(
          ownedAssetIds: <String>['wallpaper_warm_beige'],
          ownedBundleIds: <String>[],
          equippedWallpaperId: 'wallpaper_warm_beige',
        ),
        walletCoins: 0,
      );

      final result = service.unequipAsset(ShopAssetCategory.wallpaper);

      expect(result.status, ShopCosmeticsOperationStatus.success);
      expect(result.state.equippedWallpaperId, isNull);
      expect(result.state.ownedAssetIds, contains('wallpaper_warm_beige'));
    });

    test('asset ownership helper reports bundle-included assets', () {
      final service = ShopCosmeticsService(
        state: ShopCosmeticsState(
          ownedAssetIds: <String>[],
          ownedBundleIds: <String>['bundle_warm_beige'],
        ),
        walletCoins: 0,
      );

      expect(
        service.assetOwnershipState('wallpaper_warm_beige'),
        ShopAssetOwnershipState.includedInOwnedBundle,
      );
      expect(service.isAssetOwned('wallpaper_warm_beige'), isTrue);
      expect(service.isBundleOwned('bundle_warm_beige'), isTrue);
    });
  });
}
