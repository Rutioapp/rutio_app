import 'package:flutter/material.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_preview_placeholder.dart';

class ShopItemCard extends StatelessWidget {
  const ShopItemCard({
    super.key,
    required this.title,
    required this.price,
    this.description,
    this.preview,
    this.badgeLabel,
    this.rarity = ShopItemRarity.common,
    this.onTap,
    this.footer,
  });

  final String title;
  final int price;
  final String? description;
  final Widget? preview;
  final String? badgeLabel;
  final ShopItemRarity rarity;
  final VoidCallback? onTap;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final card = Ink(
      decoration: BoxDecoration(
        color: ShopUiTokens.surfaceRaised,
        borderRadius: ShopUiTokens.radiusLgShape,
        border: Border.all(color: ShopUiTokens.stroke),
        boxShadow: ShopUiTokens.softShadow,
      ),
      child: Padding(
        padding: ShopUiTokens.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: double.infinity,
              height: 84,
              child: ClipRRect(
                borderRadius: ShopUiTokens.radiusMdShape,
                child: preview ??
                    const ShopPreviewPlaceholder(
                      label: 'Preview',
                    ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: ShopUiTextStyles.cardTitle,
                      ),
                      if (description != null &&
                          description!.trim().isNotEmpty) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                          description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: ShopUiTextStyles.subtitle,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _PricePill(price: price),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _MetaPill(
                  label: _rarityLabel(rarity),
                  backgroundColor: _rarityBackground(rarity),
                  textColor: _rarityForeground(rarity),
                ),
                if (badgeLabel != null && badgeLabel!.trim().isNotEmpty)
                  _MetaPill(
                    label: badgeLabel!,
                    backgroundColor: ShopUiTokens.backgroundAlt,
                    textColor: ShopUiTokens.textPrimary,
                  ),
              ],
            ),
            if (footer != null) ...<Widget>[
              const SizedBox(height: 10),
              footer!,
            ],
          ],
        ),
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: ShopUiTokens.radiusLgShape,
        child: card,
      ),
    );
  }

  String _rarityLabel(ShopItemRarity rarity) {
    switch (rarity) {
      case ShopItemRarity.uncommon:
        return 'Uncommon';
      case ShopItemRarity.rare:
        return 'Rare';
      case ShopItemRarity.epic:
        return 'Epic';
      case ShopItemRarity.legendary:
        return 'Legendary';
      case ShopItemRarity.common:
        return 'Common';
    }
  }

  Color _rarityBackground(ShopItemRarity rarity) {
    switch (rarity) {
      case ShopItemRarity.uncommon:
        return ShopUiTokens.successSoft;
      case ShopItemRarity.rare:
        return const Color(0x1F6A8BB0);
      case ShopItemRarity.epic:
        return const Color(0x1FB28276);
      case ShopItemRarity.legendary:
        return ShopUiTokens.coinSoft;
      case ShopItemRarity.common:
        return ShopUiTokens.backgroundAlt;
    }
  }

  Color _rarityForeground(ShopItemRarity rarity) {
    switch (rarity) {
      case ShopItemRarity.uncommon:
        return ShopUiTokens.success;
      case ShopItemRarity.rare:
        return const Color(0xFF486E92);
      case ShopItemRarity.epic:
        return const Color(0xFF8D5D53);
      case ShopItemRarity.legendary:
        return const Color(0xFF9E7540);
      case ShopItemRarity.common:
        return ShopUiTokens.textPrimary;
    }
  }
}

class _PricePill extends StatelessWidget {
  const _PricePill({required this.price});

  final int price;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ShopUiTokens.coinSoft,
        borderRadius: ShopUiTokens.radiusXlShape,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.monetization_on_rounded,
              size: 15,
              color: ShopUiTokens.coin,
            ),
            const SizedBox(width: 4),
            Text(
              '$price',
              style: ShopUiTextStyles.wallet,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
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
