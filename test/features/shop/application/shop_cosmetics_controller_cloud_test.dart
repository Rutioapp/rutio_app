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
import 'package:rutio/features/shop/data/cloud/shop_cloud_dtos.dart';
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
import 'package:rutio/features/shop/domain/models/pending_cloud_cosmetics_purchase.dart';
import 'package:rutio/features/shop/domain/models/shop_asset_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_operation_result.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_state.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/domain/pending_cloud_cosmetics_purchase_store.dart';
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

    test('failed cloud fetch keeps the resolved catalog empty', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
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
      );
      final controller = env.controller;

      await controller.getState();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(controller.resolvedAssets, isEmpty);
      expect(controller.resolvedBundles, isEmpty);
      expect(controller.cloudState.status, ShopCosmeticsCloudStatus.failed);
    });

    test('cloud purchase rejects when the remote catalog is empty', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final emptyCatalogSnapshot = _snapshot(
        userId: 'shop-cloud-user',
        ownedAssetIds: const <String>[],
        catalogItems: const <RemoteShopItemDto>[],
        catalogBundles: const <RemoteShopBundleDto>[],
        catalogBundleItems: const <RemoteShopBundleItemDto>[],
      );
      final repo = _FakeCloudCosmeticsRepository(
        fetchResponses: <_FetchResponseFactory>[
          () async => _success(emptyCatalogSnapshot),
        ],
      );
      final controller = (await _createController(
        cloudRepository: repo,
        cloudCache: _memoryCache(emptyCatalogSnapshot),
      ))
          .controller;
      await controller.getState();

      final result = await controller.purchaseBundle('pack_beige_rutio');

      expect(result.status, ShopCosmeticsOperationStatus.bundleNotFound);
      expect(repo.purchaseCalls, isEmpty);
    });

    test('cloud equipBundle rejects when the bundle is absent remotely',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final emptyCatalogSnapshot = _snapshot(
        userId: 'shop-cloud-user',
        ownedAssetIds: <String>[
          'wallpaper_rutio_beige',
          'habit_card_warm_beige',
          'user_card_warm_beige',
        ],
        ownedBundleIds: const <String>[],
        catalogItems: const <RemoteShopItemDto>[],
        catalogBundles: const <RemoteShopBundleDto>[],
        catalogBundleItems: const <RemoteShopBundleItemDto>[],
      );
      final repo = _FakeCloudCosmeticsRepository(
        fetchResponses: <_FetchResponseFactory>[
          () async => _success(emptyCatalogSnapshot),
        ],
      );
      final controller = (await _createController(
        cloudRepository: repo,
        cloudCache: _memoryCache(emptyCatalogSnapshot),
      ))
          .controller;
      await controller.getState();

      final result = await controller.equipBundle('pack_beige_rutio');

      expect(result.status, ShopCosmeticsOperationStatus.bundleNotFound);
      expect(repo.equipCalls, isEmpty);
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

    test('cloud asset purchase saves pending before invoking repository',
        () async {
      final pendingStore = _MemoryPendingCloudCosmeticsPurchaseStore();
      final initialSnapshot = _snapshot(
        userId: 'shop-cloud-user',
        ownedAssetIds: const <String>[],
      );
      final repo = _FakeCloudCosmeticsRepository(
        fetchResponses: <_FetchResponseFactory>[
          () async => _success(initialSnapshot),
        ],
      );
      final env = await _createController(
        cloudRepository: repo,
        cloudCache: _memoryCache(initialSnapshot),
        pendingPurchaseStore: pendingStore,
        requestIdGenerator: () => 'asset-request-1',
      );

      await env.controller.purchaseAsset('wallpaper_mist_blue');

      expect(repo.purchaseCallRecords.single.requestId, 'asset-request-1');
      expect(pendingStore.saveLog.first.single.requestId, 'asset-request-1');
      expect(
          await pendingStore.loadPendingPurchases('shop-cloud-user'), isEmpty);
    });

    test('asset purchase timeout keeps pending and retry reuses requestId',
        () async {
      final pendingStore = _MemoryPendingCloudCosmeticsPurchaseStore();
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
                  ownedAssetIds: const <String>[],
                ),
              ),
        ],
      );
      repo.assetOutcomes.add(
        const ShopCloudPurchaseException(
          code: ShopPurchaseFailureCode.timeout,
          message: 'timeout',
          retryable: true,
        ),
      );
      final env = await _createController(
        cloudRepository: repo,
        pendingPurchaseStore: pendingStore,
        requestIdGenerator: () => 'asset-request-1',
      );

      final first = await env.controller.purchaseAsset('wallpaper_mist_blue');
      final pending =
          await pendingStore.loadPendingPurchases('shop-cloud-user');
      repo.assetOutcomes.add(
        RemoteShopPurchaseResultDto(
          requestId: 'asset-request-1',
          operation: 'purchase',
          itemId: 'wallpaper_mist_blue',
          priceCoins: 120,
          coins: 380,
          walletVersion: 2,
          inventoryQuantity: 1,
        ),
      );
      final second = await env.controller.purchaseAsset('wallpaper_mist_blue');

      expect(first.status, ShopCosmeticsOperationStatus.awaitingResolution);
      expect(pending.single.requestId, 'asset-request-1');
      expect(pending.single.status,
          PendingCloudCosmeticsPurchaseStatus.awaitingResolution);
      expect(second.status, ShopCosmeticsOperationStatus.success);
      expect(repo.purchaseCallRecords.map((call) => call.requestId),
          <String>['asset-request-1', 'asset-request-1']);
      expect(
          await pendingStore.loadPendingPurchases('shop-cloud-user'), isEmpty);
    });

    test('asset already owned after refresh resolves pending as success',
        () async {
      final pendingStore = _MemoryPendingCloudCosmeticsPurchaseStore();
      await pendingStore.savePendingPurchases(
        'shop-cloud-user',
        <PendingCloudCosmeticsPurchase>[
          _pendingCloudPurchase(
            requestId: 'asset-request-1',
            resourceId: 'wallpaper_mist_blue',
          ),
        ],
      );
      final initialSnapshot = _snapshot(
        userId: 'shop-cloud-user',
        ownedAssetIds: const <String>[],
      );
      final repo = _FakeCloudCosmeticsRepository(
        fetchResponses: <_FetchResponseFactory>[
          () async => _success(initialSnapshot),
          () async => _success(
                _snapshot(
                  userId: 'shop-cloud-user',
                  ownedAssetIds: <String>['wallpaper_mist_blue'],
                ),
              ),
        ],
      );
      repo.assetOutcomes.add(
        const ShopCloudPurchaseException(
          code: ShopPurchaseFailureCode.itemAlreadyOwned,
          message: 'item already owned',
          definitive: true,
        ),
      );
      final env = await _createController(
        cloudRepository: repo,
        cloudCache: _memoryCache(initialSnapshot),
        pendingPurchaseStore: pendingStore,
        requestIdGenerator: () => 'new-request',
      );
      await env.controller.getState();
      await env.controller.refreshCloudState(force: true);

      final result = await env.controller.purchaseAsset('wallpaper_mist_blue');

      expect(result.status, ShopCosmeticsOperationStatus.success);
      expect(result.state.ownedAssetIds, contains('wallpaper_mist_blue'));
      expect(repo.purchaseCallRecords, isEmpty);
      expect(
          await pendingStore.loadPendingPurchases('shop-cloud-user'), isEmpty);
    });

    test('double tap on asset shares one requestId', () async {
      final gate = Completer<void>();
      final pendingStore = _MemoryPendingCloudCosmeticsPurchaseStore();
      final initialSnapshot = _snapshot(
        userId: 'shop-cloud-user',
        ownedAssetIds: const <String>[],
      );
      final repo = _FakeCloudCosmeticsRepository(
        fetchResponses: <_FetchResponseFactory>[
          () async => _success(initialSnapshot),
        ],
      )..assetGate = gate.future;
      final env = await _createController(
        cloudRepository: repo,
        cloudCache: _memoryCache(initialSnapshot),
        pendingPurchaseStore: pendingStore,
        requestIdGenerator: () => 'asset-request-1',
      );

      final first = env.controller.purchaseAsset('wallpaper_mist_blue');
      final second = env.controller.purchaseAsset('wallpaper_mist_blue');
      await Future<void>.delayed(Duration.zero);
      gate.complete();
      await Future.wait(<Future<ShopCosmeticsOperationResult>>[first, second]);

      expect(repo.purchaseCallRecords, hasLength(1));
      expect(repo.purchaseCallRecords.single.requestId, 'asset-request-1');
    });

    test('bundle purchase timeout keeps pending and retry reuses requestId',
        () async {
      final pendingStore = _MemoryPendingCloudCosmeticsPurchaseStore();
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
                  ownedAssetIds: const <String>[],
                ),
              ),
        ],
      );
      repo.bundleOutcomes.add(
        const ShopCloudPurchaseException(
          code: ShopPurchaseFailureCode.timeout,
          message: 'timeout',
          retryable: true,
        ),
      );
      repo.bundleOutcomes.add(
        RemoteShopBundlePurchaseResultDto(
          requestId: 'bundle-request-1',
          bundleId: 'pack_blanco_roto',
          userId: 'shop-cloud-user',
          coinsDelta: -325,
          walletCoinsAfter: 175,
          wallpaperItemId: 'wallpaper_off_white',
          habitCardItemId: 'habit_card_sand_plain',
          userCardItemId: 'user_card_sand_plain',
          isIdempotent: true,
          createdAt: DateTime.utc(2026, 7, 19, 12),
        ),
      );
      final env = await _createController(
        cloudRepository: repo,
        pendingPurchaseStore: pendingStore,
        requestIdGenerator: () => 'bundle-request-1',
      );

      final first = await env.controller.purchaseBundle('pack_blanco_roto');
      final second = await env.controller.purchaseBundle('pack_blanco_roto');

      expect(first.status, ShopCosmeticsOperationStatus.awaitingResolution);
      expect(second.status, ShopCosmeticsOperationStatus.success);
      expect(repo.purchaseCallRecords.map((call) => call.requestId),
          <String>['bundle-request-1', 'bundle-request-1']);
      expect(second.state.ownedBundleIds, contains('pack_blanco_roto'));
      expect(second.walletCoins, 175);
      expect(
          await pendingStore.loadPendingPurchases('shop-cloud-user'), isEmpty);
    });

    test('bundle pending does not block a different asset purchase', () async {
      final pendingStore = _MemoryPendingCloudCosmeticsPurchaseStore();
      await pendingStore.savePendingPurchases(
        'shop-cloud-user',
        <PendingCloudCosmeticsPurchase>[
          _pendingCloudPurchase(
            requestId: 'bundle-request-1',
            operationType: PendingCloudCosmeticsPurchaseType.bundlePurchase,
            resourceId: 'pack_blanco_roto',
          ),
        ],
      );
      final initialSnapshot = _snapshot(
        userId: 'shop-cloud-user',
        ownedAssetIds: const <String>[],
      );
      final repo = _FakeCloudCosmeticsRepository(
        fetchResponses: <_FetchResponseFactory>[
          () async => _success(initialSnapshot),
        ],
      );
      final env = await _createController(
        cloudRepository: repo,
        cloudCache: _memoryCache(initialSnapshot),
        pendingPurchaseStore: pendingStore,
        requestIdGenerator: () => 'asset-request-1',
      );

      final result = await env.controller.purchaseAsset('wallpaper_mist_blue');

      expect(result.status, ShopCosmeticsOperationStatus.success);
      expect(repo.purchaseCallRecords.single.resourceId, 'wallpaper_mist_blue');
      final pending =
          await pendingStore.loadPendingPurchases('shop-cloud-user');
      expect(pending.single.logicalKey, 'bundle:pack_blanco_roto');
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
      const bundleId = 'pack_beige_rutio';
      final bundleAssetIds = <String>{
        'wallpaper_rutio_beige',
        'habit_card_warm_beige',
        'user_card_warm_beige',
      };
      final repo = _FakeCloudCosmeticsRepository(
        fetchResponses: <_FetchResponseFactory>[
          () async => _success(
                _snapshot(
                  userId: 'shop-cloud-user',
                  ownedAssetIds: <String>['wallpaper_rutio_beige'],
                  catalogItems: _catalogItems()
                      .where((item) => bundleAssetIds.contains(item.id))
                      .toList(growable: false),
                  catalogBundles: _catalogBundles()
                      .where((bundle) => bundle.id == bundleId)
                      .toList(growable: false),
                  catalogBundleItems: _catalogBundleItems()
                      .where((item) => item.bundleId == bundleId)
                      .toList(growable: false),
                ),
              ),
          () async => _success(
                _snapshot(
                  userId: 'shop-cloud-user',
                  ownedAssetIds: <String>['wallpaper_rutio_beige'],
                  catalogItems: _catalogItems()
                      .where((item) => bundleAssetIds.contains(item.id))
                      .toList(growable: false),
                  catalogBundles: _catalogBundles()
                      .where((bundle) => bundle.id == bundleId)
                      .toList(growable: false),
                  catalogBundleItems: _catalogBundleItems()
                      .where((item) => item.bundleId == bundleId)
                      .toList(growable: false),
                ),
              ),
          () async => _success(
                _snapshot(
                  userId: 'shop-cloud-user',
                  ownedAssetIds: <String>['wallpaper_rutio_beige'],
                  catalogItems: _catalogItems()
                      .where((item) => bundleAssetIds.contains(item.id))
                      .toList(growable: false),
                  catalogBundles: _catalogBundles()
                      .where((bundle) => bundle.id == bundleId)
                      .toList(growable: false),
                  catalogBundleItems: _catalogBundleItems()
                      .where((item) => item.bundleId == bundleId)
                      .toList(growable: false),
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
      for (var attempt = 0;
          attempt < 50 && env.controller.resolvedBundles.isEmpty;
          attempt += 1) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      expect(env.controller.resolvedBundles, isNotEmpty);
      final initialRevision = env.controller.cloudSnapshotRevision;

      final result = await env.controller.purchaseBundle(bundleId);
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
      expect(repo.purchaseCalls, contains(bundleId));
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

    test('cloud equip double tap on the same item shares one requestId',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final gate = Completer<void>();
      final snapshot = _snapshot(
        userId: 'shop-cloud-user',
        ownedAssetIds: <String>['wallpaper_mist_blue'],
      );
      final repo = _FakeCloudCosmeticsRepository(
        fetchResponses: <_FetchResponseFactory>[
          () async => _success(snapshot),
        ],
      )..equipGate = gate.future;
      final controller = (await _createController(
        cloudRepository: repo,
        cloudCache: _memoryCache(snapshot),
        requestIdGenerator: () => 'equip-request-1',
      ))
          .controller;
      await controller.getState();

      final first = controller.equipAsset('wallpaper_mist_blue');
      final second = controller.equipAsset('wallpaper_mist_blue');
      await Future<void>.delayed(Duration.zero);
      gate.complete();
      final results = await Future.wait(<Future<ShopCosmeticsOperationResult>>[
        first,
        second,
      ]);

      expect(results.every((result) => result.isSuccess), isTrue);
      expect(repo.equipCalls, hasLength(1));
      expect(repo.equipCalls.single.requestId, 'equip-request-1');
    });

    test('cloud equip blocks concurrent incompatible items in the same slot',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final gate = Completer<void>();
      final snapshot = _snapshot(
        userId: 'shop-cloud-user',
        ownedAssetIds: <String>[
          'wallpaper_mist_blue',
          'wallpaper_soft_sage',
        ],
      );
      final repo = _FakeCloudCosmeticsRepository(
        fetchResponses: <_FetchResponseFactory>[
          () async => _success(snapshot),
        ],
      )..equipGate = gate.future;
      var requestIndex = 0;
      final controller = (await _createController(
        cloudRepository: repo,
        cloudCache: _memoryCache(snapshot),
        requestIdGenerator: () => 'equip-request-${++requestIndex}',
      ))
          .controller;
      await controller.getState();

      final first = controller.equipAsset('wallpaper_mist_blue');
      await Future<void>.delayed(Duration.zero);
      final second = await controller.equipAsset('wallpaper_soft_sage');
      gate.complete();
      final firstResult = await first;

      expect(firstResult.isSuccess, isTrue);
      expect(second.status, ShopCosmeticsOperationStatus.awaitingResolution);
      expect(repo.equipCalls, hasLength(1));
      expect(repo.equipCalls.single.itemId, 'wallpaper_mist_blue');
      expect(repo.equipCalls.single.requestId, 'equip-request-1');
    });

    test('cloud equip allows different slots to run concurrently', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final gate = Completer<void>();
      final snapshot = _snapshot(
        userId: 'shop-cloud-user',
        ownedAssetIds: <String>[
          'wallpaper_mist_blue',
          'habit_card_warm_beige',
        ],
      );
      final repo = _FakeCloudCosmeticsRepository(
        fetchResponses: <_FetchResponseFactory>[
          () async => _success(snapshot),
        ],
      )..equipGate = gate.future;
      var requestIndex = 0;
      final controller = (await _createController(
        cloudRepository: repo,
        cloudCache: _memoryCache(snapshot),
        requestIdGenerator: () => 'equip-request-${++requestIndex}',
      ))
          .controller;
      await controller.getState();

      final wallpaper = controller.equipAsset('wallpaper_mist_blue');
      final habitCard = controller.equipAsset('habit_card_warm_beige');
      await Future<void>.delayed(Duration.zero);
      gate.complete();
      final results = await Future.wait(<Future<ShopCosmeticsOperationResult>>[
        wallpaper,
        habitCard,
      ]);

      expect(results.every((result) => result.isSuccess), isTrue);
      expect(repo.equipCalls, hasLength(2));
      expect(
        repo.equipCalls.map((call) => call.slot).toSet(),
        <String>{
          CosmeticSlot.background.remoteDbKey,
          CosmeticSlot.habitCard.remoteDbKey,
        },
      );
    });

    test('cloud equip timeout reconciles when refresh confirms requested item',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final snapshot = _snapshot(
        userId: 'shop-cloud-user',
        ownedAssetIds: <String>['wallpaper_mist_blue'],
      );
      final repo = _FakeCloudCosmeticsRepository(
        fetchResponses: <_FetchResponseFactory>[
          () async => _success(snapshot),
          () async => _success(
                _snapshot(
                  userId: 'shop-cloud-user',
                  ownedAssetIds: <String>['wallpaper_mist_blue'],
                  wallpaperId: 'wallpaper_mist_blue',
                ),
              ),
          () async => _success(
                _snapshot(
                  userId: 'shop-cloud-user',
                  ownedAssetIds: <String>['wallpaper_mist_blue'],
                  wallpaperId: 'wallpaper_mist_blue',
                ),
              ),
        ],
      );
      repo.equipOutcomes.add(
        const ShopCloudEquipException(
          code: ShopCosmeticsOperationFailureCode.timeout,
          message: 'timeout',
          retryable: true,
        ),
      );
      final controller = (await _createController(
        cloudRepository: repo,
        cloudCache: _memoryCache(snapshot),
        requestIdGenerator: () => 'equip-request-1',
      ))
          .controller;
      await controller.getState();

      final result = await controller.equipAsset('wallpaper_mist_blue');

      expect(result.status, ShopCosmeticsOperationStatus.success);
      expect(controller.state?.equippedWallpaperId, 'wallpaper_mist_blue');
      expect(repo.equipCalls.single.requestId, 'equip-request-1');
      expect(repo.fetchCalls, greaterThanOrEqualTo(2));
    });

    test('cloud equip timeout applies remote truth when another item wins',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final snapshot = _snapshot(
        userId: 'shop-cloud-user',
        ownedAssetIds: <String>[
          'wallpaper_mist_blue',
          'wallpaper_soft_sage',
        ],
        wallpaperId: 'wallpaper_soft_sage',
      );
      final repo = _FakeCloudCosmeticsRepository(
        fetchResponses: <_FetchResponseFactory>[
          () async => _success(snapshot),
          () async => _success(
                _snapshot(
                  userId: 'shop-cloud-user',
                  ownedAssetIds: <String>[
                    'wallpaper_mist_blue',
                    'wallpaper_soft_sage',
                  ],
                  wallpaperId: 'wallpaper_soft_sage',
                ),
              ),
          () async => _success(
                _snapshot(
                  userId: 'shop-cloud-user',
                  ownedAssetIds: <String>[
                    'wallpaper_mist_blue',
                    'wallpaper_soft_sage',
                  ],
                  wallpaperId: 'wallpaper_soft_sage',
                ),
              ),
        ],
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

      final result = await controller.equipAsset('wallpaper_mist_blue');

      expect(result.status, ShopCosmeticsOperationStatus.remoteStateApplied);
      expect(controller.state?.equippedWallpaperId, 'wallpaper_soft_sage');
      expect(
          controller.isCloudAssetEquipSlotBusy('wallpaper_mist_blue'), isFalse);
    });

    test('cloud equip timeout keeps confirmed state when refresh fails',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final snapshot = _snapshot(
        userId: 'shop-cloud-user',
        ownedAssetIds: <String>[
          'wallpaper_mist_blue',
          'wallpaper_soft_sage',
        ],
        wallpaperId: 'wallpaper_soft_sage',
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
      repo.equipOutcomes.add(
        const ShopCloudEquipException(
          code: ShopCosmeticsOperationFailureCode.timeout,
          message: 'timeout',
          retryable: true,
        ),
      );
      final controller = (await _createController(
        cloudRepository: repo,
        cloudCache: _memoryCache(snapshot),
      ))
          .controller;
      await controller.getState();

      final result = await controller.equipAsset('wallpaper_mist_blue');

      expect(result.status, ShopCosmeticsOperationStatus.awaitingResolution);
      expect(controller.state?.equippedWallpaperId, 'wallpaper_soft_sage');
      expect(
          controller.isCloudAssetEquipSlotBusy('wallpaper_mist_blue'), isFalse);
    });

    test('cloud equip can resolve on a later refresh after ambiguous failure',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final snapshot = _snapshot(
        userId: 'shop-cloud-user',
        ownedAssetIds: <String>['wallpaper_mist_blue'],
      );
      final repo = _FakeCloudCosmeticsRepository(
        fetchResponses: <_FetchResponseFactory>[
          () async => _success(snapshot),
          () async => _failure(
                ShopCloudErrorCode.networkUnavailable,
                'refresh failed',
              ),
          () async => _success(
                _snapshot(
                  userId: 'shop-cloud-user',
                  ownedAssetIds: <String>['wallpaper_mist_blue'],
                  wallpaperId: 'wallpaper_mist_blue',
                ),
              ),
        ],
      );
      repo.equipOutcomes.add(
        const ShopCloudEquipException(
          code: ShopCosmeticsOperationFailureCode.timeout,
          message: 'timeout',
          retryable: true,
        ),
      );
      final controller = (await _createController(
        cloudRepository: repo,
        cloudCache: _memoryCache(snapshot),
      ))
          .controller;
      await controller.getState();

      final ambiguous = await controller.equipAsset('wallpaper_mist_blue');
      final refreshed = await controller.refreshCloudState(force: true);

      expect(ambiguous.status, ShopCosmeticsOperationStatus.awaitingResolution);
      expect(refreshed.equippedWallpaperId, 'wallpaper_mist_blue');
      expect(controller.state?.equippedWallpaperId, 'wallpaper_mist_blue');
    });

    test('cloud equip ignores a late response after user changes', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final gate = Completer<void>();
      final repo = _FakeCloudCosmeticsRepository(
        fetchResponses: <_FetchResponseFactory>[
          () async => _success(
                _snapshot(
                  userId: 'shop-cloud-user',
                  ownedAssetIds: <String>['wallpaper_mist_blue'],
                ),
              ),
          () async => _success(
                _snapshot(
                  userId: 'shop-cloud-user',
                  ownedAssetIds: <String>['wallpaper_mist_blue'],
                ),
              ),
          () async => _success(
                _snapshot(
                  userId: 'shop-cosmetics-user-b',
                  ownedAssetIds: <String>['wallpaper_soft_sage'],
                  wallpaperId: 'wallpaper_soft_sage',
                ),
              ),
        ],
      )..equipGate = gate.future;
      final env = await _createController(
        cloudRepository: repo,
        cloudCache: _memoryCache(
          _snapshot(
            userId: 'shop-cloud-user',
            ownedAssetIds: <String>['wallpaper_mist_blue'],
          ),
        ),
      );
      await env.controller.getState();

      final equip = env.controller.equipAsset('wallpaper_mist_blue');
      await Future<void>.delayed(Duration.zero);
      await _switchScope(env.store, userId: 'shop-cosmetics-user-b');
      gate.complete();
      await equip;
      await Future<void>.delayed(Duration.zero);

      expect(env.controller.state?.equippedWallpaperId,
          isNot('wallpaper_mist_blue'));
      expect(repo.equipCalls, hasLength(1));
    });

    test('cloud equip dispose during RPC does not notify afterwards', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final gate = Completer<void>();
      final snapshot = _snapshot(
        userId: 'shop-cloud-user',
        ownedAssetIds: <String>['wallpaper_mist_blue'],
      );
      final repo = _FakeCloudCosmeticsRepository(
        fetchResponses: <_FetchResponseFactory>[
          () async => _success(snapshot),
        ],
      )..equipGate = gate.future;
      final controller = (await _createController(
        cloudRepository: repo,
        cloudCache: _memoryCache(snapshot),
      ))
          .controller;
      await controller.getState();
      var notifyCount = 0;
      controller.addListener(() {
        notifyCount += 1;
      });

      final equip = controller.equipAsset('wallpaper_mist_blue');
      await Future<void>.delayed(Duration.zero);
      final beforeDisposeNotifyCount = notifyCount;
      controller.dispose();
      gate.complete();
      await equip;

      expect(notifyCount, beforeDisposeNotifyCount);
      expect(repo.equipCalls, hasLength(1));
    });

    test('cloud equip definitive error clears slot operation', () async {
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
      final retry = await controller.equipAsset('wallpaper_mist_blue');

      expect(result.status, ShopCosmeticsOperationStatus.bundleNotFound);
      expect(retry.status, ShopCosmeticsOperationStatus.bundleNotFound);
      expect(repo.equipCalls, hasLength(2));
      expect(
          controller.isCloudAssetEquipSlotBusy('wallpaper_mist_blue'), isFalse);
    });

    test(
        'cloud equipBundle performs only missing slot RPC calls with unique ids',
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
      expect(repo.equipCalls.length, greaterThanOrEqualTo(2));
      expect(repo.equipCalls.length, lessThanOrEqualTo(3));
      expect(
        repo.equipCalls.map((call) => call.slot).toSet(),
        containsAll(<String>[
          CosmeticSlot.habitCard.remoteDbKey,
          CosmeticSlot.userCard.remoteDbKey,
        ]),
      );
      expect(
        repo.equipCalls.map((call) => call.requestId).toSet().length,
        repo.equipCalls.length,
      );
      expect(controller.getEquippedWallpaperAssetOrNullSync()?.id,
          'wallpaper_rutio_beige');
      expect(controller.getEquippedHabitCardAssetOrNullSync()?.id,
          'habit_card_warm_beige');
      expect(controller.getEquippedUserCardAssetOrNullSync()?.id,
          'user_card_warm_beige');
      expect(repo.fetchCalls, greaterThanOrEqualTo(2));
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

      var notifications = 0;
      controller.addListener(() {
        notifications += 1;
      });

      notifications = 0;
      await _switchScope(env.store, userId: 'shop-cosmetics-user-b');
      fetchGate.complete();
      await firstLoad;
      await Future<void>.delayed(Duration.zero);

      expect(notifications, greaterThan(0));
      expect(controller.cloudState.userId, 'shop-cosmetics-user-b');
      expect(controller.state?.ownedAssetIds,
          isNot(contains('wallpaper_mist_blue')));
    });

    test('guest getState returns initial state without synchronous notify',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final snapshot = _snapshot(
        userId: testUserId,
        ownedAssetIds: <String>['wallpaper_mist_blue'],
        wallpaperId: 'wallpaper_mist_blue',
      );
      final repo = _FakeCloudCosmeticsRepository(
        fetchResponses: <_FetchResponseFactory>[
          () async => _success(snapshot),
        ],
      );
      final store = _MutableScopeUserStateStore(initialScope: testUserId);
      final controller = ShopCosmeticsController(
        userStateStore: store,
        cloudRepository: repo,
        cloudCache: _memoryCache(snapshot),
        cloudEnabled: true,
      );

      await controller.getState();
      expect(controller.state, isNotNull);
      expect(controller.getEquippedWallpaperAssetOrNullSync()?.id,
          'wallpaper_mist_blue');

      var notifications = 0;
      controller.addListener(() {
        notifications += 1;
      });

      store.setTestScope(null);
      notifications = 0;

      final stateFuture = controller.getState();
      expect(notifications, 0);
      final state = await stateFuture;

      expect(state, const ShopCosmeticsState.initial());
      expect(controller.state, isNull);
      expect(controller.hasStateForCurrentScope, isFalse);
      expect(controller.cloudState.status,
          ShopCosmeticsCloudStatus.unauthenticated);
      expect(notifications, 0);
    });

    test('logout clears the in-memory cloud state', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final snapshot = _snapshot(
        userId: testUserId,
        ownedAssetIds: <String>['wallpaper_mist_blue'],
      );
      final repo = _FakeCloudCosmeticsRepository(
        fetchResponses: <_FetchResponseFactory>[
          () async => _success(snapshot),
        ],
      );
      final store = _MutableScopeUserStateStore(initialScope: testUserId);
      final controller = ShopCosmeticsController(
        userStateStore: store,
        cloudRepository: repo,
        cloudCache: _memoryCache(snapshot),
        cloudEnabled: true,
      );

      await controller.getState();
      expect(controller.state, isNotNull);

      var notifications = 0;
      controller.addListener(() {
        notifications += 1;
      });
      notifications = 0;
      store.setTestScope(null, notify: true);
      expect(notifications, greaterThan(0));
      expect(controller.state, isNull);
      expect(controller.cloudState.status,
          ShopCosmeticsCloudStatus.unauthenticated);
    });

    test('login from guest loads cloud cosmetics', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final repo = _FakeCloudCosmeticsRepository(
        fetchResponses: <_FetchResponseFactory>[
          () async => _success(
                _snapshot(
                  userId: testUserId,
                  ownedAssetIds: <String>['wallpaper_mist_blue'],
                  wallpaperId: 'wallpaper_mist_blue',
                ),
              ),
          () async => _success(
                _snapshot(
                  userId: testUserId,
                  ownedAssetIds: <String>['wallpaper_mist_blue'],
                  wallpaperId: 'wallpaper_mist_blue',
                ),
              ),
        ],
      );
      final store = _MutableScopeUserStateStore(initialScope: null);
      final controller = ShopCosmeticsController(
        userStateStore: store,
        cloudRepository: repo,
        cloudCache: _emptyMemoryCache(),
        cloudEnabled: true,
      );

      store.setTestScope(testUserId, notify: true);
      final state = await controller.getState();

      expect(repo.fetchCalls, greaterThanOrEqualTo(1));
      expect(state.equippedWallpaperId, 'wallpaper_mist_blue');
      expect(controller.getEquippedWallpaperAssetOrNullSync()?.id,
          'wallpaper_mist_blue');
    });

    test('logout invalidates cosmetic scope', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final snapshot = _snapshot(
        userId: testUserId,
        ownedAssetIds: <String>['wallpaper_mist_blue'],
        wallpaperId: 'wallpaper_mist_blue',
      );
      final store = _MutableScopeUserStateStore(initialScope: testUserId);
      final controller = ShopCosmeticsController(
        userStateStore: store,
        cloudRepository: _FakeCloudCosmeticsRepository(
          fetchResponses: <_FetchResponseFactory>[
            () async => _success(snapshot),
            () async => _success(snapshot),
          ],
        ),
        cloudCache: _memoryCache(snapshot),
        cloudEnabled: true,
      );
      await controller.getState();

      store.setTestScope(null, notify: true);

      expect(controller.state, isNull);
      expect(controller.getEquippedWallpaperAssetOrNullSync(), isNull);
      expect(controller.cloudState.status,
          ShopCosmeticsCloudStatus.unauthenticated);
    });

    test('login with same account after logout reloads cloud cosmetics',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final first = _snapshot(
        userId: testUserId,
        ownedAssetIds: <String>['wallpaper_mist_blue'],
        wallpaperId: 'wallpaper_mist_blue',
      );
      final second = _snapshot(
        userId: testUserId,
        ownedAssetIds: <String>['habit_card_soft_sage'],
        habitCardId: 'habit_card_soft_sage',
      );
      final repo = _FakeCloudCosmeticsRepository(
        fetchResponses: <_FetchResponseFactory>[
          () async => _success(first),
          () async => _success(second),
          () async => _success(second),
        ],
      );
      final store = _MutableScopeUserStateStore(initialScope: testUserId);
      final controller = ShopCosmeticsController(
        userStateStore: store,
        cloudRepository: repo,
        cloudCache: _memoryCache(first),
        cloudEnabled: true,
      );
      await controller.getState();

      store.setTestScope(null, notify: true);
      store.setTestScope(testUserId, notify: true);
      final reloaded = await controller.getState();

      expect(repo.fetchCalls, greaterThanOrEqualTo(2));
      expect(reloaded.equippedHabitCardSkinId, 'habit_card_soft_sage');
      expect(controller.getEquippedHabitCardAssetOrNullSync()?.id,
          'habit_card_soft_sage');
    });

    test('login with another account discards previous snapshot', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final userA = _snapshot(
        userId: 'shop-cosmetics-user-a',
        ownedAssetIds: <String>['wallpaper_mist_blue'],
        wallpaperId: 'wallpaper_mist_blue',
      );
      final userB = _snapshot(
        userId: 'shop-cosmetics-user-b',
        ownedAssetIds: <String>['user_card_full_moon'],
        userCardId: 'user_card_full_moon',
      );
      final repo = _FakeCloudCosmeticsRepository(
        fetchResponses: <_FetchResponseFactory>[
          () async => _success(userA),
          () async => _success(userB),
          () async => _success(userB),
        ],
      );
      final store =
          _MutableScopeUserStateStore(initialScope: 'shop-cosmetics-user-a');
      final controller = ShopCosmeticsController(
        userStateStore: store,
        cloudRepository: repo,
        cloudCache: _memoryCacheAll(<CloudCosmeticsSnapshot>[userA, userB]),
        cloudEnabled: true,
      );
      await controller.getState();

      store.setTestScope('shop-cosmetics-user-b', notify: true);
      final state = await controller.getState();

      expect(state.ownedAssetIds, isNot(contains('wallpaper_mist_blue')));
      expect(controller.getEquippedUserCardAssetOrNullSync()?.id,
          'user_card_full_moon');
    });

    test('old cloud result does not overwrite new scope', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final gate = Completer<void>();
      final userA = _snapshot(
        userId: 'shop-cosmetics-user-a',
        ownedAssetIds: <String>['wallpaper_mist_blue'],
        wallpaperId: 'wallpaper_mist_blue',
      );
      final userB = _snapshot(
        userId: 'shop-cosmetics-user-b',
        ownedAssetIds: <String>['user_card_full_moon'],
        userCardId: 'user_card_full_moon',
      );
      final repo = _FakeCloudCosmeticsRepository(
        fetchResponses: <_FetchResponseFactory>[
          () async {
            await gate.future;
            return _success(userA);
          },
          () async => _success(userB),
          () async => _success(userB),
        ],
      );
      final store =
          _MutableScopeUserStateStore(initialScope: 'shop-cosmetics-user-a');
      final controller = ShopCosmeticsController(
        userStateStore: store,
        cloudRepository: repo,
        cloudCache: _emptyMemoryCache(),
        cloudEnabled: true,
      );
      await Future<void>.delayed(Duration.zero);

      store.setTestScope('shop-cosmetics-user-b', notify: true);
      final state = await controller.getState();
      gate.complete();
      await Future<void>.delayed(Duration.zero);

      expect(state.ownedAssetIds, contains('user_card_full_moon'));
      expect(controller.cloudState.userId, 'shop-cosmetics-user-b');
      expect(controller.state?.ownedAssetIds,
          isNot(contains('wallpaper_mist_blue')));
    });

    test('wallpaper habit card and user card resolve after second login',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final first = _snapshot(
        userId: testUserId,
        ownedAssetIds: <String>['wallpaper_mist_blue'],
        wallpaperId: 'wallpaper_mist_blue',
      );
      final second = _snapshot(
        userId: testUserId,
        ownedAssetIds: <String>[
          'wallpaper_mist_blue',
          'habit_card_soft_sage',
          'user_card_full_moon',
        ],
        wallpaperId: 'wallpaper_mist_blue',
        habitCardId: 'habit_card_soft_sage',
        userCardId: 'user_card_full_moon',
      );
      final repo = _FakeCloudCosmeticsRepository(
        fetchResponses: <_FetchResponseFactory>[
          () async => _success(first),
          () async => _success(second),
          () async => _success(second),
        ],
      );
      final store = _MutableScopeUserStateStore(initialScope: testUserId);
      final controller = ShopCosmeticsController(
        userStateStore: store,
        cloudRepository: repo,
        cloudCache: _memoryCache(first),
        cloudEnabled: true,
      );
      await controller.getState();

      store.setTestScope(null, notify: true);
      store.setTestScope(testUserId, notify: true);
      await controller.getState();

      expect(controller.getEquippedWallpaperAssetOrNullSync()?.id,
          'wallpaper_mist_blue');
      expect(controller.getEquippedHabitCardAssetOrNullSync()?.id,
          'habit_card_soft_sage');
      expect(controller.getEquippedUserCardAssetOrNullSync()?.id,
          'user_card_full_moon');
    });

    test('essential bootstrap uses valid scoped cache without flash', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final snapshot = _snapshot(
        userId: testUserId,
        ownedAssetIds: <String>['wallpaper_mist_blue'],
        wallpaperId: 'wallpaper_mist_blue',
      );
      final store = _MutableScopeUserStateStore(initialScope: testUserId);
      final controller = ShopCosmeticsController(
        userStateStore: store,
        cloudRepository: _FakeCloudCosmeticsRepository(
          fetchResponses: <_FetchResponseFactory>[
            () async =>
                _failure(ShopCloudErrorCode.networkUnavailable, 'offline'),
          ],
        ),
        cloudCache: _memoryCache(snapshot),
        cloudEnabled: true,
      );

      final result = await controller.prepareEssentialCosmeticsForBootstrap(
        userId: testUserId,
      );

      expect(result.status, CosmeticsBootstrapStatus.readyFromCache);
      expect(result.wallpaperAsset?.id, 'wallpaper_mist_blue');
      expect(controller.getEquippedWallpaperAssetOrNullSync()?.id,
          'wallpaper_mist_blue');
    });

    test('essential bootstrap waits for remote snapshot without cache',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final snapshot = _snapshot(
        userId: testUserId,
        ownedAssetIds: <String>[
          'wallpaper_mist_blue',
          'habit_card_soft_sage',
          'user_card_full_moon',
        ],
        wallpaperId: 'wallpaper_mist_blue',
        habitCardId: 'habit_card_soft_sage',
        userCardId: 'user_card_full_moon',
      );
      final store = _MutableScopeUserStateStore(initialScope: testUserId);
      final controller = ShopCosmeticsController(
        userStateStore: store,
        cloudRepository: _FakeCloudCosmeticsRepository(
          fetchResponses: <_FetchResponseFactory>[
            () async => _success(snapshot),
            () async => _success(snapshot),
          ],
        ),
        cloudCache: _emptyMemoryCache(),
        cloudEnabled: true,
      );

      final result = await controller.prepareEssentialCosmeticsForBootstrap(
        userId: testUserId,
      );

      expect(result.status, CosmeticsBootstrapStatus.readyFromRemote);
      expect(result.wallpaperAsset?.id, 'wallpaper_mist_blue');
      expect(result.habitCardAsset?.id, 'habit_card_soft_sage');
      expect(result.userCardAsset?.id, 'user_card_full_moon');
    });

    test('same-user refresh failure without cache preserves visible snapshot',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final snapshot = _snapshot(
        userId: testUserId,
        ownedAssetIds: <String>[
          'wallpaper_mist_blue',
          'habit_card_soft_sage',
          'user_card_full_moon',
        ],
        wallpaperId: 'wallpaper_mist_blue',
        habitCardId: 'habit_card_soft_sage',
        userCardId: 'user_card_full_moon',
      );
      final store = _MutableScopeUserStateStore(initialScope: testUserId);
      final controller = ShopCosmeticsController(
        userStateStore: store,
        cloudRepository: _FakeCloudCosmeticsRepository(
          fetchResponses: <_FetchResponseFactory>[
            () async => _success(snapshot),
            () async =>
                _failure(ShopCloudErrorCode.networkUnavailable, 'offline'),
          ],
        ),
        cloudCache: _NonPersistingCloudCosmeticsCache(),
        cloudEnabled: true,
      );

      final result = await controller.prepareEssentialCosmeticsForBootstrap(
        userId: testUserId,
      );
      final token = result.readyToken;

      expect(token, isNotNull);
      expect(controller.validateReadyToken(token!), isTrue);

      await controller.refreshCloudState(force: true);

      expect(controller.cloudState.status, ShopCosmeticsCloudStatus.stale);
      expect(controller.cloudSnapshotRevision, result.appliedRevision);
      expect(controller.validateReadyToken(token), isTrue);
      expect(controller.getEquippedWallpaperAssetOrNullSync()?.id,
          'wallpaper_mist_blue');
      expect(controller.getEquippedHabitCardAssetOrNullSync()?.id,
          'habit_card_soft_sage');
      expect(controller.getEquippedUserCardAssetOrNullSync()?.id,
          'user_card_full_moon');
    });

    test('readiness token survives redundant same-scope notification only',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final snapshot = _snapshot(
        userId: testUserId,
        ownedAssetIds: <String>[
          'wallpaper_mist_blue',
          'habit_card_soft_sage',
          'user_card_full_moon',
        ],
        wallpaperId: 'wallpaper_mist_blue',
        habitCardId: 'habit_card_soft_sage',
        userCardId: 'user_card_full_moon',
      );
      final store = _MutableScopeUserStateStore(initialScope: testUserId);
      final controller = ShopCosmeticsController(
        userStateStore: store,
        cloudRepository: _FakeCloudCosmeticsRepository(
          fetchResponses: <_FetchResponseFactory>[
            () async => _success(snapshot),
          ],
        ),
        cloudCache: _emptyMemoryCache(),
        cloudEnabled: true,
      );

      final result = await controller.prepareEssentialCosmeticsForBootstrap(
        userId: testUserId,
      );
      final token = result.readyToken;

      expect(token, isNotNull);
      store.setTestScope(testUserId, notify: true);
      expect(controller.validateReadyToken(token!), isTrue);

      store.setTestScope('shop-cosmetics-user-b', notify: true);
      expect(controller.validateReadyToken(token), isFalse);
      expect(controller.getEquippedWallpaperAssetOrNullSync(), isNull);
    });

    test('essential bootstrap confirmed remote absence allows fallback',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final snapshot = _snapshot(userId: testUserId, ownedAssetIds: <String>[]);
      final store = _MutableScopeUserStateStore(initialScope: testUserId);
      final controller = ShopCosmeticsController(
        userStateStore: store,
        cloudRepository: _FakeCloudCosmeticsRepository(
          fetchResponses: <_FetchResponseFactory>[
            () async => _success(snapshot),
            () async => _success(snapshot),
          ],
        ),
        cloudCache: _emptyMemoryCache(),
        cloudEnabled: true,
      );

      final result = await controller.prepareEssentialCosmeticsForBootstrap(
        userId: testUserId,
      );

      expect(result.status, CosmeticsBootstrapStatus.confirmedEmpty);
      expect(result.canBuildHome, isTrue);
    });

    test('essential bootstrap remote error without cache fails', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final store = _MutableScopeUserStateStore(initialScope: testUserId);
      final controller = ShopCosmeticsController(
        userStateStore: store,
        cloudRepository: _FakeCloudCosmeticsRepository(
          fetchResponses: <_FetchResponseFactory>[
            () async =>
                _failure(ShopCloudErrorCode.networkUnavailable, 'offline'),
          ],
        ),
        cloudCache: _emptyMemoryCache(),
        cloudEnabled: true,
      );

      final result = await controller.prepareEssentialCosmeticsForBootstrap(
        userId: testUserId,
      );

      expect(result.status, CosmeticsBootstrapStatus.failed);
      expect(result.canBuildHome, isFalse);
    });

    test('essential bootstrap remote error with cache is degraded', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final snapshot = _snapshot(
        userId: testUserId,
        ownedAssetIds: <String>['wallpaper_mist_blue'],
        wallpaperId: 'wallpaper_mist_blue',
      );
      final store = _MutableScopeUserStateStore(initialScope: testUserId);
      final controller = ShopCosmeticsController(
        userStateStore: store,
        cloudRepository: _FakeCloudCosmeticsRepository(
          fetchResponses: <_FetchResponseFactory>[
            () async =>
                _failure(ShopCloudErrorCode.networkUnavailable, 'offline'),
          ],
        ),
        cloudCache: _memoryCache(snapshot),
        cloudEnabled: true,
      );

      final result = await controller.prepareEssentialCosmeticsForBootstrap(
        userId: testUserId,
        forceRemote: true,
      );

      expect(result.status, CosmeticsBootstrapStatus.degraded);
      expect(result.wallpaperAsset?.id, 'wallpaper_mist_blue');
    });

    test('essential bootstrap invalid equipped asset fails', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final snapshot = _snapshot(
        userId: testUserId,
        ownedAssetIds: <String>['missing_wallpaper'],
        wallpaperId: 'missing_wallpaper',
      );
      final store = _MutableScopeUserStateStore(initialScope: testUserId);
      final controller = ShopCosmeticsController(
        userStateStore: store,
        cloudRepository: _FakeCloudCosmeticsRepository(
          fetchResponses: <_FetchResponseFactory>[
            () async => _success(snapshot),
            () async => _success(snapshot),
          ],
        ),
        cloudCache: _emptyMemoryCache(),
        cloudEnabled: true,
      );

      final result = await controller.prepareEssentialCosmeticsForBootstrap(
        userId: testUserId,
      );

      expect(result.status, CosmeticsBootstrapStatus.failed);
      expect(result.source, 'invalid_asset');
      expect(result.canBuildHome, isFalse);
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
  PendingCloudCosmeticsPurchaseStore? pendingPurchaseStore,
  String Function()? requestIdGenerator,
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
      pendingPurchaseStore: pendingPurchaseStore,
      requestIdGenerator: requestIdGenerator,
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
  return _MemoryCloudCosmeticsCache(<CloudCosmeticsSnapshot>[snapshot]);
}

CloudCosmeticsCache _memoryCacheAll(List<CloudCosmeticsSnapshot> snapshots) {
  return _MemoryCloudCosmeticsCache(snapshots);
}

CloudCosmeticsCache _emptyMemoryCache() {
  return _MemoryCloudCosmeticsCache(const <CloudCosmeticsSnapshot>[]);
}

Future<void> _switchScope(
  UserStateStore store, {
  required String? userId,
}) async {
  await store.switchLocalScope(userId: userId, forceReload: false);
}

class _MutableScopeUserStateStore extends UserStateStore {
  _MutableScopeUserStateStore({required String? initialScope})
      : _scope = initialScope,
        super(
          UserStateRepository(storage: UserStateStorage()),
          journalEntrySyncService: JournalEntrySyncService(),
        );

  String? _scope;

  void setTestScope(String? userId, {bool notify = false}) {
    _scope = userId;
    if (notify) {
      notifyListeners();
    }
  }

  @override
  String? get activeLocalScopeUserId => _scope;

  @override
  String? get userId => _scope;
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
  List<RemoteShopItemDto>? catalogItems,
  List<RemoteShopBundleDto>? catalogBundles,
  List<RemoteShopBundleItemDto>? catalogBundleItems,
}) {
  final now = DateTime.utc(2026, 7, 19, 12);
  return CloudCosmeticsSnapshot(
    userId: userId,
    catalogItems: catalogItems ?? _catalogItems(),
    ownedAssetIds: ownedAssetIds,
    ownedBundleIds: ownedBundleIds,
    catalogBundles: catalogBundles ?? _catalogBundles(),
    catalogBundleItems: catalogBundleItems ?? _catalogBundleItems(),
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

List<RemoteShopItemDto> _catalogItems() {
  final now = DateTime.utc(2026, 7, 19, 12);
  return ShopAssetsCatalog.allAssets
      .map(
        (asset) => RemoteShopItemDto(
          id: asset.id,
          category: switch (asset.category) {
            ShopAssetCategory.wallpaper =>
              RemoteShopItemCategory.screenBackground,
            ShopAssetCategory.habitCard =>
              RemoteShopItemCategory.habitCardBackground,
            ShopAssetCategory.userCard =>
              RemoteShopItemCategory.userCardBackground,
          },
          subtype: null,
          rarity: switch (asset.rarity) {
            ShopAssetRarity.common => RemoteShopItemRarity.common,
            ShopAssetRarity.rare => RemoteShopItemRarity.rare,
            ShopAssetRarity.epic => RemoteShopItemRarity.epic,
            ShopAssetRarity.legendary => RemoteShopItemRarity.legendary,
          },
          priceCoins: asset.priceAmber,
          isConsumable: false,
          isStackable: false,
          maxQuantity: null,
          equipSlot: switch (asset.category) {
            ShopAssetCategory.wallpaper => RemoteShopEquipSlot.screenBackground,
            ShopAssetCategory.habitCard =>
              RemoteShopEquipSlot.habitCardBackground,
            ShopAssetCategory.userCard =>
              RemoteShopEquipSlot.userCardBackground,
          },
          assetKey: null,
          localizationKey: null,
          isActive: asset.isPurchasable,
          sortOrder: asset.sortOrder,
          catalogVersion: 1,
          createdAt: now,
          updatedAt: now,
        ),
      )
      .toList(growable: false);
}

List<RemoteShopBundleDto> _catalogBundles() {
  final now = DateTime.utc(2026, 7, 19, 12);
  return ShopAssetsCatalog.allBundles
      .map(
        (bundle) => RemoteShopBundleDto(
          id: bundle.id,
          familyId: bundle.familyId,
          rarity: switch (bundle.rarity) {
            ShopAssetRarity.common => RemoteShopItemRarity.common,
            ShopAssetRarity.rare => RemoteShopItemRarity.rare,
            ShopAssetRarity.epic => RemoteShopItemRarity.epic,
            ShopAssetRarity.legendary => RemoteShopItemRarity.legendary,
          },
          priceCoins: bundle.priceAmber,
          originalPriceCoins: bundle.originalPriceAmber,
          isActive: bundle.isPurchasable,
          sortOrder: bundle.sortOrder,
          catalogVersion: 1,
          createdAt: now,
          updatedAt: now,
        ),
      )
      .toList(growable: false);
}

List<RemoteShopBundleItemDto> _catalogBundleItems() {
  return ShopAssetsCatalog.allBundles
      .expand(
        (bundle) => <RemoteShopBundleItemDto>[
          _bundleItem(
            bundle.id,
            bundle.wallpaperItemId,
            RemoteShopEquipSlot.screenBackground,
          ),
          _bundleItem(
            bundle.id,
            bundle.habitCardItemId,
            RemoteShopEquipSlot.habitCardBackground,
          ),
          _bundleItem(
            bundle.id,
            bundle.userCardItemId,
            RemoteShopEquipSlot.userCardBackground,
          ),
        ],
      )
      .toList(growable: false);
}

RemoteShopBundleItemDto _bundleItem(
  String bundleId,
  String itemId,
  RemoteShopEquipSlot slot,
) {
  return RemoteShopBundleItemDto(
    bundleId: bundleId,
    itemId: itemId,
    slot: slot,
  );
}

class _MemoryCloudCosmeticsCache implements CloudCosmeticsCache {
  _MemoryCloudCosmeticsCache(this._snapshots) {
    _seed();
  }

  final List<CloudCosmeticsSnapshot> _snapshots;
  final Map<String, CloudCosmeticsCacheEntry> _entries =
      <String, CloudCosmeticsCacheEntry>{};

  void _seed() {
    for (final snapshot in _snapshots) {
      _entries[snapshot.userId] = CloudCosmeticsCacheEntry.fromSnapshot(
        snapshot,
        cachedAt: snapshot.fetchedAt,
      );
    }
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

class _NonPersistingCloudCosmeticsCache implements CloudCosmeticsCache {
  @override
  Future<void> clearAll() async {}

  @override
  Future<void> clearForUser(String userId) async {}

  @override
  Future<CloudCosmeticsCacheEntry?> read(String userId) async => null;

  @override
  Future<CloudCosmeticsCacheEntry> save(CloudCosmeticsSnapshot snapshot) async {
    return CloudCosmeticsCacheEntry.fromSnapshot(snapshot);
  }
}

class _FakeCloudCosmeticsRepository implements CloudCosmeticsRepository {
  _FakeCloudCosmeticsRepository({
    required List<_FetchResponseFactory> fetchResponses,
    this.equipError,
  }) : _fetchResponses = fetchResponses;

  final List<_FetchResponseFactory> _fetchResponses;
  final List<String> purchaseCalls = <String>[];
  final List<_PurchaseCall> purchaseCallRecords = <_PurchaseCall>[];
  final List<_EquipCall> equipCalls = <_EquipCall>[];
  final List<Object?> assetOutcomes = <Object?>[];
  final List<Object?> bundleOutcomes = <Object?>[];
  final List<Object?> equipOutcomes = <Object?>[];
  final ShopCloudEquipException? equipError;
  Future<void>? assetGate;
  Future<void>? equipGate;

  int _fetchIndex = 0;

  @override
  Future<RemoteShopEquipResultDto> equipAsset({
    required String itemId,
    required String slot,
    required String requestId,
  }) async {
    await equipGate;
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
    await assetGate;
    purchaseCalls.add(itemId);
    purchaseCallRecords.add(_PurchaseCall(
      resourceId: itemId,
      requestId: requestId,
    ));
    if (assetOutcomes.isNotEmpty) {
      final outcome = assetOutcomes.removeAt(0);
      if (outcome is ShopCloudPurchaseException) {
        throw outcome;
      }
      if (outcome is RemoteShopPurchaseResultDto) {
        return outcome;
      }
    }
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
    purchaseCallRecords.add(_PurchaseCall(
      resourceId: bundleId,
      requestId: requestId,
    ));
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

class _PurchaseCall {
  const _PurchaseCall({
    required this.resourceId,
    required this.requestId,
  });

  final String resourceId;
  final String requestId;
}

class _MemoryPendingCloudCosmeticsPurchaseStore
    implements PendingCloudCosmeticsPurchaseStore {
  final Map<String, List<PendingCloudCosmeticsPurchase>> _byUser =
      <String, List<PendingCloudCosmeticsPurchase>>{};
  final List<List<PendingCloudCosmeticsPurchase>> saveLog =
      <List<PendingCloudCosmeticsPurchase>>[];

  @override
  Future<void> clearPendingPurchases(String userId) async {
    _byUser.remove(userId);
  }

  @override
  Future<List<PendingCloudCosmeticsPurchase>> loadPendingPurchases(
    String userId,
  ) async {
    return List<PendingCloudCosmeticsPurchase>.from(
      _byUser[userId] ?? const <PendingCloudCosmeticsPurchase>[],
    );
  }

  @override
  Future<void> savePendingPurchases(
    String userId,
    List<PendingCloudCosmeticsPurchase> purchases,
  ) async {
    final copy = List<PendingCloudCosmeticsPurchase>.from(purchases);
    saveLog.add(copy);
    _byUser[userId] = copy;
  }
}

PendingCloudCosmeticsPurchase _pendingCloudPurchase({
  String userId = 'shop-cloud-user',
  required String requestId,
  PendingCloudCosmeticsPurchaseType operationType =
      PendingCloudCosmeticsPurchaseType.cosmeticPurchase,
  required String resourceId,
}) {
  return PendingCloudCosmeticsPurchase(
    userId: userId,
    requestId: requestId,
    operationType: operationType,
    resourceId: resourceId,
    createdAtMillis: 1,
    updatedAtMillis: 1,
    status: PendingCloudCosmeticsPurchaseStatus.awaitingResolution,
  );
}
