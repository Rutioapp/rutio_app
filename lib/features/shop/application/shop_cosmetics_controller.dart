import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rutio/features/global_wallet/application/global_wallet_controller.dart';
import 'package:rutio/features/shop/application/shop_cosmetics_service.dart';
import 'package:rutio/features/shop/data/cloud/cloud_cosmetics_cache.dart';
import 'package:rutio/features/shop/data/cloud/cloud_cosmetics_config.dart';
import 'package:rutio/features/shop/data/cloud/cloud_cosmetics_request_id.dart';
import 'package:rutio/features/shop/data/cloud/cloud_cosmetics_snapshot.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_equip_repository.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_errors.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_purchase_repository.dart';
import 'package:rutio/features/shop/data/cloud/shop_cosmetics_cloud_repository.dart';
import 'package:rutio/features/shop/data/shop_assets_catalog.dart';
import 'package:rutio/features/shop/data/shop_cosmetics_repository.dart';
import 'package:rutio/features/shop/domain/models/shop_asset.dart';
import 'package:rutio/features/shop/domain/models/shop_asset_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_operation_result.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_state.dart';
import 'package:rutio/features/shop/domain/shop_purchase_failure.dart';
import 'package:rutio/stores/user_state_store.dart';

enum ShopCosmeticsCloudStatus {
  loading,
  ready,
  stale,
  unauthenticated,
  walletMissing,
  failed,
}

class ShopCosmeticsCloudState {
  const ShopCosmeticsCloudState({
    required this.status,
    this.userId,
    this.snapshot,
    this.cachedEntry,
    this.failureMessage,
  });

  final ShopCosmeticsCloudStatus status;
  final String? userId;
  final CloudCosmeticsSnapshot? snapshot;
  final CloudCosmeticsCacheEntry? cachedEntry;
  final String? failureMessage;

  const ShopCosmeticsCloudState._(this.status,
      {this.userId, this.snapshot, this.cachedEntry, this.failureMessage});

  factory ShopCosmeticsCloudState.loading({
    String? userId,
    CloudCosmeticsCacheEntry? cache,
  }) {
    return ShopCosmeticsCloudState._(
      ShopCosmeticsCloudStatus.loading,
      userId: userId,
      snapshot: cache?.snapshot,
      cachedEntry: cache,
    );
  }

  factory ShopCosmeticsCloudState.ready({
    required String userId,
    required CloudCosmeticsSnapshot snapshot,
    CloudCosmeticsCacheEntry? cache,
  }) {
    return ShopCosmeticsCloudState._(
      ShopCosmeticsCloudStatus.ready,
      userId: userId,
      snapshot: snapshot,
      cachedEntry: cache,
    );
  }

  factory ShopCosmeticsCloudState.stale({
    required String userId,
    required CloudCosmeticsCacheEntry cache,
    String? failureMessage,
  }) {
    return ShopCosmeticsCloudState._(
      ShopCosmeticsCloudStatus.stale,
      userId: userId,
      snapshot: cache.snapshot,
      cachedEntry: cache,
      failureMessage: failureMessage,
    );
  }

  factory ShopCosmeticsCloudState.unauthenticated() {
    return const ShopCosmeticsCloudState._(
      ShopCosmeticsCloudStatus.unauthenticated,
    );
  }

  factory ShopCosmeticsCloudState.walletMissing({
    required String userId,
    String? failureMessage,
  }) {
    return ShopCosmeticsCloudState._(
      ShopCosmeticsCloudStatus.walletMissing,
      userId: userId,
      failureMessage: failureMessage,
    );
  }

  factory ShopCosmeticsCloudState.failed({
    required String? userId,
    required String failureMessage,
    CloudCosmeticsCacheEntry? cache,
  }) {
    return ShopCosmeticsCloudState._(
      ShopCosmeticsCloudStatus.failed,
      userId: userId,
      snapshot: cache?.snapshot,
      cachedEntry: cache,
      failureMessage: failureMessage,
    );
  }
}

class ShopCosmeticsController extends ChangeNotifier {
  ShopCosmeticsController({
    required UserStateStore userStateStore,
    GlobalWalletController? globalWalletController,
    ShopCosmeticsRepository? repository,
    CloudCosmeticsRepository? cloudRepository,
    CloudCosmeticsCache? cloudCache,
    bool? cloudEnabled,
  })  : _userStateStore = userStateStore,
        _globalWalletController = globalWalletController,
        _repository = repository ??
            ShopCosmeticsRepository(
              scopeResolver: () =>
                  userStateStore.activeLocalScopeUserId ??
                  userStateStore.userId,
            ),
        _cloudRepository = cloudRepository ?? SupabaseCloudCosmeticsRepository(),
        _cloudCache = cloudCache ?? SharedPreferencesCloudCosmeticsCache(),
        _cloudEnabled = CloudCosmeticsConfig.resolveEnabled(override: cloudEnabled) {
    _userStateStore.addListener(_handleUserStateStoreChanged);
    if (_cloudEnabled) {
      unawaited(_syncFromCurrentScope(force: false));
    }
  }

  final UserStateStore _userStateStore;
  final GlobalWalletController? _globalWalletController;
  final ShopCosmeticsRepository _repository;
  final CloudCosmeticsRepository _cloudRepository;
  final CloudCosmeticsCache _cloudCache;
  final bool _cloudEnabled;
  ShopCosmeticsState? _cachedState;
  String? _cachedScopeKey;
  Future<ShopCosmeticsState>? _pendingStateLoad;
  Future<ShopCosmeticsState>? _pendingCloudStateLoad;
  ShopCosmeticsCloudState _cloudState =
      ShopCosmeticsCloudState.unauthenticated();

  ShopCosmeticsState? get state => _cachedState;
  ShopCosmeticsCloudState get cloudState => _cloudState;
  bool get isCloudEnabled => _cloudEnabled;
  bool get hasStateForCurrentScope =>
      _cachedState != null && _cachedScopeKey == _currentScope();

  Future<ShopCosmeticsState> getState() async {
    if (_cloudEnabled) {
      final scopeKey = _currentScope();
      if (_cachedState != null && _cachedScopeKey == scopeKey) {
        return _cachedState!;
      }
      return _syncFromCurrentScope(force: false);
    }

    final scopeKey = _currentScope();
    final cached = _cachedState;
    if (cached != null && _cachedScopeKey == scopeKey) {
      _log(
        'getState scope=${_currentScope() ?? 'guest'} source=memory '
        'ownedAssetIds=${cached.ownedAssetIds} ownedBundleIds=${cached.ownedBundleIds} '
        'equippedWallpaperId=${cached.equippedWallpaperId} '
        'equippedHabitCardSkinId=${cached.equippedHabitCardSkinId} '
        'equippedUserCardSkinId=${cached.equippedUserCardSkinId}',
      );
      return cached;
    }

    final pending = _pendingStateLoad;
    if (pending != null) {
      return pending;
    }

    late final Future<ShopCosmeticsState> future;
    future = _repository.load().then((state) {
      _setCachedState(
        state,
        scopeKey: scopeKey,
        shouldNotifyListeners: false,
      );
      _log(
        'getState scope=${_currentScope() ?? 'guest'} '
        'ownedAssetIds=${state.ownedAssetIds} ownedBundleIds=${state.ownedBundleIds} '
        'equippedWallpaperId=${state.equippedWallpaperId} '
        'equippedHabitCardSkinId=${state.equippedHabitCardSkinId} '
        'equippedUserCardSkinId=${state.equippedUserCardSkinId}',
      );
      return state;
    }).whenComplete(() {
      if (identical(_pendingStateLoad, future)) {
        _pendingStateLoad = null;
      }
    });
    _pendingStateLoad = future;
    final state = await future;
    return state;
  }

  Future<ShopCosmeticsState> hydrate() => getState();

  @override
  void dispose() {
    _userStateStore.removeListener(_handleUserStateStoreChanged);
    super.dispose();
  }

  ShopAsset? getEquippedAssetForCategorySync(ShopAssetCategory category) {
    final cached = _cachedState;
    if (cached == null || _cachedScopeKey != _currentScope()) {
      return null;
    }
    return _getValidatedEquippedAssetOrNull(cached, category);
  }

  ShopAsset? getEquippedWallpaperAssetOrNullSync() {
    return getEquippedAssetForCategorySync(ShopAssetCategory.wallpaper);
  }

  ShopAsset? getEquippedHabitCardAssetOrNullSync() {
    return getEquippedAssetForCategorySync(ShopAssetCategory.habitCard);
  }

  ShopAsset? getEquippedUserCardAssetOrNullSync() {
    return getEquippedAssetForCategorySync(ShopAssetCategory.userCard);
  }

  Future<int> getWalletCoins() => _walletCoins();

  Future<bool> canPurchaseAsset(String assetId) async {
    if (_cloudEnabled) {
      final state = await _combinedCloudState();
      final asset = ShopAssetsCatalog.getAssetById(assetId);
      if (asset == null) return false;
      if (state.isAssetOwned(assetId, bundles: ShopAssetsCatalog.allBundles)) {
        return false;
      }
      final walletCoins = await _walletCoins();
      return walletCoins >= asset.priceAmber;
    }

    final service = await _service();
    return service.canPurchaseAsset(assetId);
  }

  Future<bool> canPurchaseBundle(String bundleId) async {
    final service = await _service();
    return service.canPurchaseBundle(bundleId);
  }

  Future<bool> isAssetOwned(String assetId) async {
    if (_cloudEnabled) {
      final state = await _combinedCloudState();
      return state.isAssetOwned(assetId, bundles: ShopAssetsCatalog.allBundles);
    }

    final service = await _service();
    return service.isAssetOwned(assetId);
  }

  Future<bool> isBundleOwned(String bundleId) async {
    final service = await _service();
    return service.isBundleOwned(bundleId);
  }

  Future<bool> isBundlePartiallyOwned(String bundleId) async {
    final service = await _service();
    return service.isBundlePartiallyOwned(bundleId);
  }

  Future<ShopAssetOwnershipState> assetOwnershipState(String assetId) async {
    if (_cloudEnabled) {
      final state = await _combinedCloudState();
      final asset = ShopAssetsCatalog.getAssetById(assetId);
      if (asset == null) return ShopAssetOwnershipState.locked;
      return state.assetOwnershipState(
        asset,
        bundles: ShopAssetsCatalog.allBundles,
      );
    }

    final service = await _service();
    return service.assetOwnershipState(assetId);
  }

  Future<ShopAsset?> getEquippedAssetForCategory(
    ShopAssetCategory category,
  ) async {
    final cached = getEquippedAssetForCategorySync(category);
    if (cached != null) {
      return cached;
    }
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
    if (_cloudEnabled) {
      return _purchaseAssetCloud(assetId);
    }

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
    _setCachedState(result.state);
    try {
      await _persist(result.state, result.walletCoins);
    } catch (_) {
      await _restorePersistedStateAfterFailure();
      rethrow;
    }
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
    _setCachedState(result.state);
    try {
      await _persist(result.state, result.walletCoins);
    } catch (_) {
      await _restorePersistedStateAfterFailure();
      rethrow;
    }
    return result;
  }

  Future<ShopCosmeticsOperationResult> equipAsset(String assetId) async {
    if (_cloudEnabled) {
      return _equipAssetCloud(assetId);
    }

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
    _setCachedState(result.state);
    try {
      await _persist(result.state, result.walletCoins);
    } catch (_) {
      await _restorePersistedStateAfterFailure();
      rethrow;
    }
    return result;
  }

  Future<ShopCosmeticsOperationResult> unequipAsset(
    ShopAssetCategory category,
  ) async {
    if (_cloudEnabled) {
      return _unequipAssetCloud(category);
    }

    final service = await _service();
    final result = service.unequipAsset(category);
    if (!result.isSuccess) return result;
    _setCachedState(result.state);
    try {
      await _persist(result.state, result.walletCoins);
    } catch (_) {
      await _restorePersistedStateAfterFailure();
      rethrow;
    }
    return result;
  }

  Future<ShopCosmeticsService> _service() async {
    final walletCoins = await _walletCoins();
    final state = await _repository.load();
    _setCachedState(
      state,
      scopeKey: _currentScope(),
      shouldNotifyListeners: false,
    );
    _log(
      'createService scope=${_currentScope() ?? 'guest'} walletCoins=$walletCoins '
      'ownedAssetIds=${state.ownedAssetIds} ownedBundleIds=${state.ownedBundleIds}',
    );
    return ShopCosmeticsService(state: state, walletCoins: walletCoins);
  }

  Future<int> _walletCoins() async {
    final globalWalletController = _globalWalletController;
    if (globalWalletController != null && globalWalletController.isEnabled) {
      return globalWalletController.state.coins ?? 0;
    }

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

  Future<void> _restorePersistedStateAfterFailure() async {
    final restored = await _repository.load();
    _setCachedState(restored);
  }

  void _handleUserStateStoreChanged() {
    if (!_cloudEnabled) return;

    final currentScope = _currentScope();
    if (currentScope == null) {
      _cloudState = ShopCosmeticsCloudState.unauthenticated();
      _cachedState = null;
      _cachedScopeKey = null;
      notifyListeners();
      return;
    }

    if (_cachedScopeKey != currentScope) {
      _cachedState = null;
      _cachedScopeKey = currentScope;
      _setCloudState(ShopCosmeticsCloudState.loading(userId: currentScope));
      unawaited(_syncFromCurrentScope(force: true));
    }
  }

  void _setCloudState(ShopCosmeticsCloudState state) {
    _cloudState = state;
    notifyListeners();
  }

  Future<ShopCosmeticsOperationResult> _purchaseAssetCloud(
    String assetId,
  ) async {
    final scopeKey = _currentScope();
    final asset = ShopAssetsCatalog.getAssetById(assetId);
    if (asset == null) {
      return _cloudFailureResult(
        status: ShopCosmeticsOperationStatus.assetNotFound,
      );
    }

    final state = await _combinedCloudState();
    if (state.isAssetOwned(assetId, bundles: ShopAssetsCatalog.allBundles)) {
      return _cloudFailureResult(
        status: ShopCosmeticsOperationStatus.alreadyOwned,
        state: state,
        assetId: assetId,
      );
    }

    final requestId = CloudCosmeticsRequestId.generateV4();
    try {
      final result = await _cloudRepository.purchaseAsset(
        itemId: assetId,
        requestId: requestId,
      );
      if (_currentScope() != scopeKey) {
        return _cloudFailureResult(
          status: ShopCosmeticsOperationStatus.bundleNotFound,
          assetId: assetId,
        );
      }
      final nextState = state.copyWith(
        ownedAssetIds: <String>[...state.ownedAssetIds, assetId],
      );
      _setCachedState(nextState);
      if (scopeKey != null) {
        await _cloudCache.save(
          CloudCosmeticsSnapshot(
            userId: scopeKey,
            ownedAssetIds: nextState.ownedAssetIds,
            equippedWallpaperId: nextState.equippedWallpaperId,
            equippedHabitCardSkinId: nextState.equippedHabitCardSkinId,
            equippedUserCardSkinId: nextState.equippedUserCardSkinId,
            catalogVersion: _cloudState.snapshot?.catalogVersion,
            fetchedAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          ),
        );
      }
      unawaited(_syncFromCurrentScope(force: true));
      unawaited(
        _globalWalletController?.syncSession(
          userId: _currentScope(),
          force: true,
        ),
      );
      return ShopCosmeticsOperationResult(
        status: ShopCosmeticsOperationStatus.success,
        state: nextState,
        walletCoins: result.coins,
        assetId: assetId,
      );
    } on ShopCloudPurchaseException catch (error) {
      return _mapCloudPurchaseFailure(
        error,
        assetId: assetId,
        currentState: state,
      );
    }
  }

  Future<ShopCosmeticsOperationResult> _equipAssetCloud(
    String assetId,
  ) async {
    final scopeKey = _currentScope();
    final asset = ShopAssetsCatalog.getAssetById(assetId);
    final state = await _combinedCloudState();
    if (asset == null) {
      return _cloudFailureResult(
        status: ShopCosmeticsOperationStatus.assetNotFound,
        state: state,
        assetId: assetId,
      );
    }

    final owned =
        state.isAssetOwned(assetId, bundles: ShopAssetsCatalog.allBundles);
    if (!owned) {
      return _cloudFailureResult(
        status: ShopCosmeticsOperationStatus.assetNotOwned,
        state: state,
        assetId: assetId,
      );
    }

    final requestId = CloudCosmeticsRequestId.generateV4();
    try {
      await _cloudRepository.equipAsset(
        itemId: assetId,
        requestId: requestId,
      );
      if (_currentScope() != scopeKey) {
        return _cloudFailureResult(
          status: ShopCosmeticsOperationStatus.bundleNotFound,
          assetId: assetId,
        );
      }
      final nextState = switch (asset.category) {
        ShopAssetCategory.wallpaper =>
          state.copyWith(equippedWallpaperId: assetId),
        ShopAssetCategory.habitCard =>
          state.copyWith(equippedHabitCardSkinId: assetId),
        ShopAssetCategory.userCard =>
          state.copyWith(equippedUserCardSkinId: assetId),
      };
      _setCachedState(nextState);
      if (scopeKey != null) {
        await _cloudCache.save(
          CloudCosmeticsSnapshot(
            userId: scopeKey,
            ownedAssetIds: nextState.ownedAssetIds,
            equippedWallpaperId: nextState.equippedWallpaperId,
            equippedHabitCardSkinId: nextState.equippedHabitCardSkinId,
            equippedUserCardSkinId: nextState.equippedUserCardSkinId,
            catalogVersion: _cloudState.snapshot?.catalogVersion,
            fetchedAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          ),
        );
      }
      return ShopCosmeticsOperationResult(
        status: ShopCosmeticsOperationStatus.success,
        state: nextState,
        walletCoins: await _walletCoins(),
        assetId: assetId,
      );
    } on ShopCloudEquipException catch (error) {
      return _mapCloudEquipFailure(
        error,
        assetId: assetId,
        currentState: state,
      );
    }
  }

  Future<ShopCosmeticsOperationResult> _unequipAssetCloud(
    ShopAssetCategory category,
  ) async {
    final scopeKey = _currentScope();
    final state = await _combinedCloudState();
    final nextState = switch (category) {
      ShopAssetCategory.wallpaper =>
        state.copyWith(equippedWallpaperId: null),
      ShopAssetCategory.habitCard =>
        state.copyWith(equippedHabitCardSkinId: null),
      ShopAssetCategory.userCard =>
        state.copyWith(equippedUserCardSkinId: null),
    };
    if (_currentScope() != scopeKey) {
      return _cloudFailureResult(status: ShopCosmeticsOperationStatus.bundleNotFound);
    }
    _setCachedState(nextState);
    if (scopeKey != null) {
      await _cloudCache.save(
        CloudCosmeticsSnapshot(
          userId: scopeKey,
          ownedAssetIds: nextState.ownedAssetIds,
          equippedWallpaperId: nextState.equippedWallpaperId,
          equippedHabitCardSkinId: nextState.equippedHabitCardSkinId,
          equippedUserCardSkinId: nextState.equippedUserCardSkinId,
          catalogVersion: _cloudState.snapshot?.catalogVersion,
          fetchedAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
    }
    return ShopCosmeticsOperationResult(
      status: ShopCosmeticsOperationStatus.success,
      state: nextState,
      walletCoins: await _walletCoins(),
    );
  }

  ShopCosmeticsOperationResult _cloudFailureResult({
    required ShopCosmeticsOperationStatus status,
    ShopCosmeticsState? state,
    String? assetId,
    String? bundleId,
  }) {
    final resolvedState =
        state ?? _cachedState ?? const ShopCosmeticsState.initial();
    return ShopCosmeticsOperationResult(
      status: status,
      state: resolvedState,
      walletCoins: 0,
      assetId: assetId,
      bundleId: bundleId,
    );
  }

  Future<ShopCosmeticsOperationResult> _mapCloudPurchaseFailure(
    ShopCloudPurchaseException error, {
    required String assetId,
    required ShopCosmeticsState currentState,
  }) async {
    final status = switch (error.code) {
      ShopPurchaseFailureCode.itemAlreadyOwned =>
        ShopCosmeticsOperationStatus.alreadyOwned,
      ShopPurchaseFailureCode.insufficientFunds =>
        ShopCosmeticsOperationStatus.insufficientCoins,
      ShopPurchaseFailureCode.itemNotFoundOrInactive =>
        ShopCosmeticsOperationStatus.assetNotFound,
      ShopPurchaseFailureCode.itemConfigurationInvalid =>
        ShopCosmeticsOperationStatus.bundleNotFound,
      ShopPurchaseFailureCode.authRequired ||
      ShopPurchaseFailureCode.unauthenticated ||
      ShopPurchaseFailureCode.featureDisabled ||
      ShopPurchaseFailureCode.walletNotInitialized ||
      ShopPurchaseFailureCode.cloudWalletMissing =>
        ShopCosmeticsOperationStatus.bundleNotFound,
      _ => ShopCosmeticsOperationStatus.bundleNotFound,
    };

    return ShopCosmeticsOperationResult(
      status: status,
      state: currentState,
      walletCoins: await _walletCoins(),
      assetId: assetId,
    );
  }

  Future<ShopCosmeticsOperationResult> _mapCloudEquipFailure(
    ShopCloudEquipException error, {
    required String assetId,
    required ShopCosmeticsState currentState,
  }) async {
    final status = switch (error.code) {
      ShopCosmeticsOperationFailureCode.itemNotOwned =>
        ShopCosmeticsOperationStatus.assetNotOwned,
      ShopCosmeticsOperationFailureCode.itemNotFoundOrInactive =>
        ShopCosmeticsOperationStatus.assetNotFound,
      ShopCosmeticsOperationFailureCode.itemConfigurationInvalid =>
        ShopCosmeticsOperationStatus.bundleNotFound,
      ShopCosmeticsOperationFailureCode.authRequired ||
      ShopCosmeticsOperationFailureCode.requestIdConflict ||
      ShopCosmeticsOperationFailureCode.requestIdRequired ||
      ShopCosmeticsOperationFailureCode.networkUnavailable ||
      ShopCosmeticsOperationFailureCode.timeout ||
      ShopCosmeticsOperationFailureCode.malformedResponse ||
      ShopCosmeticsOperationFailureCode.unknown =>
        ShopCosmeticsOperationStatus.bundleNotFound,
    };

    return ShopCosmeticsOperationResult(
      status: status,
      state: currentState,
      walletCoins: await _walletCoins(),
      assetId: assetId,
    );
  }

  Future<ShopCosmeticsState> _syncFromCurrentScope({bool force = false}) async {
    final scopeKey = _currentScope();
    if (scopeKey == null) {
      _cloudState = ShopCosmeticsCloudState.unauthenticated();
      _cachedState = null;
      _cachedScopeKey = null;
      notifyListeners();
      return const ShopCosmeticsState.initial();
    }

    final pending = _pendingCloudStateLoad;
    if (!force && pending != null && _cachedScopeKey == scopeKey) {
      return pending;
    }

    late final Future<ShopCosmeticsState> future;
    future = _loadCloudState(scopeKey: scopeKey, force: force).whenComplete(() {
      if (identical(_pendingCloudStateLoad, future)) {
        _pendingCloudStateLoad = null;
      }
    });
    _pendingCloudStateLoad = future;
    return future;
  }

  Future<ShopCosmeticsState> _loadCloudState({
    required String scopeKey,
    required bool force,
  }) async {
    final localState = await _repository.load();
    final cacheEntry = await _cloudCache.read(scopeKey);

    if (cacheEntry != null && !force) {
      _setCloudState(
        ShopCosmeticsCloudState.loading(userId: scopeKey, cache: cacheEntry),
      );
      _setCachedState(
        cacheEntry.snapshot.toState(
          ownedBundleIds: localState.ownedBundleIds,
        ),
        scopeKey: scopeKey,
        shouldNotifyListeners: false,
      );
    } else if (cacheEntry == null) {
      _setCloudState(ShopCosmeticsCloudState.loading(userId: scopeKey));
    }

    final result = await _cloudRepository.fetchSnapshot();
    if (_currentScope() != scopeKey) {
      return _cachedState ?? localState;
    }

    if (!result.isSuccess || result.data == null) {
      final failureMessage = result.error?.message ?? 'Could not fetch cloud cosmetics.';
      if (cacheEntry != null) {
        _setCloudState(
          ShopCosmeticsCloudState.stale(
            userId: scopeKey,
            cache: cacheEntry,
            failureMessage: failureMessage,
          ),
        );
        final restored = cacheEntry.snapshot.toState(
          ownedBundleIds: localState.ownedBundleIds,
        );
        _setCachedState(restored, scopeKey: scopeKey, shouldNotifyListeners: true);
        return restored;
      }

      if (result.error?.code == ShopCloudErrorCode.walletMissing) {
        _setCloudState(
          ShopCosmeticsCloudState.walletMissing(
            userId: scopeKey,
            failureMessage: failureMessage,
          ),
        );
      } else {
        _setCloudState(
          ShopCosmeticsCloudState.failed(
            userId: scopeKey,
            failureMessage: failureMessage,
            cache: cacheEntry,
          ),
        );
      }
      final fallback = ShopCosmeticsState(
        ownedAssetIds: const <String>[],
        ownedBundleIds: localState.ownedBundleIds,
      );
      _setCachedState(fallback, scopeKey: scopeKey, shouldNotifyListeners: true);
      return fallback;
    }

    final snapshot = result.data!;
    final combinedState = snapshot.toState(
      ownedBundleIds: localState.ownedBundleIds,
    );
    final savedEntry = await _cloudCache.save(snapshot);
    _setCloudState(
      ShopCosmeticsCloudState.ready(
        userId: scopeKey,
        snapshot: snapshot,
        cache: savedEntry,
      ),
    );
    _setCachedState(
      combinedState,
      scopeKey: scopeKey,
      shouldNotifyListeners: true,
    );
    return combinedState;
  }

  Future<ShopCosmeticsState> _combinedCloudState() async {
    final scopeKey = _currentScope();
    if (scopeKey == null) {
      return const ShopCosmeticsState.initial();
    }
    if (_cachedState != null && _cachedScopeKey == scopeKey) {
      return _cachedState!;
    }
    return _syncFromCurrentScope(force: false);
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

    final owned =
        state.isAssetOwned(asset.id, bundles: ShopAssetsCatalog.allBundles);
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

  void _setCachedState(
    ShopCosmeticsState state, {
    String? scopeKey,
    bool shouldNotifyListeners = true,
  }) {
    _cachedState = state;
    _cachedScopeKey = scopeKey ?? _currentScope();
    if (shouldNotifyListeners) {
      super.notifyListeners();
    }
  }
}
