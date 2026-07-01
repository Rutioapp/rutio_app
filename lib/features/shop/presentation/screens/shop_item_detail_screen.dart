import 'package:flutter/material.dart';
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
          ShopItemDetailInfoRow(
            label: 'Rareza',
            value: _rarityLabel(item.rarity),
          ),
          const SizedBox(height: 12),
          if (collectionName != null && collectionName!.trim().isNotEmpty) ...<Widget>[
            ShopItemDetailInfoRow(
              label: 'Coleccion',
              value: collectionName!,
            ),
            const SizedBox(height: 12),
          ],
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
          if (backpackQuantity != null && backpackQuantity! > 0) ...<Widget>[
            const SizedBox(height: 12),
            ShopItemDetailInfoRow(
              label: 'Mochila',
              value: 'x$backpackQuantity',
            ),
          ],
          const SizedBox(height: 120),
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
}
