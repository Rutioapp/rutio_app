import 'shop_item_enums.dart';
import 'shop_item_price.dart';
import 'shop_model_utils.dart';

const Object _shopItemUnset = Object();

class ShopItem {
  const ShopItem({
    required this.id,
    required this.title,
    this.description = '',
    this.category = ShopItemCategory.cosmetic,
    this.type = ShopItemType.background,
    this.rarity = ShopItemRarity.common,
    this.collectionId,
    this.priceCoins = 0,
    this.assetRef,
    this.isEnabled = true,
    this.metadata = const <String, dynamic>{},
  });

  final String id;
  final String title;
  final String description;
  final ShopItemCategory category;
  final ShopItemType type;
  final ShopItemRarity rarity;
  final String? collectionId;
  final int priceCoins;
  final String? assetRef;
  final bool isEnabled;
  final Map<String, dynamic> metadata;

  ShopItemPrice get price => ShopItemPrice(coins: priceCoins);

  CosmeticSlot? get cosmeticSlot {
    switch (type) {
      case ShopItemType.background:
        return CosmeticSlot.background;
      case ShopItemType.habitCard:
        return CosmeticSlot.habitCard;
      case ShopItemType.userCard:
        return CosmeticSlot.userCard;
      case ShopItemType.xpBoost:
      case ShopItemType.coinBoost:
      case ShopItemType.streakRecover:
      case ShopItemType.streakShield:
      case ShopItemType.mysteryBox:
        return null;
    }
  }

  ConsumableType? get consumableType {
    switch (type) {
      case ShopItemType.xpBoost:
        return ConsumableType.xpBoost;
      case ShopItemType.coinBoost:
        return ConsumableType.coinBoost;
      case ShopItemType.streakRecover:
        return ConsumableType.streakRecover;
      case ShopItemType.streakShield:
        return ConsumableType.streakShield;
      case ShopItemType.mysteryBox:
        return ConsumableType.mysteryBox;
      case ShopItemType.background:
      case ShopItemType.habitCard:
      case ShopItemType.userCard:
        return null;
    }
  }

  ShopItem copyWith({
    String? id,
    String? title,
    String? description,
    ShopItemCategory? category,
    ShopItemType? type,
    ShopItemRarity? rarity,
    Object? collectionId = _shopItemUnset,
    int? priceCoins,
    Object? assetRef = _shopItemUnset,
    bool? isEnabled,
    Map<String, dynamic>? metadata,
  }) {
    return ShopItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      type: type ?? this.type,
      rarity: rarity ?? this.rarity,
      collectionId: identical(collectionId, _shopItemUnset)
          ? this.collectionId
          : collectionId as String?,
      priceCoins: priceCoins ?? this.priceCoins,
      assetRef: identical(assetRef, _shopItemUnset) ? this.assetRef : assetRef as String?,
      isEnabled: isEnabled ?? this.isEnabled,
      metadata: metadata ?? this.metadata,
    );
  }

  factory ShopItem.fromJson(Map<String, dynamic> json) {
    final priceJson = shopJsonMap(json['price']);
    return ShopItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      category: ShopItemCategoryX.fromKey(json['category']?.toString()),
      type: ShopItemTypeX.fromKey(json['type']?.toString()),
      rarity: ShopItemRarityX.fromKey(json['rarity']?.toString()),
      collectionId: json['collectionId']?.toString(),
      priceCoins: (json['priceCoins'] as num?)?.toInt() ??
          ShopItemPrice.fromJson(priceJson).coins,
      assetRef: json['assetRef']?.toString(),
      isEnabled: json['isEnabled'] as bool? ?? true,
      metadata: shopNormalizeMetadata(shopJsonMap(json['metadata'])),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'category': category.key,
      'type': type.key,
      'rarity': rarity.key,
      'collectionId': collectionId,
      'priceCoins': priceCoins,
      'assetRef': assetRef,
      'isEnabled': isEnabled,
      'metadata': metadata.map(
        (String key, dynamic value) => MapEntry(key, shopJsonValue(value)),
      ),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShopItem &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.category == category &&
        other.type == type &&
        other.rarity == rarity &&
        other.collectionId == collectionId &&
        other.priceCoins == priceCoins &&
        other.assetRef == assetRef &&
        other.isEnabled == isEnabled &&
        shopDeepEquals(other.metadata, metadata);
  }

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        category,
        type,
        rarity,
        collectionId,
        priceCoins,
        assetRef,
        isEnabled,
        shopDeepHash(metadata),
      );
}
