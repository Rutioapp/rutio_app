import 'dart:convert';

import 'package:rutio/features/habits/domain/models/recoverable_streak_break.dart';
import 'package:rutio/features/habits/domain/models/streak_recover_operation_result.dart';
import 'package:rutio/features/shop/application/shop_service.dart';
import 'package:rutio/features/shop/data/shop_local_repository.dart';
import 'package:rutio/stores/user_state_store.dart';

class RecoverStreakUseCase {
  RecoverStreakUseCase({
    required UserStateStore userStateStore,
    required ShopLocalRepository shopRepository,
    DateTime Function()? nowProvider,
  })  : _userStateStore = userStateStore,
        _shopRepository = shopRepository,
        _nowProvider = nowProvider ?? DateTime.now;

  final UserStateStore _userStateStore;
  final ShopLocalRepository _shopRepository;
  final DateTime Function() _nowProvider;

  Future<StreakRecoverOperationResult> execute({
    required String breakId,
    required String operationId,
    String utilityId = 'utility_streak_recover_1',
  }) async {
    final normalizedBreakId = breakId.trim();
    final normalizedOperationId = operationId.trim();
    final normalizedUtilityId = utilityId.trim();
    if (normalizedBreakId.isEmpty || normalizedOperationId.isEmpty) {
      return const StreakRecoverOperationResult(
        status: StreakRecoverOperationStatus.operationAlreadyProcessed,
      );
    }

    final root = await _ensureRoot();
    if (root == null) {
      return const StreakRecoverOperationResult(
        status: StreakRecoverOperationStatus.persistenceFailure,
      );
    }

    final shopState = await _shopRepository.load();
    final walletCoins = _walletCoinsFromRoot(root);
    final breakRecord = _recoverableBreakById(normalizedBreakId);
    if (breakRecord == null) {
      return const StreakRecoverOperationResult(
        status: StreakRecoverOperationStatus.noRecoverableBreak,
      );
    }
    if (breakRecord.isRecovered) {
      return StreakRecoverOperationResult(
        status: StreakRecoverOperationStatus.alreadyRecovered,
        recoveredBreak: breakRecord,
      );
    }

    if (!_hasItem(shopState, normalizedUtilityId)) {
      return const StreakRecoverOperationResult(
        status: StreakRecoverOperationStatus.noInventory,
      );
    }

    final nextStoreResult = await _userStateStore.recoverStreakBreak(
      breakId: normalizedBreakId,
      operationId: normalizedOperationId,
    );
    if (!nextStoreResult.isSuccess) {
      return StreakRecoverOperationResult(
        status: _mapStatus(nextStoreResult.status),
        recoveredBreak: nextStoreResult.recoveredBreak,
        errorMessage: nextStoreResult.errorMessage,
      );
    }

    final consumeResult = ShopService(
      state: shopState,
      walletCoins: walletCoins,
      nowMillisProvider: () => _nowProvider().millisecondsSinceEpoch,
    ).consumeBackpackItem(normalizedUtilityId);
    if (!consumeResult.isSuccess) {
      await _restoreBestEffort(shopState);
      return const StreakRecoverOperationResult(
        status: StreakRecoverOperationStatus.persistenceFailure,
      );
    }

    try {
      await _shopRepository.save(consumeResult.state);
      return StreakRecoverOperationResult(
        status: StreakRecoverOperationStatus.success,
        recoveredBreak: nextStoreResult.recoveredBreak,
      );
    } catch (error) {
      await _restoreBestEffort(shopState);
      return StreakRecoverOperationResult(
        status: StreakRecoverOperationStatus.persistenceFailure,
        errorMessage: error.toString(),
      );
    }
  }

  RecoverableStreakBreak? _recoverableBreakById(String breakId) {
    final match = _userStateStore.recoverableStreakBreaks
        .where((entry) => entry.id == breakId)
        .toList(growable: false);
    if (match.isEmpty) return null;
    return match.first;
  }

  bool _hasItem(dynamic shopState, String utilityId) {
    final items = (shopState.backpackItems as Iterable?) ?? const [];
    return items.any((item) => item.itemId == utilityId);
  }

  StreakRecoverOperationStatus _mapStatus(
    StreakRecoverOperationStatus status,
  ) {
    return status;
  }

  Future<void> _restoreBestEffort(dynamic shopState) async {
    await _shopRepository.save(shopState);
  }

  Future<Map<String, dynamic>?> _ensureRoot() async {
    if (_userStateStore.state == null) {
      await _userStateStore.load();
    }
    final root = _userStateStore.state;
    if (root == null) return null;
    return Map<String, dynamic>.from(
      jsonDecode(jsonEncode(root)) as Map<String, dynamic>,
    );
  }

  int _walletCoinsFromRoot(Map<String, dynamic> root) {
    final userState = root['userState'] as Map?;
    final wallet = userState?['wallet'] as Map?;
    return ((wallet?['coins'] as num?) ?? 0).toInt();
  }
}
