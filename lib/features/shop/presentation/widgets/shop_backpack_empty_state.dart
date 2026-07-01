import 'package:flutter/material.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_empty_state.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_primary_button.dart';

class ShopBackpackEmptyState extends StatelessWidget {
  const ShopBackpackEmptyState({
    super.key,
    this.onOpenUtilities,
  });

  final VoidCallback? onOpenUtilities;

  @override
  Widget build(BuildContext context) {
    return ShopEmptyState(
      icon: Icons.backpack_outlined,
      title: 'La mochila esta vacia',
      message: 'Compra utilidades en la tienda para encontrarlas aqui.',
      action: onOpenUtilities == null
          ? null
          : ShopPrimaryButton(
              label: 'Ir a Utilidades',
              icon: Icons.storefront_rounded,
              onPressed: onOpenUtilities,
              expanded: false,
            ),
    );
  }
}
