import 'package:rutio/features/shop/domain/models/shop_bundle.dart';
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
import 'package:rutio/features/shop/data/shop_catalog.dart';
import 'package:rutio/features/shop/data/shop_cosmetics_repository.dart';
import 'package:rutio/features/shop/domain/models/shop_asset.dart';
import 'package:rutio/features/shop/domain/models/shop_asset_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
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
        _cloudRepository =
            cloudRepository ?? SupabaseCloudCosmeticsRepository(),
        _cloudCache = cloudCache ?? SharedPreferencesCloudCosmeticsCache(),
        _cloudEnabled =
            CloudCosmeticsConfig.resolveEnabled(override: cloudEnabled) {
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
  int _cloudMutationVersion = 0;
  int _cloudRefreshGeneration = 0;
  int _cloudSnapshotRevision = 0;
  String? _lastTraceId;
  ShopCosmeticsCloudState _cloudState =
      ShopCosmeticsCloudState.unauthenticated();

  ShopCosmeticsState? get state => _cachedState;
  ShopCosmeticsCloudState get cloudState => _cloudState;
  int get cloudSnapshotRevision => _cloudSnapshotRevision;
  String? get lastTraceId => _lastTraceId;
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
    if (_cloudEnabled) {
      final scopeKey = _currentScope();
      final snapshot = _cloudState.snapshot;
      if (scopeKey == null ||
          snapshot == null ||
          _cloudState.userId != scopeKey) {
        return null;
      }

      final cloudState = snapshot.toState();
      final equippedId = snapshot.equippedItemIdForCategory(category);
      _log(
        '[shop_cosmetics_home] source=cloud equippedId=$equippedId '
        'category=${category.name}',
      );
      return _getValidatedEquippedAssetOrNull(cloudState, category);
    }

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
    if (_cloudEnabled) {
      return _purchaseBundleCloud(bundleId);
    }

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

  Future<ShopCosmeticsOperationResult> equipAsset(
    String assetId, {
    String? traceId,
  }) async {
    if (_cloudEnabled) {
      return _equipAssetCloud(
        assetId,
        traceId: traceId,
      );
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
    final traceId = _newTraceId('tap');
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
      _traceCloudCosmetics(
        'tap',
        traceId: traceId,
        userId: scopeKey,
        nextItemId: assetId,
        slot: _resolveEquipSlot(asset),
        assetPath: asset.assetPath,
      );
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
      final resolvedScopeKey = scopeKey ?? _currentScope();
      if (resolvedScopeKey == null) {
        return _cloudFailureResult(
          status: ShopCosmeticsOperationStatus.bundleNotFound,
          assetId: assetId,
        );
      }
      final nextState = state.copyWith(
        ownedAssetIds: <String>[...state.ownedAssetIds, assetId],
      );
      _markCloudMutation();
      final snapshot = _buildCloudSnapshot(resolvedScopeKey, nextState);
      await _applyConfirmedCloudSnapshot(
        scopeKey: resolvedScopeKey,
        snapshot: snapshot,
        traceId: traceId,
        stage: 'state_applied',
        nextItemId: assetId,
      );
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

  Future<ShopCosmeticsOperationResult> _purchaseBundleCloud(
    String bundleId,
  ) async {
    final scopeKey = _currentScope();
    final traceId = _newTraceId('tap');
    final bundle = ShopAssetsCatalog.getBundleById(bundleId);
    if (bundle == null) {
      return _cloudFailureResult(
        status: ShopCosmeticsOperationStatus.bundleNotFound,
        bundleId: bundleId,
      );
    }

    final state = await _combinedCloudState();
    if (state.isBundleOwned(bundleId)) {
      return _cloudFailureResult(
        status: ShopCosmeticsOperationStatus.alreadyOwned,
        state: state,
        bundleId: bundleId,
      );
    }
    if (_bundleContainsOwnedAssets(state, bundle)) {
      return _cloudFailureResult(
        status: ShopCosmeticsOperationStatus.bundleContainsOwnedAssets,
        state: state,
        bundleId: bundleId,
      );
    }

    final requestId = CloudCosmeticsRequestId.generateV4();
    try {
      _traceCloudCosmetics(
        'tap',
        traceId: traceId,
        userId: scopeKey,
        nextItemId: bundleId,
        state: state,
        note: 'bundle_purchase_request=$requestId',
      );
      final result = await _cloudRepository.purchaseBundle(
        bundleId: bundleId,
        requestId: requestId,
      );
      if (_currentScope() != scopeKey) {
        return _cloudFailureResult(
          status: ShopCosmeticsOperationStatus.bundleNotFound,
          bundleId: bundleId,
        );
      }
      final resolvedScopeKey = scopeKey ?? _currentScope();
      if (resolvedScopeKey == null) {
        return _cloudFailureResult(
          status: ShopCosmeticsOperationStatus.bundleNotFound,
          bundleId: bundleId,
        );
      }

      final remoteItemIds = <String>[
        result.wallpaperItemId,
        result.habitCardItemId,
        result.userCardItemId,
      ];
      final localItemIds = <String>[
        bundle.wallpaperItemId,
        bundle.habitCardItemId,
        bundle.userCardItemId,
      ];
      if (!listEquals(remoteItemIds, localItemIds)) {
        return _cloudFailureResult(
          status: ShopCosmeticsOperationStatus.bundleNotFound,
          state: state,
          bundleId: bundleId,
        );
      }

      final nextState = state.copyWith(
        ownedAssetIds: _appendUniqueIds(
          state.ownedAssetIds,
          localItemIds,
        ),
        ownedBundleIds: _appendUniqueId(state.ownedBundleIds, bundleId),
      );
      _markCloudMutation();
      final snapshot = _buildCloudSnapshot(resolvedScopeKey, nextState);
      await _applyConfirmedCloudSnapshot(
        scopeKey: resolvedScopeKey,
        snapshot: snapshot,
        traceId: traceId,
        stage: 'state_applied',
        nextItemId: bundleId,
      );
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
        walletCoins: result.walletCoinsAfter,
        bundleId: bundleId,
      );
    } on ShopCloudPurchaseException catch (error) {
      return _mapCloudBundlePurchaseFailure(
        error,
        bundleId: bundleId,
        currentState: state,
      );
    }
  }

  Future<ShopCosmeticsOperationResult> _equipAssetCloud(
    String assetId, {
    String? traceId,
  }) async {
    final scopeKey = _currentScope();
    traceId ??= _newTraceId('tap');
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
    final equipSlot = _resolveEquipSlot(asset);
    final previousItemId = state.getEquippedAssetIdForCategory(asset.category);
    try {
      _traceCloudCosmetics(
        'tap',
        traceId: traceId,
        userId: scopeKey,
        slot: equipSlot,
        previousItemId: previousItemId,
        nextItemId: assetId,
        assetPath: asset.assetPath,
        state: state,
      );
      _traceCloudCosmetics(
        'rpc_start',
        traceId: traceId,
        userId: scopeKey,
        slot: equipSlot,
        previousItemId: previousItemId,
        nextItemId: assetId,
        assetPath: asset.assetPath,
        state: state,
        note: 'requestId=$requestId',
      );
      final rpcResult = await _cloudRepository.equipAsset(
        itemId: assetId,
        slot: equipSlot,
        requestId: requestId,
      );
      _traceCloudCosmetics(
        'rpc_success',
        traceId: traceId,
        userId: scopeKey,
        slot: equipSlot,
        previousItemId: previousItemId,
        nextItemId: assetId,
        assetPath: asset.assetPath,
        state: state,
        note:
            'operation=${rpcResult.operation} requestId=${rpcResult.requestId}',
      );
      if (_currentScope() != scopeKey) {
        return _cloudFailureResult(
          status: ShopCosmeticsOperationStatus.bundleNotFound,
          assetId: assetId,
        );
      }
      final resolvedScopeKey = scopeKey ?? _currentScope();
      if (resolvedScopeKey == null) {
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
      _markCloudMutation();
      final snapshot = _buildCloudSnapshot(resolvedScopeKey, nextState);
      await _applyConfirmedCloudSnapshot(
        scopeKey: resolvedScopeKey,
        snapshot: snapshot,
        traceId: traceId,
        stage: 'state_applied',
        slot: equipSlot,
        previousItemId: previousItemId,
        nextItemId: assetId,
        assetPath: asset.assetPath,
      );
      unawaited(_syncFromCurrentScope(force: true));
      return ShopCosmeticsOperationResult(
        status: ShopCosmeticsOperationStatus.success,
        state: nextState,
        walletCoins: await _walletCoins(),
        assetId: assetId,
      );
    } on ShopCloudEquipException catch (error) {
      _traceCloudCosmetics(
        'rpc_error',
        traceId: traceId,
        userId: scopeKey,
        slot: equipSlot,
        previousItemId: previousItemId,
        nextItemId: assetId,
        assetPath: asset.assetPath,
        state: state,
        note:
            'code=${error.code.name} retryable=${error.retryable} definitive=${error.definitive}',
      );
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
    final traceId = _newTraceId('tap');
    final state = await _combinedCloudState();
    final slot = switch (category) {
      ShopAssetCategory.wallpaper => CosmeticSlot.background.remoteDbKey,
      ShopAssetCategory.habitCard => CosmeticSlot.habitCard.remoteDbKey,
      ShopAssetCategory.userCard => CosmeticSlot.userCard.remoteDbKey,
    };
    final previousItemId = state.getEquippedAssetIdForCategory(category);
    final nextState = switch (category) {
      ShopAssetCategory.wallpaper => state.copyWith(equippedWallpaperId: null),
      ShopAssetCategory.habitCard =>
        state.copyWith(equippedHabitCardSkinId: null),
      ShopAssetCategory.userCard =>
        state.copyWith(equippedUserCardSkinId: null),
    };
    if (_currentScope() != scopeKey) {
      return _cloudFailureResult(
          status: ShopCosmeticsOperationStatus.bundleNotFound);
    }
    final resolvedScopeKey = scopeKey ?? _currentScope();
    if (resolvedScopeKey == null) {
      return _cloudFailureResult(
        status: ShopCosmeticsOperationStatus.bundleNotFound,
      );
    }
    _markCloudMutation();
    final snapshot = _buildCloudSnapshot(resolvedScopeKey, nextState);
    await _applyConfirmedCloudSnapshot(
      scopeKey: resolvedScopeKey,
      snapshot: snapshot,
      traceId: traceId,
      stage: 'state_applied',
      slot: slot,
      previousItemId: previousItemId,
      nextItemId: null,
    );
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

  Future<ShopCosmeticsOperationResult> _mapCloudBundlePurchaseFailure(
    ShopCloudPurchaseException error, {
    required String bundleId,
    required ShopCosmeticsState currentState,
  }) async {
    final status = switch (error.code) {
      ShopPurchaseFailureCode.bundleAlreadyOwned =>
        ShopCosmeticsOperationStatus.alreadyOwned,
      ShopPurchaseFailureCode.bundleContainsOwnedItems =>
        ShopCosmeticsOperationStatus.bundleContainsOwnedAssets,
      ShopPurchaseFailureCode.insufficientFunds =>
        ShopCosmeticsOperationStatus.insufficientCoins,
      ShopPurchaseFailureCode.bundleNotFoundOrInactive ||
      ShopPurchaseFailureCode.bundleConfigurationInvalid ||
      ShopPurchaseFailureCode.bundleIdRequired ||
      ShopPurchaseFailureCode.requestIdConflict ||
      ShopPurchaseFailureCode.walletNotFoundForUser ||
      ShopPurchaseFailureCode.authRequired ||
      ShopPurchaseFailureCode.unauthenticated ||
      ShopPurchaseFailureCode.featureDisabled ||
      ShopPurchaseFailureCode.walletNotInitialized ||
      ShopPurchaseFailureCode.cloudWalletMissing ||
      ShopPurchaseFailureCode.networkUnavailable ||
      ShopPurchaseFailureCode.timeout ||
      ShopPurchaseFailureCode.malformedResponse ||
      ShopPurchaseFailureCode.unknown =>
        ShopCosmeticsOperationStatus.bundleNotFound,
      _ => ShopCosmeticsOperationStatus.bundleNotFound,
    };

    return ShopCosmeticsOperationResult(
      status: status,
      state: currentState,
      walletCoins: await _walletCoins(),
      bundleId: bundleId,
    );
  }

  bool _bundleContainsOwnedAssets(
    ShopCosmeticsState state,
    ShopBundle bundle,
  ) {
    for (final assetId in bundle.assetIds) {
      if (state.isAssetOwned(assetId, bundles: ShopAssetsCatalog.allBundles)) {
        return true;
      }
    }
    return false;
  }

  List<String> _appendUniqueId(List<String> values, String value) {
    final next = <String>[...values];
    if (!next.contains(value)) {
      next.add(value);
    }
    return next;
  }

  List<String> _appendUniqueIds(
      List<String> values, Iterable<String> additions) {
    final next = <String>[...values];
    for (final value in additions) {
      if (next.contains(value)) continue;
      next.add(value);
    }
    return next;
  }

  Future<ShopCosmeticsOperationResult> _mapCloudEquipFailure(
    ShopCloudEquipException error, {
    required String assetId,
    required ShopCosmeticsState currentState,
  }) async {
    final status = switch (error.code) {
      ShopCosmeticsOperationFailureCode.itemNotOwned =>
        ShopCosmeticsOperationStatus.assetNotOwned,
      ShopCosmeticsOperationFailureCode.itemNotFound ||
      ShopCosmeticsOperationFailureCode.itemInactive =>
        ShopCosmeticsOperationStatus.assetNotFound,
      ShopCosmeticsOperationFailureCode.itemNotEquippable ||
      ShopCosmeticsOperationFailureCode.invalidEquipSlot =>
        ShopCosmeticsOperationStatus.bundleNotFound,
      ShopCosmeticsOperationFailureCode.unauthenticated ||
      ShopCosmeticsOperationFailureCode.requestConflict ||
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

    final generation = ++_cloudRefreshGeneration;
    final traceId = _newTraceId(force ? 'runtime_refresh' : 'cold_start');
    _log(
      '[shop_cloud_cosmetics] refresh_started generation=$generation '
      'scope=$scopeKey force=$force',
    );
    _traceCloudCosmetics(
      'home_build',
      traceId: traceId,
      userId: scopeKey,
      generation: generation,
      state: _cachedState,
      assetPath: _cachedState == null
          ? null
          : _getValidatedEquippedAssetOrNull(
              _cachedState!,
              ShopAssetCategory.wallpaper,
            )?.assetPath,
      note: force ? 'runtime_sync' : 'cold_start_sync',
    );
    final pending = _pendingCloudStateLoad;
    if (!force && pending != null && _cachedScopeKey == scopeKey) {
      return pending;
    }

    late final Future<ShopCosmeticsState> future;
    future = _loadCloudState(
      scopeKey: scopeKey,
      force: force,
      generation: generation,
      traceId: traceId,
    ).whenComplete(() {
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
    required int generation,
    required String traceId,
  }) async {
    final mutationVersion = _cloudMutationVersion;
    final cacheEntry = await _cloudCache.read(scopeKey);

    if (_isStaleCloudLoad(scopeKey, mutationVersion)) {
      _log(
        '[shop_cloud_cosmetics] stale_refresh_ignored generation=$generation '
        'scope=$scopeKey stage=cache',
      );
      return _cachedState ?? const ShopCosmeticsState.initial();
    }

    if (cacheEntry != null && !force) {
      if (_isStaleCloudLoad(scopeKey, mutationVersion)) {
        _log(
          '[shop_cloud_cosmetics] stale_refresh_ignored generation=$generation '
          'scope=$scopeKey stage=cache_hit',
        );
        return _cachedState ?? const ShopCosmeticsState.initial();
      }
      _setCloudState(
        ShopCosmeticsCloudState.loading(userId: scopeKey, cache: cacheEntry),
      );
      if (!_isStaleCloudLoad(scopeKey, mutationVersion)) {
        _setCachedState(
          cacheEntry.snapshot.toState(),
          scopeKey: scopeKey,
          shouldNotifyListeners: false,
        );
      }
    } else if (cacheEntry == null) {
      if (_isStaleCloudLoad(scopeKey, mutationVersion)) {
        _log(
          '[shop_cloud_cosmetics] stale_refresh_ignored generation=$generation '
          'scope=$scopeKey stage=no_cache',
        );
        return _cachedState ?? const ShopCosmeticsState.initial();
      }
      _setCloudState(ShopCosmeticsCloudState.loading(userId: scopeKey));
    }

    final result = await _cloudRepository.fetchSnapshot();
    final fetchCompletedAt = DateTime.now().toUtc();
    if (_isStaleCloudLoad(scopeKey, mutationVersion)) {
      _log(
        '[shop_cloud_cosmetics] stale_refresh_ignored generation=$generation '
        'scope=$scopeKey stage=fetch',
      );
      return _cachedState ?? const ShopCosmeticsState.initial();
    }

    if (!result.isSuccess || result.data == null) {
      final failureMessage =
          result.error?.message ?? 'Could not fetch cloud cosmetics.';
      if (cacheEntry != null) {
        final currentSnapshot = _cloudState.snapshot;
        if (currentSnapshot != null) {
          final comparison = compareCloudCosmeticsSnapshots(
              currentSnapshot, cacheEntry.snapshot);
          if (comparison.isNewerOrEqual) {
            _lastTraceId = traceId;
            _traceCloudCosmetics(
              'state_applied',
              traceId: traceId,
              userId: scopeKey,
              snapshot: currentSnapshot,
              state: _cachedState,
              generation: generation,
              note: 'refresh_failed_preserve_confirmed',
            );
            _traceCloudCosmetics(
              'notify',
              traceId: traceId,
              userId: scopeKey,
              snapshot: currentSnapshot,
              state: _cachedState,
              generation: generation,
              note: 'refresh_failed_preserve_confirmed',
            );
            super.notifyListeners();
            _log(
              '[shop_cloud_cosmetics] refresh_failed generation=$generation '
              'scope=$scopeKey source=preserve_confirmed',
            );
            return _cachedState ?? currentSnapshot.toState();
          }
        }
        _setCloudState(
          ShopCosmeticsCloudState.stale(
            userId: scopeKey,
            cache: cacheEntry,
            failureMessage: failureMessage,
          ),
        );
        final restored = cacheEntry.snapshot.toState();
        _cachedState = restored;
        _cachedScopeKey = scopeKey;
        _cloudSnapshotRevision += 1;
        _lastTraceId = traceId;
        _traceCloudCosmetics(
          'state_applied',
          traceId: traceId,
          userId: scopeKey,
          snapshot: cacheEntry.snapshot,
          state: restored,
          generation: generation,
          note: 'stale_cache_restore',
        );
        _traceCloudCosmetics(
          'notify',
          traceId: traceId,
          userId: scopeKey,
          snapshot: cacheEntry.snapshot,
          state: restored,
          generation: generation,
          note: 'stale_cache_restore',
        );
        super.notifyListeners();
        _log(
          '[shop_cloud_cosmetics] refresh_applied generation=$generation '
          'scope=$scopeKey source=cache stale=true',
        );
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
      final fallback = const ShopCosmeticsState.initial();
      _setCachedState(fallback,
          scopeKey: scopeKey, shouldNotifyListeners: true);
      _log(
        '[shop_cloud_cosmetics] refresh_applied generation=$generation '
        'scope=$scopeKey source=fallback stale=false',
      );
      return fallback;
    }

    final snapshot = result.data!;
    final currentSnapshot = _cloudState.snapshot;
    if (currentSnapshot != null) {
      final comparison =
          compareCloudCosmeticsSnapshots(snapshot, currentSnapshot);
      if (!comparison.isNewerOrEqual) {
        _traceCloudCosmetics(
          'state_applied',
          traceId: traceId,
          userId: scopeKey,
          snapshot: snapshot,
          state: _cachedState,
          generation: generation,
          fetchCompletedAt: fetchCompletedAt,
          note: 'ignored_older_snapshot',
        );
        return _cachedState ?? snapshot.toState();
      }
    }
    final combinedState = snapshot.toState();
    await _applyConfirmedCloudSnapshot(
      scopeKey: scopeKey,
      snapshot: snapshot,
      traceId: traceId,
      stage: 'state_applied',
      notify: true,
      saveCache: true,
    );
    _traceCloudCosmetics(
      'home_build',
      traceId: traceId,
      userId: scopeKey,
      snapshot: snapshot,
      state: combinedState,
      generation: generation,
      fetchCompletedAt: fetchCompletedAt,
      note: 'remote_applied',
    );
    _log(
      '[shop_cloud_cosmetics] refresh_applied generation=$generation '
      'scope=$scopeKey source=remote stale=false',
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

  bool _isStaleCloudLoad(String scopeKey, int mutationVersion) {
    return _currentScope() != scopeKey ||
        mutationVersion != _cloudMutationVersion;
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

  String _resolveEquipSlot(ShopAsset asset) {
    final catalogSlot =
        ShopCatalog.getItemById(asset.id)?.cosmeticSlot?.remoteDbKey;
    if (catalogSlot != null && catalogSlot.isNotEmpty) {
      return catalogSlot;
    }

    final assetSlot = asset.cosmeticSlot?.remoteDbKey;
    if (assetSlot != null && assetSlot.isNotEmpty) {
      return assetSlot;
    }

    final fallback = switch (asset.category) {
      ShopAssetCategory.wallpaper => CosmeticSlot.background,
      ShopAssetCategory.habitCard => CosmeticSlot.habitCard,
      ShopAssetCategory.userCard => CosmeticSlot.userCard,
    };
    return fallback.remoteDbKey;
  }

  CloudCosmeticsSnapshot _buildCloudSnapshot(
    String scopeKey,
    ShopCosmeticsState state,
  ) {
    final now = DateTime.now().toUtc();
    return CloudCosmeticsSnapshot(
      userId: scopeKey,
      ownedAssetIds: state.ownedAssetIds,
      ownedBundleIds: state.ownedBundleIds,
      equippedWallpaperId: state.equippedWallpaperId,
      equippedHabitCardSkinId: state.equippedHabitCardSkinId,
      equippedUserCardSkinId: state.equippedUserCardSkinId,
      catalogVersion: _cloudState.snapshot?.catalogVersion,
      fetchedAt: now,
      updatedAt: now,
    );
  }

  void _markCloudMutation() {
    _cloudMutationVersion += 1;
  }

  Future<ShopCosmeticsState> _applyConfirmedCloudSnapshot({
    required String scopeKey,
    required CloudCosmeticsSnapshot snapshot,
    required String traceId,
    required String stage,
    String? slot,
    String? previousItemId,
    String? nextItemId,
    String? assetPath,
    bool notify = true,
    bool saveCache = true,
  }) async {
    _lastTraceId = traceId;
    final nextState = snapshot.toState();
    _cloudSnapshotRevision += 1;
    _cachedState = nextState;
    _cachedScopeKey = scopeKey;
    if (saveCache) {
      unawaited(_cloudCache.save(snapshot));
    }
    _cloudState = ShopCosmeticsCloudState.ready(
      userId: scopeKey,
      snapshot: snapshot,
      cache: _cloudState.cachedEntry,
    );
    _traceCloudCosmetics(
      stage,
      traceId: traceId,
      userId: scopeKey,
      slot: slot,
      previousItemId: previousItemId,
      nextItemId: nextItemId,
      snapshot: snapshot,
      state: nextState,
      assetPath: assetPath,
    );
    if (notify) {
      _traceCloudCosmetics(
        'notify',
        traceId: traceId,
        userId: scopeKey,
        slot: slot,
        previousItemId: previousItemId,
        nextItemId: nextItemId,
        snapshot: snapshot,
        state: nextState,
        assetPath: assetPath,
      );
      super.notifyListeners();
    }
    return nextState;
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

  String _newTraceId(String stage) {
    return '$stage-${DateTime.now().microsecondsSinceEpoch}';
  }

  void _traceCloudCosmetics(
    String stage, {
    String? traceId,
    String? userId,
    String? slot,
    String? previousItemId,
    String? nextItemId,
    CloudCosmeticsSnapshot? snapshot,
    ShopCosmeticsState? state,
    String? assetPath,
    int? generation,
    DateTime? fetchStartedAt,
    DateTime? fetchCompletedAt,
    String? note,
  }) {
    if (!kDebugMode) return;
    debugPrint(
      '[cosmetic_trace] stage=$stage '
      'traceId=${traceId ?? _lastTraceId ?? 'none'} '
      'userId=${userId ?? _currentScope() ?? 'none'} '
      'slot=${slot ?? 'none'} '
      'prev=${previousItemId ?? 'none'} '
      'next=${nextItemId ?? 'none'} '
      'revision=$_cloudSnapshotRevision '
      'controllerHash=${identityHashCode(this)} '
      'repositoryHash=${identityHashCode(_repository)} '
      'snapshotHash=${snapshot == null ? 'none' : identityHashCode(snapshot)} '
      'assetPath=${assetPath ?? 'none'} '
      'generation=${generation ?? _cloudRefreshGeneration} '
      'fetchStartedAt=${fetchStartedAt?.toIso8601String() ?? 'none'} '
      'fetchCompletedAt=${fetchCompletedAt?.toIso8601String() ?? 'none'} '
      'stateEquipped=${state == null ? 'none' : _describeEquipped(state)} '
      '${note == null ? '' : 'note=$note'}',
    );
  }

  String _describeEquipped(ShopCosmeticsState state) {
    return 'wallpaper=${state.equippedWallpaperId} '
        'habitCard=${state.equippedHabitCardSkinId} '
        'userCard=${state.equippedUserCardSkinId}';
  }

  void _setCachedState(
    ShopCosmeticsState state, {
    String? scopeKey,
    bool shouldNotifyListeners = true,
  }) {
    _cachedState = state;
    _cachedScopeKey = scopeKey ?? _currentScope();
    if (shouldNotifyListeners) {
      _log('[shop_cloud_equip] notify_listeners');
      super.notifyListeners();
    }
  }
}
