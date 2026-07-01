import 'package:flutter/material.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';

class ShopFilterChip extends StatelessWidget {
  const ShopFilterChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? ShopUiTokens.textPrimary : ShopUiTokens.surfaceRaised,
      borderRadius: ShopUiTokens.radiusXlShape,
      child: InkWell(
        onTap: onTap,
        borderRadius: ShopUiTokens.radiusXlShape,
        child: Ink(
          padding: ShopUiTokens.chipPadding,
          decoration: BoxDecoration(
            borderRadius: ShopUiTokens.radiusXlShape,
            border: Border.all(
              color: selected
                  ? ShopUiTokens.textPrimary
                  : ShopUiTokens.strokeStrong,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ShopUiTextStyles.label.copyWith(
              color: selected
                  ? ShopUiTokens.surfaceRaised
                  : ShopUiTokens.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
