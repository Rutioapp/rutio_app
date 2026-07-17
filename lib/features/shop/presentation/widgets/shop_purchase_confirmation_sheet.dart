import 'package:flutter/material.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/presentation/shop_localizations.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_primary_button.dart';
import 'package:rutio/l10n/l10n.dart';

class ShopPurchaseConfirmationSheet extends StatelessWidget {
  const ShopPurchaseConfirmationSheet({
    super.key,
    required this.item,
    required this.walletCoins,
    required this.onCancel,
    required this.onConfirm,
  });

  final ShopItem item;
  final int walletCoins;
  final VoidCallback onCancel;
  final ValueChanged<String> onConfirm;

  bool get hasEnoughCoins => walletCoins >= item.priceCoins;
  int get remainingCoins => walletCoins - item.priceCoins;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: FractionallySizedBox(
          heightFactor: 0.56,
          alignment: Alignment.bottomCenter,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: ShopUiTokens.surfaceRaised,
              borderRadius: ShopUiTokens.radiusXlShape,
              border: Border.all(color: ShopUiTokens.stroke),
              boxShadow: ShopUiTokens.softShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: ShopUiTokens.strokeStrong,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l10n.shopConfirmPurchaseTitle,
                    style: ShopUiTextStyles.cardTitle,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            l10n.shopUtilityTitleForItem(item),
                            style:
                                ShopUiTextStyles.label.copyWith(fontSize: 15),
                          ),
                          const SizedBox(height: 16),
                          _InfoRow(
                            label: l10n.shopPriceLabel,
                            value: l10n.shopPriceCoins(item.priceCoins),
                          ),
                          const SizedBox(height: 10),
                          _InfoRow(
                            label: l10n.shopCurrentBalanceLabel,
                            value: l10n.shopPriceCoins(walletCoins),
                          ),
                          const SizedBox(height: 10),
                          _InfoRow(
                            label: l10n.shopRemainingBalanceLabel,
                            value: l10n.shopPriceCoins(
                              remainingCoins.clamp(0, 1 << 31),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            hasEnoughCoins
                                ? l10n.shopActionAvailable
                                : l10n.shopStatusInsufficientCoins,
                            style: ShopUiTextStyles.bodySmall.copyWith(
                              color: hasEnoughCoins
                                  ? ShopUiTokens.textSecondary
                                  : ShopUiTokens.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onCancel,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: ShopUiTokens.strokeStrong,
                            ),
                            foregroundColor: ShopUiTokens.textPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: ShopUiTokens.radiusXlShape,
                            ),
                          ),
                          child: Text(l10n.shopCancel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ShopPrimaryButton(
                          key: const Key('shopPurchaseConfirmButton'),
                          label: hasEnoughCoins
                              ? l10n.shopActionBuy
                              : l10n.shopStatusInsufficientCoins,
                          onPressed:
                              hasEnoughCoins ? () => onConfirm(item.id) : null,
                          expanded: true,
                          icon: hasEnoughCoins
                              ? Icons.monetization_on_outlined
                              : Icons.lock_outline_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: ShopUiTextStyles.bodySmall,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: ShopUiTextStyles.label,
        ),
      ],
    );
  }
}
