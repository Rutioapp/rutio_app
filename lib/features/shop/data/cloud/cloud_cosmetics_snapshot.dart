import 'package:flutter/foundation.dart';

import '../../domain/models/shop_cosmetics_state.dart';
import '../../domain/models/shop_asset_enums.dart';
import '../shop_assets_catalog.dart';
import 'shop_cloud_dtos.dart';
import 'shop_cloud_snapshot.dart';

@immutable
class CloudCosmeticsSnapshot {
  const CloudCosmeticsSnapshot({
    required this.userId,
    required this.ownedAssetIds,
    required this.ownedBundleIds,
    required this.catalogBundles,
    required this.equippedWallpaperId,
    required this.equippedHabitCardSkinId,
    required this.equippedUserCardSkinId,
    required this.catalogVersion,
    required this.fetchedAt,
    required this.updatedAt,
  });

  final String userId;
  final List<String> ownedAssetIds;
  final List<String> ownedBundleIds;
  final List<RemoteShopBundleDto> catalogBundles;
  final String? equippedWallpaperId;
  final String? equippedHabitCardSkinId;
  final String? equippedUserCardSkinId;
  final int? catalogVersion;
  final DateTime fetchedAt;
  final DateTime updatedAt;

  factory CloudCosmeticsSnapshot.fromShopSnapshot(
    ShopCloudSnapshot snapshot,
  ) {
    final ownedAssetIds = _resolveOwnedAssetIds(snapshot.inventory);
    final ownedBundleIds = _resolveOwnedBundleIds(snapshot.ownedBundles);
    final catalogBundles =
        List<RemoteShopBundleDto>.unmodifiable(snapshot.catalogBundles);
    final equipped = _resolveEquippedCosmetics(
      snapshot.equippedCosmetics,
      ownedAssetIds,
    );

    return CloudCosmeticsSnapshot(
      userId: snapshot.authenticatedUserId,
      ownedAssetIds: List<String>.unmodifiable(ownedAssetIds),
      ownedBundleIds: List<String>.unmodifiable(ownedBundleIds),
      catalogBundles: catalogBundles,
      equippedWallpaperId: equipped.wallpaper,
      equippedHabitCardSkinId: equipped.habitCard,
      equippedUserCardSkinId: equipped.userCard,
      catalogVersion: snapshot.catalogVersion,
      fetchedAt: snapshot.fetchedAt,
      updatedAt: _resolveUpdatedAt(snapshot),
    );
  }

  ShopCosmeticsState toState({
    Iterable<String>? ownedBundleIds,
  }) {
    return ShopCosmeticsState(
      ownedAssetIds: ownedAssetIds,
      ownedBundleIds: (ownedBundleIds ?? this.ownedBundleIds).toList(
        growable: false,
      ),
      equippedWallpaperId: equippedWallpaperId,
      equippedHabitCardSkinId: equippedHabitCardSkinId,
      equippedUserCardSkinId: equippedUserCardSkinId,
    );
  }

  String? equippedItemIdForCategory(ShopAssetCategory category) {
    return switch (category) {
      ShopAssetCategory.wallpaper => equippedWallpaperId,
      ShopAssetCategory.habitCard => equippedHabitCardSkinId,
      ShopAssetCategory.userCard => equippedUserCardSkinId,
    };
  }

  CloudCosmeticsSnapshot copyWith({
    List<String>? ownedAssetIds,
    List<String>? ownedBundleIds,
    List<RemoteShopBundleDto>? catalogBundles,
    Object? equippedWallpaperId = _cloudCosmeticsUnset,
    Object? equippedHabitCardSkinId = _cloudCosmeticsUnset,
    Object? equippedUserCardSkinId = _cloudCosmeticsUnset,
    int? catalogVersion,
    DateTime? fetchedAt,
    DateTime? updatedAt,
  }) {
    return CloudCosmeticsSnapshot(
      userId: userId,
      ownedAssetIds:
          List<String>.unmodifiable(ownedAssetIds ?? this.ownedAssetIds),
      ownedBundleIds:
          List<String>.unmodifiable(ownedBundleIds ?? this.ownedBundleIds),
      catalogBundles: List<RemoteShopBundleDto>.unmodifiable(
        catalogBundles ?? this.catalogBundles,
      ),
      equippedWallpaperId: identical(equippedWallpaperId, _cloudCosmeticsUnset)
          ? this.equippedWallpaperId
          : equippedWallpaperId as String?,
      equippedHabitCardSkinId:
          identical(equippedHabitCardSkinId, _cloudCosmeticsUnset)
              ? this.equippedHabitCardSkinId
              : equippedHabitCardSkinId as String?,
      equippedUserCardSkinId:
          identical(equippedUserCardSkinId, _cloudCosmeticsUnset)
              ? this.equippedUserCardSkinId
              : equippedUserCardSkinId as String?,
      catalogVersion: catalogVersion ?? this.catalogVersion,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'userId': userId,
      'ownedAssetIds': ownedAssetIds,
      'ownedBundleIds': ownedBundleIds,
      'catalogBundles': catalogBundles.map((bundle) => bundle.toJson()).toList(
            growable: false,
          ),
      'equippedWallpaperId': equippedWallpaperId,
      'equippedHabitCardSkinId': equippedHabitCardSkinId,
      'equippedUserCardSkinId': equippedUserCardSkinId,
      'catalogVersion': catalogVersion,
      'fetchedAt': fetchedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory CloudCosmeticsSnapshot.fromJson(Map<String, dynamic> json) {
    final userId = (json['userId'] ?? '').toString().trim();
    final fetchedAt = DateTime.tryParse((json['fetchedAt'] ?? '').toString());
    final updatedAt = DateTime.tryParse((json['updatedAt'] ?? '').toString());
    if (userId.isEmpty || fetchedAt == null || updatedAt == null) {
      throw const FormatException('Invalid cloud cosmetics snapshot.');
    }

    return CloudCosmeticsSnapshot(
      userId: userId,
      ownedAssetIds: List<String>.unmodifiable(_normalizeOwnedAssetIds(
        (json['ownedAssetIds'] as List?)?.map((value) => value.toString()) ??
            const <String>[],
      )),
      ownedBundleIds: List<String>.unmodifiable(_normalizeOwnedBundleIds(
        (json['ownedBundleIds'] as List?)?.map((value) => value.toString()) ??
            const <String>[],
      )),
      catalogBundles: List<RemoteShopBundleDto>.unmodifiable(
        ((json['catalogBundles'] as List?) ?? const <dynamic>[])
            .whereType<Map>()
            .map(
              (value) => RemoteShopBundleDto.fromJson(
                Map<String, dynamic>.from(value.cast<String, dynamic>()),
              ),
            )
            .toList(growable: false),
      ),
      equippedWallpaperId: _normalizeEquippedId(
        json['equippedWallpaperId']?.toString(),
        ShopAssetCategory.wallpaper,
      ),
      equippedHabitCardSkinId: _normalizeEquippedId(
        json['equippedHabitCardSkinId']?.toString(),
        ShopAssetCategory.habitCard,
      ),
      equippedUserCardSkinId: _normalizeEquippedId(
        json['equippedUserCardSkinId']?.toString(),
        ShopAssetCategory.userCard,
      ),
      catalogVersion: (json['catalogVersion'] as num?)?.toInt(),
      fetchedAt: fetchedAt,
      updatedAt: updatedAt,
    );
  }
}

class CloudCosmeticsSnapshotComparison {
  const CloudCosmeticsSnapshotComparison({
    required this.isNewerOrEqual,
    required this.replacedBy,
  });

  final bool isNewerOrEqual;
  final CloudCosmeticsSnapshot? replacedBy;
}

CloudCosmeticsSnapshotComparison compareCloudCosmeticsSnapshots(
  CloudCosmeticsSnapshot next,
  CloudCosmeticsSnapshot? current,
) {
  if (current == null) {
    return CloudCosmeticsSnapshotComparison(
      isNewerOrEqual: true,
      replacedBy: null,
    );
  }

  final updatedComparison = next.updatedAt.compareTo(current.updatedAt);
  if (updatedComparison > 0) {
    return CloudCosmeticsSnapshotComparison(
      isNewerOrEqual: true,
      replacedBy: current,
    );
  }
  if (updatedComparison < 0) {
    return CloudCosmeticsSnapshotComparison(
      isNewerOrEqual: false,
      replacedBy: current,
    );
  }

  final fetchedComparison = next.fetchedAt.compareTo(current.fetchedAt);
  if (fetchedComparison >= 0) {
    return CloudCosmeticsSnapshotComparison(
      isNewerOrEqual: true,
      replacedBy: current,
    );
  }

  return CloudCosmeticsSnapshotComparison(
    isNewerOrEqual: false,
    replacedBy: current,
  );
}

DateTime _resolveUpdatedAt(ShopCloudSnapshot snapshot) {
  // `fetchedAt` is only the read time on this client. It must not make a stale
  // remote read look newer than a confirmed state that already reached memory.
  final values = <DateTime>[];
  if (snapshot.wallet != null) {
    values.add(snapshot.wallet!.updatedAt);
  }
  values.addAll(snapshot.inventory.map((row) => row.updatedAt));
  values.addAll(snapshot.equippedCosmetics.map((row) => row.equippedAt));
  values.addAll(snapshot.ownedBundles.map((row) => row.updatedAt));
  values.sort();
  return values.last.toUtc();
}

List<String> _resolveOwnedAssetIds(List<RemoteInventoryItemDto> inventory) {
  final assetIds = <String>{};
  final knownAssetIds =
      ShopAssetsCatalog.allAssets.map((asset) => asset.id).toSet();
  for (final row in inventory) {
    if (row.quantity <= 0) continue;
    if (!knownAssetIds.contains(row.itemId)) continue;
    assetIds.add(row.itemId);
  }

  final sorted = List<String>.from(assetIds);
  sorted.sort((a, b) {
    final aIndex = _assetIndex[a] ?? 1 << 30;
    final bIndex = _assetIndex[b] ?? 1 << 30;
    final compare = aIndex.compareTo(bIndex);
    if (compare != 0) return compare;
    return a.compareTo(b);
  });
  return sorted;
}

List<String> _resolveOwnedBundleIds(List<RemoteOwnedBundleDto> bundles) {
  final knownBundleIds =
      ShopAssetsCatalog.allBundles.map((bundle) => bundle.id).toSet();
  final bundleIds = <String>{};
  for (final row in bundles) {
    if (!knownBundleIds.contains(row.bundleId)) continue;
    bundleIds.add(row.bundleId);
  }

  final sorted = List<String>.from(bundleIds);
  sorted.sort((a, b) {
    final aIndex = _bundleIndex[a] ?? 1 << 30;
    final bIndex = _bundleIndex[b] ?? 1 << 30;
    final compare = aIndex.compareTo(bIndex);
    if (compare != 0) return compare;
    return a.compareTo(b);
  });
  return sorted;
}

({String? wallpaper, String? habitCard, String? userCard})
    _resolveEquippedCosmetics(
  List<RemoteEquippedCosmeticDto> equippedCosmetics,
  List<String> ownedAssetIds,
) {
  String? wallpaper;
  String? habitCard;
  String? userCard;
  final owned = ownedAssetIds.toSet();
  for (final row in equippedCosmetics) {
    if (!owned.contains(row.itemId)) continue;
    final asset = ShopAssetsCatalog.getAssetById(row.itemId);
    if (asset == null) continue;
    switch (asset.category) {
      case ShopAssetCategory.wallpaper:
        wallpaper ??= row.itemId;
        break;
      case ShopAssetCategory.habitCard:
        habitCard ??= row.itemId;
        break;
      case ShopAssetCategory.userCard:
        userCard ??= row.itemId;
        break;
    }
  }

  return (wallpaper: wallpaper, habitCard: habitCard, userCard: userCard);
}

String? _normalizeEquippedId(String? raw, ShopAssetCategory category) {
  final assetId = raw?.trim();
  if (assetId == null || assetId.isEmpty) return null;
  final asset = ShopAssetsCatalog.getAssetById(assetId);
  if (asset == null || asset.category != category) {
    return null;
  }
  return assetId;
}

List<String> _normalizeOwnedAssetIds(Iterable<String> ids) {
  final set = <String>{};
  for (final raw in ids) {
    final value = raw.trim();
    if (value.isEmpty) continue;
    set.add(value);
  }
  return List<String>.from(set);
}

List<String> _normalizeOwnedBundleIds(Iterable<String> ids) {
  final set = <String>{};
  for (final raw in ids) {
    final value = raw.trim();
    if (value.isEmpty) continue;
    set.add(value);
  }
  return List<String>.from(set);
}

const Object _cloudCosmeticsUnset = Object();

final Map<String, int> _assetIndex = <String, int>{
  for (var i = 0; i < ShopAssetsCatalog.allAssets.length; i++)
    ShopAssetsCatalog.allAssets[i].id: i,
};

final Map<String, int> _bundleIndex = <String, int>{
  for (var i = 0; i < ShopAssetsCatalog.allBundles.length; i++)
    ShopAssetsCatalog.allBundles[i].id: i,
};
