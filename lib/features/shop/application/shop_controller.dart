import 'package:flutter/foundation.dart';
import 'package:rutio/features/shop/application/shop_operation_result.dart';
import 'package:rutio/features/shop/application/shop_service.dart';
import 'package:rutio/features/shop/application/mystery_box_operation_result.dart';
import 'package:rutio/features/shop/application/open_mystery_box_use_case.dart';
import 'package:rutio/features/shop/application/present_mystery_box_result_use_case.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_config.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_errors.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_read_repository.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_snapshot.dart';
import 'package:rutio/features/habits/application/activate_streak_shield_use_case.dart';
import 'package:rutio/features/habits/application/recover_streak_use_case.dart';
import 'package:rutio/features/habits/domain/models/active_streak_shield.dart';
import 'package:rutio/features/habits/domain/models/recoverable_streak_break.dart';
import 'package:rutio/features/habits/domain/models/streak_recover_operation_result.dart';
import 'package:rutio/features/habits/domain/models/streak_shield_operation_result.dart';
import 'package:rutio/features/shop/data/local_active_utility_effects_repository.dart';
import 'package:rutio/features/shop/data/dart_random_source.dart';
import 'package:rutio/features/shop/data/local_mystery_box_opening_repository.dart';
import 'package:rutio/features/shop/data/shop_catalog.dart';
import 'package:rutio/features/shop/data/shop_local_repository.dart';
import 'package:rutio/features/shop/domain/active_utility_effects_repository.dart';
import 'package:rutio/features/shop/domain/models/active_utility_effect.dart';
import 'package:rutio/features/shop/domain/mystery_box_opening_repository.dart';
import 'package:rutio/features/shop/domain/random_source.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/domain/models/mystery_box_opening_transaction.dart';
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
  utilityAlreadyActive,
  utilityActivationInProgress,
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
    ActiveUtilityEffectsRepository? activeUtilityEffectsRepository,
    MysteryBoxOpeningRepository? mysteryBoxOpeningRepository,
    RandomSource? randomSource,
    DateTime Function()? nowProvider,
    ShopCloudReadRepository? shopCloudReadRepository,
  })  : _userStateStore = userStateStore,
        _shopRepository = shopRepository ??
            ShopLocalRepository(
              scopeResolver: () =>
                  userStateStore.activeLocalScopeUserId ??
                  userStateStore.userId,
            ),
        _activeUtilityEffectsRepository = activeUtilityEffectsRepository ??
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
        _randomSource = randomSource ?? DartRandomSource(),
        _nowProvider = nowProvider ?? DateTime.now,
        _shopCloudReadRepository = shopCloudReadRepository ??
            ShopCloudReadRepository(
              readEnabled: ShopCloudConfig.isReadEnabled,
            );

  final UserStateStore _userStateStore;
  final ShopLocalRepository _shopRepository;
  final ActiveUtilityEffectsRepository _activeUtilityEffectsRepository;
  final MysteryBoxOpeningRepository _mysteryBoxOpeningRepository;
  final RandomSource _randomSource;
  final DateTime Function() _nowProvider;
  final ShopCloudReadRepository _shopCloudReadRepository;
  final Set<String> _pendingUtilityActivations = <String>{};
  final Set<String> _pendingMysteryBoxScopes = <String>{};

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

      final activeEffects =
          await _activeUtilityEffectsRepository.loadEffects(scope);
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
    } finally {
      _pendingUtilityActivations.remove(activationKey);
    }
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
        randomSource: _randomSource,
        nowProvider: _nowProvider,
      ).open(transactionId: effectiveTransactionId);

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
    if (!ShopCloudConfig.isReadEnabled) {
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
  }) {
    return ShopControllerResult(
      status: status,
      item: item,
      shopState: shopState,
      walletCoins: walletCoins ?? getWalletCoins(),
    );
  }

  String? _currentScopeUserId() {
    final scope =
        (_userStateStore.activeLocalScopeUserId ?? _userStateStore.userId ?? '')
            .trim();
    return scope.isEmpty ? null : scope;
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
}
