import 'package:flutter/material.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_item_asset_preview.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_preview_placeholder.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_primary_button.dart';

class ShopOwnedItemCard extends StatelessWidget {
  const ShopOwnedItemCard({
    super.key,
    required this.item,
    required this.isEquipped,
    required this.onTap,
    required this.onEquipPressed,
  });

  final ShopItem item;
  final bool isEquipped;
  final VoidCallback onTap;
  final ValueChanged<String> onEquipPressed;

  @override
  Widget build(BuildContext context) {
    final bool isBackground = item.type == ShopItemType.background;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: ShopUiTokens.radiusLgShape,
        child: Ink(
          decoration: BoxDecoration(
            color: ShopUiTokens.surfaceRaised,
            borderRadius: ShopUiTokens.radiusLgShape,
            border: Border.all(
              color: isEquipped
                  ? ShopUiTokens.success.withValues(alpha: 0.35)
                  : ShopUiTokens.stroke,
            ),
          ),
          child: Padding(
            padding: ShopUiTokens.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _PreviewBlock(
                  item: item,
                  isEquipped: isEquipped,
                  isBackground: isBackground,
                ),
                const SizedBox(height: 12),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ShopUiTextStyles.cardTitle.copyWith(fontSize: 18),
                ),
                const Spacer(),
                const SizedBox(height: 14),
                ShopPrimaryButton(
                  key: Key('shopOwnedEquip-${item.id}'),
                  label: isEquipped ? 'Equipado' : 'Equipar',
                  icon: isEquipped
                      ? Icons.check_rounded
                      : Icons.playlist_add_rounded,
                  onPressed: isEquipped ? null : () => onEquipPressed(item.id),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewBlock extends StatelessWidget {
  const _PreviewBlock({
    required this.item,
    required this.isEquipped,
    required this.isBackground,
  });

  final ShopItem item;
  final bool isEquipped;
  final bool isBackground;

  @override
  Widget build(BuildContext context) {
    final Widget preview = ClipRRect(
      borderRadius: ShopUiTokens.radiusMdShape,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: double.infinity,
        height: isBackground ? 110 : 96,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ShopItemAssetPreview(
              item: item,
              fallbackLabel: item.title,
              fallbackTone: _toneForItem(item.type),
              height: isBackground ? 110 : 96,
              fallbackIcon: _iconForItem(item.type),
              fit: BoxFit.cover,
            ),
            if (isEquipped)
              Positioned(
                top: 8,
                left: 8,
                child: _StatusBadge(
                  key: Key('shopOwnedStatus-${item.id}'),
                ),
              ),
          ],
        ),
      ),
    );

    if (!isEquipped) {
      return preview;
    }

    return preview;
  }

  ShopPreviewPlaceholderTone _toneForItem(ShopItemType type) {
    switch (type) {
      case ShopItemType.background:
        return ShopPreviewPlaceholderTone.camel;
      case ShopItemType.habitCard:
        return ShopPreviewPlaceholderTone.sand;
      case ShopItemType.userCard:
        return ShopPreviewPlaceholderTone.ice;
      case ShopItemType.xpBoost:
      case ShopItemType.coinBoost:
      case ShopItemType.streakRecover:
      case ShopItemType.streakShield:
      case ShopItemType.mysteryBox:
        return ShopPreviewPlaceholderTone.sage;
    }
  }

  IconData _iconForItem(ShopItemType type) {
    switch (type) {
      case ShopItemType.background:
        return Icons.wallpaper_rounded;
      case ShopItemType.habitCard:
        return Icons.view_agenda_outlined;
      case ShopItemType.userCard:
        return Icons.badge_outlined;
      case ShopItemType.xpBoost:
        return Icons.bolt_rounded;
      case ShopItemType.coinBoost:
        return Icons.payments_rounded;
      case ShopItemType.streakRecover:
        return Icons.restore_rounded;
      case ShopItemType.streakShield:
        return Icons.shield_rounded;
      case ShopItemType.mysteryBox:
        return Icons.card_giftcard_rounded;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ShopUiTokens.successSoft,
        borderRadius: ShopUiTokens.radiusXlShape,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          'Equipado',
          style: ShopUiTextStyles.labelSmall.copyWith(
            color: ShopUiTokens.success,
          ),
        ),
      ),
    );
  }
}
