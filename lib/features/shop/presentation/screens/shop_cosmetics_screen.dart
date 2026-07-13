import 'package:flutter/material.dart';
import 'package:rutio/features/shop/application/shop_cosmetics_controller.dart';
import 'package:rutio/features/shop/data/shop_assets_catalog.dart';
import 'package:rutio/features/shop/domain/models/shop_asset.dart';
import 'package:rutio/features/shop/domain/models/shop_asset_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_bundle.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_operation_result.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_state.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_cosmetics_detail_sheet.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_cosmetics_purchase_confirmation_sheet.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_cosmetics_product_card.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_empty_state.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_filter_chip.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_header.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_page_shell.dart';

enum ShopCosmeticsFilter {
  all,
  wallpapers,
  cards,
  packs,
}

class ShopCosmeticsScreen extends StatefulWidget {
  const ShopCosmeticsScreen({
    super.key,
    required this.controller,
    this.onBackPressed,
    this.onMenuPressed,
  });

  final ShopCosmeticsController controller;
  final VoidCallback? onBackPressed;
  final VoidCallback? onMenuPressed;

  @override
  State<ShopCosmeticsScreen> createState() => _ShopCosmeticsScreenState();
}

class _ShopCosmeticsScreenState extends State<ShopCosmeticsScreen> {
  ShopCosmeticsFilter _selectedFilter = ShopCosmeticsFilter.all;
  ShopCosmeticsState? _state;
  int _walletCoins = 0;
  bool _loading = true;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
    });

    final state = await widget.controller.getState();
    final walletCoins = await widget.controller.getWalletCoins();
    if (!mounted) return;

    setState(() {
      _state = state;
      _walletCoins = walletCoins;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ShopPageShell(
      header: ShopHeader(
        title: 'Cosméticos',
        titleStyle: ShopUiTextStyles.sectionTitle.copyWith(
          fontSize: 25,
          height: 1.04,
        ),
        leadingIcon: widget.onBackPressed != null
            ? Icons.arrow_back_ios_new_rounded
            : Icons.menu_rounded,
        onLeadingPressed: widget.onBackPressed ?? widget.onMenuPressed,
        walletCoins: _walletCoins,
        useDrawerLeadingStyle: widget.onBackPressed == null,
      ),
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final state = _state;
    if (state == null) {
      return const ShopEmptyState(
        title: 'Cosméticos no disponibles',
        message: 'No hemos podido cargar la tienda de cosméticos ahora mismo.',
      );
    }

    final entries = _visibleEntries(state);
    if (entries.isEmpty) {
      return const ShopEmptyState(
        title: 'Nada por mostrar',
        message: 'No encontramos cosméticos en esta secci?n.',
      );
    }

    return Column(
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
        const SizedBox(height: 18),
        Text(
          '${entries.length} resultados',
          style: ShopUiTextStyles.bodySmall,
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final int crossAxisCount = constraints.maxWidth >= 560 ? 3 : 2;
            final double mainAxisExtent = crossAxisCount == 3 ? 276 : 292;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                mainAxisExtent: mainAxisExtent,
              ),
              itemBuilder: (BuildContext context, int index) {
                final entry = entries[index];
                return switch (entry) {
                  _AssetEntry(:final asset, :final ownershipState) =>
                    ShopCosmeticsProductCard.asset(
                      asset: asset,
                      ownershipState: ownershipState,
                      hasEnoughCoins: _walletCoins >= asset.priceAmber,
                      busy: _busyId == asset.id,
                      onPressed: () => _openAssetDetail(asset, ownershipState),
                      onPrimaryActionPressed: () =>
                          _onAssetPrimaryActionPressed(
                        asset,
                        ownershipState,
                      ),
                    ),
                  _BundleEntry(
                    :final bundle,
                    :final assets,
                    :final isOwned,
                    :final isPartiallyOwned,
                  ) =>
                    ShopCosmeticsProductCard.bundle(
                      bundle: bundle,
                      bundleAssets: assets,
                      isBundleOwned: isOwned,
                      isBundlePartiallyOwned: isPartiallyOwned,
                      hasEnoughCoins: _walletCoins >= bundle.priceAmber,
                      busy: _busyId == bundle.id,
                      onPressed: () => _openBundleDetail(
                        bundle,
                        assets,
                        isOwned,
                        isPartiallyOwned,
                      ),
                      onPrimaryActionPressed: () =>
                          _onBundlePrimaryActionPressed(bundle, assets),
                    ),
                };
              },
            );
          },
        ),
      ],
    );
  }

  List<_ShopEntry> _visibleEntries(ShopCosmeticsState state) {
    final allEntries = <_ShopEntry>[
      ...ShopAssetsCatalog.allAssets.map(
        (ShopAsset asset) => _AssetEntry(
          asset: asset,
          ownershipState: state.assetOwnershipState(
            asset,
            bundles: ShopAssetsCatalog.allBundles,
          ),
        ),
      ),
      ...ShopAssetsCatalog.allBundles.map(
        (ShopBundle bundle) => _BundleEntry(
          bundle: bundle,
          assets: bundle.assetIds
              .map(ShopAssetsCatalog.getAssetById)
              .whereType<ShopAsset>()
              .toList(growable: false),
          isOwned: state.isBundleOwned(bundle.id),
          isPartiallyOwned: _bundleContainsOwnedAssets(state, bundle),
        ),
      ),
    ]..sort(_compareEntries);

    switch (_selectedFilter) {
      case ShopCosmeticsFilter.all:
        return allEntries;
      case ShopCosmeticsFilter.wallpapers:
        return allEntries.whereType<_AssetEntry>().where((entry) {
          return entry.asset.category == ShopAssetCategory.wallpaper;
        }).toList(growable: false);
      case ShopCosmeticsFilter.cards:
        return allEntries.whereType<_AssetEntry>().where((entry) {
          return entry.asset.category == ShopAssetCategory.habitCard ||
              entry.asset.category == ShopAssetCategory.userCard;
        }).toList(growable: false);
      case ShopCosmeticsFilter.packs:
        return allEntries.whereType<_BundleEntry>().toList(growable: false);
    }
  }

  int _compareEntries(_ShopEntry a, _ShopEntry b) {
    final ownershipCompare = a.ownershipRank.compareTo(b.ownershipRank);
    if (ownershipCompare != 0) return ownershipCompare;

    final rarityCompare =
        _rarityOrder(a.rarity).compareTo(_rarityOrder(b.rarity));
    if (rarityCompare != 0) return rarityCompare;

    final categoryCompare = _categoryOrder(a.categoryOrder)
        .compareTo(_categoryOrder(b.categoryOrder));
    if (categoryCompare != 0) return categoryCompare;

    return a.sortOrder.compareTo(b.sortOrder);
  }

  int _rarityOrder(ShopAssetRarity rarity) {
    switch (rarity) {
      case ShopAssetRarity.common:
        return 0;
      case ShopAssetRarity.rare:
        return 1;
      case ShopAssetRarity.epic:
        return 2;
      case ShopAssetRarity.legendary:
        return 3;
    }
  }

  int _categoryOrder(_EntryCategory category) {
    switch (category) {
      case _EntryCategory.wallpaper:
        return 0;
      case _EntryCategory.habitCard:
        return 1;
      case _EntryCategory.userCard:
        return 2;
      case _EntryCategory.bundle:
        return 3;
    }
  }

  Future<void> _handleAssetPrimaryAction(
    ShopAsset asset,
    ShopAssetOwnershipState ownershipState,
  ) async {
    if (_busyId != null) return;

    setState(() {
      _busyId = asset.id;
    });

    final result = switch (ownershipState) {
      ShopAssetOwnershipState.locked =>
        await widget.controller.purchaseAsset(asset.id),
      ShopAssetOwnershipState.owned ||
      ShopAssetOwnershipState.equipped ||
      ShopAssetOwnershipState.includedInOwnedBundle =>
        await widget.controller.equipAsset(asset.id),
    };

    await _reload();
    if (!mounted) return;

    setState(() {
      _busyId = null;
    });

    _showFeedback(_assetFeedback(result, ownershipState));
  }

  Future<void> _onAssetPrimaryActionPressed(
    ShopAsset asset,
    ShopAssetOwnershipState ownershipState,
  ) async {
    if (ownershipState == ShopAssetOwnershipState.locked) {
      await _confirmAssetPurchase(asset);
      return;
    }
    await _handleAssetPrimaryAction(asset, ownershipState);
  }

  Future<void> _handleBundlePurchase(ShopBundle bundle) async {
    if (_busyId != null) return;

    setState(() {
      _busyId = bundle.id;
    });

    final result = await widget.controller.purchaseBundle(bundle.id);
    await _reload();
    if (!mounted) return;

    setState(() {
      _busyId = null;
    });

    _showFeedback(_bundleFeedback(result));
  }

  Future<void> _onBundlePrimaryActionPressed(
    ShopBundle bundle,
    List<ShopAsset> assets,
  ) async {
    await _confirmBundlePurchase(bundle, assets);
  }

  void _openAssetDetail(
    ShopAsset asset,
    ShopAssetOwnershipState ownershipState,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ShopCosmeticsDetailSheet.asset(
          asset: asset,
          ownershipState: ownershipState,
          walletCoins: _walletCoins,
          busy: _busyId == asset.id,
          onPrimaryActionPressed: () async {
            Navigator.of(context).pop();
            if (ownershipState == ShopAssetOwnershipState.locked) {
              await _confirmAssetPurchase(asset);
              return;
            }
            await _handleAssetPrimaryAction(asset, ownershipState);
          },
        );
      },
    );
  }

  void _openBundleDetail(
    ShopBundle bundle,
    List<ShopAsset> assets,
    bool isOwned,
    bool isPartiallyOwned,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ShopCosmeticsDetailSheet.bundle(
          bundle: bundle,
          bundleAssets: assets,
          isBundleOwned: isOwned,
          isBundlePartiallyOwned: isPartiallyOwned,
          walletCoins: _walletCoins,
          busy: _busyId == bundle.id,
          onPrimaryActionPressed: () async {
            Navigator.of(context).pop();
            await _confirmBundlePurchase(bundle, assets);
          },
        );
      },
    );
  }

  Future<void> _confirmAssetPurchase(ShopAsset asset) async {
    if (_busyId != null) return;

    final bool? shouldConfirm = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ShopCosmeticsPurchaseConfirmationSheet.asset(
          asset: asset,
          walletCoins: _walletCoins,
          onCancel: () => Navigator.of(context).pop(false),
          onConfirm: () => Navigator.of(context).pop(true),
        );
      },
    );

    if (shouldConfirm != true || !mounted) return;
    await _handleAssetPrimaryAction(asset, ShopAssetOwnershipState.locked);
  }

  Future<void> _confirmBundlePurchase(
    ShopBundle bundle,
    List<ShopAsset> assets,
  ) async {
    if (_busyId != null) return;

    final bool? shouldConfirm = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ShopCosmeticsPurchaseConfirmationSheet.bundle(
          bundle: bundle,
          bundleAssets: assets,
          walletCoins: _walletCoins,
          onCancel: () => Navigator.of(context).pop(false),
          onConfirm: () => Navigator.of(context).pop(true),
        );
      },
    );

    if (shouldConfirm != true || !mounted) return;
    await _handleBundlePurchase(bundle);
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: ShopUiTokens.textPrimary,
      ),
    );
  }

  bool _bundleContainsOwnedAssets(
    ShopCosmeticsState state,
    ShopBundle bundle,
  ) {
    if (state.isBundleOwned(bundle.id)) return false;
    for (final assetId in bundle.assetIds) {
      if (state.isAssetOwned(assetId, bundles: ShopAssetsCatalog.allBundles)) {
        return true;
      }
    }
    return false;
  }

  String _assetFeedback(
    ShopCosmeticsOperationResult result,
    ShopAssetOwnershipState previousState,
  ) {
    switch (result.status) {
      case ShopCosmeticsOperationStatus.success:
        return previousState == ShopAssetOwnershipState.locked
            ? 'Cosmetico comprado'
            : 'Cosmetico equipado';
      case ShopCosmeticsOperationStatus.insufficientCoins:
        return 'No tienes ambar suficiente';
      case ShopCosmeticsOperationStatus.alreadyOwned:
        return 'Ya lo tienes en tu coleccion';
      case ShopCosmeticsOperationStatus.assetNotOwned:
        return 'Necesitas comprarlo antes de equiparlo';
      case ShopCosmeticsOperationStatus.assetNotFound:
      case ShopCosmeticsOperationStatus.bundleNotFound:
      case ShopCosmeticsOperationStatus.bundleContainsOwnedAssets:
        return 'No hemos encontrado este cosmetico';
    }
  }

  String _bundleFeedback(ShopCosmeticsOperationResult result) {
    switch (result.status) {
      case ShopCosmeticsOperationStatus.success:
        return 'Pack comprado';
      case ShopCosmeticsOperationStatus.insufficientCoins:
        return 'No tienes ambar suficiente';
      case ShopCosmeticsOperationStatus.alreadyOwned:
        return 'Ese pack ya esta comprado';
      case ShopCosmeticsOperationStatus.bundleContainsOwnedAssets:
        return 'Ya tienes parte de este pack';
      case ShopCosmeticsOperationStatus.assetNotFound:
      case ShopCosmeticsOperationStatus.bundleNotFound:
        return 'No hemos encontrado este pack';
      case ShopCosmeticsOperationStatus.assetNotOwned:
        return 'Operacion no disponible';
    }
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
          _buildChip(
            key: 'shopCosmeticsFilter-all',
            label: 'Todo',
            filter: ShopCosmeticsFilter.all,
          ),
          const SizedBox(width: 10),
          _buildChip(
            key: 'shopCosmeticsFilter-wallpapers',
            label: 'Fondos',
            filter: ShopCosmeticsFilter.wallpapers,
          ),
          const SizedBox(width: 10),
          _buildChip(
            key: 'shopCosmeticsFilter-cards',
            label: 'Tarjetas',
            filter: ShopCosmeticsFilter.cards,
          ),
          const SizedBox(width: 10),
          _buildChip(
            key: 'shopCosmeticsFilter-packs',
            label: 'Packs',
            filter: ShopCosmeticsFilter.packs,
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String key,
    required String label,
    required ShopCosmeticsFilter filter,
  }) {
    return ShopFilterChip(
      key: Key(key),
      label: label,
      selected: selectedFilter == filter,
      onTap: () => onFilterSelected(filter),
    );
  }
}

sealed class _ShopEntry {
  const _ShopEntry();

  ShopAssetRarity get rarity;
  int get sortOrder;
  _EntryCategory get categoryOrder;
  int get ownershipRank;
}

class _AssetEntry extends _ShopEntry {
  const _AssetEntry({
    required this.asset,
    required this.ownershipState,
  });

  final ShopAsset asset;
  final ShopAssetOwnershipState ownershipState;

  @override
  ShopAssetRarity get rarity => asset.rarity;

  @override
  int get sortOrder => asset.sortOrder;

  @override
  _EntryCategory get categoryOrder {
    switch (asset.category) {
      case ShopAssetCategory.wallpaper:
        return _EntryCategory.wallpaper;
      case ShopAssetCategory.habitCard:
        return _EntryCategory.habitCard;
      case ShopAssetCategory.userCard:
        return _EntryCategory.userCard;
    }
  }

  @override
  int get ownershipRank {
    switch (ownershipState) {
      case ShopAssetOwnershipState.locked:
        return 0;
      case ShopAssetOwnershipState.owned:
      case ShopAssetOwnershipState.includedInOwnedBundle:
      case ShopAssetOwnershipState.equipped:
        return 1;
    }
  }
}

class _BundleEntry extends _ShopEntry {
  const _BundleEntry({
    required this.bundle,
    required this.assets,
    required this.isOwned,
    required this.isPartiallyOwned,
  });

  final ShopBundle bundle;
  final List<ShopAsset> assets;
  final bool isOwned;
  final bool isPartiallyOwned;

  @override
  ShopAssetRarity get rarity => bundle.rarity;

  @override
  int get sortOrder => bundle.sortOrder;

  @override
  _EntryCategory get categoryOrder => _EntryCategory.bundle;

  @override
  int get ownershipRank => (isOwned || isPartiallyOwned) ? 1 : 0;
}

enum _EntryCategory {
  wallpaper,
  habitCard,
  userCard,
  bundle,
}
