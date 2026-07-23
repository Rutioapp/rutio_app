import 'package:flutter/foundation.dart';

import '../../domain/models/shop_item.dart';
import '../../domain/models/shop_item_enums.dart';
import '../shop_catalog.dart';
import 'shop_cloud_dtos.dart';
import 'shop_cloud_errors.dart';

@immutable
class ShopCloudCatalogReconciliation {
  const ShopCloudCatalogReconciliation({
    required this.knownItemIds,
    required this.unknownRemoteItemIds,
    required this.missingLocalItemIds,
    required this.priceMismatchItemIds,
    required this.configurationMismatchItemIds,
    required this.warnings,
  });

  final List<String> knownItemIds;
  final List<String> unknownRemoteItemIds;
  final List<String> missingLocalItemIds;
  final List<String> priceMismatchItemIds;
  final List<String> configurationMismatchItemIds;
  final List<ShopCloudWarning> warnings;
}

class ShopCloudCatalogReconciler {
  const ShopCloudCatalogReconciler._();

  static ShopCloudCatalogReconciliation reconcile({
    required List<RemoteShopItemDto> remoteItems,
    List<ShopItem>? localItems,
  }) {
    final effectiveLocalItems = localItems ?? ShopCatalog.allItems;
    final localById = <String, ShopItem>{
      for (final item in effectiveLocalItems) item.id: item,
    };
    final remoteById = <String, RemoteShopItemDto>{
      for (final item in remoteItems) item.id: item,
    };
    final warnings = <ShopCloudWarning>[];
    final knownItemIds = <String>[];
    final unknownRemoteItemIds = <String>[];
    final priceMismatchItemIds = <String>[];
    final configurationMismatchItemIds = <String>[];

    for (final remote in remoteItems) {
      final local = localById[remote.id];
      if (local == null) {
        unknownRemoteItemIds.add(remote.id);
        warnings.add(
          ShopCloudWarning(
            code: ShopCloudWarningCode.remoteUnknownCatalogId,
            itemId: remote.id,
            message: 'Remote catalog item is not present locally.',
          ),
        );
        continue;
      }

      knownItemIds.add(remote.id);
      _compareAgainstLocal(
        remote: remote,
        local: local,
        warnings: warnings,
        priceMismatchItemIds: priceMismatchItemIds,
        configurationMismatchItemIds: configurationMismatchItemIds,
      );
    }

    final missingLocalItemIds = <String>[
      for (final local in effectiveLocalItems)
        if (!remoteById.containsKey(local.id)) local.id,
    ];

    for (final missingId in missingLocalItemIds) {
      warnings.add(
        ShopCloudWarning(
          code: ShopCloudWarningCode.localCatalogMissingRemoteId,
          itemId: missingId,
          message: 'Local catalog item is absent from remote catalog.',
        ),
      );
    }

    return ShopCloudCatalogReconciliation(
      knownItemIds: List<String>.unmodifiable(knownItemIds),
      unknownRemoteItemIds: List<String>.unmodifiable(unknownRemoteItemIds),
      missingLocalItemIds: List<String>.unmodifiable(missingLocalItemIds),
      priceMismatchItemIds: List<String>.unmodifiable(priceMismatchItemIds),
      configurationMismatchItemIds:
          List<String>.unmodifiable(configurationMismatchItemIds),
      warnings: List<ShopCloudWarning>.unmodifiable(warnings),
    );
  }

  static void _compareAgainstLocal({
    required RemoteShopItemDto remote,
    required ShopItem local,
    required List<ShopCloudWarning> warnings,
    required List<String> priceMismatchItemIds,
    required List<String> configurationMismatchItemIds,
  }) {
    if (local.priceCoins != remote.priceCoins) {
      priceMismatchItemIds.add(remote.id);
      warnings.add(
        ShopCloudWarning(
          code: ShopCloudWarningCode.priceMismatch,
          itemId: remote.id,
          message: 'Remote price differs from local catalog price.',
          details: <String, Object?>{
            'localPriceCoins': local.priceCoins,
            'remotePriceCoins': remote.priceCoins,
          },
        ),
      );
    }

    final expected = _expectedRemoteConfig(local);
    final remoteCategoryKey = remote.category.dbKey;
    final expectedCategoryKey = expected['category'] as String?;
    final expectedSubtype = expected['subtype'] as String?;
    final expectedRarity = expected['rarity'] as String?;
    final expectedIsConsumable = expected['isConsumable'] as bool;
    final expectedIsStackable = expected['isStackable'] as bool;
    final expectedMaxQuantity = expected['maxQuantity'] as int?;
    final expectedEquipSlot = expected['equipSlot'] as String?;
    final expectedAssetKey = local.assetRef;
    final expectedIsActive = local.isEnabled;

    final configMismatch = remoteCategoryKey != expectedCategoryKey ||
        remote.subtype != expectedSubtype ||
        remote.rarity?.dbKey != expectedRarity ||
        remote.isConsumable != expectedIsConsumable ||
        remote.isStackable != expectedIsStackable ||
        remote.maxQuantity != expectedMaxQuantity ||
        remote.equipSlot?.dbKey != expectedEquipSlot ||
        remote.assetKey != expectedAssetKey ||
        remote.isActive != expectedIsActive;

    if (configMismatch) {
      configurationMismatchItemIds.add(remote.id);
      warnings.add(
        ShopCloudWarning(
          code: ShopCloudWarningCode.configMismatch,
          itemId: remote.id,
          message: 'Remote catalog configuration differs from local catalog.',
          details: <String, Object?>{
            'localCategory': expectedCategoryKey,
            'remoteCategory': remoteCategoryKey,
            'localSubtype': expectedSubtype,
            'remoteSubtype': remote.subtype,
            'localRarity': expectedRarity,
            'remoteRarity': remote.rarity?.dbKey,
            'localIsConsumable': expectedIsConsumable,
            'remoteIsConsumable': remote.isConsumable,
            'localIsStackable': expectedIsStackable,
            'remoteIsStackable': remote.isStackable,
            'localMaxQuantity': expectedMaxQuantity,
            'remoteMaxQuantity': remote.maxQuantity,
            'localEquipSlot': expectedEquipSlot,
            'remoteEquipSlot': remote.equipSlot?.dbKey,
            'localAssetKey': expectedAssetKey,
            'remoteAssetKey': remote.assetKey,
            'localIsActive': expectedIsActive,
            'remoteIsActive': remote.isActive,
          },
        ),
      );
    }
  }

  static Map<String, Object?> _expectedRemoteConfig(ShopItem item) {
    final isUtility = item.category == ShopItemCategory.utility;
    final cosmeticSlot = item.cosmeticSlot;
    return <String, Object?>{
      'category': isUtility ? 'utility' : cosmeticSlot?.remoteDbKey,
      'subtype': item.type.key,
      'rarity': isUtility ? null : item.rarity.key,
      'isConsumable': isUtility,
      'isStackable': isUtility,
      'maxQuantity': isUtility ? null : 1,
      'equipSlot': isUtility ? null : cosmeticSlot?.remoteDbKey,
    };
  }
}
