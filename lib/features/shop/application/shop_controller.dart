import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rutio/features/shop/application/shop_operation_result.dart';
import 'package:rutio/features/shop/application/shop_service.dart';
import 'package:rutio/features/shop/application/purchase_cloud_utility_use_case.dart';
import 'package:rutio/features/shop/application/mystery_box_operation_result.dart';
import 'package:rutio/features/shop/application/open_mystery_box_use_case.dart';
import 'package:rutio/features/shop/application/present_mystery_box_result_use_case.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_config.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_dtos.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_errors.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_purchase_repository.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_purchase_dtos.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_read_repository.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_snapshot.dart';
import 'package:rutio/features/shop/data/cloud/mystery_box_cloud_config.dart';
import 'package:rutio/features/shop/data/cloud/mystery_box_opening_repository.dart';
import 'package:rutio/features/shop/data/cloud/pending_mystery_box_operation_store.dart';
import 'package:rutio/features/shop/data/cloud/utility_consumption_config.dart';
import 'package:rutio/features/shop/data/cloud/utility_consumption_repository.dart';
import 'package:rutio/features/habits/application/activate_streak_shield_use_case.dart';
import 'package:rutio/features/habits/application/recover_streak_use_case.dart';
import 'package:rutio/features/habits/domain/models/active_streak_shield.dart';
import 'package:rutio/features/habits/domain/models/recoverable_streak_break.dart';
import 'package:rutio/features/habits/domain/models/streak_recover_operation_result.dart';
import 'package:rutio/features/habits/domain/models/streak_shield_operation_result.dart';
import 'package:rutio/features/shop/data/local_active_utility_effects_repository.dart';
import 'package:rutio/features/shop/data/dart_random_source.dart';
import 'package:rutio/features/shop/data/local_mystery_box_opening_repository.dart';
import 'package:rutio/features/shop/data/pending_shop_operation_store.dart';
import 'package:rutio/features/shop/data/shop_catalog.dart';
import 'package:rutio/features/shop/data/shop_local_repository.dart';
import 'package:rutio/features/shop/domain/active_utility_effects_repository.dart';
import 'package:rutio/features/shop/domain/models/active_utility_effect.dart';
import 'package:rutio/features/shop/domain/models/backpack_item.dart';
import 'package:rutio/features/shop/domain/mystery_box_opening_repository.dart';
import 'package:rutio/features/shop/domain/pending_shop_operation_store.dart';
import 'package:rutio/features/shop/domain/random_source.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/domain/models/mystery_box_opening_transaction.dart';
import 'package:rutio/features/shop/domain/shop_state.dart';
import 'package:rutio/features/shop/domain/shop_purchase_failure.dart';
import 'package:rutio/features/shop/domain/shop_purchase_result.dart';
import 'package:rutio/core/supabase/rutio_supabase_client.dart';
import 'package:rutio/features/global_wallet/application/global_wallet_controller.dart';
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
  utilityAlreadyActive,
  utilityActivationInProgress,
  cloudPurchasePending,
  cloudPurchaseInProgress,
  cloudPurchaseFailed,
}

enum ShopEconomySource {
  local,
  cloud,
}

enum ShopCloudEconomyStatus {
  disabled,
  loading,
  ready,
  stale,
  walletMissing,
  unauthenticated,
  failed,
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
    this.purchaseFailure,
    this.cloudPurchaseResult,
    this.cloudRefreshFailed = false,
  });

  final ShopControllerStatus status;
  final ShopState shopState;
  final int walletCoins;
  final ShopItem? item;
  final ShopPurchaseFailure? purchaseFailure;
  final ShopPurchaseResult? cloudPurchaseResult;
  final bool cloudRefreshFailed;

  bool get isSuccess => status == ShopControllerStatus.success;
}

class ShopController extends ChangeNotifier {
  ShopController({
    required UserStateStore userStateStore,
    GlobalWalletController? globalWalletController,
    ShopLocalRepository? shopRepository,
    ActiveUtilityEffectsRepository? activeUtilityEffectsRepository,
    MysteryBoxOpeningRepository? mysteryBoxOpeningRepository,
    CloudMysteryBoxOpeningRepository? cloudMysteryBoxOpeningRepository,
    PendingMysteryBoxOperationStore? pendingMysteryBoxOperationStore,
    RandomSource? randomSource,
    DateTime Function()? nowProvider,
    ShopCloudReadRepository? shopCloudReadRepository,
    ShopCloudPurchaseRepository? shopCloudPurchaseRepository,
    PendingShopOperationStore? pendingShopOperationStore,
    PurchaseCloudUtilityUseCase? purchaseCloudUtilityUseCase,
    UtilityConsumptionRepository? utilityConsumptionRepository,
    String? Function()? currentSupabaseUserIdProvider,
    bool? cloudReadEnabled,
    bool? cloudPurchaseEnabled,
    bool? mysteryBoxCloudEnabled,
    bool? utilityConsumptionEnabled,
  })  : _userStateStore = userStateStore,
        _globalWalletController = globalWalletController,
        _currentSupabaseUserIdProvider =
            currentSupabaseUserIdProvider ?? _defaultCurrentSupabaseUserId,
        _cloudReadEnabled =
            ShopCloudConfig.resolveReadEnabled(override: cloudReadEnabled),
        _cloudPurchaseEnabled = ShopCloudConfig.resolvePurchaseEnabled(
            override: cloudPurchaseEnabled),
        _mysteryBoxCloudEnabled = MysteryBoxCloudConfig.resolveEnabled(
          override: mysteryBoxCloudEnabled,
        ),
        _utilityConsumptionEnabled = UtilityConsumptionConfig.resolveEnabled(
          override: utilityConsumptionEnabled,
        ),
        _shopRepository = shopRepository ??
            ShopLocalRepository(
              scopeResolver: () =>
                  userStateStore.activeLocalScopeUserId ??
                  userStateStore.userId,
            ),
        _utilityConsumptionRepository = UtilityConsumptionConfig.resolveEnabled(
          override: utilityConsumptionEnabled,
        )
            ? (utilityConsumptionRepository ??
                (activeUtilityEffectsRepository is UtilityConsumptionRepository
                    ? activeUtilityEffectsRepository
                    : SupabaseUtilityConsumptionRepository()))
            : null,
        _activeUtilityEffectsRepository =
            UtilityConsumptionConfig.resolveEnabled(
          override: utilityConsumptionEnabled,
        )
                ? (utilityConsumptionRepository ??
                    (activeUtilityEffectsRepository
                            is UtilityConsumptionRepository
                        ? activeUtilityEffectsRepository
                        : SupabaseUtilityConsumptionRepository()))
                : activeUtilityEffectsRepository ??
                    LocalActiveUtilityEffectsRepository(
                      scopeResolver: () =>
                          userStateStore.activeLocalScopeUserId ??
                          userStateStore.userId,
                    ),
        _mysteryBoxOpeningRepository = mysteryBoxOpeningRepository ??
            LocalMysteryBoxOpeningRepository(
              scopeResolver: () =>
                  userStateStore.activeLocalScopeUserId ??
                  userStateStore.userId,
            ),
        _cloudMysteryBoxOpeningRepository = cloudMysteryBoxOpeningRepository,
        _pendingMysteryBoxOperationStore = pendingMysteryBoxOperationStore,
        _randomSource = randomSource ?? DartRandomSource(),
        _nowProvider = nowProvider ?? DateTime.now,
        _shopCloudReadRepository = shopCloudReadRepository ??
            ShopCloudReadRepository(
              readEnabled: ShopCloudConfig.resolveReadEnabled(
                override: cloudReadEnabled,
              ),
            ),
        _purchaseCloudUtilityUseCase = purchaseCloudUtilityUseCase ??
            PurchaseCloudUtilityUseCase(
              purchaseRepository:
                  shopCloudPurchaseRepository ?? ShopCloudPurchaseRepository(),
              pendingOperationStore: pendingShopOperationStore ??
                  SharedPreferencesPendingShopOperationStore(),
              cloudReadRepository: shopCloudReadRepository ??
                  ShopCloudReadRepository(
                    readEnabled: ShopCloudConfig.resolveReadEnabled(
                      override: cloudReadEnabled,
                    ),
                  ),
              currentUserIdProvider: () => (currentSupabaseUserIdProvider ??
                  _defaultCurrentSupabaseUserId)(),
              purchaseEnabled: ShopCloudConfig.resolvePurchaseEnabled(
                override: cloudPurchaseEnabled,
              ),
              readEnabled: ShopCloudConfig.resolveReadEnabled(
                  override: cloudReadEnabled),
              nowProvider: nowProvider,
            );

  final UserStateStore _userStateStore;
  final GlobalWalletController? _globalWalletController;
  final ShopLocalRepository _shopRepository;
  final ActiveUtilityEffectsRepository _activeUtilityEffectsRepository;
  final bool _utilityConsumptionEnabled;
  final UtilityConsumptionRepository? _utilityConsumptionRepository;
  final MysteryBoxOpeningRepository _mysteryBoxOpeningRepository;
  final CloudMysteryBoxOpeningRepository? _cloudMysteryBoxOpeningRepository;
  final PendingMysteryBoxOperationStore? _pendingMysteryBoxOperationStore;
  final RandomSource _randomSource;
  final DateTime Function() _nowProvider;
  final String? Function() _currentSupabaseUserIdProvider;
  final bool _cloudReadEnabled;
  final bool _cloudPurchaseEnabled;
  final bool _mysteryBoxCloudEnabled;
  final ShopCloudReadRepository _shopCloudReadRepository;
  final PurchaseCloudUtilityUseCase _purchaseCloudUtilityUseCase;
  final Map<String, ShopCloudSnapshot> _cloudSnapshotByUserId =
      <String, ShopCloudSnapshot>{};
  final Map<String, Future<void>> _cloudHydrationFutureByUserId =
      <String, Future<void>>{};
  final Set<String> _pendingUtilityActivations = <String>{};
  final Set<String> _pendingMysteryBoxScopes = <String>{};
  final Map<String, Future<ShopControllerResult>> _activeCloudPurchaseByItemId =
      <String, Future<ShopControllerResult>>{};
  String? _cloudEconomyUserId;
  ShopEconomySource _economySource = ShopEconomySource.local;
  ShopCloudEconomyStatus _economyStatus = ShopCloudEconomyStatus.disabled;
  int? _cloudPurchaseWalletCoins;
  final Map<String, int> _cloudPurchaseInventoryQuantityByItemId =
      <String, int>{};

  ShopEconomySource get economySource => _economySource;

  ShopCloudEconomyStatus get economyStatus => _economyStatus;

  bool get isCloudEconomyReady =>
      _economySource == ShopEconomySource.cloud &&
      (_economyStatus == ShopCloudEconomyStatus.ready ||
          _economyStatus == ShopCloudEconomyStatus.stale);

  int? get visibleCoinBalance {
    if (!isCloudEconomyEnabled) {
      return _walletCoins();
    }
    if (!isCloudEconomyReady) {
      return null;
    }
    return _cloudPurchaseWalletCoins ?? _walletCoins();
  }

  int getWalletCoins() {
    return _walletCoins();
  }

  bool get isCloudPurchaseEnabled => _cloudPurchaseEnabled;

  bool get isCloudEconomyEnabled => _cloudReadEnabled && _cloudPurchaseEnabled;

  Future<void> hydrateVisibleEconomy({bool force = false}) async {
    if (!isCloudEconomyEnabled) {
      _setEconomyState(
        source: ShopEconomySource.local,
        status: ShopCloudEconomyStatus.disabled,
      );
      return;
    }

    final currentUserId = _currentSupabaseUserId();
    if (currentUserId == null) {
      _setUnauthenticatedVisibleEconomy();
      return;
    }

    final cachedSnapshot = _cloudSnapshotByUserId[currentUserId];
    if (!force &&
        _cloudEconomyUserId == currentUserId &&
        cachedSnapshot != null &&
        isCloudEconomyReady) {
      return;
    }

    final existingFuture = _cloudHydrationFutureByUserId[currentUserId];
    if (existingFuture != null && !force) {
      await existingFuture;
      return;
    }

    final future = _hydrateVisibleEconomy(currentUserId);
    _cloudHydrationFutureByUserId[currentUserId] = future;
    try {
      await future;
    } finally {
      final activeFuture = _cloudHydrationFutureByUserId[currentUserId];
      if (identical(activeFuture, future)) {
        _cloudHydrationFutureByUserId.remove(currentUserId);
      }
    }
  }

  Future<ShopItemState?> getItemState(String itemId) async {
    final item = ShopCatalog.getItemById(itemId);
    if (item == null) return null;

    final root = await _ensureRoot();
    if (root == null) return null;

    final shopState = await getVisibleShopState();
    final walletCoins = _walletCoinsForItem(item);
    return _buildItemState(
      item: item,
      shopState: shopState,
      walletCoins: walletCoins,
    );
  }

  Future<ShopState> getVisibleShopState() async {
    final shopState = await _shopRepository.load();
    if (!isCloudEconomyEnabled) {
      return shopState;
    }

    await hydrateVisibleEconomy();
    if (!isCloudEconomyReady) {
      return shopState;
    }
    return _adjustShopStateForCloudPurchase(null, shopState);
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

    if (isCloudEconomyEnabled &&
        item.category == ShopItemCategory.utility &&
        !_supportedCloudUtilityIds.contains(item.id)) {
      return _controllerResult(
        ShopControllerStatus.cloudPurchaseFailed,
        item: item,
        shopState: await _shopRepository.load(),
        purchaseFailure: const ShopPurchaseFailure(
          code: ShopPurchaseFailureCode.unsupportedCloudItem,
          message: 'The requested item is not supported by cloud purchase.',
          definitive: true,
        ),
      );
    }

    if (isCloudEconomyEnabled &&
        item.category == ShopItemCategory.utility &&
        _supportedCloudUtilityIds.contains(item.id)) {
      if (!_cloudEconomyCanPurchase()) {
        await hydrateVisibleEconomy(force: false);
      }
      if (!_cloudEconomyCanPurchase()) {
        return _controllerResult(
          ShopControllerStatus.cloudPurchaseFailed,
          item: item,
          shopState: await _adjustedLocalShopState(item),
          walletCoins: visibleCoinBalance ?? 0,
          purchaseFailure: _cloudPurchaseUnavailableFailure(),
        );
      }

      final normalizedItemId = item.id.trim();
      final existingFuture = _activeCloudPurchaseByItemId[normalizedItemId];
      if (existingFuture != null) {
        return existingFuture;
      }

      final future = _purchaseCloudUtility(item);
      _activeCloudPurchaseByItemId[normalizedItemId] = future;
      try {
        return await future;
      } finally {
        _activeCloudPurchaseByItemId.remove(normalizedItemId);
      }
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
    final walletCoins = _walletCoins();
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
      walletCoins: _walletCoins(),
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
      walletCoins: _walletCoins(),
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
      walletCoins: _walletCoins(),
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

  Future<List<ActiveUtilityEffect>> getActiveUtilityEffects() async {
    final scope = _currentScopeUserId();
    final repoEffects = scope == null
        ? const <ActiveUtilityEffect>[]
        : await _activeUtilityEffectsRepository.loadEffects(scope);
    return <ActiveUtilityEffect>[
      ...repoEffects,
      ..._streakShieldEffectsFromStore(),
    ];
  }

  List<Map<String, dynamic>> getActiveHabits() {
    return _userStateStore.activeHabits;
  }

  List<RecoverableStreakBreak> getRecoverableStreakBreaks() {
    return _userStateStore.recoverableStreakBreaks;
  }

  ActiveStreakShield? getActiveStreakShieldForHabit(String habitId) {
    return _userStateStore.activeStreakShieldForHabit(habitId);
  }

  RecoverableStreakBreak? getRecoverableStreakBreakForHabit(String habitId) {
    return _userStateStore.recoverableStreakBreakForHabit(habitId);
  }

  Future<List<MysteryBoxOpeningTransaction>> getPendingMysteryBoxOpenings() {
    return _loadPendingMysteryBoxOpenings();
  }

  bool isUtilityActivationPending(String utilityId) {
    return _pendingUtilityActivations.contains(_activationKey(utilityId));
  }

  Future<ShopControllerResult> activateBoost(String utilityId) async {
    final normalizedUtilityId = utilityId.trim();
    final item = ShopCatalog.getItemById(normalizedUtilityId);
    if (item == null) {
      return _controllerResult(
        ShopControllerStatus.itemNotFound,
        item: null,
        shopState: await _shopRepository.load(),
      );
    }

    if (item.category != ShopItemCategory.utility) {
      return _controllerResult(
        ShopControllerStatus.invalidItemType,
        item: item,
        shopState: await _shopRepository.load(),
      );
    }

    if (item.type != ShopItemType.xpBoost &&
        item.type != ShopItemType.coinBoost) {
      return _controllerResult(
        ShopControllerStatus.invalidItemType,
        item: item,
        shopState: await _shopRepository.load(),
      );
    }

    final activationKey = _activationKey(normalizedUtilityId);
    if (_pendingUtilityActivations.contains(activationKey)) {
      return _controllerResult(
        ShopControllerStatus.utilityActivationInProgress,
        item: item,
        shopState: await _shopRepository.load(),
      );
    }

    _pendingUtilityActivations.add(activationKey);
    try {
      if (_utilityConsumptionEnabled) {
        return await _activateBoostCloud(item: item);
      }
      return await _activateBoostLocal(item: item);
    } finally {
      _pendingUtilityActivations.remove(activationKey);
    }
  }

  Future<ShopControllerResult> _activateBoostCloud({
    required ShopItem item,
  }) async {
    final visibleShopState = await getVisibleShopState();
    final visibleWalletCoins = visibleCoinBalance ?? getWalletCoins();
    final visibleItemState = _buildItemState(
      item: item,
      shopState: visibleShopState,
      walletCoins: visibleWalletCoins,
    );
    final expectedQuantity = visibleItemState.backpackQuantity > 0
        ? visibleItemState.backpackQuantity - 1
        : 0;
    final currentUserId = _currentSupabaseUserId();
    if (currentUserId == null) {
      return _controllerResult(
        ShopControllerStatus.unavailableState,
        item: item,
        shopState: visibleShopState,
        walletCoins: visibleWalletCoins,
      );
    }

    final effectType = switch (item.type) {
      ShopItemType.xpBoost => ActiveUtilityEffectType.xpBoost,
      ShopItemType.coinBoost => ActiveUtilityEffectType.coinBoost,
      _ => null,
    };
    if (effectType == null) {
      return _controllerResult(
        ShopControllerStatus.invalidItemType,
        item: item,
        shopState: visibleShopState,
        walletCoins: visibleWalletCoins,
      );
    }

    final activeEffects = await _activeUtilityEffectsRepository.loadEffects(
      currentUserId,
    );
    if (activeEffects.any((effect) => effect.type == effectType)) {
      return _controllerResult(
        ShopControllerStatus.utilityAlreadyActive,
        item: item,
        shopState: visibleShopState,
        walletCoins: visibleWalletCoins,
      );
    }

    final requestId = _utilityActivationRequestId(
      userId: currentUserId,
      utilityId: item.id,
    );

    try {
      await _utilityConsumptionRepository!.activateUtilityEffect(
        requestId: requestId,
        utilityId: item.id,
        operationType: 'activate',
        sourceType: 'shop_activation',
        sourceId: requestId,
      );
      await _refreshCloudPurchaseSnapshot(force: true);
      final refreshedQuantity =
          _cloudPurchaseInventoryQuantityByItemId[item.id];
      if (refreshedQuantity == null || refreshedQuantity > expectedQuantity) {
        _cloudPurchaseInventoryQuantityByItemId[item.id] = expectedQuantity;
      }
      final refreshedShopState = await getVisibleShopState();
      final refreshedUserId = _currentSupabaseUserId();
      if (refreshedUserId != null) {
        unawaited(
          _globalWalletController?.syncSession(
            userId: refreshedUserId,
            force: true,
          ),
        );
      }
      return _controllerResult(
        ShopControllerStatus.success,
        item: item,
        shopState: refreshedShopState,
        walletCoins: visibleCoinBalance ?? visibleWalletCoins,
      );
    } catch (error) {
      _logUtilityActivationError(item.id, error);
      final status = _mapUtilityActivationFailure(error);
      return _controllerResult(
        status,
        item: item,
        shopState: visibleShopState,
        walletCoins: visibleWalletCoins,
      );
    }
  }

  Future<ShopControllerResult> _activateBoostLocal({
    required ShopItem item,
  }) async {
    final root = await _ensureRoot();
    if (root == null) {
      return _controllerResult(
        ShopControllerStatus.unavailableState,
        item: item,
        shopState: await _shopRepository.load(),
      );
    }

    final shopState = await _shopRepository.load();
    final walletCoins = _walletCoins();
    final scope = _currentScopeUserId();
    if (scope == null) {
      return _controllerResult(
        ShopControllerStatus.unavailableState,
        item: item,
        shopState: shopState,
        walletCoins: walletCoins,
      );
    }
    final itemState = _buildItemState(
      item: item,
      shopState: shopState,
      walletCoins: walletCoins,
    );
    if (!itemState.isInBackpack) {
      return _controllerResult(
        ShopControllerStatus.backpackItemNotFound,
        item: item,
        shopState: shopState,
        walletCoins: walletCoins,
      );
    }

    final activeEffects = await _activeUtilityEffectsRepository.loadEffects(
      scope,
    );
    final effectType = switch (item.type) {
      ShopItemType.xpBoost => ActiveUtilityEffectType.xpBoost,
      ShopItemType.coinBoost => ActiveUtilityEffectType.coinBoost,
      _ => null,
    };
    if (effectType == null) {
      return _controllerResult(
        ShopControllerStatus.invalidItemType,
        item: item,
        shopState: shopState,
        walletCoins: walletCoins,
      );
    }

    final hasActiveEffect = activeEffects.any(
      (effect) => effect.type == effectType,
    );
    if (hasActiveEffect) {
      return _controllerResult(
        ShopControllerStatus.utilityAlreadyActive,
        item: item,
        shopState: shopState,
        walletCoins: walletCoins,
      );
    }

    final service = ShopService(
      state: shopState,
      walletCoins: walletCoins,
    );
    final consumeResult = service.consumeBackpackItem(item.id);
    if (!consumeResult.isSuccess) {
      return _controllerResult(
        ShopControllerStatus.backpackItemNotFound,
        item: item,
        shopState: shopState,
        walletCoins: walletCoins,
      );
    }

    final activatedAtMillis = _nowProvider().millisecondsSinceEpoch;
    final nextEffect = ActiveUtilityEffect(
      id: _activationEffectId(item.id, activatedAtMillis),
      utilityId: item.id,
      type: effectType,
      activatedAtMillis: activatedAtMillis,
      remainingUses: 10,
      totalUses: 10,
    );
    final nextEffects = <ActiveUtilityEffect>[
      ...activeEffects,
      nextEffect,
    ];

    try {
      await _shopRepository.save(consumeResult.state);
      await _activeUtilityEffectsRepository.saveEffects(scope, nextEffects);
    } catch (_) {
      try {
        await _shopRepository.save(shopState);
      } catch (_) {}
      return _controllerResult(
        ShopControllerStatus.unavailableState,
        item: item,
        shopState: shopState,
        walletCoins: walletCoins,
      );
    }

    return _controllerResult(
      ShopControllerStatus.success,
      item: item,
      shopState: consumeResult.state,
      walletCoins: consumeResult.walletCoins,
    );
  }

  Future<MysteryBoxOperationResult> openMysteryBox({
    String? transactionId,
  }) async {
    final normalizedTransactionId = transactionId?.trim();
    final effectiveTransactionId =
        normalizedTransactionId == null || normalizedTransactionId.isEmpty
            ? _generateMysteryBoxTransactionId()
            : normalizedTransactionId;
    final scope = _currentScopeUserId();
    if (scope == null) {
      return const MysteryBoxOperationResult(
        status: MysteryBoxOperationStatus.unavailableState,
      );
    }

    if (_pendingMysteryBoxScopes.contains(scope)) {
      return const MysteryBoxOperationResult(
        status: MysteryBoxOperationStatus.duplicateTransaction,
      );
    }

    _pendingMysteryBoxScopes.add(scope);
    try {
      final pending = await _loadPendingMysteryBoxOpenings();
      if (pending.isNotEmpty &&
          !pending.any((entry) => entry.id == effectiveTransactionId)) {
        return MysteryBoxOperationResult(
          status: MysteryBoxOperationStatus.duplicateTransaction,
          transaction: pending.first,
        );
      }

      final result = await OpenMysteryBoxUseCase(
        userStateStore: _userStateStore,
        shopRepository: _shopRepository,
        mysteryBoxOpeningRepository: _mysteryBoxOpeningRepository,
        cloudMysteryBoxOpeningRepository: _cloudMysteryBoxOpeningRepository,
        pendingMysteryBoxOperationStore: _pendingMysteryBoxOperationStore,
        randomSource: _randomSource,
        cloudEnabled: _mysteryBoxCloudEnabled,
        nowProvider: _nowProvider,
      ).open(transactionId: effectiveTransactionId);

      if (result.isSuccess && _mysteryBoxCloudEnabled) {
        await _refreshCloudPurchaseSnapshot(force: true);
        final currentUserId = _currentSupabaseUserId();
        if (currentUserId != null) {
          unawaited(
            _globalWalletController?.syncSession(
              userId: currentUserId,
              force: true,
            ),
          );
        }
      }

      return result;
    } finally {
      _pendingMysteryBoxScopes.remove(scope);
    }
  }

  Future<MysteryBoxOperationResult> presentMysteryBoxResult(
    String transactionId,
  ) {
    return PresentMysteryBoxResultUseCase(
      OpenMysteryBoxUseCase(
        userStateStore: _userStateStore,
        shopRepository: _shopRepository,
        mysteryBoxOpeningRepository: _mysteryBoxOpeningRepository,
        randomSource: _randomSource,
        nowProvider: _nowProvider,
      ),
    ).present(transactionId: transactionId);
  }

  Future<StreakShieldOperationResult> activateStreakShield({
    required String habitId,
    required String operationId,
    String utilityId = 'utility_streak_shield_1',
  }) {
    return ActivateStreakShieldUseCase(
      userStateStore: _userStateStore,
      shopRepository: _shopRepository,
      nowProvider: _nowProvider,
    ).execute(
      habitId: habitId,
      operationId: operationId,
      utilityId: utilityId,
    );
  }

  Future<StreakRecoverOperationResult> recoverStreakBreak({
    required String breakId,
    required String operationId,
    String utilityId = 'utility_streak_recover_1',
  }) {
    return RecoverStreakUseCase(
      userStateStore: _userStateStore,
      shopRepository: _shopRepository,
      nowProvider: _nowProvider,
    ).execute(
      breakId: breakId,
      operationId: operationId,
      utilityId: utilityId,
    );
  }

  Future<ShopCloudReadResult<ShopCloudSnapshot>?>
      loadCloudSnapshotForDiagnostics() async {
    if (!isCloudEconomyEnabled) {
      return null;
    }

    final result = await _shopCloudReadRepository.fetchShopSnapshot();
    if (kDebugMode) {
      if (result.isSuccess && result.data != null) {
        final snapshot = result.data!;
        debugPrint(
          '[shop_cloud_read] snapshot fetched for user=${snapshot.authenticatedUserId} '
          'catalog=${snapshot.catalogItems.length} inventory=${snapshot.inventory.length} '
          'equipped=${snapshot.equippedCosmetics.length} warnings=${snapshot.warnings.length}',
        );
      } else {
        debugPrint(
          '[shop_cloud_read] snapshot fetch failed: ${result.error?.code.name}',
        );
      }
    }
    return result;
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
    final userState = Map<String, dynamic>.from(
        root['userState'] as Map? ?? <String, dynamic>{});
    final wallet = Map<String, dynamic>.from(
        userState['wallet'] as Map? ?? <String, dynamic>{});
    wallet['coins'] = walletCoins;
    userState['wallet'] = wallet;
    root['userState'] = userState;
    await _userStateStore.save(root);
  }

  bool _shouldUseCloudPurchase(ShopItem item) {
    return isCloudEconomyEnabled &&
        item.category == ShopItemCategory.utility &&
        _supportedCloudUtilityIds.contains(item.id) &&
        _cloudEconomyCanPurchase();
  }

  static const Set<String> _supportedCloudUtilityIds = <String>{
    'utility_xp_boost_1d',
    'utility_coin_boost_1d',
    'utility_streak_recover_1',
    'utility_streak_shield_1',
    'utility_mystery_box_basic',
  };

  bool _cloudEconomyCanPurchase() {
    if (!isCloudEconomyEnabled) return false;
    return isCloudEconomyReady && _cloudPurchaseWalletCoins != null;
  }

  ShopPurchaseFailure _cloudPurchaseUnavailableFailure() {
    switch (_economyStatus) {
      case ShopCloudEconomyStatus.unauthenticated:
        return const ShopPurchaseFailure(
          code: ShopPurchaseFailureCode.unauthenticated,
          message: 'No authenticated user session is available.',
          definitive: true,
        );
      case ShopCloudEconomyStatus.walletMissing:
        return const ShopPurchaseFailure(
          code: ShopPurchaseFailureCode.cloudWalletMissing,
          message: 'Cloud wallet row is missing.',
          definitive: true,
        );
      case ShopCloudEconomyStatus.loading:
        return const ShopPurchaseFailure(
          code: ShopPurchaseFailureCode.operationPending,
          message: 'Shop cloud economy is still loading.',
        );
      case ShopCloudEconomyStatus.failed:
      case ShopCloudEconomyStatus.stale:
      case ShopCloudEconomyStatus.ready:
      case ShopCloudEconomyStatus.disabled:
        return const ShopPurchaseFailure(
          code: ShopPurchaseFailureCode.unknown,
          message: 'Shop cloud economy is not ready.',
        );
    }
  }

  Future<void> _hydrateVisibleEconomy(String currentUserId) async {
    _setEconomyState(
      source: ShopEconomySource.cloud,
      status: ShopCloudEconomyStatus.loading,
      userId: currentUserId,
    );

    final snapshotResult = await _shopCloudReadRepository.fetchShopSnapshot();
    final activeUserId = _currentSupabaseUserId();
    if (activeUserId == null || activeUserId != currentUserId) {
      _clearCloudEconomyForSessionChange();
      return;
    }

    if (!snapshotResult.isSuccess || snapshotResult.data == null) {
      _handleHydrationFailure(
        currentUserId: currentUserId,
        errorCode: snapshotResult.error?.code,
      );
      return;
    }

    final snapshot = snapshotResult.data!;
    if (snapshot.authenticatedUserId.trim() != currentUserId) {
      _clearCloudEconomyForSessionChange();
      return;
    }

    if (snapshot.wallet == null) {
      _cloudSnapshotByUserId[currentUserId] = snapshot;
      _cloudEconomyUserId = currentUserId;
      _cloudPurchaseWalletCoins = null;
      _cloudPurchaseInventoryQuantityByItemId.clear();
      _setEconomyState(
        source: ShopEconomySource.cloud,
        status: ShopCloudEconomyStatus.walletMissing,
        userId: currentUserId,
        snapshot: snapshot,
      );
      return;
    }

    _cloudSnapshotByUserId[currentUserId] = snapshot;
    _cloudEconomyUserId = currentUserId;
    _cloudPurchaseWalletCoins = snapshot.wallet?.coins;
    _cloudPurchaseInventoryQuantityByItemId
      ..clear()
      ..addEntries(
        snapshot.inventory
            .where((row) => _supportedCloudUtilityIds.contains(row.itemId))
            .map((row) => MapEntry(row.itemId, row.quantity)),
      );
    _setEconomyState(
      source: ShopEconomySource.cloud,
      status: ShopCloudEconomyStatus.ready,
      userId: currentUserId,
      snapshot: snapshot,
    );
  }

  void _handleHydrationFailure({
    required String currentUserId,
    ShopCloudErrorCode? errorCode,
  }) {
    final hasCachedSnapshot = _cloudSnapshotByUserId.containsKey(currentUserId);
    switch (errorCode) {
      case ShopCloudErrorCode.walletMissing:
        _setEconomyState(
          source: ShopEconomySource.cloud,
          status: ShopCloudEconomyStatus.walletMissing,
          userId: currentUserId,
        );
        break;
      case ShopCloudErrorCode.unauthenticated:
      case ShopCloudErrorCode.sessionChanged:
        _clearCloudEconomyForSessionChange();
        break;
      case ShopCloudErrorCode.featureDisabled:
        _setEconomyState(
          source: ShopEconomySource.local,
          status: ShopCloudEconomyStatus.disabled,
        );
        break;
      case ShopCloudErrorCode.networkUnavailable:
      case ShopCloudErrorCode.timeout:
      case ShopCloudErrorCode.malformedResponse:
      case ShopCloudErrorCode.invalidRemoteItem:
      case ShopCloudErrorCode.unknown:
      case null:
        _setEconomyState(
          source: ShopEconomySource.cloud,
          status: hasCachedSnapshot
              ? ShopCloudEconomyStatus.stale
              : ShopCloudEconomyStatus.failed,
          userId: currentUserId,
        );
        break;
    }
  }

  void _clearCloudEconomyForSessionChange() {
    _cloudEconomyUserId = null;
    _cloudPurchaseWalletCoins = null;
    _cloudPurchaseInventoryQuantityByItemId.clear();
    _setEconomyState(
      source: ShopEconomySource.local,
      status: ShopCloudEconomyStatus.unauthenticated,
    );
  }

  void _setUnauthenticatedVisibleEconomy() {
    _clearCloudEconomyForSessionChange();
  }

  void _setEconomyState({
    required ShopEconomySource source,
    required ShopCloudEconomyStatus status,
    String? userId,
    ShopCloudSnapshot? snapshot,
  }) {
    final changed = _economySource != source ||
        _economyStatus != status ||
        _cloudEconomyUserId != userId;
    _economySource = source;
    _economyStatus = status;
    if (snapshot != null && userId != null) {
      _cloudSnapshotByUserId[userId] = snapshot;
    }
    if (userId != null) {
      _cloudEconomyUserId = userId;
    }
    if (changed) {
      notifyListeners();
    }
  }

  Future<ShopControllerResult> _purchaseCloudUtility(ShopItem item) async {
    try {
      final result = await _purchaseCloudUtilityUseCase.purchaseCloudUtility(
        itemId: item.id,
      );

      if (result.isSuccess && result.remoteResult != null) {
        await _applyCloudPurchaseResult(result.remoteResult!);
        final refreshFailed = await _refreshCloudPurchaseSnapshot(force: true);
        return _controllerResult(
          ShopControllerStatus.success,
          item: item,
          shopState: await _adjustedLocalShopState(item),
          walletCoins: _cloudPurchaseWalletCoins ?? getWalletCoins(),
          purchaseFailure: null,
          cloudPurchaseResult: result,
          cloudRefreshFailed: refreshFailed,
        );
      }

      if (result.isPending) {
        return _controllerResult(
          ShopControllerStatus.cloudPurchasePending,
          item: item,
          shopState: await _adjustedLocalShopState(item),
          walletCoins: _cloudPurchaseWalletCoins ?? getWalletCoins(),
          purchaseFailure: result.failure,
          cloudPurchaseResult: result,
        );
      }

      return _controllerResult(
        ShopControllerStatus.cloudPurchaseFailed,
        item: item,
        shopState: await _adjustedLocalShopState(item),
        walletCoins: _cloudPurchaseWalletCoins ?? getWalletCoins(),
        purchaseFailure: result.failure,
        cloudPurchaseResult: result,
      );
    } catch (error) {
      return _controllerResult(
        ShopControllerStatus.cloudPurchaseFailed,
        item: item,
        shopState: await _adjustedLocalShopState(item),
        walletCoins: visibleCoinBalance ?? 0,
        purchaseFailure: ShopPurchaseFailure(
          code: ShopPurchaseFailureCode.unknown,
          message: 'Unexpected cloud purchase error.',
          cause: error,
        ),
      );
    }
  }

  Future<bool> _refreshCloudPurchaseSnapshot({bool force = false}) async {
    if (!isCloudEconomyEnabled) return false;
    final currentUserId = _currentSupabaseUserId();
    if (currentUserId == null) {
      _clearCloudEconomyForSessionChange();
      return false;
    }

    if (!force && isCloudEconomyReady && _cloudEconomyUserId == currentUserId) {
      return false;
    }

    await hydrateVisibleEconomy(force: force);
    return _economyStatus != ShopCloudEconomyStatus.ready;
  }

  Future<void> _applyCloudPurchaseResult(
    RemoteShopPurchaseResultDto remoteResult,
  ) async {
    _cloudEconomyUserId = _currentSupabaseUserId();
    _cloudPurchaseWalletCoins = remoteResult.coins;
    _cloudPurchaseInventoryQuantityByItemId[remoteResult.itemId] =
        remoteResult.inventoryQuantity;
    if (_cloudEconomyUserId != null) {
      _cloudSnapshotByUserId[_cloudEconomyUserId!] = ShopCloudSnapshot(
        authenticatedUserId: _cloudEconomyUserId!,
        catalogItems: const <RemoteShopItemDto>[],
        wallet: RemoteWalletDto(
          userId: _cloudEconomyUserId!,
          coins: remoteResult.coins,
          version: remoteResult.walletVersion,
          createdAt: _nowProvider().toUtc(),
          updatedAt: _nowProvider().toUtc(),
        ),
        inventory: <RemoteInventoryItemDto>[
          RemoteInventoryItemDto(
            id: 'pending-${remoteResult.requestId}-${remoteResult.itemId}',
            userId: _cloudEconomyUserId!,
            itemId: remoteResult.itemId,
            quantity: remoteResult.inventoryQuantity,
            acquisitionSource: 'purchase',
            acquiredAt: _nowProvider().toUtc(),
            updatedAt: _nowProvider().toUtc(),
          ),
        ],
        equippedCosmetics: const <RemoteEquippedCosmeticDto>[],
        fetchedAt: _nowProvider().toUtc(),
        catalogVersion: null,
        warnings: const <ShopCloudWarning>[],
      );
      _setEconomyState(
        source: ShopEconomySource.cloud,
        status: ShopCloudEconomyStatus.stale,
        userId: _cloudEconomyUserId,
      );
    }
    final currentUserId = _currentSupabaseUserId();
    if (currentUserId != null) {
      unawaited(
        _globalWalletController?.syncSession(
            userId: currentUserId, force: true),
      );
    }
  }

  Future<ShopState> _adjustedLocalShopState(ShopItem item) async {
    final shopState = await _shopRepository.load();
    return _adjustShopStateForCloudPurchase(item, shopState);
  }

  ShopState _adjustShopStateForCloudPurchase(
    ShopItem? item,
    ShopState shopState,
  ) {
    if (!isCloudEconomyEnabled) {
      return shopState;
    }

    final updatedBackpackItems = shopState.backpackItems.map((entry) {
      final cloudQuantity =
          _cloudPurchaseInventoryQuantityByItemId[entry.itemId];
      if (cloudQuantity == null) return entry;
      return entry.copyWith(quantity: cloudQuantity);
    }).toList(growable: true);

    for (final entry in _cloudPurchaseInventoryQuantityByItemId.entries) {
      if (entry.value <= 0 ||
          updatedBackpackItems.any((item) => item.itemId == entry.key)) {
        continue;
      }
      updatedBackpackItems.add(
        BackpackItem(
          itemId: entry.key,
          quantity: entry.value,
          updatedAtMillis: _nowProvider().millisecondsSinceEpoch,
        ),
      );
    }

    if (item != null && _shouldUseCloudPurchase(item)) {
      final cloudQuantity = _cloudPurchaseInventoryQuantityByItemId[item.id];
      if (cloudQuantity != null &&
          !updatedBackpackItems.any((entry) => entry.itemId == item.id)) {
        updatedBackpackItems.add(
          BackpackItem(
            itemId: item.id,
            quantity: cloudQuantity,
            updatedAtMillis: _nowProvider().millisecondsSinceEpoch,
          ),
        );
      }
    }

    return shopState.copyWith(backpackItems: updatedBackpackItems);
  }

  int _walletCoinsForItem(ShopItem item) {
    if (_shouldUseCloudPurchase(item) && _cloudPurchaseWalletCoins != null) {
      return _cloudPurchaseWalletCoins!;
    }
    return _walletCoins();
  }

  int _walletCoinsFromRoot(Map<String, dynamic> root) {
    final userState = root['userState'] as Map?;
    final wallet = userState?['wallet'] as Map?;
    return ((wallet?['coins'] as num?) ?? 0).toInt();
  }

  int _walletCoins() {
    final globalWalletController = _globalWalletController;
    if (globalWalletController != null && globalWalletController.isEnabled) {
      return globalWalletController.state.coins ?? 0;
    }

    final root = _userStateStore.state;
    if (root == null) return 0;
    return _walletCoinsFromRoot(root);
  }

  ShopItemState _buildItemState({
    required ShopItem item,
    required ShopState shopState,
    required int walletCoins,
  }) {
    final owned = item.category == ShopItemCategory.cosmetic &&
        shopState.inventory.any((entry) => entry.itemId == item.id);
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
    ShopPurchaseFailure? purchaseFailure,
    ShopPurchaseResult? cloudPurchaseResult,
    bool cloudRefreshFailed = false,
  }) {
    return ShopControllerResult(
      status: status,
      item: item,
      shopState: shopState,
      walletCoins: walletCoins ?? getWalletCoins(),
      purchaseFailure: purchaseFailure,
      cloudPurchaseResult: cloudPurchaseResult,
      cloudRefreshFailed: cloudRefreshFailed,
    );
  }

  Future<void> refreshCloudPurchaseSnapshot() async {
    await _refreshCloudPurchaseSnapshot();
  }

  Future<List<ShopPurchaseResult>> resolvePendingPurchasesForCurrentUser({
    int maxOperations = 3,
  }) async {
    final results = await _purchaseCloudUtilityUseCase
        .resolvePendingPurchasesForCurrentUser(
      maxOperations: maxOperations,
    );
    if (results.any((result) => result.isSuccess)) {
      await _refreshCloudPurchaseSnapshot(force: true);
      final currentUserId = _currentSupabaseUserId();
      if (currentUserId != null) {
        unawaited(
          _globalWalletController?.syncSession(
            userId: currentUserId,
            force: true,
          ),
        );
      }
    }
    return results;
  }

  String? _currentScopeUserId() {
    final scope =
        (_userStateStore.activeLocalScopeUserId ?? _userStateStore.userId ?? '')
            .trim();
    return scope.isEmpty ? null : scope;
  }

  static String? _defaultCurrentSupabaseUserId() {
    try {
      final userId = RutioSupabaseClient.instance.auth.currentUser?.id.trim();
      if (userId == null || userId.isEmpty) return null;
      return userId;
    } catch (_) {
      return null;
    }
  }

  String? _currentSupabaseUserId() {
    try {
      final userId = _currentSupabaseUserIdProvider()?.trim();
      if (userId == null || userId.isEmpty) return null;
      return userId;
    } catch (_) {
      return null;
    }
  }

  String _activationKey(String utilityId) {
    return '${_currentScopeUserId() ?? ''}|${utilityId.trim()}';
  }

  Future<List<MysteryBoxOpeningTransaction>>
      _loadPendingMysteryBoxOpenings() async {
    final scope = _currentScopeUserId();
    if (scope == null) return const <MysteryBoxOpeningTransaction>[];
    final transactions =
        await _mysteryBoxOpeningRepository.loadTransactions(scope);
    return transactions
        .where((transaction) => transaction.isPendingPresentation)
        .toList(growable: false);
  }

  String _generateMysteryBoxTransactionId() {
    final nowMillis = _nowProvider().microsecondsSinceEpoch;
    final randomPart = _randomSource.nextInt(1 << 31);
    return 'mystery_box_${nowMillis}_$randomPart';
  }

  List<ActiveUtilityEffect> _streakShieldEffectsFromStore() {
    final effects = <ActiveUtilityEffect>[];
    for (final shield in _userStateStore.activeStreakShields) {
      if (!shield.isActive) continue;
      effects.add(
        ActiveUtilityEffect(
          id: shield.id,
          utilityId: shield.utilityId,
          type: ActiveUtilityEffectType.streakShield,
          activatedAtMillis: shield.activatedAtMillis,
          remainingUses: 1,
          totalUses: 1,
          habitId: shield.habitId,
        ),
      );
    }
    effects.sort((a, b) {
      final byActivation = a.activatedAtMillis.compareTo(b.activatedAtMillis);
      if (byActivation != 0) return byActivation;
      return a.id.compareTo(b.id);
    });
    return effects;
  }

  String _activationEffectId(String utilityId, int activatedAtMillis) {
    return '${utilityId.trim()}_$activatedAtMillis';
  }

  String _utilityActivationRequestId({
    required String userId,
    required String utilityId,
  }) {
    final activatedAtMicros = _nowProvider().toUtc().microsecondsSinceEpoch;
    return 'utility_activate:${userId.trim()}:${utilityId.trim()}:$activatedAtMicros';
  }

  void _logUtilityActivationError(String utilityId, Object error) {
    if (!kDebugMode) return;
    debugPrint('[utility_activation] activateBoost($utilityId) failed: $error');
  }

  ShopControllerStatus _mapUtilityActivationFailure(Object error) {
    final normalized = error.toString().toLowerCase();
    if (normalized.contains('utility inventory unavailable') ||
        normalized.contains('inventory unavailable') ||
        normalized.contains('no utility inventory') ||
        normalized.contains('no backpack item')) {
      return ShopControllerStatus.backpackItemNotFound;
    }

    if (normalized.contains('active utility effect') ||
        normalized.contains('already active') ||
        normalized.contains('duplicate key') ||
        normalized.contains('unique constraint') ||
        normalized.contains('violates unique constraint') ||
        normalized.contains('request_id already used') ||
        normalized.contains('source_id already used')) {
      return ShopControllerStatus.utilityAlreadyActive;
    }

    if (normalized.contains('authentication required') ||
        normalized.contains('unauthenticated') ||
        normalized.contains('session changed') ||
        normalized.contains('user session') ||
        normalized.contains('user_id is required') ||
        normalized.contains('authentication is required')) {
      return ShopControllerStatus.unavailableState;
    }

    if (normalized.contains('timeout') ||
        normalized.contains('network') ||
        normalized.contains('socket') ||
        normalized.contains('connection')) {
      return ShopControllerStatus.unavailableState;
    }

    return ShopControllerStatus.unavailableState;
  }
}
