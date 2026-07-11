import 'package:flutter/material.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_empty_state.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_filter_chip.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_header.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_page_shell.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_section_header.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_utility_item_card.dart';

enum ShopUtilitiesFilter {
  all,
  boosts,
  streaks,
}

extension ShopUtilitiesFilterX on ShopUtilitiesFilter {
  String get label {
    switch (this) {
      case ShopUtilitiesFilter.all:
        return 'Todo';
      case ShopUtilitiesFilter.boosts:
        return 'Boosts';
      case ShopUtilitiesFilter.streaks:
        return 'Rachas';
    }
  }
}

class ShopUtilitiesScreen extends StatefulWidget {
  const ShopUtilitiesScreen({
    super.key,
    required this.walletCoins,
    required this.items,
    required this.onItemPressed,
    this.onBackPressed,
  });

  final int walletCoins;
  final List<ShopItem> items;
  final VoidCallback? onBackPressed;
  final ValueChanged<String> onItemPressed;

  @override
  State<ShopUtilitiesScreen> createState() => _ShopUtilitiesScreenState();
}

class _ShopUtilitiesScreenState extends State<ShopUtilitiesScreen> {
  ShopUtilitiesFilter _selectedFilter = ShopUtilitiesFilter.all;

  @override
  Widget build(BuildContext context) {
    final List<_UtilitySectionData> sections =
        _sectionsForFilter(widget.items, _selectedFilter);

    return ShopPageShell(
      header: ShopHeader(
        title: 'Utilidades',
        subtitle: 'Ayudas suaves para Rutio',
        titleStyle: ShopUiTextStyles.headerTitle.copyWith(fontSize: 22.5),
        leadingIcon: Icons.arrow_back_ios_new_rounded,
        onLeadingPressed: widget.onBackPressed,
        walletCoins: widget.walletCoins,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _UtilitiesFilterRow(
            selectedFilter: _selectedFilter,
            onFilterSelected: (ShopUtilitiesFilter filter) {
              if (filter == _selectedFilter) return;
              setState(() {
                _selectedFilter = filter;
              });
            },
          ),
          const SizedBox(height: 18),
          if (sections.isEmpty)
            const ShopEmptyState(
              title: 'Nada por mostrar',
              message: 'No hay utilidades disponibles en esta categoría.',
            )
          else
            ..._buildSections(sections),
        ],
      ),
    );
  }

  List<Widget> _buildSections(List<_UtilitySectionData> sections) {
    final List<Widget> result = <Widget>[];
    for (int index = 0; index < sections.length; index++) {
      final _UtilitySectionData section = sections[index];
      result.add(
        _Section(
          key: Key('shopUtilitiesSection-${section.filter.name}'),
          title: section.title,
          items: section.items,
          onItemPressed: widget.onItemPressed,
        ),
      );
      if (index != sections.length - 1) {
        result.add(const SizedBox(height: ShopUiTokens.sectionSpacing));
      }
    }
    return result;
  }

  List<_UtilitySectionData> _sectionsForFilter(
    List<ShopItem> items,
    ShopUtilitiesFilter filter,
  ) {
    final List<_UtilitySectionData> allSections = <_UtilitySectionData>[
      _UtilitySectionData(
        title: 'Boosts',
        filter: ShopUtilitiesFilter.boosts,
        items: items
            .where((ShopItem item) =>
                item.type == ShopItemType.xpBoost ||
                item.type == ShopItemType.coinBoost)
            .toList(growable: false),
      ),
      _UtilitySectionData(
        title: 'Rachas',
        filter: ShopUtilitiesFilter.streaks,
        items: items
            .where((ShopItem item) =>
                item.type == ShopItemType.streakRecover ||
                item.type == ShopItemType.streakShield)
            .toList(growable: false),
      ),
      _UtilitySectionData(
        title: 'Cajas',
        filter: ShopUtilitiesFilter.all,
        items: items
            .where((ShopItem item) => item.type == ShopItemType.mysteryBox)
            .toList(growable: false),
      ),
    ].where((section) => section.items.isNotEmpty).toList(growable: false);

    switch (filter) {
      case ShopUtilitiesFilter.all:
        return allSections;
      case ShopUtilitiesFilter.boosts:
        return allSections
            .where((section) => section.filter == ShopUtilitiesFilter.boosts)
            .toList(growable: false);
      case ShopUtilitiesFilter.streaks:
        return allSections
            .where((section) => section.filter == ShopUtilitiesFilter.streaks)
            .toList(growable: false);
    }
  }
}

class _UtilitiesFilterRow extends StatelessWidget {
  const _UtilitiesFilterRow({
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  final ShopUtilitiesFilter selectedFilter;
  final ValueChanged<ShopUtilitiesFilter> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: <Widget>[
          _buildChip(ShopUtilitiesFilter.all),
          const SizedBox(width: 10),
          _buildChip(ShopUtilitiesFilter.boosts),
          const SizedBox(width: 10),
          _buildChip(ShopUtilitiesFilter.streaks),
        ],
      ),
    );
  }

  Widget _buildChip(ShopUtilitiesFilter filter) {
    return ShopFilterChip(
      key: Key('shopUtilitiesFilter-${filter.name}'),
      label: filter.label,
      selected: selectedFilter == filter,
      onTap: () => onFilterSelected(filter),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    super.key,
    required this.title,
    required this.items,
    required this.onItemPressed,
  });

  final String title;
  final List<ShopItem> items;
  final ValueChanged<String> onItemPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: Key('shopUtilitiesSection-$title'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ShopSectionHeader(
          title: title,
          subtitle: '${items.length} utilidades',
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final int crossAxisCount = constraints.maxWidth >= 560 ? 3 : 2;
            final double mainAxisExtent = 286;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                mainAxisExtent: mainAxisExtent,
              ),
              itemBuilder: (BuildContext context, int index) {
                final ShopItem item = items[index];
                return ShopUtilityItemCard(
                  key: Key('shopUtilityCard-${item.id}'),
                  item: item,
                  onTap: () => onItemPressed(item.id),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _UtilitySectionData {
  const _UtilitySectionData({
    required this.title,
    required this.filter,
    required this.items,
  });

  final String title;
  final ShopUtilitiesFilter filter;
  final List<ShopItem> items;
}
