import 'package:flutter/material.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';

class ShopUtilityVisualConfig {
  const ShopUtilityVisualConfig({
    this.padding = const EdgeInsets.all(10),
    this.scale = 1.0,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
  });

  final EdgeInsets padding;
  final double scale;
  final BoxFit fit;
  final Alignment alignment;

  static const ShopUtilityVisualConfig standard = ShopUtilityVisualConfig();

  static const ShopUtilityVisualConfig mysteryBox = ShopUtilityVisualConfig(
    padding: EdgeInsets.all(2),
    scale: 1.22,
  );

  static ShopUtilityVisualConfig forItem(ShopItem item) {
    if (item.type == ShopItemType.mysteryBox ||
        item.id == 'utility_mystery_box_basic') {
      return mysteryBox;
    }
    return standard;
  }
}
