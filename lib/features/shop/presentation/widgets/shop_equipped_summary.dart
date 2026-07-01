import 'package:flutter/material.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_customization_preview.dart';

class ShopEquippedSummary extends StatelessWidget {
  const ShopEquippedSummary({
    super.key,
    this.backgroundItem,
    this.habitCardItem,
    this.userCardItem,
  });

  final ShopItem? backgroundItem;
  final ShopItem? habitCardItem;
  final ShopItem? userCardItem;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ShopUiTokens.surfaceRaised,
        borderRadius: ShopUiTokens.radiusLgShape,
        border: Border.all(color: ShopUiTokens.stroke),
        boxShadow: ShopUiTokens.softShadow,
      ),
      child: Padding(
        padding: ShopUiTokens.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Preview actual',
              style: ShopUiTextStyles.sectionTitle,
            ),
            const SizedBox(height: 8),
            const Text(
              'Una vista suave del set equipado ahora mismo.',
              style: ShopUiTextStyles.subtitle,
            ),
            const SizedBox(height: 16),
            ShopCustomizationPreview(
              backgroundItem: backgroundItem,
              habitCardItem: habitCardItem,
              userCardItem: userCardItem,
            ),
          ],
        ),
      ),
    );
  }
}
