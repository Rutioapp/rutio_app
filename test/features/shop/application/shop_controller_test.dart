import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/features/shop/application/mystery_box_operation_result.dart';
import 'package:rutio/features/shop/application/shop_controller.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_dtos.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_errors.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_read_repository.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_snapshot.dart';
import 'package:rutio/features/shop/data/cloud/utility_consumption_ledger.dart';
import 'package:rutio/features/shop/data/local_active_utility_effects_repository.dart';
import 'package:rutio/features/shop/data/cloud/utility_consumption_repository.dart';
import 'package:rutio/features/shop/data/shop_local_repository.dart';
import 'package:rutio/features/shop/domain/active_utility_effects_repository.dart';
import 'package:rutio/features/shop/domain/models/active_utility_effect.dart';
import 'package:rutio/features/shop/domain/models/backpack_item.dart';
import 'package:rutio/features/shop/domain/models/owned_shop_item.dart';
import 'package:rutio/features/shop/domain/mystery_box_opening_repository.dart';
import 'package:rutio/features/shop/domain/models/mystery_box_opening_transaction.dart';
import 'package:rutio/features/shop/domain/shop_state.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rutio/features/habits/domain/models/streak_recover_operation_result.dart';
import 'package:rutio/features/habits/domain/models/streak_shield_operation_result.dart';

import '../../../support/fixed_random_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShopController', () {
    test('cloud economy disabled stays local when purchase flag is off',
        () async {
      final controller = await _createController(
        walletCoins: 500,
        cloudReadEnabled: true,
        cloudPurchaseEnabled: false,
        currentSupabaseUserIdProvider: () => 'shop-controller-user',
        shopCloudReadRepository: _FakeShopCloudReadRepository(
          snapshotFactory: () => _cloudSnapshot(walletCoins: 10000),
        ),
      );

      await controller.hydrateVisibleEconomy();

      expect(controller.economySource, ShopEconomySource.local);
      expect(controller.visibleCoinBalance, 500);
    });

    test('cloud economy becomes visible when both flags are enabled', () async {
      final controller = await _createController(
        walletCoins: 500,
        cloudReadEnabled: true,
        cloudPurchaseEnabled: true,
        currentSupabaseUserIdProvider: () => 'shop-controller-user',
        shopCloudReadRepository: _FakeShopCloudReadRepository(
          snapshotFactory: () => _cloudSnapshot(
            walletCoins: 10000,
            itemId: 'utility_xp_boost_1d',
            quantity: 1,
          ),
        ),
      );

      await controller.hydrateVisibleEconomy();
      final visibleShopState = await controller.getVisibleShopState();

      expect(controller.economySource, ShopEconomySource.cloud);
      expect(controller.economyStatus, ShopCloudEconomyStatus.ready);
      expect(controller.visibleCoinBalance, 10000);
      expect(
        visibleShopState.backpackItems
            .singleWhere(
              (entry) => entry.itemId == 'utility_xp_boost_1d',
            )
            .quantity,
        1,
      );
    });

    test('cloud economy reports walletMissing when remote wallet is absent',
        () async {
      final controller = await _createController(
        walletCoins: 500,
        cloudReadEnabled: true,
        cloudPurchaseEnabled: true,
        currentSupabaseUserIdProvider: () => 'shop-controller-user',
        shopCloudReadRepository: _FakeShopCloudReadRepository(
          snapshotFactory: () => _cloudSnapshot(walletCoins: null),
        ),
      );

      await controller.hydrateVisibleEconomy();

      expect(controller.economySource, ShopEconomySource.cloud);
      expect(controller.economyStatus, ShopCloudEconomyStatus.walletMissing);
      expect(controller.visibleCoinBalance, isNull);
    });

    test(
        'cloud inventory removes stale local quantity when remote row is missing',
        () async {
      final controller = await _createController(
        walletCoins: 500,
        shopState: const ShopState(
          backpackItems: <BackpackItem>[
            BackpackItem(itemId: 'utility_xp_boost_1d', quantity: 2),
          ],
        ),
        cloudReadEnabled: true,
        cloudPurchaseEnabled: true,
        currentSupabaseUserIdProvider: () => 'shop-controller-user',
        shopCloudReadRepository: _FakeShopCloudReadRepository(
          snapshotFactory: () =>
              _cloudSnapshot(walletCoins: 10000, quantity: 0),
        ),
      );

      await controller.hydrateVisibleEconomy();
      final visibleShopState = await controller.getVisibleShopState();

      expect(
        visibleShopState.backpackItems
            .where((entry) => entry.itemId == 'utility_xp_boost_1d'),
        isEmpty,
      );
    });

    test('cloud inventory quantity 1 replaces any local quantity', () async {
      final controller = await _createController(
        walletCoins: 500,
        shopState: const ShopState(
          backpackItems: <BackpackItem>[
            BackpackItem(itemId: 'utility_xp_boost_1d', quantity: 2),
          ],
        ),
        cloudReadEnabled: true,
        cloudPurchaseEnabled: true,
        currentSupabaseUserIdProvider: () => 'shop-controller-user',
        shopCloudReadRepository: _FakeShopCloudReadRepository(
          snapshotFactory: () => _cloudSnapshot(
            walletCoins: 10000,
            itemId: 'utility_xp_boost_1d',
            quantity: 1,
          ),
        ),
      );

      await controller.hydrateVisibleEconomy();
      final visibleShopState = await controller.getVisibleShopState();
      final cloudEntries = visibleShopState.backpackItems
          .where((entry) => entry.itemId == 'utility_xp_boost_1d')
          .toList(growable: false);

      expect(cloudEntries, hasLength(1));
      expect(cloudEntries.single.quantity, 1);
    });

    test('cloud inventory does not create duplicate backpack entries',
        () async {
      final controller = await _createController(
        walletCoins: 500,
        shopState: const ShopState(
          backpackItems: <BackpackItem>[
            BackpackItem(itemId: 'utility_xp_boost_1d', quantity: 1),
            BackpackItem(itemId: 'utility_xp_boost_1d', quantity: 1),
          ],
        ),
        cloudReadEnabled: true,
        cloudPurchaseEnabled: true,
        currentSupabaseUserIdProvider: () => 'shop-controller-user',
        shopCloudReadRepository: _FakeShopCloudReadRepository(
          snapshotFactory: () => _cloudSnapshot(
            walletCoins: 10000,
            itemId: 'utility_xp_boost_1d',
            quantity: 1,
          ),
        ),
      );

      await controller.hydrateVisibleEconomy();
      final visibleShopState = await controller.getVisibleShopState();
      final cloudEntries = visibleShopState.backpackItems
          .where((entry) => entry.itemId == 'utility_xp_boost_1d')
          .toList(growable: false);

      expect(cloudEntries, hasLength(1));
      expect(cloudEntries.single.quantity, 1);
    });

    test('non-cloud backpack items keep their local state', () async {
      final shopRepository = _InMemoryShopRepository();
      const shopState = ShopState(
        backpackItems: <BackpackItem>[
          BackpackItem(itemId: 'utility_custom_local_only', quantity: 3),
        ],
      );
      final controller = await _createController(
        walletCoins: 500,
        shopState: shopState,
        shopRepository: shopRepository,
        cloudReadEnabled: true,
        cloudPurchaseEnabled: true,
        currentSupabaseUserIdProvider: () => 'shop-controller-user',
        shopCloudReadRepository: _FakeShopCloudReadRepository(
          snapshotFactory: () =>
              _cloudSnapshot(walletCoins: 10000, quantity: 0),
        ),
      );

      await controller.hydrateVisibleEconomy();
      final visibleShopState = await controller.getVisibleShopState();

      expect(visibleShopState.backpackItems, hasLength(1));
      expect(visibleShopState.backpackItems.single.itemId,
          'utility_custom_local_only');
      expect(visibleShopState.backpackItems.single.quantity, 3);
    });

    test('purchaseItem with missing item fails in a controlled way', () async {
      final controller = await _createController(walletCoins: 500);

      final result = await controller.purchaseItem('missing-item');

      expect(result.status, ShopControllerStatus.itemNotFound);
      expect(result.isSuccess, isFalse);
      expect(controller.getWalletCoins(), 500);
    });

    test('purchaseItem cosmetic spends wallet and adds inventory', () async {
      final controller = await _createController(walletCoins: 200);

      final result = await controller.purchaseItem('wallpaper_mist_blue');

      expect(result.status, ShopControllerStatus.success);
      expect(result.walletCoins, 80);
      expect(controller.getWalletCoins(), 80);
      expect(
        result.shopState.inventory.map((entry) => entry.itemId),
        contains('wallpaper_mist_blue'),
      );
    });

    test('purchaseItem utility spends wallet and adds backpack', () async {
      final controller = await _createController(walletCoins: 200);

      final result = await controller.purchaseItem('utility_xp_boost_1d');

      expect(result.status, ShopControllerStatus.success);
      expect(result.walletCoins, 125);
      expect(controller.getWalletCoins(), 125);
      expect(result.shopState.backpackItems, hasLength(1));
      expect(
          result.shopState.backpackItems.first.itemId, 'utility_xp_boost_1d');
      expect(result.shopState.backpackItems.first.quantity, 1);
      expect(result.shopState.backpackItems.first.updatedAtMillis, isNotNull);
    });

    test('purchaseItem utility twice accumulates quantity in backpack',
        () async {
      final controller = await _createController(walletCoins: 300);

      final first = await controller.purchaseItem('utility_xp_boost_1d');
      final second = await controller.purchaseItem('utility_xp_boost_1d');

      expect(first.status, ShopControllerStatus.success);
      expect(second.status, ShopControllerStatus.success);
      expect(second.walletCoins, 150);
      expect(second.shopState.backpackItems, hasLength(1));
      expect(
          second.shopState.backpackItems.first.itemId, 'utility_xp_boost_1d');
      expect(second.shopState.backpackItems.first.quantity, 2);
      expect(second.shopState.backpackItems.first.updatedAtMillis, isNotNull);
    });

    test('purchaseItem without enough coins fails without mutating state',
        () async {
      final controller = await _createController(walletCoins: 10);
      final beforeState = await controller.getItemState('wallpaper_mist_blue');

      final result = await controller.purchaseItem('wallpaper_mist_blue');

      expect(result.status, ShopControllerStatus.insufficientCoins);
      expect(controller.getWalletCoins(), 10);
      expect(result.shopState.inventory, isEmpty);
      final afterState = await controller.getItemState('wallpaper_mist_blue');
      expect(afterState?.isOwned, beforeState?.isOwned);
    });

    test('equipItem purchased cosmetic works', () async {
      final controller = await _createController(
        walletCoins: 500,
        shopState: const ShopState(
          inventory: <OwnedShopItem>[
            OwnedShopItem(itemId: 'wallpaper_mist_blue')
          ],
        ),
      );

      final result = await controller.equipItem('wallpaper_mist_blue');

      expect(result.status, ShopControllerStatus.success);
      expect(result.shopState.equippedCosmetics.backgroundItemId,
          'wallpaper_mist_blue');
    });

    test('cosmetic purchase never appears in backpack', () async {
      final controller = await _createController(walletCoins: 200);

      final result = await controller.purchaseItem('wallpaper_mist_blue');
      final itemState = await controller.getItemState('wallpaper_mist_blue');

      expect(result.status, ShopControllerStatus.success);
      expect(result.shopState.backpackItems, isEmpty);
      expect(itemState?.backpackQuantity, 0);
      expect(itemState?.isOwned, isTrue);
    });

    test('equipItem unowned cosmetic fails', () async {
      final controller = await _createController(walletCoins: 500);

      final result = await controller.equipItem('wallpaper_mist_blue');

      expect(result.status, ShopControllerStatus.itemNotOwned);
      expect(result.shopState.equippedCosmetics.backgroundItemId, isNull);
    });

    test('consumeItem utility reduces backpack quantity', () async {
      final controller = await _createController(
        walletCoins: 500,
        shopState: const ShopState(
          backpackItems: <BackpackItem>[
            BackpackItem(itemId: 'utility_xp_boost_1d', quantity: 2),
          ],
        ),
      );

      final result = await controller.consumeItem('utility_xp_boost_1d');

      expect(result.status, ShopControllerStatus.success);
      expect(result.shopState.backpackItems, hasLength(1));
      expect(
          result.shopState.backpackItems.first.itemId, 'utility_xp_boost_1d');
      expect(result.shopState.backpackItems.first.quantity, 1);
      expect(result.shopState.backpackItems.first.updatedAtMillis, isNotNull);
    });

    test('consumeItem missing or unowned item fails in a controlled way',
        () async {
      final controller = await _createController(walletCoins: 500);

      final unowned = await controller.consumeItem('utility_xp_boost_1d');
      final missing = await controller.consumeItem('missing-item');

      expect(unowned.status, ShopControllerStatus.backpackItemNotFound);
      expect(missing.status, ShopControllerStatus.itemNotFound);
    });

    test('activateBoost consumes backpack item and persists active effect',
        () async {
      final controller = await _createController(
        walletCoins: 500,
        shopState: const ShopState(
          backpackItems: <BackpackItem>[
            BackpackItem(itemId: 'utility_xp_boost_1d', quantity: 2),
          ],
        ),
      );

      final result = await controller.activateBoost('utility_xp_boost_1d');
      final activeEffects = await controller.getActiveUtilityEffects();

      expect(result.status, ShopControllerStatus.success);
      expect(result.shopState.backpackItems, hasLength(1));
      expect(result.shopState.backpackItems.first.quantity, 1);
      expect(activeEffects, hasLength(1));
      expect(activeEffects.first.utilityId, 'utility_xp_boost_1d');
      expect(activeEffects.first.type, ActiveUtilityEffectType.xpBoost);
      expect(activeEffects.first.remainingUses, 10);
      expect(activeEffects.first.totalUses, 10);
    });

    test('activateBoost coin boost creates exactly 10 uses', () async {
      final controller = await _createController(
        walletCoins: 500,
        shopState: const ShopState(
          backpackItems: <BackpackItem>[
            BackpackItem(itemId: 'utility_coin_boost_1d', quantity: 1),
          ],
        ),
      );

      final result = await controller.activateBoost('utility_coin_boost_1d');
      final activeEffects = await controller.getActiveUtilityEffects();

      expect(result.status, ShopControllerStatus.success);
      expect(activeEffects, hasLength(1));
      expect(activeEffects.single.utilityId, 'utility_coin_boost_1d');
      expect(activeEffects.single.type, ActiveUtilityEffectType.coinBoost);
      expect(activeEffects.single.remainingUses, 10);
      expect(activeEffects.single.totalUses, 10);
    });

    test('xp and coin boosts can coexist in the backpack', () async {
      final controller = await _createController(
        walletCoins: 500,
        shopState: const ShopState(
          backpackItems: <BackpackItem>[
            BackpackItem(itemId: 'utility_xp_boost_1d', quantity: 1),
            BackpackItem(itemId: 'utility_coin_boost_1d', quantity: 1),
          ],
        ),
      );

      final first = await controller.activateBoost('utility_xp_boost_1d');
      final second = await controller.activateBoost('utility_coin_boost_1d');
      final activeEffects = await controller.getActiveUtilityEffects();

      expect(first.status, ShopControllerStatus.success);
      expect(second.status, ShopControllerStatus.success);
      expect(activeEffects, hasLength(2));
      expect(
        activeEffects.map((effect) => effect.type),
        containsAll(<ActiveUtilityEffectType>[
          ActiveUtilityEffectType.xpBoost,
          ActiveUtilityEffectType.coinBoost,
        ]),
      );
    });

    test('activateBoost rejects a second active boost of the same type',
        () async {
      final controller = await _createController(
        walletCoins: 500,
        shopState: const ShopState(
          backpackItems: <BackpackItem>[
            BackpackItem(itemId: 'utility_xp_boost_1d', quantity: 2),
          ],
        ),
      );

      final first = await controller.activateBoost('utility_xp_boost_1d');
      final second = await controller.activateBoost('utility_xp_boost_1d');
      final activeEffects = await controller.getActiveUtilityEffects();

      expect(first.status, ShopControllerStatus.success);
      expect(second.status, ShopControllerStatus.utilityAlreadyActive);
      expect(activeEffects, hasLength(1));
      expect(activeEffects.first.remainingUses, 10);
    });

    test('activateBoost rolls back inventory if effect persistence fails',
        () async {
      final activeRepo = _FailingActiveUtilityEffectsRepository();
      final controller = await _createController(
        walletCoins: 500,
        shopState: const ShopState(
          backpackItems: <BackpackItem>[
            BackpackItem(itemId: 'utility_xp_boost_1d', quantity: 1),
          ],
        ),
        activeUtilityEffectsRepository: activeRepo,
      );

      final result = await controller.activateBoost('utility_xp_boost_1d');
      final activeEffects = await controller.getActiveUtilityEffects();
      final itemState = await controller.getItemState('utility_xp_boost_1d');

      expect(result.status, ShopControllerStatus.unavailableState);
      expect(activeEffects, isEmpty);
      expect(itemState?.backpackQuantity, 1);
    });

    test('activateStreakShield consumes one shield and persists it', () async {
      final controller = await _createController(
        walletCoins: 500,
        shopState: const ShopState(
          backpackItems: <BackpackItem>[
            BackpackItem(itemId: 'utility_streak_shield_1', quantity: 1),
          ],
        ),
        activeHabits: const <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'habit-1',
            'title': 'Leer',
          },
        ],
      );

      final result = await controller.activateStreakShield(
        habitId: 'habit-1',
        operationId: 'shield-op-1',
      );

      expect(result.status, StreakShieldOperationStatus.success);
      expect(result.isSuccess, isTrue);
      expect(controller.getActiveStreakShieldForHabit('habit-1'), isNotNull);
      expect(
        (await controller.getItemState('utility_streak_shield_1'))
            ?.backpackQuantity,
        0,
      );
      final activeEffects = await controller.getActiveUtilityEffects();
      expect(activeEffects, hasLength(1));
      expect(activeEffects.single.type, ActiveUtilityEffectType.streakShield);
      expect(activeEffects.single.habitId, 'habit-1');
    });

    test('activateStreakShield cloud keeps the local shield state intact',
        () async {
      final utilityRepo = _RecordingUtilityConsumptionRepository();
      final controller = await _createController(
        walletCoins: 500,
        shopState: const ShopState(
          backpackItems: <BackpackItem>[
            BackpackItem(itemId: 'utility_streak_shield_1', quantity: 1),
          ],
        ),
        activeHabits: const <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'habit-1',
            'title': 'Leer',
            'remoteId': '11111111-1111-4111-8111-111111111111',
          },
        ],
        cloudReadEnabled: true,
        cloudPurchaseEnabled: true,
        utilityConsumptionEnabled: true,
        utilityConsumptionRepository: utilityRepo,
        shopCloudReadRepository: _FakeShopCloudReadRepository(
          snapshotFactory: () => _cloudSnapshot(
            walletCoins: 10000,
            itemId: 'utility_streak_shield_1',
            quantity: 1,
          ),
        ),
        currentSupabaseUserIdProvider: () => 'shop-controller-user',
      );

      final result = await controller.activateStreakShield(
        habitId: 'habit-1',
        operationId: 'shield-op-cloud-1',
      );

      expect(result.status, StreakShieldOperationStatus.success);
      expect(result.isSuccess, isTrue);
      expect(utilityRepo.calls, 1);
      final activeEffects = await controller.getActiveUtilityEffects();
      expect(activeEffects, hasLength(1));
      expect(activeEffects.single.type, ActiveUtilityEffectType.streakShield);
      expect(
        activeEffects.single.habitId,
        '11111111-1111-4111-8111-111111111111',
      );
      expect(utilityRepo.requests.single['p_habit_id'],
          '11111111-1111-4111-8111-111111111111');
      expect(utilityRepo.requests.single['p_request_id'],
          'utility_activate:shop-controller-user:shield-op-cloud-1');
      expect(controller.getActiveStreakShieldForHabit('habit-1'), isNotNull);
      expect(controller.getActiveStreakShieldForHabit('habit-1')?.habitId,
          'habit-1');
      expect(
        (await controller.getItemState('utility_streak_shield_1'))
            ?.backpackQuantity,
        0,
      );
    });

    test('activateStreakShield cloud without remote UUID skips the RPC',
        () async {
      final utilityRepo = _RecordingUtilityConsumptionRepository();
      final controller = await _createController(
        walletCoins: 500,
        shopState: const ShopState(
          backpackItems: <BackpackItem>[
            BackpackItem(itemId: 'utility_streak_shield_1', quantity: 1),
          ],
        ),
        activeHabits: const <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'habit-1',
            'title': 'Leer',
          },
        ],
        cloudReadEnabled: true,
        cloudPurchaseEnabled: true,
        utilityConsumptionEnabled: true,
        utilityConsumptionRepository: utilityRepo,
        shopCloudReadRepository: _FakeShopCloudReadRepository(
          snapshotFactory: () => _cloudSnapshot(
            walletCoins: 10000,
            itemId: 'utility_streak_shield_1',
            quantity: 1,
          ),
        ),
        currentSupabaseUserIdProvider: () => 'shop-controller-user',
      );

      final result = await controller.activateStreakShield(
        habitId: 'habit-1',
        operationId: 'shield-op-cloud-2',
      );

      expect(result.status, StreakShieldOperationStatus.persistenceFailure);
      expect(
          result.errorMessage,
          contains(
              'Missing remote habit UUID for cloud streak shield activation'));
      expect(utilityRepo.calls, 0);
      expect(controller.getActiveStreakShieldForHabit('habit-1'), isNull);
      expect(
        (await controller.getItemState('utility_streak_shield_1'))
            ?.backpackQuantity,
        1,
      );
    });

    test('activateStreakShield cloud refreshes the visible snapshot', () async {
      final shopCloudReadRepository = _CountingShopCloudReadRepository(
        snapshotFactory: () => _cloudSnapshot(walletCoins: 10000),
      );
      final utilityRepo = _RecordingUtilityConsumptionRepository();
      final controller = await _createController(
        walletCoins: 500,
        shopState: const ShopState(
          backpackItems: <BackpackItem>[
            BackpackItem(itemId: 'utility_streak_shield_1', quantity: 1),
          ],
        ),
        activeHabits: const <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'habit-1',
            'title': 'Leer',
            'remoteId': '11111111-1111-4111-8111-111111111111',
          },
        ],
        cloudReadEnabled: true,
        cloudPurchaseEnabled: true,
        utilityConsumptionEnabled: true,
        utilityConsumptionRepository: utilityRepo,
        shopCloudReadRepository: shopCloudReadRepository,
        currentSupabaseUserIdProvider: () => 'shop-controller-user',
      );

      final result = await controller.activateStreakShield(
        habitId: 'habit-1',
        operationId: 'shield-op-cloud-3',
      );

      expect(result.status, StreakShieldOperationStatus.success);
      expect(shopCloudReadRepository.fetchCount, greaterThanOrEqualTo(1));
      expect(controller.visibleCoinBalance, 10000);
    });

    test('activateStreakShield cloud rejects a second shield on the same habit',
        () async {
      final utilityRepo = _RecordingUtilityConsumptionRepository();
      final controller = await _createController(
        walletCoins: 500,
        shopState: const ShopState(
          backpackItems: <BackpackItem>[
            BackpackItem(itemId: 'utility_streak_shield_1', quantity: 1),
          ],
        ),
        activeHabits: const <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'habit-1',
            'title': 'Leer',
            'remoteId': '11111111-1111-4111-8111-111111111111',
          },
        ],
        cloudReadEnabled: true,
        cloudPurchaseEnabled: true,
        utilityConsumptionEnabled: true,
        utilityConsumptionRepository: utilityRepo,
        shopCloudReadRepository: _FakeShopCloudReadRepository(
          snapshotFactory: () => _cloudSnapshot(
            walletCoins: 10000,
            itemId: 'utility_streak_shield_1',
            quantity: 1,
          ),
        ),
        currentSupabaseUserIdProvider: () => 'shop-controller-user',
      );

      final first = await controller.activateStreakShield(
        habitId: 'habit-1',
        operationId: 'shield-op-cloud-4',
      );
      final second = await controller.activateStreakShield(
        habitId: 'habit-1',
        operationId: 'shield-op-cloud-5',
      );

      expect(first.status, StreakShieldOperationStatus.success);
      expect(second.status, StreakShieldOperationStatus.shieldAlreadyActive);
      expect(utilityRepo.calls, 1);
    });

    test('recoverStreakBreak restores the break and consumes the item',
        () async {
      final controller = await _createController(
        walletCoins: 500,
        shopState: const ShopState(
          backpackItems: <BackpackItem>[
            BackpackItem(itemId: 'utility_streak_recover_1', quantity: 1),
          ],
        ),
        activeHabits: const <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'habit-1',
            'title': 'Leer',
          },
        ],
        recoverableBreaks: const <String, dynamic>{
          'break-1': <String, dynamic>{
            'id': 'break-1',
            'userId': 'shop-controller-user',
            'habitId': 'habit-1',
            'brokenAtMillis': 1,
            'missedOccurrenceDateKey': '2026-07-21',
            'previousStreak': 5,
            'currentStreakAfterBreak': 0,
            'status': 'recoverable',
            'shieldProtected': false,
          },
        },
        nowProvider: () => DateTime.utc(2026, 7, 21, 12),
      );

      final result = await controller.recoverStreakBreak(
        breakId: 'break-1',
        operationId: 'recover-op-1',
      );

      expect(result.status, StreakRecoverOperationStatus.success);
      expect(result.isSuccess, isTrue);
      expect(
          controller.getRecoverableStreakBreakForHabit('habit-1'), isNotNull);
      expect(
        controller.getRecoverableStreakBreakForHabit('habit-1')?.isRecovered,
        isTrue,
      );
      expect(
        (await controller.getItemState('utility_streak_recover_1'))
            ?.backpackQuantity,
        0,
      );
    });

    test('recoverStreakBreak returns recoveryExpired after the window',
        () async {
      final controller = await _createController(
        walletCoins: 500,
        shopState: const ShopState(
          backpackItems: <BackpackItem>[
            BackpackItem(itemId: 'utility_streak_recover_1', quantity: 1),
          ],
        ),
        activeHabits: const <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'habit-1',
            'title': 'Leer',
          },
        ],
        recoverableBreaks: const <String, dynamic>{
          'break-1': <String, dynamic>{
            'id': 'break-1',
            'userId': 'shop-controller-user',
            'habitId': 'habit-1',
            'brokenAtMillis': 1,
            'missedOccurrenceDateKey': '2026-07-18',
            'previousStreak': 5,
            'currentStreakAfterBreak': 0,
            'status': 'recoverable',
            'shieldProtected': false,
          },
        },
        nowProvider: () => DateTime.utc(2026, 7, 21, 12),
      );

      final result = await controller.recoverStreakBreak(
        breakId: 'break-1',
        operationId: 'recover-op-expired',
      );

      expect(result.status, StreakRecoverOperationStatus.recoveryExpired);
      expect(result.isSuccess, isFalse);
    });

    test('recoverStreakBreak cloud calls the RPC and clears one unit',
        () async {
      final shopRepository = _TrackingShopRepository();
      final utilityRepo = _RecordingUtilityConsumptionRepository();
      final controller = await _createController(
        walletCoins: 500,
        shopState: const ShopState(
          backpackItems: <BackpackItem>[
            BackpackItem(itemId: 'utility_streak_recover_1', quantity: 1),
          ],
        ),
        shopRepository: shopRepository,
        activeHabits: const <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'habit-1',
            'title': 'Leer',
            'remoteId': '11111111-1111-4111-8111-111111111111',
          },
        ],
        recoverableBreaks: const <String, dynamic>{
          'break-1': <String, dynamic>{
            'id': 'break-1',
            'userId': 'shop-controller-user',
            'habitId': 'habit-1',
            'brokenAtMillis': 1,
            'missedOccurrenceDateKey': '2026-07-21',
            'previousStreak': 5,
            'currentStreakAfterBreak': 0,
            'status': 'recoverable',
            'shieldProtected': false,
          },
        },
        cloudReadEnabled: true,
        cloudPurchaseEnabled: true,
        utilityConsumptionEnabled: true,
        utilityConsumptionRepository: utilityRepo,
        shopCloudReadRepository: _FakeShopCloudReadRepository(
          snapshotFactory: () => _cloudSnapshot(
            walletCoins: 10000,
            itemId: 'utility_streak_recover_1',
            quantity: 1,
          ),
        ),
        currentSupabaseUserIdProvider: () => 'shop-controller-user',
        nowProvider: () => DateTime.utc(2026, 7, 21, 12),
      );

      final result = await controller.recoverStreakBreak(
        breakId: 'break-1',
        operationId: 'recover-op-cloud-1',
      );

      expect(result.status, StreakRecoverOperationStatus.success);
      expect(result.isSuccess, isTrue);
      expect(utilityRepo.calls, 1);
      expect(shopRepository.loadCalls, 0);
      expect(shopRepository.saveCalls, 0);

      final visibleShopState = await controller.getVisibleShopState();
      expect(
        visibleShopState.backpackItems
            .where((entry) => entry.itemId == 'utility_streak_recover_1'),
        isEmpty,
      );
    });

    test('recoverStreakBreak cloud does not call the RPC after expiry',
        () async {
      final shopRepository = _TrackingShopRepository();
      final utilityRepo = _RecordingUtilityConsumptionRepository();
      final controller = await _createController(
        walletCoins: 500,
        shopState: const ShopState(
          backpackItems: <BackpackItem>[
            BackpackItem(itemId: 'utility_streak_recover_1', quantity: 1),
          ],
        ),
        shopRepository: shopRepository,
        activeHabits: const <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'habit-1',
            'title': 'Leer',
            'remoteId': '11111111-1111-4111-8111-111111111111',
          },
        ],
        recoverableBreaks: const <String, dynamic>{
          'break-1': <String, dynamic>{
            'id': 'break-1',
            'userId': 'shop-controller-user',
            'habitId': 'habit-1',
            'brokenAtMillis': 1,
            'missedOccurrenceDateKey': '2026-07-18',
            'previousStreak': 5,
            'currentStreakAfterBreak': 0,
            'status': 'recoverable',
            'shieldProtected': false,
          },
        },
        cloudReadEnabled: true,
        cloudPurchaseEnabled: true,
        utilityConsumptionEnabled: true,
        utilityConsumptionRepository: utilityRepo,
        shopCloudReadRepository: _FakeShopCloudReadRepository(
          snapshotFactory: () => _cloudSnapshot(
            walletCoins: 10000,
            itemId: 'utility_streak_recover_1',
            quantity: 1,
          ),
        ),
        currentSupabaseUserIdProvider: () => 'shop-controller-user',
        nowProvider: () => DateTime.utc(2026, 7, 21, 12),
      );

      final result = await controller.recoverStreakBreak(
        breakId: 'break-1',
        operationId: 'recover-op-expired-cloud',
      );

      expect(result.status, StreakRecoverOperationStatus.recoveryExpired);
      expect(result.isSuccess, isFalse);
      expect(utilityRepo.calls, 0);
      expect(shopRepository.loadCalls, 0);
      expect(shopRepository.saveCalls, 0);
    });

    test('recoverStreakBreak cloud blocks a second pending recovery', () async {
      final utilityRepo = _BlockingUtilityConsumptionRepository();
      final controller = await _createController(
        walletCoins: 500,
        shopState: const ShopState(
          backpackItems: <BackpackItem>[
            BackpackItem(itemId: 'utility_streak_recover_1', quantity: 1),
          ],
        ),
        activeHabits: const <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'habit-1',
            'title': 'Leer',
            'remoteId': '11111111-1111-4111-8111-111111111111',
          },
        ],
        recoverableBreaks: const <String, dynamic>{
          'break-1': <String, dynamic>{
            'id': 'break-1',
            'userId': 'shop-controller-user',
            'habitId': 'habit-1',
            'brokenAtMillis': 1,
            'missedOccurrenceDateKey': '2026-07-21',
            'previousStreak': 5,
            'currentStreakAfterBreak': 0,
            'status': 'recoverable',
            'shieldProtected': false,
          },
        },
        cloudReadEnabled: true,
        cloudPurchaseEnabled: true,
        utilityConsumptionEnabled: true,
        utilityConsumptionRepository: utilityRepo,
        shopCloudReadRepository: _FakeShopCloudReadRepository(
          snapshotFactory: () => _cloudSnapshot(
            walletCoins: 10000,
            itemId: 'utility_streak_recover_1',
            quantity: 1,
          ),
        ),
        currentSupabaseUserIdProvider: () => 'shop-controller-user',
        nowProvider: () => DateTime.utc(2026, 7, 21, 12),
      );

      final first = controller.recoverStreakBreak(
        breakId: 'break-1',
        operationId: 'recover-op-pending',
      );
      await utilityRepo.waitForApplyStarted;
      final second = await controller.recoverStreakBreak(
        breakId: 'break-1',
        operationId: 'recover-op-pending',
      );
      utilityRepo.release();
      final firstResult = await first;

      expect(firstResult.status, StreakRecoverOperationStatus.success);
      expect(second.status,
          StreakRecoverOperationStatus.operationAlreadyProcessed);
      expect(utilityRepo.calls, 1);
    });

    test('openMysteryBox consumes one box and persists the result', () async {
      final controller = await _createController(
        walletCoins: 500,
        shopState: const ShopState(
          backpackItems: <BackpackItem>[
            BackpackItem(itemId: 'utility_mystery_box_basic', quantity: 2),
          ],
        ),
        randomSource: FixedRandomSource(<int>[0]),
      );

      final result = await controller.openMysteryBox(transactionId: 'tx-1');
      final pending = await controller.getPendingMysteryBoxOpenings();

      expect(result.status, MysteryBoxOperationStatus.success);
      expect(result.transaction, isNotNull);
      expect(result.transaction!.reward.rewardId, 'reward_80_coins_40_xp');
      expect(
          (await controller.getItemState('utility_mystery_box_basic'))!
              .backpackQuantity,
          1);
      expect(
          (await controller.getItemState('utility_mystery_box_basic'))!
              .isInBackpack,
          isTrue);
      expect(pending, hasLength(1));
      expect(pending.single.status, MysteryBoxOpeningStatus.granted);
    });

    test('openMysteryBox blocks a second concurrent opening', () async {
      final openingRepository = _BlockingMysteryBoxOpeningRepository();
      final controller = await _createController(
        walletCoins: 500,
        shopState: const ShopState(
          backpackItems: <BackpackItem>[
            BackpackItem(itemId: 'utility_mystery_box_basic', quantity: 2),
          ],
        ),
        mysteryBoxOpeningRepository: openingRepository,
        randomSource: FixedRandomSource(<int>[0]),
      );

      final first = controller.openMysteryBox(transactionId: 'tx-1');
      await openingRepository.waitForSaveStarted;
      final second = await controller.openMysteryBox(transactionId: 'tx-2');
      openingRepository.release();
      await first;

      expect(second.status, MysteryBoxOperationStatus.duplicateTransaction);
    });

    test('utility cannot be equipped', () async {
      final controller = await _createController(walletCoins: 500);

      final result = await controller.equipItem('utility_xp_boost_1d');

      expect(result.status, ShopControllerStatus.invalidItemType);
      expect(result.shopState.equippedCosmetics,
          const ShopState.initial().equippedCosmetics);
    });

    test('legacy utility in inventory does not mark utility as owned',
        () async {
      final controller = await _createController(
        walletCoins: 500,
        shopState: const ShopState(
          inventory: <OwnedShopItem>[
            OwnedShopItem(itemId: 'utility_xp_boost_1d'),
          ],
        ),
      );

      final itemState = await controller.getItemState('utility_xp_boost_1d');

      expect(itemState, isNotNull);
      expect(itemState?.isOwned, isFalse);
      expect(itemState?.backpackQuantity, 0);
    });
  });
}

Future<ShopController> _createController({
  required int walletCoins,
  ShopState shopState = const ShopState.initial(),
  List<Map<String, dynamic>> activeHabits = const <Map<String, dynamic>>[],
  Map<String, dynamic> recoverableBreaks = const <String, dynamic>{},
  ShopLocalRepository? shopRepository,
  ActiveUtilityEffectsRepository? activeUtilityEffectsRepository,
  MysteryBoxOpeningRepository? mysteryBoxOpeningRepository,
  FixedRandomSource? randomSource,
  DateTime Function()? nowProvider,
  bool? cloudReadEnabled,
  bool? cloudPurchaseEnabled,
  bool utilityConsumptionEnabled = false,
  ShopCloudReadRepository? shopCloudReadRepository,
  UtilityConsumptionRepository? utilityConsumptionRepository,
  String? Function()? currentSupabaseUserIdProvider,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});

  final repo = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope('shop-controller-user');
  final store = UserStateStore(
    repo,
    journalEntrySyncService: JournalEntrySyncService(),
    utilityConsumptionRepository: utilityConsumptionRepository,
    utilityConsumptionEnabledOverride: utilityConsumptionEnabled,
  );
  await store.save(
    _baseState(
      walletCoins: walletCoins,
      activeHabits: activeHabits,
      recoverableBreaks: recoverableBreaks,
    ),
  );

  final shopRepositoryInstance = shopRepository ?? ShopLocalRepository();
  await shopRepositoryInstance.save(shopState);
  if (shopRepositoryInstance is _TrackingShopRepository) {
    shopRepositoryInstance.resetCounts();
  }

  return ShopController(
    userStateStore: store,
    shopRepository: shopRepositoryInstance,
    activeUtilityEffectsRepository: activeUtilityEffectsRepository,
    utilityConsumptionRepository: utilityConsumptionRepository,
    mysteryBoxOpeningRepository: mysteryBoxOpeningRepository,
    randomSource: randomSource,
    nowProvider: nowProvider,
    cloudReadEnabled: cloudReadEnabled,
    cloudPurchaseEnabled: cloudPurchaseEnabled,
    utilityConsumptionEnabled: utilityConsumptionEnabled,
    shopCloudReadRepository: shopCloudReadRepository,
    currentSupabaseUserIdProvider: currentSupabaseUserIdProvider,
  );
}

class _InMemoryShopRepository implements ShopLocalRepository {
  _InMemoryShopRepository({
    ShopState state = const ShopState.initial(),
  }) : _state = state;

  ShopState _state;

  @override
  Future<ShopState> load() async {
    return _state;
  }

  @override
  Future<void> save(ShopState state) async {
    _state = state;
  }

  @override
  Future<void> clear() async {
    _state = const ShopState.initial();
  }
}

class _TrackingShopRepository extends _InMemoryShopRepository {
  _TrackingShopRepository() : super(state: const ShopState.initial());

  int loadCalls = 0;
  int saveCalls = 0;

  void resetCounts() {
    loadCalls = 0;
    saveCalls = 0;
  }

  @override
  Future<ShopState> load() async {
    loadCalls += 1;
    return super.load();
  }

  @override
  Future<void> save(ShopState state) async {
    saveCalls += 1;
    await super.save(state);
  }

  @override
  Future<void> clear() async {
    saveCalls += 1;
    await super.clear();
  }
}

class _FailingActiveUtilityEffectsRepository
    implements ActiveUtilityEffectsRepository {
  _FailingActiveUtilityEffectsRepository();

  final LocalActiveUtilityEffectsRepository _delegate =
      LocalActiveUtilityEffectsRepository();

  @override
  Future<List<ActiveUtilityEffect>> loadEffects(String userScope) {
    return _delegate.loadEffects(userScope);
  }

  @override
  Future<void> saveEffects(
    String userScope,
    List<ActiveUtilityEffect> effects,
  ) async {
    throw StateError('active effects save failed');
  }
}

class _BlockingMysteryBoxOpeningRepository
    implements MysteryBoxOpeningRepository {
  _BlockingMysteryBoxOpeningRepository() {
    _saveStarted.complete();
  }

  final List<MysteryBoxOpeningTransaction> _transactions =
      <MysteryBoxOpeningTransaction>[];
  final Completer<void> _saveStarted = Completer<void>();
  final Completer<void> _release = Completer<void>();

  Future<void> get waitForSaveStarted => _saveStarted.future;

  void release() {
    if (!_release.isCompleted) {
      _release.complete();
    }
  }

  @override
  Future<List<MysteryBoxOpeningTransaction>> loadTransactions(
    String userScope,
  ) async {
    return List<MysteryBoxOpeningTransaction>.from(_transactions);
  }

  @override
  Future<void> saveTransactions(
    String userScope,
    List<MysteryBoxOpeningTransaction> transactions,
  ) async {
    if (!_saveStarted.isCompleted) {
      _saveStarted.complete();
    }
    await _release.future;
    _transactions
      ..clear()
      ..addAll(transactions);
  }
}

class _FakeShopCloudReadRepository extends ShopCloudReadRepository {
  _FakeShopCloudReadRepository({
    required this.snapshotFactory,
  }) : super(
          readEnabled: true,
          currentUserIdProvider: () => 'shop-controller-user',
        );

  final ShopCloudSnapshot Function() snapshotFactory;

  @override
  Future<ShopCloudReadResult<ShopCloudSnapshot>> fetchShopSnapshot() async {
    return ShopCloudReadResult<ShopCloudSnapshot>.success(
      data: snapshotFactory(),
    );
  }
}

class _CountingShopCloudReadRepository extends _FakeShopCloudReadRepository {
  _CountingShopCloudReadRepository({
    required super.snapshotFactory,
  });

  int fetchCount = 0;

  @override
  Future<ShopCloudReadResult<ShopCloudSnapshot>> fetchShopSnapshot() async {
    fetchCount += 1;
    return super.fetchShopSnapshot();
  }
}

class _RecordingUtilityConsumptionRepository
    implements UtilityConsumptionRepository {
  int calls = 0;
  final List<Map<String, dynamic>> requests = <Map<String, dynamic>>[];
  final List<ActiveUtilityEffect> _effects = <ActiveUtilityEffect>[];

  @override
  Future<List<ActiveUtilityEffect>> loadEffects(String userScope) async {
    return List<ActiveUtilityEffect>.unmodifiable(_effects);
  }

  @override
  Future<void> saveEffects(
    String userScope,
    List<ActiveUtilityEffect> effects,
  ) async {
    _effects
      ..clear()
      ..addAll(effects);
  }

  @override
  Future<UtilityConsumptionLedgerEntry> activateUtilityEffect({
    required String requestId,
    required String utilityId,
    required String operationType,
    required String sourceType,
    required String sourceId,
    String? habitId,
    String? breakId,
  }) async {
    calls += 1;
    requests.add(<String, dynamic>{
      'p_request_id': requestId,
      'p_utility_id': utilityId,
      'p_operation_type': operationType,
      'p_source_type': sourceType,
      'p_source_id': sourceId,
      if (habitId != null) 'p_habit_id': habitId,
      if (breakId != null) 'p_break_id': breakId,
    });
    _effects.add(
      ActiveUtilityEffect(
        id: 'effect-$calls',
        utilityId: utilityId,
        type: ActiveUtilityEffectType.streakShield,
        activatedAtMillis: DateTime.utc(2026, 7, 18).millisecondsSinceEpoch,
        remainingUses: 1,
        totalUses: 1,
        habitId: habitId,
      ),
    );
    return UtilityConsumptionLedgerEntry(
      id: 'ledger-$calls',
      userId: 'shop-controller-user',
      requestId: requestId,
      operationType: operationType,
      sourceType: sourceType,
      sourceId: sourceId,
      utilityId: utilityId,
      utilityType: ActiveUtilityEffectType.streakShield,
      effectId: 'effect-$calls',
      totalUses: 1,
      remainingUses: 1,
      createdAt: DateTime.utc(2026, 7, 18),
      isIdempotent: calls > 1,
    );
  }

  @override
  Future<UtilityConsumptionLedgerEntry> consumeUtilityUse({
    required String requestId,
    required String utilityId,
    required String operationType,
    required String sourceType,
    required String sourceId,
    String? habitId,
    String? breakId,
  }) {
    return activateUtilityEffect(
      requestId: requestId,
      utilityId: utilityId,
      operationType: operationType,
      sourceType: sourceType,
      sourceId: sourceId,
      habitId: habitId,
      breakId: breakId,
    );
  }

  @override
  Future<UtilityConsumptionLedgerEntry> applyStreakRecover({
    required String requestId,
    required String utilityId,
    required String operationType,
    required String breakId,
  }) {
    return activateUtilityEffect(
      requestId: requestId,
      utilityId: utilityId,
      operationType: operationType,
      sourceType: 'streak_recover',
      sourceId: breakId,
      breakId: breakId,
    );
  }
}

class _BlockingUtilityConsumptionRepository
    extends _RecordingUtilityConsumptionRepository {
  final Completer<void> _applyStarted = Completer<void>();
  final Completer<void> _release = Completer<void>();

  Future<void> get waitForApplyStarted => _applyStarted.future;

  void release() {
    if (!_release.isCompleted) {
      _release.complete();
    }
  }

  @override
  Future<UtilityConsumptionLedgerEntry> applyStreakRecover({
    required String requestId,
    required String utilityId,
    required String operationType,
    required String breakId,
  }) async {
    if (!_applyStarted.isCompleted) {
      _applyStarted.complete();
    }
    await _release.future;
    return super.applyStreakRecover(
      requestId: requestId,
      utilityId: utilityId,
      operationType: operationType,
      breakId: breakId,
    );
  }
}

ShopCloudSnapshot _cloudSnapshot({
  int? walletCoins = 10000,
  String itemId = 'utility_xp_boost_1d',
  int quantity = 0,
}) {
  return ShopCloudSnapshot(
    authenticatedUserId: 'shop-controller-user',
    catalogItems: <RemoteShopItemDto>[],
    wallet: walletCoins == null
        ? null
        : RemoteWalletDto(
            userId: 'shop-controller-user',
            coins: walletCoins,
            version: 1,
            createdAt: DateTime.utc(2026, 7, 18),
            updatedAt: DateTime.utc(2026, 7, 18),
          ),
    inventory: quantity > 0
        ? <RemoteInventoryItemDto>[
            RemoteInventoryItemDto(
              id: 'inv-1',
              userId: 'shop-controller-user',
              itemId: itemId,
              quantity: quantity,
              acquisitionSource: 'purchase',
              acquiredAt: DateTime.utc(2026, 7, 18),
              updatedAt: DateTime.utc(2026, 7, 18),
            ),
          ]
        : const <RemoteInventoryItemDto>[],
    ownedBundles: const <RemoteOwnedBundleDto>[],
    equippedCosmetics: const <RemoteEquippedCosmeticDto>[],
    fetchedAt: DateTime.utc(2026, 7, 18),
    catalogVersion: 1,
    warnings: const <ShopCloudWarning>[],
  );
}

Map<String, dynamic> _baseState({
  required int walletCoins,
  List<Map<String, dynamic>> activeHabits = const <Map<String, dynamic>>[],
  Map<String, dynamic> recoverableBreaks = const <String, dynamic>{},
}) {
  final mutableActiveHabits = activeHabits
      .map((habit) => Map<String, dynamic>.from(habit))
      .toList(growable: false);
  final mutableRecoverableBreaks = recoverableBreaks.map(
    (key, value) => MapEntry(
      key,
      value is Map ? Map<String, dynamic>.from(value) : value,
    ),
  );

  return <String, dynamic>{
    'userState': <String, dynamic>{
      'userId': 'shop-controller-user',
      'meta': <String, dynamic>{
        'schemaVersion': 1,
        'lastSavedAt': DateTime.now().toUtc().toIso8601String(),
        'diaryRewardAppliedDateKeys': <dynamic>[],
      },
      'progression': <String, dynamic>{
        'level': 1,
        'xp': 0,
        'prestige': 0,
      },
      'wallet': <String, dynamic>{'coins': walletCoins},
      'inventory': <String, dynamic>{'items': <dynamic>[]},
      'profile': <String, dynamic>{
        'equipped': <String, dynamic>{},
        'badges': <String, dynamic>{'owned': <dynamic>[], 'shown': null},
        'achievements': <String, dynamic>{
          'unlocked': <dynamic>[],
          'featured': <dynamic>[],
          'rewardAppliedAchievementIds': <dynamic>[],
          'progress': <String, dynamic>{},
        },
      },
      'claims': <String, dynamic>{
        'milestonesClaimed': <dynamic>[],
        'achievementRewardsClaimed': <dynamic>[],
        'prestigeClaimed': <dynamic>[],
      },
      'daily': <String, dynamic>{
        'lastResetDate': '2026-06-27',
        'xpEarnedToday': 0,
        'coinsEarnedToday': 0,
        'habitsCompletedToday': <String, dynamic>{},
      },
      'history': <String, dynamic>{
        'habitCompletions': <String, dynamic>{},
        'habitCountValues': <String, dynamic>{},
        'habitSkips': <String, dynamic>{},
        'habitCompletionTimes': <String, dynamic>{},
        'habitOccurrenceStatuses': <String, dynamic>{},
        'habitStreakBreaks': mutableRecoverableBreaks,
        'habitStreakShields': <String, dynamic>{},
      },
      'familyXp': <String, dynamic>{
        'mind': 0,
        'spirit': 0,
        'body': 0,
        'emotional': 0,
        'social': 0,
        'discipline': 0,
        'professional': 0,
      },
      'activeHabits': mutableActiveHabits,
    },
  };
}
