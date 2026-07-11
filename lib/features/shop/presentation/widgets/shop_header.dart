import 'package:flutter/material.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_wallet_pill.dart';
import 'package:rutio/widgets/app_header/app_header.dart';

class ShopHeader extends StatelessWidget {
  const ShopHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.titleStyle,
    this.leadingIcon,
    this.onLeadingPressed,
    this.trailingIcon,
    this.onTrailingPressed,
    this.walletCoins,
    this.useDrawerLeadingStyle = false,
  });

  final String title;
  final String? subtitle;
  final TextStyle? titleStyle;
  final IconData? leadingIcon;
  final VoidCallback? onLeadingPressed;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingPressed;
  final int? walletCoins;
  final bool useDrawerLeadingStyle;

  @override
  Widget build(BuildContext context) {
    final Widget? leading = _buildLeading();
    final Widget? trailing = _buildTrailing();
    final TextStyle effectiveTitleStyle = titleStyle ?? _resolveTitleStyle();

    return Padding(
      padding: ShopUiTokens.headerPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            height: ShopUiTokens.minTouchTarget,
            child: CustomMultiChildLayout(
              delegate: _ShopHeaderLayoutDelegate(horizontalGap: 4),
              children: <Widget>[
                if (leading != null)
                  LayoutId(
                    id: _ShopHeaderSlot.leading,
                    child: leading,
                  ),
                LayoutId(
                  id: _ShopHeaderSlot.title,
                  child: Padding(
                    padding: EdgeInsets.zero,
                    child: Text(
                      title,
                      key: const Key('shopHeaderTitle'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: effectiveTitleStyle,
                    ),
                  ),
                ),
                if (trailing != null)
                  LayoutId(
                    id: _ShopHeaderSlot.trailing,
                    child: trailing,
                  ),
              ],
            ),
          ),
          if (subtitle != null && subtitle!.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                subtitle!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: ShopUiTextStyles.subtitle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget? _buildLeading() {
    if (leadingIcon == null && onLeadingPressed == null) {
      return null;
    }

    if (useDrawerLeadingStyle && onLeadingPressed != null) {
      return AppDrawerButton(
        onTap: onLeadingPressed!,
        color: ShopUiTokens.textPrimary,
        boxSize: ShopUiTokens.minTouchTarget,
        iconSize: 22,
      );
    }

    return _HeaderIconButton(
      icon: leadingIcon ?? Icons.arrow_back_ios_new_rounded,
      onPressed: onLeadingPressed,
    );
  }

  Widget? _buildTrailing() {
    if (walletCoins == null && trailingIcon == null) {
      return null;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (walletCoins != null)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 124),
            child: ShopWalletPill(
              coins: walletCoins!,
              compact: true,
            ),
          ),
        if (walletCoins != null && trailingIcon != null)
          const SizedBox(width: 8),
        if (trailingIcon != null)
          _HeaderIconButton(
            icon: trailingIcon!,
            onPressed: onTrailingPressed,
          ),
      ],
    );
  }

  TextStyle _resolveTitleStyle() {
    final int titleLength = title.trim().length;
    final bool useCompactTitle =
        titleLength >= 10 || (walletCoins != null && titleLength >= 9);
    if (!useCompactTitle) {
      return ShopUiTextStyles.headerTitle;
    }

    if (walletCoins != null && titleLength >= 12) {
      return ShopUiTextStyles.headerTitleCompact.copyWith(fontSize: 13.5);
    }

    return ShopUiTextStyles.headerTitleCompact;
  }
}

enum _ShopHeaderSlot {
  leading,
  title,
  trailing,
}

class _ShopHeaderLayoutDelegate extends MultiChildLayoutDelegate {
  _ShopHeaderLayoutDelegate({
    required this.horizontalGap,
  });

  final double horizontalGap;

  @override
  void performLayout(Size size) {
    Size leadingSize = Size.zero;
    Size trailingSize = Size.zero;

    if (hasChild(_ShopHeaderSlot.leading)) {
      leadingSize = layoutChild(
        _ShopHeaderSlot.leading,
        BoxConstraints.loose(size),
      );
    }
    if (hasChild(_ShopHeaderSlot.trailing)) {
      trailingSize = layoutChild(
        _ShopHeaderSlot.trailing,
        BoxConstraints.loose(size),
      );
    }

    final double mirroredSideWidth = leadingSize.width > trailingSize.width
        ? leadingSize.width
        : trailingSize.width;
    final double titleMaxWidth =
        (size.width - (mirroredSideWidth * 2) - (horizontalGap * 2))
            .clamp(0.0, size.width);

    final Size titleSize = layoutChild(
      _ShopHeaderSlot.title,
      BoxConstraints(
        maxWidth: titleMaxWidth,
        maxHeight: size.height,
      ),
    );

    if (hasChild(_ShopHeaderSlot.leading)) {
      positionChild(
        _ShopHeaderSlot.leading,
        Offset(0, (size.height - leadingSize.height) / 2),
      );
    }

    positionChild(
      _ShopHeaderSlot.title,
      Offset((size.width - titleSize.width) / 2,
          (size.height - titleSize.height) / 2),
    );

    if (hasChild(_ShopHeaderSlot.trailing)) {
      positionChild(
        _ShopHeaderSlot.trailing,
        Offset(size.width - trailingSize.width,
            (size.height - trailingSize.height) / 2),
      );
    }
  }

  @override
  bool shouldRelayout(_ShopHeaderLayoutDelegate oldDelegate) {
    return oldDelegate.horizontalGap != horizontalGap;
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
      color:
          ShopUiTokens.surface.withValues(alpha: onPressed == null ? 0.55 : 1),
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
