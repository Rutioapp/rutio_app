import 'package:flutter/material.dart';
import 'package:rutio/features/shop/application/shop_cosmetics_controller.dart';
import 'package:rutio/features/shop/data/shop_catalog.dart';
import 'package:rutio/features/shop/data/shop_assets_catalog.dart';
import 'package:rutio/features/shop/domain/models/equipped_cosmetics.dart';
import 'package:rutio/features/shop/domain/models/shop_asset.dart';
import 'package:rutio/features/shop/domain/models/shop_asset_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_state.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_empty_state.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_equipped_summary.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_header.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_owned_item_card.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_page_shell.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_primary_button.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_section_header.dart';

class ShopCustomizationScreen extends StatelessWidget {
  const ShopCustomizationScreen({
    super.key,
    required this.walletCoins,
    required this.equippedCosmetics,
    required this.ownedCosmeticItems,
    required this.onBackPressed,
    required this.onEquipPressed,
    required this.onItemPressed,
    this.onOpenCosmetics,
    this.cosmeticsController,
  });

  final int walletCoins;
  final EquippedCosmetics equippedCosmetics;
  final List<ShopItem> ownedCosmeticItems;
  final VoidCallback onBackPressed;
  final ValueChanged<String> onEquipPressed;
  final ValueChanged<String> onItemPressed;
  final VoidCallback? onOpenCosmetics;
  final ShopCosmeticsController? cosmeticsController;

  @override
  Widget build(BuildContext context) {
    final controller = cosmeticsController;
    if (controller != null) {
      return FutureBuilder<_CustomizationViewData>(
        future: _loadCustomizationViewData(controller),
        builder: (BuildContext context, AsyncSnapshot<_CustomizationViewData> snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return ShopPageShell(
              header: ShopHeader(
                title: 'Personalizacion',
                subtitle: 'Gestiona los cosmeticos que ya son tuyos',
                leadingIcon: Icons.arrow_back_ios_new_rounded,
                onLeadingPressed: onBackPressed,
                walletCoins: walletCoins,
              ),
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          final data = snapshot.data ??
              const _CustomizationViewData(
                walletCoins: 0,
                equippedCosmetics: EquippedCosmetics(),
                ownedCosmeticItems: <ShopItem>[],
              );
          return _buildContent(
            walletCoins: data.walletCoins,
            equippedCosmetics: data.equippedCosmetics,
            ownedCosmeticItems: data.ownedCosmeticItems,
          );
        },
      );
    }

    return _buildContent(
      walletCoins: walletCoins,
      equippedCosmetics: equippedCosmetics,
      ownedCosmeticItems: ownedCosmeticItems,
    );
  }

  Widget _buildContent({
    required int walletCoins,
    required EquippedCosmetics equippedCosmetics,
    required List<ShopItem> ownedCosmeticItems,
  }) {
    final List<ShopItem> backgrounds = _itemsForType(
      ownedCosmeticItems,
      ShopItemType.background,
    );
    final List<ShopItem> habitCards = _itemsForType(
      ownedCosmeticItems,
      ShopItemType.habitCard,
    );
    final List<ShopItem> userCards = _itemsForType(
      ownedCosmeticItems,
      ShopItemType.userCard,
    );

    return ShopPageShell(
      header: ShopHeader(
        title: 'Personalización',
        subtitle: 'Gestiona los cosméticos que ya son tuyos',
        leadingIcon: Icons.arrow_back_ios_new_rounded,
        onLeadingPressed: onBackPressed,
        walletCoins: walletCoins,
      ),
      child: ownedCosmeticItems.isEmpty
          ? _emptyState()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ShopEquippedSummary(
                  backgroundItem: _equippedItem(
                    ownedCosmeticItems,
                    equippedCosmetics,
                    ShopItemType.background,
                  ),
                  habitCardItem: _equippedItem(
                    ownedCosmeticItems,
                    equippedCosmetics,
                    ShopItemType.habitCard,
                  ),
                  userCardItem: _equippedItem(
                    ownedCosmeticItems,
                    equippedCosmetics,
                    ShopItemType.userCard,
                  ),
                ),
                const SizedBox(height: ShopUiTokens.sectionSpacing),
                const ShopSectionHeader(
                  title: 'Tus cosméticos',
                  subtitle: 'Todo lo que ya pertenece a tu cuenta.',
                ),
                const SizedBox(height: 4),
                if (backgrounds.isNotEmpty) ...<Widget>[
                  _OwnedSection(
                    title: 'Fondos',
                    items: backgrounds,
                    equippedCosmetics: equippedCosmetics,
                    onEquipPressed: onEquipPressed,
                    onItemPressed: onItemPressed,
                  ),
                  const SizedBox(height: ShopUiTokens.sectionSpacing),
                ],
                if (habitCards.isNotEmpty) ...<Widget>[
                  _OwnedSection(
                    title: 'Habit Cards',
                    items: habitCards,
                    equippedCosmetics: equippedCosmetics,
                    onEquipPressed: onEquipPressed,
                    onItemPressed: onItemPressed,
                  ),
                  const SizedBox(height: ShopUiTokens.sectionSpacing),
                ],
                if (userCards.isNotEmpty) ...<Widget>[
                  _OwnedSection(
                    title: 'User Cards',
                    items: userCards,
                    equippedCosmetics: equippedCosmetics,
                    onEquipPressed: onEquipPressed,
                    onItemPressed: onItemPressed,
                  ),
                ],
              ],
            ),
    );
  }

  Widget _emptyState() {
    return ShopEmptyState(
      key: const Key('shopCustomizationEmptyState'),
      icon: Icons.auto_awesome_rounded,
      title: 'Todavia no tienes cosméticos.',
      message: 'Compra nuevos objetos en la tienda para personalizar Rutio.',
      action: onOpenCosmetics == null
          ? null
          : ShopPrimaryButton(
              key: const Key('shopCustomizationOpenCosmetics'),
              label: 'Ir a Cosméticos',
              icon: Icons.palette_outlined,
              onPressed: onOpenCosmetics,
              expanded: false,
            ),
    );
  }

  List<ShopItem> _itemsForType(List<ShopItem> ownedCosmeticItems, ShopItemType type) {
    return ownedCosmeticItems
        .where((ShopItem item) => item.type == type)
        .toList(growable: false);
  }

  ShopItem? _equippedItem(
    List<ShopItem> ownedCosmeticItems,
    EquippedCosmetics equippedCosmetics,
    ShopItemType type,
  ) {
    final String? equippedId = _equippedItemId(equippedCosmetics, type);
    if (equippedId == null) {
      return null;
    }

    try {
      return ownedCosmeticItems.firstWhere((ShopItem item) => item.id == equippedId);
    } catch (_) {
      return ShopCatalog.getItemById(equippedId);
    }
  }

  String? _equippedItemId(
    EquippedCosmetics equippedCosmetics,
    ShopItemType type,
  ) {
    switch (type) {
      case ShopItemType.background:
        return equippedCosmetics.backgroundItemId;
      case ShopItemType.habitCard:
        return equippedCosmetics.habitCardItemId;
      case ShopItemType.userCard:
        return equippedCosmetics.userCardItemId;
      case ShopItemType.xpBoost:
      case ShopItemType.coinBoost:
      case ShopItemType.streakRecover:
      case ShopItemType.streakShield:
      case ShopItemType.mysteryBox:
        return null;
    }
  }

  Future<_CustomizationViewData> _loadCustomizationViewData(
    ShopCosmeticsController controller,
  ) async {
    final ShopCosmeticsState state = await controller.getState();
    final int resolvedWalletCoins = await controller.getWalletCoins();
    final List<ShopItem> resolvedItems = ShopAssetsCatalog.allAssets
        .where(
          (ShopAsset asset) => state.isAssetOwned(
            asset.id,
            bundles: ShopAssetsCatalog.allBundles,
          ),
        )
        .map(_mapAssetToShopItem)
        .whereType<ShopItem>()
        .toList(growable: false);

    return _CustomizationViewData(
      walletCoins: resolvedWalletCoins,
      equippedCosmetics: EquippedCosmetics(
        backgroundItemId: state.equippedWallpaperId,
        habitCardItemId: state.equippedHabitCardSkinId,
        userCardItemId: state.equippedUserCardSkinId,
      ),
      ownedCosmeticItems: resolvedItems,
    );
  }

  ShopItem? _mapAssetToShopItem(ShopAsset asset) {
    final existing = ShopCatalog.getItemById(asset.id);
    if (existing != null) {
      return existing;
    }

    return ShopItem(
      id: asset.id,
      title: asset.nameEn,
      description: asset.nameEs,
      type: _mapAssetType(asset.category),
      rarity: _mapRarity(asset.rarity),
      priceCoins: asset.priceAmber,
      assetRef: asset.assetPath,
      metadata: <String, dynamic>{'familyId': asset.familyId},
    );
  }

  ShopItemType _mapAssetType(ShopAssetCategory category) {
    switch (category) {
      case ShopAssetCategory.wallpaper:
        return ShopItemType.background;
      case ShopAssetCategory.habitCard:
        return ShopItemType.habitCard;
      case ShopAssetCategory.userCard:
        return ShopItemType.userCard;
    }
  }

  ShopItemRarity _mapRarity(ShopAssetRarity rarity) {
    switch (rarity) {
      case ShopAssetRarity.common:
        return ShopItemRarity.common;
      case ShopAssetRarity.rare:
        return ShopItemRarity.rare;
      case ShopAssetRarity.epic:
        return ShopItemRarity.epic;
      case ShopAssetRarity.legendary:
        return ShopItemRarity.legendary;
    }
  }
}

class _OwnedSection extends StatelessWidget {
  const _OwnedSection({
    required this.title,
    required this.items,
    required this.equippedCosmetics,
    required this.onEquipPressed,
    required this.onItemPressed,
  });

  final String title;
  final List<ShopItem> items;
  final EquippedCosmetics equippedCosmetics;
  final ValueChanged<String> onEquipPressed;
  final ValueChanged<String> onItemPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: Key('shopCustomizationSection-$title'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ShopSectionHeader(
          title: title,
          subtitle: '${items.length} objetos',
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final int crossAxisCount = constraints.maxWidth >= 560 ? 3 : 2;
            final double aspectRatio = crossAxisCount == 3 ? 0.50 : 0.55;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: aspectRatio,
              ),
              itemBuilder: (BuildContext context, int index) {
                final ShopItem item = items[index];
                return ShopOwnedItemCard(
                  key: Key('shopOwnedItem-${item.id}'),
                  item: item,
                  isEquipped: _isEquipped(item, equippedCosmetics),
                  onTap: () => onItemPressed(item.id),
                  onEquipPressed: onEquipPressed,
                );
              },
            );
          },
        ),
      ],
    );
  }

  bool _isEquipped(ShopItem item, EquippedCosmetics equippedCosmetics) {
    switch (item.type) {
      case ShopItemType.background:
        return equippedCosmetics.backgroundItemId == item.id;
      case ShopItemType.habitCard:
        return equippedCosmetics.habitCardItemId == item.id;
      case ShopItemType.userCard:
        return equippedCosmetics.userCardItemId == item.id;
      case ShopItemType.xpBoost:
      case ShopItemType.coinBoost:
      case ShopItemType.streakRecover:
      case ShopItemType.streakShield:
      case ShopItemType.mysteryBox:
        return false;
    }
  }
}

class _CustomizationViewData {
  const _CustomizationViewData({
    required this.walletCoins,
    required this.equippedCosmetics,
    required this.ownedCosmeticItems,
  });

  final int walletCoins;
  final EquippedCosmetics equippedCosmetics;
  final List<ShopItem> ownedCosmeticItems;
}
