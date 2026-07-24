import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/features/global_wallet/application/global_wallet_controller.dart';
import 'package:rutio/features/global_wallet/application/global_wallet_state.dart';
import 'package:rutio/features/global_wallet/data/cloud/cloud_wallet_errors.dart';
import 'package:rutio/features/global_wallet/data/cloud/cloud_wallet_repository.dart';
import 'package:rutio/features/global_wallet/data/cloud/cloud_wallet_snapshot.dart';
import 'package:rutio/features/global_wallet/data/cloud/wallet_cache.dart';
import 'package:rutio/features/shop/application/shop_cosmetics_controller.dart';
import 'package:rutio/features/shop/data/cloud/cloud_cosmetics_cache.dart';
import 'package:rutio/features/shop/data/cloud/cloud_cosmetics_snapshot.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_equip_repository.dart';
import 'package:rutio/features/shop/data/cloud/shop_cosmetics_cloud_repository.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_equip_dtos.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_errors.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_purchase_dtos.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_purchase_repository.dart';
import 'package:rutio/features/shop/data/shop_assets_catalog.dart';
import 'package:rutio/features/shop/data/shop_cosmetics_repository.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_state.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/domain/shop_purchase_failure.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

const testUserId = 'shop-cloud-user';

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
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(state.ownedAssetIds, contains('user_card_full_moon'));
      expect(controller.getEquippedUserCardAssetOrNullSync()?.id,
          'user_card_full_moon');
      expect(controller.state?.equippedUserCardSkinId, 'user_card_full_moon');
    });

    test('cloud state ignores legacy bundles when resolving wallpaper',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final repository = await _shopRepository();
      await repository.save(
        ShopCosmeticsState(
          ownedAssetIds: <String>['wallpaper_mist_blue'],
          ownedBundleIds: <String>['pack_blanco_roto'],
          equippedWallpaperId: 'wallpaper_mist_blue',
        ),
      );

      final snapshot = _snapshot(
        userId: 'shop-cloud-user',
        ownedAssetIds: <String>['wallpaper_dusty_lilac'],
        wallpaperId: 'wallpaper_dusty_lilac',
      );
      final repo = _FakeCloudCosmeticsRepository(
        fetchResponses: <_FetchResponseFactory>[
          () async => _success(snapshot),
        ],
      );

      final env = await _createController(
        cloudRepository: repo,
        cloudCache: _memoryCache(snapshot),
      );
      final controller = env.controller;

      final state = await controller.getState();

      expect(state.ownedBundleIds, isEmpty);
      expect(controller.getEquippedWallpaperAssetOrNullSync()?.id,
          'wallpaper_dusty_lilac');
      expect(controller.state?.equippedWallpaperId, 'wallpaper_dusty_lilac');
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
      final controller =
          (await _createController(cloudRepository: repo)).controller;

      await controller.purchaseAsset('wallpaper_mist_blue');
      final legacyState = await (await _shopRepository()).load();

      expect(legacyState.ownedAssetIds, isNot(contains('wallpaper_mist_blue')));
    });

    test('cloud purchase applies the confirmed wallet balance immediately',
        () async {
      final walletRepo = _FakeCloudWalletRepository()
        ..enqueueSuccess(
          _walletSnapshot(
            userId: 'shop-cloud-user',
            coins: 380,
            version: 2,
            updatedAt: DateTime.utc(2026, 7, 19, 14),
          ),
        );
      final walletController = GlobalWalletController(
        repository: walletRepo,
        cache: _MemoryWalletCache(),
        currentUserIdProvider: () => 'shop-cloud-user',
        enabled: true,
      );
      await walletController.applyConfirmedBalance(
        userId: 'shop-cloud-user',
        coins: 500,
        version: 1,
        updatedAt: DateTime.utc(2026, 7, 19, 13),
      );
      final env = await _createController(
        cloudRepository: _FakeCloudCosmeticsRepository(
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
        ),
        globalWalletController: walletController,
      );

      final result = await env.controller.purchaseAsset('wallpaper_mist_blue');
      await Future<void>.delayed(Duration.zero);

      expect(result.isSuccess, isTrue);
      expect(walletController.state.status, GlobalWalletStatus.ready);
      expect(walletController.state.coins, 380);
      expect(walletRepo.calls, 1);
    });

    test('bundle purchase applies the confirmed wallet balance immediately',
        () async {
      final walletRepo = _FakeCloudWalletRepository()
        ..enqueueSuccess(
          _walletSnapshot(
            userId: 'shop-cloud-user',
            coins: 175,
            version: 2,
            updatedAt: DateTime.utc(2026, 7, 19, 15),
          ),
        );
      final walletController = GlobalWalletController(
        repository: walletRepo,
        cache: _MemoryWalletCache(),
        currentUserIdProvider: () => 'shop-cloud-user',
        enabled: true,
      );
      await walletController.applyConfirmedBalance(
        userId: 'shop-cloud-user',
        coins: 500,
        version: 1,
        updatedAt: DateTime.utc(2026, 7, 19, 13),
      );
      final env = await _createController(
        cloudRepository: _FakeCloudCosmeticsRepository(
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
                    ownedAssetIds: const <String>[],
                  ),
                ),
            () async => _success(
                  _snapshot(
                    userId: 'shop-cloud-user',
                    ownedAssetIds: const <String>[
                      'wallpaper_rutio_beige',
                      'habit_card_warm_beige',
                      'user_card_warm_beige',
                    ],
                  ),
                ),
          ],
        ),
        globalWalletController: walletController,
      );

      final result = await env.controller.purchaseBundle('pack_blanco_roto');
      await Future<void>.delayed(Duration.zero);

      expect(result.isSuccess, isTrue);
      expect(walletController.state.status, GlobalWalletStatus.ready);
      expect(walletController.state.coins, 175);
      expect(walletRepo.calls, 1);
    });

    test('bundle purchase accepts a partially owned bundle and keeps assets',
        () async {
      final walletRepo = _FakeCloudWalletRepository()
        ..enqueueSuccess(
          _walletSnapshot(
            userId: 'shop-cloud-user',
            coins: 320,
            version: 2,
            updatedAt: DateTime.utc(2026, 7, 19, 15, 30),
          ),
        );
      final walletController = GlobalWalletController(
        repository: walletRepo,
        cache: _MemoryWalletCache(),
        currentUserIdProvider: () => 'shop-cloud-user',
        enabled: true,
      );
      await walletController.applyConfirmedBalance(
        userId: 'shop-cloud-user',
        coins: 500,
        version: 1,
        updatedAt: DateTime.utc(2026, 7, 19, 13),
      );
      final repo = _FakeCloudCosmeticsRepository(
        fetchResponses: <_FetchResponseFactory>[
          () async => _success(
                _snapshot(
                  userId: 'shop-cloud-user',
                  ownedAssetIds: <String>['wallpaper_rutio_beige'],
                ),
              ),
          () async => _success(
                _snapshot(
                  userId: 'shop-cloud-user',
                  ownedAssetIds: <String>['wallpaper_rutio_beige'],
                ),
              ),
          () async => _success(
                _snapshot(
                  userId: 'shop-cloud-user',
                  ownedAssetIds: <String>[
                    'wallpaper_rutio_beige',
                    'habit_card_warm_beige',
                    'user_card_warm_beige',
                  ],
                  ownedBundleIds: <String>['pack_beige_rutio'],
                ),
              ),
        ],
      );
      repo.bundleOutcomes.add(
        RemoteShopBundlePurchaseResultDto(
          requestId: 'req-partial',
          bundleId: 'pack_beige_rutio',
          userId: 'shop-cloud-user',
          coinsDelta: -120,
          walletCoinsAfter: 320,
          wallpaperItemId: 'wallpaper_rutio_beige',
          habitCardItemId: 'habit_card_warm_beige',
          userCardItemId: 'user_card_warm_beige',
          isIdempotent: false,
          createdAt: DateTime.utc(2026, 7, 19, 15, 30),
        ),
      );
      final env = await _createController(
        cloudRepository: repo,
        globalWalletController: walletController,
      );
      await env.controller.getState();

      final result = await env.controller.purchaseBundle('pack_beige_rutio');
      await Future<void>.delayed(Duration.zero);

      expect(result.status, ShopCosmeticsOperationStatus.success);
      expect(result.walletCoins, 320);
      expect(
          env.controller.state?.ownedBundleIds, contains('pack_beige_rutio'));
      expect(
        env.controller.state?.ownedAssetIds,
        containsAll(<String>[
          'wallpaper_rutio_beige',
          'habit_card_warm_beige',
          'user_card_warm_beige',
        ]),
      );
      expect(walletController.state.coins, 320);
      expect(repo.purchaseCalls, contains('pack_beige_rutio'));
    });

    test('bundle purchase accepts a zero-cost completed bundle', () async {
      final walletRepo = _FakeCloudWalletRepository()
        ..enqueueSuccess(
          _walletSnapshot(
            userId: 'shop-cloud-user',
            coins: 500,
            version: 2,
            updatedAt: DateTime.utc(2026, 7, 19, 15, 30),
          ),
        );
      final walletController = GlobalWalletController(
        repository: walletRepo,
        cache: _MemoryWalletCache(),
        currentUserIdProvider: () => 'shop-cloud-user',
        enabled: true,
      );
      await walletController.applyConfirmedBalance(
        userId: 'shop-cloud-user',
        coins: 500,
        version: 1,
        updatedAt: DateTime.utc(2026, 7, 19, 13),
      );
      final repo = _FakeCloudCosmeticsRepository(
        fetchResponses: <_FetchResponseFactory>[
          () async => _success(
                _snapshot(
                  userId: 'shop-cloud-user',
                  ownedAssetIds: <String>[
                    'wallpaper_rutio_beige',
                    'habit_card_warm_beige',
                    'user_card_warm_beige',
                  ],
                ),
              ),
          () async => _success(
                _snapshot(
                  userId: 'shop-cloud-user',
                  ownedAssetIds: <String>[
                    'wallpaper_rutio_beige',
                    'habit_card_warm_beige',
                    'user_card_warm_beige',
                  ],
                ),
              ),
          () async => _success(
                _snapshot(
                  userId: 'shop-cloud-user',
                  ownedAssetIds: <String>[
                    'wallpaper_rutio_beige',
                    'habit_card_warm_beige',
                    'user_card_warm_beige',
                  ],
                  ownedBundleIds: <String>['pack_beige_rutio'],
                ),
              ),
        ],
      );
      repo.bundleOutcomes.add(
        RemoteShopBundlePurchaseResultDto(
          requestId: 'req-zero',
          bundleId: 'pack_beige_rutio',
          userId: 'shop-cloud-user',
          coinsDelta: 0,
          walletCoinsAfter: 500,
          wallpaperItemId: 'wallpaper_rutio_beige',
          habitCardItemId: 'habit_card_warm_beige',
          userCardItemId: 'user_card_warm_beige',
          isIdempotent: false,
          createdAt: DateTime.utc(2026, 7, 19, 15, 31),
        ),
      );
      final env = await _createController(
        cloudRepository: repo,
        globalWalletController: walletController,
      );
      await env.controller.getState();

      final result = await env.controller.purchaseBundle('pack_beige_rutio');
      await Future<void>.delayed(Duration.zero);

      expect(result.status, ShopCosmeticsOperationStatus.success);
      expect(result.walletCoins, 500);
      expect(
          env.controller.state?.ownedBundleIds, contains('pack_beige_rutio'));
      expect(walletController.state.coins, 500);
    });

    test('bundle purchase keeps the snapshot unchanged on SQL ambiguity',
        () async {
      final walletRepo = _FakeCloudWalletRepository()
        ..enqueueSuccess(
          _walletSnapshot(
            userId: 'shop-cloud-user',
            coins: 500,
            version: 2,
            updatedAt: DateTime.utc(2026, 7, 19, 15, 30),
          ),
        );
      final walletController = GlobalWalletController(
        repository: walletRepo,
        cache: _MemoryWalletCache(),
        currentUserIdProvider: () => 'shop-cloud-user',
        enabled: true,
      );
      await walletController.applyConfirmedBalance(
        userId: 'shop-cloud-user',
        coins: 500,
        version: 1,
        updatedAt: DateTime.utc(2026, 7, 19, 13),
      );
      final repo = _FakeCloudCosmeticsRepository(
        fetchResponses: <_FetchResponseFactory>[
          () async => _success(
                _snapshot(
                  userId: 'shop-cloud-user',
                  ownedAssetIds: <String>['wallpaper_rutio_beige'],
                ),
              ),
        ],
      );
      repo.bundleOutcomes.add(
        const ShopCloudPurchaseException(
          code: ShopPurchaseFailureCode.databaseQueryFailed,
          message: 'column reference "user_id" is ambiguous',
          retryable: true,
          definitive: true,
        ),
      );

      final env = await _createController(
        cloudRepository: repo,
        globalWalletController: walletController,
      );
      final initialState = await env.controller.getState();
      final initialRevision = env.controller.cloudSnapshotRevision;

      final result = await env.controller.purchaseBundle('pack_beige_rutio');
      await Future<void>.delayed(Duration.zero);

      expect(result.isSuccess, isFalse);
      expect(result.status, ShopCosmeticsOperationStatus.bundleNotFound);
      expect(env.controller.cloudSnapshotRevision, initialRevision);
      expect(env.controller.state?.ownedAssetIds, initialState.ownedAssetIds);
      expect(env.controller.state?.ownedBundleIds, initialState.ownedBundleIds);
      expect(env.controller.state?.equippedWallpaperId,
          initialState.equippedWallpaperId);
      expect(env.controller.state?.equippedHabitCardSkinId,
          initialState.equippedHabitCardSkinId);
      expect(env.controller.state?.equippedUserCardSkinId,
          initialState.equippedUserCardSkinId);
      expect(walletController.state.coins, 500);
      expect(repo.purchaseCalls, contains('pack_beige_rutio'));
    });

    test('cloud equip switches the correct slot and survives reload', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final snapshot = _snapshot(
        userId: 'shop-cloud-user',
        ownedAssetIds: <String>['habit_card_warm_beige'],
      );
      final repo = _FakeCloudCosmeticsRepository(
        fetchResponses: <_FetchResponseFactory>[
          () async => _success(snapshot),
          () async => _success(
                _snapshot(
                  userId: 'shop-cloud-user',
                  ownedAssetIds: <String>['habit_card_warm_beige'],
                  habitCardId: 'habit_card_warm_beige',
                ),
              ),
        ],
      );
      final controller = (await _createController(
        cloudRepository: repo,
        cloudCache: _memoryCache(snapshot),
      ))
          .controller;
      await controller.getState();

      final result = await controller.equipAsset('habit_card_warm_beige');

      expect(result.isSuccess, isTrue);
      expect(controller.getEquippedHabitCardAssetOrNullSync()?.id,
          'habit_card_warm_beige');
      expect(repo.equipCalls.single.slot, CosmeticSlot.habitCard.remoteDbKey);
      expect(repo.equipCalls.single.requestId, isNotEmpty);
    });

    test('cloud equip sends the wallpaper slot through to RPC', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final snapshot = _snapshot(
        userId: 'shop-cloud-user',
        ownedAssetIds: <String>['wallpaper_mist_blue'],
      );
      final repo = _FakeCloudCosmeticsRepository(
        fetchResponses: <_FetchResponseFactory>[
          () async => _success(snapshot),
        ],
      );
      final controller = (await _createController(
        cloudRepository: repo,
        cloudCache: _memoryCache(snapshot),
      ))
          .controller;
      await controller.getState();

      final result = await controller.equipAsset('wallpaper_mist_blue');

      expect(result.isSuccess, isTrue);
      expect(repo.equipCalls.single.slot, CosmeticSlot.background.remoteDbKey);
      expect(await controller.getWalletCoins(), 500);
      expect(controller.state?.ownedAssetIds, isNotEmpty);
    });

    test('cloud equip sends the user card slot through to RPC', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final snapshot = _snapshot(
        userId: 'shop-cloud-user',
        ownedAssetIds: <String>['user_card_full_moon'],
      );
      final repo = _FakeCloudCosmeticsRepository(
        fetchResponses: <_FetchResponseFactory>[
          () async => _success(snapshot),
        ],
      );
      final controller = (await _createController(
        cloudRepository: repo,
        cloudCache: _memoryCache(snapshot),
      ))
          .controller;
      await controller.getState();

      final result = await controller.equipAsset('user_card_full_moon');

      expect(result.isSuccess, isTrue);
      expect(repo.equipCalls.single.slot, CosmeticSlot.userCard.remoteDbKey);
    });

    test('cloud equipBundle performs three RPC calls with unique request ids',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final snapshot = _snapshot(
        userId: 'shop-cloud-user',
        ownedAssetIds: <String>[
          'wallpaper_rutio_beige',
          'habit_card_warm_beige',
          'user_card_warm_beige',
        ],
        ownedBundleIds: <String>['pack_beige_rutio'],
        wallpaperId: 'wallpaper_mist_blue',
      );
      final repo = _FakeCloudCosmeticsRepository(
        fetchResponses: <_FetchResponseFactory>[
          () async => _success(snapshot),
          () async => _success(
                _snapshot(
                  userId: 'shop-cloud-user',
                  ownedAssetIds: <String>[
                    'wallpaper_rutio_beige',
                    'habit_card_warm_beige',
                    'user_card_warm_beige',
                  ],
                  ownedBundleIds: <String>['pack_beige_rutio'],
                  wallpaperId: 'wallpaper_rutio_beige',
                  habitCardId: 'habit_card_warm_beige',
                  userCardId: 'user_card_warm_beige',
                ),
              ),
          () async => _success(
                _snapshot(
                  userId: 'shop-cloud-user',
                  ownedAssetIds: <String>[
                    'wallpaper_rutio_beige',
                    'habit_card_warm_beige',
                    'user_card_warm_beige',
                  ],
                  ownedBundleIds: <String>['pack_beige_rutio'],
                  wallpaperId: 'wallpaper_rutio_beige',
                  habitCardId: 'habit_card_warm_beige',
                  userCardId: 'user_card_warm_beige',
                ),
              ),
        ],
      );
      final controller = (await _createController(
        cloudRepository: repo,
        cloudCache: _memoryCache(snapshot),
      ))
          .controller;
      await controller.getState();

      final result = await controller.equipBundle('pack_beige_rutio');

      expect(result.isSuccess, isTrue);
      expect(repo.equipCalls, hasLength(3));
      expect(
        repo.equipCalls.map((call) => call.slot).toList(growable: false),
        <String>[
          CosmeticSlot.background.remoteDbKey,
          CosmeticSlot.habitCard.remoteDbKey,
          CosmeticSlot.userCard.remoteDbKey,
        ],
      );
      expect(
        repo.equipCalls.map((call) => call.requestId).toSet().length,
        3,
      );
      expect(controller.getEquippedWallpaperAssetOrNullSync()?.id,
          'wallpaper_rutio_beige');
      expect(controller.getEquippedHabitCardAssetOrNullSync()?.id,
          'habit_card_warm_beige');
      expect(controller.getEquippedUserCardAssetOrNullSync()?.id,
          'user_card_warm_beige');
      expect(repo.fetchCalls, greaterThanOrEqualTo(3));
    });

    test('cloud equipBundle keeps the pack incomplete on partial failure',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final snapshot = _snapshot(
        userId: 'shop-cloud-user',
        ownedAssetIds: <String>[
          'wallpaper_rutio_beige',
          'habit_card_warm_beige',
          'user_card_warm_beige',
        ],
        ownedBundleIds: <String>['pack_beige_rutio'],
      );
      final repo = _FakeCloudCosmeticsRepository(
        fetchResponses: <_FetchResponseFactory>[
          () async => _success(snapshot),
          () async => _success(snapshot),
          () async => _success(snapshot),
        ],
      );
      repo.equipOutcomes.add(
        RemoteShopEquipResultDto(
          requestId: 'req-1',
          operation: 'equip',
          itemId: 'wallpaper_rutio_beige',
          slot: CosmeticSlot.background.remoteDbKey,
          createdAt: DateTime.utc(2026, 7, 19, 12),
        ),
      );
      repo.equipOutcomes.add(
        const ShopCloudEquipException(
          code: ShopCosmeticsOperationFailureCode.networkUnavailable,
          message: 'network unavailable',
          retryable: true,
        ),
      );

      final controller = (await _createController(
        cloudRepository: repo,
        cloudCache: _memoryCache(snapshot),
      ))
          .controller;
      await controller.getState();

      final result = await controller.equipBundle('pack_beige_rutio');

      expect(result.isSuccess, isFalse);
      expect(controller.getEquippedWallpaperAssetOrNullSync(), isNull);
      expect(controller.getEquippedHabitCardAssetOrNullSync(), isNull);
      expect(controller.getEquippedUserCardAssetOrNullSync(), isNull);
      expect(repo.equipCalls, hasLength(2));
      expect(repo.fetchCalls, greaterThanOrEqualTo(2));
    });

    test('cloud equip replaces the previous cosmetic in the same slot',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final snapshot = _snapshot(
        userId: 'shop-cloud-user',
        ownedAssetIds: <String>[
          'wallpaper_mist_blue',
          'wallpaper_rutio_beige',
        ],
        wallpaperId: 'wallpaper_mist_blue',
      );
      final repo = _FakeCloudCosmeticsRepository(
        fetchResponses: <_FetchResponseFactory>[
          () async => _success(snapshot),
        ],
      );
      final controller = (await _createController(
        cloudRepository: repo,
        cloudCache: _memoryCache(snapshot),
      ))
          .controller;
      await controller.getState();

      final result = await controller.equipAsset('wallpaper_rutio_beige');

      expect(result.isSuccess, isTrue);
      expect(controller.getEquippedWallpaperAssetOrNullSync()?.id,
          'wallpaper_rutio_beige');
      expect(
          controller.state?.ownedAssetIds,
          containsAll(<String>[
            'wallpaper_mist_blue',
            'wallpaper_rutio_beige',
          ]));
      expect(await controller.getWalletCoins(), 500);
    });

    test(
        'cloud equip survives a stale in-flight fetch without reverting the new slot',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final fetchGate = Completer<void>();
      final snapshot = _snapshot(
        userId: 'shop-cloud-user',
        ownedAssetIds: <String>[
          'wallpaper_mist_blue',
          'wallpaper_soft_sage',
        ],
        wallpaperId: 'wallpaper_mist_blue',
      );
      final updatedSnapshot = _snapshot(
        userId: 'shop-cloud-user',
        ownedAssetIds: <String>[
          'wallpaper_mist_blue',
          'wallpaper_soft_sage',
        ],
        wallpaperId: 'wallpaper_soft_sage',
      );
      final repo = _FakeCloudCosmeticsRepository(
        fetchResponses: <_FetchResponseFactory>[
          () async {
            await fetchGate.future;
            return _success(snapshot);
          },
          () async => _success(updatedSnapshot),
        ],
      );
      final controller = (await _createController(
        cloudRepository: repo,
        cloudCache: _memoryCache(snapshot),
      ))
          .controller;

      final loadFuture = controller.getState();
      await Future<void>.delayed(Duration.zero);

      final result = await controller.equipAsset('wallpaper_soft_sage');
      expect(result.isSuccess, isTrue);
      expect(controller.getEquippedWallpaperAssetOrNullSync()?.id,
          'wallpaper_soft_sage');

      fetchGate.complete();
      await loadFuture;
      await Future<void>.delayed(Duration.zero);

      expect(controller.getEquippedWallpaperAssetOrNullSync()?.id,
          'wallpaper_soft_sage');
      expect(repo.equipCalls.single.slot, CosmeticSlot.background.remoteDbKey);
      expect(repo.equipCalls.single.requestId, isNotEmpty);
    });

    test(
        'cloud equip keeps the confirmed wallpaper when the follow-up refresh fails',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final snapshot = _snapshot(
        userId: 'shop-cloud-user',
        ownedAssetIds: <String>[
          'wallpaper_mist_blue',
          'wallpaper_dusty_lilac',
        ],
        wallpaperId: 'wallpaper_mist_blue',
      );
      final repo = _FakeCloudCosmeticsRepository(
        fetchResponses: <_FetchResponseFactory>[
          () async => _success(snapshot),
          () async => _failure(
                ShopCloudErrorCode.networkUnavailable,
                'refresh failed',
              ),
        ],
      );
      final controller = (await _createController(
        cloudRepository: repo,
        cloudCache: _memoryCache(snapshot),
      ))
          .controller;
      await controller.getState();
      final initialRevision = controller.cloudSnapshotRevision;

      final result = await controller.equipAsset('wallpaper_dusty_lilac');

      expect(result.isSuccess, isTrue);
      expect(controller.getEquippedWallpaperAssetOrNullSync()?.id,
          'wallpaper_dusty_lilac');
      expect(controller.state?.equippedWallpaperId, 'wallpaper_dusty_lilac');
      expect(controller.cloudSnapshotRevision, greaterThan(initialRevision));
      expect(repo.equipCalls.single.requestId, isNotEmpty);
      expect(repo.equipCalls, hasLength(1));
    });

    test('cloud equip maps invalid slot errors to a controlled failure',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final snapshot = _snapshot(
        userId: 'shop-cloud-user',
        ownedAssetIds: <String>['wallpaper_mist_blue'],
      );
      final repo = _FakeCloudCosmeticsRepository(
        fetchResponses: <_FetchResponseFactory>[
          () async => _success(snapshot),
        ],
        equipError: const ShopCloudEquipException(
          code: ShopCosmeticsOperationFailureCode.invalidEquipSlot,
          message: 'Invalid equip slot.',
          definitive: true,
        ),
      );
      final controller = (await _createController(
        cloudRepository: repo,
        cloudCache: _memoryCache(snapshot),
      ))
          .controller;
      await controller.getState();

      final result = await controller.equipAsset('wallpaper_mist_blue');

      expect(result.isSuccess, isFalse);
      expect(result.status, ShopCosmeticsOperationStatus.bundleNotFound);
      expect(controller.getEquippedWallpaperAssetOrNullSync(), isNull);
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
      expect(controller.state?.ownedAssetIds,
          isNot(contains('wallpaper_mist_blue')));
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
      final controller =
          (await _createController(cloudEnabled: false)).controller;

      expect(controller.isCloudEnabled, isFalse);

      final result = await controller.purchaseAsset('wallpaper_mist_blue');
      final persisted = await (await _shopRepository()).load();

      expect(result.isSuccess, isTrue);
      expect(persisted.ownedAssetIds, contains('wallpaper_mist_blue'));
    });
  });
}

Future<_ControllerEnv> _createController({
  CloudCosmeticsRepository? cloudRepository,
  CloudCosmeticsCache? cloudCache,
  bool? cloudEnabled = true,
  GlobalWalletController? globalWalletController,
  String userId = testUserId,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final repo = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope(userId);
  final store = UserStateStore(
    repo,
    journalEntrySyncService: JournalEntrySyncService(),
  );
  await store.save(_baseState(userId: userId, walletCoins: 500));
  await store.load();
  return (
    controller: ShopCosmeticsController(
      userStateStore: store,
      globalWalletController: globalWalletController,
      cloudRepository: cloudRepository,
      cloudCache: cloudCache,
      cloudEnabled: cloudEnabled,
    ),
    store: store,
  );
}

Future<ShopCosmeticsRepository> _shopRepository({
  String userId = testUserId,
}) async {
  final preferences = await SharedPreferences.getInstance();
  return ShopCosmeticsRepository(
    sharedPreferencesProvider: () async => preferences,
    scopeResolver: () => userId,
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
  List<String> ownedBundleIds = const <String>[],
  String? wallpaperId,
  String? habitCardId,
  String? userCardId,
}) {
  final now = DateTime.utc(2026, 7, 19, 12);
  return CloudCosmeticsSnapshot(
    userId: userId,
    ownedAssetIds: ownedAssetIds,
    ownedBundleIds: ownedBundleIds,
    equippedWallpaperId: wallpaperId,
    equippedHabitCardSkinId: habitCardId,
    equippedUserCardSkinId: userCardId,
    catalogVersion: 1,
    fetchedAt: now,
    updatedAt: now,
  );
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
    this.equipError,
  }) : _fetchResponses = fetchResponses;

  final List<_FetchResponseFactory> _fetchResponses;
  final List<String> purchaseCalls = <String>[];
  final List<_EquipCall> equipCalls = <_EquipCall>[];
  final List<Object?> bundleOutcomes = <Object?>[];
  final List<Object?> equipOutcomes = <Object?>[];
  final ShopCloudEquipException? equipError;

  int _fetchIndex = 0;

  @override
  Future<RemoteShopEquipResultDto> equipAsset({
    required String itemId,
    required String slot,
    required String requestId,
  }) async {
    equipCalls.add(_EquipCall(
      itemId: itemId,
      slot: slot,
      requestId: requestId,
    ));
    if (equipOutcomes.isNotEmpty) {
      final outcome = equipOutcomes.removeAt(0);
      if (outcome is ShopCloudEquipException) {
        throw outcome;
      }
      if (outcome is RemoteShopEquipResultDto) {
        return outcome;
      }
    }
    if (equipError != null) {
      throw equipError!;
    }
    return RemoteShopEquipResultDto(
      requestId: requestId,
      operation: 'equip',
      itemId: itemId,
      slot: slot,
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

  int get fetchCalls => _fetchIndex;

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

  @override
  Future<RemoteShopBundlePurchaseResultDto> purchaseBundle({
    required String bundleId,
    required String requestId,
  }) async {
    purchaseCalls.add(bundleId);
    final bundle = ShopAssetsCatalog.getBundleById(bundleId)!;
    if (bundleOutcomes.isNotEmpty) {
      final outcome = bundleOutcomes.removeAt(0);
      if (outcome is ShopCloudPurchaseException) {
        throw outcome;
      }
      if (outcome is RemoteShopBundlePurchaseResultDto) {
        return outcome;
      }
    }
    return RemoteShopBundlePurchaseResultDto(
      requestId: requestId,
      bundleId: bundleId,
      userId: 'shop-cloud-user',
      coinsDelta: -bundle.priceAmber,
      walletCoinsAfter: 500 - bundle.priceAmber,
      wallpaperItemId: bundle.wallpaperItemId,
      habitCardItemId: bundle.habitCardItemId,
      userCardItemId: bundle.userCardItemId,
      isIdempotent: false,
      createdAt: DateTime.utc(2026, 7, 19, 12),
    );
  }
}

class _FakeCloudWalletRepository implements CloudWalletRepository {
  final List<Future<WalletReadResult<CloudWalletSnapshot>>> _responses =
      <Future<WalletReadResult<CloudWalletSnapshot>>>[];

  int calls = 0;

  void enqueueSuccess(CloudWalletSnapshot snapshot) {
    _responses.add(
      Future<WalletReadResult<CloudWalletSnapshot>>.value(
        WalletReadResult<CloudWalletSnapshot>.success(data: snapshot),
      ),
    );
  }

  @override
  Future<WalletReadResult<CloudWalletSnapshot>> fetchWallet() {
    calls += 1;
    if (_responses.isEmpty) {
      throw StateError('No queued wallet response.');
    }
    return _responses.removeAt(0);
  }
}

class _MemoryWalletCache implements WalletCache {
  final Map<String, WalletCacheEntry> _entries = <String, WalletCacheEntry>{};

  @override
  Future<WalletCacheEntry?> read(String userId) async => _entries[userId];

  @override
  Future<WalletCacheEntry?> save(CloudWalletSnapshot snapshot) async {
    final next = WalletCacheEntry.fromSnapshot(
      snapshot,
      cachedAt: DateTime.now().toUtc(),
    );
    _entries[snapshot.userId] = next;
    return next;
  }

  @override
  Future<void> clearForUser(String userId) async {
    _entries.remove(userId);
  }
}

CloudWalletSnapshot _walletSnapshot({
  required String userId,
  required int coins,
  required int version,
  required DateTime updatedAt,
}) {
  return CloudWalletSnapshot(
    userId: userId,
    coins: coins,
    version: version,
    createdAt: updatedAt,
    updatedAt: updatedAt,
    fetchedAt: updatedAt,
  );
}

class _EquipCall {
  const _EquipCall({
    required this.itemId,
    required this.slot,
    required this.requestId,
  });

  final String itemId;
  final String slot;
  final String requestId;
}
