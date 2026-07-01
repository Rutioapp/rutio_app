import 'package:flutter/material.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_wallet_pill.dart';

class ShopHeader extends StatelessWidget {
  const ShopHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.onLeadingPressed,
    this.trailingIcon,
    this.onTrailingPressed,
    this.walletCoins,
  });

  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final VoidCallback? onLeadingPressed;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingPressed;
  final int? walletCoins;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ShopUiTokens.headerPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _HeaderIconButton(
                icon: leadingIcon ?? Icons.arrow_back_ios_new_rounded,
                onPressed: onLeadingPressed,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ShopUiTextStyles.pageTitle,
                    ),
                    if (subtitle != null && subtitle!.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: ShopUiTextStyles.subtitle,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (walletCoins != null) ...<Widget>[
                Flexible(
                  child: ShopWalletPill(coins: walletCoins!),
                ),
                if (trailingIcon != null) const SizedBox(width: 8),
              ],
              if (trailingIcon != null)
                _HeaderIconButton(
                  icon: trailingIcon!,
                  onPressed: onTrailingPressed,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ShopUiTokens.surface.withValues(alpha: onPressed == null ? 0.55 : 1),
      borderRadius: ShopUiTokens.radiusSmShape,
      child: InkWell(
        onTap: onPressed,
        borderRadius: ShopUiTokens.radiusSmShape,
        child: SizedBox(
          width: ShopUiTokens.minTouchTarget,
          height: ShopUiTokens.minTouchTarget,
          child: Icon(
            icon,
            size: ShopUiTokens.headerIconSize,
            color: onPressed == null
                ? ShopUiTokens.textTertiary
                : ShopUiTokens.textPrimary,
          ),
        ),
      ),
    );
  }
}
