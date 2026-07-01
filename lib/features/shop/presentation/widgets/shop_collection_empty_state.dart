import 'package:flutter/material.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_empty_state.dart';

class ShopCollectionEmptyState extends StatelessWidget {
  const ShopCollectionEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShopEmptyState(
      icon: Icons.photo_library_outlined,
      title: 'No hay colecciones disponibles.',
      message: 'Vuelve pronto para descubrir nuevos universos editoriales.',
    );
  }
}
