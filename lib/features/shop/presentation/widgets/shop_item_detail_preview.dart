import 'package:flutter/material.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_item_asset_preview.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_preview_placeholder.dart';

class ShopItemDetailPreview extends StatelessWidget {
  const ShopItemDetailPreview({
    super.key,
    required this.item,
    this.isOwned = false,
    this.isEquipped = false,
    this.backpackQuantity,
  });

  final ShopItem item;
  final bool isOwned;
  final bool isEquipped;
  final int? backpackQuantity;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ShopUiTokens.surfaceRaised,
        borderRadius: ShopUiTokens.radiusXlShape,
        border: Border.all(color: ShopUiTokens.stroke),
        boxShadow: ShopUiTokens.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ClipRRect(
              borderRadius: ShopUiTokens.radiusLgShape,
              child: ShopItemAssetPreview(
                item: item,
                fallbackLabel: item.title,
                fallbackTone: _toneForItem(item.type),
                height: 240,
                fallbackIcon: _iconForItem(item.type),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _Badge(
                  label: _rarityLabel(item.rarity),
                  backgroundColor: _rarityBackground(item.rarity),
                  foregroundColor: _rarityForeground(item.rarity),
                ),
                _Badge(
                  label: _typeLabel(item.type),
                  backgroundColor: ShopUiTokens.backgroundAlt,
                  foregroundColor: ShopUiTokens.textPrimary,
                ),
                if (isEquipped)
                  const _Badge(
                    label: 'Equipado',
                    backgroundColor: ShopUiTokens.successSoft,
                    foregroundColor: ShopUiTokens.success,
                  )
                else if (backpackQuantity != null && backpackQuantity! > 0)
                  _Badge(
                    label: 'En mochila x$backpackQuantity',
                    backgroundColor: ShopUiTokens.coinSoft,
                    foregroundColor: ShopUiTokens.textPrimary,
                  )
                else if (isOwned)
                  const _Badge(
                    label: 'Comprado',
                    backgroundColor: ShopUiTokens.backgroundAlt,
                    foregroundColor: ShopUiTokens.textPrimary,
                  )
                else
                  const _Badge(
                    label: 'Disponible',
                    backgroundColor: ShopUiTokens.surfaceMuted,
                    foregroundColor: ShopUiTokens.textPrimary,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
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
        return ShopPreviewPlaceholderTone.sage;
      case ShopItemType.coinBoost:
        return ShopPreviewPlaceholderTone.clay;
      case ShopItemType.streakRecover:
      case ShopItemType.streakShield:
        return ShopPreviewPlaceholderTone.charcoal;
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
        return Icons.rocket_launch_outlined;
      case ShopItemType.coinBoost:
        return Icons.monetization_on_outlined;
      case ShopItemType.streakRecover:
        return Icons.restore_rounded;
      case ShopItemType.streakShield:
        return Icons.shield_outlined;
      case ShopItemType.mysteryBox:
        return Icons.card_giftcard_rounded;
    }
  }

  String _typeLabel(ShopItemType type) {
    switch (type) {
      case ShopItemType.background:
        return 'Fondo';
      case ShopItemType.habitCard:
        return 'Card de habitos';
      case ShopItemType.userCard:
        return 'Card de usuario';
      case ShopItemType.xpBoost:
        return 'XP Boost';
      case ShopItemType.coinBoost:
        return 'Coin Boost';
      case ShopItemType.streakRecover:
        return 'Streak Recover';
      case ShopItemType.streakShield:
        return 'Streak Shield';
      case ShopItemType.mysteryBox:
        return 'Mystery Box';
    }
  }

  String _rarityLabel(ShopItemRarity rarity) {
    switch (rarity) {
      case ShopItemRarity.uncommon:
        return 'Uncommon';
      case ShopItemRarity.rare:
        return 'Rare';
      case ShopItemRarity.epic:
        return 'Epic';
      case ShopItemRarity.legendary:
        return 'Legendary';
      case ShopItemRarity.common:
        return 'Common';
    }
  }

  Color _rarityBackground(ShopItemRarity rarity) {
    switch (rarity) {
      case ShopItemRarity.uncommon:
        return ShopUiTokens.successSoft;
      case ShopItemRarity.rare:
        return const Color(0x1F6A8BB0);
      case ShopItemRarity.epic:
        return const Color(0x1FB28276);
      case ShopItemRarity.legendary:
        return ShopUiTokens.coinSoft;
      case ShopItemRarity.common:
        return ShopUiTokens.backgroundAlt;
    }
  }

  Color _rarityForeground(ShopItemRarity rarity) {
    switch (rarity) {
      case ShopItemRarity.uncommon:
        return ShopUiTokens.success;
      case ShopItemRarity.rare:
        return const Color(0xFF486E92);
      case ShopItemRarity.epic:
        return const Color(0xFF8D5D53);
      case ShopItemRarity.legendary:
        return ShopUiTokens.accent;
      case ShopItemRarity.common:
        return ShopUiTokens.textPrimary;
    }
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: ShopUiTokens.radiusXlShape,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text(
          label,
          style: ShopUiTextStyles.labelSmall.copyWith(color: foregroundColor),
        ),
      ),
    );
  }
}
