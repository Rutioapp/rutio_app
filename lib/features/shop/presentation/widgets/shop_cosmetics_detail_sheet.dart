import 'package:flutter/material.dart';
import 'package:rutio/features/shop/domain/models/shop_asset.dart';
import 'package:rutio/features/shop/domain/models/shop_asset_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_bundle.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_enums.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_cosmetics_product_card.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_cosmetics_rarity_badge.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_header.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_primary_button.dart';

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
        isBundleOwned = false;

  const ShopCosmeticsDetailSheet.bundle({
    super.key,
    required this.bundle,
    required this.bundleAssets,
    required this.isBundleOwned,
    required this.walletCoins,
    required this.onPrimaryActionPressed,
    this.busy = false,
  })  : asset = null,
        ownershipState = ShopAssetOwnershipState.locked;

  final ShopAsset? asset;
  final ShopAssetOwnershipState ownershipState;
  final ShopBundle? bundle;
  final List<ShopAsset> bundleAssets;
  final bool isBundleOwned;
  final int walletCoins;
  final VoidCallback onPrimaryActionPressed;
  final bool busy;

  bool get _isBundle => bundle != null;

  @override
  Widget build(BuildContext context) {
    final title = _isBundle ? bundle!.nameEs : asset!.nameEs;
    final rarity = _isBundle ? bundle!.rarity : asset!.rarity;
    final price = _isBundle ? bundle!.priceAmber : asset!.priceAmber;
    final canBuy = walletCoins >= price;
    final action = _resolveAction(canBuy);
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
                title: 'Detalle',
                subtitle:
                    _isBundle ? 'Pack' : _assetCategoryLabel(asset!.category),
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
                              : ShopCosmeticsAssetPreview(asset: asset!),
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
                        _description(),
                        style: ShopUiTextStyles.subtitle,
                      ),
                      const SizedBox(height: 18),
                      _DetailRow(label: 'Categoria', value: _categoryLabel()),
                      const SizedBox(height: 12),
                      _DetailRow(label: 'Precio', value: '$price ambar'),
                      const SizedBox(height: 12),
                      _DetailRow(label: 'Estado', value: action.statusLabel),
                      if (_isBundle) ...<Widget>[
                        const SizedBox(height: 16),
                        Text('Incluye', style: ShopUiTextStyles.label),
                        const SizedBox(height: 8),
                        ...bundleAssets.map(
                          (ShopAsset asset) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _DetailRow(
                              label: _assetCategoryLabel(asset.category),
                              value: asset.nameEs,
                            ),
                          ),
                        ),
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
                      if (!action.enabled) ...<Widget>[
                        Text(
                          action.label == 'Comprar'
                              ? 'Todavía no se realiza la compra real desde esta pantalla.'
                              : 'Este cosmético ya no requiere una acción adicional.',
                          style: ShopUiTextStyles.bodySmall,
                        ),
                        const SizedBox(height: 12),
                      ],
                      ShopPrimaryButton(
                        key: Key(
                          _isBundle
                              ? 'shopCosmeticsDetailAction-${bundle!.id}'
                              : 'shopCosmeticsDetailAction-${asset!.id}',
                        ),
                        label: busy ? 'Procesando...' : action.label,
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

  _SheetAction _resolveAction(bool canBuy) {
    if (_isBundle) {
      if (isBundleOwned) {
        return const _SheetAction(
          label: 'Comprado',
          statusLabel: 'Comprado',
          icon: Icons.check_circle_outline_rounded,
          enabled: false,
        );
      }
      return _SheetAction(
        label: canBuy ? 'Comprar pack' : 'Saldo insuficiente',
        statusLabel: canBuy ? 'Disponible' : 'Bloqueado',
        icon: canBuy ? Icons.shopping_bag_outlined : Icons.lock_outline_rounded,
        enabled: canBuy,
      );
    }

    switch (ownershipState) {
      case ShopAssetOwnershipState.locked:
        return _SheetAction(
          label: canBuy ? 'Comprar' : 'Saldo insuficiente',
          statusLabel: 'Bloqueado',
          icon: canBuy
              ? Icons.monetization_on_outlined
              : Icons.lock_outline_rounded,
          enabled: canBuy,
        );
      case ShopAssetOwnershipState.owned:
        return const _SheetAction(
          label: 'Equipar',
          statusLabel: 'Comprado',
          icon: Icons.auto_fix_high_rounded,
          enabled: true,
        );
      case ShopAssetOwnershipState.equipped:
        return const _SheetAction(
          label: 'Equipado',
          statusLabel: 'Equipado',
          icon: Icons.check_circle_outline_rounded,
          enabled: false,
        );
      case ShopAssetOwnershipState.includedInOwnedBundle:
        return const _SheetAction(
          label: 'Equipar',
          statusLabel: 'Incluido en pack',
          icon: Icons.auto_fix_high_rounded,
          enabled: true,
        );
    }
  }

  String _description() {
    if (_isBundle) {
      return 'Un pack sereno con fondo y cards coordinadas para mantener una estetica Rutio consistente.';
    }
    return switch (asset!.category) {
      ShopAssetCategory.wallpaper =>
        'Un fondo calmado para refrescar la vista principal de Rutio.',
      ShopAssetCategory.habitCard =>
        'Una habit card con tono suave para elevar la lectura diaria.',
      ShopAssetCategory.userCard =>
        'Una user card premium y minimal para tu identidad dentro de Rutio.',
    };
  }

  String _categoryLabel() {
    if (_isBundle) return 'Pack';
    return _assetCategoryLabel(asset!.category);
  }

  String _assetCategoryLabel(ShopAssetCategory category) {
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

class _SheetAction {
  const _SheetAction({
    required this.label,
    required this.statusLabel,
    required this.icon,
    required this.enabled,
  });

  final String label;
  final String statusLabel;
  final IconData icon;
  final bool enabled;
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
