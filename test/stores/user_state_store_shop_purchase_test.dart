import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/features/shop/data/shop_catalog.dart';
import 'package:rutio/features/shop/data/shop_local_repository.dart';
import 'package:rutio/features/shop/domain/models/backpack_item.dart';
import 'package:rutio/features/shop/domain/shop_state.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserStateStore shop purchases', () {
    test('buying a cosmetic spends wallet coins and saves shop inventory',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final item = ShopCatalog.getItemById('wallpaper_mellow_camel')!;
      final store = await _seedStore(walletCoins: 200);

      final success = await store.buyItem(
        itemId: item.id,
        price: item.priceCoins,
      );

      final shopState = await ShopLocalRepository().load();
      expect(success, isTrue);
      expect(_walletCoins(store), 200 - item.priceCoins);
      expect(
          shopState.inventory.map((entry) => entry.itemId), <String>[item.id]);
      expect(shopState.backpackItems, isEmpty);
    });

    test('buying a utility spends wallet coins and saves backpack item',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final item = ShopCatalog.getItemById('utility_xp_boost_1d')!;
      final store = await _seedStore(walletCoins: 200);

      final success = await store.buyItem(
        itemId: item.id,
        price: item.priceCoins,
      );

      final shopState = await ShopLocalRepository().load();
      expect(success, isTrue);
      expect(_walletCoins(store), 125);
      expect(shopState.inventory, isEmpty);
      expect(
        shopState.backpackItems,
        const <BackpackItem>[
          BackpackItem(itemId: 'utility_xp_boost_1d', quantity: 1),
        ],
      );
    });

    test('purchase fails when wallet does not have enough coins', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final item = ShopCatalog.getItemById('wallpaper_jungle_sunrise')!;
      final store = await _seedStore(walletCoins: 200);

      final success = await store.buyItem(
        itemId: item.id,
        price: item.priceCoins,
      );

      final shopState = await ShopLocalRepository().load();
      expect(success, isFalse);
      expect(_walletCoins(store), 200);
      expect(shopState, const ShopState.initial());
    });

    test('legacy ShopState.coins is not used as the real balance source',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final item = ShopCatalog.getItemById('wallpaper_mellow_camel')!;
      await ShopLocalRepository().save(const ShopState(coins: 999));
      final store = await _seedStore(walletCoins: 0);

      final success = await store.buyItem(
        itemId: item.id,
        price: item.priceCoins,
      );

      final shopState = await ShopLocalRepository().load();
      expect(success, isFalse);
      expect(_walletCoins(store), 0);
      expect(shopState.coins, 999);
      expect(shopState.inventory, isEmpty);
    });
  });
}

Future<UserStateStore> _seedStore({required int walletCoins}) async {
  final repo = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope('shop-user');
  final store = UserStateStore(
    repo,
    journalEntrySyncService: JournalEntrySyncService(),
  );
  await store.save(
    <String, dynamic>{
      'userState': <String, dynamic>{
        'userId': 'shop-user',
        'meta': <String, dynamic>{
          'schemaVersion': 1,
          'lastSavedAt': DateTime.now().toUtc().toIso8601String(),
          'diaryRewardAppliedDateKeys': <dynamic>[],
        },
        'progression': <String, dynamic>{'level': 1, 'xp': 0, 'prestige': 0},
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
          'lastResetDate': _todayKey(),
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
    },
  );
  return store;
}

int _walletCoins(UserStateStore store) {
  final wallet = ((store.state?['userState'] as Map?)?['wallet'] as Map?)
          ?.cast<String, dynamic>() ??
      const <String, dynamic>{};
  return ((wallet['coins'] as num?) ?? 0).toInt();
}

String _todayKey() {
  final now = DateTime.now();
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  return '${now.year}-$month-$day';
}
