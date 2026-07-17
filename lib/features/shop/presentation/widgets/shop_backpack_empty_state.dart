import 'package:flutter/material.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_empty_state.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_primary_button.dart';
import 'package:rutio/l10n/l10n.dart';

class ShopBackpackEmptyState extends StatelessWidget {
  const ShopBackpackEmptyState({
    super.key,
    this.onOpenUtilities,
  });

  final VoidCallback? onOpenUtilities;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ShopEmptyState(
      icon: Icons.backpack_outlined,
      title: l10n.shopEmptyBackpackTitle,
      message: l10n.shopEmptyBackpackMessage,
      action: onOpenUtilities == null
          ? null
          : ShopPrimaryButton(
              label: l10n.shopBackpackEmptyAction,
              icon: Icons.storefront_rounded,
              onPressed: onOpenUtilities,
              expanded: false,
            ),
    );
  }
}
