import 'package:flutter/material.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_item_card.dart';

class ShopUtilityItemCard extends StatelessWidget {
  const ShopUtilityItemCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final ShopItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ShopItemCard(
      title: item.title,
      price: item.priceCoins,
      description: item.description,
      rarity: item.rarity,
      badgeLabel: 'Utilidad',
      onTap: onTap,
      footer: const SizedBox.shrink(),
    );
  }
}
