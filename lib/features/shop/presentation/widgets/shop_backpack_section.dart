import 'package:flutter/material.dart';
import 'package:rutio/features/shop/presentation/models/backpack_item_view_model.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_backpack_item_card.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_section_header.dart';

class ShopBackpackSection extends StatelessWidget {
  const ShopBackpackSection({
    super.key,
    required this.title,
    required this.items,
    required this.onItemPressed,
    required this.onUsePressed,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<BackpackItemViewModel> items;
  final ValueChanged<String> onItemPressed;
  final Future<void> Function(String) onUsePressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: Key('shopBackpackSection-$title'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ShopSectionHeader(
          title: title,
          subtitle: subtitle ?? '${items.length} items',
        ),
        const SizedBox(height: 12),
        for (int index = 0; index < items.length; index++) ...<Widget>[
          ShopBackpackItemCard(
            key: Key('shopBackpackCard-${items[index].itemId}'),
            item: items[index],
            onTap: () => onItemPressed(items[index].itemId),
            onUsePressed: onUsePressed,
          ),
          if (index < items.length - 1)
            const SizedBox(height: ShopUiTokens.itemSpacing),
        ],
      ],
    );
  }
}
