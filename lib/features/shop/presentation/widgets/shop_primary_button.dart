import 'package:flutter/material.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';

class ShopPrimaryButton extends StatelessWidget {
  const ShopPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expanded = true,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final bool compact;

  bool get isEnabled => onPressed != null;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: isEnabled ? ShopUiTokens.textPrimary : ShopUiTokens.backgroundAlt,
      borderRadius: ShopUiTokens.radiusXlShape,
      child: InkWell(
        onTap: onPressed,
        borderRadius: ShopUiTokens.radiusXlShape,
        child: Ink(
          height: compact ? 48 : ShopUiTokens.buttonHeight,
          padding: compact
              ? const EdgeInsets.symmetric(horizontal: 16)
              : ShopUiTokens.buttonPadding,
          decoration: BoxDecoration(
            borderRadius: ShopUiTokens.radiusXlShape,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(
                  icon,
                  size: compact ? 16 : 18,
                  color: isEnabled
                      ? ShopUiTokens.surfaceRaised
                      : ShopUiTokens.textTertiary,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: isEnabled
                      ? (compact
                          ? ShopUiTextStyles.button.copyWith(fontSize: 13.5)
                          : ShopUiTextStyles.button)
                      : (compact
                          ? ShopUiTextStyles.buttonDisabled
                              .copyWith(fontSize: 13.5)
                          : ShopUiTextStyles.buttonDisabled),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
