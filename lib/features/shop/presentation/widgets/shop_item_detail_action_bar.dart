import 'package:flutter/material.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_primary_button.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/l10n/l10n.dart';

class ShopItemDetailActionBar extends StatelessWidget {
  const ShopItemDetailActionBar({
    super.key,
    required this.item,
    required this.walletCoins,
    required this.isOwned,
    required this.isEquipped,
    required this.onPurchasePressed,
    required this.onEquipPressed,
    this.backpackQuantity,
    this.onConsumePressed,
  });

  final ShopItem item;
  final int walletCoins;
  final bool isOwned;
  final bool isEquipped;
  final int? backpackQuantity;
  final ValueChanged<String> onPurchasePressed;
  final ValueChanged<String> onEquipPressed;
  final ValueChanged<String>? onConsumePressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final _ActionState action = _resolveAction(l10n);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: ShopUiTokens.surfaceRaised,
        borderRadius: ShopUiTokens.radiusXlShape,
        border: Border.all(color: ShopUiTokens.stroke),
        boxShadow: ShopUiTokens.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (action.helperText != null) ...<Widget>[
              Text(
                action.helperText!,
                style: ShopUiTextStyles.bodySmall,
              ),
              const SizedBox(height: 12),
            ],
            ShopPrimaryButton(
              label: action.label,
              onPressed: action.onPressed,
              icon: action.icon,
            ),
          ],
        ),
      ),
    );
  }

  _ActionState _resolveAction(AppLocalizations l10n) {
    final bool hasStock = (backpackQuantity ?? 0) > 0;
    final bool hasEnoughCoins = walletCoins >= item.priceCoins;

    if (item.category == ShopItemCategory.utility) {
      if (!hasEnoughCoins) {
        return _ActionState(
          label: l10n.shopStatusInsufficientCoins,
          helperText: l10n.shopStatusInsufficientCoins,
          icon: Icons.lock_outline_rounded,
        );
      }

      return _ActionState(
        label: l10n.shopActionBuy,
        helperText: hasStock
            ? l10n.shopBackpackCount(backpackQuantity ?? 0)
            : l10n.shopEmptyBackpackMessage,
        icon: Icons.monetization_on_outlined,
        onPressed: () => onPurchasePressed(item.id),
      );
    }

    if (!isOwned && !hasStock && !hasEnoughCoins) {
      return _ActionState(
        label: l10n.shopStatusInsufficientCoins,
        helperText: l10n.shopStatusInsufficientCoins,
        icon: Icons.lock_outline_rounded,
      );
    }

    if (item.cosmeticSlot != null) {
      if (isEquipped) {
        return _ActionState(
          label: l10n.shopActionEquipped,
          helperText: l10n.shopActionEquipped,
          icon: Icons.check_circle_outline_rounded,
        );
      }

      if (isOwned) {
        return _ActionState(
          label: l10n.shopActionEquip,
          helperText: l10n.shopActionAvailable,
          icon: Icons.auto_fix_high_rounded,
          onPressed: () => onEquipPressed(item.id),
        );
      }
    }

    if (item.consumableType != null && hasStock) {
      return _ActionState(
        label: l10n.shopBackpackCount(backpackQuantity ?? 0),
        helperText: onConsumePressed == null
            ? l10n.shopStatusPurchased
            : l10n.shopStatusPurchased,
        icon: Icons.inventory_2_outlined,
      );
    }

    return _ActionState(
      label: l10n.shopActionBuy,
      helperText: l10n.shopActionAvailable,
      icon: Icons.monetization_on_outlined,
      onPressed: () => onPurchasePressed(item.id),
    );
  }
}

class _ActionState {
  const _ActionState({
    required this.label,
    required this.icon,
    this.onPressed,
    this.helperText,
  });

  final String label;
  final String? helperText;
  final IconData icon;
  final VoidCallback? onPressed;
}
