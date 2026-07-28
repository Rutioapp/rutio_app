import 'package:rutio/features/shop/domain/models/shop_bundle.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rutio/features/global_wallet/application/global_wallet_controller.dart';
import 'package:rutio/features/shop/application/shop_cosmetics_service.dart';
import 'package:rutio/features/shop/data/cloud/cloud_cosmetics_cache.dart';
import 'package:rutio/features/shop/data/cloud/cloud_cosmetics_config.dart';
import 'package:rutio/features/shop/data/cloud/cloud_cosmetics_request_id.dart';
import 'package:rutio/features/shop/data/cloud/cloud_cosmetics_snapshot.dart';
import 'package:rutio/features/shop/data/cloud/pending_cloud_cosmetics_purchase_store.dart';
import 'package:rutio/features/shop/data/cloud/shop_cosmetics_catalog_resolver.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_dtos.dart';
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
import 'package:rutio/features/shop/domain/models/shop_bundle_completion_quote.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_operation_result.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_state.dart';
import 'package:rutio/features/shop/domain/models/pending_cloud_cosmetics_purchase.dart';
import 'package:rutio/features/shop/domain/pending_cloud_cosmetics_purchase_store.dart';
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

enum _CloudEquipOperationPhase {
  processing,
  awaitingResolution,
  success,
  definitiveFailure,
}

class _CloudEquipOperation {
  const _CloudEquipOperation({
    required this.slot,
    required this.assetId,
    required this.requestId,
    required this.phase,
  });

  final String slot;
  final String assetId;
  final String requestId;
  final _CloudEquipOperationPhase phase;

  _CloudEquipOperation copyWith({
    _CloudEquipOperationPhase? phase,
  }) {
    return _CloudEquipOperation(
      slot: slot,
      assetId: assetId,
      requestId: requestId,
      phase: phase ?? this.phase,
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
    PendingCloudCosmeticsPurchaseStore? pendingPurchaseStore,
    String Function()? requestIdGenerator,
    DateTime Function()? nowProvider,
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
        _pendingPurchaseStore = pendingPurchaseStore ??
            SharedPreferencesPendingCloudCosmeticsPurchaseStore(),
        _requestIdGenerator =
            requestIdGenerator ?? CloudCosmeticsRequestId.generateV4,
        _nowProvider = nowProvider ?? DateTime.now,
        _cloudEnabled =
            CloudCosmeticsConfig.resolveEnabled(override: cloudEnabled) {
    _userStateStore.addListener(_handleUserStateStoreChanged);
    _globalWalletController?.addListener(_handleGlobalWalletChanged);
    if (_cloudEnabled) {
      unawaited(_syncFromCurrentScope(force: false));
    }
  }

  final UserStateStore _userStateStore;
  final GlobalWalletController? _globalWalletController;
  final ShopCosmeticsRepository _repository;
  final CloudCosmeticsRepository _cloudRepository;
  final CloudCosmeticsCache _cloudCache;
  final PendingCloudCosmeticsPurchaseStore _pendingPurchaseStore;
  final String Function() _requestIdGenerator;
  final DateTime Function() _nowProvider;
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
  final Set<String> _busyBundleEquipIds = <String>{};
  final Set<String> _awaitingResolutionPurchaseKeys = <String>{};
  final Map<String, Future<ShopCosmeticsOperationResult>>
      _activeCloudEquipBySlot =
      <String, Future<ShopCosmeticsOperationResult>>{};
  final Map<String, _CloudEquipOperation> _cloudEquipOperationsBySlot =
      <String, _CloudEquipOperation>{};
  final Map<String, Future<ShopCosmeticsOperationResult>>
      _activeCloudPurchasesByKey =
      <String, Future<ShopCosmeticsOperationResult>>{};
  Future<List<ShopCosmeticsOperationResult>>? _pendingPurchaseResolution;
  bool _isDisposed = false;
  final ShopCosmeticsCatalogResolver _catalogResolver =
      const ShopCosmeticsCatalogResolver();

  ShopCosmeticsState? get state => _cachedState;
  ShopCosmeticsCloudState get cloudState => _cloudState;
  int get cloudSnapshotRevision => _cloudSnapshotRevision;
  String? get lastTraceId => _lastTraceId;
  bool get isCloudEnabled => _cloudEnabled;

  bool isCloudAssetPurchaseAwaitingResolution(String assetId) {
    return _awaitingResolutionPurchaseKeys.contains(
      PendingCloudCosmeticsPurchase.logicalKeyFor(
        operationType: PendingCloudCosmeticsPurchaseType.cosmeticPurchase,
        resourceId: assetId,
      ),
    );
  }

  bool isCloudBundlePurchaseAwaitingResolution(String bundleId) {
    return _awaitingResolutionPurchaseKeys.contains(
      PendingCloudCosmeticsPurchase.logicalKeyFor(
        operationType: PendingCloudCosmeticsPurchaseType.bundlePurchase,
        resourceId: bundleId,
      ),
    );
  }

  bool isCloudAssetEquipProcessing(String assetId) {
    if (!_cloudEnabled) return false;
    final asset = _catalogAssetById(assetId);
    if (asset == null) return false;
    final operation = _cloudEquipOperationsBySlot[_resolveEquipSlot(asset)];
    return operation?.assetId == assetId &&
        operation?.phase == _CloudEquipOperationPhase.processing;
  }

  bool isCloudAssetEquipAwaitingResolution(String assetId) {
    if (!_cloudEnabled) return false;
    final asset = _catalogAssetById(assetId);
    if (asset == null) return false;
    final operation = _cloudEquipOperationsBySlot[_resolveEquipSlot(asset)];
    return operation?.assetId == assetId &&
        operation?.phase == _CloudEquipOperationPhase.awaitingResolution;
  }

  bool isCloudAssetEquipSlotBusy(String assetId) {
    if (!_cloudEnabled) return false;
    final asset = _catalogAssetById(assetId);
    if (asset == null) return false;
    final operation = _cloudEquipOperationsBySlot[_resolveEquipSlot(asset)];
    return operation?.phase == _CloudEquipOperationPhase.processing ||
        operation?.phase == _CloudEquipOperationPhase.awaitingResolution;
  }

  int get visibleWalletCoins {
    final globalWalletController = _globalWalletController;
    if (globalWalletController != null && globalWalletController.isEnabled) {
      return globalWalletController.state.coins ?? 0;
    }

    final root = _userStateStore.state;
    if (root == null) return 0;
    final userState = (root['userState'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    final wallet = (userState['wallet'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    return ((wallet['coins'] as num?) ?? 0).toInt();
  }

  ShopResolvedCosmeticsCatalog get resolvedCatalog {
    if (!_cloudEnabled) {
      return ShopResolvedCosmeticsCatalog(
        assets: List<ShopAsset>.unmodifiable(ShopAssetsCatalog.allAssets),
        bundles: List<ShopBundle>.unmodifiable(ShopAssetsCatalog.allBundles),
      );
    }

    final snapshot = _cloudState.snapshot;
    final scopeKey = _currentScope();
    if (scopeKey == null ||
        snapshot == null ||
        _cloudState.userId != scopeKey) {
      return const ShopResolvedCosmeticsCatalog.empty();
    }

    return _catalogResolver.resolve(
      localAssets: ShopAssetsCatalog.allAssets,
      localBundles: ShopAssetsCatalog.allBundles,
      remoteItems: snapshot.catalogItems,
      remoteBundles: snapshot.catalogBundles,
      remoteBundleItems: snapshot.catalogBundleItems,
    );
  }

  List<ShopAsset> get resolvedAssets => resolvedCatalog.assets;
  List<ShopBundle> get resolvedBundles => resolvedCatalog.bundles;

  ShopAsset? _catalogAssetById(String assetId) {
    for (final asset in _catalogAssets()) {
      if (asset.id == assetId) {
        return asset;
      }
    }
    return null;
  }

  ShopBundle? _catalogBundleById(String bundleId) {
    for (final bundle in _catalogBundles()) {
      if (bundle.id == bundleId) {
        return bundle;
      }
    }
    return null;
  }

  List<ShopAsset> _catalogAssets() {
    if (_cloudEnabled) {
      return resolvedAssets;
    }
    return ShopAssetsCatalog.allAssets;
  }

  List<ShopBundle> _catalogBundles() {
    if (_cloudEnabled) {
      return resolvedBundles;
    }
    return ShopAssetsCatalog.allBundles;
  }

  ShopBundle? _resolvedBundleById(String bundleId) {
    for (final bundle in resolvedBundles) {
      if (bundle.id == bundleId) {
        return bundle;
      }
    }
    return null;
  }

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
      if (_currentScope() != scopeKey) {
        return state;
      }
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

  Future<ShopCosmeticsState> refreshCloudState({bool force = false}) {
    if (_cloudEnabled) {
      return _syncFromCurrentScope(force: force);
    }
    return getState();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _userStateStore.removeListener(_handleUserStateStoreChanged);
    _globalWalletController?.removeListener(_handleGlobalWalletChanged);
    super.dispose();
  }

  void _handleGlobalWalletChanged() {
    if (_globalWalletController == null) return;
    notifyListeners();
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
      final asset = _catalogAssetById(assetId);
      if (asset == null) return false;
      if (state.isAssetOwned(assetId, bundles: _catalogBundles())) {
        return false;
      }
      final walletCoins = await _walletCoins();
      return walletCoins >= asset.priceAmber;
    }

    final service = await _service();
    return service.canPurchaseAsset(assetId);
  }

  Future<bool> canPurchaseBundle(String bundleId) async {
    if (_cloudEnabled) {
      final state = await _combinedCloudState();
      final bundle = _catalogBundleById(bundleId);
      if (bundle == null) return false;
      final quote = ShopBundleCompletionQuote.tryCreate(
        bundle: bundle,
        state: state,
        catalogAssets: resolvedAssets,
        catalogBundles: resolvedBundles,
      );
      if (quote == null) return false;
      if (quote.isExplicitlyOwned || quote.missingItemCount == 0) return false;
      final walletCoins = await _walletCoins();
      return walletCoins >= quote.effectivePriceAmber;
    }

    final service = await _service();
    return service.canPurchaseBundle(bundleId);
  }

  Future<bool> isAssetOwned(String assetId) async {
    if (_cloudEnabled) {
      final state = await _combinedCloudState();
      return state.isAssetOwned(assetId, bundles: _catalogBundles());
    }

    final service = await _service();
    return service.isAssetOwned(assetId);
  }

  Future<bool> isBundleOwned(String bundleId) async {
    if (_cloudEnabled) {
      final state = await _combinedCloudState();
      return state.isBundleOwned(bundleId);
    }

    final service = await _service();
    return service.isBundleOwned(bundleId);
  }

  Future<bool> isBundlePartiallyOwned(String bundleId) async {
    if (_cloudEnabled) {
      final state = await _combinedCloudState();
      final bundle = _catalogBundleById(bundleId);
      if (bundle == null) return false;
      final quote = ShopBundleCompletionQuote.tryCreate(
        bundle: bundle,
        state: state,
        catalogAssets: resolvedAssets,
        catalogBundles: resolvedBundles,
      );
      return quote?.isPartiallyOwned ?? false;
    }

    final service = await _service();
    return service.isBundlePartiallyOwned(bundleId);
  }

  Future<ShopAssetOwnershipState> assetOwnershipState(String assetId) async {
    if (_cloudEnabled) {
      final state = await _combinedCloudState();
      final asset = _catalogAssetById(assetId);
      if (asset == null) return ShopAssetOwnershipState.locked;
      return state.assetOwnershipState(
        asset,
        bundles: _catalogBundles(),
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

  Future<ShopCosmeticsOperationResult> equipBundle(String bundleId) async {
    if (_busyBundleEquipIds.contains(bundleId)) {
      return _cloudFailureResult(
        status: ShopCosmeticsOperationStatus.bundleNotFound,
        bundleId: bundleId,
        walletCoins: await _walletCoins(),
      );
    }

    _busyBundleEquipIds.add(bundleId);
    try {
      if (_cloudEnabled) {
        return _equipBundleCloud(bundleId);
      }

      final service = await _service();
      final result = service.equipBundle(bundleId);
      _log(
        'equipBundle bundleId=$bundleId success=${result.isSuccess} '
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
    } finally {
      _busyBundleEquipIds.remove(bundleId);
    }
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
    final currentScope = _currentScope();
    final previousScope = _cachedScopeKey;
    _log('session_changed user=${currentScope != null}');
    if (currentScope == null) {
      _log('scope_changed from=${_debugScope(previousScope)} to=guest');
      _markCloudMutation();
      _cachedState = null;
      _cachedScopeKey = null;
      _pendingStateLoad = null;
      _pendingCloudStateLoad = null;
      _activeCloudEquipBySlot.clear();
      _cloudEquipOperationsBySlot.clear();
      if (_cloudEnabled) {
        _cloudState = ShopCosmeticsCloudState.unauthenticated();
      }
      notifyListeners();
      return;
    }

    if (_cachedScopeKey == currentScope) {
      return;
    }

    _log(
      'scope_changed from=${_debugScope(previousScope)} '
      'to=${_debugScope(currentScope)}',
    );
    _markCloudMutation();
    _cachedState = null;
    _cachedScopeKey = null;
    _pendingStateLoad = null;
    _pendingCloudStateLoad = null;
    _activeCloudEquipBySlot.clear();
    _cloudEquipOperationsBySlot.clear();

    if (!_cloudEnabled) {
      notifyListeners();
      return;
    }

    _cloudState = ShopCosmeticsCloudState.loading(userId: currentScope);
    unawaited(_syncFromCurrentScope(force: true));
  }

  void _setCloudState(ShopCosmeticsCloudState state) {
    if (_isDisposed) return;
    _cloudState = state;
    notifyListeners();
  }

  Future<ShopCosmeticsOperationResult> _purchaseAssetCloud(
    String assetId, {
    bool resolvingPending = false,
    bool refreshAfterSuccess = true,
  }) async {
    final activeKey = PendingCloudCosmeticsPurchase.logicalKeyFor(
      operationType: PendingCloudCosmeticsPurchaseType.cosmeticPurchase,
      resourceId: assetId,
    );
    if (!resolvingPending) {
      final active = _activeCloudPurchasesByKey[activeKey];
      if (active != null) return active;
      late final Future<ShopCosmeticsOperationResult> future;
      future = _purchaseAssetCloud(
        assetId,
        resolvingPending: true,
        refreshAfterSuccess: refreshAfterSuccess,
      ).whenComplete(() {
        if (identical(_activeCloudPurchasesByKey[activeKey], future)) {
          _activeCloudPurchasesByKey.remove(activeKey);
        }
      });
      _activeCloudPurchasesByKey[activeKey] = future;
      return future;
    }

    final scopeKey = _currentScope();
    final traceId = _newTraceId('tap');
    final state = await _combinedCloudState();
    if (scopeKey == null) {
      return _cloudFailureResult(
        status: ShopCosmeticsOperationStatus.bundleNotFound,
        state: state,
        assetId: assetId,
      );
    }
    final asset = _catalogAssetById(assetId);
    if (asset == null) {
      return _cloudFailureResult(
        status: ShopCosmeticsOperationStatus.assetNotFound,
        state: state,
        assetId: assetId,
      );
    }
    final existingPending = await _pendingPurchaseFor(
      userId: scopeKey,
      operationType: PendingCloudCosmeticsPurchaseType.cosmeticPurchase,
      resourceId: assetId,
    );
    if (state.isAssetOwned(assetId, bundles: _catalogBundles())) {
      if (existingPending != null) {
        await _removePendingPurchase(scopeKey, existingPending.logicalKey);
        return ShopCosmeticsOperationResult(
          status: ShopCosmeticsOperationStatus.success,
          state: state,
          walletCoins: await _walletCoins(),
          assetId: assetId,
        );
      }
      return _cloudFailureResult(
        status: ShopCosmeticsOperationStatus.alreadyOwned,
        state: state,
        assetId: assetId,
      );
    }

    final pendingPurchase = await _ensurePendingPurchase(
      userId: scopeKey,
      operationType: PendingCloudCosmeticsPurchaseType.cosmeticPurchase,
      resourceId: assetId,
      existing: existingPending,
    );
    final requestId = pendingPurchase.requestId;
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
      if (_isDisposed) {
        await _removePendingPurchase(scopeKey, pendingPurchase.logicalKey);
        return ShopCosmeticsOperationResult(
          status: ShopCosmeticsOperationStatus.success,
          state: state,
          walletCoins: result.coins,
          assetId: assetId,
        );
      }
      final nextState = state.copyWith(
        ownedAssetIds: <String>[...state.ownedAssetIds, assetId],
      );
      _markCloudMutation();
      final snapshot = _buildCloudSnapshot(scopeKey, nextState);
      await _applyConfirmedCloudSnapshot(
        scopeKey: scopeKey,
        snapshot: snapshot,
        traceId: traceId,
        stage: 'state_applied',
        nextItemId: assetId,
      );
      if (_globalWalletController?.isEnabled == true) {
        await _globalWalletController!.applyConfirmedBalance(
          userId: scopeKey,
          coins: result.coins,
          version: result.walletVersion,
          updatedAt: DateTime.now().toUtc(),
        );
      }
      await _removePendingPurchase(scopeKey, pendingPurchase.logicalKey);
      if (refreshAfterSuccess) {
        unawaited(_syncFromCurrentScope(force: true));
      }
      final currentUserId = _currentScope();
      if (currentUserId != null) {
        unawaited(
          _globalWalletController?.syncSession(
            userId: currentUserId,
            force: true,
          ),
        );
      }
      return ShopCosmeticsOperationResult(
        status: ShopCosmeticsOperationStatus.success,
        state: nextState,
        walletCoins: result.coins,
        assetId: assetId,
      );
    } on ShopCloudPurchaseException catch (error) {
      final reconciled = await _tryReconcileAlreadyPurchasedAsset(
        error,
        userId: scopeKey,
        assetId: assetId,
        pending: pendingPurchase,
      );
      if (reconciled != null) return reconciled;

      if (_shouldKeepPendingAfterPurchaseError(error)) {
        await _markPendingPurchaseAwaiting(
          pendingPurchase,
          failureCode: error.code.name,
        );
        return ShopCosmeticsOperationResult(
          status: ShopCosmeticsOperationStatus.awaitingResolution,
          state: state,
          walletCoins: await _walletCoins(),
          assetId: assetId,
        );
      }
      await _removePendingPurchase(scopeKey, pendingPurchase.logicalKey);
      return _mapCloudPurchaseFailure(
        error,
        assetId: assetId,
        currentState: state,
      );
    }
  }

  Future<ShopCosmeticsOperationResult> _purchaseBundleCloud(
    String bundleId, {
    bool resolvingPending = false,
    bool refreshAfterSuccess = true,
  }) async {
    final activeKey = PendingCloudCosmeticsPurchase.logicalKeyFor(
      operationType: PendingCloudCosmeticsPurchaseType.bundlePurchase,
      resourceId: bundleId,
    );
    if (!resolvingPending) {
      final active = _activeCloudPurchasesByKey[activeKey];
      if (active != null) return active;
      late final Future<ShopCosmeticsOperationResult> future;
      future = _purchaseBundleCloud(
        bundleId,
        resolvingPending: true,
        refreshAfterSuccess: refreshAfterSuccess,
      ).whenComplete(() {
        if (identical(_activeCloudPurchasesByKey[activeKey], future)) {
          _activeCloudPurchasesByKey.remove(activeKey);
        }
      });
      _activeCloudPurchasesByKey[activeKey] = future;
      return future;
    }

    final scopeKey = _currentScope();
    final traceId = _newTraceId('tap');
    final state = await _combinedCloudState();
    if (scopeKey == null) {
      return _cloudFailureResult(
        status: ShopCosmeticsOperationStatus.bundleNotFound,
        state: state,
        bundleId: bundleId,
      );
    }
    if (resolvedAssets.isEmpty || resolvedBundles.isEmpty) {
      return _cloudFailureResult(
        status: ShopCosmeticsOperationStatus.bundleNotFound,
        state: state,
        bundleId: bundleId,
      );
    }
    final bundle = _resolvedBundleById(bundleId);
    if (bundle == null) {
      return _cloudFailureResult(
        status: ShopCosmeticsOperationStatus.bundleNotFound,
        state: state,
        bundleId: bundleId,
      );
    }
    final quote = ShopBundleCompletionQuote.tryCreate(
      bundle: bundle,
      state: state,
      catalogAssets: resolvedAssets,
      catalogBundles: resolvedBundles,
    );
    if (quote == null) {
      return _cloudFailureResult(
        status: ShopCosmeticsOperationStatus.bundleNotFound,
        state: state,
        bundleId: bundleId,
      );
    }
    final existingPending = await _pendingPurchaseFor(
      userId: scopeKey,
      operationType: PendingCloudCosmeticsPurchaseType.bundlePurchase,
      resourceId: bundleId,
    );
    if (quote.isExplicitlyOwned) {
      if (existingPending != null) {
        await _removePendingPurchase(scopeKey, existingPending.logicalKey);
        return ShopCosmeticsOperationResult(
          status: ShopCosmeticsOperationStatus.success,
          state: state,
          walletCoins: await _walletCoins(),
          bundleId: bundleId,
        );
      }
      return _cloudFailureResult(
        status: ShopCosmeticsOperationStatus.alreadyOwned,
        state: state,
        bundleId: bundleId,
      );
    }

    final pendingPurchase = await _ensurePendingPurchase(
      userId: scopeKey,
      operationType: PendingCloudCosmeticsPurchaseType.bundlePurchase,
      resourceId: bundleId,
      existing: existingPending,
    );
    final requestId = pendingPurchase.requestId;
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
      if (_isDisposed) {
        await _removePendingPurchase(scopeKey, pendingPurchase.logicalKey);
        return ShopCosmeticsOperationResult(
          status: ShopCosmeticsOperationStatus.success,
          state: state,
          walletCoins: result.walletCoinsAfter,
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
        await _markPendingPurchaseAwaiting(
          pendingPurchase,
          failureCode: ShopPurchaseFailureCode.malformedResponse.name,
        );
        return ShopCosmeticsOperationResult(
          status: ShopCosmeticsOperationStatus.awaitingResolution,
          state: state,
          walletCoins: await _walletCoins(),
          bundleId: bundleId,
        );
      }

      final nextState = state.copyWith(
        ownedAssetIds: _appendUniqueIds(state.ownedAssetIds, localItemIds),
        ownedBundleIds: _appendUniqueId(state.ownedBundleIds, bundleId),
      );
      _markCloudMutation();
      final snapshot = _buildCloudSnapshot(scopeKey, nextState);
      await _applyConfirmedCloudSnapshot(
        scopeKey: scopeKey,
        snapshot: snapshot,
        traceId: traceId,
        stage: 'state_applied',
        nextItemId: bundleId,
      );
      if (_globalWalletController?.isEnabled == true) {
        await _globalWalletController!.applyConfirmedBalance(
          userId: scopeKey,
          coins: result.walletCoinsAfter,
          updatedAt: result.createdAt,
        );
      }
      await _removePendingPurchase(scopeKey, pendingPurchase.logicalKey);
      if (refreshAfterSuccess) {
        unawaited(_syncFromCurrentScope(force: true));
      }
      final currentUserId = _currentScope();
      if (currentUserId != null) {
        unawaited(
          _globalWalletController?.syncSession(
            userId: currentUserId,
            force: true,
          ),
        );
      }
      return ShopCosmeticsOperationResult(
        status: ShopCosmeticsOperationStatus.success,
        state: nextState,
        walletCoins: result.walletCoinsAfter,
        bundleId: bundleId,
      );
    } on ShopCloudPurchaseException catch (error) {
      final reconciled = await _tryReconcileAlreadyPurchasedBundle(
        error,
        userId: scopeKey,
        bundleId: bundleId,
        pending: pendingPurchase,
      );
      if (reconciled != null) return reconciled;

      if (_shouldKeepPendingAfterPurchaseError(error)) {
        await _markPendingPurchaseAwaiting(
          pendingPurchase,
          failureCode: error.code.name,
        );
        return ShopCosmeticsOperationResult(
          status: ShopCosmeticsOperationStatus.awaitingResolution,
          state: state,
          walletCoins: await _walletCoins(),
          bundleId: bundleId,
        );
      }
      await _removePendingPurchase(scopeKey, pendingPurchase.logicalKey);
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
    final state = await _combinedCloudState();
    final asset = _catalogAssetById(assetId);
    if (asset == null) {
      return _cloudFailureResult(
        status: ShopCosmeticsOperationStatus.assetNotFound,
        state: state,
        assetId: assetId,
      );
    }

    final owned = state.isAssetOwned(assetId, bundles: _catalogBundles());
    if (!owned) {
      return _cloudFailureResult(
        status: ShopCosmeticsOperationStatus.assetNotOwned,
        state: state,
        assetId: assetId,
      );
    }

    final previousItemId = state.getEquippedAssetIdForCategory(asset.category);
    final slot = _resolveEquipSlot(asset);
    final activeOperation = _cloudEquipOperationsBySlot[slot];
    final activeFuture = _activeCloudEquipBySlot[slot];
    if (activeOperation != null && activeFuture != null) {
      if (activeOperation.assetId == assetId) {
        return activeFuture;
      }
      return ShopCosmeticsOperationResult(
        status: ShopCosmeticsOperationStatus.awaitingResolution,
        state: state,
        walletCoins: await _walletCoins(),
        assetId: assetId,
      );
    }

    final operation = _CloudEquipOperation(
      slot: slot,
      assetId: assetId,
      requestId: _requestIdGenerator(),
      phase: _CloudEquipOperationPhase.processing,
    );
    _setCloudEquipOperation(operation);

    late final Future<ShopCosmeticsOperationResult> future;
    future = _runCloudEquipAssetIntent(
      asset: asset,
      initialState: state,
      traceId: traceId,
      scopeKey: scopeKey,
      previousItemId: previousItemId,
      operation: operation,
    ).whenComplete(() {
      if (identical(_activeCloudEquipBySlot[slot], future)) {
        _activeCloudEquipBySlot.remove(slot);
      }
      final currentOperation = _cloudEquipOperationsBySlot[slot];
      if (currentOperation?.requestId == operation.requestId) {
        _clearCloudEquipOperation(slot);
      }
    });
    _activeCloudEquipBySlot[slot] = future;
    return future;
  }

  Future<ShopCosmeticsOperationResult> _runCloudEquipAssetIntent({
    required ShopAsset asset,
    required ShopCosmeticsState initialState,
    required String traceId,
    required String? scopeKey,
    required String? previousItemId,
    required _CloudEquipOperation operation,
  }) async {
    try {
      final nextState = await _performCloudEquipAssetStep(
        asset: asset,
        state: initialState,
        traceId: traceId,
        scopeKey: scopeKey,
        previousItemId: previousItemId,
        requestId: operation.requestId,
      );
      if (_currentScope() != scopeKey || scopeKey == null) {
        return _cloudFailureResult(
          status: ShopCosmeticsOperationStatus.bundleNotFound,
          assetId: asset.id,
          walletCoins: await _walletCoins(),
        );
      }
      if (_isDisposed) {
        return ShopCosmeticsOperationResult(
          status: ShopCosmeticsOperationStatus.success,
          state: initialState,
          walletCoins: await _walletCoins(),
          assetId: asset.id,
        );
      }
      _setCloudEquipOperation(
        operation.copyWith(phase: _CloudEquipOperationPhase.success),
      );
      _markCloudMutation();
      final snapshot = _buildCloudSnapshot(scopeKey, nextState);
      await _applyConfirmedCloudSnapshot(
        scopeKey: scopeKey,
        snapshot: snapshot,
        traceId: traceId,
        stage: 'state_applied',
        slot: operation.slot,
        previousItemId: previousItemId,
        nextItemId: asset.id,
        assetPath: asset.assetPath,
      );
      return ShopCosmeticsOperationResult(
        status: ShopCosmeticsOperationStatus.success,
        state: nextState,
        walletCoins: await _walletCoins(),
        assetId: asset.id,
      );
    } on ShopCloudEquipException catch (error) {
      _traceCloudCosmetics(
        'rpc_error',
        traceId: traceId,
        userId: scopeKey,
        slot: operation.slot,
        previousItemId: previousItemId,
        nextItemId: asset.id,
        assetPath: asset.assetPath,
        state: initialState,
        note:
            'code=${error.code.name} retryable=${error.retryable} definitive=${error.definitive}',
      );
      if (_shouldReconcileCloudEquipError(error)) {
        _setCloudEquipOperation(
          operation.copyWith(
            phase: _CloudEquipOperationPhase.awaitingResolution,
          ),
        );
        return _reconcileCloudEquipAsset(
          asset: asset,
          initialState: initialState,
          traceId: traceId,
          scopeKey: scopeKey,
          previousItemId: previousItemId,
          operation: operation,
        );
      }
      _setCloudEquipOperation(
        operation.copyWith(phase: _CloudEquipOperationPhase.definitiveFailure),
      );
      return _mapCloudEquipFailure(
        error,
        assetId: asset.id,
        currentState: initialState,
      );
    }
  }

  Future<ShopCosmeticsOperationResult> _equipBundleCloud(
    String bundleId,
  ) async {
    final scopeKey = _currentScope();
    final traceId = _newTraceId('tap');
    final state = await _combinedCloudState();
    if (resolvedAssets.isEmpty || resolvedBundles.isEmpty) {
      return _cloudFailureResult(
        status: ShopCosmeticsOperationStatus.bundleNotFound,
        state: state,
        bundleId: bundleId,
        walletCoins: await _walletCoins(),
      );
    }
    final bundle = _resolvedBundleById(bundleId);
    if (bundle == null) {
      return _cloudFailureResult(
        status: ShopCosmeticsOperationStatus.bundleNotFound,
        state: state,
        bundleId: bundleId,
        walletCoins: await _walletCoins(),
      );
    }
    final quote = ShopBundleCompletionQuote.tryCreate(
      bundle: bundle,
      state: state,
      catalogAssets: resolvedAssets,
      catalogBundles: resolvedBundles,
    );
    if (quote == null) {
      return _cloudFailureResult(
        status: ShopCosmeticsOperationStatus.bundleNotFound,
        state: state,
        bundleId: bundleId,
        walletCoins: await _walletCoins(),
      );
    }
    if (!quote.canEquip) {
      return _cloudFailureResult(
        status: ShopCosmeticsOperationStatus.assetNotOwned,
        state: state,
        bundleId: bundleId,
        walletCoins: await _walletCoins(),
      );
    }

    final bundleAssets = _resolveOwnedBundleAssets(bundle);
    if (bundleAssets == null) {
      return _cloudFailureResult(
        status: ShopCosmeticsOperationStatus.bundleNotFound,
        state: state,
        bundleId: bundleId,
        walletCoins: await _walletCoins(),
      );
    }

    try {
      _traceCloudCosmetics(
        'tap',
        traceId: traceId,
        userId: scopeKey,
        slot: 'bundle',
        previousItemId: bundle.wallpaperItemId,
        nextItemId: bundleId,
        state: state,
        note: 'bundle_step=1/3',
      );
      var currentState = state;
      for (var index = 0; index < bundleAssets.length; index += 1) {
        final asset = bundleAssets[index];
        currentState = await _performCloudEquipAssetStep(
          asset: asset,
          state: currentState,
          traceId: traceId,
          scopeKey: scopeKey,
          previousItemId: currentState.getEquippedAssetIdForCategory(
            asset.category,
          ),
          note: 'bundle_step=${index + 1}/3 bundleId=$bundleId',
        );
        if (_currentScope() != scopeKey) {
          await _syncFromCurrentScope(force: true);
          return _cloudFailureResult(
            status: ShopCosmeticsOperationStatus.bundleNotFound,
            state: currentState,
            bundleId: bundleId,
            walletCoins: await _walletCoins(),
          );
        }
      }

      final resolvedScopeKey = scopeKey ?? _currentScope();
      if (resolvedScopeKey == null) {
        await _syncFromCurrentScope(force: true);
        return _cloudFailureResult(
          status: ShopCosmeticsOperationStatus.bundleNotFound,
          state: currentState,
          bundleId: bundleId,
          walletCoins: await _walletCoins(),
        );
      }

      _markCloudMutation();
      final snapshot = _buildCloudSnapshot(resolvedScopeKey, currentState);
      await _applyConfirmedCloudSnapshot(
        scopeKey: resolvedScopeKey,
        snapshot: snapshot,
        traceId: traceId,
        stage: 'state_applied',
        slot: 'bundle',
        previousItemId: bundle.id,
        nextItemId: bundle.id,
      );
      unawaited(_syncFromCurrentScope(force: true));
      return ShopCosmeticsOperationResult(
        status: ShopCosmeticsOperationStatus.success,
        state: currentState,
        walletCoins: await _walletCoins(),
        bundleId: bundleId,
      );
    } on ShopCloudEquipException catch (error) {
      await _syncFromCurrentScope(force: true);
      return _mapCloudEquipFailure(
        error,
        assetId: bundleId,
        currentState: state,
      );
    }
  }

  Future<ShopCosmeticsState> _performCloudEquipAssetStep({
    required ShopAsset asset,
    required ShopCosmeticsState state,
    required String traceId,
    required String? scopeKey,
    required String? previousItemId,
    String? requestId,
    String? note,
  }) async {
    requestId ??= _requestIdGenerator();
    final equipSlot = _resolveEquipSlot(asset);
    _traceCloudCosmetics(
      'tap',
      traceId: traceId,
      userId: scopeKey,
      slot: equipSlot,
      previousItemId: previousItemId,
      nextItemId: asset.id,
      assetPath: asset.assetPath,
      state: state,
      note: note,
    );
    _traceCloudCosmetics(
      'rpc_start',
      traceId: traceId,
      userId: scopeKey,
      slot: equipSlot,
      previousItemId: previousItemId,
      nextItemId: asset.id,
      assetPath: asset.assetPath,
      state: state,
      note: 'requestId=$requestId',
    );
    final rpcResult = await _cloudRepository.equipAsset(
      itemId: asset.id,
      slot: equipSlot,
      requestId: requestId,
    );
    _traceCloudCosmetics(
      'rpc_success',
      traceId: traceId,
      userId: scopeKey,
      slot: equipSlot,
      previousItemId: previousItemId,
      nextItemId: asset.id,
      assetPath: asset.assetPath,
      state: state,
      note: 'operation=${rpcResult.operation} requestId=${rpcResult.requestId}',
    );
    return switch (asset.category) {
      ShopAssetCategory.wallpaper =>
        state.copyWith(equippedWallpaperId: asset.id),
      ShopAssetCategory.habitCard =>
        state.copyWith(equippedHabitCardSkinId: asset.id),
      ShopAssetCategory.userCard =>
        state.copyWith(equippedUserCardSkinId: asset.id),
    };
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

  Future<List<ShopCosmeticsOperationResult>>
      resolvePendingCloudPurchasesForCurrentUser({
    int maxOperations = 4,
  }) {
    if (!_cloudEnabled) {
      return Future<List<ShopCosmeticsOperationResult>>.value(
        const <ShopCosmeticsOperationResult>[],
      );
    }

    final active = _pendingPurchaseResolution;
    if (active != null) return active;

    late final Future<List<ShopCosmeticsOperationResult>> future;
    future = _resolvePendingCloudPurchasesForCurrentUser(
      maxOperations: maxOperations,
    ).whenComplete(() {
      if (identical(_pendingPurchaseResolution, future)) {
        _pendingPurchaseResolution = null;
      }
    });
    _pendingPurchaseResolution = future;
    return future;
  }

  Future<List<ShopCosmeticsOperationResult>>
      _resolvePendingCloudPurchasesForCurrentUser({
    required int maxOperations,
  }) async {
    final userId = _currentScope();
    if (userId == null) return const <ShopCosmeticsOperationResult>[];

    final pending = await _pendingPurchaseStore.loadPendingPurchases(userId);
    if (pending.isEmpty) return const <ShopCosmeticsOperationResult>[];

    final results = <ShopCosmeticsOperationResult>[];
    for (final operation in pending.take(maxOperations)) {
      if (_currentScope() != userId) break;
      final result = switch (operation.operationType) {
        PendingCloudCosmeticsPurchaseType.cosmeticPurchase =>
          await _purchaseAssetCloud(
            operation.resourceId,
            resolvingPending: true,
            refreshAfterSuccess: false,
          ),
        PendingCloudCosmeticsPurchaseType.bundlePurchase =>
          await _purchaseBundleCloud(
            operation.resourceId,
            resolvingPending: true,
            refreshAfterSuccess: false,
          ),
      };
      results.add(result);
    }
    return List<ShopCosmeticsOperationResult>.unmodifiable(results);
  }

  Future<PendingCloudCosmeticsPurchase?> _pendingPurchaseFor({
    required String userId,
    required PendingCloudCosmeticsPurchaseType operationType,
    required String resourceId,
  }) async {
    final logicalKey = PendingCloudCosmeticsPurchase.logicalKeyFor(
      operationType: operationType,
      resourceId: resourceId,
    );
    final pending = await _pendingPurchaseStore.loadPendingPurchases(userId);
    for (final purchase in pending) {
      if (purchase.logicalKey == logicalKey) return purchase;
    }
    return null;
  }

  Future<PendingCloudCosmeticsPurchase> _ensurePendingPurchase({
    required String userId,
    required PendingCloudCosmeticsPurchaseType operationType,
    required String resourceId,
    PendingCloudCosmeticsPurchase? existing,
  }) async {
    final nowMillis = _nowProvider().toUtc().millisecondsSinceEpoch;
    final pending = existing?.copyWith(
          updatedAtMillis: nowMillis,
          status: PendingCloudCosmeticsPurchaseStatus.pending,
          lastFailureCode: null,
        ) ??
        PendingCloudCosmeticsPurchase(
          userId: userId,
          requestId: _requestIdGenerator(),
          operationType: operationType,
          resourceId: resourceId.trim(),
          createdAtMillis: nowMillis,
          updatedAtMillis: nowMillis,
          status: PendingCloudCosmeticsPurchaseStatus.pending,
        );
    _awaitingResolutionPurchaseKeys.remove(pending.logicalKey);
    await _upsertPendingPurchase(pending);
    return pending;
  }

  Future<void> _markPendingPurchaseAwaiting(
    PendingCloudCosmeticsPurchase purchase, {
    String? failureCode,
  }) async {
    _awaitingResolutionPurchaseKeys.add(purchase.logicalKey);
    if (!_isDisposed) {
      notifyListeners();
    }
    await _upsertPendingPurchase(
      purchase.copyWith(
        updatedAtMillis: _nowProvider().toUtc().millisecondsSinceEpoch,
        status: PendingCloudCosmeticsPurchaseStatus.awaitingResolution,
        lastFailureCode: failureCode,
      ),
    );
  }

  Future<void> _upsertPendingPurchase(
    PendingCloudCosmeticsPurchase purchase,
  ) async {
    final userId = purchase.userId.trim();
    if (userId.isEmpty) return;
    final current = await _pendingPurchaseStore.loadPendingPurchases(userId);
    final next = <PendingCloudCosmeticsPurchase>[
      for (final existing in current)
        if (existing.logicalKey != purchase.logicalKey) existing,
      purchase,
    ];
    await _pendingPurchaseStore.savePendingPurchases(userId, next);
  }

  Future<void> _removePendingPurchase(
    String userId,
    String logicalKey,
  ) async {
    final current = await _pendingPurchaseStore.loadPendingPurchases(userId);
    final next = current
        .where((purchase) => purchase.logicalKey != logicalKey)
        .toList(growable: false);
    await _pendingPurchaseStore.savePendingPurchases(userId, next);
    if (_awaitingResolutionPurchaseKeys.remove(logicalKey) && !_isDisposed) {
      notifyListeners();
    }
  }

  bool _shouldKeepPendingAfterPurchaseError(ShopCloudPurchaseException error) {
    if (error.definitive) return false;
    return switch (error.code) {
      ShopPurchaseFailureCode.timeout ||
      ShopPurchaseFailureCode.networkUnavailable ||
      ShopPurchaseFailureCode.malformedResponse ||
      ShopPurchaseFailureCode.unknown =>
        true,
      _ => error.keepPending,
    };
  }

  bool _isAlreadyPurchasedError(ShopCloudPurchaseException error) {
    return switch (error.code) {
      ShopPurchaseFailureCode.itemAlreadyOwned ||
      ShopPurchaseFailureCode.bundleAlreadyOwned ||
      ShopPurchaseFailureCode.bundleContainsOwnedItems =>
        true,
      _ => false,
    };
  }

  Future<ShopCosmeticsOperationResult?> _tryReconcileAlreadyPurchasedAsset(
    ShopCloudPurchaseException error, {
    required String userId,
    required String assetId,
    required PendingCloudCosmeticsPurchase pending,
  }) async {
    if (!_isAlreadyPurchasedError(error)) return null;
    final refreshed = await _syncFromCurrentScope(force: true);
    if (_currentScope() != userId) return null;
    if (refreshed.isAssetOwned(assetId, bundles: _catalogBundles())) {
      await _removePendingPurchase(userId, pending.logicalKey);
      return ShopCosmeticsOperationResult(
        status: ShopCosmeticsOperationStatus.success,
        state: refreshed,
        walletCoins: await _walletCoins(),
        assetId: assetId,
      );
    }
    return null;
  }

  Future<ShopCosmeticsOperationResult?> _tryReconcileAlreadyPurchasedBundle(
    ShopCloudPurchaseException error, {
    required String userId,
    required String bundleId,
    required PendingCloudCosmeticsPurchase pending,
  }) async {
    if (!_isAlreadyPurchasedError(error)) return null;
    final refreshed = await _syncFromCurrentScope(force: true);
    if (_currentScope() != userId) return null;
    if (refreshed.isBundleOwned(bundleId)) {
      await _removePendingPurchase(userId, pending.logicalKey);
      return ShopCosmeticsOperationResult(
        status: ShopCosmeticsOperationStatus.success,
        state: refreshed,
        walletCoins: await _walletCoins(),
        bundleId: bundleId,
      );
    }
    return null;
  }

  ShopCosmeticsOperationResult _cloudFailureResult({
    required ShopCosmeticsOperationStatus status,
    ShopCosmeticsState? state,
    String? assetId,
    String? bundleId,
    int? walletCoins,
  }) {
    final resolvedState =
        state ?? _cachedState ?? const ShopCosmeticsState.initial();
    return ShopCosmeticsOperationResult(
      status: status,
      state: resolvedState,
      walletCoins: walletCoins ?? 0,
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

  List<ShopAsset>? _resolveOwnedBundleAssets(ShopBundle bundle) {
    final wallpaper = _catalogAssetById(bundle.wallpaperItemId);
    final habitCard = _catalogAssetById(bundle.habitCardItemId);
    final userCard = _catalogAssetById(bundle.userCardItemId);
    if (wallpaper == null ||
        habitCard == null ||
        userCard == null ||
        wallpaper.category != ShopAssetCategory.wallpaper ||
        habitCard.category != ShopAssetCategory.habitCard ||
        userCard.category != ShopAssetCategory.userCard) {
      return null;
    }
    return <ShopAsset>[wallpaper, habitCard, userCard];
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

  bool _shouldReconcileCloudEquipError(ShopCloudEquipException error) {
    if (error.definitive) return false;
    return switch (error.code) {
      ShopCosmeticsOperationFailureCode.timeout ||
      ShopCosmeticsOperationFailureCode.networkUnavailable ||
      ShopCosmeticsOperationFailureCode.malformedResponse ||
      ShopCosmeticsOperationFailureCode.unknown =>
        true,
      _ => error.keepPending,
    };
  }

  Future<ShopCosmeticsOperationResult> _reconcileCloudEquipAsset({
    required ShopAsset asset,
    required ShopCosmeticsState initialState,
    required String traceId,
    required String? scopeKey,
    required String? previousItemId,
    required _CloudEquipOperation operation,
  }) async {
    if (_currentScope() != scopeKey || scopeKey == null || _isDisposed) {
      return ShopCosmeticsOperationResult(
        status: ShopCosmeticsOperationStatus.awaitingResolution,
        state: initialState,
        walletCoins: await _walletCoins(),
        assetId: asset.id,
      );
    }

    final revisionBeforeRefresh = _cloudSnapshotRevision;
    final refreshed = await _syncFromCurrentScope(force: true);
    if (_currentScope() != scopeKey || _isDisposed) {
      return ShopCosmeticsOperationResult(
        status: ShopCosmeticsOperationStatus.awaitingResolution,
        state: initialState,
        walletCoins: await _walletCoins(),
        assetId: asset.id,
      );
    }

    final snapshot = _cloudState.snapshot;
    if (_cloudSnapshotRevision == revisionBeforeRefresh ||
        _cloudState.status != ShopCosmeticsCloudStatus.ready ||
        snapshot == null ||
        snapshot.userId != scopeKey) {
      return ShopCosmeticsOperationResult(
        status: ShopCosmeticsOperationStatus.awaitingResolution,
        state: initialState,
        walletCoins: await _walletCoins(),
        assetId: asset.id,
      );
    }

    final remoteEquippedId =
        refreshed.getEquippedAssetIdForCategory(asset.category);
    final status = remoteEquippedId == asset.id
        ? ShopCosmeticsOperationStatus.success
        : ShopCosmeticsOperationStatus.remoteStateApplied;
    _setCloudEquipOperation(
      operation.copyWith(phase: _CloudEquipOperationPhase.success),
    );
    _traceCloudCosmetics(
      'reconciled',
      traceId: traceId,
      userId: scopeKey,
      slot: operation.slot,
      previousItemId: previousItemId,
      nextItemId: remoteEquippedId,
      assetPath: asset.assetPath,
      snapshot: snapshot,
      state: refreshed,
      note: remoteEquippedId == asset.id
          ? 'requested_item_confirmed'
          : 'remote_truth_applied requested=${asset.id}',
    );
    return ShopCosmeticsOperationResult(
      status: status,
      state: refreshed,
      walletCoins: await _walletCoins(),
      assetId: asset.id,
    );
  }

  void _setCloudEquipOperation(_CloudEquipOperation operation) {
    if (_isDisposed) return;
    _cloudEquipOperationsBySlot[operation.slot] = operation;
    notifyListeners();
  }

  void _clearCloudEquipOperation(String slot) {
    if (_isDisposed) {
      _cloudEquipOperationsBySlot.remove(slot);
      return;
    }
    if (_cloudEquipOperationsBySlot.remove(slot) != null) {
      notifyListeners();
    }
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
      _markCloudMutation();
      _cloudState = ShopCosmeticsCloudState.unauthenticated();
      _cachedState = null;
      _cachedScopeKey = null;
      _pendingStateLoad = null;
      _pendingCloudStateLoad = null;
      return const ShopCosmeticsState.initial();
    }

    final generation = ++_cloudRefreshGeneration;
    final traceId = _newTraceId(force ? 'runtime_refresh' : 'cold_start');
    _log(
      '[shop_cloud_cosmetics] refresh_started generation=$generation '
      'scope=$scopeKey force=$force',
    );
    _log('hydration_started scope=${_debugScope(scopeKey)}');
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

    final completer = Completer<ShopCosmeticsState>();
    late final Future<ShopCosmeticsState> future;
    future = completer.future.whenComplete(() {
      if (identical(_pendingCloudStateLoad, future)) {
        _pendingCloudStateLoad = null;
      }
    });
    _pendingCloudStateLoad = future;
    unawaited(_completeCloudStateLoad(
      completer: completer,
      scopeKey: scopeKey,
      force: force,
      generation: generation,
      traceId: traceId,
    ));
    return future;
  }

  Future<void> _completeCloudStateLoad({
    required Completer<ShopCosmeticsState> completer,
    required String scopeKey,
    required bool force,
    required int generation,
    required String traceId,
  }) async {
    try {
      final state = await _loadCloudState(
        scopeKey: scopeKey,
        force: force,
        generation: generation,
        traceId: traceId,
      );
      if (!completer.isCompleted) {
        completer.complete(state);
      }
    } catch (error, stackTrace) {
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
    }
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
      _log('stale_result_discarded scope=${_debugScope(scopeKey)} stage=cache');
      return _cachedState ?? const ShopCosmeticsState.initial();
    }

    if (cacheEntry != null && !force) {
      _log('cache_loaded scope=${_debugScope(scopeKey)} hit=true');
      if (_isStaleCloudLoad(scopeKey, mutationVersion)) {
        _log(
          '[shop_cloud_cosmetics] stale_refresh_ignored generation=$generation '
          'scope=$scopeKey stage=cache_hit',
        );
        _log(
          'stale_result_discarded scope=${_debugScope(scopeKey)} '
          'stage=cache_hit',
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
      _log('cache_loaded scope=${_debugScope(scopeKey)} hit=false');
      if (_isStaleCloudLoad(scopeKey, mutationVersion)) {
        _log(
          '[shop_cloud_cosmetics] stale_refresh_ignored generation=$generation '
          'scope=$scopeKey stage=no_cache',
        );
        _log(
          'stale_result_discarded scope=${_debugScope(scopeKey)} '
          'stage=no_cache',
        );
        return _cachedState ?? const ShopCosmeticsState.initial();
      }
      _setCloudState(ShopCosmeticsCloudState.loading(userId: scopeKey));
    }

    _log('cloud_refresh_started scope=${_debugScope(scopeKey)}');
    final result = await _cloudRepository.fetchSnapshot();
    final fetchCompletedAt = DateTime.now().toUtc();
    if (_isStaleCloudLoad(scopeKey, mutationVersion)) {
      _log(
        '[shop_cloud_cosmetics] stale_refresh_ignored generation=$generation '
        'scope=$scopeKey stage=fetch',
      );
      _log('stale_result_discarded scope=${_debugScope(scopeKey)} stage=fetch');
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
    if (snapshot.userId != scopeKey) {
      _log(
        'stale_result_discarded scope=${_debugScope(scopeKey)} '
        'stage=fetch user_mismatch=true',
      );
      return _cachedState ?? const ShopCosmeticsState.initial();
    }
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
    _log('cloud_refresh_applied scope=${_debugScope(scopeKey)}');
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
    return _isDisposed ||
        _currentScope() != scopeKey ||
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

    final owned = state.isAssetOwned(asset.id, bundles: _catalogBundles());
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
      catalogItems:
          _cloudState.snapshot?.catalogItems ?? const <RemoteShopItemDto>[],
      catalogBundles:
          _cloudState.snapshot?.catalogBundles ?? const <RemoteShopBundleDto>[],
      catalogBundleItems: _cloudState.snapshot?.catalogBundleItems ??
          const <RemoteShopBundleItemDto>[],
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
    if (_isDisposed) {
      return snapshot.toState();
    }
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
      if (!_isDisposed) {
        super.notifyListeners();
      }
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

  String _debugScope(String? scope) {
    final value = scope?.trim();
    if (value == null || value.isEmpty) return 'guest';
    if (value.length <= 8) return value;
    return '${value.substring(0, 4)}…${value.substring(value.length - 4)}';
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
    if (_isDisposed) return;
    _cachedState = state;
    _cachedScopeKey = scopeKey ?? _currentScope();
    if (shouldNotifyListeners) {
      _log('[shop_cloud_equip] notify_listeners');
      super.notifyListeners();
    }
  }
}
