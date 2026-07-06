import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/features/shop/application/shop_cosmetics_controller.dart';
import 'package:rutio/features/shop/data/shop_cosmetics_repository.dart';
import 'package:rutio/features/shop/domain/models/shop_asset_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_state.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShopCosmeticsController', () {
    test('purchaseAsset persists ownership and wallet coins', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final controller = await _createController(walletCoins: 500);

      final result = await controller.purchaseAsset('wallpaper_warm_beige');
      final persisted = await ShopCosmeticsRepository().load();

      expect(result.isSuccess, isTrue);
      expect(await controller.getWalletCoins(), 380);
      expect(persisted.ownedAssetIds, contains('wallpaper_warm_beige'));
    });

    test('purchaseBundle unlocks assets and persists equipped ids later', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final controller = await _createController(walletCoins: 1000);

      final bundleResult = await controller.purchaseBundle('bundle_warm_beige');
      final equipResult = await controller.equipAsset('wallpaper_warm_beige');
      final persisted = await ShopCosmeticsRepository().load();

      expect(bundleResult.isSuccess, isTrue);
      expect(equipResult.isSuccess, isTrue);
      expect(await controller.getWalletCoins(), 700);
      expect(persisted.ownedBundleIds, contains('bundle_warm_beige'));
      expect(persisted.equippedWallpaperId, 'wallpaper_warm_beige');
    });

    test('restores owned and equipped state from persistence', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final repository = ShopCosmeticsRepository();
      await repository.save(
        ShopCosmeticsState(
          ownedAssetIds: <String>[
            'wallpaper_warm_beige',
            'habit_card_warm_beige',
          ],
          ownedBundleIds: <String>['bundle_warm_beige'],
          equippedWallpaperId: 'wallpaper_warm_beige',
          equippedHabitCardSkinId: 'habit_card_warm_beige',
        ),
      );

      final controller = await _createController(walletCoins: 0);
      final state = await controller.getState();

      expect(state.ownedBundleIds, contains('bundle_warm_beige'));
      expect(state.ownedAssetIds, contains('wallpaper_warm_beige'));
      expect(
        await controller.getEquippedAssetForCategory(ShopAssetCategory.wallpaper),
        isNotNull,
      );
      expect(
        await controller.assetOwnershipState('wallpaper_warm_beige'),
        ShopAssetOwnershipState.equipped,
      );
    });
  });
}

Future<ShopCosmeticsController> _createController({
  required int walletCoins,
}) async {
  final repo = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope('shop-cosmetics-user');
  final store = UserStateStore(
    repo,
    journalEntrySyncService: JournalEntrySyncService(),
  );
  await store.save(_baseState(walletCoins: walletCoins));
  return ShopCosmeticsController(userStateStore: store);
}

Map<String, dynamic> _baseState({
  required int walletCoins,
}) {
  return <String, dynamic>{
    'userState': <String, dynamic>{
      'userId': 'shop-cosmetics-user',
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
        'lastResetDate': '2026-07-06',
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
