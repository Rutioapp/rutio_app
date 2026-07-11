import 'package:flutter/material.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';

class ShopItemDetailInfoRow extends StatelessWidget {
  const ShopItemDetailInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueKey,
    this.valueStyle,
    this.valueMaxLines = 2,
  });

  final String label;
  final String value;
  final Key? valueKey;
  final TextStyle? valueStyle;
  final int valueMaxLines;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ShopUiTokens.surfaceRaised,
        borderRadius: ShopUiTokens.radiusMdShape,
        border: Border.all(color: ShopUiTokens.stroke),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: ShopUiTextStyles.bodySmall,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                value,
                key: valueKey,
                textAlign: TextAlign.start,
                style: valueStyle ?? ShopUiTextStyles.label,
                maxLines: valueMaxLines,
                overflow: TextOverflow.clip,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
