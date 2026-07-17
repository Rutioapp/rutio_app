import 'package:flutter/material.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/shop_localizations.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_header.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_item_detail_action_bar.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_item_detail_info_row.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_item_detail_preview.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_page_shell.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_preview_placeholder.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_utility_asset_art.dart';
import 'package:rutio/l10n/l10n.dart';

class ShopItemDetailScreen extends StatelessWidget {
  const ShopItemDetailScreen({
    super.key,
    required this.item,
    required this.walletCoins,
    required this.isOwned,
    required this.isEquipped,
    required this.onBackPressed,
    required this.onPurchasePressed,
    required this.onEquipPressed,
    this.backpackQuantity,
    this.collectionName,
    this.onConsumePressed,
  });

  final ShopItem item;
  final int walletCoins;
  final bool isOwned;
  final bool isEquipped;
  final int? backpackQuantity;
  final String? collectionName;
  final VoidCallback onBackPressed;
  final ValueChanged<String> onPurchasePressed;
  final ValueChanged<String> onEquipPressed;
  final ValueChanged<String>? onConsumePressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (item.category == ShopItemCategory.utility) {
      return _UtilityItemDetailScreen(
        item: item,
        walletCoins: walletCoins,
        isOwned: isOwned,
        isEquipped: isEquipped,
        backpackQuantity: backpackQuantity,
        onBackPressed: onBackPressed,
        onPurchasePressed: onPurchasePressed,
        onEquipPressed: onEquipPressed,
        onConsumePressed: onConsumePressed,
      );
    }

    return ShopPageShell(
      header: ShopHeader(
        title: l10n.shopDetailTitle,
        subtitle: _headerSubtitle(context),
        leadingIcon: Icons.arrow_back_ios_new_rounded,
        onLeadingPressed: onBackPressed,
        walletCoins: walletCoins,
      ),
      bottomBar: ShopItemDetailActionBar(
        item: item,
        walletCoins: walletCoins,
        isOwned: isOwned,
        isEquipped: isEquipped,
        backpackQuantity: backpackQuantity,
        onPurchasePressed: onPurchasePressed,
        onEquipPressed: onEquipPressed,
        onConsumePressed: onConsumePressed,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ShopItemDetailPreview(
            item: item,
            isOwned: isOwned,
            isEquipped: isEquipped,
            backpackQuantity: backpackQuantity,
          ),
          const SizedBox(height: ShopUiTokens.sectionSpacing),
          Text(
            l10n.shopUtilityTitleForItem(item),
            key: const Key('shopItemDetailTitle'),
            style: ShopUiTextStyles.pageTitle.copyWith(fontSize: 30),
          ),
          const SizedBox(height: 10),
          Text(
            item.description.isEmpty
                ? l10n.shopNoDescriptionYet
                : l10n.shopUtilityDescriptionForItem(item),
            key: const Key('shopItemDetailDescription'),
            style: ShopUiTextStyles.subtitle,
          ),
          const SizedBox(height: ShopUiTokens.sectionSpacing),
          DecoratedBox(
            decoration: BoxDecoration(
              color: ShopUiTokens.surfaceRaised,
              borderRadius: ShopUiTokens.radiusXlShape,
              border: Border.all(color: ShopUiTokens.stroke),
              boxShadow: ShopUiTokens.softShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  ShopItemDetailInfoRow(
                    label: l10n.shopRarityLabel,
                    value: l10n.shopRarityLabelByShopItem(item.rarity),
                  ),
                  const SizedBox(height: 12),
                  ShopItemDetailInfoRow(
                    label: l10n.shopTypeLabel,
                    value: l10n.shopItemTypeLabel(item.type),
                  ),
                  if (collectionName != null &&
                      collectionName!.trim().isNotEmpty) ...<Widget>[
                    const SizedBox(height: 12),
                    ShopItemDetailInfoRow(
                      label: l10n.shopCollectionsTitle,
                      value: collectionName!,
                    ),
                  ],
                  const SizedBox(height: 12),
                  ShopItemDetailInfoRow(
                    label: l10n.shopPriceLabel,
                    value: l10n.shopPriceCoins(item.priceCoins),
                  ),
                  const SizedBox(height: 12),
                  ShopItemDetailInfoRow(
                    label: l10n.shopStatusLabel,
                    value: _statusLabel(context),
                    valueKey: const Key('shopItemDetailStatusValue'),
                  ),
                  if (backpackQuantity != null &&
                      backpackQuantity! > 0) ...<Widget>[
                    const SizedBox(height: 12),
                    ShopItemDetailInfoRow(
                      label: l10n.shopBackpackTitle,
                      value: l10n.shopBackpackCount(backpackQuantity!),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _headerSubtitle(BuildContext context) {
    return context.l10n.shopCategoryUtility;
  }

  String _statusLabel(BuildContext context) {
    if (isEquipped) {
      return context.l10n.shopActionEquipped;
    }
    if ((backpackQuantity ?? 0) > 0) {
      return context.l10n.shopBackpackCount(backpackQuantity!);
    }
    if (isOwned) {
      return context.l10n.shopStatusPurchased;
    }
    return context.l10n.shopActionAvailable;
  }
}

class _UtilityItemDetailScreen extends StatelessWidget {
  const _UtilityItemDetailScreen({
    required this.item,
    required this.walletCoins,
    required this.isOwned,
    required this.isEquipped,
    required this.backpackQuantity,
    required this.onBackPressed,
    required this.onPurchasePressed,
    required this.onEquipPressed,
    this.onConsumePressed,
  });

  final ShopItem item;
  final int walletCoins;
  final bool isOwned;
  final bool isEquipped;
  final int? backpackQuantity;
  final VoidCallback onBackPressed;
  final ValueChanged<String> onPurchasePressed;
  final ValueChanged<String> onEquipPressed;
  final ValueChanged<String>? onConsumePressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ShopPageShell(
      header: ShopHeader(
        title: l10n.shopDetailTitle,
        leadingIcon: Icons.arrow_back_ios_new_rounded,
        onLeadingPressed: onBackPressed,
        walletCoins: walletCoins,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.shopUtilityTitleForItem(item),
            key: const Key('shopItemDetailTitle'),
            style: ShopUiTextStyles.pageTitle.copyWith(fontSize: 30),
          ),
          const SizedBox(height: 16),
          _UtilityPreviewCard(
            key: const Key('shopItemDetailUtilityPreview'),
            item: item,
          ),
          const SizedBox(height: ShopUiTokens.sectionSpacing),
          Text(
            l10n.shopUtilityDescriptionForItem(item),
            key: const Key('shopItemDetailDescription'),
            style: ShopUiTextStyles.subtitle,
          ),
          const SizedBox(height: ShopUiTokens.sectionSpacing),
          DecoratedBox(
            decoration: BoxDecoration(
              color: ShopUiTokens.surfaceRaised,
              borderRadius: ShopUiTokens.radiusXlShape,
              border: Border.all(color: ShopUiTokens.stroke),
              boxShadow: ShopUiTokens.softShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  ShopItemDetailInfoRow(
                    label: l10n.shopRarityLabel,
                    value: l10n.shopRarityLabelByShopItem(item.rarity),
                    valueKey: const Key('shopItemDetailUtilityTypeValue'),
                  ),
                  const SizedBox(height: 12),
                  ShopItemDetailInfoRow(
                    label: l10n.shopTypeLabel,
                    value: l10n.shopUtilityCategoryLabelForItem(item),
                    valueKey: const Key('shopItemDetailUtilityRarityValue'),
                  ),
                  const SizedBox(height: 12),
                  ShopItemDetailInfoRow(
                    label: l10n.shopDurationLabel,
                    value: l10n.shopUtilityDurationLabel(item),
                    valueKey: const Key('shopItemDetailUtilityDurationValue'),
                  ),
                  const SizedBox(height: 12),
                  ShopItemDetailInfoRow(
                    label: l10n.shopEffectLabel,
                    value: l10n.shopUtilityEffectLabelForItem(item),
                    valueKey: const Key('shopItemDetailUtilityEffectValue'),
                    valueStyle: ShopUiTextStyles.label.copyWith(fontSize: 12.5),
                    valueMaxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  ShopItemDetailInfoRow(
                    label: l10n.shopPriceLabel,
                    value: l10n.shopPriceCoins(item.priceCoins),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: ShopUiTokens.sectionSpacing),
          ShopItemDetailActionBar(
            item: item,
            walletCoins: walletCoins,
            isOwned: isOwned,
            isEquipped: isEquipped,
            backpackQuantity: backpackQuantity,
            onPurchasePressed: onPurchasePressed,
            onEquipPressed: onEquipPressed,
            onConsumePressed: onConsumePressed,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _UtilityPreviewCard extends StatelessWidget {
  const _UtilityPreviewCard({
    super.key,
    required this.item,
  });

  final ShopItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ShopUiTokens.surfaceRaised,
        borderRadius: ShopUiTokens.radiusXlShape,
        border: Border.all(color: ShopUiTokens.stroke),
        boxShadow: ShopUiTokens.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ClipRRect(
              borderRadius: ShopUiTokens.radiusLgShape,
              child: SizedBox(
                height: 260,
                width: double.infinity,
                child: Center(
                  child: _UtilityPreviewImage(item: item),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _UtilityBadge(
                  label: l10n.shopRarityLabelByShopItem(item.rarity),
                  backgroundColor: _rarityBackground(item.rarity),
                  foregroundColor: _rarityForeground(item.rarity),
                ),
                _UtilityBadge(
                  label: l10n.shopUtilityCategoryLabelForItem(item),
                  backgroundColor: ShopUiTokens.backgroundAlt,
                  foregroundColor: ShopUiTokens.textPrimary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
        return ShopUiTokens.accent;
      case ShopItemRarity.common:
        return ShopUiTokens.textPrimary;
    }
  }
}

class _UtilityBadge extends StatelessWidget {
  const _UtilityBadge({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: ShopUiTokens.radiusXlShape,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text(
          label,
          style: ShopUiTextStyles.labelSmall.copyWith(color: foregroundColor),
        ),
      ),
    );
  }
}

class _UtilityPreviewImage extends StatelessWidget {
  const _UtilityPreviewImage({required this.item});

  final ShopItem item;

  @override
  Widget build(BuildContext context) {
    final String? assetPath = item.assetRef;
    if (assetPath != null && assetPath.startsWith('assets/shop/utilities/')) {
      return ShopUtilityAssetArt(
        key: Key('shopUtilityDetailPreviewScale-${item.id}'),
        item: item,
        fallbackTone: _toneForItem(item.type),
        fallbackIcon: _fallbackIconForItem(item),
        filterQuality: FilterQuality.high,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: ShopUiTokens.backgroundAlt,
        borderRadius: ShopUiTokens.radiusLgShape,
      ),
      child: Center(
        child: Icon(
          _fallbackIconForItem(item),
          size: 84,
          color: ShopUiTokens.textPrimary,
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
        return Icons.restore_rounded;
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

  ShopPreviewPlaceholderTone _toneForItem(ShopItemType type) {
    switch (type) {
      case ShopItemType.xpBoost:
        return ShopPreviewPlaceholderTone.sage;
      case ShopItemType.coinBoost:
        return ShopPreviewPlaceholderTone.camel;
      case ShopItemType.streakRecover:
      case ShopItemType.streakShield:
        return ShopPreviewPlaceholderTone.sand;
      case ShopItemType.mysteryBox:
        return ShopPreviewPlaceholderTone.clay;
      case ShopItemType.background:
      case ShopItemType.habitCard:
      case ShopItemType.userCard:
        return ShopPreviewPlaceholderTone.charcoal;
    }
  }
}
