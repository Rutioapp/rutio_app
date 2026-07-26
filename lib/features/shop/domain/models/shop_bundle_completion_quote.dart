import 'package:rutio/features/shop/domain/models/shop_asset.dart';
import 'package:rutio/features/shop/domain/models/shop_asset_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_bundle.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_state.dart';

class ShopBundleCompletionQuote {
  ShopBundleCompletionQuote._({
    required this.bundle,
    required this.ownedAssets,
    required this.missingAssets,
    required this.ownedItemCount,
    required this.missingItemCount,
    required this.missingRetailPriceAmber,
    required this.effectivePriceAmber,
    required this.isExplicitlyOwned,
    required this.isCompleteFromItems,
    required this.isPartiallyOwned,
    required this.canEquip,
  });

  final ShopBundle bundle;
  final List<ShopAsset> ownedAssets;
  final List<ShopAsset> missingAssets;
  final int ownedItemCount;
  final int missingItemCount;
  final int missingRetailPriceAmber;
  final int effectivePriceAmber;
  final bool isExplicitlyOwned;
  final bool isCompleteFromItems;
  final bool isPartiallyOwned;
  final bool canEquip;

  static ShopBundleCompletionQuote? tryCreate({
    required ShopBundle bundle,
    required ShopCosmeticsState state,
    required Iterable<ShopAsset> catalogAssets,
    required Iterable<ShopBundle> catalogBundles,
  }) {
    final bundleAssets = _resolveBundleAssets(
      bundle,
      catalogAssets,
    );
    if (bundleAssets == null) return null;

    final ownedAssets = <ShopAsset>[];
    final missingAssets = <ShopAsset>[];
    for (final asset in bundleAssets) {
      final owned = state.isAssetOwned(
        asset.id,
        bundles: catalogBundles,
      );
      if (owned) {
        ownedAssets.add(asset);
      } else {
        missingAssets.add(asset);
      }
    }

    final ownedItemCount = ownedAssets.length;
    final missingItemCount = missingAssets.length;
    final missingRetailPriceAmber =
        missingAssets.fold<int>(0, (int total, ShopAsset asset) {
      return total + asset.priceAmber;
    });
    final isExplicitlyOwned = state.isBundleOwned(bundle.id);
    final isCompleteFromItems = !isExplicitlyOwned && missingItemCount == 0;
    final isPartiallyOwned =
        !isExplicitlyOwned && missingItemCount > 0 && missingItemCount < 3;
    final effectivePriceAmber = _effectivePrice(
      bundle: bundle,
      missingRetailPriceAmber: missingRetailPriceAmber,
      missingItemCount: missingItemCount,
    );

    return ShopBundleCompletionQuote._(
      bundle: bundle,
      ownedAssets: List<ShopAsset>.unmodifiable(ownedAssets),
      missingAssets: List<ShopAsset>.unmodifiable(missingAssets),
      ownedItemCount: ownedItemCount,
      missingItemCount: missingItemCount,
      missingRetailPriceAmber: missingRetailPriceAmber,
      effectivePriceAmber: effectivePriceAmber,
      isExplicitlyOwned: isExplicitlyOwned,
      isCompleteFromItems: isCompleteFromItems,
      isPartiallyOwned: isPartiallyOwned,
      canEquip: isExplicitlyOwned || isCompleteFromItems,
    );
  }

  static List<ShopAsset>? _resolveBundleAssets(
    ShopBundle bundle,
    Iterable<ShopAsset> catalogAssets,
  ) {
    final assetsById = <String, ShopAsset>{
      for (final asset in catalogAssets) asset.id: asset,
    };
    final wallpaper = assetsById[bundle.wallpaperItemId];
    final habitCard = assetsById[bundle.habitCardItemId];
    final userCard = assetsById[bundle.userCardItemId];
    if (wallpaper == null ||
        habitCard == null ||
        userCard == null ||
        wallpaper.category != ShopAssetCategory.wallpaper ||
        habitCard.category != ShopAssetCategory.habitCard ||
        userCard.category != ShopAssetCategory.userCard) {
      return null;
    }
    return <ShopAsset>[wallpaper, habitCard, userCard];
  }

  static int _effectivePrice({
    required ShopBundle bundle,
    required int missingRetailPriceAmber,
    required int missingItemCount,
  }) {
    if (missingItemCount == 0) return 0;
    if (missingItemCount == 3) return bundle.priceAmber;
    if (missingRetailPriceAmber <= 0) return 0;
    if (bundle.originalPriceAmber <= 0) return missingRetailPriceAmber;

    final price = ((missingRetailPriceAmber * bundle.priceAmber) /
            bundle.originalPriceAmber)
        .ceil();
    if (price < 0) return 0;
    if (price > missingRetailPriceAmber) return missingRetailPriceAmber;
    return price;
  }
}
