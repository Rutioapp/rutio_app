import 'package:rutio/features/shop/application/shop_operation_result.dart';
import 'package:rutio/features/shop/application/shop_service.dart';
import 'package:rutio/features/shop/data/shop_catalog.dart';
import 'package:rutio/features/shop/data/shop_local_repository.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/domain/shop_state.dart';
import 'package:rutio/stores/user_state_store.dart';

enum ShopControllerStatus {
  success,
  unavailableState,
  itemNotFound,
  insufficientCoins,
  alreadyOwned,
  itemNotOwned,
  invalidItemType,
  backpackItemNotFound,
}

class ShopItemState {
  const ShopItemState({
    required this.item,
    required this.walletCoins,
    required this.isOwned,
    required this.isEquipped,
    required this.backpackQuantity,
  });

  final ShopItem item;
  final int walletCoins;
  final bool isOwned;
  final bool isEquipped;
  final int backpackQuantity;

  bool get canAfford => walletCoins >= item.priceCoins;
  bool get isInBackpack => backpackQuantity > 0;
}

class ShopControllerResult {
  const ShopControllerResult({
    required this.status,
    required this.shopState,
    required this.walletCoins,
    this.item,
  });

  final ShopControllerStatus status;
  final ShopState shopState;
  final int walletCoins;
  final ShopItem? item;

  bool get isSuccess => status == ShopControllerStatus.success;
}

class ShopController {
  ShopController({
    required UserStateStore userStateStore,
    ShopLocalRepository? shopRepository,
  })  : _userStateStore = userStateStore,
        _shopRepository = shopRepository ?? ShopLocalRepository();

  final UserStateStore _userStateStore;
  final ShopLocalRepository _shopRepository;

  int getWalletCoins() {
    final root = _userStateStore.state;
    if (root == null) return 0;
    return _walletCoinsFromRoot(root);
  }

  Future<ShopItemState?> getItemState(String itemId) async {
    final item = ShopCatalog.getItemById(itemId);
    if (item == null) return null;

    final root = await _ensureRoot();
    if (root == null) return null;

    final shopState = await _shopRepository.load();
    return _buildItemState(
      item: item,
      shopState: shopState,
      walletCoins: _walletCoinsFromRoot(root),
    );
  }

  Future<ShopControllerResult> purchaseItem(String itemId) async {
    final item = ShopCatalog.getItemById(itemId);
    if (item == null) {
      return _controllerResult(
        ShopControllerStatus.itemNotFound,
        item: null,
        shopState: await _shopRepository.load(),
      );
    }

    final root = await _ensureRoot();
    if (root == null) {
      return _controllerResult(
        ShopControllerStatus.unavailableState,
        item: item,
        shopState: await _shopRepository.load(),
      );
    }

    final shopState = await _shopRepository.load();
    final walletCoins = _walletCoinsFromRoot(root);
    final result = ShopService(
      state: shopState,
      walletCoins: walletCoins,
    ).purchaseItem(item);

    if (!result.isSuccess) {
      return _mapOperationResult(result, item: item);
    }

    await _persistWalletCoins(root, result.walletCoins);
    await _shopRepository.save(result.state);
    return _controllerResult(
      ShopControllerStatus.success,
      item: item,
      shopState: result.state,
      walletCoins: result.walletCoins,
    );
  }

  Future<ShopControllerResult> equipItem(String itemId) async {
    final item = ShopCatalog.getItemById(itemId);
    if (item == null) {
      return _controllerResult(
        ShopControllerStatus.itemNotFound,
        item: null,
        shopState: await _shopRepository.load(),
      );
    }

    final root = await _ensureRoot();
    if (root == null) {
      return _controllerResult(
        ShopControllerStatus.unavailableState,
        item: item,
        shopState: await _shopRepository.load(),
      );
    }

    final shopState = await _shopRepository.load();
    final result = ShopService(
      state: shopState,
      walletCoins: _walletCoinsFromRoot(root),
    ).equipCosmetic(item);

    if (!result.isSuccess) {
      return _mapOperationResult(result, item: item);
    }

    await _shopRepository.save(result.state);
    return _controllerResult(
      ShopControllerStatus.success,
      item: item,
      shopState: result.state,
      walletCoins: result.walletCoins,
    );
  }

  Future<ShopControllerResult> unequipSlot(CosmeticSlot slot) async {
    final root = await _ensureRoot();
    if (root == null) {
      return _controllerResult(
        ShopControllerStatus.unavailableState,
        item: null,
        shopState: await _shopRepository.load(),
      );
    }

    final shopState = await _shopRepository.load();
    final result = ShopService(
      state: shopState,
      walletCoins: _walletCoinsFromRoot(root),
    ).unequipCosmetic(slot);

    await _shopRepository.save(result.state);
    return _controllerResult(
      ShopControllerStatus.success,
      item: null,
      shopState: result.state,
      walletCoins: result.walletCoins,
    );
  }

  Future<ShopControllerResult> consumeItem(String itemId) async {
    final item = ShopCatalog.getItemById(itemId);
    if (item == null) {
      return _controllerResult(
        ShopControllerStatus.itemNotFound,
        item: null,
        shopState: await _shopRepository.load(),
      );
    }

    final root = await _ensureRoot();
    if (root == null) {
      return _controllerResult(
        ShopControllerStatus.unavailableState,
        item: item,
        shopState: await _shopRepository.load(),
      );
    }

    final shopState = await _shopRepository.load();
    final result = ShopService(
      state: shopState,
      walletCoins: _walletCoinsFromRoot(root),
    ).consumeBackpackItem(itemId);

    if (!result.isSuccess) {
      return _mapOperationResult(result, item: item);
    }

    await _shopRepository.save(result.state);
    return _controllerResult(
      ShopControllerStatus.success,
      item: item,
      shopState: result.state,
      walletCoins: result.walletCoins,
    );
  }

  Future<Map<String, dynamic>?> _ensureRoot() async {
    if (_userStateStore.state == null) {
      await _userStateStore.load();
    }

    final root = _userStateStore.state;
    if (root == null) return null;
    return Map<String, dynamic>.from(root);
  }

  Future<void> _persistWalletCoins(
    Map<String, dynamic> root,
    int walletCoins,
  ) async {
    final userState =
        Map<String, dynamic>.from(root['userState'] as Map? ?? <String, dynamic>{});
    final wallet =
        Map<String, dynamic>.from(userState['wallet'] as Map? ?? <String, dynamic>{});
    wallet['coins'] = walletCoins;
    userState['wallet'] = wallet;
    root['userState'] = userState;
    await _userStateStore.save(root);
  }

  int _walletCoinsFromRoot(Map<String, dynamic> root) {
    final userState = root['userState'] as Map?;
    final wallet = userState?['wallet'] as Map?;
    return ((wallet?['coins'] as num?) ?? 0).toInt();
  }

  ShopItemState _buildItemState({
    required ShopItem item,
    required ShopState shopState,
    required int walletCoins,
  }) {
    final owned = shopState.inventory.any((entry) => entry.itemId == item.id);
    final backpackQuantity = shopState.backpackItems
        .where((entry) => entry.itemId == item.id)
        .fold<int>(0, (sum, entry) => sum + entry.quantity);
    final equipped = switch (item.cosmeticSlot) {
      CosmeticSlot.background =>
        shopState.equippedCosmetics.backgroundItemId == item.id,
      CosmeticSlot.habitCard =>
        shopState.equippedCosmetics.habitCardItemId == item.id,
      CosmeticSlot.userCard =>
        shopState.equippedCosmetics.userCardItemId == item.id,
      null => false,
    };

    return ShopItemState(
      item: item,
      walletCoins: walletCoins,
      isOwned: owned,
      isEquipped: equipped,
      backpackQuantity: backpackQuantity,
    );
  }

  ShopControllerResult _mapOperationResult(
    ShopOperationResult result, {
    required ShopItem? item,
  }) {
    return _controllerResult(
      switch (result.status) {
        ShopOperationStatus.success => ShopControllerStatus.success,
        ShopOperationStatus.insufficientCoins =>
          ShopControllerStatus.insufficientCoins,
        ShopOperationStatus.alreadyOwned => ShopControllerStatus.alreadyOwned,
        ShopOperationStatus.itemNotOwned => ShopControllerStatus.itemNotOwned,
        ShopOperationStatus.invalidItemType =>
          ShopControllerStatus.invalidItemType,
        ShopOperationStatus.invalidQuantity =>
          ShopControllerStatus.invalidItemType,
        ShopOperationStatus.backpackItemNotFound =>
          ShopControllerStatus.backpackItemNotFound,
      },
      item: item,
      shopState: result.state,
      walletCoins: result.walletCoins,
    );
  }

  ShopControllerResult _controllerResult(
    ShopControllerStatus status, {
    required ShopItem? item,
    required ShopState shopState,
    int? walletCoins,
  }) {
    return ShopControllerResult(
      status: status,
      item: item,
      shopState: shopState,
      walletCoins: walletCoins ?? getWalletCoins(),
    );
  }
}
