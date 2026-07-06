import 'package:flutter/material.dart';
import 'package:rutio/features/shop/data/shop_catalog.dart';
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
                      child: ShopItemAssetPreview(
                        item: item,
                        fallbackLabel: item.title,
                        fallbackTone: _toneForItem(item.type),
                        height: 96,
                        fallbackIcon: _iconForItem(item.type),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _StatusBadge(
                        key: Key('shopOwnedStatus-${item.id}'),
                        isEquipped: isEquipped,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ShopUiTextStyles.cardTitle.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 6),
                Text(
                  item.description.isEmpty ? 'Sin descripcion' : item.description,
                  maxLines: 1,
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
                    if (item.collectionId != null &&
                        item.collectionId!.trim().isNotEmpty)
                      _MetaPill(
                        label: _collectionLabel(item.collectionId!),
                        backgroundColor: ShopUiTokens.backgroundAlt,
                        textColor: ShopUiTokens.textPrimary,
                      ),
                    _MetaPill(
                      label: isEquipped ? 'Equipado' : 'Disponible',
                      backgroundColor: isEquipped
                          ? ShopUiTokens.successSoft
                          : ShopUiTokens.surfaceMuted,
                      textColor: isEquipped
                          ? ShopUiTokens.success
                          : ShopUiTokens.textPrimary,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ShopPrimaryButton(
                  key: Key('shopOwnedEquip-${item.id}'),
                  label: isEquipped ? 'Equipado' : 'Equipar',
                  icon: isEquipped ? Icons.check_rounded : Icons.playlist_add_rounded,
                  onPressed: isEquipped ? null : () => onEquipPressed(item.id),
                ),
              ],
            ),
          ),
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

  String _collectionLabel(String collectionId) {
    final collection = ShopCatalog.allCollections.firstWhere(
      (collection) => collection.id == collectionId,
      orElse: () => ShopCatalog.allCollections.first,
    );
    return collection.title;
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    super.key,
    required this.isEquipped,
  });

  final bool isEquipped;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isEquipped
            ? ShopUiTokens.successSoft
            : Colors.white.withValues(alpha: 0.82),
        borderRadius: ShopUiTokens.radiusXlShape,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          isEquipped ? 'Equipado' : 'Disponible',
          style: ShopUiTextStyles.labelSmall.copyWith(
            color: isEquipped ? ShopUiTokens.success : ShopUiTokens.textPrimary,
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
