import 'package:flutter/material.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_primary_button.dart';
import 'package:rutio/widgets/currency/amber_coin_icon.dart';

class ShopUtilityItemCard extends StatelessWidget {
  const ShopUtilityItemCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final ShopItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ShopUiTokens.surfaceRaised,
      elevation: 1,
      shadowColor: ShopUiTokens.shadow.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: ShopUiTokens.radiusLgShape,
        side: const BorderSide(color: ShopUiTokens.stroke),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: ShopUiTokens.radiusLgShape,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              SizedBox(
                height: 132,
                child: ClipRRect(
                  borderRadius: ShopUiTokens.radiusMdShape,
                  child: _UtilityPreview(item: item),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: ShopUiTextStyles.cardTitle.copyWith(fontSize: 17),
              ),
              const SizedBox(height: 5),
              Row(
                children: <Widget>[
                  Flexible(child: _TagPill(label: _labelForItem(item))),
                  const SizedBox(width: 6),
                  _PricePill(price: item.priceCoins),
                ],
              ),
              const Spacer(),
              const SizedBox(height: 12),
              ShopPrimaryButton(
                label: 'Comprar',
                onPressed: onTap,
                expanded: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _labelForItem(ShopItem item) {
    switch (item.rarity) {
      case ShopItemRarity.common:
        return 'Common';
      case ShopItemRarity.uncommon:
        return 'Uncommon';
      case ShopItemRarity.rare:
        return 'Rare';
      case ShopItemRarity.epic:
        return 'Epic';
      case ShopItemRarity.legendary:
        return 'Legendary';
    }
  }
}

class _UtilityPreview extends StatelessWidget {
  const _UtilityPreview({required this.item});

  final ShopItem item;

  @override
  Widget build(BuildContext context) {
    final String? assetPath = _assetPathForItem(item);

    if (assetPath != null) {
      return Padding(
        padding: const EdgeInsets.all(10),
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => _FallbackGraphic(item: item),
        ),
      );
    }

    return _FallbackGraphic(item: item);
  }

  String? _assetPathForItem(ShopItem item) {
    final String? assetRef = item.assetRef;
    if (assetRef != null && assetRef.startsWith('assets/shop/utilities/')) {
      return assetRef;
    }
    return null;
  }
}

class _FallbackGraphic extends StatelessWidget {
  const _FallbackGraphic({required this.item});

  final ShopItem item;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ShopUiTokens.backgroundAlt,
        borderRadius: ShopUiTokens.radiusMdShape,
      ),
      child: Center(
        child: Icon(
          _fallbackIconForItem(item),
          color: ShopUiTokens.textPrimary,
          size: 34,
        ),
      ),
    );
  }

  IconData _fallbackIconForItem(ShopItem item) {
    switch (item.type) {
      case ShopItemType.xpBoost:
        return Icons.auto_graph_rounded;
      case ShopItemType.coinBoost:
        return Icons.monetization_on_rounded;
      case ShopItemType.streakRecover:
        return Icons.refresh_rounded;
      case ShopItemType.streakShield:
        return Icons.shield_rounded;
      case ShopItemType.mysteryBox:
        return Icons.card_giftcard_rounded;
      case ShopItemType.background:
      case ShopItemType.habitCard:
      case ShopItemType.userCard:
        return Icons.inventory_2_rounded;
    }
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ShopUiTokens.backgroundAlt,
        borderRadius: ShopUiTokens.radiusXlShape,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ShopUiTextStyles.labelSmall.copyWith(
            fontSize: 10,
            color: ShopUiTokens.textPrimary,
          ),
        ),
      ),
    );
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
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const AmberCoinIcon(size: 13),
            const SizedBox(width: 3),
            Text(
              '$price',
              style: ShopUiTextStyles.wallet.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
