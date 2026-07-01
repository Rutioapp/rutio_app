import 'package:flutter/material.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';

enum ShopPreviewPlaceholderTone {
  camel,
  sage,
  sand,
  clay,
  ice,
  charcoal,
}

class ShopPreviewPlaceholder extends StatelessWidget {
  const ShopPreviewPlaceholder({
    super.key,
    this.label,
    this.tone = ShopPreviewPlaceholderTone.camel,
    this.height = ShopUiTokens.cardPreviewHeight,
    this.icon = Icons.photo_size_select_large_outlined,
  });

  final String? label;
  final ShopPreviewPlaceholderTone tone;
  final double height;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteForTone(tone);

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            palette.$1,
            palette.$2,
          ],
        ),
        borderRadius: ShopUiTokens.radiusMdShape,
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -12,
            right: -8,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -18,
            left: -12,
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: ShopUiTokens.placeholderPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  icon,
                  color: palette.$3,
                  size: 22,
                ),
                const Spacer(),
                if (label != null && label!.trim().isNotEmpty)
                  Text(
                    label!,
                    style: ShopUiTextStyles.label.copyWith(color: palette.$3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color, Color) _paletteForTone(ShopPreviewPlaceholderTone tone) {
    switch (tone) {
      case ShopPreviewPlaceholderTone.sage:
        return (
          ShopUiTokens.placeholderSage,
          ShopUiTokens.successSoft,
          ShopUiTokens.success,
        );
      case ShopPreviewPlaceholderTone.sand:
        return (
          ShopUiTokens.placeholderSand,
          ShopUiTokens.surfaceMuted,
          ShopUiTokens.accent,
        );
      case ShopPreviewPlaceholderTone.clay:
        return (
          ShopUiTokens.placeholderClay,
          ShopUiTokens.accentSoft,
          ShopUiTokens.danger,
        );
      case ShopPreviewPlaceholderTone.ice:
        return (
          ShopUiTokens.placeholderIce,
          const Color(0xFFEAF5F8),
          ShopUiTokens.textPrimary,
        );
      case ShopPreviewPlaceholderTone.charcoal:
        return (
          ShopUiTokens.placeholderCharcoal,
          const Color(0xFF7B766C),
          ShopUiTokens.surfaceRaised,
        );
      case ShopPreviewPlaceholderTone.camel:
        return (
          ShopUiTokens.placeholderCamel,
          ShopUiTokens.surfaceMuted,
          ShopUiTokens.textPrimary,
        );
    }
  }
}
