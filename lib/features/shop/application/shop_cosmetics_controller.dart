import 'package:flutter/foundation.dart';
import 'package:rutio/features/shop/application/shop_cosmetics_service.dart';
import 'package:rutio/features/shop/data/shop_assets_catalog.dart';
import 'package:rutio/features/shop/data/shop_cosmetics_repository.dart';
import 'package:rutio/features/shop/domain/models/shop_asset.dart';
import 'package:rutio/features/shop/domain/models/shop_asset_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_operation_result.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_state.dart';
import 'package:rutio/stores/user_state_store.dart';

class ShopCosmeticsController {
  ShopCosmeticsController({
    required UserStateStore userStateStore,
    ShopCosmeticsRepository? repository,
  })  : _userStateStore = userStateStore,
        _repository = repository ??
            ShopCosmeticsRepository(
              scopeResolver: () =>
                  userStateStore.activeLocalScopeUserId ?? userStateStore.userId,
            );

  final UserStateStore _userStateStore;
  final ShopCosmeticsRepository _repository;

  Future<ShopCosmeticsState> getState() async {
    final state = await _repository.load();
    _log(
      'getState scope=${_currentScope() ?? 'guest'} '
      'ownedAssetIds=${state.ownedAssetIds} ownedBundleIds=${state.ownedBundleIds} '
      'equippedWallpaperId=${state.equippedWallpaperId} '
      'equippedHabitCardSkinId=${state.equippedHabitCardSkinId} '
      'equippedUserCardSkinId=${state.equippedUserCardSkinId}',
    );
    return state;
  }

  Future<int> getWalletCoins() => _walletCoins();

  Future<bool> canPurchaseAsset(String assetId) async {
    final service = await _service();
    return service.canPurchaseAsset(assetId);
  }

  Future<bool> canPurchaseBundle(String bundleId) async {
    final service = await _service();
    return service.canPurchaseBundle(bundleId);
  }

  Future<bool> isAssetOwned(String assetId) async {
    final service = await _service();
    return service.isAssetOwned(assetId);
  }

  Future<bool> isBundleOwned(String bundleId) async {
    final service = await _service();
    return service.isBundleOwned(bundleId);
  }

  Future<ShopAssetOwnershipState> assetOwnershipState(String assetId) async {
    final service = await _service();
    return service.assetOwnershipState(assetId);
  }

  Future<ShopAsset?> getEquippedAssetForCategory(
    ShopAssetCategory category,
  ) async {
    final state = await getState();
    return _getValidatedEquippedAssetOrNull(state, category);
  }

  Future<ShopAsset?> getEquippedWallpaperAssetOrNull() async {
    final state = await getState();
    return _getValidatedEquippedAssetOrNull(state, ShopAssetCategory.wallpaper);
  }

  Future<ShopAsset?> getEquippedHabitCardAssetOrNull() async {
    final state = await getState();
    return _getValidatedEquippedAssetOrNull(state, ShopAssetCategory.habitCard);
  }

  Future<ShopAsset?> getEquippedUserCardAssetOrNull() async {
    final state = await getState();
    return _getValidatedEquippedAssetOrNull(state, ShopAssetCategory.userCard);
  }

  Future<ShopCosmeticsOperationResult> purchaseAsset(String assetId) async {
    final service = await _service();
    final asset = ShopAssetsCatalog.getAssetById(assetId);
    final result = service.purchaseAsset(assetId);
    _log(
      'purchaseAsset assetId=$assetId found=${asset != null} category=${asset?.category.name} '
      'success=${result.isSuccess} ownedAssetIds=${result.state.ownedAssetIds} '
      'equippedWallpaperId=${result.state.equippedWallpaperId} '
      'equippedHabitCardSkinId=${result.state.equippedHabitCardSkinId} '
      'equippedUserCardSkinId=${result.state.equippedUserCardSkinId}',
    );
    if (!result.isSuccess) return result;
    await _persist(result.state, result.walletCoins);
    return result;
  }

  Future<ShopCosmeticsOperationResult> purchaseBundle(String bundleId) async {
    final service = await _service();
    final result = service.purchaseBundle(bundleId);
    _log(
      'purchaseBundle bundleId=$bundleId success=${result.isSuccess} '
      'ownedBundleIds=${result.state.ownedBundleIds} '
      'equippedWallpaperId=${result.state.equippedWallpaperId} '
      'equippedHabitCardSkinId=${result.state.equippedHabitCardSkinId} '
      'equippedUserCardSkinId=${result.state.equippedUserCardSkinId}',
    );
    if (!result.isSuccess) return result;
    await _persist(result.state, result.walletCoins);
    return result;
  }

  Future<ShopCosmeticsOperationResult> equipAsset(String assetId) async {
    final service = await _service();
    final asset = ShopAssetsCatalog.getAssetById(assetId);
    final owned = asset == null ? false : service.isAssetOwned(assetId);
    final includedInOwnedBundle = asset == null
        ? false
        : !service.state.ownedAssetIds.contains(assetId) &&
            service.state.isAssetOwned(
              assetId,
              bundles: ShopAssetsCatalog.allBundles,
            );
    final result = service.equipAsset(assetId);
    final updatedSlot = switch (asset?.category) {
      ShopAssetCategory.wallpaper => 'equippedWallpaperId',
      ShopAssetCategory.habitCard => 'equippedHabitCardSkinId',
      ShopAssetCategory.userCard => 'equippedUserCardSkinId',
      null => 'none',
    };
    _log(
      'equipAsset assetId=$assetId found=${asset != null} category=${asset?.category.name} '
      'owned=$owned includedInOwnedBundle=$includedInOwnedBundle success=${result.isSuccess} '
      'updatedSlot=$updatedSlot equippedWallpaperId=${result.state.equippedWallpaperId} '
      'equippedHabitCardSkinId=${result.state.equippedHabitCardSkinId} '
      'equippedUserCardSkinId=${result.state.equippedUserCardSkinId}',
    );
    if (!result.isSuccess) return result;
    await _persist(result.state, result.walletCoins);
    return result;
  }

  Future<ShopCosmeticsOperationResult> unequipAsset(
    ShopAssetCategory category,
  ) async {
    final service = await _service();
    final result = service.unequipAsset(category);
    if (!result.isSuccess) return result;
    await _persist(result.state, result.walletCoins);
    return result;
  }

  Future<ShopCosmeticsService> _service() async {
    final walletCoins = await _walletCoins();
    final state = await _repository.load();
    _log(
      'createService scope=${_currentScope() ?? 'guest'} walletCoins=$walletCoins '
      'ownedAssetIds=${state.ownedAssetIds} ownedBundleIds=${state.ownedBundleIds}',
    );
    return ShopCosmeticsService(state: state, walletCoins: walletCoins);
  }

  Future<int> _walletCoins() async {
    if (_userStateStore.state == null) {
      await _userStateStore.load();
    }

    final root = _userStateStore.state;
    if (root == null) return 0;
    final userState = (root['userState'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    final wallet = (userState['wallet'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    return ((wallet['coins'] as num?) ?? 0).toInt();
  }

  Future<void> _persist(ShopCosmeticsState state, int walletCoins) async {
    final root = await _ensureRoot();
    if (root == null) return;

    await _repository.save(state);
    final userState = Map<String, dynamic>.from(
      root['userState'] as Map? ?? <String, dynamic>{},
    );
    final wallet = Map<String, dynamic>.from(
      userState['wallet'] as Map? ?? <String, dynamic>{},
    );
    wallet['coins'] = walletCoins;
    userState['wallet'] = wallet;
    root['userState'] = userState;
    await _userStateStore.save(root);
    _log(
      'persistState scope=${_currentScope() ?? 'guest'} walletCoins=$walletCoins persisted=true '
      'equippedWallpaperId=${state.equippedWallpaperId} '
      'equippedHabitCardSkinId=${state.equippedHabitCardSkinId} '
      'equippedUserCardSkinId=${state.equippedUserCardSkinId}',
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

  ShopAsset? _getValidatedEquippedAssetOrNull(
    ShopCosmeticsState state,
    ShopAssetCategory category,
  ) {
    final logLabel = switch (category) {
      ShopAssetCategory.wallpaper => 'resolveWallpaper',
      ShopAssetCategory.habitCard => 'resolveHabitCard',
      ShopAssetCategory.userCard => 'resolveUserCard',
    };
    final assetId = state.getEquippedAssetIdForCategory(category);
    if (assetId == null || assetId.trim().isEmpty) {
      _log(
        '$logLabel equippedId=$assetId owned=false categoryValid=false assetPath=null',
      );
      return null;
    }

    final asset = ShopCosmeticsService(
      state: state,
      walletCoins: 0,
    ).getEquippedAssetForCategory(category);
    if (asset == null || asset.category != category) {
      _log(
        '$logLabel equippedId=$assetId owned=false categoryValid=false assetPath=null',
      );
      return null;
    }

    final owned = state.isAssetOwned(asset.id, bundles: ShopAssetsCatalog.allBundles);
    if (!owned) {
      _log(
        '$logLabel equippedId=$assetId owned=false categoryValid=true assetPath=null',
      );
      return null;
    }

    _log(
      '$logLabel equippedId=$assetId owned=true categoryValid=true assetPath=${asset.assetPath}',
    );
    return asset;
  }

  String? _currentScope() {
    final active = _userStateStore.activeLocalScopeUserId?.trim();
    if (active != null && active.isNotEmpty) {
      return active;
    }
    final userId = _userStateStore.userId?.trim();
    if (userId != null && userId.isNotEmpty) {
      return userId;
    }
    return null;
  }

  void _log(String message) {
    if (!kDebugMode) return;
    debugPrint('[ShopCosmetics] $message');
  }
}
