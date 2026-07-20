import 'package:flutter/painting.dart';

import 'package:rutio/features/shop/domain/models/habit_card_content_tone.dart';
import 'package:rutio/features/shop/domain/models/shop_asset_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';

const Object _shopAssetUnset = Object();

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
    this.imageFit = BoxFit.cover,
    this.imageAlignmentX = 0,
    this.imageAlignmentY = 0,
    this.overlayColorValue,
    this.overlayOpacity = 0,
    this.contentTone = HabitCardContentTone.dark,
    this.useContentScrim = false,
    this.isPurchasable = true,
    this.sortOrder = 0,
  });

  static final Map<String, AssetImage> _assetImageCache =
      <String, AssetImage>{};

  final String id;
  final String familyId;
  final ShopAssetCategory category;
  final ShopAssetRarity rarity;
  final String nameEs;
  final String nameEn;
  final int priceAmber;
  final String assetPath;
  final String previewAssetPath;
  final BoxFit imageFit;
  final double imageAlignmentX;
  final double imageAlignmentY;
  final int? overlayColorValue;
  final double overlayOpacity;
  final HabitCardContentTone contentTone;
  final bool useContentScrim;
  final bool isPurchasable;
  final int sortOrder;

  CosmeticSlot? get cosmeticSlot {
    switch (category) {
      case ShopAssetCategory.wallpaper:
        return CosmeticSlot.background;
      case ShopAssetCategory.habitCard:
        return CosmeticSlot.habitCard;
      case ShopAssetCategory.userCard:
        return CosmeticSlot.userCard;
    }
  }

  AssetImage get imageProvider =>
      _assetImageCache.putIfAbsent(assetPath, () => AssetImage(assetPath));

  Alignment get imageAlignment => Alignment(imageAlignmentX, imageAlignmentY);

  Color? get overlayColor =>
      overlayColorValue == null ? null : Color(overlayColorValue!);

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
    BoxFit? imageFit,
    double? imageAlignmentX,
    double? imageAlignmentY,
    Object? overlayColorValue = _shopAssetUnset,
    double? overlayOpacity,
    HabitCardContentTone? contentTone,
    bool? useContentScrim,
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
      imageFit: imageFit ?? this.imageFit,
      imageAlignmentX: imageAlignmentX ?? this.imageAlignmentX,
      imageAlignmentY: imageAlignmentY ?? this.imageAlignmentY,
      overlayColorValue: identical(overlayColorValue, _shopAssetUnset)
          ? this.overlayColorValue
          : overlayColorValue as int?,
      overlayOpacity: overlayOpacity ?? this.overlayOpacity,
      contentTone: contentTone ?? this.contentTone,
      useContentScrim: useContentScrim ?? this.useContentScrim,
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
      imageFit: _boxFitFromKey(json['imageFit']?.toString()),
      imageAlignmentX: (json['imageAlignmentX'] as num?)?.toDouble() ?? 0,
      imageAlignmentY: (json['imageAlignmentY'] as num?)?.toDouble() ?? 0,
      overlayColorValue: (json['overlayColorValue'] as num?)?.toInt(),
      overlayOpacity: (json['overlayOpacity'] as num?)?.toDouble() ?? 0,
      contentTone:
          HabitCardContentToneX.fromKey(json['contentTone']?.toString()),
      useContentScrim: json['useContentScrim'] as bool? ?? false,
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
      'imageFit': _boxFitKey(imageFit),
      'imageAlignmentX': imageAlignmentX,
      'imageAlignmentY': imageAlignmentY,
      'overlayColorValue': overlayColorValue,
      'overlayOpacity': overlayOpacity,
      'contentTone': contentTone.key,
      'useContentScrim': useContentScrim,
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
        other.imageFit == imageFit &&
        other.imageAlignmentX == imageAlignmentX &&
        other.imageAlignmentY == imageAlignmentY &&
        other.overlayColorValue == overlayColorValue &&
        other.overlayOpacity == overlayOpacity &&
        other.contentTone == contentTone &&
        other.useContentScrim == useContentScrim &&
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
        imageFit,
        imageAlignmentX,
        imageAlignmentY,
        overlayColorValue,
        overlayOpacity,
        contentTone,
        useContentScrim,
        isPurchasable,
        sortOrder,
      );

  static BoxFit _boxFitFromKey(String? key) {
    switch ((key ?? '').trim()) {
      case 'contain':
        return BoxFit.contain;
      case 'fill':
        return BoxFit.fill;
      case 'fitHeight':
        return BoxFit.fitHeight;
      case 'fitWidth':
        return BoxFit.fitWidth;
      case 'none':
        return BoxFit.none;
      case 'scaleDown':
        return BoxFit.scaleDown;
      case 'cover':
      default:
        return BoxFit.cover;
    }
  }

  static String _boxFitKey(BoxFit fit) {
    switch (fit) {
      case BoxFit.contain:
        return 'contain';
      case BoxFit.cover:
        return 'cover';
      case BoxFit.fill:
        return 'fill';
      case BoxFit.fitHeight:
        return 'fitHeight';
      case BoxFit.fitWidth:
        return 'fitWidth';
      case BoxFit.none:
        return 'none';
      case BoxFit.scaleDown:
        return 'scaleDown';
    }
  }
}
