import 'package:flutter/material.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_preview_placeholder.dart';

class ShopItemAssetPreview extends StatelessWidget {
  const ShopItemAssetPreview({
    super.key,
    required this.item,
    required this.fallbackTone,
    required this.fallbackIcon,
    this.fallbackLabel,
    this.height,
    this.fit = BoxFit.cover,
  });

  final ShopItem? item;
  final ShopPreviewPlaceholderTone fallbackTone;
  final IconData fallbackIcon;
  final String? fallbackLabel;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final assetRef = item?.assetRef;
    if (assetRef != null && assetRef.startsWith('assets/shop/')) {
      return ColoredBox(
        color: Colors.transparent,
        child: Image.asset(
          assetRef,
          key: Key('shopAssetPreview-${item!.id}'),
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return ShopPreviewPlaceholder(
      label: fallbackLabel ?? item?.title,
      tone: fallbackTone,
      height: height ?? 120.0,
      icon: fallbackIcon,
    );
  }
}
