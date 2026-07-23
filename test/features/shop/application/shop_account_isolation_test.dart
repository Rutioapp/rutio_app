import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/features/shop/application/shop_controller.dart';
import 'package:rutio/features/shop/application/shop_cosmetics_controller.dart';
import 'package:rutio/features/shop/data/shop_cosmetics_repository.dart';
import 'package:rutio/features/shop/data/shop_local_repository.dart';
import 'package:rutio/features/shop/domain/models/backpack_item.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_state.dart';
import 'package:rutio/features/shop/domain/shop_state.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Shop account isolation', () {
    test('switching users rebuilds the visible local shop state', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final repo = UserStateRepository(storage: UserStateStorage());
      final store = UserStateStore(
        repo,
        journalEntrySyncService: JournalEntrySyncService(),
      );

      await _seedUserScope(store, userId: 'user-a', walletCoins: 500);
      await _seedUserScope(store, userId: 'user-b', walletCoins: 75);

      await _saveShopState(
        scope: 'user-a',
        state: const ShopState(
          backpackItems: <BackpackItem>[
            BackpackItem(
              itemId: 'utility_xp_boost_1d',
              quantity: 2,
              updatedAtMillis: 10,
            ),
          ],
        ),
      );
      await _saveShopState(
        scope: 'user-b',
        state: const ShopState(
          backpackItems: <BackpackItem>[
            BackpackItem(
              itemId: 'utility_coin_boost_1d',
              quantity: 1,
              updatedAtMillis: 20,
            ),
          ],
        ),
      );

      await _saveCosmeticsState(
        scope: 'user-a',
        state: ShopCosmeticsState(
          ownedAssetIds: <String>[
            'wallpaper_mist_blue',
            'habit_card_warm_beige',
            'user_card_warm_beige',
          ],
          ownedBundleIds: <String>['pack_beige_rutio'],
          equippedWallpaperId: 'wallpaper_mist_blue',
          equippedHabitCardSkinId: 'habit_card_warm_beige',
          equippedUserCardSkinId: 'user_card_warm_beige',
        ),
      );
      await _saveCosmeticsState(
        scope: 'user-b',
        state: ShopCosmeticsState(
          ownedAssetIds: <String>['wallpaper_soft_sage'],
          ownedBundleIds: <String>['pack_camel_suave'],
          equippedWallpaperId: 'wallpaper_soft_sage',
        ),
      );

      await store.switchLocalScope(userId: 'user-a', forceReload: true);

      final shopController = ShopController(
        userStateStore: store,
        cloudReadEnabled: false,
        cloudPurchaseEnabled: false,
      );
      final cosmeticsController = ShopCosmeticsController(
        userStateStore: store,
        cloudEnabled: false,
      );

      final userAShopState = await shopController.getVisibleShopState();
      final userACosmeticsState = await cosmeticsController.getState();

      expect(shopController.getWalletCoins(), 500);
      expect(
        userAShopState.backpackItems.single.itemId,
        'utility_xp_boost_1d',
      );
      expect(userAShopState.backpackItems.single.quantity, 2);
      expect(
        userACosmeticsState.equippedWallpaperId,
        'wallpaper_mist_blue',
      );
      expect(
        userACosmeticsState.ownedBundleIds,
        contains('pack_beige_rutio'),
      );

      await store.switchLocalScope(userId: 'user-b', forceReload: true);

      final userBShopState = await shopController.getVisibleShopState();
      final userBCosmeticsState = await cosmeticsController.getState();

      expect(shopController.getWalletCoins(), 75);
      expect(
        userBShopState.backpackItems.single.itemId,
        'utility_coin_boost_1d',
      );
      expect(userBShopState.backpackItems.single.quantity, 1);
      expect(userBCosmeticsState.equippedWallpaperId, 'wallpaper_soft_sage');
      expect(
        userBCosmeticsState.ownedBundleIds,
        contains('pack_camel_suave'),
      );
      expect(
        cosmeticsController.getEquippedWallpaperAssetOrNullSync()?.id,
        'wallpaper_soft_sage',
      );
    });
  });
}

Future<void> _seedUserScope(
  UserStateStore store, {
  required String userId,
  required int walletCoins,
}) async {
  await store.switchLocalScope(userId: userId, forceReload: true);
  await store.save(_baseState(userId: userId, walletCoins: walletCoins));
}

Future<void> _saveShopState({
  required String scope,
  required ShopState state,
}) async {
  await ShopLocalRepository(scopeResolver: () => scope).save(state);
}

Future<void> _saveCosmeticsState({
  required String scope,
  required ShopCosmeticsState state,
}) async {
  await ShopCosmeticsRepository(scopeResolver: () => scope).save(state);
}

Map<String, dynamic> _baseState({
  required String userId,
  required int walletCoins,
}) {
  return <String, dynamic>{
    'userState': <String, dynamic>{
      'userId': userId,
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
        'lastResetDate': '2026-07-23',
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
