import 'package:flutter/material.dart';
import 'package:rutio/features/shop/application/shop_cosmetics_controller.dart';
import 'package:rutio/features/shop/data/shop_assets_catalog.dart';
import 'package:rutio/features/shop/data/shop_catalog.dart';
import 'package:rutio/features/shop/domain/models/equipped_cosmetics.dart';
import 'package:rutio/features/shop/domain/models/shop_asset.dart';
import 'package:rutio/features/shop/domain/models/shop_asset_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_bundle.dart';
import 'package:rutio/features/shop/domain/models/shop_bundle_completion_quote.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_state.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_empty_state.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_equipped_summary.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_filter_chip.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_header.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_owned_bundle_card.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_owned_item_card.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_page_shell.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_primary_button.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_section_header.dart';

enum PersonalizationCosmeticFilter {
  packs,
  backgrounds,
  habitCards,
  userCards,
}

extension PersonalizationCosmeticFilterX on PersonalizationCosmeticFilter {
  String get label {
    switch (this) {
      case PersonalizationCosmeticFilter.packs:
        return 'Packs';
      case PersonalizationCosmeticFilter.backgrounds:
        return 'Fondos';
      case PersonalizationCosmeticFilter.habitCards:
        return 'Habit Cards';
      case PersonalizationCosmeticFilter.userCards:
        return 'User Cards';
    }
  }

  bool get isBundleFilter => this == PersonalizationCosmeticFilter.packs;

  ShopItemType? get itemType {
    switch (this) {
      case PersonalizationCosmeticFilter.packs:
        return null;
      case PersonalizationCosmeticFilter.backgrounds:
        return ShopItemType.background;
      case PersonalizationCosmeticFilter.habitCards:
        return ShopItemType.habitCard;
      case PersonalizationCosmeticFilter.userCards:
        return ShopItemType.userCard;
    }
  }
}

class ShopCustomizationScreen extends StatefulWidget {
  const ShopCustomizationScreen({
    super.key,
    required this.walletCoins,
    required this.equippedCosmetics,
    required this.ownedCosmeticItems,
    this.ownedBundles = const <ShopBundle>[],
    required this.onBackPressed,
    required this.onEquipPressed,
    required this.onEquipBundlePressed,
    required this.onItemPressed,
    this.onOpenCosmetics,
    this.cosmeticsController,
  });

  final int walletCoins;
  final EquippedCosmetics equippedCosmetics;
  final List<ShopItem> ownedCosmeticItems;
  final List<ShopBundle> ownedBundles;
  final VoidCallback onBackPressed;
  final Future<void> Function(String itemId) onEquipPressed;
  final Future<void> Function(String bundleId) onEquipBundlePressed;
  final ValueChanged<String> onItemPressed;
  final VoidCallback? onOpenCosmetics;
  final ShopCosmeticsController? cosmeticsController;

  @override
  State<ShopCustomizationScreen> createState() =>
      _ShopCustomizationScreenState();
}

class _ShopCustomizationScreenState extends State<ShopCustomizationScreen> {
  PersonalizationCosmeticFilter _selectedFilter =
      PersonalizationCosmeticFilter.backgrounds;
  Future<void>? _controllerHydrationFuture;
  ShopCosmeticsController? _cachedController;
  String? _busyEquipItemId;
  String? _busyEquipBundleId;

  @override
  void initState() {
    super.initState();
    _syncControllerHydration();
  }

  @override
  void didUpdateWidget(covariant ShopCustomizationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.cosmeticsController, widget.cosmeticsController)) {
      _syncControllerHydration();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.cosmeticsController;
    if (controller != null) {
      return FutureBuilder<void>(
        future: _controllerHydrationFuture,
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return ShopPageShell(
              header: ShopHeader(
                title: 'Personalizaci\u00f3n',
                subtitle: 'Gestiona los cosm\u00e9ticos que ya son tuyos',
                leadingIcon: Icons.arrow_back_ios_new_rounded,
                onLeadingPressed: widget.onBackPressed,
                walletCoins: widget.walletCoins,
              ),
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          return AnimatedBuilder(
            animation: controller,
            builder: (BuildContext context, _) {
              final data = _buildControllerViewData(controller);
              return _buildContent(
                walletCoins: data.walletCoins,
                equippedCosmetics: data.equippedCosmetics,
                ownedCosmeticItems: data.ownedCosmeticItems,
                ownedBundles: data.ownedBundles,
                cosmeticsState: data.cosmeticsState,
              );
            },
          );
        },
      );
    }

    return _buildContent(
      walletCoins: widget.walletCoins,
      equippedCosmetics: widget.equippedCosmetics,
      ownedCosmeticItems: widget.ownedCosmeticItems,
      ownedBundles: widget.ownedBundles,
      cosmeticsState: _buildStateFromProps(),
    );
  }

  void _syncControllerHydration() {
    final controller = widget.cosmeticsController;
    if (controller == null) {
      _cachedController = null;
      _controllerHydrationFuture = null;
      return;
    }

    if (identical(_cachedController, controller) &&
        _controllerHydrationFuture != null) {
      return;
    }

    _cachedController = controller;
    _controllerHydrationFuture = _hydrateControllerState(controller);
  }

  Widget _buildContent({
    required int walletCoins,
    required EquippedCosmetics equippedCosmetics,
    required List<ShopItem> ownedCosmeticItems,
    required List<ShopBundle> ownedBundles,
    required ShopCosmeticsState cosmeticsState,
  }) {
    final List<ShopItem> filteredItems = _selectedFilter.isBundleFilter
        ? const <ShopItem>[]
        : _itemsForFilter(ownedCosmeticItems, _selectedFilter);
    final List<ShopBundle> filteredBundles = _selectedFilter.isBundleFilter
        ? _bundlesForFilter(cosmeticsState)
        : const <ShopBundle>[];

    return ShopPageShell(
      header: ShopHeader(
        title: 'Personalizaci\u00f3n',
        subtitle: 'Gestiona los cosm\u00e9ticos que ya son tuyos',
        leadingIcon: Icons.arrow_back_ios_new_rounded,
        onLeadingPressed: widget.onBackPressed,
        walletCoins: walletCoins,
      ),
      child: Column(
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
            title: 'Tus cosm\u00e9ticos',
            subtitle: 'Todo lo que ya pertenece a tu cuenta.',
          ),
          const SizedBox(height: 8),
          _PersonalizationCosmeticFilterChips(
            selectedFilter: _selectedFilter,
            onChanged: (PersonalizationCosmeticFilter filter) {
              if (filter == _selectedFilter) return;
              setState(() {
                _selectedFilter = filter;
              });
            },
          ),
          const SizedBox(height: 16),
          if (_selectedFilter.isBundleFilter)
            if (filteredBundles.isEmpty)
              _bundleEmptyState()
            else
              _OwnedBundlesSection(
                key: const Key('shopCustomizationBundleSection'),
                bundles: filteredBundles,
                equippedCosmetics: equippedCosmetics,
                cosmeticsState: cosmeticsState,
                busyEquipBundleId: _busyEquipBundleId,
                onEquipPressed: _handleEquipBundlePressed,
              )
          else if (filteredItems.isEmpty)
            _categoryEmptyState(_selectedFilter)
          else
            _OwnedSection(
              key: Key('shopCustomizationCategory-${_selectedFilter.name}'),
              title: _selectedFilter.label,
              items: filteredItems,
              equippedCosmetics: equippedCosmetics,
              busyEquipItemId: _busyEquipItemId,
              onEquipPressed: _handleEquipPressed,
              onItemPressed: widget.onItemPressed,
            ),
        ],
      ),
    );
  }

  Widget _categoryEmptyState(PersonalizationCosmeticFilter filter) {
    return ShopEmptyState(
      key: Key('shopCustomizationCategoryEmptyState-${filter.name}'),
      icon: Icons.auto_awesome_rounded,
      title: 'Todav\u00eda no tienes elementos aqu\u00ed',
      message:
          'Cuando consigas cosm\u00e9ticos de esta categor\u00eda aparecer\u00e1n en esta secci\u00f3n.',
      action: widget.onOpenCosmetics == null
          ? null
          : ShopPrimaryButton(
              key: const Key('shopCustomizationOpenCosmetics'),
              label: 'Ir a Cosm\u00e9ticos',
              icon: Icons.palette_outlined,
              onPressed: widget.onOpenCosmetics,
              expanded: false,
            ),
    );
  }

  Widget _bundleEmptyState() {
    return ShopEmptyState(
      key: const Key('shopCustomizationBundleEmptyState'),
      icon: Icons.auto_awesome_rounded,
      title: 'Todav\u00eda no tienes packs',
      message:
          'Los packs que compres aparecer\u00e1n aqu\u00ed y podr\u00e1s equipar todos sus cosm\u00e9ticos a la vez.',
      action: widget.onOpenCosmetics == null
          ? null
          : ShopPrimaryButton(
              key: const Key('shopCustomizationOpenCosmetics'),
              label: 'Ir a Cosm\u00e9ticos',
              icon: Icons.palette_outlined,
              onPressed: widget.onOpenCosmetics,
              expanded: false,
            ),
    );
  }

  List<ShopItem> _itemsForFilter(
    List<ShopItem> ownedCosmeticItems,
    PersonalizationCosmeticFilter filter,
  ) {
    final ShopItemType? type = filter.itemType;
    if (type == null) {
      return const <ShopItem>[];
    }
    return ownedCosmeticItems
        .where((ShopItem item) => item.type == type)
        .toList(growable: false);
  }

  List<ShopBundle> _bundlesForFilter(ShopCosmeticsState state) {
    final Map<String, ShopBundle> resolved = <String, ShopBundle>{};
    for (final ShopBundle bundle in ShopAssetsCatalog.allBundles) {
      final quote = ShopBundleCompletionQuote.tryCreate(
        bundle: bundle,
        state: state,
      );
      if (quote == null) continue;
      if (!quote.isExplicitlyOwned && !quote.isCompleteFromItems) continue;
      resolved[bundle.id] = bundle;
    }

    final List<ShopBundle> sorted = resolved.values.toList(growable: false);
    sorted.sort((ShopBundle a, ShopBundle b) => a.sortOrder.compareTo(b.sortOrder));
    return sorted;
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
      return ownedCosmeticItems
          .firstWhere((ShopItem item) => item.id == equippedId);
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

  Future<void> _hydrateControllerState(
    ShopCosmeticsController controller,
  ) async {
    await controller.getState();
  }

  _CustomizationViewData _buildControllerViewData(
    ShopCosmeticsController controller,
  ) {
    final ShopCosmeticsState state =
        controller.state ?? const ShopCosmeticsState.initial();
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
    final List<ShopBundle> resolvedBundles = ShopAssetsCatalog.allBundles
        .where((ShopBundle bundle) => state.ownedBundleIds.contains(bundle.id))
        .toList(growable: false)
      ..sort((ShopBundle a, ShopBundle b) => a.sortOrder.compareTo(b.sortOrder));

    return _CustomizationViewData(
      walletCoins: controller.visibleWalletCoins,
      equippedCosmetics: EquippedCosmetics(
        backgroundItemId: state.equippedWallpaperId,
        habitCardItemId: state.equippedHabitCardSkinId,
        userCardItemId: state.equippedUserCardSkinId,
      ),
      ownedCosmeticItems: resolvedItems,
      ownedBundles: resolvedBundles,
      cosmeticsState: state,
    );
  }

  ShopCosmeticsState _buildStateFromProps() {
    return ShopCosmeticsState(
      ownedAssetIds: widget.ownedCosmeticItems.map((item) => item.id).toList(),
      ownedBundleIds: widget.ownedBundles.map((bundle) => bundle.id).toList(),
      equippedWallpaperId: widget.equippedCosmetics.backgroundItemId,
      equippedHabitCardSkinId: widget.equippedCosmetics.habitCardItemId,
      equippedUserCardSkinId: widget.equippedCosmetics.userCardItemId,
    );
  }

  Future<void> _handleEquipPressed(String itemId) async {
    if (_busyEquipItemId == itemId) return;
    setState(() {
      _busyEquipItemId = itemId;
    });
    try {
      await widget.onEquipPressed(itemId);
    } finally {
      if (mounted) {
        setState(() {
          if (_busyEquipItemId == itemId) {
            _busyEquipItemId = null;
          }
        });
      } else if (_busyEquipItemId == itemId) {
        _busyEquipItemId = null;
      }
    }
  }

  Future<void> _handleEquipBundlePressed(String bundleId) async {
    if (_busyEquipBundleId == bundleId) return;
    setState(() {
      _busyEquipBundleId = bundleId;
    });
    try {
      await widget.onEquipBundlePressed(bundleId);
    } finally {
      if (mounted) {
        setState(() {
          if (_busyEquipBundleId == bundleId) {
            _busyEquipBundleId = null;
          }
        });
      } else if (_busyEquipBundleId == bundleId) {
        _busyEquipBundleId = null;
      }
    }
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
    super.key,
    required this.title,
    required this.items,
    required this.equippedCosmetics,
    required this.busyEquipItemId,
    required this.onEquipPressed,
    required this.onItemPressed,
  });

  final String title;
  final List<ShopItem> items;
  final EquippedCosmetics equippedCosmetics;
  final String? busyEquipItemId;
  final Future<void> Function(String itemId) onEquipPressed;
  final ValueChanged<String> onItemPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: Key('shopCustomizationSection-$title'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ShopSectionHeader(
          title: title,
          subtitle: items.length == 1 ? '1 objeto' : '${items.length} objetos',
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final int crossAxisCount = constraints.maxWidth >= 560 ? 3 : 2;
            final double mainAxisExtent = crossAxisCount == 3 ? 300 : 272;

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
                return ShopOwnedItemCard(
                  key: Key('shopOwnedItem-${item.id}'),
                  item: item,
                  isEquipped: _isEquipped(item, equippedCosmetics),
                  busy: busyEquipItemId == item.id,
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

class _OwnedBundlesSection extends StatelessWidget {
  const _OwnedBundlesSection({
    super.key,
    required this.bundles,
    required this.equippedCosmetics,
    required this.cosmeticsState,
    required this.busyEquipBundleId,
    required this.onEquipPressed,
  });

  final List<ShopBundle> bundles;
  final EquippedCosmetics equippedCosmetics;
  final ShopCosmeticsState cosmeticsState;
  final String? busyEquipBundleId;
  final Future<void> Function(String bundleId) onEquipPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ShopSectionHeader(
          title: 'Packs',
          subtitle: bundles.length == 1
              ? '1 pack comprado'
              : '${bundles.length} packs comprados',
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final int crossAxisCount = constraints.maxWidth >= 560 ? 3 : 2;
            final double mainAxisExtent = crossAxisCount == 3 ? 332 : 312;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bundles.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                mainAxisExtent: mainAxisExtent,
              ),
              itemBuilder: (BuildContext context, int index) {
                final ShopBundle bundle = bundles[index];
                final quote = ShopBundleCompletionQuote.tryCreate(
                  bundle: bundle,
                  state: cosmeticsState,
                );
                return ShopOwnedBundleCard(
                  key: Key('shopOwnedBundle-${bundle.id}'),
                  bundle: bundle,
                  bundleAssets: _bundleAssetsFor(bundle),
                  completionQuote: quote,
                  isEquipped: _isBundleEquipped(bundle, equippedCosmetics),
                  busy: busyEquipBundleId == bundle.id,
                  onEquipPressed: onEquipPressed,
                );
              },
            );
          },
        ),
      ],
    );
  }

  List<ShopAsset> _bundleAssetsFor(ShopBundle bundle) {
    return <String>[
      bundle.wallpaperItemId,
      bundle.habitCardItemId,
      bundle.userCardItemId,
    ]
        .map(ShopAssetsCatalog.getAssetById)
        .whereType<ShopAsset>()
        .toList(growable: false);
  }

  bool _isBundleEquipped(
    ShopBundle bundle,
    EquippedCosmetics equippedCosmetics,
  ) {
    return equippedCosmetics.backgroundItemId == bundle.wallpaperItemId &&
        equippedCosmetics.habitCardItemId == bundle.habitCardItemId &&
        equippedCosmetics.userCardItemId == bundle.userCardItemId;
  }
}

class _PersonalizationCosmeticFilterChips extends StatelessWidget {
  const _PersonalizationCosmeticFilterChips({
    required this.selectedFilter,
    required this.onChanged,
  });

  final PersonalizationCosmeticFilter selectedFilter;
  final ValueChanged<PersonalizationCosmeticFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: <Widget>[
          _buildChip(PersonalizationCosmeticFilter.packs),
          const SizedBox(width: 10),
          _buildChip(PersonalizationCosmeticFilter.backgrounds),
          const SizedBox(width: 10),
          _buildChip(PersonalizationCosmeticFilter.habitCards),
          const SizedBox(width: 10),
          _buildChip(PersonalizationCosmeticFilter.userCards),
        ],
      ),
    );
  }

  Widget _buildChip(PersonalizationCosmeticFilter filter) {
    return ShopFilterChip(
      key: Key('shopCustomizationFilter-${filter.name}'),
      label: filter.label,
      selected: selectedFilter == filter,
      onTap: () => onChanged(filter),
    );
  }
}

class _CustomizationViewData {
  const _CustomizationViewData({
    required this.walletCoins,
    required this.equippedCosmetics,
    required this.ownedCosmeticItems,
    required this.ownedBundles,
    required this.cosmeticsState,
  });

  final int walletCoins;
  final EquippedCosmetics equippedCosmetics;
  final List<ShopItem> ownedCosmeticItems;
  final List<ShopBundle> ownedBundles;
  final ShopCosmeticsState cosmeticsState;
}
