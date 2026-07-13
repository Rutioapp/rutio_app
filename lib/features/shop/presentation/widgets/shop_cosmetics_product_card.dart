import 'package:flutter/material.dart';
import 'package:rutio/features/shop/domain/models/shop_asset.dart';
import 'package:rutio/features/shop/domain/models/shop_asset_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_bundle.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_enums.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_primary_button.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_preview_placeholder.dart';
import 'package:rutio/widgets/currency/amber_coin_icon.dart';

class ShopCosmeticsProductCard extends StatelessWidget {
  const ShopCosmeticsProductCard.asset({
    super.key,
    required this.asset,
    required this.ownershipState,
    required this.hasEnoughCoins,
    required this.onPressed,
    required this.onPrimaryActionPressed,
    this.busy = false,
  })  : bundle = null,
        bundleAssets = const <ShopAsset>[],
        isBundleOwned = false;

  const ShopCosmeticsProductCard.bundle({
    super.key,
    required this.bundle,
    required this.bundleAssets,
    required this.isBundleOwned,
    required this.hasEnoughCoins,
    required this.onPressed,
    required this.onPrimaryActionPressed,
    this.busy = false,
  })  : asset = null,
        ownershipState = ShopAssetOwnershipState.locked;

  final ShopAsset? asset;
  final ShopAssetOwnershipState ownershipState;
  final ShopBundle? bundle;
  final List<ShopAsset> bundleAssets;
  final bool isBundleOwned;
  final bool hasEnoughCoins;
  final VoidCallback onPressed;
  final VoidCallback onPrimaryActionPressed;
  final bool busy;

  bool get _isBundle => bundle != null;

  @override
  Widget build(BuildContext context) {
    final String title = _isBundle ? bundle!.nameEs : asset!.nameEs;
    final ShopAssetRarity rarity = _isBundle ? bundle!.rarity : asset!.rarity;
    final int price = _isBundle ? bundle!.priceAmber : asset!.priceAmber;
    final _ProductActionState action = _resolveAction();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key(
          _isBundle
              ? 'shopCosmeticsBundleCard-${bundle!.id}'
              : 'shopCosmeticsAssetCard-${asset!.id}',
        ),
        onTap: onPressed,
        borderRadius: ShopUiTokens.radiusLgShape,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ShopUiTokens.surfaceRaised,
            borderRadius: ShopUiTokens.radiusLgShape,
            border: Border.all(
              color: action.highlight
                  ? ShopUiTokens.success.withValues(alpha: 0.45)
                  : ShopUiTokens.stroke.withValues(alpha: 0.9),
            ),
            boxShadow: ShopUiTokens.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ClipRRect(
                borderRadius: ShopUiTokens.radiusMdShape,
                child: SizedBox(
                  width: double.infinity,
                  height: 92,
                  child: _isBundle
                      ? ShopCosmeticsBundlePreview(assets: bundleAssets)
                      : ShopCosmeticsAssetPreview(asset: asset!),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: ShopUiTextStyles.label.copyWith(fontSize: 15),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _rarityLabel(rarity),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ShopUiTextStyles.labelSmall.copyWith(
                        color: ShopUiTokens.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const AmberCoinIcon(size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '$price',
                        style: ShopUiTextStyles.labelSmall.copyWith(
                          color: ShopUiTokens.textPrimary,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              if (action.showPrimaryButton)
                ShopPrimaryButton(
                  key: Key(
                    _isBundle
                        ? 'shopCosmeticsAction-${bundle!.id}'
                        : 'shopCosmeticsAction-${asset!.id}',
                  ),
                  label: busy ? 'Procesando...' : action.label,
                  onPressed:
                      busy || !action.enabled ? null : onPrimaryActionPressed,
                  icon: action.icon,
                )
              else
                _OwnedStateFooter(
                  label: action.statusLabel,
                  highlighted: action.highlight,
                ),
            ],
          ),
        ),
      ),
    );
  }

  _ProductActionState _resolveAction() {
    if (_isBundle) {
      if (isBundleOwned) {
        return const _ProductActionState(
          label: 'Comprado',
          statusLabel: 'Comprado',
          icon: Icons.check_circle_outline_rounded,
          enabled: false,
          highlight: true,
          showPrimaryButton: false,
        );
      }
      if (!hasEnoughCoins) {
        return const _ProductActionState(
          label: 'Saldo insuficiente',
          statusLabel: 'Bloqueado',
          icon: Icons.lock_outline_rounded,
          enabled: false,
        );
      }
      return const _ProductActionState(
        label: 'Comprar pack',
        statusLabel: 'Disponible',
        icon: Icons.shopping_bag_outlined,
        enabled: true,
      );
    }

    switch (ownershipState) {
      case ShopAssetOwnershipState.locked:
        if (!hasEnoughCoins) {
          return const _ProductActionState(
            label: 'Saldo insuficiente',
            statusLabel: 'Bloqueado',
            icon: Icons.lock_outline_rounded,
            enabled: false,
          );
        }
        return const _ProductActionState(
          label: 'Comprar',
          statusLabel: 'Disponible',
          icon: Icons.monetization_on_outlined,
          enabled: true,
        );
      case ShopAssetOwnershipState.owned:
        return const _ProductActionState(
          label: 'Comprado',
          statusLabel: 'Comprado',
          icon: Icons.check_circle_outline_rounded,
          enabled: false,
          showPrimaryButton: false,
        );
      case ShopAssetOwnershipState.includedInOwnedBundle:
        return const _ProductActionState(
          label: 'Incluido en pack',
          statusLabel: 'Incluido en pack',
          icon: Icons.inventory_2_outlined,
          enabled: false,
          showPrimaryButton: false,
        );
      case ShopAssetOwnershipState.equipped:
        return const _ProductActionState(
          label: 'Equipado',
          statusLabel: 'Equipado',
          icon: Icons.check_circle_outline_rounded,
          enabled: false,
          highlight: true,
          showPrimaryButton: false,
        );
    }
  }

  String _rarityLabel(ShopAssetRarity rarity) {
    switch (rarity) {
      case ShopAssetRarity.common:
        return 'Common';
      case ShopAssetRarity.rare:
        return 'Rare';
      case ShopAssetRarity.epic:
        return 'Epic';
      case ShopAssetRarity.legendary:
        return 'Legendary';
    }
  }
}

class _ProductActionState {
  const _ProductActionState({
    required this.label,
    required this.statusLabel,
    required this.icon,
    required this.enabled,
    this.highlight = false,
    this.showPrimaryButton = true,
  });

  final String label;
  final String statusLabel;
  final IconData icon;
  final bool enabled;
  final bool highlight;
  final bool showPrimaryButton;
}

class _OwnedStateFooter extends StatelessWidget {
  const _OwnedStateFooter({
    required this.label,
    required this.highlighted,
  });

  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlighted
            ? ShopUiTokens.successSoft
            : ShopUiTokens.backgroundAlt.withValues(alpha: 0.7),
        borderRadius: ShopUiTokens.radiusSmShape,
        border: Border.all(
          color: highlighted
              ? ShopUiTokens.success.withValues(alpha: 0.28)
              : ShopUiTokens.stroke,
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: ShopUiTextStyles.labelSmall.copyWith(
          color:
              highlighted ? ShopUiTokens.success : ShopUiTokens.textSecondary,
        ),
      ),
    );
  }
}

class ShopCosmeticsAssetPreview extends StatelessWidget {
  const ShopCosmeticsAssetPreview({super.key, required this.asset});

  final ShopAsset asset;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset.previewAssetPath,
      key: Key('shopCosmeticsPreview-${asset.id}'),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => ShopPreviewPlaceholder(
        label: asset.nameEs,
        tone: _toneForCategory(asset.category),
        height: 92,
        icon: _iconForCategory(asset.category),
      ),
    );
  }

  ShopPreviewPlaceholderTone _toneForCategory(ShopAssetCategory category) {
    switch (category) {
      case ShopAssetCategory.wallpaper:
        return ShopPreviewPlaceholderTone.camel;
      case ShopAssetCategory.habitCard:
        return ShopPreviewPlaceholderTone.sand;
      case ShopAssetCategory.userCard:
        return ShopPreviewPlaceholderTone.ice;
    }
  }

  IconData _iconForCategory(ShopAssetCategory category) {
    switch (category) {
      case ShopAssetCategory.wallpaper:
        return Icons.wallpaper_rounded;
      case ShopAssetCategory.habitCard:
        return Icons.view_agenda_outlined;
      case ShopAssetCategory.userCard:
        return Icons.badge_outlined;
    }
  }
}

class ShopCosmeticsBundlePreview extends StatelessWidget {
  const ShopCosmeticsBundlePreview({super.key, required this.assets});

  final List<ShopAsset> assets;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            ShopUiTokens.backgroundAlt,
            ShopUiTokens.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: assets.take(3).map((ShopAsset asset) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: ClipRRect(
                  borderRadius: ShopUiTokens.radiusSmShape,
                  child: ShopCosmeticsAssetPreview(asset: asset),
                ),
              ),
            );
          }).toList(growable: false),
        ),
      ),
    );
  }
}
