import 'package:rutio/features/shop/domain/models/shop_asset_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_model_utils.dart';

class ShopBundle {
  ShopBundle({
    required this.id,
    required this.familyId,
    required this.rarity,
    required this.nameEs,
    required this.nameEn,
    required this.priceAmber,
    required List<String> assetIds,
    this.isPurchasable = true,
    this.sortOrder = 0,
  }) : assetIds = List<String>.unmodifiable(assetIds);

  final String id;
  final String familyId;
  final ShopAssetRarity rarity;
  final String nameEs;
  final String nameEn;
  final int priceAmber;
  final List<String> assetIds;
  final bool isPurchasable;
  final int sortOrder;

  ShopBundle copyWith({
    String? id,
    String? familyId,
    ShopAssetRarity? rarity,
    String? nameEs,
    String? nameEn,
    int? priceAmber,
    List<String>? assetIds,
    bool? isPurchasable,
    int? sortOrder,
  }) {
    return ShopBundle(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      rarity: rarity ?? this.rarity,
      nameEs: nameEs ?? this.nameEs,
      nameEn: nameEn ?? this.nameEn,
      priceAmber: priceAmber ?? this.priceAmber,
      assetIds: assetIds ?? this.assetIds,
      isPurchasable: isPurchasable ?? this.isPurchasable,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  factory ShopBundle.fromJson(Map<String, dynamic> json) {
    return ShopBundle(
      id: (json['id'] ?? '').toString(),
      familyId: (json['familyId'] ?? '').toString(),
      rarity: ShopAssetRarityX.fromKey(json['rarity']?.toString()),
      nameEs: (json['nameEs'] ?? '').toString(),
      nameEn: (json['nameEn'] ?? '').toString(),
      priceAmber: (json['priceAmber'] as num?)?.toInt() ?? 0,
      assetIds: shopJsonList<String>(
        json['assetIds'],
        (dynamic value) => value.toString(),
      ),
      isPurchasable: json['isPurchasable'] as bool? ?? true,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'familyId': familyId,
      'rarity': rarity.key,
      'nameEs': nameEs,
      'nameEn': nameEn,
      'priceAmber': priceAmber,
      'assetIds': assetIds,
      'isPurchasable': isPurchasable,
      'sortOrder': sortOrder,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShopBundle &&
        other.id == id &&
        other.familyId == familyId &&
        other.rarity == rarity &&
        other.nameEs == nameEs &&
        other.nameEn == nameEn &&
        other.priceAmber == priceAmber &&
        shopDeepEquals(other.assetIds, assetIds) &&
        other.isPurchasable == isPurchasable &&
        other.sortOrder == sortOrder;
  }

  @override
  int get hashCode => Object.hash(
        id,
        familyId,
        rarity,
        nameEs,
        nameEn,
        priceAmber,
        Object.hashAll(assetIds),
        isPurchasable,
        sortOrder,
      );
}
