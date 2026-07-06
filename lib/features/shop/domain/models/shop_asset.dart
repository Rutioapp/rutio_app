import 'package:rutio/features/shop/domain/models/shop_asset_enums.dart';

class ShopAsset {
  const ShopAsset({
    required this.id,
    required this.familyId,
    required this.category,
    required this.rarity,
    required this.nameEs,
    required this.nameEn,
    required this.priceAmber,
    required this.assetPath,
    required this.previewAssetPath,
    this.isPurchasable = true,
    this.sortOrder = 0,
  });

  final String id;
  final String familyId;
  final ShopAssetCategory category;
  final ShopAssetRarity rarity;
  final String nameEs;
  final String nameEn;
  final int priceAmber;
  final String assetPath;
  final String previewAssetPath;
  final bool isPurchasable;
  final int sortOrder;

  ShopAsset copyWith({
    String? id,
    String? familyId,
    ShopAssetCategory? category,
    ShopAssetRarity? rarity,
    String? nameEs,
    String? nameEn,
    int? priceAmber,
    String? assetPath,
    String? previewAssetPath,
    bool? isPurchasable,
    int? sortOrder,
  }) {
    return ShopAsset(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      category: category ?? this.category,
      rarity: rarity ?? this.rarity,
      nameEs: nameEs ?? this.nameEs,
      nameEn: nameEn ?? this.nameEn,
      priceAmber: priceAmber ?? this.priceAmber,
      assetPath: assetPath ?? this.assetPath,
      previewAssetPath: previewAssetPath ?? this.previewAssetPath,
      isPurchasable: isPurchasable ?? this.isPurchasable,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  factory ShopAsset.fromJson(Map<String, dynamic> json) {
    return ShopAsset(
      id: (json['id'] ?? '').toString(),
      familyId: (json['familyId'] ?? '').toString(),
      category: ShopAssetCategoryX.fromKey(json['category']?.toString()),
      rarity: ShopAssetRarityX.fromKey(json['rarity']?.toString()),
      nameEs: (json['nameEs'] ?? '').toString(),
      nameEn: (json['nameEn'] ?? '').toString(),
      priceAmber: (json['priceAmber'] as num?)?.toInt() ?? 0,
      assetPath: (json['assetPath'] ?? '').toString(),
      previewAssetPath: (json['previewAssetPath'] ?? '').toString(),
      isPurchasable: json['isPurchasable'] as bool? ?? true,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'familyId': familyId,
      'category': category.key,
      'rarity': rarity.key,
      'nameEs': nameEs,
      'nameEn': nameEn,
      'priceAmber': priceAmber,
      'assetPath': assetPath,
      'previewAssetPath': previewAssetPath,
      'isPurchasable': isPurchasable,
      'sortOrder': sortOrder,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShopAsset &&
        other.id == id &&
        other.familyId == familyId &&
        other.category == category &&
        other.rarity == rarity &&
        other.nameEs == nameEs &&
        other.nameEn == nameEn &&
        other.priceAmber == priceAmber &&
        other.assetPath == assetPath &&
        other.previewAssetPath == previewAssetPath &&
        other.isPurchasable == isPurchasable &&
        other.sortOrder == sortOrder;
  }

  @override
  int get hashCode => Object.hash(
        id,
        familyId,
        category,
        rarity,
        nameEs,
        nameEn,
        priceAmber,
        assetPath,
        previewAssetPath,
        isPurchasable,
        sortOrder,
      );
}
