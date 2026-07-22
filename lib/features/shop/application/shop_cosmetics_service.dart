import 'package:rutio/features/shop/data/shop_assets_catalog.dart';
import 'package:rutio/features/shop/domain/models/shop_asset.dart';
import 'package:rutio/features/shop/domain/models/shop_asset_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_bundle.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_operation_result.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_state.dart';

class ShopCosmeticsService {
  ShopCosmeticsService({
    required this.state,
    required this.walletCoins,
  });

  final ShopCosmeticsState state;
  final int walletCoins;

  bool canPurchaseAsset(String assetId) {
    final asset = ShopAssetsCatalog.getAssetById(assetId);
    if (asset == null) return false;
    if (state.isAssetOwned(assetId, bundles: ShopAssetsCatalog.allBundles)) {
      return false;
    }
    return walletCoins >= asset.priceAmber;
  }

  bool canPurchaseBundle(String bundleId) {
    final bundle = ShopAssetsCatalog.getBundleById(bundleId);
    if (bundle == null) return false;
    if (state.isBundleOwned(bundleId)) return false;
    if (_bundleContainsOwnedAssets(bundle)) return false;
    return walletCoins >= bundle.priceAmber;
  }

  bool isAssetOwned(String assetId) {
    return state.isAssetOwned(assetId, bundles: ShopAssetsCatalog.allBundles);
  }

  bool isBundleOwned(String bundleId) {
    return state.isBundleOwned(bundleId);
  }

  bool isBundlePartiallyOwned(String bundleId) {
    final bundle = ShopAssetsCatalog.getBundleById(bundleId);
    if (bundle == null) return false;
    if (state.isBundleOwned(bundleId)) return false;
    return _bundleContainsOwnedAssets(bundle);
  }

  ShopAsset? getEquippedAssetForCategory(ShopAssetCategory category) {
    final assetId = state.getEquippedAssetIdForCategory(category);
    if (assetId == null) return null;
    return ShopAssetsCatalog.getAssetById(assetId);
  }

  ShopAssetOwnershipState assetOwnershipState(String assetId) {
    final asset = ShopAssetsCatalog.getAssetById(assetId);
    if (asset == null) return ShopAssetOwnershipState.locked;
    return state.assetOwnershipState(
      asset,
      bundles: ShopAssetsCatalog.allBundles,
    );
  }

  ShopCosmeticsOperationResult purchaseAsset(String assetId) {
    final asset = ShopAssetsCatalog.getAssetById(assetId);
    if (asset == null) {
      return _result(ShopCosmeticsOperationStatus.assetNotFound);
    }
    if (state.isAssetOwned(assetId, bundles: ShopAssetsCatalog.allBundles)) {
      return _result(ShopCosmeticsOperationStatus.alreadyOwned,
          assetId: assetId);
    }
    if (walletCoins < asset.priceAmber) {
      return _result(
        ShopCosmeticsOperationStatus.insufficientCoins,
        assetId: assetId,
      );
    }

    final nextState = state.copyWith(
      ownedAssetIds: <String>[...state.ownedAssetIds, assetId],
    );
    return _result(
      ShopCosmeticsOperationStatus.success,
      state: nextState,
      walletCoins: walletCoins - asset.priceAmber,
      assetId: assetId,
    );
  }

  ShopCosmeticsOperationResult purchaseBundle(String bundleId) {
    final bundle = ShopAssetsCatalog.getBundleById(bundleId);
    if (bundle == null) {
      return _result(ShopCosmeticsOperationStatus.bundleNotFound);
    }
    if (state.isBundleOwned(bundleId)) {
      return _result(ShopCosmeticsOperationStatus.alreadyOwned,
          bundleId: bundleId);
    }
    if (_bundleContainsOwnedAssets(bundle)) {
      return _result(
        ShopCosmeticsOperationStatus.bundleContainsOwnedAssets,
        bundleId: bundleId,
      );
    }
    if (walletCoins < bundle.priceAmber) {
      return _result(
        ShopCosmeticsOperationStatus.insufficientCoins,
        bundleId: bundleId,
      );
    }

    final nextState = state.copyWith(
      ownedBundleIds: <String>[...state.ownedBundleIds, bundleId],
    );
    return _result(
      ShopCosmeticsOperationStatus.success,
      state: nextState,
      walletCoins: walletCoins - bundle.priceAmber,
      bundleId: bundleId,
    );
  }

  bool _bundleContainsOwnedAssets(ShopBundle bundle) {
    for (final assetId in bundle.assetIds) {
      if (state.isAssetOwned(assetId, bundles: ShopAssetsCatalog.allBundles)) {
        return true;
      }
    }
    return false;
  }

  ShopCosmeticsOperationResult equipAsset(String assetId) {
    final asset = ShopAssetsCatalog.getAssetById(assetId);
    if (asset == null) {
      return _result(ShopCosmeticsOperationStatus.assetNotFound);
    }
    if (!isAssetOwned(assetId)) {
      return _result(
        ShopCosmeticsOperationStatus.assetNotOwned,
        assetId: assetId,
      );
    }

    final nextState = _equip(asset);
    return _result(
      ShopCosmeticsOperationStatus.success,
      state: nextState,
      assetId: assetId,
    );
  }

  ShopCosmeticsOperationResult equipBundle(String bundleId) {
    final bundle = ShopAssetsCatalog.getBundleById(bundleId);
    if (bundle == null) {
      return _result(ShopCosmeticsOperationStatus.bundleNotFound);
    }
    if (!isBundleOwned(bundleId)) {
      return _result(
        ShopCosmeticsOperationStatus.assetNotOwned,
        bundleId: bundleId,
      );
    }

    final wallpaper = ShopAssetsCatalog.getAssetById(bundle.wallpaperItemId);
    final habitCard = ShopAssetsCatalog.getAssetById(bundle.habitCardItemId);
    final userCard = ShopAssetsCatalog.getAssetById(bundle.userCardItemId);
    if (wallpaper == null ||
        habitCard == null ||
        userCard == null ||
        wallpaper.category != ShopAssetCategory.wallpaper ||
        habitCard.category != ShopAssetCategory.habitCard ||
        userCard.category != ShopAssetCategory.userCard) {
      return _result(
        ShopCosmeticsOperationStatus.bundleNotFound,
        bundleId: bundleId,
      );
    }

    final nextState = state.copyWith(
      equippedWallpaperId: wallpaper.id,
      equippedHabitCardSkinId: habitCard.id,
      equippedUserCardSkinId: userCard.id,
    );
    return _result(
      ShopCosmeticsOperationStatus.success,
      state: nextState,
      bundleId: bundleId,
    );
  }

  ShopCosmeticsOperationResult unequipAsset(ShopAssetCategory category) {
    final nextState = switch (category) {
      ShopAssetCategory.wallpaper => state.copyWith(equippedWallpaperId: null),
      ShopAssetCategory.habitCard =>
        state.copyWith(equippedHabitCardSkinId: null),
      ShopAssetCategory.userCard =>
        state.copyWith(equippedUserCardSkinId: null),
    };

    return _result(ShopCosmeticsOperationStatus.success, state: nextState);
  }

  ShopCosmeticsState _equip(ShopAsset asset) {
    return switch (asset.category) {
      ShopAssetCategory.wallpaper =>
        state.copyWith(equippedWallpaperId: asset.id),
      ShopAssetCategory.habitCard =>
        state.copyWith(equippedHabitCardSkinId: asset.id),
      ShopAssetCategory.userCard =>
        state.copyWith(equippedUserCardSkinId: asset.id),
    };
  }

  ShopCosmeticsOperationResult _result(
    ShopCosmeticsOperationStatus status, {
    ShopCosmeticsState? state,
    int? walletCoins,
    String? assetId,
    String? bundleId,
  }) {
    return ShopCosmeticsOperationResult(
      status: status,
      state: state ?? this.state,
      walletCoins: walletCoins ?? this.walletCoins,
      assetId: assetId,
      bundleId: bundleId,
    );
  }
}
