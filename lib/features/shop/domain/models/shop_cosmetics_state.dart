import 'package:rutio/features/shop/domain/models/shop_asset.dart';
import 'package:rutio/features/shop/domain/models/shop_asset_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_bundle.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_model_utils.dart';

const Object _shopCosmeticsUnset = Object();

class ShopCosmeticsState {
  ShopCosmeticsState({
    required List<String> ownedAssetIds,
    required List<String> ownedBundleIds,
    this.equippedWallpaperId,
    this.equippedHabitCardSkinId,
    this.equippedUserCardSkinId,
  })  : ownedAssetIds = List<String>.unmodifiable(_normalizeIds(ownedAssetIds)),
        ownedBundleIds = List<String>.unmodifiable(_normalizeIds(ownedBundleIds));

  const ShopCosmeticsState.initial()
      : ownedAssetIds = const <String>[],
        ownedBundleIds = const <String>[],
        equippedWallpaperId = null,
        equippedHabitCardSkinId = null,
        equippedUserCardSkinId = null;

  final List<String> ownedAssetIds;
  final List<String> ownedBundleIds;
  final String? equippedWallpaperId;
  final String? equippedHabitCardSkinId;
  final String? equippedUserCardSkinId;

  bool isAssetOwned(String assetId, {Iterable<ShopBundle>? bundles}) {
    if (ownedAssetIds.contains(assetId)) return true;
    final availableBundles = bundles ?? const <ShopBundle>[];
    for (final bundle in availableBundles) {
      if (!ownedBundleIds.contains(bundle.id)) continue;
      if (bundle.assetIds.contains(assetId)) return true;
    }
    return false;
  }

  bool isBundleOwned(String bundleId) => ownedBundleIds.contains(bundleId);

  String? getEquippedAssetIdForCategory(ShopAssetCategory category) {
    switch (category) {
      case ShopAssetCategory.wallpaper:
        return equippedWallpaperId;
      case ShopAssetCategory.habitCard:
        return equippedHabitCardSkinId;
      case ShopAssetCategory.userCard:
        return equippedUserCardSkinId;
    }
  }

  ShopCosmeticsState copyWith({
    List<String>? ownedAssetIds,
    List<String>? ownedBundleIds,
    Object? equippedWallpaperId = _shopCosmeticsUnset,
    Object? equippedHabitCardSkinId = _shopCosmeticsUnset,
    Object? equippedUserCardSkinId = _shopCosmeticsUnset,
  }) {
    return ShopCosmeticsState(
      ownedAssetIds: ownedAssetIds ?? this.ownedAssetIds,
      ownedBundleIds: ownedBundleIds ?? this.ownedBundleIds,
      equippedWallpaperId: identical(equippedWallpaperId, _shopCosmeticsUnset)
          ? this.equippedWallpaperId
          : equippedWallpaperId as String?,
      equippedHabitCardSkinId: identical(
        equippedHabitCardSkinId,
        _shopCosmeticsUnset,
      )
          ? this.equippedHabitCardSkinId
          : equippedHabitCardSkinId as String?,
      equippedUserCardSkinId: identical(
        equippedUserCardSkinId,
        _shopCosmeticsUnset,
      )
          ? this.equippedUserCardSkinId
          : equippedUserCardSkinId as String?,
    );
  }

  factory ShopCosmeticsState.fromJson(Map<String, dynamic> json) {
    return ShopCosmeticsState(
      ownedAssetIds: shopJsonList<String>(
        json['ownedAssetIds'],
        (dynamic value) => value.toString(),
      ),
      ownedBundleIds: shopJsonList<String>(
        json['ownedBundleIds'],
        (dynamic value) => value.toString(),
      ),
      equippedWallpaperId: json['equippedWallpaperId']?.toString(),
      equippedHabitCardSkinId: json['equippedHabitCardSkinId']?.toString(),
      equippedUserCardSkinId: json['equippedUserCardSkinId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'ownedAssetIds': ownedAssetIds,
      'ownedBundleIds': ownedBundleIds,
      'equippedWallpaperId': equippedWallpaperId,
      'equippedHabitCardSkinId': equippedHabitCardSkinId,
      'equippedUserCardSkinId': equippedUserCardSkinId,
    };
  }

  ShopAssetOwnershipState assetOwnershipState(
    ShopAsset asset, {
    required Iterable<ShopBundle> bundles,
  }) {
    final equippedAssetId = getEquippedAssetIdForCategory(asset.category);
    if (equippedAssetId == asset.id) {
      return ShopAssetOwnershipState.equipped;
    }
    if (ownedAssetIds.contains(asset.id)) {
      return ShopAssetOwnershipState.owned;
    }
    for (final bundle in bundles) {
      if (!ownedBundleIds.contains(bundle.id)) continue;
      if (bundle.assetIds.contains(asset.id)) {
        return ShopAssetOwnershipState.includedInOwnedBundle;
      }
    }
    return ShopAssetOwnershipState.locked;
  }

  static List<String> _normalizeIds(List<String> values) {
    final normalized = <String>{};
    for (final value in values) {
      final cleaned = value.trim();
      if (cleaned.isEmpty) continue;
      normalized.add(cleaned);
    }
    return normalized.toList(growable: false);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShopCosmeticsState &&
        shopDeepEquals(other.ownedAssetIds, ownedAssetIds) &&
        shopDeepEquals(other.ownedBundleIds, ownedBundleIds) &&
        other.equippedWallpaperId == equippedWallpaperId &&
        other.equippedHabitCardSkinId == equippedHabitCardSkinId &&
        other.equippedUserCardSkinId == equippedUserCardSkinId;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(ownedAssetIds),
        Object.hashAll(ownedBundleIds),
        equippedWallpaperId,
        equippedHabitCardSkinId,
        equippedUserCardSkinId,
      );
}
