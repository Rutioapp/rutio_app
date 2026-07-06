import 'package:flutter/material.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_preview_placeholder.dart';

class ShopCustomizationPreview extends StatelessWidget {
  const ShopCustomizationPreview({
    super.key,
    this.backgroundItem,
    this.habitCardItem,
    this.userCardItem,
  });

  final ShopItem? backgroundItem;
  final ShopItem? habitCardItem;
  final ShopItem? userCardItem;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('shopCustomizationPreview'),
      children: <Widget>[
        _PreviewSlot(
          label: 'Fondo actual',
          item: backgroundItem,
          tone: ShopPreviewPlaceholderTone.camel,
          icon: Icons.wallpaper_rounded,
        ),
        const SizedBox(height: 12),
        _PreviewSlot(
          label: 'Habit Card actual',
          item: habitCardItem,
          tone: ShopPreviewPlaceholderTone.sand,
          icon: Icons.view_agenda_outlined,
        ),
        const SizedBox(height: 12),
        _PreviewSlot(
          label: 'User Card actual',
          item: userCardItem,
          tone: ShopPreviewPlaceholderTone.ice,
          icon: Icons.badge_outlined,
        ),
      ],
    );
  }
}

class _PreviewSlot extends StatelessWidget {
  const _PreviewSlot({
    required this.label,
    required this.item,
    required this.tone,
    required this.icon,
  });

  final String label;
  final ShopItem? item;
  final ShopPreviewPlaceholderTone tone;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ShopUiTokens.backgroundAlt.withValues(alpha: 0.45),
        borderRadius: ShopUiTokens.radiusMdShape,
        border: Border.all(color: ShopUiTokens.stroke),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 108,
              height: 72,
              child: ClipRRect(
                borderRadius: ShopUiTokens.radiusSmShape,
                child: _CompactPreviewThumb(
                  item: item,
                  tone: tone,
                  icon: icon,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: ShopUiTextStyles.label.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item?.title ?? 'Todavia no hay un objeto equipado.',
                    style: ShopUiTextStyles.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactPreviewThumb extends StatelessWidget {
  const _CompactPreviewThumb({
    required this.item,
    required this.tone,
    required this.icon,
  });

  final ShopItem? item;
  final ShopPreviewPlaceholderTone tone;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final assetRef = item?.assetRef;
    if (assetRef != null && assetRef.startsWith('assets/shop/')) {
      return Image.asset(
        assetRef,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    final Color color = switch (tone) {
      ShopPreviewPlaceholderTone.camel => ShopUiTokens.placeholderCamel,
      ShopPreviewPlaceholderTone.sage => ShopUiTokens.placeholderSage,
      ShopPreviewPlaceholderTone.sand => ShopUiTokens.placeholderSand,
      ShopPreviewPlaceholderTone.clay => ShopUiTokens.placeholderClay,
      ShopPreviewPlaceholderTone.ice => ShopUiTokens.placeholderIce,
      ShopPreviewPlaceholderTone.charcoal => ShopUiTokens.placeholderCharcoal,
    };

    return DecoratedBox(
      decoration: BoxDecoration(color: color),
      child: Center(
        child: Icon(
          icon,
          size: 18,
          color: Colors.white.withValues(alpha: 0.82),
        ),
      ),
    );
  }
}
