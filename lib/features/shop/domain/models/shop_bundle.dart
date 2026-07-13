import 'package:rutio/features/shop/domain/models/shop_asset_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_model_utils.dart';

class ShopBundle {
  ShopBundle({
    required this.id,
    required this.familyId,
    required this.rarity,
    required this.nameEs,
    required this.nameEn,
    required this.descriptionEs,
    required this.descriptionEn,
    required this.wallpaperItemId,
    required this.habitCardItemId,
    required this.userCardItemId,
    required this.originalPriceAmber,
    required this.priceAmber,
    required this.discountPercentage,
    this.isFeatured = false,
    this.isPurchasable = true,
    this.sortOrder = 0,
  })  : assetIds = List<String>.unmodifiable(<String>[
          wallpaperItemId,
          habitCardItemId,
          userCardItemId,
        ]),
        assert(
          <String>{
                wallpaperItemId,
                habitCardItemId,
                userCardItemId,
              }.length ==
              3,
          'A bundle must contain three distinct cosmetic items.',
        );

  final String id;
  final String familyId;
  final ShopAssetRarity rarity;
  final String nameEs;
  final String nameEn;
  final String descriptionEs;
  final String descriptionEn;
  final String wallpaperItemId;
  final String habitCardItemId;
  final String userCardItemId;
  final int originalPriceAmber;
  final int priceAmber;
  final int discountPercentage;
  final bool isFeatured;
  final List<String> assetIds;
  final bool isPurchasable;
  final int sortOrder;

  int get discountedPriceAmber => priceAmber;

  int get savingsAmber => originalPriceAmber - priceAmber;

  ShopBundle copyWith({
    String? id,
    String? familyId,
    ShopAssetRarity? rarity,
    String? nameEs,
    String? nameEn,
    String? descriptionEs,
    String? descriptionEn,
    String? wallpaperItemId,
    String? habitCardItemId,
    String? userCardItemId,
    int? originalPriceAmber,
    int? priceAmber,
    int? discountPercentage,
    bool? isFeatured,
    bool? isPurchasable,
    int? sortOrder,
  }) {
    return ShopBundle(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      rarity: rarity ?? this.rarity,
      nameEs: nameEs ?? this.nameEs,
      nameEn: nameEn ?? this.nameEn,
      descriptionEs: descriptionEs ?? this.descriptionEs,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      wallpaperItemId: wallpaperItemId ?? this.wallpaperItemId,
      habitCardItemId: habitCardItemId ?? this.habitCardItemId,
      userCardItemId: userCardItemId ?? this.userCardItemId,
      originalPriceAmber: originalPriceAmber ?? this.originalPriceAmber,
      priceAmber: priceAmber ?? this.priceAmber,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      isFeatured: isFeatured ?? this.isFeatured,
      isPurchasable: isPurchasable ?? this.isPurchasable,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  factory ShopBundle.fromJson(Map<String, dynamic> json) {
    final assetIds = shopJsonList<String>(
      json['assetIds'],
      (dynamic value) => value.toString(),
    );
    final fallbackWallpaperId = assetIds.isNotEmpty ? assetIds[0] : '';
    final fallbackHabitCardId = assetIds.length > 1 ? assetIds[1] : '';
    final fallbackUserCardId = assetIds.length > 2 ? assetIds[2] : '';
    final wallpaperItemId =
        (json['wallpaperItemId'] ?? fallbackWallpaperId).toString();
    final habitCardItemId =
        (json['habitCardItemId'] ?? fallbackHabitCardId).toString();
    final userCardItemId =
        (json['userCardItemId'] ?? fallbackUserCardId).toString();
    final discountedPriceAmber =
        (json['discountedPriceAmber'] as num?)?.toInt() ??
            (json['priceAmber'] as num?)?.toInt() ??
            0;
    final computedOriginal =
        (json['originalPriceAmber'] as num?)?.toInt() ?? discountedPriceAmber;
    final resolvedDiscountPercentage =
        (json['discountPercentage'] as num?)?.toInt() ?? 0;

    return ShopBundle(
      id: (json['id'] ?? '').toString(),
      familyId: (json['familyId'] ?? '').toString(),
      rarity: ShopAssetRarityX.fromKey(json['rarity']?.toString()),
      nameEs: (json['nameEs'] ?? '').toString(),
      nameEn: (json['nameEn'] ?? '').toString(),
      descriptionEs: (json['descriptionEs'] ?? '').toString(),
      descriptionEn: (json['descriptionEn'] ?? '').toString(),
      wallpaperItemId: wallpaperItemId,
      habitCardItemId: habitCardItemId,
      userCardItemId: userCardItemId,
      originalPriceAmber: computedOriginal,
      priceAmber: discountedPriceAmber,
      discountPercentage: resolvedDiscountPercentage,
      isFeatured: json['isFeatured'] as bool? ?? false,
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
      'descriptionEs': descriptionEs,
      'descriptionEn': descriptionEn,
      'wallpaperItemId': wallpaperItemId,
      'habitCardItemId': habitCardItemId,
      'userCardItemId': userCardItemId,
      'originalPriceAmber': originalPriceAmber,
      'priceAmber': priceAmber,
      'discountedPriceAmber': discountedPriceAmber,
      'discountPercentage': discountPercentage,
      'isFeatured': isFeatured,
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
        other.descriptionEs == descriptionEs &&
        other.descriptionEn == descriptionEn &&
        other.wallpaperItemId == wallpaperItemId &&
        other.habitCardItemId == habitCardItemId &&
        other.userCardItemId == userCardItemId &&
        other.originalPriceAmber == originalPriceAmber &&
        other.priceAmber == priceAmber &&
        other.discountPercentage == discountPercentage &&
        other.isFeatured == isFeatured &&
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
        descriptionEs,
        descriptionEn,
        wallpaperItemId,
        habitCardItemId,
        userCardItemId,
        originalPriceAmber,
        priceAmber,
        discountPercentage,
        isFeatured,
        Object.hashAll(assetIds),
        isPurchasable,
        sortOrder,
      );
}
