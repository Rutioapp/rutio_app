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
import 'package:rutio/features/shop/data/local_active_utility_effects_repository.dart';
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
            'missedOccurrenceDateKey': '2026-07-19',
            'previousStreak': 5,
            'currentStreakAfterBreak': 0,
            'status': 'recoverable',
            'shieldProtected': false,
          },
        },
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
  ActiveUtilityEffectsRepository? activeUtilityEffectsRepository,
  MysteryBoxOpeningRepository? mysteryBoxOpeningRepository,
  FixedRandomSource? randomSource,
  DateTime Function()? nowProvider,
  bool? cloudReadEnabled,
  bool? cloudPurchaseEnabled,
  ShopCloudReadRepository? shopCloudReadRepository,
  String? Function()? currentSupabaseUserIdProvider,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});

  final repo = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope('shop-controller-user');
  final store = UserStateStore(
    repo,
    journalEntrySyncService: JournalEntrySyncService(),
  );
  await store.save(
    _baseState(
      walletCoins: walletCoins,
      activeHabits: activeHabits,
      recoverableBreaks: recoverableBreaks,
    ),
  );

  final shopRepository = ShopLocalRepository();
  await shopRepository.save(shopState);

  return ShopController(
    userStateStore: store,
    shopRepository: shopRepository,
    activeUtilityEffectsRepository: activeUtilityEffectsRepository,
    mysteryBoxOpeningRepository: mysteryBoxOpeningRepository,
    randomSource: randomSource,
    nowProvider: nowProvider,
    cloudReadEnabled: cloudReadEnabled,
    cloudPurchaseEnabled: cloudPurchaseEnabled,
    shopCloudReadRepository: shopCloudReadRepository,
    currentSupabaseUserIdProvider: currentSupabaseUserIdProvider,
  );
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
