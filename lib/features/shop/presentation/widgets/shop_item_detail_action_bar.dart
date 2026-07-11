import 'package:flutter/material.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_primary_button.dart';

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
    final _ActionState action = _resolveAction();

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
            if (item.category != ShopItemCategory.utility) ...<Widget>[
              Text(
                action.helperText,
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

  _ActionState _resolveAction() {
    final bool hasStock = (backpackQuantity ?? 0) > 0;
    final bool hasEnoughCoins = walletCoins >= item.priceCoins;

    if (item.category == ShopItemCategory.utility) {
      if (hasStock) {
        return _ActionState(
          label: 'En mochila x$backpackQuantity',
          helperText: 'Ya tienes esta utilidad guardada para usarla despues.',
          icon: Icons.inventory_2_outlined,
        );
      }

      if (!hasEnoughCoins) {
        return const _ActionState(
          label: 'Sin monedas suficientes',
          helperText: 'Necesitas mas monedas para conseguir esta utilidad.',
          icon: Icons.lock_outline_rounded,
        );
      }

      return _ActionState(
        label: 'Comprar',
        helperText: 'Se añadira a tu mochila al comprarla.',
        icon: Icons.monetization_on_outlined,
        onPressed: () => onPurchasePressed(item.id),
      );
    }

    if (!isOwned && !hasStock && !hasEnoughCoins) {
      return const _ActionState(
        label: 'Sin monedas suficientes',
        helperText: 'Necesitas mas monedas para conseguir este item.',
        icon: Icons.lock_outline_rounded,
      );
    }

    if (item.cosmeticSlot != null) {
      if (isEquipped) {
        return const _ActionState(
          label: 'Equipado',
          helperText: 'Este cosmetico ya esta activo en tu perfil.',
          icon: Icons.check_circle_outline_rounded,
        );
      }

      if (isOwned) {
        return _ActionState(
          label: 'Equipar',
          helperText: 'Puedes aplicar este cosmetico cuando quieras.',
          icon: Icons.auto_fix_high_rounded,
          onPressed: () => onEquipPressed(item.id),
        );
      }
    }

    if (item.consumableType != null && hasStock) {
      return _ActionState(
        label: 'En mochila x$backpackQuantity',
        helperText: onConsumePressed == null
            ? 'Ya tienes unidades guardadas para una fase futura.'
            : 'Ya tienes unidades guardadas en tu mochila.',
        icon: Icons.inventory_2_outlined,
      );
    }

    return _ActionState(
      label: 'Comprar',
      helperText: 'Se añadira a tu coleccion al comprarlo.',
      icon: Icons.monetization_on_outlined,
      onPressed: () => onPurchasePressed(item.id),
    );
  }
}

class _ActionState {
  const _ActionState({
    required this.label,
    required this.helperText,
    required this.icon,
    this.onPressed,
  });

  final String label;
  final String helperText;
  final IconData icon;
  final VoidCallback? onPressed;
}
