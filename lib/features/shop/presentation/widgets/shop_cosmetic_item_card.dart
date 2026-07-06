import 'package:flutter/material.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_item_asset_preview.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_preview_placeholder.dart';

class ShopCosmeticItemCard extends StatelessWidget {
  const ShopCosmeticItemCard({
    super.key,
    required this.item,
    required this.onPressed,
    this.isOwned = false,
    this.isEquipped = false,
  });

  final ShopItem item;
  final VoidCallback onPressed;
  final bool isOwned;
  final bool isEquipped;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: ShopUiTokens.radiusLgShape,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ShopUiTokens.surfaceRaised,
            borderRadius: ShopUiTokens.radiusLgShape,
            border: Border.all(
              color: isEquipped
                  ? ShopUiTokens.success.withValues(alpha: 0.35)
                  : ShopUiTokens.stroke,
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
                    child: ShopItemAssetPreview(
                      item: item,
                      fallbackLabel: item.title,
                      fallbackTone: _toneForItem(item),
                      height: 132,
                      fallbackIcon: _iconForItem(item.type),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _StatusBadge(
                      isOwned: isOwned,
                      isEquipped: isEquipped,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.title,
                style: ShopUiTextStyles.label.copyWith(fontSize: 15),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _subtitleForType(item.type),
                      style: ShopUiTextStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _PricePill(price: item.priceCoins),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  ShopPreviewPlaceholderTone _toneForItem(ShopItem item) {
    switch (item.type) {
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
      case ShopItemType.coinBoost:
      case ShopItemType.streakRecover:
      case ShopItemType.streakShield:
      case ShopItemType.mysteryBox:
        return Icons.auto_awesome_rounded;
    }
  }

  String _subtitleForType(ShopItemType type) {
    switch (type) {
      case ShopItemType.background:
        return 'Fondo';
      case ShopItemType.habitCard:
        return 'Card de hábitos';
      case ShopItemType.userCard:
        return 'Card de usuario';
      case ShopItemType.xpBoost:
      case ShopItemType.coinBoost:
      case ShopItemType.streakRecover:
      case ShopItemType.streakShield:
      case ShopItemType.mysteryBox:
        return 'Utilidad';
    }
  }
}

class _PricePill extends StatelessWidget {
  const _PricePill({required this.price});

  final int price;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ShopUiTokens.coinSoft,
        borderRadius: ShopUiTokens.radiusXlShape,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.monetization_on_rounded,
              size: 14,
              color: ShopUiTokens.coin,
            ),
            const SizedBox(width: 4),
            Text('$price', style: ShopUiTextStyles.wallet),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.isOwned,
    required this.isEquipped,
  });

  final bool isOwned;
  final bool isEquipped;

  @override
  Widget build(BuildContext context) {
    if (!isOwned && !isEquipped) {
      return const SizedBox.shrink();
    }

    final String label = isEquipped ? 'Equipped' : 'Owned';
    final Color background = isEquipped
        ? ShopUiTokens.successSoft
        : ShopUiTokens.backgroundAlt;
    final Color foreground =
        isEquipped ? ShopUiTokens.success : ShopUiTokens.textPrimary;

    return Container(
      key: Key('shopCosmeticStatus-$label'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: ShopUiTokens.radiusXlShape,
      ),
      child: Text(
        label,
        style: ShopUiTextStyles.labelSmall.copyWith(color: foreground),
      ),
    );
  }
}
