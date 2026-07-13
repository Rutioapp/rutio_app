import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/features/shop/application/shop_cosmetics_controller.dart';
import 'package:rutio/features/shop/data/shop_assets_catalog.dart';
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

      final result = await controller.purchaseAsset('wallpaper_mist_blue');
      final persisted = await ShopCosmeticsRepository().load();

      expect(result.isSuccess, isTrue);
      expect(await controller.getWalletCoins(), 380);
      expect(persisted.ownedAssetIds, contains('wallpaper_mist_blue'));
    });

    test('demo-sized wallet still spends coins normally on purchase', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final asset = ShopAssetsCatalog.getAssetById('wallpaper_mist_blue')!;
      final controller = await _createController(walletCoins: 999999);

      final result = await controller.purchaseAsset(asset.id);

      expect(result.isSuccess, isTrue);
      expect(await controller.getWalletCoins(), 999999 - asset.priceAmber);
    });

    test('rare wallpaper purchase persists ownership and equipped state',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final controller = await _createController(walletCoins: 1000);

      final purchaseResult =
          await controller.purchaseAsset('wallpaper_jungle_sunrise');
      final equipResult =
          await controller.equipAsset('wallpaper_jungle_sunrise');
      final persisted = await ShopCosmeticsRepository().load();

      expect(purchaseResult.isSuccess, isTrue);
      expect(equipResult.isSuccess, isTrue);
      expect(await controller.getWalletCoins(), 750);
      expect(persisted.ownedAssetIds, contains('wallpaper_jungle_sunrise'));
      expect(persisted.equippedWallpaperId, 'wallpaper_jungle_sunrise');
    });

    test('restores owned and equipped state from persistence', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final repository = ShopCosmeticsRepository();
      await repository.save(
        ShopCosmeticsState(
          ownedAssetIds: <String>[
            'wallpaper_mist_blue',
            'habit_card_warm_beige',
          ],
          ownedBundleIds: <String>['bundle_warm_beige'],
          equippedWallpaperId: 'wallpaper_mist_blue',
          equippedHabitCardSkinId: 'habit_card_warm_beige',
        ),
      );

      final controller = await _createController(walletCoins: 0);
      final state = await controller.getState();

      expect(state.ownedBundleIds, contains('bundle_warm_beige'));
      expect(state.ownedAssetIds, contains('wallpaper_mist_blue'));
      expect(
        await controller
            .getEquippedAssetForCategory(ShopAssetCategory.wallpaper),
        isNotNull,
      );
      expect(
        await controller.assetOwnershipState('wallpaper_mist_blue'),
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

    test(
        'equipped wallpaper helper returns null when equipped asset is not owned',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final repository = ShopCosmeticsRepository();
      await repository.save(
        ShopCosmeticsState(
          ownedAssetIds: <String>[],
          ownedBundleIds: <String>[],
          equippedWallpaperId: 'wallpaper_mist_blue',
        ),
      );

      final controller = await _createController(walletCoins: 0);

      expect(await controller.getEquippedWallpaperAssetOrNull(), isNull);
    });

    test('equipped wallpaper helper returns null for empty equipped id',
        () async {
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
          ownedAssetIds: <String>['wallpaper_mist_blue'],
          ownedBundleIds: <String>[],
          equippedWallpaperId: 'wallpaper_mist_blue',
        ),
      );

      final controller = await _createController(walletCoins: 0);
      final asset = await controller.getEquippedWallpaperAssetOrNull();

      expect(asset?.id, 'wallpaper_mist_blue');
      expect(asset?.category, ShopAssetCategory.wallpaper);
    });

    test('sync wallpaper helper resolves hydrated asset from memory', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final repository = ShopCosmeticsRepository();
      await repository.save(
        ShopCosmeticsState(
          ownedAssetIds: <String>['wallpaper_mist_blue'],
          ownedBundleIds: <String>[],
          equippedWallpaperId: 'wallpaper_mist_blue',
        ),
      );

      final controller = await _createController(walletCoins: 0);
      await controller.hydrate();

      expect(
        controller.getEquippedWallpaperAssetOrNullSync()?.id,
        'wallpaper_mist_blue',
      );
      expect(controller.hasStateForCurrentScope, isTrue);
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
          equippedUserCardSkinId: 'wallpaper_mist_blue',
        ),
      );

      final controller = await _createController(walletCoins: 0);

      expect(await controller.getEquippedUserCardAssetOrNull(), isNull);
    });

    test('getWalletCoins falls back to zero when root state is missing',
        () async {
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

      await controller.purchaseAsset('wallpaper_mist_blue');
      await controller.equipAsset('wallpaper_mist_blue');

      expect(
        (await controller.getEquippedWallpaperAssetOrNull())?.id,
        'wallpaper_mist_blue',
      );
    });

    test('equipping a purchased habit card updates resolved habit card asset',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final controller = await _createController(walletCoins: 500);

      await controller.purchaseAsset('habit_card_violet_flame');
      await controller.equipAsset('habit_card_violet_flame');

      expect(
        (await controller.getEquippedHabitCardAssetOrNull())?.id,
        'habit_card_violet_flame',
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

      await controller.purchaseAsset('wallpaper_mist_blue');
      await controller.purchaseAsset('habit_card_warm_beige');
      await controller.purchaseAsset('user_card_warm_beige');

      final wallpaperResult =
          await controller.equipAsset('wallpaper_mist_blue');
      final habitCardResult =
          await controller.equipAsset('habit_card_warm_beige');
      final userCardResult =
          await controller.equipAsset('user_card_warm_beige');
      final persisted = await ShopCosmeticsRepository().load();

      expect(wallpaperResult.isSuccess, isTrue);
      expect(habitCardResult.isSuccess, isTrue);
      expect(userCardResult.isSuccess, isTrue);
      expect(persisted.equippedWallpaperId, 'wallpaper_mist_blue');
      expect(persisted.equippedHabitCardSkinId, 'habit_card_warm_beige');
      expect(persisted.equippedUserCardSkinId, 'user_card_warm_beige');
    });

    test('equipAsset notifies listeners with the new equipped wallpaper id',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final controller = await _createController(walletCoins: 500);
      await controller.purchaseAsset('wallpaper_mist_blue');

      var notificationCount = 0;
      controller.addListener(() {
        notificationCount += 1;
      });

      final result = await controller.equipAsset('wallpaper_mist_blue');

      expect(result.isSuccess, isTrue);
      expect(notificationCount, greaterThan(0));
      expect(controller.state?.equippedWallpaperId, 'wallpaper_mist_blue');
    });

    test('equipAsset notifies listeners with the new equipped habit card id',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final controller = await _createController(walletCoins: 500);
      await controller.purchaseAsset('habit_card_violet_flame');

      var notificationCount = 0;
      controller.addListener(() {
        notificationCount += 1;
      });

      final result = await controller.equipAsset('habit_card_violet_flame');
      final persisted = await ShopCosmeticsRepository().load();

      expect(result.isSuccess, isTrue);
      expect(notificationCount, greaterThan(0));
      expect(
        controller.state?.equippedHabitCardSkinId,
        'habit_card_violet_flame',
      );
      expect(persisted.equippedHabitCardSkinId, 'habit_card_violet_flame');
    });

    test('equipAsset fails for unowned asset', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final controller = await _createController(walletCoins: 0);

      final result = await controller.equipAsset('wallpaper_mist_blue');

      expect(result.status, ShopCosmeticsOperationStatus.assetNotOwned);
      expect(
          (await ShopCosmeticsRepository().load()).equippedWallpaperId, isNull);
    });

    test('equipAsset fails for missing asset id', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final controller = await _createController(walletCoins: 0);

      final result = await controller.equipAsset('missing_asset');

      expect(result.status, ShopCosmeticsOperationStatus.assetNotFound);
    });

    test('equipAsset restores previous in-memory state when persistence fails',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final repository = _FailingShopCosmeticsRepository(
        ShopCosmeticsState(
          ownedAssetIds: const <String>[
            'wallpaper_mist_blue',
            'wallpaper_soft_sage',
          ],
          ownedBundleIds: const <String>[],
          equippedWallpaperId: 'wallpaper_mist_blue',
        ),
      );
      final controller = await _createController(
        walletCoins: 0,
        repository: repository,
      );
      await controller.hydrate();

      await expectLater(
        controller.equipAsset('wallpaper_soft_sage'),
        throwsA(isA<StateError>()),
      );

      expect(controller.state?.equippedWallpaperId, 'wallpaper_mist_blue');
      expect(
        controller.getEquippedWallpaperAssetOrNullSync()?.id,
        'wallpaper_mist_blue',
      );
    });
  });
}

Future<ShopCosmeticsController> _createController({
  required int walletCoins,
  ShopCosmeticsRepository? repository,
}) async {
  final repo = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope('shop-cosmetics-user');
  final store = UserStateStore(
    repo,
    journalEntrySyncService: JournalEntrySyncService(),
  );
  await store.save(_baseState(walletCoins: walletCoins));
  return ShopCosmeticsController(
    userStateStore: store,
    repository: repository,
  );
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

class _FailingShopCosmeticsRepository extends ShopCosmeticsRepository {
  _FailingShopCosmeticsRepository(this._state);

  final ShopCosmeticsState _state;

  @override
  Future<ShopCosmeticsState> load() async => _state;

  @override
  Future<void> save(ShopCosmeticsState state) async {
    throw StateError('persistence failed');
  }
}
