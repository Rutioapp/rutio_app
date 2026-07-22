import 'package:flutter/material.dart';
import 'package:rutio/features/shop/domain/models/shop_asset.dart';
import 'package:rutio/features/shop/domain/models/shop_asset_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_bundle.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_cosmetics_product_card.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_primary_button.dart';

class ShopOwnedBundleCard extends StatelessWidget {
  const ShopOwnedBundleCard({
    super.key,
    required this.bundle,
    required this.bundleAssets,
    required this.isEquipped,
    this.busy = false,
    required this.onEquipPressed,
  });

  final ShopBundle bundle;
  final List<ShopAsset> bundleAssets;
  final bool isEquipped;
  final bool busy;
  final Future<void> Function(String bundleId) onEquipPressed;

  @override
  Widget build(BuildContext context) {
    final bool highlighted = isEquipped;
    final String buttonLabel = busy
        ? 'Equipando...'
        : isEquipped
            ? 'Pack equipado'
            : 'Equipar pack';
    final String statusLabel = busy
        ? 'Equipando...'
        : isEquipped
            ? 'Pack equipado'
            : 'Disponible';

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: ShopUiTokens.surfaceRaised,
          borderRadius: ShopUiTokens.radiusLgShape,
          border: Border.all(
            color: highlighted
                ? ShopUiTokens.success.withValues(alpha: 0.35)
                : ShopUiTokens.stroke,
          ),
        ),
        child: Padding(
          padding: ShopUiTokens.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ClipRRect(
                borderRadius: ShopUiTokens.radiusMdShape,
                child: SizedBox(
                  width: double.infinity,
                  height: 94,
                  child: ShopCosmeticsBundlePreview(assets: bundleAssets),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                bundle.nameEs,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: ShopUiTextStyles.cardTitle.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _rarityLabel(bundle.rarity),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ShopUiTextStyles.labelSmall.copyWith(
                        color: ShopUiTokens.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    statusLabel,
                    style: ShopUiTextStyles.labelSmall.copyWith(
                      color: highlighted
                          ? ShopUiTokens.success
                          : ShopUiTokens.textSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ShopPrimaryButton(
                key: Key('shopOwnedBundleAction-${bundle.id}'),
                label: buttonLabel,
                icon: isEquipped
                    ? Icons.check_rounded
                    : Icons.playlist_add_rounded,
                onPressed: busy || isEquipped
                    ? null
                    : () => onEquipPressed(bundle.id),
              ),
            ],
          ),
        ),
      ),
    );
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
