import 'package:flutter/foundation.dart';

import '../../domain/models/shop_item.dart';
import '../../domain/models/shop_item_enums.dart';
import 'shop_cloud_dtos.dart';

@immutable
class ShopResolvedUtilitiesCatalog {
  const ShopResolvedUtilitiesCatalog({
    required this.items,
  });

  const ShopResolvedUtilitiesCatalog.empty() : items = const <ShopItem>[];

  final List<ShopItem> items;
}

class ShopUtilitiesCatalogResolver {
  const ShopUtilitiesCatalogResolver({
    this.supportedUtilityIds = _defaultSupportedUtilityIds,
  });

  final Set<String> supportedUtilityIds;

  static const Set<String> _defaultSupportedUtilityIds = <String>{
    'utility_xp_boost_1d',
    'utility_coin_boost_1d',
    'utility_streak_recover_1',
    'utility_streak_shield_1',
    'utility_mystery_box_basic',
  };

  ShopResolvedUtilitiesCatalog resolve({
    required Iterable<ShopItem> localItems,
    required Iterable<RemoteShopItemDto> remoteItems,
  }) {
    final localUtilitiesById = <String, ShopItem>{
      for (final item in localItems)
        if (item.category == ShopItemCategory.utility) item.id: item,
    };
    final remoteSortOrderById = <String, int>{};
    final resolved = <ShopItem>[];

    for (final remote in remoteItems) {
      final item = _resolveItem(
        remote: remote,
        localUtilitiesById: localUtilitiesById,
      );
      if (item == null) continue;
      remoteSortOrderById[item.id] = remote.sortOrder;
      resolved.add(item);
    }

    resolved.sort((a, b) {
      final bySortOrder =
          remoteSortOrderById[a.id]!.compareTo(remoteSortOrderById[b.id]!);
      if (bySortOrder != 0) return bySortOrder;
      return a.id.compareTo(b.id);
    });

    return ShopResolvedUtilitiesCatalog(
      items: List<ShopItem>.unmodifiable(resolved),
    );
  }

  ShopItem? _resolveItem({
    required RemoteShopItemDto remote,
    required Map<String, ShopItem> localUtilitiesById,
  }) {
    if (!remote.isUtility || !remote.isActive) return null;
    if (!supportedUtilityIds.contains(remote.id)) return null;

    final local = localUtilitiesById[remote.id];
    if (local == null) return null;
    final rarity = remote.rarity;
    if (rarity == null || rarity == RemoteShopItemRarity.unknown) return null;

    return local.copyWith(
      priceCoins: remote.priceCoins,
      rarity: _mapRarity(rarity),
      isEnabled: remote.isActive,
    );
  }

  ShopItemRarity _mapRarity(RemoteShopItemRarity rarity) {
    return switch (rarity) {
      RemoteShopItemRarity.common => ShopItemRarity.common,
      RemoteShopItemRarity.uncommon => ShopItemRarity.uncommon,
      RemoteShopItemRarity.rare => ShopItemRarity.rare,
      RemoteShopItemRarity.epic => ShopItemRarity.epic,
      RemoteShopItemRarity.legendary => ShopItemRarity.legendary,
      RemoteShopItemRarity.unknown => ShopItemRarity.common,
    };
  }
}
