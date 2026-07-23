import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/data/shop_assets_catalog.dart';
import 'package:rutio/features/shop/domain/models/shop_bundle_completion_quote.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_state.dart';

void main() {
  group('ShopBundleCompletionQuote', () {
    test('returns zero price when all bundle assets are already owned', () {
      final bundle = ShopAssetsCatalog.getBundleById('pack_beige_rutio')!;
      final quote = ShopBundleCompletionQuote.tryCreate(
        bundle: bundle,
        state: ShopCosmeticsState(
          ownedAssetIds: <String>[
            'wallpaper_rutio_beige',
            'habit_card_warm_beige',
            'user_card_warm_beige',
          ],
          ownedBundleIds: <String>[],
        ),
      )!;

      expect(quote.missingItemCount, 0);
      expect(quote.effectivePriceAmber, 0);
      expect(quote.isCompleteFromItems, isTrue);
      expect(quote.canEquip, isTrue);
      expect(quote.isExplicitlyOwned, isFalse);
    });

    test('uses the full bundle price when all assets are missing', () {
      final bundle = ShopAssetsCatalog.getBundleById('pack_beige_rutio')!;
      final quote = ShopBundleCompletionQuote.tryCreate(
        bundle: bundle,
        state: const ShopCosmeticsState.initial(),
      )!;

      expect(quote.missingItemCount, 3);
      expect(quote.effectivePriceAmber, bundle.priceAmber);
      expect(quote.isPartiallyOwned, isFalse);
    });

    test('calculates a proportional completion price for one owned asset',
        () {
      final bundle = ShopAssetsCatalog.getBundleById('pack_beige_rutio')!;
      final quote = ShopBundleCompletionQuote.tryCreate(
        bundle: bundle,
        state: ShopCosmeticsState(
          ownedAssetIds: <String>['wallpaper_rutio_beige'],
          ownedBundleIds: <String>[],
        ),
      )!;

      expect(quote.ownedItemCount, 1);
      expect(quote.missingItemCount, 2);
      expect(quote.missingRetailPriceAmber, 240);
      expect(
        quote.effectivePriceAmber,
        ((quote.missingRetailPriceAmber * bundle.priceAmber) /
                bundle.originalPriceAmber)
            .ceil(),
      );
      expect(quote.isPartiallyOwned, isTrue);
      expect(quote.canEquip, isFalse);
    });

    test('caps the proportional price at the missing retail price', () {
      final bundle = ShopAssetsCatalog.getBundleById('pack_beige_rutio')!;
      final expensiveBundle = bundle.copyWith(
        originalPriceAmber: 1,
        priceAmber: 9999,
      );
      final quote = ShopBundleCompletionQuote.tryCreate(
        bundle: expensiveBundle,
        state: ShopCosmeticsState(
          ownedAssetIds: <String>['wallpaper_rutio_beige'],
          ownedBundleIds: <String>[],
        ),
      )!;

      expect(quote.effectivePriceAmber, quote.missingRetailPriceAmber);
    });

    test('falls back to the missing retail price when original price is invalid',
        () {
      final bundle = ShopAssetsCatalog.getBundleById('pack_beige_rutio')!
          .copyWith(originalPriceAmber: 0);
      final quote = ShopBundleCompletionQuote.tryCreate(
        bundle: bundle,
        state: ShopCosmeticsState(
          ownedAssetIds: <String>['wallpaper_rutio_beige'],
          ownedBundleIds: <String>[],
        ),
      )!;

      expect(quote.effectivePriceAmber, quote.missingRetailPriceAmber);
    });

    test('keeps explicit ownership separate from item completion', () {
      final bundle = ShopAssetsCatalog.getBundleById('pack_beige_rutio')!;
      final quote = ShopBundleCompletionQuote.tryCreate(
        bundle: bundle,
        state: ShopCosmeticsState(
          ownedAssetIds: <String>[
            'wallpaper_rutio_beige',
            'habit_card_warm_beige',
            'user_card_warm_beige',
          ],
          ownedBundleIds: <String>['pack_beige_rutio'],
        ),
      )!;

      expect(quote.isExplicitlyOwned, isTrue);
      expect(quote.isCompleteFromItems, isFalse);
      expect(quote.canEquip, isTrue);
      expect(quote.effectivePriceAmber, 0);
    });
  });
}
