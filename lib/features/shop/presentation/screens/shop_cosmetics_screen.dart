import 'package:flutter/material.dart';
import 'package:rutio/features/shop/domain/models/equipped_cosmetics.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_cosmetic_item_card.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_filter_chip.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_header.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_page_shell.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_section_header.dart';

enum ShopCosmeticsFilter {
  all,
  backgrounds,
  habitCards,
  userCards,
}

class ShopCosmeticsScreen extends StatefulWidget {
  const ShopCosmeticsScreen({
    super.key,
    required this.walletCoins,
    required this.items,
    required this.onItemPressed,
    this.ownedItemIds = const <String>{},
    this.equippedCosmetics = const EquippedCosmetics(),
    this.onBackPressed,
    this.onMenuPressed,
    this.onViewAllPressed,
  });

  final int walletCoins;
  final List<ShopItem> items;
  final Set<String> ownedItemIds;
  final EquippedCosmetics equippedCosmetics;
  final VoidCallback? onBackPressed;
  final VoidCallback? onMenuPressed;
  final ValueChanged<String> onItemPressed;
  final ValueChanged<ShopCosmeticsFilter>? onViewAllPressed;

  @override
  State<ShopCosmeticsScreen> createState() => _ShopCosmeticsScreenState();
}

class _ShopCosmeticsScreenState extends State<ShopCosmeticsScreen> {
  ShopCosmeticsFilter _selectedFilter = ShopCosmeticsFilter.all;

  @override
  Widget build(BuildContext context) {
    final List<ShopItem> cosmeticItems = widget.items
        .where((ShopItem item) => item.category == ShopItemCategory.cosmetic)
        .toList(growable: false);

    final sections = <_CosmeticSectionData>[
      _CosmeticSectionData(
        title: 'Fondos',
        filter: ShopCosmeticsFilter.backgrounds,
        itemType: ShopItemType.background,
      ),
      _CosmeticSectionData(
        title: 'Cards de hábitos',
        filter: ShopCosmeticsFilter.habitCards,
        itemType: ShopItemType.habitCard,
      ),
      _CosmeticSectionData(
        title: 'Cards de usuario',
        filter: ShopCosmeticsFilter.userCards,
        itemType: ShopItemType.userCard,
      ),
    ];

    final visibleSections = sections.where(
      (_CosmeticSectionData section) =>
          _selectedFilter == ShopCosmeticsFilter.all ||
          _selectedFilter == section.filter,
    );

    return ShopPageShell(
      header: ShopHeader(
        title: 'Cosméticos',
        subtitle: 'Personaliza tu Rutio',
        leadingIcon: widget.onBackPressed != null
            ? Icons.arrow_back_ios_new_rounded
            : Icons.menu_rounded,
        onLeadingPressed: widget.onBackPressed ?? widget.onMenuPressed,
        trailingIcon: widget.onBackPressed != null && widget.onMenuPressed != null
            ? Icons.menu_rounded
            : null,
        onTrailingPressed:
            widget.onBackPressed != null ? widget.onMenuPressed : null,
        walletCoins: widget.walletCoins,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _FilterRow(
            selectedFilter: _selectedFilter,
            onFilterSelected: (ShopCosmeticsFilter filter) {
              setState(() {
                _selectedFilter = filter;
              });
            },
          ),
          const SizedBox(height: ShopUiTokens.sectionSpacing),
          for (final _CosmeticSectionData section in visibleSections) ...<Widget>[
            _CosmeticSection(
              title: section.title,
              items: cosmeticItems
                  .where((ShopItem item) => item.type == section.itemType)
                  .toList(growable: false),
              ownedItemIds: widget.ownedItemIds,
              equippedCosmetics: widget.equippedCosmetics,
              onItemPressed: widget.onItemPressed,
              onViewAllPressed: widget.onViewAllPressed == null
                  ? null
                  : () => widget.onViewAllPressed!(section.filter),
            ),
            const SizedBox(height: ShopUiTokens.sectionSpacing),
          ],
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  final ShopCosmeticsFilter selectedFilter;
  final ValueChanged<ShopCosmeticsFilter> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          ShopFilterChip(
            key: const Key('shopCosmeticsFilter-all'),
            label: 'Todos',
            selected: selectedFilter == ShopCosmeticsFilter.all,
            onTap: () => onFilterSelected(ShopCosmeticsFilter.all),
          ),
          const SizedBox(width: 10),
          ShopFilterChip(
            key: const Key('shopCosmeticsFilter-backgrounds'),
            label: 'Fondos',
            selected: selectedFilter == ShopCosmeticsFilter.backgrounds,
            onTap: () => onFilterSelected(ShopCosmeticsFilter.backgrounds),
          ),
          const SizedBox(width: 10),
          ShopFilterChip(
            key: const Key('shopCosmeticsFilter-habitCards'),
            label: 'Cards',
            selected: selectedFilter == ShopCosmeticsFilter.habitCards,
            onTap: () => onFilterSelected(ShopCosmeticsFilter.habitCards),
          ),
          const SizedBox(width: 10),
          ShopFilterChip(
            key: const Key('shopCosmeticsFilter-userCards'),
            label: 'Usuario',
            selected: selectedFilter == ShopCosmeticsFilter.userCards,
            onTap: () => onFilterSelected(ShopCosmeticsFilter.userCards),
          ),
        ],
      ),
    );
  }
}

class _CosmeticSection extends StatelessWidget {
  const _CosmeticSection({
    required this.title,
    required this.items,
    required this.ownedItemIds,
    required this.equippedCosmetics,
    required this.onItemPressed,
    this.onViewAllPressed,
  });

  final String title;
  final List<ShopItem> items;
  final Set<String> ownedItemIds;
  final EquippedCosmetics equippedCosmetics;
  final ValueChanged<String> onItemPressed;
  final VoidCallback? onViewAllPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: Key('shopCosmeticsSection-$title'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ShopSectionHeader(
          title: title,
          subtitle: '${items.length} opciones disponibles',
          trailing: onViewAllPressed == null
              ? null
              : TextButton(
                  onPressed: onViewAllPressed,
                  child: const Text('Ver todo'),
                ),
        ),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final int crossAxisCount = constraints.maxWidth >= 560 ? 3 : 2;
            final double childAspectRatio =
                crossAxisCount == 3 ? 0.75 : 0.68;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: childAspectRatio,
              ),
              itemBuilder: (BuildContext context, int index) {
                final ShopItem item = items[index];
                return ShopCosmeticItemCard(
                  key: Key('shopCosmeticCard-${item.id}'),
                  item: item,
                  isOwned: ownedItemIds.contains(item.id),
                  isEquipped: _isEquipped(item, equippedCosmetics),
                  onPressed: () => onItemPressed(item.id),
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

class _CosmeticSectionData {
  const _CosmeticSectionData({
    required this.title,
    required this.filter,
    required this.itemType,
  });

  final String title;
  final ShopCosmeticsFilter filter;
  final ShopItemType itemType;
}
