import 'package:flutter/material.dart';
import 'package:rutio/features/shop/domain/models/shop_collection.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_item_asset_preview.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_preview_placeholder.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_primary_button.dart';

class ShopFeaturedCollectionCard extends StatelessWidget {
  const ShopFeaturedCollectionCard({
    super.key,
    required this.collection,
    this.featuredItem,
    this.onTap,
  });

  final ShopCollection collection;
  final ShopItem? featuredItem;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ShopUiTokens.surfaceRaised,
        borderRadius: ShopUiTokens.radiusLgShape,
        border: Border.all(color: ShopUiTokens.stroke),
        boxShadow: ShopUiTokens.softShadow,
      ),
      child: Padding(
        padding: ShopUiTokens.cardPadding,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final isCompact = constraints.maxWidth < 440;

            return Flex(
              direction: isCompact ? Axis.vertical : Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  flex: isCompact ? 0 : 5,
                  child: ShopItemAssetPreview(
                    item: featuredItem,
                    fallbackTone: _toneForCollection(collection.themeKey),
                    height: 180,
                    fallbackIcon: Icons.auto_awesome_rounded,
                    fallbackLabel: featuredItem?.title ?? collection.title,
                  ),
                ),
                SizedBox(
                  width: isCompact ? 0 : 18,
                  height: isCompact ? 18 : 0,
                ),
                Expanded(
                  flex: isCompact ? 0 : 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Destacado',
                        style: ShopUiTextStyles.eyebrow,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        collection.title,
                        style: ShopUiTextStyles.cardTitle.copyWith(fontSize: 26),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        collection.description,
                        style: ShopUiTextStyles.subtitle,
                      ),
                      if (featuredItem != null) ...<Widget>[
                        const SizedBox(height: 16),
                        _FeaturedMetaRow(item: featuredItem!),
                      ],
                      const SizedBox(height: 18),
                      ShopPrimaryButton(
                        label: 'Ver coleccion',
                        onPressed: onTap,
                        icon: Icons.arrow_forward_rounded,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  ShopPreviewPlaceholderTone _toneForCollection(String themeKey) {
    switch (themeKey) {
      case 'gradient':
        return ShopPreviewPlaceholderTone.ice;
      case 'landscape':
        return ShopPreviewPlaceholderTone.sage;
      case 'minimal':
      default:
        return ShopPreviewPlaceholderTone.camel;
    }
  }
}

class _FeaturedMetaRow extends StatelessWidget {
  const _FeaturedMetaRow({required this.item});

  final ShopItem item;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _MetaPill(label: item.title),
        _MetaPill(label: '${item.priceCoins} coins'),
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ShopUiTokens.backgroundAlt,
        borderRadius: ShopUiTokens.radiusXlShape,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: ShopUiTextStyles.labelSmall.copyWith(
            color: ShopUiTokens.textPrimary,
          ),
        ),
      ),
    );
  }
}
