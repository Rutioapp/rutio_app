import 'package:flutter/foundation.dart';

import '../../domain/models/shop_asset.dart';
import '../../domain/models/shop_asset_enums.dart';
import '../../domain/models/shop_bundle.dart';
import 'shop_cloud_dtos.dart';

@immutable
class ShopResolvedCosmeticsCatalog {
  const ShopResolvedCosmeticsCatalog({
    required this.assets,
    required this.bundles,
  });

  const ShopResolvedCosmeticsCatalog.empty()
      : assets = const <ShopAsset>[],
        bundles = const <ShopBundle>[];

  final List<ShopAsset> assets;
  final List<ShopBundle> bundles;
}

class ShopCosmeticsCatalogResolver {
  const ShopCosmeticsCatalogResolver();

  ShopResolvedCosmeticsCatalog resolve({
    required Iterable<ShopAsset> localAssets,
    required Iterable<ShopBundle> localBundles,
    required Iterable<RemoteShopItemDto> remoteItems,
    required Iterable<RemoteShopBundleDto> remoteBundles,
    Iterable<RemoteShopBundleItemDto> remoteBundleItems =
        const <RemoteShopBundleItemDto>[],
  }) {
    final localAssetsById = <String, ShopAsset>{
      for (final asset in localAssets) asset.id: asset,
    };
    final localBundlesById = <String, ShopBundle>{
      for (final bundle in localBundles) bundle.id: bundle,
    };
    final remoteBundleItemsByBundleId =
        _bundleItemsByBundleId(remoteBundleItems);

    final resolvedAssets = <ShopAsset>[];
    for (final remote in remoteItems) {
      final asset = _resolveAsset(
        remote: remote,
        localAssetsById: localAssetsById,
      );
      if (asset == null) continue;
      resolvedAssets.add(asset);
    }

    final resolvedBundles = <ShopBundle>[];
    for (final remote in remoteBundles) {
      final bundle = _resolveBundle(
        remote: remote,
        localBundlesById: localBundlesById,
        localAssetsById: localAssetsById,
        remoteBundleItemsByBundleId: remoteBundleItemsByBundleId,
      );
      if (bundle == null) continue;
      resolvedBundles.add(bundle);
    }

    resolvedAssets.sort(_compareAssets);
    resolvedBundles.sort(_compareBundles);

    return ShopResolvedCosmeticsCatalog(
      assets: List<ShopAsset>.unmodifiable(resolvedAssets),
      bundles: List<ShopBundle>.unmodifiable(resolvedBundles),
    );
  }

  ShopAsset? _resolveAsset({
    required RemoteShopItemDto remote,
    required Map<String, ShopAsset> localAssetsById,
  }) {
    if (!remote.isActive || remote.isUtility) {
      return null;
    }

    final local = localAssetsById[remote.id];
    if (local == null) return null;
    final category = _categoryForRemoteItem(remote.category);
    if (category == null || local.category != category) return null;
    if (!_slotMatchesRemote(local.category, remote.equipSlot)) return null;
    if (remote.rarity == null ||
        remote.rarity == RemoteShopItemRarity.unknown) {
      return null;
    }

    return local.copyWith(
      priceAmber: remote.priceCoins,
      rarity: _mapRarity(remote.rarity!),
      isPurchasable: remote.isActive,
      sortOrder: remote.sortOrder,
    );
  }

  ShopBundle? _resolveBundle({
    required RemoteShopBundleDto remote,
    required Map<String, ShopBundle> localBundlesById,
    required Map<String, ShopAsset> localAssetsById,
    required Map<String, List<RemoteShopBundleItemDto>>
        remoteBundleItemsByBundleId,
  }) {
    if (!remote.isActive) {
      return null;
    }

    final local = localBundlesById[remote.id];
    if (local == null) return null;

    final remoteItems = remoteBundleItemsByBundleId[remote.id];
    if (remoteItems == null || remoteItems.length != 3) {
      return null;
    }

    final resolvedComposition = <RemoteShopBundleItemDto>[];
    for (final slot in <RemoteShopEquipSlot>[
      RemoteShopEquipSlot.screenBackground,
      RemoteShopEquipSlot.habitCardBackground,
      RemoteShopEquipSlot.userCardBackground,
    ]) {
      final item = remoteItems.firstWhere(
        (item) => item.slot == slot,
        orElse: () => const RemoteShopBundleItemDto(
          bundleId: '',
          itemId: '',
          slot: RemoteShopEquipSlot.unknown,
        ),
      );
      if (item.slot == RemoteShopEquipSlot.unknown) {
        return null;
      }
      final asset = localAssetsById[item.itemId];
      if (asset == null) return null;
      if (!_slotMatchesRemote(asset.category, slot)) return null;
      resolvedComposition.add(item);
    }

    final wallpaper = localAssetsById[resolvedComposition[0].itemId];
    final habitCard = localAssetsById[resolvedComposition[1].itemId];
    final userCard = localAssetsById[resolvedComposition[2].itemId];
    if (wallpaper == null || habitCard == null || userCard == null) {
      return null;
    }

    final originalPrice = remote.originalPriceCoins;
    final discountedPrice = remote.priceCoins;
    final discountPercentage =
        _discountPercentageFromPrices(discountedPrice, originalPrice);

    return local.copyWith(
      familyId: remote.familyId,
      rarity: _mapRarity(remote.rarity),
      wallpaperItemId: wallpaper.id,
      habitCardItemId: habitCard.id,
      userCardItemId: userCard.id,
      originalPriceAmber: originalPrice,
      priceAmber: discountedPrice,
      discountPercentage: discountPercentage,
      isPurchasable: remote.isActive,
      sortOrder: remote.sortOrder,
    );
  }

  Map<String, List<RemoteShopBundleItemDto>> _bundleItemsByBundleId(
    Iterable<RemoteShopBundleItemDto> remoteBundleItems,
  ) {
    final byBundleId = <String, List<RemoteShopBundleItemDto>>{};
    for (final item in remoteBundleItems) {
      byBundleId
          .putIfAbsent(item.bundleId, () => <RemoteShopBundleItemDto>[])
          .add(item);
    }
    return byBundleId;
  }

  ShopAssetCategory? _categoryForRemoteItem(RemoteShopItemCategory category) {
    return switch (category) {
      RemoteShopItemCategory.screenBackground => ShopAssetCategory.wallpaper,
      RemoteShopItemCategory.habitCardBackground => ShopAssetCategory.habitCard,
      RemoteShopItemCategory.userCardBackground => ShopAssetCategory.userCard,
      RemoteShopItemCategory.utility || RemoteShopItemCategory.unknown => null,
    };
  }

  bool _slotMatchesRemote(
    ShopAssetCategory category,
    RemoteShopEquipSlot? slot,
  ) {
    if (slot == null) return false;
    return switch (category) {
      ShopAssetCategory.wallpaper =>
        slot == RemoteShopEquipSlot.screenBackground,
      ShopAssetCategory.habitCard =>
        slot == RemoteShopEquipSlot.habitCardBackground,
      ShopAssetCategory.userCard =>
        slot == RemoteShopEquipSlot.userCardBackground,
    };
  }

  ShopAssetRarity _mapRarity(RemoteShopItemRarity rarity) {
    return switch (rarity) {
      RemoteShopItemRarity.common => ShopAssetRarity.common,
      RemoteShopItemRarity.uncommon => ShopAssetRarity.common,
      RemoteShopItemRarity.rare => ShopAssetRarity.rare,
      RemoteShopItemRarity.epic => ShopAssetRarity.epic,
      RemoteShopItemRarity.legendary => ShopAssetRarity.legendary,
      RemoteShopItemRarity.unknown => ShopAssetRarity.common,
    };
  }

  int _discountPercentageFromPrices(int priceCoins, int originalPriceCoins) {
    if (priceCoins < 0 || originalPriceCoins <= 0) return 0;
    if (priceCoins >= originalPriceCoins) return 0;
    final discount =
        (((originalPriceCoins - priceCoins) * 100) / originalPriceCoins)
            .round();
    if (discount < 0) return 0;
    if (discount > 100) return 100;
    return discount;
  }

  int _compareAssets(ShopAsset a, ShopAsset b) {
    final sortOrderCompare = a.sortOrder.compareTo(b.sortOrder);
    if (sortOrderCompare != 0) return sortOrderCompare;
    return a.id.compareTo(b.id);
  }

  int _compareBundles(ShopBundle a, ShopBundle b) {
    final sortOrderCompare = a.sortOrder.compareTo(b.sortOrder);
    if (sortOrderCompare != 0) return sortOrderCompare;
    return a.id.compareTo(b.id);
  }
}
