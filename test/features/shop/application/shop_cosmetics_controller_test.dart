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

    test('equipped wallpaper helper returns null for invalid id', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final repository = ShopCosmeticsRepository();
      await repository.save(
        ShopCosmeticsState(
          ownedAssetIds: <String>[],
          ownedBundleIds: <String>[],
          equippedWallpaperId: 'wallpaper_missing',
        ),
      );

      final controller = await _createController(walletCoins: 0);

      expect(await controller.getEquippedWallpaperAssetOrNull(), isNull);
    });

    test('equipped wallpaper helper ignores wrong category ids', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final repository = ShopCosmeticsRepository();
      await repository.save(
        ShopCosmeticsState(
          ownedAssetIds: <String>[],
          ownedBundleIds: <String>[],
          equippedWallpaperId: 'habit_card_warm_beige',
        ),
      );

      final controller = await _createController(walletCoins: 0);

      expect(await controller.getEquippedWallpaperAssetOrNull(), isNull);
    });

    test('equipped wallpaper helper returns null when equipped asset is not owned',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final repository = ShopCosmeticsRepository();
      await repository.save(
        ShopCosmeticsState(
          ownedAssetIds: <String>[],
          ownedBundleIds: <String>[],
          equippedWallpaperId: 'wallpaper_warm_beige',
        ),
      );

      final controller = await _createController(walletCoins: 0);

      expect(await controller.getEquippedWallpaperAssetOrNull(), isNull);
    });

    test('equipped wallpaper helper returns null for empty equipped id', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final repository = ShopCosmeticsRepository();
      await repository.save(
        ShopCosmeticsState(
          ownedAssetIds: <String>[],
          ownedBundleIds: <String>[],
          equippedWallpaperId: '   ',
        ),
      );

      final controller = await _createController(walletCoins: 0);

      expect(await controller.getEquippedWallpaperAssetOrNull(), isNull);
    });

    test('equipped wallpaper helper resolves valid asset', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final repository = ShopCosmeticsRepository();
      await repository.save(
        ShopCosmeticsState(
          ownedAssetIds: <String>['wallpaper_warm_beige'],
          ownedBundleIds: <String>[],
          equippedWallpaperId: 'wallpaper_warm_beige',
        ),
      );

      final controller = await _createController(walletCoins: 0);
      final asset = await controller.getEquippedWallpaperAssetOrNull();

      expect(asset?.id, 'wallpaper_warm_beige');
      expect(asset?.category, ShopAssetCategory.wallpaper);
    });

    test('equipped habit card helper resolves valid asset', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final repository = ShopCosmeticsRepository();
      await repository.save(
        ShopCosmeticsState(
          ownedAssetIds: <String>['habit_card_warm_beige'],
          ownedBundleIds: <String>[],
          equippedHabitCardSkinId: 'habit_card_warm_beige',
        ),
      );

      final controller = await _createController(walletCoins: 0);
      final asset = await controller.getEquippedHabitCardAssetOrNull();

      expect(asset?.id, 'habit_card_warm_beige');
      expect(asset?.category, ShopAssetCategory.habitCard);
    });

    test('equipped habit card helper returns null for invalid id', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final repository = ShopCosmeticsRepository();
      await repository.save(
        ShopCosmeticsState(
          ownedAssetIds: <String>[],
          ownedBundleIds: <String>[],
          equippedHabitCardSkinId: 'habit_card_missing',
        ),
      );

      final controller = await _createController(walletCoins: 0);

      expect(await controller.getEquippedHabitCardAssetOrNull(), isNull);
    });

    test('equipped habit card helper ignores wrong category ids', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final repository = ShopCosmeticsRepository();
      await repository.save(
        ShopCosmeticsState(
          ownedAssetIds: <String>[],
          ownedBundleIds: <String>[],
          equippedHabitCardSkinId: 'user_card_warm_beige',
        ),
      );

      final controller = await _createController(walletCoins: 0);

      expect(await controller.getEquippedHabitCardAssetOrNull(), isNull);
    });

    test('equipped habit card helper resolves bundle-owned asset', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final repository = ShopCosmeticsRepository();
      await repository.save(
        ShopCosmeticsState(
          ownedAssetIds: <String>[],
          ownedBundleIds: <String>['bundle_warm_beige'],
          equippedHabitCardSkinId: 'habit_card_warm_beige',
        ),
      );

      final controller = await _createController(walletCoins: 0);

      expect(
        (await controller.getEquippedHabitCardAssetOrNull())?.id,
        'habit_card_warm_beige',
      );
    });

    test('equipped user card helper resolves valid asset', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final repository = ShopCosmeticsRepository();
      await repository.save(
        ShopCosmeticsState(
          ownedAssetIds: <String>['user_card_warm_beige'],
          ownedBundleIds: <String>[],
          equippedUserCardSkinId: 'user_card_warm_beige',
        ),
      );

      final controller = await _createController(walletCoins: 0);
      final asset = await controller.getEquippedUserCardAssetOrNull();

      expect(asset?.id, 'user_card_warm_beige');
      expect(asset?.category, ShopAssetCategory.userCard);
    });

    test('equipped user card helper returns null for invalid id', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final repository = ShopCosmeticsRepository();
      await repository.save(
        ShopCosmeticsState(
          ownedAssetIds: <String>[],
          ownedBundleIds: <String>[],
          equippedUserCardSkinId: 'user_card_missing',
        ),
      );

      final controller = await _createController(walletCoins: 0);

      expect(await controller.getEquippedUserCardAssetOrNull(), isNull);
    });

    test('equipped user card helper ignores wrong category ids', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final repository = ShopCosmeticsRepository();
      await repository.save(
        ShopCosmeticsState(
          ownedAssetIds: <String>[],
          ownedBundleIds: <String>[],
          equippedUserCardSkinId: 'wallpaper_warm_beige',
        ),
      );

      final controller = await _createController(walletCoins: 0);

      expect(await controller.getEquippedUserCardAssetOrNull(), isNull);
    });

    test('getWalletCoins falls back to zero when root state is missing', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final repo = UserStateRepository(storage: UserStateStorage())
        ..setActiveUserScope('shop-cosmetics-empty-user');
      final store = UserStateStore(
        repo,
        journalEntrySyncService: JournalEntrySyncService(),
      );
      final controller = ShopCosmeticsController(userStateStore: store);

      expect(await controller.getWalletCoins(), 0);
    });

    test('equipping a purchased wallpaper updates resolved wallpaper asset',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final controller = await _createController(walletCoins: 500);

      await controller.purchaseAsset('wallpaper_warm_beige');
      await controller.equipAsset('wallpaper_warm_beige');

      expect(
        (await controller.getEquippedWallpaperAssetOrNull())?.id,
        'wallpaper_warm_beige',
      );
    });

    test('equipping a purchased habit card updates resolved habit card asset',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final controller = await _createController(walletCoins: 500);

      await controller.purchaseAsset('habit_card_warm_beige');
      await controller.equipAsset('habit_card_warm_beige');

      expect(
        (await controller.getEquippedHabitCardAssetOrNull())?.id,
        'habit_card_warm_beige',
      );
    });

    test('equipping a purchased user card updates resolved user card asset',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final controller = await _createController(walletCoins: 500);

      await controller.purchaseAsset('user_card_warm_beige');
      await controller.equipAsset('user_card_warm_beige');

      expect(
        (await controller.getEquippedUserCardAssetOrNull())?.id,
        'user_card_warm_beige',
      );
    });

    test('equipAsset updates the correct slot for each category', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final controller = await _createController(walletCoins: 1000);

      await controller.purchaseAsset('wallpaper_warm_beige');
      await controller.purchaseAsset('habit_card_warm_beige');
      await controller.purchaseAsset('user_card_warm_beige');

      final wallpaperResult = await controller.equipAsset('wallpaper_warm_beige');
      final habitCardResult = await controller.equipAsset('habit_card_warm_beige');
      final userCardResult = await controller.equipAsset('user_card_warm_beige');
      final persisted = await ShopCosmeticsRepository().load();

      expect(wallpaperResult.isSuccess, isTrue);
      expect(habitCardResult.isSuccess, isTrue);
      expect(userCardResult.isSuccess, isTrue);
      expect(persisted.equippedWallpaperId, 'wallpaper_warm_beige');
      expect(persisted.equippedHabitCardSkinId, 'habit_card_warm_beige');
      expect(persisted.equippedUserCardSkinId, 'user_card_warm_beige');
    });

    test('equipAsset fails for unowned asset', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final controller = await _createController(walletCoins: 0);

      final result = await controller.equipAsset('wallpaper_warm_beige');

      expect(result.status, ShopCosmeticsOperationStatus.assetNotOwned);
      expect((await ShopCosmeticsRepository().load()).equippedWallpaperId, isNull);
    });

    test('equipAsset fails for missing asset id', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final controller = await _createController(walletCoins: 0);

      final result = await controller.equipAsset('missing_asset');

      expect(result.status, ShopCosmeticsOperationStatus.assetNotFound);
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
