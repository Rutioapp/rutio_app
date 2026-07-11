import 'package:flutter/material.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/widgets/currency/amber_coin_icon.dart';

class ShopWalletPill extends StatelessWidget {
  const ShopWalletPill({
    super.key,
    required this.coins,
    this.backgroundColor = ShopUiTokens.surfaceRaised,
    this.foregroundColor = ShopUiTokens.textPrimary,
    this.compact = false,
  });

  final int coins;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double iconBoxSize = compact ? 20 : 24;
    final double horizontalPadding = compact ? 10 : 12;
    final double verticalPadding = compact ? 8 : 10;
    final double gap = compact ? 6 : 8;
    final TextStyle textStyle = compact
        ? ShopUiTextStyles.wallet.copyWith(fontSize: 14, color: foregroundColor)
        : ShopUiTextStyles.wallet.copyWith(color: foregroundColor);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: ShopUiTokens.radiusXlShape,
        border: Border.all(color: ShopUiTokens.stroke),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: compact ? 36 : 44,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: iconBoxSize,
                height: iconBoxSize,
                child: Center(
                  child: AmberCoinIcon(size: iconBoxSize),
                ),
              ),
              SizedBox(width: gap),
              Flexible(
                child: Text(
                  '$coins',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
