import 'package:rutio/features/shop/data/shop_assets_catalog.dart';
import 'package:rutio/features/shop/data/shop_catalog.dart';
import 'package:rutio/features/shop/domain/models/shop_asset_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_bundle.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';

class ShopCatalogContractItem {
  const ShopCatalogContractItem({
    required this.id,
    required this.category,
    required this.subtype,
    required this.rarity,
    required this.priceCoins,
    required this.isConsumable,
    required this.isStackable,
    required this.maxQuantity,
    required this.equipSlot,
    required this.assetKey,
    required this.localizationKey,
    required this.isActive,
    required this.catalogVersion,
  });

  final String id;
  final String category;
  final String? subtype;
  final String? rarity;
  final int priceCoins;
  final bool isConsumable;
  final bool isStackable;
  final int? maxQuantity;
  final String? equipSlot;
  final String assetKey;
  final String localizationKey;
  final bool isActive;
  final int catalogVersion;

  @override
  String toString() {
    return 'ShopCatalogContractItem(id: $id, category: $category, subtype: $subtype, '
        'rarity: $rarity, priceCoins: $priceCoins, isConsumable: $isConsumable, '
        'isStackable: $isStackable, maxQuantity: $maxQuantity, equipSlot: $equipSlot, '
        'assetKey: $assetKey, localizationKey: $localizationKey, isActive: $isActive, '
        'catalogVersion: $catalogVersion)';
  }
}

class ShopCatalogContractBundle {
  const ShopCatalogContractBundle({
    required this.id,
    required this.familyId,
    required this.rarity,
    required this.priceCoins,
    required this.originalPriceCoins,
    required this.isActive,
    required this.sortOrder,
    required this.catalogVersion,
    required this.itemIdsBySlot,
  });

  final String id;
  final String familyId;
  final String rarity;
  final int priceCoins;
  final int originalPriceCoins;
  final bool isActive;
  final int sortOrder;
  final int catalogVersion;
  final Map<String, String> itemIdsBySlot;

  String? itemIdForSlot(String slot) => itemIdsBySlot[slot];

  @override
  String toString() {
    return 'ShopCatalogContractBundle(id: $id, familyId: $familyId, rarity: $rarity, '
        'priceCoins: $priceCoins, originalPriceCoins: $originalPriceCoins, '
        'isActive: $isActive, sortOrder: $sortOrder, catalogVersion: $catalogVersion, '
        'itemIdsBySlot: $itemIdsBySlot)';
  }
}

class ShopCatalogContractDifference {
  const ShopCatalogContractDifference({
    required this.id,
    required this.field,
    required this.dartValue,
    required this.sqlValue,
  });

  final String id;
  final String field;
  final Object? dartValue;
  final Object? sqlValue;
}

class ShopCatalogContractComparison {
  const ShopCatalogContractComparison({
    required this.dartItemCount,
    required this.sqlItemCount,
    required this.assetCount,
    required this.bundleCount,
    required this.sqlBundleCount,
    required this.itemDifferences,
    required this.bundleDifferences,
    required this.structuralIssues,
    required this.dartItems,
    required this.sqlItems,
    required this.dartBundles,
    required this.sqlBundles,
  });

  final int dartItemCount;
  final int sqlItemCount;
  final int assetCount;
  final int bundleCount;
  final int sqlBundleCount;
  final List<ShopCatalogContractDifference> itemDifferences;
  final List<ShopCatalogContractDifference> bundleDifferences;
  final List<String> structuralIssues;
  final List<ShopCatalogContractItem> dartItems;
  final List<ShopCatalogContractItem> sqlItems;
  final List<ShopCatalogContractBundle> dartBundles;
  final List<ShopCatalogContractBundle> sqlBundles;

  bool get hasDifferences =>
      itemDifferences.isNotEmpty ||
      bundleDifferences.isNotEmpty ||
      structuralIssues.isNotEmpty;

  String renderMarkdownReport({
    required bool remoteParityConfirmed,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(
      'Paridad Dart <-> migraciones: ${hasDifferences ? 'no confirmada' : 'confirmada'}',
    );
    buffer.writeln(
      'Paridad Dart <-> remoto real: ${remoteParityConfirmed ? 'confirmada' : 'pendiente de consulta'}',
    );
    buffer.writeln('Items Dart: $dartItemCount');
    buffer.writeln('Items SQL: $sqlItemCount');
    buffer.writeln('Assets: $assetCount');
    buffer.writeln('Bundles Dart: $bundleCount');
    buffer.writeln('Bundles SQL: $sqlBundleCount');

    if (structuralIssues.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Problemas estructurales:');
      for (final issue in structuralIssues) {
        buffer.writeln('- $issue');
      }
    }

    if (itemDifferences.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(
          '| ID | Dart | SQL | Campo diferente | Valor Dart | Valor SQL |');
      buffer.writeln(
          '| -- | ---- | --- | --------------- | ---------- | --------- |');
      for (final diff in itemDifferences) {
        buffer.writeln(
          '| ${diff.id} | Dart | SQL | ${diff.field} | ${_valueToTableCell(diff.dartValue)} | ${_valueToTableCell(diff.sqlValue)} |',
        );
      }
    }

    if (bundleDifferences.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(
        '| ID | Dart | SQL | Campo diferente | Valor Dart | Valor SQL |',
      );
      buffer.writeln(
          '| -- | ---- | --- | --------------- | ---------- | --------- |');
      for (final diff in bundleDifferences) {
        buffer.writeln(
          '| ${diff.id} | Dart | SQL | ${diff.field} | ${_valueToTableCell(diff.dartValue)} | ${_valueToTableCell(diff.sqlValue)} |',
        );
      }
    }

    return buffer.toString().trimRight();
  }

  static String _valueToTableCell(Object? value) {
    if (value == null) {
      return 'null';
    }
    final text = value.toString().replaceAll('\n', ' ');
    return text.replaceAll('|', r'\|');
  }
}

class ShopCatalogContractSnapshot {
  const ShopCatalogContractSnapshot({
    required this.items,
    required this.bundles,
  });

  final List<ShopCatalogContractItem> items;
  final List<ShopCatalogContractBundle> bundles;

  static ShopCatalogContractSnapshot fromLocal() {
    final items = <ShopCatalogContractItem>[
      for (final item in ShopCatalog.allItems) _toContractItem(item),
    ];
    final bundles = <ShopCatalogContractBundle>[
      for (final bundle in ShopAssetsCatalog.allBundles)
        _toContractBundle(bundle),
    ];
    return ShopCatalogContractSnapshot(items: items, bundles: bundles);
  }
}

ShopCatalogContractComparison compareShopCatalogContracts({
  required ShopCatalogContractSnapshot dartSnapshot,
  required ShopCatalogContractSnapshot sqlSnapshot,
}) {
  final structuralIssues = <String>[];
  structuralIssues.addAll(_duplicateIssues(
    label: 'Dart item id',
    values: dartSnapshot.items.map((item) => item.id),
  ));
  structuralIssues.addAll(_duplicateIssues(
    label: 'SQL item id',
    values: sqlSnapshot.items.map((item) => item.id),
  ));
  structuralIssues.addAll(_duplicateIssues(
    label: 'Dart asset key',
    values: dartSnapshot.items.map((item) => item.assetKey),
  ));
  structuralIssues.addAll(_duplicateIssues(
    label: 'SQL asset key',
    values: sqlSnapshot.items.map((item) => item.assetKey),
  ));
  structuralIssues.addAll(_duplicateIssues(
    label: 'Dart localization key',
    values: dartSnapshot.items.map((item) => item.localizationKey),
  ));
  structuralIssues.addAll(_duplicateIssues(
    label: 'SQL localization key',
    values: sqlSnapshot.items.map((item) => item.localizationKey),
  ));
  structuralIssues.addAll(_duplicateIssues(
    label: 'Dart bundle id',
    values: dartSnapshot.bundles.map((bundle) => bundle.id),
  ));
  structuralIssues.addAll(_duplicateIssues(
    label: 'SQL bundle id',
    values: sqlSnapshot.bundles.map((bundle) => bundle.id),
  ));

  final dartItemsById = <String, ShopCatalogContractItem>{
    for (final item in dartSnapshot.items) item.id: item,
  };
  final sqlItemsById = <String, ShopCatalogContractItem>{
    for (final item in sqlSnapshot.items) item.id: item,
  };
  final itemDifferences = <ShopCatalogContractDifference>[];

  final itemIds = <String>{
    ...dartItemsById.keys,
    ...sqlItemsById.keys,
  }.toList()
    ..sort();
  for (final id in itemIds) {
    final dartItem = dartItemsById[id];
    final sqlItem = sqlItemsById[id];
    if (dartItem == null || sqlItem == null) {
      itemDifferences.add(
        ShopCatalogContractDifference(
          id: id,
          field: dartItem == null ? 'missing_in_dart' : 'missing_in_sql',
          dartValue: dartItem == null ? 'missing' : 'present',
          sqlValue: sqlItem == null ? 'missing' : 'present',
        ),
      );
      continue;
    }

    _appendIfDifferent(
      diffs: itemDifferences,
      id: id,
      field: 'category',
      dartValue: dartItem.category,
      sqlValue: sqlItem.category,
    );
    _appendIfDifferent(
      diffs: itemDifferences,
      id: id,
      field: 'subtype',
      dartValue: dartItem.subtype,
      sqlValue: sqlItem.subtype,
    );
    _appendIfDifferent(
      diffs: itemDifferences,
      id: id,
      field: 'rarity',
      dartValue: dartItem.rarity,
      sqlValue: sqlItem.rarity,
    );
    _appendIfDifferent(
      diffs: itemDifferences,
      id: id,
      field: 'priceCoins',
      dartValue: dartItem.priceCoins,
      sqlValue: sqlItem.priceCoins,
    );
    _appendIfDifferent(
      diffs: itemDifferences,
      id: id,
      field: 'isConsumable',
      dartValue: dartItem.isConsumable,
      sqlValue: sqlItem.isConsumable,
    );
    _appendIfDifferent(
      diffs: itemDifferences,
      id: id,
      field: 'isStackable',
      dartValue: dartItem.isStackable,
      sqlValue: sqlItem.isStackable,
    );
    _appendIfDifferent(
      diffs: itemDifferences,
      id: id,
      field: 'maxQuantity',
      dartValue: dartItem.maxQuantity,
      sqlValue: sqlItem.maxQuantity,
    );
    _appendIfDifferent(
      diffs: itemDifferences,
      id: id,
      field: 'equipSlot',
      dartValue: dartItem.equipSlot,
      sqlValue: sqlItem.equipSlot,
    );
    _appendIfDifferent(
      diffs: itemDifferences,
      id: id,
      field: 'assetKey',
      dartValue: dartItem.assetKey,
      sqlValue: sqlItem.assetKey,
    );
    _appendIfDifferent(
      diffs: itemDifferences,
      id: id,
      field: 'localizationKey',
      dartValue: dartItem.localizationKey,
      sqlValue: sqlItem.localizationKey,
    );
    _appendIfDifferent(
      diffs: itemDifferences,
      id: id,
      field: 'isActive',
      dartValue: dartItem.isActive,
      sqlValue: sqlItem.isActive,
    );
    _appendIfDifferent(
      diffs: itemDifferences,
      id: id,
      field: 'catalogVersion',
      dartValue: dartItem.catalogVersion,
      sqlValue: sqlItem.catalogVersion,
    );
  }

  final dartBundlesById = <String, ShopCatalogContractBundle>{
    for (final bundle in dartSnapshot.bundles) bundle.id: bundle,
  };
  final sqlBundlesById = <String, ShopCatalogContractBundle>{
    for (final bundle in sqlSnapshot.bundles) bundle.id: bundle,
  };
  final bundleDifferences = <ShopCatalogContractDifference>[];

  final bundleIds = <String>{
    ...dartBundlesById.keys,
    ...sqlBundlesById.keys,
  }.toList()
    ..sort();
  for (final id in bundleIds) {
    final dartBundle = dartBundlesById[id];
    final sqlBundle = sqlBundlesById[id];
    if (dartBundle == null || sqlBundle == null) {
      bundleDifferences.add(
        ShopCatalogContractDifference(
          id: id,
          field: dartBundle == null ? 'missing_in_dart' : 'missing_in_sql',
          dartValue: dartBundle == null ? 'missing' : 'present',
          sqlValue: sqlBundle == null ? 'missing' : 'present',
        ),
      );
      continue;
    }

    _appendIfDifferent(
      diffs: bundleDifferences,
      id: id,
      field: 'familyId',
      dartValue: dartBundle.familyId,
      sqlValue: sqlBundle.familyId,
    );
    _appendIfDifferent(
      diffs: bundleDifferences,
      id: id,
      field: 'rarity',
      dartValue: dartBundle.rarity,
      sqlValue: sqlBundle.rarity,
    );
    _appendIfDifferent(
      diffs: bundleDifferences,
      id: id,
      field: 'priceCoins',
      dartValue: dartBundle.priceCoins,
      sqlValue: sqlBundle.priceCoins,
    );
    _appendIfDifferent(
      diffs: bundleDifferences,
      id: id,
      field: 'originalPriceCoins',
      dartValue: dartBundle.originalPriceCoins,
      sqlValue: sqlBundle.originalPriceCoins,
    );
    _appendIfDifferent(
      diffs: bundleDifferences,
      id: id,
      field: 'isActive',
      dartValue: dartBundle.isActive,
      sqlValue: sqlBundle.isActive,
    );
    _appendIfDifferent(
      diffs: bundleDifferences,
      id: id,
      field: 'sortOrder',
      dartValue: dartBundle.sortOrder,
      sqlValue: sqlBundle.sortOrder,
    );
    _appendIfDifferent(
      diffs: bundleDifferences,
      id: id,
      field: 'catalogVersion',
      dartValue: dartBundle.catalogVersion,
      sqlValue: sqlBundle.catalogVersion,
    );

    const slots = <String>[
      'screen_background',
      'habit_card_background',
      'user_card_background',
    ];
    for (final slot in slots) {
      _appendIfDifferent(
        diffs: bundleDifferences,
        id: id,
        field: slot,
        dartValue: dartBundle.itemIdForSlot(slot),
        sqlValue: sqlBundle.itemIdForSlot(slot),
      );
    }

    final bundleSlots = dartBundle.itemIdsBySlot.keys.toSet();
    if (bundleSlots.length != 3) {
      structuralIssues.add(
        'Dart bundle $id has ${bundleSlots.length} slots instead of 3.',
      );
    }
    if (sqlBundle.itemIdsBySlot.length != 3) {
      structuralIssues.add(
        'SQL bundle $id has ${sqlBundle.itemIdsBySlot.length} slots instead of 3.',
      );
    }
    if (bundleSlots.length != dartBundle.itemIdsBySlot.length) {
      structuralIssues.add('Dart bundle $id contains duplicated slots.');
    }
    if (sqlBundle.itemIdsBySlot.length !=
        sqlBundle.itemIdsBySlot.keys.toSet().length) {
      structuralIssues.add('SQL bundle $id contains duplicated slots.');
    }
  }

  return ShopCatalogContractComparison(
    dartItemCount: dartSnapshot.items.length,
    sqlItemCount: sqlSnapshot.items.length,
    assetCount: ShopAssetsCatalog.allAssets.length,
    bundleCount: ShopAssetsCatalog.allBundles.length,
    sqlBundleCount: sqlSnapshot.bundles.length,
    itemDifferences: itemDifferences,
    bundleDifferences: bundleDifferences,
    structuralIssues: structuralIssues,
    dartItems: dartSnapshot.items,
    sqlItems: sqlSnapshot.items,
    dartBundles: dartSnapshot.bundles,
    sqlBundles: sqlSnapshot.bundles,
  );
}

void _appendIfDifferent({
  required List<ShopCatalogContractDifference> diffs,
  required String id,
  required String field,
  required Object? dartValue,
  required Object? sqlValue,
}) {
  if (_valuesEqual(dartValue, sqlValue)) {
    return;
  }
  diffs.add(
    ShopCatalogContractDifference(
      id: id,
      field: field,
      dartValue: dartValue,
      sqlValue: sqlValue,
    ),
  );
}

bool _valuesEqual(Object? left, Object? right) {
  if (left is Map && right is Map) {
    if (left.length != right.length) {
      return false;
    }
    for (final entry in left.entries) {
      if (!_valuesEqual(entry.value, right[entry.key])) {
        return false;
      }
    }
    return true;
  }
  if (left is Iterable && right is Iterable) {
    final leftList = left.toList(growable: false);
    final rightList = right.toList(growable: false);
    if (leftList.length != rightList.length) {
      return false;
    }
    for (var i = 0; i < leftList.length; i++) {
      if (!_valuesEqual(leftList[i], rightList[i])) {
        return false;
      }
    }
    return true;
  }
  return left == right;
}

List<String> _duplicateIssues({
  required String label,
  required Iterable<String> values,
}) {
  final counts = <String, int>{};
  for (final value in values) {
    counts[value] = (counts[value] ?? 0) + 1;
  }
  final issues = <String>[];
  for (final entry in counts.entries) {
    if (entry.value > 1) {
      issues.add('$label "$entry.key" appears ${entry.value} times.');
    }
  }
  return issues;
}

ShopCatalogContractItem _toContractItem(ShopItem item) {
  final isUtility = item.category == ShopItemCategory.utility;
  final cosmeticSlot = item.cosmeticSlot;
  return ShopCatalogContractItem(
    id: item.id,
    category: _contractCategory(item),
    subtype: item.type.key,
    rarity: isUtility ? null : item.rarity.key,
    priceCoins: item.priceCoins,
    isConsumable: isUtility,
    isStackable: isUtility,
    maxQuantity: isUtility ? null : 1,
    equipSlot: isUtility ? null : cosmeticSlot?.remoteDbKey,
    assetKey: item.assetRef ?? '',
    localizationKey: _localizationKeyForItem(item),
    isActive: item.isEnabled,
    catalogVersion: kShopCatalogContractVersion,
  );
}

ShopCatalogContractItem shopCatalogContractItemFromSql({
  required String id,
  required String category,
  required String? subtype,
  required String? rarity,
  required int priceCoins,
  required bool isConsumable,
  required bool isStackable,
  required int? maxQuantity,
  required String? equipSlot,
  required String assetKey,
  required String localizationKey,
  required bool isActive,
  required int catalogVersion,
}) {
  return ShopCatalogContractItem(
    id: id,
    category: category,
    subtype: subtype,
    rarity: rarity,
    priceCoins: priceCoins,
    isConsumable: isConsumable,
    isStackable: isStackable,
    maxQuantity: maxQuantity,
    equipSlot: equipSlot,
    assetKey: assetKey,
    localizationKey: localizationKey,
    isActive: isActive,
    catalogVersion: catalogVersion,
  );
}

ShopCatalogContractBundle _toContractBundle(ShopBundle bundle) {
  return ShopCatalogContractBundle(
    id: bundle.id,
    familyId: bundle.familyId,
    rarity: bundle.rarity.key,
    priceCoins: bundle.priceAmber,
    originalPriceCoins: bundle.originalPriceAmber,
    isActive: bundle.isPurchasable,
    sortOrder: bundle.sortOrder,
    catalogVersion: _bundleCatalogVersion(bundle.id),
    itemIdsBySlot: <String, String>{
      'screen_background': bundle.wallpaperItemId,
      'habit_card_background': bundle.habitCardItemId,
      'user_card_background': bundle.userCardItemId,
    },
  );
}

int _bundleCatalogVersion(String bundleId) {
  switch (bundleId) {
    case 'pack_lila_profunda':
    case 'pack_coral_atardecer':
      return kShopCatalogContractVersion + 1;
    default:
      return kShopCatalogContractVersion;
  }
}

String _contractCategory(ShopItem item) {
  if (item.category == ShopItemCategory.utility) {
    return 'utility';
  }
  final slot = item.cosmeticSlot;
  switch (slot) {
    case CosmeticSlot.background:
      return 'screen_background';
    case CosmeticSlot.habitCard:
      return 'habit_card_background';
    case CosmeticSlot.userCard:
      return 'user_card_background';
    case null:
      return 'screen_background';
  }
}

String _localizationKeyForItem(ShopItem item) {
  if (item.category == ShopItemCategory.utility) {
    switch (item.id) {
      case 'utility_xp_boost_1d':
        return 'shopXpBoostTitle';
      case 'utility_coin_boost_1d':
        return 'shopCoinBoostTitle';
      case 'utility_streak_recover_1':
        return 'shopStreakRecoverTitle';
      case 'utility_streak_shield_1':
        return 'shopStreakShieldTitle';
      case 'utility_mystery_box_basic':
        return 'shopMysteryBoxTitle';
    }
  }

  final prefix = switch (item.type) {
    ShopItemType.background => 'shopCosmetic_${item.id}_title',
    ShopItemType.habitCard => 'shopCosmetic_${item.id}_title',
    ShopItemType.userCard => 'shopCosmetic_${item.id}_title',
    ShopItemType.xpBoost => 'shopXpBoostTitle',
    ShopItemType.coinBoost => 'shopCoinBoostTitle',
    ShopItemType.streakRecover => 'shopStreakRecoverTitle',
    ShopItemType.streakShield => 'shopStreakShieldTitle',
    ShopItemType.mysteryBox => 'shopMysteryBoxTitle',
  };
  return prefix;
}

const int kShopCatalogContractVersion = 1;
