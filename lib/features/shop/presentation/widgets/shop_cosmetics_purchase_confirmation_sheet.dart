import 'package:flutter/material.dart';
import 'package:rutio/features/shop/domain/models/shop_asset.dart';
import 'package:rutio/features/shop/domain/models/shop_bundle.dart';
import 'package:rutio/features/shop/presentation/shop_localizations.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_cosmetics_rarity_badge.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_primary_button.dart';
import 'package:rutio/l10n/l10n.dart';

class ShopCosmeticsPurchaseConfirmationSheet extends StatelessWidget {
  const ShopCosmeticsPurchaseConfirmationSheet.asset({
    super.key,
    required this.asset,
    required this.walletCoins,
    required this.onCancel,
    required this.onConfirm,
  })  : bundle = null,
        bundleAssets = const <ShopAsset>[];

  const ShopCosmeticsPurchaseConfirmationSheet.bundle({
    super.key,
    required this.bundle,
    required this.bundleAssets,
    required this.walletCoins,
    required this.onCancel,
    required this.onConfirm,
  }) : asset = null;

  final ShopAsset? asset;
  final ShopBundle? bundle;
  final List<ShopAsset> bundleAssets;
  final int walletCoins;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  bool get _isBundle => bundle != null;

  int get _price => _isBundle ? bundle!.priceAmber : asset!.priceAmber;

  bool get _hasEnoughCoins => walletCoins >= _price;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: FractionallySizedBox(
          heightFactor: 0.68,
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
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  _isBundle ? bundle!.nameEs : asset!.nameEs,
                                  style: ShopUiTextStyles.label.copyWith(
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ShopCosmeticsRarityBadge(
                                rarity:
                                    _isBundle ? bundle!.rarity : asset!.rarity,
                                compact: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (!_isBundle) ...<Widget>[
                            _InfoRow(
                              label: l10n.shopCategoryLabel,
                              value: l10n.shopAssetCategoryLabel(
                                asset!.category,
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          if (_isBundle) ...<Widget>[
                            _InfoRow(
                              label: l10n.shopOriginalPriceLabel,
                              value: l10n.shopPriceAmber(
                                bundle!.originalPriceAmber,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _InfoRow(
                              label: l10n.shopSavingsLabel,
                              value: l10n.shopPriceAmber(bundle!.savingsAmber),
                            ),
                            const SizedBox(height: 10),
                          ],
                          _InfoRow(
                            label: l10n.shopPriceLabel,
                            value: l10n.shopPriceAmber(_price),
                          ),
                          const SizedBox(height: 10),
                          _InfoRow(
                            label: l10n.shopCurrentBalanceLabel,
                            value: l10n.shopPriceAmber(walletCoins),
                          ),
                          if (_isBundle) ...<Widget>[
                            const SizedBox(height: 14),
                            Text(
                              l10n.shopIncludesLabel,
                              style: ShopUiTextStyles.label,
                            ),
                            const SizedBox(height: 8),
                            ...bundleAssets.map(
                              (ShopAsset includedAsset) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _InfoRow(
                                  label: l10n.shopAssetCategoryLabel(
                                    includedAsset.category,
                                  ),
                                  value: includedAsset.nameEs,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          Text(
                            _hasEnoughCoins
                                ? l10n.shopActionAvailable
                                : l10n.shopStatusInsufficientCoins,
                            style: ShopUiTextStyles.bodySmall.copyWith(
                              color: _hasEnoughCoins
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
                          key: const Key(
                            'shopCosmeticsPurchaseConfirmationCancel',
                          ),
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
                          key: Key(
                            _isBundle
                                ? 'shopCosmeticsPurchaseConfirmationConfirm-${bundle!.id}'
                                : 'shopCosmeticsPurchaseConfirmationConfirm-${asset!.id}',
                          ),
                          label: _isBundle
                              ? l10n.shopActionBuyPack
                              : l10n.shopActionBuy,
                          onPressed: _hasEnoughCoins ? onConfirm : null,
                          expanded: true,
                          icon: _hasEnoughCoins
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
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: ShopUiTextStyles.label,
          ),
        ),
      ],
    );
  }
}
