import 'package:flutter/material.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';

class ShopWalletPill extends StatelessWidget {
  const ShopWalletPill({
    super.key,
    required this.coins,
    this.backgroundColor = ShopUiTokens.surfaceRaised,
    this.foregroundColor = ShopUiTokens.textPrimary,
  });

  final int coins;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: ShopUiTokens.radiusXlShape,
        border: Border.all(color: ShopUiTokens.stroke),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: ShopUiTokens.coinSoft,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.monetization_on_rounded,
                size: ShopUiTokens.walletIconSize,
                color: ShopUiTokens.coin,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '$coins',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ShopUiTextStyles.wallet.copyWith(color: foregroundColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
