import 'package:flutter/material.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/presentation/models/shop_utility_visual_config.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_preview_placeholder.dart';

class ShopUtilityAssetArt extends StatelessWidget {
  const ShopUtilityAssetArt({
    super.key,
    required this.item,
    required this.fallbackTone,
    required this.fallbackIcon,
    this.padding,
    this.scale,
    this.fit,
    this.alignment,
    this.filterQuality = FilterQuality.high,
  });

  final ShopItem item;
  final ShopPreviewPlaceholderTone fallbackTone;
  final IconData fallbackIcon;
  final EdgeInsets? padding;
  final double? scale;
  final BoxFit? fit;
  final Alignment? alignment;
  final FilterQuality filterQuality;

  @override
  Widget build(BuildContext context) {
    final assetPath = item.assetRef;
    final visualConfig = ShopUtilityVisualConfig.forItem(item);

    if (assetPath != null && assetPath.startsWith('assets/shop/utilities/')) {
      return Transform.scale(
        scale: scale ?? visualConfig.scale,
        child: Padding(
          padding: padding ?? visualConfig.padding,
          child: Image.asset(
            assetPath,
            key: Key('shopUtilityAssetArt-${item.id}'),
            fit: fit ?? visualConfig.fit,
            alignment: alignment ?? visualConfig.alignment,
            filterQuality: filterQuality,
            errorBuilder: (_, __, ___) => _fallback(),
          ),
        ),
      );
    }

    return _fallback();
  }

  Widget _fallback() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ShopUiTokens.backgroundAlt,
        borderRadius: ShopUiTokens.radiusMdShape,
      ),
      child: Center(
        child: Icon(
          fallbackIcon,
          color: ShopUiTokens.textPrimary,
          size: 34,
        ),
      ),
    );
  }
}
