import 'package:flutter/material.dart';
import 'package:rutio/features/shop/application/shop_cosmetics_controller.dart';
import 'package:rutio/features/shop/data/shop_assets_catalog.dart';
import 'package:rutio/features/shop/data/shop_catalog.dart';
import 'package:rutio/features/shop/domain/models/shop_asset.dart';
import 'package:rutio/features/shop/domain/models/shop_asset_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_state.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/presentation/screens/shop_cosmetic_detail_screen.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_empty_state.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_header.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_page_shell.dart';

class ShopCosmeticDetailContainer extends StatefulWidget {
  const ShopCosmeticDetailContainer({
    super.key,
    required this.itemId,
    required this.controller,
    required this.onBackPressed,
    this.collectionName,
    this.onEquipCompleted,
  });

  final String itemId;
  final ShopCosmeticsController controller;
  final VoidCallback onBackPressed;
  final String? collectionName;
  final ValueChanged<String>? onEquipCompleted;

  @override
  State<ShopCosmeticDetailContainer> createState() =>
      _ShopCosmeticDetailContainerState();
}

class _ShopCosmeticDetailContainerState
    extends State<ShopCosmeticDetailContainer> {
  Future<_CosmeticDetailData>? _future;
  ShopCosmeticsController? _cachedController;

  @override
  void initState() {
    super.initState();
    _syncFuture();
  }

  @override
  void didUpdateWidget(covariant ShopCosmeticDetailContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller) ||
        oldWidget.itemId != widget.itemId) {
      _syncFuture();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_CosmeticDetailData>(
      future: _future,
      builder: (BuildContext context,
          AsyncSnapshot<_CosmeticDetailData> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return ShopPageShell(
            header: ShopHeader(
              title: 'Detalle',
              subtitle: 'Cosmético',
              leadingIcon: Icons.arrow_back_ios_new_rounded,
              onLeadingPressed: widget.onBackPressed,
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data;
        if (data == null || data.item == null || data.isOwned == false) {
          return _fallback();
        }

        return ShopCosmeticDetailScreen(
          item: data.item!,
          isEquipped: data.isEquipped,
          collectionName: widget.collectionName ?? data.collectionName,
          onBackPressed: widget.onBackPressed,
          onEquipPressed: _handleEquipPressed,
        );
      },
    );
  }

  void _syncFuture() {
    if (identical(_cachedController, widget.controller) && _future != null) {
      return;
    }

    _cachedController = widget.controller;
    _future = _load();
  }

  Widget _fallback() {
    return ShopPageShell(
      header: ShopHeader(
        title: 'Detalle',
        subtitle: 'Cosmético',
        leadingIcon: Icons.arrow_back_ios_new_rounded,
        onLeadingPressed: widget.onBackPressed,
      ),
      child: const ShopEmptyState(
        title: 'No hemos podido cargar este cosmético.',
        message: 'Vuelve atrás e inténtalo de nuevo.',
      ),
    );
  }

  Future<void> _handleEquipPressed(String itemId) async {
    await widget.controller.equipAsset(itemId);
    if (!mounted) return;

    widget.onEquipCompleted?.call(itemId);
    setState(() {
      _future = _load();
    });
  }

  Future<_CosmeticDetailData> _load() async {
    final ShopCosmeticsState state = await widget.controller.getState();
    final ShopItem? item = ShopCatalog.getItemById(widget.itemId) ??
        _resolveAssetItem(widget.itemId);

    if (item == null) {
      return const _CosmeticDetailData.nullData();
    }

    final bool isOwned = state.isAssetOwned(
      item.id,
      bundles: ShopAssetsCatalog.allBundles,
    );
    final bool isEquipped = switch (item.cosmeticSlot) {
      CosmeticSlot.background => state.equippedWallpaperId == item.id,
      CosmeticSlot.habitCard => state.equippedHabitCardSkinId == item.id,
      CosmeticSlot.userCard => state.equippedUserCardSkinId == item.id,
      null => false,
    };

    final String? collectionName = item.collectionId == null
        ? null
        : ShopCatalog.allCollections
            .where((collection) => collection.id == item.collectionId)
            .map((collection) => collection.title)
            .cast<String?>()
            .firstOrNull;

    return _CosmeticDetailData(
      item: item,
      isOwned: isOwned,
      isEquipped: isEquipped,
      collectionName: collectionName,
    );
  }

  ShopItem? _resolveAssetItem(String itemId) {
    final ShopAsset? asset = ShopAssetsCatalog.getAssetById(itemId);
    if (asset == null) {
      return null;
    }

    final existing = ShopCatalog.getItemById(itemId);
    if (existing != null) {
      return existing;
    }

    return ShopItem(
      id: asset.id,
      title: asset.nameEn,
      description: asset.nameEs,
      category: ShopItemCategory.cosmetic,
      type: _mapType(asset.category),
      rarity: _mapRarity(asset.rarity),
      collectionId: null,
      priceCoins: asset.priceAmber,
      assetRef: asset.assetPath,
      metadata: <String, dynamic>{'familyId': asset.familyId},
    );
  }

  ShopItemType _mapType(ShopAssetCategory category) {
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

extension<T> on Iterable<T> {
  T? get firstOrNull {
    for (final value in this) {
      return value;
    }
    return null;
  }
}

class _CosmeticDetailData {
  const _CosmeticDetailData({
    required this.item,
    required this.isOwned,
    required this.isEquipped,
    required this.collectionName,
  });

  const _CosmeticDetailData.nullData()
      : item = null,
        isOwned = false,
        isEquipped = false,
        collectionName = null;

  final ShopItem? item;
  final bool isOwned;
  final bool isEquipped;
  final String? collectionName;
}
