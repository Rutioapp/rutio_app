import 'package:flutter/foundation.dart';

import '../../domain/models/shop_item.dart';
import '../../domain/models/shop_item_enums.dart';
import '../../domain/models/shop_bundle.dart';
import '../shop_catalog.dart';
import '../shop_assets_catalog.dart';
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

@immutable
class ShopCloudBundleCatalogReconciliation {
  const ShopCloudBundleCatalogReconciliation({
    required this.knownBundleIds,
    required this.unknownRemoteBundleIds,
    required this.missingLocalBundleIds,
    required this.compositionMismatchBundleIds,
    required this.warnings,
  });

  final List<String> knownBundleIds;
  final List<String> unknownRemoteBundleIds;
  final List<String> missingLocalBundleIds;
  final List<String> compositionMismatchBundleIds;
  final List<ShopCloudWarning> warnings;
}

class ShopCloudBundleCatalogReconciler {
  const ShopCloudBundleCatalogReconciler._();

  static ShopCloudBundleCatalogReconciliation reconcile({
    required List<RemoteShopBundleDto> remoteBundles,
    required Map<String, List<RemoteShopBundleItemDto>>
        remoteCompositionByBundleId,
    List<ShopBundle>? localBundles,
  }) {
    final effectiveLocalBundles = localBundles ?? ShopAssetsCatalog.allBundles;
    final localById = <String, ShopBundle>{
      for (final bundle in effectiveLocalBundles) bundle.id: bundle,
    };
    final remoteById = <String, RemoteShopBundleDto>{
      for (final bundle in remoteBundles) bundle.id: bundle,
    };
    final warnings = <ShopCloudWarning>[];
    final knownBundleIds = <String>[];
    final unknownRemoteBundleIds = <String>[];
    final compositionMismatchBundleIds = <String>[];

    for (final remote in remoteBundles) {
      final local = localById[remote.id];
      if (local == null) {
        unknownRemoteBundleIds.add(remote.id);
        warnings.add(
          ShopCloudWarning(
            code: ShopCloudWarningCode.remoteUnknownCatalogId,
            itemId: remote.id,
            message: 'Remote bundle is not present locally.',
          ),
        );
        continue;
      }

      knownBundleIds.add(remote.id);
      final remoteComposition =
          remoteCompositionByBundleId[remote.id] ?? const [];
      final remoteAssetIds = _bundleAssetIds(remoteComposition);
      final localAssetIds = _expectedLocalBundleAssetIds(local);
      if (!_sameAssetIds(remoteAssetIds, localAssetIds)) {
        compositionMismatchBundleIds.add(remote.id);
        warnings.add(
          ShopCloudWarning(
            code: ShopCloudWarningCode.configMismatch,
            itemId: remote.id,
            message: 'Remote bundle composition differs from local catalog.',
            details: <String, Object?>{
              'localAssetIds': localAssetIds,
              'remoteAssetIds': remoteAssetIds,
            },
          ),
        );
      }
    }

    final missingLocalBundleIds = <String>[
      for (final local in effectiveLocalBundles)
        if (!remoteById.containsKey(local.id)) local.id,
    ];

    for (final missingId in missingLocalBundleIds) {
      warnings.add(
        ShopCloudWarning(
          code: ShopCloudWarningCode.localCatalogMissingRemoteId,
          itemId: missingId,
          message: 'Local bundle is absent or inactive in remote catalog.',
        ),
      );
    }

    return ShopCloudBundleCatalogReconciliation(
      knownBundleIds: List<String>.unmodifiable(knownBundleIds),
      unknownRemoteBundleIds: List<String>.unmodifiable(unknownRemoteBundleIds),
      missingLocalBundleIds: List<String>.unmodifiable(missingLocalBundleIds),
      compositionMismatchBundleIds:
          List<String>.unmodifiable(compositionMismatchBundleIds),
      warnings: List<ShopCloudWarning>.unmodifiable(warnings),
    );
  }
}

List<String> _expectedLocalBundleAssetIds(ShopBundle bundle) {
  return <String>[
    bundle.wallpaperItemId,
    bundle.habitCardItemId,
    bundle.userCardItemId,
  ];
}

List<String> _bundleAssetIds(List<RemoteShopBundleItemDto> rows) {
  final sorted = List<RemoteShopBundleItemDto>.from(rows);
  sorted.sort((a, b) {
    final slotCompare = _bundleSlotOrder(a.slot).compareTo(
      _bundleSlotOrder(b.slot),
    );
    if (slotCompare != 0) return slotCompare;
    final itemCompare = a.itemId.compareTo(b.itemId);
    if (itemCompare != 0) return itemCompare;
    return a.bundleId.compareTo(b.bundleId);
  });
  return sorted.map((row) => row.itemId).toList(growable: false);
}

bool _sameAssetIds(List<String> remoteAssetIds, List<String> localAssetIds) {
  if (remoteAssetIds.length != localAssetIds.length) return false;
  for (var i = 0; i < remoteAssetIds.length; i++) {
    if (remoteAssetIds[i] != localAssetIds[i]) return false;
  }
  return true;
}

int _bundleSlotOrder(RemoteShopEquipSlot slot) {
  return switch (slot) {
    RemoteShopEquipSlot.screenBackground => 0,
    RemoteShopEquipSlot.habitCardBackground => 1,
    RemoteShopEquipSlot.userCardBackground => 2,
    RemoteShopEquipSlot.unknown => 3,
  };
}
