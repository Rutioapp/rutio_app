enum RemoteShopItemCategory {
  screenBackground,
  habitCardBackground,
  userCardBackground,
  utility,
  unknown,
}

extension RemoteShopItemCategoryX on RemoteShopItemCategory {
  static RemoteShopItemCategory fromKey(Object? value) {
    switch ((value ?? '').toString().trim()) {
      case 'screen_background':
        return RemoteShopItemCategory.screenBackground;
      case 'habit_card_background':
        return RemoteShopItemCategory.habitCardBackground;
      case 'user_card_background':
        return RemoteShopItemCategory.userCardBackground;
      case 'utility':
        return RemoteShopItemCategory.utility;
      default:
        return RemoteShopItemCategory.unknown;
    }
  }

  String? get dbKey {
    switch (this) {
      case RemoteShopItemCategory.screenBackground:
        return 'screen_background';
      case RemoteShopItemCategory.habitCardBackground:
        return 'habit_card_background';
      case RemoteShopItemCategory.userCardBackground:
        return 'user_card_background';
      case RemoteShopItemCategory.utility:
        return 'utility';
      case RemoteShopItemCategory.unknown:
        return null;
    }
  }
}

enum RemoteShopItemRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
  unknown,
}

extension RemoteShopItemRarityX on RemoteShopItemRarity {
  static RemoteShopItemRarity fromKey(Object? value) {
    switch ((value ?? '').toString().trim()) {
      case 'uncommon':
        return RemoteShopItemRarity.uncommon;
      case 'rare':
        return RemoteShopItemRarity.rare;
      case 'epic':
        return RemoteShopItemRarity.epic;
      case 'legendary':
        return RemoteShopItemRarity.legendary;
      case 'common':
        return RemoteShopItemRarity.common;
      default:
        return RemoteShopItemRarity.unknown;
    }
  }

  String? get dbKey {
    switch (this) {
      case RemoteShopItemRarity.common:
        return 'common';
      case RemoteShopItemRarity.uncommon:
        return 'uncommon';
      case RemoteShopItemRarity.rare:
        return 'rare';
      case RemoteShopItemRarity.epic:
        return 'epic';
      case RemoteShopItemRarity.legendary:
        return 'legendary';
      case RemoteShopItemRarity.unknown:
        return null;
    }
  }
}

enum RemoteShopEquipSlot {
  screenBackground,
  habitCardBackground,
  userCardBackground,
  unknown,
}

extension RemoteShopEquipSlotX on RemoteShopEquipSlot {
  static RemoteShopEquipSlot fromKey(Object? value) {
    switch ((value ?? '').toString().trim()) {
      case 'screen_background':
        return RemoteShopEquipSlot.screenBackground;
      case 'habit_card_background':
        return RemoteShopEquipSlot.habitCardBackground;
      case 'user_card_background':
        return RemoteShopEquipSlot.userCardBackground;
      default:
        return RemoteShopEquipSlot.unknown;
    }
  }

  String? get dbKey {
    switch (this) {
      case RemoteShopEquipSlot.screenBackground:
        return 'screen_background';
      case RemoteShopEquipSlot.habitCardBackground:
        return 'habit_card_background';
      case RemoteShopEquipSlot.userCardBackground:
        return 'user_card_background';
      case RemoteShopEquipSlot.unknown:
        return null;
    }
  }
}

class RemoteShopItemDto {
  const RemoteShopItemDto({
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
    required this.sortOrder,
    required this.catalogVersion,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final RemoteShopItemCategory category;
  final String? subtype;
  final RemoteShopItemRarity? rarity;
  final int priceCoins;
  final bool isConsumable;
  final bool isStackable;
  final int? maxQuantity;
  final RemoteShopEquipSlot? equipSlot;
  final String? assetKey;
  final String? localizationKey;
  final bool isActive;
  final int sortOrder;
  final int catalogVersion;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasUnknownCategory => category == RemoteShopItemCategory.unknown;

  bool get hasUnknownRarity => rarity == RemoteShopItemRarity.unknown;

  bool get hasUnknownSlot =>
      equipSlot == null || equipSlot == RemoteShopEquipSlot.unknown;

  bool get isUtility => category == RemoteShopItemCategory.utility;

  bool get isCosmetic => !isUtility;

  factory RemoteShopItemDto.fromJson(Map<String, dynamic> json) {
    final id = _trim(json['id']);
    final priceCoins = _int(json['priceCoins'] ?? json['price_coins']);
    final sortOrder = _int(json['sortOrder'] ?? json['sort_order']);
    final catalogVersion =
        _int(json['catalogVersion'] ?? json['catalog_version']);
    final createdAt = _dateTime(json['createdAt'] ?? json['created_at']);
    final updatedAt = _dateTime(json['updatedAt'] ?? json['updated_at']);

    if (id == null ||
        id.isEmpty ||
        priceCoins == null ||
        priceCoins < 0 ||
        sortOrder == null ||
        sortOrder < 0 ||
        catalogVersion == null ||
        catalogVersion < 1 ||
        createdAt == null ||
        updatedAt == null) {
      throw const FormatException('Invalid remote shop item row.');
    }

    return RemoteShopItemDto(
      id: id,
      category: RemoteShopItemCategoryX.fromKey(
        json['category'] ?? json['equip_slot'],
      ),
      subtype: _nullableTrim(json['subtype']),
      rarity: _nullableRarity(json['rarity']),
      priceCoins: priceCoins,
      isConsumable: _bool(json['isConsumable'] ?? json['is_consumable']),
      isStackable: _bool(json['isStackable'] ?? json['is_stackable']),
      maxQuantity: _nullableInt(json['maxQuantity'] ?? json['max_quantity']),
      equipSlot: _nullableEquipSlot(json['equipSlot'] ?? json['equip_slot']),
      assetKey: _nullableTrim(json['assetKey'] ?? json['asset_key']),
      localizationKey:
          _nullableTrim(json['localizationKey'] ?? json['localization_key']),
      isActive: _bool(json['isActive'] ?? json['is_active']),
      sortOrder: sortOrder,
      catalogVersion: catalogVersion,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'category': category.dbKey,
      'subtype': subtype,
      'rarity': rarity?.dbKey,
      'priceCoins': priceCoins,
      'isConsumable': isConsumable,
      'isStackable': isStackable,
      'maxQuantity': maxQuantity,
      'equipSlot': equipSlot?.dbKey,
      'assetKey': assetKey,
      'localizationKey': localizationKey,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'catalogVersion': catalogVersion,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class RemoteWalletDto {
  const RemoteWalletDto({
    required this.userId,
    required this.coins,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
  });

  final String userId;
  final int coins;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory RemoteWalletDto.fromJson(
    Map<String, dynamic> json, {
    String? expectedUserId,
  }) {
    final userId = _trim(json['userId'] ?? json['user_id']);
    final coins = _int(json['coins']);
    final version = _int(json['version']);
    final createdAt = _dateTime(json['createdAt'] ?? json['created_at']);
    final updatedAt = _dateTime(json['updatedAt'] ?? json['updated_at']);

    if (userId == null ||
        userId.isEmpty ||
        coins == null ||
        coins < 0 ||
        version == null ||
        version < 0 ||
        createdAt == null ||
        updatedAt == null) {
      throw const FormatException('Invalid remote wallet row.');
    }

    if (expectedUserId != null && expectedUserId.trim() != userId) {
      throw const FormatException('Wallet user scope mismatch.');
    }

    return RemoteWalletDto(
      userId: userId,
      coins: coins,
      version: version,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'userId': userId,
      'coins': coins,
      'version': version,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class RemoteInventoryItemDto {
  const RemoteInventoryItemDto({
    required this.id,
    required this.userId,
    required this.itemId,
    required this.quantity,
    required this.acquisitionSource,
    required this.acquiredAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String itemId;
  final int quantity;
  final String acquisitionSource;
  final DateTime acquiredAt;
  final DateTime updatedAt;

  factory RemoteInventoryItemDto.fromJson(
    Map<String, dynamic> json, {
    String? expectedUserId,
  }) {
    final id = _trim(json['id']);
    final userId = _trim(json['userId'] ?? json['user_id']);
    final itemId = _trim(json['itemId'] ?? json['item_id']);
    final quantity = _int(json['quantity']);
    final acquisitionSource =
        _trim(json['acquisitionSource'] ?? json['acquisition_source']);
    final acquiredAt = _dateTime(json['acquiredAt'] ?? json['acquired_at']);
    final updatedAt = _dateTime(json['updatedAt'] ?? json['updated_at']);

    if (id == null ||
        id.isEmpty ||
        userId == null ||
        userId.isEmpty ||
        itemId == null ||
        itemId.isEmpty ||
        quantity == null ||
        quantity <= 0 ||
        acquisitionSource == null ||
        acquisitionSource.isEmpty ||
        acquiredAt == null ||
        updatedAt == null) {
      throw const FormatException('Invalid remote inventory row.');
    }

    if (expectedUserId != null && expectedUserId.trim() != userId) {
      throw const FormatException('Inventory user scope mismatch.');
    }

    return RemoteInventoryItemDto(
      id: id,
      userId: userId,
      itemId: itemId,
      quantity: quantity,
      acquisitionSource: acquisitionSource,
      acquiredAt: acquiredAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'itemId': itemId,
      'quantity': quantity,
      'acquisitionSource': acquisitionSource,
      'acquiredAt': acquiredAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class RemoteEquippedCosmeticDto {
  const RemoteEquippedCosmeticDto({
    required this.userId,
    required this.slot,
    required this.itemId,
    required this.equippedAt,
  });

  final String userId;
  final RemoteShopEquipSlot slot;
  final String itemId;
  final DateTime equippedAt;

  factory RemoteEquippedCosmeticDto.fromJson(
    Map<String, dynamic> json, {
    String? expectedUserId,
  }) {
    final userId = _trim(json['userId'] ?? json['user_id']);
    final itemId = _trim(json['itemId'] ?? json['item_id']);
    final slot = RemoteShopEquipSlotX.fromKey(json['slot']);
    final equippedAt = _dateTime(json['equippedAt'] ?? json['equipped_at']);

    if (userId == null ||
        userId.isEmpty ||
        itemId == null ||
        itemId.isEmpty ||
        slot == RemoteShopEquipSlot.unknown ||
        equippedAt == null) {
      throw const FormatException('Invalid remote equipped cosmetic row.');
    }

    if (expectedUserId != null && expectedUserId.trim() != userId) {
      throw const FormatException('Equipped cosmetic user scope mismatch.');
    }

    return RemoteEquippedCosmeticDto(
      userId: userId,
      slot: slot,
      itemId: itemId,
      equippedAt: equippedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'userId': userId,
      'slot': slot.dbKey,
      'itemId': itemId,
      'equippedAt': equippedAt.toIso8601String(),
    };
  }
}

class RemoteOwnedBundleDto {
  const RemoteOwnedBundleDto({
    required this.userId,
    required this.bundleId,
    required this.acquisitionSource,
    required this.acquiredAt,
    required this.updatedAt,
  });

  final String userId;
  final String bundleId;
  final String acquisitionSource;
  final DateTime acquiredAt;
  final DateTime updatedAt;

  factory RemoteOwnedBundleDto.fromJson(
    Map<String, dynamic> json, {
    String? expectedUserId,
  }) {
    final userId = _trim(json['userId'] ?? json['user_id']);
    final bundleId = _trim(json['bundleId'] ?? json['bundle_id']);
    final acquisitionSource =
        _trim(json['acquisitionSource'] ?? json['acquisition_source']);
    final acquiredAt = _dateTime(json['acquiredAt'] ?? json['acquired_at']);
    final updatedAt = _dateTime(json['updatedAt'] ?? json['updated_at']);

    if (userId == null ||
        userId.isEmpty ||
        bundleId == null ||
        bundleId.isEmpty ||
        acquisitionSource == null ||
        acquisitionSource.isEmpty ||
        acquiredAt == null ||
        updatedAt == null) {
      throw const FormatException('Invalid remote owned bundle row.');
    }

    if (expectedUserId != null && expectedUserId.trim() != userId) {
      throw const FormatException('Owned bundle user scope mismatch.');
    }

    return RemoteOwnedBundleDto(
      userId: userId,
      bundleId: bundleId,
      acquisitionSource: acquisitionSource,
      acquiredAt: acquiredAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'userId': userId,
      'bundleId': bundleId,
      'acquisitionSource': acquisitionSource,
      'acquiredAt': acquiredAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class RemoteShopBundleDto {
  const RemoteShopBundleDto({
    required this.id,
    required this.familyId,
    required this.rarity,
    required this.priceCoins,
    required this.originalPriceCoins,
    required this.isActive,
    required this.sortOrder,
    required this.catalogVersion,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String familyId;
  final RemoteShopItemRarity rarity;
  final int priceCoins;
  final int originalPriceCoins;
  final bool isActive;
  final int sortOrder;
  final int catalogVersion;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory RemoteShopBundleDto.fromJson(Map<String, dynamic> json) {
    final id = _trim(json['id']);
    final familyId = _trim(json['familyId'] ?? json['family_id']);
    final priceCoins = _int(json['priceCoins'] ?? json['price_coins']);
    final originalPriceCoins =
        _int(json['originalPriceCoins'] ?? json['original_price_coins']);
    final sortOrder = _int(json['sortOrder'] ?? json['sort_order']);
    final catalogVersion =
        _int(json['catalogVersion'] ?? json['catalog_version']);
    final createdAt = _dateTime(json['createdAt'] ?? json['created_at']);
    final updatedAt = _dateTime(json['updatedAt'] ?? json['updated_at']);
    final rarity = _requiredBundleRarity(json['rarity']);

    if (id == null ||
        id.isEmpty ||
        familyId == null ||
        familyId.isEmpty ||
        priceCoins == null ||
        priceCoins < 0 ||
        originalPriceCoins == null ||
        originalPriceCoins < priceCoins ||
        sortOrder == null ||
        sortOrder < 0 ||
        catalogVersion == null ||
        catalogVersion < 1 ||
        createdAt == null ||
        updatedAt == null) {
      throw const FormatException('Invalid remote shop bundle row.');
    }

    return RemoteShopBundleDto(
      id: id,
      familyId: familyId,
      rarity: rarity,
      priceCoins: priceCoins,
      originalPriceCoins: originalPriceCoins,
      isActive: _bool(json['isActive'] ?? json['is_active']),
      sortOrder: sortOrder,
      catalogVersion: catalogVersion,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'familyId': familyId,
      'rarity': rarity.dbKey,
      'priceCoins': priceCoins,
      'originalPriceCoins': originalPriceCoins,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'catalogVersion': catalogVersion,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class RemoteShopBundleItemDto {
  const RemoteShopBundleItemDto({
    required this.bundleId,
    required this.itemId,
    required this.slot,
  });

  final String bundleId;
  final String itemId;
  final RemoteShopEquipSlot slot;

  factory RemoteShopBundleItemDto.fromJson(Map<String, dynamic> json) {
    final bundleId = _trim(json['bundleId'] ?? json['bundle_id']);
    final itemId = _trim(json['itemId'] ?? json['item_id']);
    final slot = RemoteShopEquipSlotX.fromKey(json['slot']);

    if (bundleId == null ||
        bundleId.isEmpty ||
        itemId == null ||
        itemId.isEmpty ||
        slot == RemoteShopEquipSlot.unknown) {
      throw const FormatException('Invalid remote shop bundle item row.');
    }

    return RemoteShopBundleItemDto(
      bundleId: bundleId,
      itemId: itemId,
      slot: slot,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'bundleId': bundleId,
      'itemId': itemId,
      'slot': slot.dbKey,
    };
  }
}

String? _trim(Object? value) {
  final normalized = (value ?? '').toString().trim();
  return normalized.isEmpty ? null : normalized;
}

String? _nullableTrim(Object? value) => _trim(value);

bool _bool(Object? value) {
  if (value is bool) return value;
  final normalized = (value ?? '').toString().trim().toLowerCase();
  return normalized == 'true' || normalized == '1' || normalized == 'yes';
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '').toString().trim());
}

int? _nullableInt(Object? value) => _int(value);

DateTime? _dateTime(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  final normalized = value.toString().trim();
  if (normalized.isEmpty) return null;
  return DateTime.tryParse(normalized);
}

RemoteShopItemRarity? _nullableRarity(Object? value) {
  final normalized = (value ?? '').toString().trim();
  if (normalized.isEmpty) return null;
  return RemoteShopItemRarityX.fromKey(normalized);
}

RemoteShopItemRarity _requiredBundleRarity(Object? value) {
  final rarity = _nullableRarity(value);
  if (rarity == null || rarity == RemoteShopItemRarity.unknown) {
    throw const FormatException('Invalid remote shop bundle row.');
  }
  return rarity;
}

RemoteShopEquipSlot? _nullableEquipSlot(Object? value) {
  final normalized = (value ?? '').toString().trim();
  if (normalized.isEmpty) return null;
  return RemoteShopEquipSlotX.fromKey(normalized);
}
