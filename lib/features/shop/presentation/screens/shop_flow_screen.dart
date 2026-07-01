import 'package:flutter/material.dart';
import 'package:rutio/features/shop/application/shop_controller.dart';
import 'package:rutio/features/shop/data/shop_catalog.dart';
import 'package:rutio/features/shop/data/shop_local_repository.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/presentation/models/shop_flow_snapshot.dart';
import 'package:rutio/features/shop/presentation/screens/shop_backpack_screen.dart';
import 'package:rutio/features/shop/presentation/screens/shop_collections_screen.dart';
import 'package:rutio/features/shop/presentation/screens/shop_cosmetics_screen.dart';
import 'package:rutio/features/shop/presentation/screens/shop_customization_screen.dart';
import 'package:rutio/features/shop/presentation/screens/shop_home_screen.dart';
import 'package:rutio/features/shop/presentation/screens/shop_item_detail_container.dart';
import 'package:rutio/features/shop/presentation/screens/shop_utilities_screen.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_empty_state.dart';

enum _ShopFlowPage {
  home,
  cosmetics,
  utilities,
  collections,
  backpack,
  customization,
  detail,
}

class ShopFlowScreen extends StatefulWidget {
  const ShopFlowScreen({
    super.key,
    required this.controller,
    this.shopRepository,
  });

  final ShopController controller;
  final ShopLocalRepository? shopRepository;

  @override
  State<ShopFlowScreen> createState() => _ShopFlowScreenState();
}

class _ShopFlowScreenState extends State<ShopFlowScreen> {
  final List<_ShopFlowPage> _stack = <_ShopFlowPage>[_ShopFlowPage.home];
  late final ShopLocalRepository _shopRepository;

  ShopFlowSnapshot? _snapshot;
  String? _selectedItemId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _shopRepository = widget.shopRepository ?? ShopLocalRepository();
    _reloadSnapshot();
  }

  Future<void> _reloadSnapshot() async {
    setState(() {
      _loading = true;
    });

    final snapshot = await _loadSnapshot();
    if (!mounted) return;

    setState(() {
      _snapshot = snapshot;
      _loading = false;
    });
  }

  Future<ShopFlowSnapshot> _loadSnapshot() async {
    final int walletCoins = widget.controller.getWalletCoins();
    final shopState = await _shopRepository.load();
    return ShopFlowSnapshot.fromStore(
      walletCoins: walletCoins,
      shopState: shopState,
    );
  }

  void _pushPage(_ShopFlowPage page) {
    setState(() {
      _stack.add(page);
    });
  }

  void _replaceTopPage(_ShopFlowPage page) {
    setState(() {
      if (_stack.isNotEmpty) {
        _stack.removeLast();
      }
      _stack.add(page);
    });
  }

  void _popPage() {
    if (_stack.length <= 1) {
      Navigator.of(context).maybePop();
      return;
    }

    setState(() {
      _stack.removeLast();
      if (_stack.last != _ShopFlowPage.detail) {
        _selectedItemId = null;
      }
    });
  }

  void _openCosmetics() => _pushPage(_ShopFlowPage.cosmetics);
  void _openUtilities() => _pushPage(_ShopFlowPage.utilities);
  void _openCollections() => _pushPage(_ShopFlowPage.collections);
  void _openBackpack() => _pushPage(_ShopFlowPage.backpack);
  void _openCustomization() => _pushPage(_ShopFlowPage.customization);

  void _openDetail(String itemId) {
    setState(() {
      _selectedItemId = itemId;
      _stack.add(_ShopFlowPage.detail);
    });
  }

  void _openCollection(String collectionId) {
    _showSnack('Coleccion $collectionId disponible pronto');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.fixed,
        backgroundColor: ShopUiTokens.textPrimary,
      ),
    );
  }

  Future<void> _handleUsePressed(String itemId) async {
    _showSnack('Disponible proximamente');
  }

  Future<void> _handleEquipPressed(String itemId) async {
    final result = await widget.controller.equipItem(itemId);
    if (!mounted) return;

    await _reloadSnapshot();
    _showSnack(_equipMessage(result));
  }

  Future<void> _handlePurchaseCompleted(ShopControllerResult result) async {
    if (!mounted) return;

    await _reloadSnapshot();
    final ShopItem? item = result.item;
    if (item != null &&
        result.isSuccess &&
        item.category == ShopItemCategory.utility) {
      _replaceTopPage(_ShopFlowPage.backpack);
    }
  }

  Future<void> _handleEquipCompleted(ShopControllerResult result) async {
    if (!mounted) return;
    await _reloadSnapshot();
  }

  String _equipMessage(ShopControllerResult result) {
    if (result.status == ShopControllerStatus.success) {
      return 'Cosmetico equipado';
    }
    return 'No se ha podido equipar el item';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _snapshot == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final snapshot = _snapshot!;

    return PopScope(
      canPop: _stack.length <= 1,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop && _stack.length > 1) {
          _popPage();
        }
      },
      child: _buildCurrentPage(snapshot),
    );
  }

  Widget _buildCurrentPage(ShopFlowSnapshot snapshot) {
    final _ShopFlowPage page = _stack.last;

    switch (page) {
      case _ShopFlowPage.home:
        return ShopHomeScreen(
          walletCoins: snapshot.walletCoins,
          onOpenCosmetics: _openCosmetics,
          onOpenUtilities: _openUtilities,
          onOpenCollections: _openCollections,
          onOpenBackpack: _openBackpack,
          onOpenCustomization: _openCustomization,
          onBackPressed: Navigator.of(context).canPop() ? _popPage : null,
        );
      case _ShopFlowPage.cosmetics:
        return ShopCosmeticsScreen(
          walletCoins: snapshot.walletCoins,
          items: snapshot.cosmeticCatalogItems,
          ownedItemIds: snapshot.ownedItemIds,
          equippedCosmetics: snapshot.equippedCosmetics,
          onBackPressed: _popPage,
          onItemPressed: _openDetail,
        );
      case _ShopFlowPage.utilities:
        return ShopUtilitiesScreen(
          walletCoins: snapshot.walletCoins,
          items: snapshot.utilityCatalogItems,
          onBackPressed: _popPage,
          onItemPressed: _openDetail,
        );
      case _ShopFlowPage.collections:
        return ShopCollectionsScreen(
          walletCoins: snapshot.walletCoins,
          collections: snapshot.collections,
          ownedItemIds: snapshot.ownedItemIds,
          onBackPressed: _popPage,
          onCollectionPressed: _openCollection,
        );
      case _ShopFlowPage.backpack:
        return ShopBackpackScreen(
          walletCoins: snapshot.walletCoins,
          items: snapshot.backpackViewModels,
          onBackPressed: _popPage,
          onItemPressed: _openDetail,
          onUsePressed: _handleUsePressed,
          onOpenUtilities: _openUtilities,
        );
      case _ShopFlowPage.customization:
        return ShopCustomizationScreen(
          walletCoins: snapshot.walletCoins,
          equippedCosmetics: snapshot.equippedCosmetics,
          ownedCosmeticItems: snapshot.ownedCosmeticItems,
          onBackPressed: _popPage,
          onEquipPressed: _handleEquipPressed,
          onItemPressed: _openDetail,
          onOpenCosmetics: _openCosmetics,
        );
      case _ShopFlowPage.detail:
        final String? itemId = _selectedItemId;
        if (itemId == null) {
          return const Scaffold(
            body: Center(
              child: ShopEmptyState(
                title: 'Detalle no disponible',
                message: 'No pudimos abrir este item.',
              ),
            ),
          );
        }

        final ShopItem? item = ShopCatalog.getItemById(itemId);
        if (item == null) {
          return const Scaffold(
            body: Center(
              child: ShopEmptyState(
                title: 'Detalle no disponible',
                message: 'No pudimos abrir este item.',
              ),
            ),
          );
        }

        final String? collectionName = item.collectionId == null
            ? null
            : snapshot.collectionById(item.collectionId!)?.title;

        return ShopItemDetailContainer.withController(
          itemId: itemId,
          onBackPressed: _popPage,
          controller: widget.controller,
          collectionName: collectionName,
          onPurchaseCompleted: _handlePurchaseCompleted,
          onEquipCompleted: _handleEquipCompleted,
        );
    }
  }
}
