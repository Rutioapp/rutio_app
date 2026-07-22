import 'package:flutter/foundation.dart';

import 'shop_cloud_dtos.dart';
import 'shop_cloud_errors.dart';

@immutable
class ShopCloudSnapshot {
  const ShopCloudSnapshot({
    required this.authenticatedUserId,
    required this.catalogItems,
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
  final RemoteWalletDto? wallet;
  final List<RemoteInventoryItemDto> inventory;
  final List<RemoteEquippedCosmeticDto> equippedCosmetics;
  final List<RemoteOwnedBundleDto> ownedBundles;
  final DateTime fetchedAt;
  final int? catalogVersion;
  final List<ShopCloudWarning> warnings;
}
