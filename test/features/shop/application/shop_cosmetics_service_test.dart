import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/application/shop_cosmetics_service.dart';
import 'package:rutio/features/shop/data/shop_assets_catalog.dart';
import 'package:rutio/features/shop/domain/models/shop_asset_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_bundle_completion_quote.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_state.dart';

void main() {
  group('ShopCosmeticsService purchase', () {
    test('purchaseAsset success deducts wallet and marks asset owned', () {
      final service = ShopCosmeticsService(
        state: const ShopCosmeticsState.initial(),
        walletCoins: 500,
      );

      final result = service.purchaseAsset('wallpaper_mist_blue');

      expect(result.status, ShopCosmeticsOperationStatus.success);
      expect(result.walletCoins, 380);
      expect(result.state.ownedAssetIds, contains('wallpaper_mist_blue'));
      expect(service.isAssetOwned('wallpaper_mist_blue'), isFalse);
      expect(
        result.state.assetOwnershipState(
          ShopAssetsCatalog.getAssetById('wallpaper_mist_blue')!,
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

      final result = service.purchaseAsset('wallpaper_mist_blue');

      expect(result.status, ShopCosmeticsOperationStatus.insufficientCoins);
      expect(result.walletCoins, 100);
      expect(result.state, const ShopCosmeticsState.initial());
    });

    test('purchaseAsset fails when asset is already owned', () {
      final service = ShopCosmeticsService(
        state: ShopCosmeticsState(
          ownedAssetIds: <String>['wallpaper_mist_blue'],
          ownedBundleIds: <String>[],
        ),
        walletCoins: 500,
      );

      final result = service.purchaseAsset('wallpaper_mist_blue');

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

    test('purchaseBundle success deducts wallet and marks bundle owned', () {
      final bundlePrice =
          ShopAssetsCatalog.getBundleById('pack_beige_rutio')!.priceAmber;
      final service = ShopCosmeticsService(
        state: const ShopCosmeticsState.initial(),
        walletCoins: 1000,
      );

      final result = service.purchaseBundle('pack_beige_rutio');

      expect(result.status, ShopCosmeticsOperationStatus.success);
      expect(result.walletCoins, 1000 - bundlePrice);
      expect(result.state.ownedBundleIds, contains('pack_beige_rutio'));
      expect(
        result.state.ownedAssetIds,
        containsAll(<String>[
          'wallpaper_rutio_beige',
          'habit_card_warm_beige',
          'user_card_warm_beige',
        ]),
      );
    });

    test('purchaseBundle fails when balance is insufficient', () {
      final service = ShopCosmeticsService(
        state: const ShopCosmeticsState.initial(),
        walletCoins: 300,
      );

      final result = service.purchaseBundle('pack_beige_rutio');

      expect(result.status, ShopCosmeticsOperationStatus.insufficientCoins);
      expect(result.walletCoins, 300);
      expect(result.state, const ShopCosmeticsState.initial());
    });

    test('purchaseBundle fails when bundle is already owned', () {
      final service = ShopCosmeticsService(
        state: ShopCosmeticsState(
          ownedAssetIds: <String>[],
          ownedBundleIds: <String>['pack_beige_rutio'],
        ),
        walletCoins: 1000,
      );

      final result = service.purchaseBundle('pack_beige_rutio');

      expect(result.status, ShopCosmeticsOperationStatus.alreadyOwned);
      expect(result.walletCoins, 1000);
    });

    test('purchaseBundle completes a partially owned bundle with a discount',
        () {
      final service = ShopCosmeticsService(
        state: ShopCosmeticsState(
          ownedAssetIds: <String>['wallpaper_rutio_beige'],
          ownedBundleIds: <String>[],
        ),
        walletCoins: 1000,
      );
      final bundle = ShopAssetsCatalog.getBundleById('pack_beige_rutio')!;
      final quote = ShopBundleCompletionQuote.tryCreate(
        bundle: bundle,
        state: service.state,
      )!;
      final result = service.purchaseBundle('pack_beige_rutio');

      expect(service.canPurchaseBundle('pack_beige_rutio'), isTrue);
      expect(result.status, ShopCosmeticsOperationStatus.success);
      expect(
        result.state.ownedAssetIds,
        containsAll(<String>[
          'wallpaper_rutio_beige',
          'habit_card_warm_beige',
          'user_card_warm_beige',
        ]),
      );
      expect(result.state.ownedAssetIds.length, 3);
      expect(result.state.ownedBundleIds, contains('pack_beige_rutio'));
      expect(result.walletCoins, 1000 - quote.effectivePriceAmber);
    });

    test('purchaseBundle completes a two-owned bundle with the remaining item',
        () {
      final service = ShopCosmeticsService(
        state: ShopCosmeticsState(
          ownedAssetIds: <String>[
            'wallpaper_rutio_beige',
            'habit_card_warm_beige',
          ],
          ownedBundleIds: <String>[],
        ),
        walletCoins: 1000,
      );
      final quote = ShopBundleCompletionQuote.tryCreate(
        bundle: ShopAssetsCatalog.getBundleById('pack_beige_rutio')!,
        state: service.state,
      )!;

      final result = service.purchaseBundle('pack_beige_rutio');

      expect(result.status, ShopCosmeticsOperationStatus.success);
      expect(result.state.ownedAssetIds, containsAll(<String>[
        'wallpaper_rutio_beige',
        'habit_card_warm_beige',
        'user_card_warm_beige',
      ]));
      expect(result.state.ownedAssetIds.length, 3);
      expect(result.walletCoins, 1000 - quote.effectivePriceAmber);
    });

    test('purchaseBundle records a completed pack for zero coins', () {
      final service = ShopCosmeticsService(
        state: ShopCosmeticsState(
          ownedAssetIds: <String>[
            'wallpaper_rutio_beige',
            'habit_card_warm_beige',
            'user_card_warm_beige',
          ],
          ownedBundleIds: <String>[],
        ),
        walletCoins: 0,
      );

      final result = service.purchaseBundle('pack_beige_rutio');

      expect(result.status, ShopCosmeticsOperationStatus.success);
      expect(result.walletCoins, 0);
      expect(result.state.ownedBundleIds, contains('pack_beige_rutio'));
      expect(result.state.ownedAssetIds, hasLength(3));
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
    test('equipAsset works for wallpaper and habit card assets', () {
      final service = ShopCosmeticsService(
        state: ShopCosmeticsState(
          ownedAssetIds: <String>[
            'wallpaper_mist_blue',
            'wallpaper_soft_sage',
            'habit_card_warm_beige',
            'habit_card_soft_camel',
            'habit_card_lilac_dawn',
          ],
          ownedBundleIds: <String>[],
          equippedWallpaperId: 'wallpaper_mist_blue',
          equippedHabitCardSkinId: 'habit_card_warm_beige',
        ),
        walletCoins: 0,
      );

      final wallpaper = service.equipAsset('wallpaper_soft_sage');
      final habitCard = ShopCosmeticsService(
        state: wallpaper.state,
        walletCoins: 0,
      ).equipAsset('habit_card_soft_camel');

      expect(wallpaper.status, ShopCosmeticsOperationStatus.success);
      expect(wallpaper.state.equippedWallpaperId, 'wallpaper_soft_sage');
      expect(wallpaper.state.ownedAssetIds, contains('wallpaper_mist_blue'));

      expect(habitCard.status, ShopCosmeticsOperationStatus.success);
      expect(habitCard.state.equippedHabitCardSkinId, 'habit_card_soft_camel');
      expect(habitCard.state.ownedAssetIds, contains('habit_card_warm_beige'));

      final rareHabitCard = ShopCosmeticsService(
        state: habitCard.state,
        walletCoins: 0,
      ).equipAsset('habit_card_lilac_dawn');
      expect(rareHabitCard.status, ShopCosmeticsOperationStatus.success);
      expect(
        rareHabitCard.state.equippedHabitCardSkinId,
        'habit_card_lilac_dawn',
      );
    });

    test('equipAsset fails when asset is not owned', () {
      final service = ShopCosmeticsService(
        state: const ShopCosmeticsState.initial(),
        walletCoins: 0,
      );

      final result = service.equipAsset('wallpaper_mist_blue');

      expect(result.status, ShopCosmeticsOperationStatus.assetNotOwned);
    });

    test('equipAsset fails safely when id belongs to a bundle', () {
      final service = ShopCosmeticsService(
        state: const ShopCosmeticsState.initial(),
        walletCoins: 0,
      );

      final result = service.equipAsset('pack_beige_rutio');

      expect(result.status, ShopCosmeticsOperationStatus.assetNotFound);
    });

    test('unequipAsset clears the requested slot', () {
      final service = ShopCosmeticsService(
        state: ShopCosmeticsState(
          ownedAssetIds: <String>['wallpaper_mist_blue'],
          ownedBundleIds: <String>[],
          equippedWallpaperId: 'wallpaper_mist_blue',
        ),
        walletCoins: 0,
      );

      final result = service.unequipAsset(ShopAssetCategory.wallpaper);

      expect(result.status, ShopCosmeticsOperationStatus.success);
      expect(result.state.equippedWallpaperId, isNull);
      expect(result.state.ownedAssetIds, contains('wallpaper_mist_blue'));
    });

    test('asset ownership helper reports direct ownership only', () {
      final service = ShopCosmeticsService(
        state: ShopCosmeticsState(
          ownedAssetIds: <String>['habit_card_warm_beige'],
          ownedBundleIds: <String>[],
        ),
        walletCoins: 0,
      );

      expect(
        service.assetOwnershipState('habit_card_warm_beige'),
        ShopAssetOwnershipState.owned,
      );
      expect(service.isAssetOwned('habit_card_warm_beige'), isTrue);
      expect(service.isBundleOwned('pack_beige_rutio'), isFalse);
      expect(service.isBundlePartiallyOwned('pack_beige_rutio'), isTrue);
    });
  });
}
