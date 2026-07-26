import 'package:flutter/foundation.dart';

import 'shop_cloud_dtos.dart';
import 'shop_cloud_errors.dart';

@immutable
class ShopCloudSnapshot {
  const ShopCloudSnapshot({
    required this.authenticatedUserId,
    required this.catalogItems,
    required this.catalogBundles,
    this.catalogBundleItems = const <RemoteShopBundleItemDto>[],
    required this.wallet,
    required this.inventory,
    required this.equippedCosmetics,
    required this.ownedBundles,
    required this.fetchedAt,
    required this.catalogVersion,
    required this.warnings,
  });

  final String authenticatedUserId;
  final List<RemoteShopItemDto> catalogItems;
  final List<RemoteShopBundleDto> catalogBundles;
  final List<RemoteShopBundleItemDto> catalogBundleItems;
  final RemoteWalletDto? wallet;
  final List<RemoteInventoryItemDto> inventory;
  final List<RemoteEquippedCosmeticDto> equippedCosmetics;
  final List<RemoteOwnedBundleDto> ownedBundles;
  final DateTime fetchedAt;
  final int? catalogVersion;
  final List<ShopCloudWarning> warnings;

  ShopCloudSnapshot copyWith({
    String? authenticatedUserId,
    List<RemoteShopItemDto>? catalogItems,
    List<RemoteShopBundleDto>? catalogBundles,
    List<RemoteShopBundleItemDto>? catalogBundleItems,
    RemoteWalletDto? wallet,
    List<RemoteInventoryItemDto>? inventory,
    List<RemoteEquippedCosmeticDto>? equippedCosmetics,
    List<RemoteOwnedBundleDto>? ownedBundles,
    DateTime? fetchedAt,
    int? catalogVersion,
    List<ShopCloudWarning>? warnings,
  }) {
    return ShopCloudSnapshot(
      authenticatedUserId: authenticatedUserId ?? this.authenticatedUserId,
      catalogItems: catalogItems ?? this.catalogItems,
      catalogBundles: catalogBundles ?? this.catalogBundles,
      catalogBundleItems: catalogBundleItems ?? this.catalogBundleItems,
      wallet: wallet ?? this.wallet,
      inventory: inventory ?? this.inventory,
      equippedCosmetics: equippedCosmetics ?? this.equippedCosmetics,
      ownedBundles: ownedBundles ?? this.ownedBundles,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      catalogVersion: catalogVersion ?? this.catalogVersion,
      warnings: warnings ?? this.warnings,
    );
  }
}
