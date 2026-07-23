import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rutio/features/shop/application/shop_cosmetics_controller.dart';
import 'package:rutio/features/shop/data/shop_assets_catalog.dart';
import 'package:rutio/features/shop/domain/models/shop_asset.dart';
import 'package:rutio/features/shop/domain/models/shop_asset_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_bundle.dart';
import 'package:rutio/features/shop/domain/models/shop_bundle_completion_quote.dart';
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
  int _walletCoinsRefreshVersion = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
    _syncStateFromController();
    unawaited(_refreshState());
  }

  @override
  void didUpdateWidget(covariant ShopCosmeticsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }
    oldWidget.controller.removeListener(_handleControllerChanged);
    widget.controller.addListener(_handleControllerChanged);
    _syncStateFromController();
    unawaited(_refreshState());
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    if (!mounted) return;
    setState(_syncStateFromController);
  }

  void _syncStateFromController() {
    _walletCoinsRefreshVersion += 1;
    _state = widget.controller.state;
    _walletCoins = widget.controller.visibleWalletCoins;
    _loading = _state == null;
  }

  Future<void> _refreshState() {
    final hadCachedState = _state != null;
    if (!hadCachedState) {
      setState(() {
        _loading = true;
      });
    }

    final stateFuture = widget.controller.getState();
    final walletCoinsFuture = widget.controller.getWalletCoins();
    final walletCoinsVersion = _walletCoinsRefreshVersion;

    stateFuture.then((ShopCosmeticsState nextState) {
      if (!mounted) return;
      setState(() {
        _state = nextState;
        _loading = false;
      });
    }).catchError((_) {
      if (!mounted || hadCachedState) return;
      setState(() {
        _loading = false;
      });
    });

    walletCoinsFuture.then((int nextWalletCoins) {
      if (!mounted || walletCoinsVersion != _walletCoinsRefreshVersion) return;
      setState(() {
        _walletCoins = nextWalletCoins;
      });
    }).catchError((_) {});

    return Future<void>.value();
  }

  @override
  Widget build(BuildContext context) {
    return ShopPageShell(
      scrollable: false,
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
      child: Expanded(child: _buildBody()),
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
        message: 'No encontramos cosméticos en esta sección.',
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
        Expanded(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final int crossAxisCount = constraints.maxWidth >= 560 ? 3 : 2;
              final double mainAxisExtent = crossAxisCount == 3 ? 276 : 292;

              return GridView.builder(
                key: const Key('shopCosmeticsGrid'),
                padding: EdgeInsets.zero,
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
                        onPressed: () =>
                            _openAssetDetail(asset, ownershipState),
                        onPrimaryActionPressed: () =>
                            _onAssetPrimaryActionPressed(
                          asset,
                          ownershipState,
                        ),
                      ),
                    _BundleEntry(
                      :final bundle,
                      :final assets,
                      :final quote,
                    ) =>
                      ShopCosmeticsProductCard.bundle(
                        bundle: bundle,
                        bundleAssets: assets,
                        completionQuote: quote,
                        hasEnoughCoins:
                            _walletCoins >= quote.effectivePriceAmber,
                        busy: _busyId == bundle.id,
                        onPressed: () => _openBundleDetail(
                          bundle,
                          assets,
                          quote,
                        ),
                        onPrimaryActionPressed: () =>
                            _onBundlePrimaryActionPressed(bundle, quote, assets),
                      ),
                  };
                },
              );
            },
          ),
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
    ];

    for (final bundle in ShopAssetsCatalog.allBundles) {
      final quote = ShopBundleCompletionQuote.tryCreate(
        bundle: bundle,
        state: state,
      );
      if (quote == null) {
        continue;
      }
      allEntries.add(
        _BundleEntry(
          bundle: bundle,
          assets: bundle.assetIds
              .map(ShopAssetsCatalog.getAssetById)
              .whereType<ShopAsset>()
              .toList(growable: false),
          quote: quote,
        ),
      );
    }

    allEntries.sort(_compareEntries);

    return switch (_selectedFilter) {
      ShopCosmeticsFilter.all => allEntries,
      ShopCosmeticsFilter.wallpapers =>
        allEntries.whereType<_AssetEntry>().where((entry) {
          return entry.asset.category == ShopAssetCategory.wallpaper;
        }).toList(growable: false),
      ShopCosmeticsFilter.cards =>
        allEntries.whereType<_AssetEntry>().where((entry) {
          return entry.asset.category == ShopAssetCategory.habitCard ||
              entry.asset.category == ShopAssetCategory.userCard;
        }).toList(growable: false),
      ShopCosmeticsFilter.packs =>
        allEntries.whereType<_BundleEntry>().toList(growable: false),
    };
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

    await _refreshState();
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
    await _refreshState();
    if (!mounted) return;

    setState(() {
      _busyId = null;
    });

    _showFeedback(_bundleFeedback(result));
  }

  Future<void> _onBundlePrimaryActionPressed(
    ShopBundle bundle,
    ShopBundleCompletionQuote quote,
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
    ShopBundleCompletionQuote quote,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ShopCosmeticsDetailSheet.bundle(
          bundle: bundle,
          bundleAssets: assets,
          completionQuote: quote,
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
          completionQuote: _bundleCompletionQuote(bundle),
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

  ShopBundleCompletionQuote? _bundleCompletionQuote(ShopBundle bundle) {
    final state = _state;
    if (state == null) return null;
    return ShopBundleCompletionQuote.tryCreate(bundle: bundle, state: state);
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
        return 'Completar pack';
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
    required this.quote,
  });

  final ShopBundle bundle;
  final List<ShopAsset> assets;
  final ShopBundleCompletionQuote quote;

  @override
  ShopAssetRarity get rarity => bundle.rarity;

  @override
  int get sortOrder => bundle.sortOrder;

  @override
  _EntryCategory get categoryOrder => _EntryCategory.bundle;

  @override
  int get ownershipRank {
    if (quote.isExplicitlyOwned || quote.isCompleteFromItems) return 0;
    if (quote.isPartiallyOwned) return 1;
    return 2;
  }
}

enum _EntryCategory {
  wallpaper,
  habitCard,
  userCard,
  bundle,
}
