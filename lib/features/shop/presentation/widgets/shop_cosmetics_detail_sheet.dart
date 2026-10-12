import 'package:flutter/material.dart';
import 'package:rutio/features/shop/domain/models/shop_asset.dart';
import 'package:rutio/features/shop/domain/models/shop_asset_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_bundle.dart';
import 'package:rutio/features/shop/domain/models/shop_bundle_completion_quote.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_enums.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/shop_localizations.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_cosmetics_product_card.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_cosmetics_rarity_badge.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_header.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_item_asset_preview.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_primary_button.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/l10n/l10n.dart';

class ShopCosmeticsDetailSheet extends StatelessWidget {
  const ShopCosmeticsDetailSheet.asset({
    super.key,
    required this.asset,
    required this.ownershipState,
    required this.walletCoins,
    required this.onPrimaryActionPressed,
    this.busy = false,
  })  : bundle = null,
        bundleAssets = const <ShopAsset>[],
        completionQuote = null;

  const ShopCosmeticsDetailSheet.bundle({
    super.key,
    required this.bundle,
    required this.bundleAssets,
    required this.completionQuote,
    required this.walletCoins,
    required this.onPrimaryActionPressed,
    this.busy = false,
  })  : asset = null,
        ownershipState = ShopAssetOwnershipState.locked;

  final ShopAsset? asset;
  final ShopAssetOwnershipState ownershipState;
  final ShopBundle? bundle;
  final List<ShopAsset> bundleAssets;
  final ShopBundleCompletionQuote? completionQuote;
  final int walletCoins;
  final VoidCallback onPrimaryActionPressed;
  final bool busy;

  bool get _isBundle => bundle != null;

  int get _price => _isBundle
      ? completionQuote?.effectivePriceAmber ?? bundle!.priceAmber
      : asset!.priceAmber;

  bool get _hasEnoughCoins => walletCoins >= _price;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = _isBundle
        ? l10n.shopBundleName(completionQuote?.bundle ?? bundle!)
        : l10n.shopAssetName(asset!);
    final rarity = _isBundle
        ? completionQuote?.bundle.rarity ?? bundle!.rarity
        : asset!.rarity;
    final action = _resolveAction(l10n, _hasEnoughCoins);
    final mediaHeight = MediaQuery.sizeOf(context).height;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: mediaHeight * 0.92),
        child: Container(
          key: const Key('shopCosmeticsDetailSheet'),
          decoration: BoxDecoration(
            color: ShopUiTokens.surfaceRaised,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ShopUiTokens.strokeStrong,
                    borderRadius: ShopUiTokens.radiusXlShape,
                  ),
                ),
              ),
              ShopHeader(
                title: l10n.shopDetailTitle,
                subtitle:
                    _isBundle
                        ? l10n.shopCategoryPack
                        : l10n.shopAssetCategoryLabel(asset!.category),
                leadingIcon: Icons.arrow_back_ios_new_rounded,
                onLeadingPressed: () => Navigator.of(context).pop(),
                walletCoins: walletCoins,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: ShopUiTokens.radiusLgShape,
                        child: SizedBox(
                          height: _isBundle ? 210 : 230,
                          child: _isBundle
                              ? ShopCosmeticsBundlePreview(assets: bundleAssets)
                              : ShopCosmeticsAssetPreview(
                                  asset: asset!,
                                  mode: switch (asset!.category) {
                                    ShopAssetCategory.habitCard ||
                                    ShopAssetCategory.userCard =>
                                      ShopAssetPreviewMode.applied,
                                    ShopAssetCategory.wallpaper =>
                                      ShopAssetPreviewMode.visual,
                                  },
                                ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              title,
                              style: ShopUiTextStyles.cardTitle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          ShopCosmeticsRarityBadge(rarity: rarity),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _description(l10n),
                        style: ShopUiTextStyles.subtitle,
                      ),
                      const SizedBox(height: 18),
                      _DetailRow(
                        label: l10n.shopCategoryLabel,
                        value: _categoryLabel(l10n),
                      ),
                      const SizedBox(height: 12),
                      if (_isBundle) ..._bundleInfoRows(l10n),
                      _DetailRow(label: l10n.shopStatusLabel, value: action.statusLabel),
                      if (_isBundle) ...<Widget>[
                        const SizedBox(height: 16),
                        Text(l10n.shopIncludesLabel, style: ShopUiTextStyles.label),
                        const SizedBox(height: 8),
                        ...bundleAssets.map(
                          (ShopAsset asset) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _DetailRow(
                              label: l10n.shopAssetCategoryLabel(asset.category),
                              value: l10n.shopAssetName(asset),
                            ),
                          ),
                        ),
                        if (completionQuote?.isPartiallyOwned ?? false) ...<Widget>[
                          const SizedBox(height: 8),
                          _DetailRow(
                            label: l10n.shopMissingItemsLabel,
                            value: _missingAssetsLabel(l10n),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      if (action.showPrimaryButton && !action.enabled) ...<Widget>[
                        Text(
                          action.message ?? l10n.shopDetailNoActionMessage,
                          style: ShopUiTextStyles.bodySmall,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (action.showPrimaryButton)
                        ShopPrimaryButton(
                          key: Key(
                            _isBundle
                                ? 'shopCosmeticsDetailAction-${bundle!.id}'
                                : 'shopCosmeticsDetailAction-${asset!.id}',
                          ),
                          label: busy ? l10n.shopProcessingLabel : action.label,
                          onPressed: busy || !action.enabled
                              ? null
                              : onPrimaryActionPressed,
                          icon: action.icon,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _bundleInfoRows(AppLocalizations l10n) {
    final quote = completionQuote;
    if (quote == null) {
      return const <Widget>[];
    }

    if (quote.isExplicitlyOwned || quote.isCompleteFromItems) {
      return const <Widget>[];
    }

    return <Widget>[
      _DetailRow(
        label: quote.isPartiallyOwned
            ? l10n.shopCompletionPriceLabel
            : l10n.shopPriceLabel,
        value: l10n.shopPriceAmber(_price),
      ),
      if (quote.isPartiallyOwned) ...<Widget>[
        const SizedBox(height: 12),
        _DetailRow(
          label: l10n.shopMissingItemsLabel,
          value: _missingAssetsLabel(l10n),
        ),
        const SizedBox(height: 12),
      ],
    ];
  }

  _SheetAction _resolveAction(AppLocalizations l10n, bool canBuy) {
    if (_isBundle) {
      final quote = completionQuote;
      if (quote == null) {
        return _SheetAction(
          label: l10n.shopStatusBlocked,
          statusLabel: l10n.shopStatusUnavailable,
          icon: Icons.lock_outline_rounded,
          enabled: false,
          showPrimaryButton: false,
          message: null,
        );
      }
      if (quote.isExplicitlyOwned) {
        return _SheetAction(
          label: l10n.shopStatusPurchased,
          statusLabel: l10n.shopStatusPurchased,
          icon: Icons.check_circle_outline_rounded,
          enabled: false,
          showPrimaryButton: false,
          message: null,
        );
      }
      if (quote.isCompleteFromItems) {
        return _SheetAction(
          label: l10n.shopBundleCompleted,
          statusLabel: l10n.shopBundleCompleted,
          icon: Icons.check_circle_outline_rounded,
          enabled: false,
          showPrimaryButton: false,
          message: null,
        );
      }
      if (quote.isPartiallyOwned) {
        return _SheetAction(
          label: canBuy ? l10n.shopCompletePackAction : l10n.shopStatusInsufficientCoins,
          statusLabel: l10n.shopBundleOwnedCount(quote.ownedItemCount),
          icon: Icons.auto_fix_high_rounded,
          enabled: canBuy,
          showPrimaryButton: true,
          message: canBuy
              ? l10n.shopDetailPartialBundleMessage
              : l10n.shopDetailInsufficientAmberMessage,
        );
      }
      return _SheetAction(
        label: canBuy ? l10n.shopActionBuyPack : l10n.shopStatusInsufficientCoins,
        statusLabel: canBuy ? l10n.shopActionAvailable : l10n.shopStatusBlocked,
        icon: canBuy ? Icons.shopping_bag_outlined : Icons.lock_outline_rounded,
        enabled: canBuy,
        showPrimaryButton: true,
        message: canBuy ? null : l10n.shopDetailInsufficientAmberMessage,
      );
    }

    switch (ownershipState) {
      case ShopAssetOwnershipState.locked:
        return _SheetAction(
          label: canBuy ? l10n.shopActionBuy : l10n.shopStatusInsufficientCoins,
          statusLabel: l10n.shopStatusBlocked,
          icon: canBuy
              ? Icons.monetization_on_outlined
              : Icons.lock_outline_rounded,
          enabled: canBuy,
          showPrimaryButton: true,
          message: canBuy ? null : l10n.shopDetailInsufficientAmberMessage,
        );
      case ShopAssetOwnershipState.owned:
        return _SheetAction(
          label: l10n.shopActionEquip,
          statusLabel: l10n.shopStatusPurchased,
          icon: Icons.auto_fix_high_rounded,
          enabled: true,
          showPrimaryButton: true,
          message: null,
        );
      case ShopAssetOwnershipState.equipped:
        return _SheetAction(
          label: l10n.shopActionEquipped,
          statusLabel: l10n.shopActionEquipped,
          icon: Icons.check_circle_outline_rounded,
          enabled: false,
          showPrimaryButton: true,
          message: null,
        );
      case ShopAssetOwnershipState.includedInOwnedBundle:
        return _SheetAction(
          label: l10n.shopActionEquip,
          statusLabel: l10n.shopStatusIncludedInPack,
          icon: Icons.auto_fix_high_rounded,
          enabled: true,
          showPrimaryButton: true,
          message: null,
        );
    }
  }

  String _description(AppLocalizations l10n) {
    if (_isBundle) {
      return l10n.shopBundleDescription(completionQuote?.bundle ?? bundle!);
    }
    return switch (asset!.category) {
      ShopAssetCategory.wallpaper =>
        l10n.shopWallpaperDescription,
      ShopAssetCategory.habitCard =>
        l10n.shopHabitCardDescription,
      ShopAssetCategory.userCard =>
        l10n.shopUserCardDescription,
    };
  }

  String _categoryLabel(AppLocalizations l10n) {
    if (_isBundle) return l10n.shopCategoryPack;
    return l10n.shopAssetCategoryLabel(asset!.category);
  }

  String _missingAssetsLabel(AppLocalizations l10n) {
    final missing = completionQuote?.missingAssets ?? const <ShopAsset>[];
    return missing.map(l10n.shopAssetName).join(', ');
  }
}

class _SheetAction {
  const _SheetAction({
    required this.label,
    required this.statusLabel,
    required this.icon,
    required this.enabled,
    required this.showPrimaryButton,
    this.message,
  });

  final String label;
  final String statusLabel;
  final IconData icon;
  final bool enabled;
  final bool showPrimaryButton;
  final String? message;
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
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
