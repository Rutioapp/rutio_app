import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/features/shop/application/shop_cosmetics_controller.dart';
import 'package:rutio/features/shop/data/cloud/cloud_cosmetics_cache.dart';
import 'package:rutio/features/shop/data/cloud/cloud_cosmetics_snapshot.dart';
import 'package:rutio/features/shop/data/cloud/shop_cosmetics_cloud_repository.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_equip_dtos.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_errors.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_purchase_dtos.dart';
import 'package:rutio/features/shop/data/shop_assets_catalog.dart';
import 'package:rutio/features/shop/data/shop_cosmetics_repository.dart';
import 'package:rutio/features/shop/domain/models/shop_asset_enums.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef _FetchResponseFactory
    = FutureOr<ShopCloudReadResult<CloudCosmeticsSnapshot>> Function();

typedef _ControllerEnv = ({
  ShopCosmeticsController controller,
  UserStateStore store,
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShopCosmeticsController cloud mode', () {
    test('loads a cloud snapshot and keeps cached state during loading',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final snapshot = _snapshot(
        userId: 'shop-cloud-user',
        ownedAssetIds: <String>['wallpaper_mist_blue'],
        wallpaperId: 'wallpaper_mist_blue',
      );
      final repo = _FakeCloudCosmeticsRepository(
        fetchResponses: <_FetchResponseFactory>[
          () async {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            return _success(snapshot);
          },
        ],
      );

      final env = await _createController(
        cloudRepository: repo,
        cloudCache: _memoryCache(snapshot),
      );
      final controller = env.controller;

      await Future<void>.delayed(Duration.zero);
      expect(controller.cloudState.status, ShopCosmeticsCloudStatus.loading);
      expect(controller.getEquippedWallpaperAssetOrNullSync()?.id,
          'wallpaper_mist_blue');

      final state = await controller.getState();

      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(controller.cloudState.status, ShopCosmeticsCloudStatus.ready);
      expect(state.ownedAssetIds, contains('wallpaper_mist_blue'));
      expect(controller.getEquippedWallpaperAssetOrNullSync()?.id,
          'wallpaper_mist_blue');
    });

    test('stale cache survives a failed fetch', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final snapshot = _snapshot(
        userId: 'shop-cloud-user',
        ownedAssetIds: <String>['user_card_full_moon'],
        userCardId: 'user_card_full_moon',
      );
      final repo = _FakeCloudCosmeticsRepository(
        fetchResponses: <_FetchResponseFactory>[
          () async => _failure(
            ShopCloudErrorCode.networkUnavailable,
            'network unavailable',
          ),
        ],
      );

      final env = await _createController(
        cloudRepository: repo,
        cloudCache: _memoryCache(snapshot),
      );
      final controller = env.controller;

      final state = await controller.getState();

      expect(controller.cloudState.status, ShopCosmeticsCloudStatus.stale);
      expect(state.ownedAssetIds, contains('user_card_full_moon'));
      expect(controller.getEquippedUserCardAssetOrNullSync()?.id,
          'user_card_full_moon');
    });

    test('cloud purchase updates the cloud state without touching legacy data',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final repo = _FakeCloudCosmeticsRepository(
        fetchResponses: <_FetchResponseFactory>[
          () async => _success(
            _snapshot(
              userId: 'shop-cloud-user',
              ownedAssetIds: const <String>[],
            ),
          ),
          () async => _success(
            _snapshot(
              userId: 'shop-cloud-user',
              ownedAssetIds: <String>['wallpaper_mist_blue'],
            ),
          ),
        ],
      );
      final controller = (await _createController(cloudRepository: repo)).controller;

      await controller.purchaseAsset('wallpaper_mist_blue');
      final legacyState = await ShopCosmeticsRepository().load();

      expect(legacyState.ownedAssetIds, isNot(contains('wallpaper_mist_blue')));
    });

    test('cloud equip switches the correct slot and survives reload', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final repo = _FakeCloudCosmeticsRepository(
        fetchResponses: <_FetchResponseFactory>[
          () async => _success(
            _snapshot(
              userId: 'shop-cloud-user',
              ownedAssetIds: <String>['habit_card_warm_beige'],
            ),
          ),
          () async => _success(
            _snapshot(
              userId: 'shop-cloud-user',
              ownedAssetIds: <String>['habit_card_warm_beige'],
              habitCardId: 'habit_card_warm_beige',
            ),
          ),
        ],
      );
      final controller = (await _createController(cloudRepository: repo)).controller;

      final result = await controller.equipAsset('habit_card_warm_beige');

      expect(result.isSuccess, isTrue);
      expect(controller.getEquippedHabitCardAssetOrNullSync()?.id,
          'habit_card_warm_beige');
    });

    test('switching users clears the previous cloud state immediately',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final fetchGate = Completer<void>();
      final repo = _FakeCloudCosmeticsRepository(
        fetchResponses: <_FetchResponseFactory>[
          () async {
            await fetchGate.future;
            return _success(
              _snapshot(
                userId: 'shop-cosmetics-user-a',
                ownedAssetIds: <String>['wallpaper_mist_blue'],
                wallpaperId: 'wallpaper_mist_blue',
              ),
            );
          },
          () async => _success(
            _snapshot(
              userId: 'shop-cosmetics-user-b',
              ownedAssetIds: <String>['user_card_full_moon'],
              userCardId: 'user_card_full_moon',
            ),
          ),
        ],
      );
      final env = await _createController(cloudRepository: repo);
      final controller = env.controller;
      final firstLoad = controller.getState();
      await Future<void>.delayed(Duration.zero);

      await _switchScope(env.store, userId: 'shop-cosmetics-user-b');
      fetchGate.complete();
      await firstLoad;
      await Future<void>.delayed(Duration.zero);

      expect(controller.cloudState.userId, 'shop-cosmetics-user-b');
      expect(controller.state?.ownedAssetIds, isNot(contains('wallpaper_mist_blue')));
    });

    test('logout clears the in-memory cloud state', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final fetchGate = Completer<void>();
      final repo = _FakeCloudCosmeticsRepository(
        fetchResponses: <_FetchResponseFactory>[
          () async {
            await fetchGate.future;
            return _success(
              _snapshot(
                userId: 'shop-cloud-user',
                ownedAssetIds: <String>['wallpaper_mist_blue'],
              ),
            );
          },
        ],
      );
      final env = await _createController(cloudRepository: repo);
      final controller = env.controller;

      final loadFuture = controller.getState();
      await Future<void>.delayed(Duration.zero);
      await _switchScope(env.store, userId: null);
      fetchGate.complete();
      await loadFuture;
      await Future<void>.delayed(Duration.zero);
    });

    test('cloud flag disabled keeps the legacy flow', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final controller = (await _createController(cloudEnabled: false)).controller;

      expect(controller.isCloudEnabled, isFalse);

      final result = await controller.purchaseAsset('wallpaper_mist_blue');
      final persisted = await ShopCosmeticsRepository().load();

      expect(result.isSuccess, isTrue);
      expect(persisted.ownedAssetIds, contains('wallpaper_mist_blue'));
    });
  });
}

Future<_ControllerEnv> _createController({
  CloudCosmeticsRepository? cloudRepository,
  CloudCosmeticsCache? cloudCache,
  bool? cloudEnabled = true,
}) async {
  final repo = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope('shop-cloud-user');
  final store = UserStateStore(
    repo,
    journalEntrySyncService: JournalEntrySyncService(),
  );
  await store.save(_baseState(walletCoins: 500));
  await store.load();
  return (
    controller: ShopCosmeticsController(
      userStateStore: store,
      cloudRepository: cloudRepository,
      cloudCache: cloudCache,
      cloudEnabled: cloudEnabled,
    ),
    store: store,
  );
}

CloudCosmeticsCache _memoryCache(CloudCosmeticsSnapshot snapshot) {
  return _MemoryCloudCosmeticsCache(snapshot);
}

Future<void> _switchScope(
  UserStateStore store, {
  required String? userId,
}) async {
  await store.switchLocalScope(userId: userId, forceReload: false);
}

ShopCloudReadResult<CloudCosmeticsSnapshot> _success(
  CloudCosmeticsSnapshot snapshot,
) {
  return ShopCloudReadResult<CloudCosmeticsSnapshot>.success(data: snapshot);
}

ShopCloudReadResult<CloudCosmeticsSnapshot> _failure(
  ShopCloudErrorCode code,
  String message,
) {
  return ShopCloudReadResult<CloudCosmeticsSnapshot>.failure(
    error: ShopCloudReadError(code: code, message: message),
  );
}

CloudCosmeticsSnapshot _snapshot({
  required String userId,
  required List<String> ownedAssetIds,
  String? wallpaperId,
  String? habitCardId,
  String? userCardId,
}) {
  final now = DateTime.utc(2026, 7, 19, 12);
  return CloudCosmeticsSnapshot(
    userId: userId,
    ownedAssetIds: ownedAssetIds,
    equippedWallpaperId: wallpaperId,
    equippedHabitCardSkinId: habitCardId,
    equippedUserCardSkinId: userCardId,
    catalogVersion: 1,
    fetchedAt: now,
    updatedAt: now,
  );
}

Map<String, dynamic> _baseState({
  required int walletCoins,
}) {
  return <String, dynamic>{
    'userState': <String, dynamic>{
      'userId': 'shop-cloud-user',
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

class _MemoryCloudCosmeticsCache implements CloudCosmeticsCache {
  _MemoryCloudCosmeticsCache(this._snapshot) {
    _seed();
  }

  final CloudCosmeticsSnapshot _snapshot;
  final Map<String, CloudCosmeticsCacheEntry> _entries =
      <String, CloudCosmeticsCacheEntry>{};

  void _seed() {
    _entries[_snapshot.userId] = CloudCosmeticsCacheEntry.fromSnapshot(
      _snapshot,
      cachedAt: _snapshot.fetchedAt,
    );
  }

  @override
  Future<void> clearAll() async {
    _entries.clear();
  }

  @override
  Future<void> clearForUser(String userId) async {
    _entries.remove(userId);
  }

  @override
  Future<CloudCosmeticsCacheEntry?> read(String userId) async {
    return _entries[userId];
  }

  @override
  Future<CloudCosmeticsCacheEntry> save(CloudCosmeticsSnapshot snapshot) async {
    final entry = CloudCosmeticsCacheEntry.fromSnapshot(snapshot);
    _entries[snapshot.userId] = entry;
    return entry;
  }
}

class _FakeCloudCosmeticsRepository implements CloudCosmeticsRepository {
  _FakeCloudCosmeticsRepository({
    required List<_FetchResponseFactory> fetchResponses,
  }) : _fetchResponses = fetchResponses;

  final List<_FetchResponseFactory> _fetchResponses;
  final List<String> purchaseCalls = <String>[];
  final List<String> equipCalls = <String>[];

  int _fetchIndex = 0;

  @override
  Future<RemoteShopEquipResultDto> equipAsset({
    required String itemId,
    required String requestId,
  }) async {
    equipCalls.add(itemId);
    return RemoteShopEquipResultDto(
      requestId: requestId,
      operation: 'equip',
      itemId: itemId,
      slot: ShopAssetsCatalog.getAssetById(itemId)!.category.key,
      createdAt: DateTime.utc(2026, 7, 19, 12),
    );
  }

  @override
  Future<ShopCloudReadResult<CloudCosmeticsSnapshot>> fetchSnapshot() async {
    if (_fetchIndex < _fetchResponses.length) {
      _fetchIndex += 1;
      return await _fetchResponses[_fetchIndex - 1]();
    }
    return _failure(ShopCloudErrorCode.unknown, 'No queued fetch response.');
  }

  @override
  Future<RemoteShopPurchaseResultDto> purchaseAsset({
    required String itemId,
    required String requestId,
  }) async {
    purchaseCalls.add(itemId);
    final asset = ShopAssetsCatalog.getAssetById(itemId)!;
    return RemoteShopPurchaseResultDto(
      requestId: requestId,
      operation: 'purchase',
      itemId: itemId,
      priceCoins: asset.priceAmber,
      coins: 500 - asset.priceAmber,
      walletVersion: 1,
      inventoryQuantity: 1,
    );
  }
}
