import 'package:flutter/material.dart';
import 'package:rutio/features/shop/domain/models/shop_asset.dart';
import 'package:rutio/features/shop/domain/models/shop_asset_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_bundle.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_enums.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_cosmetics_rarity_badge.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_preview_placeholder.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_primary_button.dart';

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
    final title = _isBundle ? bundle!.nameEs : asset!.nameEs;
    final subtitle = _isBundle ? _bundleSubtitle() : _assetSubtitle(asset!);
    final rarity = _isBundle ? bundle!.rarity : asset!.rarity;
    final price = _isBundle ? bundle!.priceAmber : asset!.priceAmber;
    final action = _resolveAction();
    final palette = ShopCosmeticsRarityPalette.fromRarity(rarity);

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
                  ? palette.border
                  : ShopUiTokens.stroke.withValues(alpha: 0.9),
            ),
            boxShadow: ShopUiTokens.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Stack(
                children: <Widget>[
                  ClipRRect(
                    borderRadius: ShopUiTokens.radiusMdShape,
                    child: SizedBox(
                      height: 116,
                      width: double.infinity,
                      child: _isBundle
                          ? ShopCosmeticsBundlePreview(assets: bundleAssets)
                          : ShopCosmeticsAssetPreview(asset: asset!),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: ShopCosmeticsRarityBadge(rarity: rarity, compact: true),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _StatusChip(action.statusLabel),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: ShopUiTextStyles.label.copyWith(fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ShopUiTextStyles.bodySmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _InfoChip(
                      label: _isBundle ? 'Pack' : _categoryLabel(asset!.category),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(label: '$price'),
                ],
              ),
              const Spacer(),
              ShopPrimaryButton(
                key: Key(
                  _isBundle
                      ? 'shopCosmeticsAction-${bundle!.id}'
                      : 'shopCosmeticsAction-${asset!.id}',
                ),
                label: busy ? 'Procesando...' : action.label,
                onPressed: busy || !action.enabled ? null : onPrimaryActionPressed,
                icon: action.icon,
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
        statusLabel: 'Bloqueado',
        icon: Icons.monetization_on_outlined,
        enabled: true,
      );
      case ShopAssetOwnershipState.owned:
        return const _ProductActionState(
          label: 'Equipar',
          statusLabel: 'Comprado',
          icon: Icons.auto_fix_high_rounded,
          enabled: true,
        );
      case ShopAssetOwnershipState.includedInOwnedBundle:
        return const _ProductActionState(
          label: 'Equipar',
          statusLabel: 'Incluido en pack',
          icon: Icons.auto_fix_high_rounded,
          enabled: true,
        );
      case ShopAssetOwnershipState.equipped:
        return const _ProductActionState(
          label: 'Equipado',
          statusLabel: 'Equipado',
          icon: Icons.check_circle_outline_rounded,
          enabled: false,
          highlight: true,
        );
    }
  }

  String _assetSubtitle(ShopAsset asset) {
    final state = switch (ownershipState) {
      ShopAssetOwnershipState.locked => 'Bloqueado',
      ShopAssetOwnershipState.owned => 'Comprado',
      ShopAssetOwnershipState.equipped => 'Equipado',
      ShopAssetOwnershipState.includedInOwnedBundle => 'Incluido en pack',
    };
    return '${_categoryLabel(asset.category)} · $state';
  }

  String _bundleSubtitle() {
    final count = bundleAssets.length;
    return '$count cosmeticos incluidos';
  }

  String _categoryLabel(ShopAssetCategory category) {
    switch (category) {
      case ShopAssetCategory.wallpaper:
        return 'Fondo';
      case ShopAssetCategory.habitCard:
        return 'Habit card';
      case ShopAssetCategory.userCard:
        return 'User card';
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
  });

  final String label;
  final String statusLabel;
  final IconData icon;
  final bool enabled;
  final bool highlight;
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('shopCosmeticsStatus-$label'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ShopUiTokens.surface.withValues(alpha: 0.92),
        borderRadius: ShopUiTokens.radiusXlShape,
        border: Border.all(color: ShopUiTokens.stroke),
      ),
      child: Text(
        label,
        style: ShopUiTextStyles.labelSmall.copyWith(
          color: ShopUiTokens.textPrimary,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ShopUiTokens.backgroundAlt,
        borderRadius: ShopUiTokens.radiusXlShape,
      ),
      child: Text(label, style: ShopUiTextStyles.labelSmall),
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
        height: 148,
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
        padding: const EdgeInsets.all(10),
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
