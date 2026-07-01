import 'package:flutter/material.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/presentation/models/backpack_item_view_model.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_preview_placeholder.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_primary_button.dart';

class ShopBackpackItemCard extends StatelessWidget {
  const ShopBackpackItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onUsePressed,
  });

  final BackpackItemViewModel item;
  final VoidCallback onTap;
  final ValueChanged<String> onUsePressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: ShopUiTokens.radiusLgShape,
        child: Ink(
          decoration: BoxDecoration(
            color: ShopUiTokens.surfaceRaised,
            borderRadius: ShopUiTokens.radiusLgShape,
            border: Border.all(color: ShopUiTokens.stroke),
            boxShadow: ShopUiTokens.softShadow,
          ),
          child: Padding(
            padding: ShopUiTokens.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: ShopUiTokens.radiusMdShape,
                      child: ShopPreviewPlaceholder(
                        label: item.title,
                        tone: _toneForItemType(item.type),
                        height: 108,
                        icon: _iconForItemType(item.type),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _QuantityBadge(
                        key: Key('shopBackpackQuantity-${item.itemId}'),
                        quantity: item.quantity,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ShopUiTextStyles.cardTitle.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 6),
                Text(
                  item.description.trim().isEmpty
                      ? 'Sin descripcion'
                      : item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ShopUiTextStyles.subtitle,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _MetaPill(
                      label: _rarityLabel(item.rarity),
                      backgroundColor: _rarityBackground(item.rarity),
                      textColor: _rarityForeground(item.rarity),
                    ),
                    _MetaPill(
                      label: 'x${item.quantity}',
                      backgroundColor: ShopUiTokens.backgroundAlt,
                      textColor: ShopUiTokens.textPrimary,
                    ),
                  ],
                ),
                if (item.quantity > 0) ...<Widget>[
                  const SizedBox(height: 14),
                  ShopPrimaryButton(
                    key: Key('shopBackpackUse-${item.itemId}'),
                    label: 'Usar',
                    icon: Icons.auto_fix_high_rounded,
                    onPressed: () => onUsePressed(item.itemId),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  ShopPreviewPlaceholderTone _toneForItemType(ShopItemType type) {
    switch (type) {
      case ShopItemType.xpBoost:
      case ShopItemType.coinBoost:
        return ShopPreviewPlaceholderTone.sage;
      case ShopItemType.streakRecover:
      case ShopItemType.streakShield:
        return ShopPreviewPlaceholderTone.sand;
      case ShopItemType.mysteryBox:
        return ShopPreviewPlaceholderTone.camel;
      case ShopItemType.background:
      case ShopItemType.habitCard:
      case ShopItemType.userCard:
        return ShopPreviewPlaceholderTone.clay;
    }
  }

  IconData _iconForItemType(ShopItemType type) {
    switch (type) {
      case ShopItemType.xpBoost:
      case ShopItemType.coinBoost:
        return Icons.bolt_rounded;
      case ShopItemType.streakRecover:
        return Icons.restore_rounded;
      case ShopItemType.streakShield:
        return Icons.shield_rounded;
      case ShopItemType.mysteryBox:
        return Icons.card_giftcard_rounded;
      case ShopItemType.background:
        return Icons.wallpaper_rounded;
      case ShopItemType.habitCard:
        return Icons.view_agenda_outlined;
      case ShopItemType.userCard:
        return Icons.badge_outlined;
    }
  }

  String _rarityLabel(ShopItemRarity rarity) {
    switch (rarity) {
      case ShopItemRarity.common:
        return 'Common';
      case ShopItemRarity.uncommon:
        return 'Uncommon';
      case ShopItemRarity.rare:
        return 'Rare';
      case ShopItemRarity.epic:
        return 'Epic';
      case ShopItemRarity.legendary:
        return 'Legendary';
    }
  }

  Color _rarityBackground(ShopItemRarity rarity) {
    switch (rarity) {
      case ShopItemRarity.common:
        return ShopUiTokens.backgroundAlt;
      case ShopItemRarity.uncommon:
        return ShopUiTokens.successSoft;
      case ShopItemRarity.rare:
        return const Color(0x1F6A8BB0);
      case ShopItemRarity.epic:
        return const Color(0x1FB28276);
      case ShopItemRarity.legendary:
        return ShopUiTokens.coinSoft;
    }
  }

  Color _rarityForeground(ShopItemRarity rarity) {
    switch (rarity) {
      case ShopItemRarity.common:
        return ShopUiTokens.textPrimary;
      case ShopItemRarity.uncommon:
        return ShopUiTokens.success;
      case ShopItemRarity.rare:
        return const Color(0xFF486E92);
      case ShopItemRarity.epic:
        return const Color(0xFF8D5D53);
      case ShopItemRarity.legendary:
        return const Color(0xFF9E7540);
    }
  }
}

class _QuantityBadge extends StatelessWidget {
  const _QuantityBadge({
    super.key,
    required this.quantity,
  });

  final int quantity;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: ShopUiTokens.radiusXlShape,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          'x$quantity',
          style: ShopUiTextStyles.labelSmall.copyWith(
            color: ShopUiTokens.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: ShopUiTokens.radiusXlShape,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: ShopUiTextStyles.labelSmall.copyWith(color: textColor),
        ),
      ),
    );
  }
}
