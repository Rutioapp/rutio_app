import 'package:flutter/material.dart';
import 'package:rutio/features/shop/domain/models/shop_collection.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_collection_progress.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_item_asset_preview.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_preview_placeholder.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_primary_button.dart';

class ShopCollectionCard extends StatelessWidget {
  const ShopCollectionCard({
    super.key,
    required this.collection,
    required this.totalItems,
    required this.ownedItems,
    required this.isUnlocked,
    required this.onTap,
    this.featuredItem,
  });

  final ShopCollection collection;
  final int totalItems;
  final int ownedItems;
  final bool isUnlocked;
  final ShopItem? featuredItem;
  final VoidCallback onTap;

  bool get isCompleted => totalItems > 0 && ownedItems >= totalItems;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: ShopUiTokens.radiusLgShape,
        child: Ink(
          decoration: BoxDecoration(
            color: ShopUiTokens.surfaceRaised,
            borderRadius: ShopUiTokens.radiusLgShape,
            border: Border.all(
              color: isCompleted
                  ? ShopUiTokens.success.withValues(alpha: 0.35)
                  : isUnlocked
                      ? ShopUiTokens.strokeStrong
                      : ShopUiTokens.stroke,
            ),
            boxShadow: ShopUiTokens.softShadow,
          ),
          child: Padding(
            padding: ShopUiTokens.cardPadding,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool compact = constraints.maxWidth < 440;

                final Widget preview = ShopItemAssetPreview(
                  item: featuredItem,
                  fallbackLabel: featuredItem?.title ?? collection.title,
                  fallbackTone: _toneForCollection(collection.themeKey),
                  height: 190,
                  fallbackIcon: _iconForCollection(collection.themeKey),
                );

                final Widget details = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _StatePill(
                          label: _stateLabel(),
                          backgroundColor: _stateBackground(),
                          textColor: _stateForeground(),
                        ),
                        if (collection.themeKey.trim().isNotEmpty)
                          _StatePill(
                            label: collection.themeKey,
                            backgroundColor: ShopUiTokens.backgroundAlt,
                            textColor: ShopUiTokens.textPrimary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      collection.title,
                      style: ShopUiTextStyles.cardTitle.copyWith(fontSize: 26),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      collection.description.isEmpty
                          ? 'Coleccion editorial del catalogo Rutio.'
                          : collection.description,
                      style: ShopUiTextStyles.subtitle,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '$totalItems objetos',
                      style: ShopUiTextStyles.labelSmall,
                    ),
                    const SizedBox(height: 10),
                    ShopCollectionProgress(
                      key: Key('shopCollectionProgress-${collection.id}'),
                      current: ownedItems,
                      total: totalItems,
                    ),
                    const SizedBox(height: 16),
                    ShopPrimaryButton(
                      label: isUnlocked ? 'Ver coleccion' : 'Bloqueada',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: onTap,
                    ),
                  ],
                );

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      preview,
                      const SizedBox(height: 18),
                      details,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(flex: 5, child: preview),
                    const SizedBox(width: 18),
                    Expanded(flex: 6, child: details),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String _stateLabel() {
    if (isCompleted) {
      return 'Completada';
    }
    if (ownedItems > 0) {
      return 'Empezada';
    }
    return isUnlocked ? 'Nueva' : 'Bloqueada';
  }

  Color _stateBackground() {
    if (isCompleted) {
      return ShopUiTokens.successSoft;
    }
    if (ownedItems > 0) {
      return ShopUiTokens.accentSoft;
    }
    if (isUnlocked) {
      return ShopUiTokens.backgroundAlt;
    }
    return ShopUiTokens.surfaceMuted;
  }

  Color _stateForeground() {
    if (isCompleted) {
      return ShopUiTokens.success;
    }
    if (ownedItems > 0) {
      return ShopUiTokens.accent;
    }
    if (isUnlocked) {
      return ShopUiTokens.textPrimary;
    }
    return ShopUiTokens.textSecondary;
  }

  ShopPreviewPlaceholderTone _toneForCollection(String themeKey) {
    switch (themeKey) {
      case 'gradient':
        return ShopPreviewPlaceholderTone.ice;
      case 'landscape':
        return ShopPreviewPlaceholderTone.sage;
      case 'minimal':
        return ShopPreviewPlaceholderTone.camel;
      default:
        return ShopPreviewPlaceholderTone.sand;
    }
  }

  IconData _iconForCollection(String themeKey) {
    switch (themeKey) {
      case 'gradient':
        return Icons.auto_awesome_rounded;
      case 'landscape':
        return Icons.terrain_rounded;
      case 'minimal':
        return Icons.square_rounded;
      default:
        return Icons.grid_view_rounded;
    }
  }
}

class _StatePill extends StatelessWidget {
  const _StatePill({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: ShopUiTokens.radiusXlShape,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: ShopUiTextStyles.labelSmall.copyWith(color: textColor),
        ),
      ),
    );
  }
}
