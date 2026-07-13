import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/features/shop/application/shop_controller.dart';
import 'package:rutio/features/shop/data/shop_local_repository.dart';
import 'package:rutio/features/shop/domain/models/backpack_item.dart';
import 'package:rutio/features/shop/domain/models/owned_shop_item.dart';
import 'package:rutio/features/shop/domain/shop_state.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShopController', () {
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
      expect(
        result.shopState.backpackItems,
        const <BackpackItem>[
          BackpackItem(itemId: 'utility_xp_boost_1d', quantity: 1),
        ],
      );
    });

    test('purchaseItem utility twice accumulates quantity in backpack',
        () async {
      final controller = await _createController(walletCoins: 300);

      final first = await controller.purchaseItem('utility_xp_boost_1d');
      final second = await controller.purchaseItem('utility_xp_boost_1d');

      expect(first.status, ShopControllerStatus.success);
      expect(second.status, ShopControllerStatus.success);
      expect(second.walletCoins, 150);
      expect(
        second.shopState.backpackItems,
        const <BackpackItem>[
          BackpackItem(itemId: 'utility_xp_boost_1d', quantity: 2),
        ],
      );
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
      expect(
        result.shopState.backpackItems,
        const <BackpackItem>[
          BackpackItem(itemId: 'utility_xp_boost_1d', quantity: 1),
        ],
      );
    });

    test('consumeItem missing or unowned item fails in a controlled way',
        () async {
      final controller = await _createController(walletCoins: 500);

      final unowned = await controller.consumeItem('utility_xp_boost_1d');
      final missing = await controller.consumeItem('missing-item');

      expect(unowned.status, ShopControllerStatus.backpackItemNotFound);
      expect(missing.status, ShopControllerStatus.itemNotFound);
    });

    test('utility cannot be equipped', () async {
      final controller = await _createController(walletCoins: 500);

      final result = await controller.equipItem('utility_xp_boost_1d');

      expect(result.status, ShopControllerStatus.invalidItemType);
      expect(result.shopState.equippedCosmetics,
          const ShopState.initial().equippedCosmetics);
    });
  });
}

Future<ShopController> _createController({
  required int walletCoins,
  ShopState shopState = const ShopState.initial(),
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});

  final repo = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope('shop-controller-user');
  final store = UserStateStore(
    repo,
    journalEntrySyncService: JournalEntrySyncService(),
  );
  await store.save(_baseState(walletCoins: walletCoins));

  final shopRepository = ShopLocalRepository();
  await shopRepository.save(shopState);

  return ShopController(
    userStateStore: store,
    shopRepository: shopRepository,
  );
}

Map<String, dynamic> _baseState({
  required int walletCoins,
}) {
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
      'activeHabits': <dynamic>[],
    },
  };
}
