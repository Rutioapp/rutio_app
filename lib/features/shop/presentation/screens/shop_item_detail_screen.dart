import 'package:flutter/material.dart';
import 'package:rutio/features/shop/data/shop_catalog.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_header.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_item_detail_action_bar.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_item_detail_info_row.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_item_detail_preview.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_page_shell.dart';

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
        title: 'Detalle',
        subtitle: _headerSubtitle(item),
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
            item.title,
            key: const Key('shopItemDetailTitle'),
            style: ShopUiTextStyles.pageTitle.copyWith(fontSize: 30),
          ),
          const SizedBox(height: 10),
          Text(
            item.description.isEmpty
                ? 'Sin descripcion todavia.'
                : item.description,
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
                    label: 'Rareza',
                    value: _rarityLabel(item.rarity),
                  ),
                  const SizedBox(height: 12),
                  ShopItemDetailInfoRow(
                    label: 'Tipo',
                    value: _typeLabel(item.type),
                  ),
                  if (collectionName != null &&
                      collectionName!.trim().isNotEmpty) ...<Widget>[
                    const SizedBox(height: 12),
                    ShopItemDetailInfoRow(
                      label: 'Coleccion',
                      value: collectionName!,
                    ),
                  ],
                  const SizedBox(height: 12),
                  ShopItemDetailInfoRow(
                    label: 'Precio',
                    value: '${item.priceCoins} coins',
                  ),
                  const SizedBox(height: 12),
                  ShopItemDetailInfoRow(
                    label: 'Estado',
                    value: _statusLabel(),
                    valueKey: const Key('shopItemDetailStatusValue'),
                  ),
                  if (backpackQuantity != null &&
                      backpackQuantity! > 0) ...<Widget>[
                    const SizedBox(height: 12),
                    ShopItemDetailInfoRow(
                      label: 'Mochila',
                      value: 'x$backpackQuantity',
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

  String _headerSubtitle(ShopItem item) {
    if (item.cosmeticSlot != null) {
      return 'Cosmetico';
    }
    return 'Utilidad';
  }

  String _statusLabel() {
    if (isEquipped) {
      return 'Equipado';
    }
    if ((backpackQuantity ?? 0) > 0) {
      return 'En mochila x$backpackQuantity';
    }
    if (isOwned) {
      return 'Comprado';
    }
    return 'Disponible';
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

  String _typeLabel(ShopItemType type) {
    switch (type) {
      case ShopItemType.background:
        return 'Fondo';
      case ShopItemType.habitCard:
        return 'Habit card';
      case ShopItemType.userCard:
        return 'User card';
      case ShopItemType.xpBoost:
        return 'XP Boost';
      case ShopItemType.coinBoost:
        return 'Coin Boost';
      case ShopItemType.streakRecover:
        return 'Streak Recover';
      case ShopItemType.streakShield:
        return 'Streak Shield';
      case ShopItemType.mysteryBox:
        return 'Mystery Box';
    }
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
    return ShopPageShell(
      header: ShopHeader(
        title: 'Detalle',
        leadingIcon: Icons.arrow_back_ios_new_rounded,
        onLeadingPressed: onBackPressed,
        walletCoins: walletCoins,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            item.title,
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
            item.description,
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
                    label: 'Tipo',
                    value: ShopCatalog.utilityCategoryLabel(item),
                    valueKey: const Key('shopItemDetailUtilityTypeValue'),
                  ),
                  const SizedBox(height: 12),
                  ShopItemDetailInfoRow(
                    label: 'Rareza',
                    value: _rarityLabel(item.rarity),
                    valueKey: const Key('shopItemDetailUtilityRarityValue'),
                  ),
                  const SizedBox(height: 12),
                  ShopItemDetailInfoRow(
                    label: 'Duracion',
                    value: ShopCatalog.utilityDurationLabel(item),
                    valueKey: const Key('shopItemDetailUtilityDurationValue'),
                  ),
                  const SizedBox(height: 12),
                  ShopItemDetailInfoRow(
                    label: 'Efecto',
                    value: ShopCatalog.utilityEffectLabel(item),
                    valueKey: const Key('shopItemDetailUtilityEffectValue'),
                    valueStyle: ShopUiTextStyles.label.copyWith(fontSize: 12.5),
                    valueMaxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  ShopItemDetailInfoRow(
                    label: 'Precio',
                    value: '${item.priceCoins} coins',
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
}

class _UtilityPreviewCard extends StatelessWidget {
  const _UtilityPreviewCard({
    super.key,
    required this.item,
  });

  final ShopItem item;

  @override
  Widget build(BuildContext context) {
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
                  label: _rarityLabel(item.rarity),
                  backgroundColor: _rarityBackground(item.rarity),
                  foregroundColor: _rarityForeground(item.rarity),
                ),
                _UtilityBadge(
                  label: ShopCatalog.utilityCategoryLabel(item),
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
      return Image.asset(
        assetPath,
        fit: BoxFit.contain,
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
}
