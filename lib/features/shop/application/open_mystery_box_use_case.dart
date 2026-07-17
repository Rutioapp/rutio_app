import 'dart:convert';

import 'package:rutio/features/gamification/domain/level_progression.dart';
import 'package:rutio/features/shop/application/mystery_box_operation_result.dart';
import 'package:rutio/features/shop/data/mystery_box_reward_catalog.dart';
import 'package:rutio/features/shop/domain/mystery_box_opening_repository.dart';
import 'package:rutio/features/shop/domain/mystery_box_reward_resolver.dart';
import 'package:rutio/features/shop/domain/models/mystery_box_opening_transaction.dart';
import 'package:rutio/features/shop/domain/models/mystery_box_reward_result.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/domain/random_source.dart';
import 'package:rutio/features/shop/domain/shop_state.dart';
import 'package:rutio/features/shop/data/shop_catalog.dart';
import 'package:rutio/features/shop/application/shop_service.dart';
import 'package:rutio/features/shop/data/shop_local_repository.dart';
import 'package:rutio/stores/user_state_store.dart';

class OpenMysteryBoxUseCase {
  OpenMysteryBoxUseCase({
    required UserStateStore userStateStore,
    required ShopLocalRepository shopRepository,
    required MysteryBoxOpeningRepository mysteryBoxOpeningRepository,
    required RandomSource randomSource,
    DateTime Function()? nowProvider,
  })  : _userStateStore = userStateStore,
        _shopRepository = shopRepository,
        _mysteryBoxOpeningRepository = mysteryBoxOpeningRepository,
        _randomSource = randomSource,
        _nowProvider = nowProvider ?? DateTime.now;

  final UserStateStore _userStateStore;
  final ShopLocalRepository _shopRepository;
  final MysteryBoxOpeningRepository _mysteryBoxOpeningRepository;
  final RandomSource _randomSource;
  final DateTime Function() _nowProvider;

  Future<MysteryBoxOperationResult> open({
    required String transactionId,
  }) async {
    final normalizedTransactionId = transactionId.trim();
    if (normalizedTransactionId.isEmpty) {
      return const MysteryBoxOperationResult(
        status: MysteryBoxOperationStatus.invalidTransactionId,
      );
    }

    final scope = _currentScopeUserId();
    if (scope == null) {
      return const MysteryBoxOperationResult(
        status: MysteryBoxOperationStatus.unavailableState,
      );
    }

    final pendingTransactions =
        await _mysteryBoxOpeningRepository.loadTransactions(scope);
    MysteryBoxOpeningTransaction? existingTransaction;
    for (final transaction in pendingTransactions) {
      if (transaction.id == normalizedTransactionId) {
        existingTransaction = transaction;
        break;
      }
    }
    if (existingTransaction != null) {
      final root = await _ensureRoot();
      if (existingTransaction.isPresented || existingTransaction.isGranted) {
        return MysteryBoxOperationResult(
          status: MysteryBoxOperationStatus.success,
          transaction: existingTransaction,
          shopState: await _shopRepository.load(),
          walletCoins: _walletCoinsFromRoot(root),
        );
      }
      return MysteryBoxOperationResult(
        status: MysteryBoxOperationStatus.duplicateTransaction,
        transaction: existingTransaction,
      );
    }

    final pendingPresentationTransactions = pendingTransactions
        .where((transaction) => transaction.isPendingPresentation)
        .toList(growable: false);
    if (pendingPresentationTransactions.isNotEmpty) {
      return MysteryBoxOperationResult(
        status: MysteryBoxOperationStatus.duplicateTransaction,
        transaction: pendingPresentationTransactions.first,
      );
    }

    final validationErrors = MysteryBoxRewardCatalog.validateConfiguration();
    if (validationErrors.isNotEmpty) {
      return MysteryBoxOperationResult(
        status: MysteryBoxOperationStatus.invalidConfiguration,
        errorMessage: validationErrors.join('; '),
      );
    }

    final root = await _ensureRoot();
    if (root == null) {
      return const MysteryBoxOperationResult(
        status: MysteryBoxOperationStatus.unavailableState,
      );
    }

    final originalRoot = _cloneMap(root);
    final originalShopState = await _shopRepository.load();
    final originalTransactions = pendingTransactions;

    final mysteryBoxItem = ShopCatalog.getItemById(
      MysteryBoxRewardCatalog.mysteryBoxUtilityId,
    );
    if (mysteryBoxItem == null ||
        mysteryBoxItem.category != ShopItemCategory.utility ||
        mysteryBoxItem.type != ShopItemType.mysteryBox) {
      return const MysteryBoxOperationResult(
        status: MysteryBoxOperationStatus.invalidConfiguration,
        errorMessage: 'Mystery Box item is not configured.',
      );
    }

    final shopService = ShopService(
      state: originalShopState,
      walletCoins: _walletCoinsFromRoot(root),
      nowMillisProvider: () => _nowProvider().millisecondsSinceEpoch,
    );
    final consumeResult = shopService.consumeBackpackItem(mysteryBoxItem.id);
    if (!consumeResult.isSuccess) {
      return const MysteryBoxOperationResult(
        status: MysteryBoxOperationStatus.noBoxes,
      );
    }

    final rewardDefinition = const MysteryBoxRewardResolver().resolve(
      catalog: MysteryBoxRewardCatalog.defaultRewards,
      randomSource: _randomSource,
    );
    final reward = MysteryBoxRewardResult(
      rewardId: rewardDefinition.id,
      coins: rewardDefinition.coins,
      xp: rewardDefinition.xp,
      utilityRewards: Map<String, int>.from(rewardDefinition.utilityRewards),
    );

    final nextShopState = _applyUtilityRewards(
      consumeResult.state,
      reward.utilityRewards,
    );
    final nextRoot = _applyRewardToRoot(
      root,
      reward: reward,
    );
    final transaction = MysteryBoxOpeningTransaction(
      id: normalizedTransactionId,
      userScope: scope,
      mysteryBoxUtilityId: mysteryBoxItem.id,
      reward: reward,
      createdAtMillis: _nowProvider().millisecondsSinceEpoch,
      status: MysteryBoxOpeningStatus.granted,
    );
    final nextTransactions = <MysteryBoxOpeningTransaction>[
      ...pendingTransactions.where((entry) => entry.id != normalizedTransactionId),
      transaction,
    ];

    try {
      await _shopRepository.save(nextShopState);
      await _mysteryBoxOpeningRepository.saveTransactions(
        scope,
        nextTransactions,
      );
      await _userStateStore.save(nextRoot);
    } catch (error) {
      try {
        await _shopRepository.save(originalShopState);
      } catch (_) {}
      try {
        await _mysteryBoxOpeningRepository.saveTransactions(
          scope,
          originalTransactions,
        );
      } catch (_) {}
      try {
        await _userStateStore.save(originalRoot);
      } catch (_) {}

      return MysteryBoxOperationResult(
        status: MysteryBoxOperationStatus.persistenceError,
        errorMessage: error.toString(),
      );
    }

    return MysteryBoxOperationResult(
      status: MysteryBoxOperationStatus.success,
      transaction: transaction,
      shopState: nextShopState,
      walletCoins: _walletCoinsFromRoot(nextRoot),
    );
  }

  Future<List<MysteryBoxOpeningTransaction>> loadPendingOpenings() async {
    final scope = _currentScopeUserId();
    if (scope == null) return const <MysteryBoxOpeningTransaction>[];
    final transactions = await _mysteryBoxOpeningRepository.loadTransactions(scope);
    return transactions
        .where((transaction) => transaction.isPendingPresentation)
        .toList(growable: false);
  }

  Future<MysteryBoxOperationResult> markPresented(String transactionId) async {
    final normalizedTransactionId = transactionId.trim();
    if (normalizedTransactionId.isEmpty) {
      return const MysteryBoxOperationResult(
        status: MysteryBoxOperationStatus.invalidTransactionId,
      );
    }

    final scope = _currentScopeUserId();
    if (scope == null) {
      return const MysteryBoxOperationResult(
        status: MysteryBoxOperationStatus.unavailableState,
      );
    }

    final transactions = await _mysteryBoxOpeningRepository.loadTransactions(scope);
    final index = transactions.indexWhere((tx) => tx.id == normalizedTransactionId);
    if (index == -1) {
      return const MysteryBoxOperationResult(
        status: MysteryBoxOperationStatus.transactionNotFound,
      );
    }

    final current = transactions[index];
    if (current.isPresented) {
      return MysteryBoxOperationResult(
        status: MysteryBoxOperationStatus.success,
        transaction: current,
      );
    }

    final next = current.copyWith(status: MysteryBoxOpeningStatus.presented);
    final nextTransactions = List<MysteryBoxOpeningTransaction>.from(transactions)
      ..[index] = next;

    try {
      await _mysteryBoxOpeningRepository.saveTransactions(scope, nextTransactions);
    } catch (error) {
      return MysteryBoxOperationResult(
        status: MysteryBoxOperationStatus.persistenceError,
        transaction: current,
        errorMessage: error.toString(),
      );
    }

    return MysteryBoxOperationResult(
      status: MysteryBoxOperationStatus.success,
      transaction: next,
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

  String? _currentScopeUserId() {
    final scope = (_userStateStore.activeLocalScopeUserId ??
            _userStateStore.userId ??
            '')
        .trim();
    return scope.isEmpty ? null : scope;
  }

  int _walletCoinsFromRoot(Map<String, dynamic>? root) {
    if (root == null) return 0;
    final userState = _ensureUserStateRoot(root);
    final wallet = _map(userState['wallet']);
    return (wallet['coins'] as num?)?.toInt() ?? 0;
  }

  Map<String, dynamic> _applyRewardToRoot(
    Map<String, dynamic> root, {
    required MysteryBoxRewardResult reward,
  }) {
    final nextRoot = _cloneMap(root);
    final userState = _ensureUserStateRoot(nextRoot);
    final progression = _map(userState['progression']);
    final wallet = _map(userState['wallet']);
    final daily = _map(userState['daily']);

    final currentXp = (progression['xp'] as num?)?.toInt() ?? 0;
    final nextXp = (currentXp + reward.xp).clamp(0, 1 << 30).toInt();
    final levelProgress = LevelProgression.fromTotalXp(nextXp);
    progression['xp'] = nextXp;
    progression['level'] = levelProgress.level;
    userState['progression'] = progression;

    final currentCoins = (wallet['coins'] as num?)?.toInt() ?? 0;
    wallet['coins'] = (currentCoins + reward.coins).clamp(0, 1 << 30).toInt();
    userState['wallet'] = wallet;

    daily['xpEarnedToday'] =
        (((daily['xpEarnedToday'] as num?)?.toInt() ?? 0) + reward.xp)
            .clamp(0, 1 << 30)
            .toInt();
    daily['coinsEarnedToday'] =
        (((daily['coinsEarnedToday'] as num?)?.toInt() ?? 0) + reward.coins)
            .clamp(0, 1 << 30)
            .toInt();
    userState['daily'] = daily;
    nextRoot['userState'] = userState;
    return nextRoot;
  }

  ShopState _applyUtilityRewards(
    ShopState shopState,
    Map<String, int> utilityRewards,
  ) {
    var nextState = shopState;

    for (final entry in utilityRewards.entries) {
      final utilityId = entry.key.trim();
      final quantity = entry.value;
      if (utilityId.isEmpty || quantity <= 0) continue;
      final service = ShopService(
        state: nextState,
        walletCoins: _walletCoinsFromRoot(_userStateStore.state),
        nowMillisProvider: () => _nowProvider().millisecondsSinceEpoch,
      );
      final addResult = service.addToBackpack(utilityId, quantity);
      nextState = addResult.state;
    }

    return nextState;
  }

  Map<String, dynamic> _cloneMap(Map<String, dynamic> value) {
    return Map<String, dynamic>.from(
      jsonDecode(jsonEncode(value)) as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> _ensureUserStateRoot(Map<String, dynamic> root) {
    final userState = Map<String, dynamic>.from(root['userState'] as Map? ?? <String, dynamic>{});
    root['userState'] = userState;
    return userState;
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
    if (value is Map) return Map<String, dynamic>.from(value.cast<String, dynamic>());
    return <String, dynamic>{};
  }
}
