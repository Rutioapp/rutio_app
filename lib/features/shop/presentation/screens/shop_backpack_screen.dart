import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rutio/features/shop/domain/models/active_utility_effect.dart';
import 'package:rutio/features/shop/domain/models/mystery_box_opening_transaction.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/presentation/models/backpack_item_view_model.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_backpack_active_effects_section.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_backpack_empty_state.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_backpack_item_card.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_empty_state.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_filter_chip.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_header.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_page_shell.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_primary_button.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_section_header.dart';
import 'package:rutio/l10n/l10n.dart';

enum ShopBackpackFilter {
  all,
  boosts,
  streaks,
  boxes,
}

class ShopBackpackScreen extends StatefulWidget {
  const ShopBackpackScreen({
    super.key,
    required this.walletCoins,
    required this.items,
    required this.activeEffects,
    required this.pendingMysteryBoxOpenings,
    required this.onBackPressed,
    required this.onItemPressed,
    required this.onUsePressed,
    this.onOpenUtilities,
    this.onContinueMysteryBoxOpening,
  });

  final int walletCoins;
  final List<BackpackItemViewModel> items;
  final List<ActiveUtilityEffect> activeEffects;
  final List<MysteryBoxOpeningTransaction> pendingMysteryBoxOpenings;
  final VoidCallback onBackPressed;
  final ValueChanged<String> onItemPressed;
  final Future<void> Function(String) onUsePressed;
  final VoidCallback? onOpenUtilities;
  final Future<void> Function(MysteryBoxOpeningTransaction)?
      onContinueMysteryBoxOpening;

  @override
  State<ShopBackpackScreen> createState() => _ShopBackpackScreenState();
}

class _ShopBackpackScreenState extends State<ShopBackpackScreen> {
  String? _busyItemId;
  ShopBackpackFilter _selectedFilter = ShopBackpackFilter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final visibleItems = widget.items
        .map(
          (item) => item.copyWith(
            isActivating: _busyItemId == item.itemId,
          ),
        )
        .toList(growable: false);
    final filteredItems = _filterItems(visibleItems, _selectedFilter);
    final pendingMysteryBox = widget.pendingMysteryBoxOpenings.isEmpty
        ? null
        : widget.pendingMysteryBoxOpenings.first;

    return ShopPageShell(
      header: ShopHeader(
        title: l10n.shopBackpackTitle,
        subtitle: l10n.shopBackpackSubtitle,
        leadingIcon: Icons.arrow_back_ios_new_rounded,
        onLeadingPressed: widget.onBackPressed,
        walletCoins: widget.walletCoins,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (pendingMysteryBox != null) ...<Widget>[
            _PendingMysteryBoxBanner(
              pendingCount: widget.pendingMysteryBoxOpenings.length,
              onContinue: widget.onContinueMysteryBoxOpening == null
                  ? null
                  : () {
                      unawaited(
                        widget.onContinueMysteryBoxOpening!(pendingMysteryBox),
                      );
                    },
            ),
            const SizedBox(height: 16),
          ],
          ShopBackpackActiveEffectsSection(effects: widget.activeEffects),
          const SizedBox(height: 18),
          const ShopSectionHeader(
            title: 'Filtros',
          ),
          const SizedBox(height: 4),
          _BackpackFilterRow(
            selectedFilter: _selectedFilter,
            onFilterSelected: (filter) {
              if (filter == _selectedFilter) return;
              setState(() {
                _selectedFilter = filter;
              });
            },
          ),
          const SizedBox(height: 18),
          const ShopSectionHeader(
            title: 'Tus consumibles',
          ),
          const SizedBox(height: 10),
          if (widget.items.isEmpty)
            ShopBackpackEmptyState(onOpenUtilities: widget.onOpenUtilities)
          else if (filteredItems.isEmpty)
            _CompactFilterEmptyState(
              key: Key('shopBackpackFilteredEmptyState'),
              message: l10n.shopEmptyStateNoResultsMessage,
            )
          else
            _BackpackItemsGrid(
              items: filteredItems,
              onItemPressed: widget.onItemPressed,
              onUsePressed: _handleUsePressed,
            ),
        ],
      ),
    );
  }

  Future<void> _handleUsePressed(String itemId) async {
    if (_busyItemId == itemId) return;

    final item = widget.items.firstWhere(
      (entry) => entry.itemId == itemId,
      orElse: () => BackpackItemViewModel(
        itemId: itemId,
        title: itemId,
        description: '',
        quantity: 0,
        rarity: ShopItemRarity.common,
        type: ShopItemType.mysteryBox,
      ),
    );

    if (item.isBoost && item.isActive) return;

    setState(() {
      _busyItemId = itemId;
    });

    try {
      await widget.onUsePressed(itemId);
    } finally {
      if (mounted) {
        setState(() {
          _busyItemId = null;
        });
      }
    }
  }

  List<BackpackItemViewModel> _filterItems(
    List<BackpackItemViewModel> items,
    ShopBackpackFilter filter,
  ) {
    switch (filter) {
      case ShopBackpackFilter.all:
        return items;
      case ShopBackpackFilter.boosts:
        return items.where((item) => item.isBoost).toList(growable: false);
      case ShopBackpackFilter.streaks:
        return items
            .where(
              (item) =>
                  item.type == ShopItemType.streakRecover ||
                  item.type == ShopItemType.streakShield,
            )
            .toList(growable: false);
      case ShopBackpackFilter.boxes:
        return items
            .where((item) => item.type == ShopItemType.mysteryBox)
            .toList(growable: false);
    }
  }
}

class _PendingMysteryBoxBanner extends StatelessWidget {
  const _PendingMysteryBoxBanner({
    required this.pendingCount,
    required this.onContinue,
  });

  final int pendingCount;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ShopUiTokens.surfaceRaised,
        borderRadius: ShopUiTokens.radiusLgShape,
        border: Border.all(color: ShopUiTokens.stroke),
        boxShadow: ShopUiTokens.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: ShopUiTokens.coinSoft,
                borderRadius: ShopUiTokens.radiusMdShape,
              ),
              child: const Icon(
                Icons.card_giftcard_rounded,
                color: ShopUiTokens.textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.shopMysteryBoxOpeningTitle,
                    style: ShopUiTextStyles.cardTitle.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pendingCount == 1
                        ? l10n.shopMysteryBoxRewardDescription
                        : l10n.shopMysteryBoxRewardDescription,
                    style: ShopUiTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            if (onContinue != null) ...<Widget>[
              const SizedBox(width: 12),
              ShopPrimaryButton(
                label: l10n.shopActionContinue,
                icon: Icons.play_arrow_rounded,
                onPressed: onContinue,
                expanded: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BackpackFilterRow extends StatelessWidget {
  const _BackpackFilterRow({
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  final ShopBackpackFilter selectedFilter;
  final ValueChanged<ShopBackpackFilter> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: ShopBackpackFilter.values.map((filter) {
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ShopFilterChip(
              key: Key('shopBackpackFilter-${filter.name}'),
              label: switch (filter) {
                ShopBackpackFilter.all => l10n.shopFilterAll,
                ShopBackpackFilter.boosts => l10n.shopFilterBoosts,
                ShopBackpackFilter.streaks => l10n.shopFilterStreak,
                ShopBackpackFilter.boxes => l10n.shopFilterBoxes,
              },
              selected: selectedFilter == filter,
              onTap: () => onFilterSelected(filter),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}

class _BackpackItemsGrid extends StatelessWidget {
  const _BackpackItemsGrid({
    required this.items,
    required this.onItemPressed,
    required this.onUsePressed,
  });

  final List<BackpackItemViewModel> items;
  final ValueChanged<String> onItemPressed;
  final Future<void> Function(String) onUsePressed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final crossAxisCount = constraints.maxWidth >= 720 ? 3 : 2;
        return GridView.builder(
          key: const Key('shopBackpackItemsGrid'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 250,
          ),
          itemBuilder: (BuildContext context, int index) {
            final item = items[index];
            return ShopBackpackItemCard(
              key: Key('shopBackpackCard-${item.itemId}'),
              item: item,
              onTap: () => onItemPressed(item.itemId),
              onUsePressed: onUsePressed,
            );
          },
        );
      },
    );
  }
}

class _CompactFilterEmptyState extends StatelessWidget {
  const _CompactFilterEmptyState({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return ShopEmptyState(
      title: 'Sin resultados',
      message: message,
      icon: Icons.search_off_rounded,
    );
  }
}
