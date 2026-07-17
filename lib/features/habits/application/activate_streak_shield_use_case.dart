import 'dart:convert';

import 'package:rutio/features/habits/domain/models/streak_shield_operation_result.dart';
import 'package:rutio/features/shop/data/shop_catalog.dart';
import 'package:rutio/features/shop/data/shop_local_repository.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/application/shop_service.dart';
import 'package:rutio/stores/user_state_store.dart';

class ActivateStreakShieldUseCase {
  ActivateStreakShieldUseCase({
    required UserStateStore userStateStore,
    required ShopLocalRepository shopRepository,
    DateTime Function()? nowProvider,
  })  : _userStateStore = userStateStore,
        _shopRepository = shopRepository,
        _nowProvider = nowProvider ?? DateTime.now;

  final UserStateStore _userStateStore;
  final ShopLocalRepository _shopRepository;
  final DateTime Function() _nowProvider;

  Future<StreakShieldOperationResult> execute({
    required String habitId,
    required String operationId,
    String utilityId = 'utility_streak_shield_1',
  }) async {
    final normalizedHabitId = habitId.trim();
    final normalizedOperationId = operationId.trim();
    final normalizedUtilityId = utilityId.trim();
    if (normalizedHabitId.isEmpty || normalizedOperationId.isEmpty) {
      return const StreakShieldOperationResult(
        status: StreakShieldOperationStatus.operationAlreadyProcessed,
      );
    }

    final item = ShopCatalog.getItemById(normalizedUtilityId);
    if (item == null || item.type != ShopItemType.streakShield) {
      return const StreakShieldOperationResult(
        status: StreakShieldOperationStatus.habitNotEligible,
      );
    }

    final root = await _ensureRoot();
    if (root == null) {
      return const StreakShieldOperationResult(
        status: StreakShieldOperationStatus.persistenceFailure,
      );
    }

    final shopState = await _shopRepository.load();
    final walletCoins = _walletCoinsFromRoot(root);
    final consumeResult = ShopService(
      state: shopState,
      walletCoins: walletCoins,
      nowMillisProvider: () => _nowProvider().millisecondsSinceEpoch,
    ).consumeBackpackItem(normalizedUtilityId);

    if (!consumeResult.isSuccess) {
      return const StreakShieldOperationResult(
        status: StreakShieldOperationStatus.noInventory,
      );
    }

    try {
      final result = await _userStateStore.activateStreakShield(
        habitId: normalizedHabitId,
        operationId: normalizedOperationId,
        utilityId: normalizedUtilityId,
      );
      if (!result.isSuccess) {
        await _shopRepository.save(shopState);
      } else {
        await _shopRepository.save(consumeResult.state);
      }
      return result;
    } catch (error) {
      await _shopRepository.save(shopState);
      return StreakShieldOperationResult(
        status: StreakShieldOperationStatus.persistenceFailure,
        errorMessage: error.toString(),
      );
    }
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
