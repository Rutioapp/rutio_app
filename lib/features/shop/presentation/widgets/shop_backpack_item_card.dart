import 'package:flutter/material.dart';
import 'package:rutio/features/shop/data/shop_catalog.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/presentation/models/backpack_item_view_model.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/shop_localizations.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_preview_placeholder.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_primary_button.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_utility_asset_art.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/l10n/l10n.dart';

class ShopBackpackItemCard extends StatelessWidget {
  const ShopBackpackItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onUsePressed,
  });

  final BackpackItemViewModel item;
  final VoidCallback onTap;
  final Future<void> Function(String) onUsePressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final catalogItem = ShopCatalog.getItemById(item.itemId);

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
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: ShopUiTokens.radiusMdShape,
                      child: SizedBox(
                        height: 88,
                        child: _BackpackPreview(
                          viewModel: item,
                          item: catalogItem,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _QuantityBadge(
                        key: Key('shopBackpackQuantity-${item.itemId}'),
                        quantity: item.quantity,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        catalogItem != null
                            ? l10n.shopUtilityTitleForItem(catalogItem)
                            : item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            ShopUiTextStyles.cardTitle.copyWith(fontSize: 15.5),
                      ),
                      const SizedBox(height: 4),
                      _MetaPill(
                        label: l10n.shopRarityLabelByShopItem(item.rarity),
                        backgroundColor: _rarityBackground(item.rarity),
                        textColor: _rarityForeground(item.rarity),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                ShopPrimaryButton(
                  key: Key('shopBackpackUse-${item.itemId}'),
                  label: _buttonLabel(l10n, item),
                  icon: _buttonIcon(item),
                  onPressed: _canUse(item)
                      ? () async {
                          await onUsePressed(item.itemId);
                        }
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _canUse(BackpackItemViewModel item) {
    if (item.isActivating) return false;
    if (item.isMysteryBox) return true;
    if (!item.isBoost) return true;
    return !item.isActive;
  }

  String _buttonLabel(AppLocalizations l10n, BackpackItemViewModel item) {
    if (item.isMysteryBox) {
      if (item.isActivating) return l10n.shopStatusBusyOpening;
      if (item.hasMysteryBoxPendingRecovery) return l10n.shopActionContinue;
      return l10n.shopActionOpen;
    }
    if (item.isStreakShield) {
      return l10n.shopActionActivate;
    }
    if (item.isStreakRecover) {
      return l10n.shopActionUse;
    }
    if (item.isBoost) {
      if (item.isActive) return l10n.shopActionActive;
      return l10n.shopActionActivate;
    }
    return l10n.shopActionUse;
  }

  IconData _buttonIcon(BackpackItemViewModel item) {
    if (item.isMysteryBox) {
      if (item.isActivating) return Icons.hourglass_top_rounded;
      if (item.hasMysteryBoxPendingRecovery) {
        return Icons.play_arrow_rounded;
      }
      return Icons.card_giftcard_rounded;
    }
    if (item.isStreakShield) {
      return Icons.shield_rounded;
    }
    if (item.isStreakRecover) {
      return Icons.restore_rounded;
    }
    if (item.isBoost) {
      return item.isActive
          ? Icons.check_circle_outline_rounded
          : Icons.bolt_rounded;
    }
    return Icons.auto_fix_high_rounded;
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

class _BackpackPreview extends StatelessWidget {
  const _BackpackPreview({
    required this.viewModel,
    required this.item,
  });

  final BackpackItemViewModel viewModel;
  final ShopItem? item;

  @override
  Widget build(BuildContext context) {
    if (item != null) {
      return ShopUtilityAssetArt(
        item: item!,
        fallbackTone: _toneForItemType(viewModel.type),
        fallbackIcon: _iconForItemType(viewModel.type),
      );
    }

    return ShopPreviewPlaceholder(
      label: viewModel.title,
      tone: _toneForItemType(viewModel.type),
      height: 108,
      icon: _iconForItemType(viewModel.type),
    );
  }

  ShopPreviewPlaceholderTone _toneForItemType(ShopItemType type) {
    switch (type) {
      case ShopItemType.xpBoost:
        return ShopPreviewPlaceholderTone.sage;
      case ShopItemType.coinBoost:
        return ShopPreviewPlaceholderTone.camel;
      case ShopItemType.streakRecover:
      case ShopItemType.streakShield:
        return ShopPreviewPlaceholderTone.sand;
      case ShopItemType.mysteryBox:
        return ShopPreviewPlaceholderTone.clay;
      case ShopItemType.background:
      case ShopItemType.habitCard:
      case ShopItemType.userCard:
        return ShopPreviewPlaceholderTone.charcoal;
    }
  }

  IconData _iconForItemType(ShopItemType type) {
    switch (type) {
      case ShopItemType.xpBoost:
        return Icons.bolt_rounded;
      case ShopItemType.coinBoost:
        return Icons.monetization_on_rounded;
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
        color: Colors.white.withValues(alpha: 0.88),
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
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: ShopUiTokens.radiusXlShape,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          child: Text(
            label,
            style: ShopUiTextStyles.labelSmall.copyWith(color: textColor),
          ),
        ),
      ),
    );
  }
}
