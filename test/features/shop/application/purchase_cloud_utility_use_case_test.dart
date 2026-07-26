import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/application/purchase_cloud_utility_use_case.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_dtos.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_errors.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_purchase_data_sources.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_purchase_repository.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_read_repository.dart';
import 'package:rutio/features/shop/domain/models/pending_shop_purchase.dart';
import 'package:rutio/features/shop/domain/pending_shop_operation_store.dart';
import 'package:rutio/features/shop/domain/shop_purchase_failure.dart';

void main() {
  group('PurchaseCloudUtilityUseCase', () {
    test('confirms a cloud purchase and clears the pending operation',
        () async {
      final currentUser = _CurrentUserHolder('user-1');
      final pendingStore = _MemoryPendingShopOperationStore();
      final readRepo = _FakeShopCloudReadRepository(
        currentUserIdProvider: () => currentUser.value,
        walletCoins: 5000,
      );
      final purchaseDataSource = _FakePurchaseDataSource(
        handler: (itemId, requestId) => <String, dynamic>{
          'requestId': requestId,
          'operation': 'purchase',
          'itemId': itemId,
          'priceCoins': 75,
          'coins': 4925,
          'walletVersion': 1,
          'inventoryQuantity': 1,
        },
      );
      final purchaseRepo =
          ShopCloudPurchaseRepository(dataSource: purchaseDataSource);
      final useCase = PurchaseCloudUtilityUseCase(
        purchaseRepository: purchaseRepo,
        pendingOperationStore: pendingStore,
        cloudReadRepository: readRepo,
        currentUserIdProvider: () => currentUser.value,
        purchaseEnabled: true,
        readEnabled: true,
      );

      final result = await useCase.purchaseCloudUtility(
        itemId: 'utility_xp_boost_1d',
      );

      expect(result.isSuccess, isTrue);
      expect(result.remoteResult?.coins, 4925);
      expect(await pendingStore.loadPendingPurchases('user-1'), isEmpty);
      expect(purchaseDataSource.calls, 1);
    });

    test('rejects unsupported items and unauthenticated users', () async {
      final useCase = PurchaseCloudUtilityUseCase(
        purchaseRepository:
            ShopCloudPurchaseRepository(dataSource: _NoopPurchaseDataSource()),
        pendingOperationStore: _MemoryPendingShopOperationStore(),
        cloudReadRepository: _FakeShopCloudReadRepository(
          currentUserIdProvider: () => 'user-1',
        ),
        currentUserIdProvider: () => 'user-1',
        purchaseEnabled: true,
        readEnabled: true,
      );

      final unsupported = await useCase.purchaseCloudUtility(
        itemId: 'wallpaper_mist_blue',
      );
      expect(unsupported.failure?.code,
          ShopPurchaseFailureCode.unsupportedCloudItem);

      final unauthenticated = PurchaseCloudUtilityUseCase(
        purchaseRepository:
            ShopCloudPurchaseRepository(dataSource: _NoopPurchaseDataSource()),
        pendingOperationStore: _MemoryPendingShopOperationStore(),
        cloudReadRepository: _FakeShopCloudReadRepository(
          currentUserIdProvider: () => null,
        ),
        currentUserIdProvider: () => null,
        purchaseEnabled: true,
        readEnabled: true,
      );
      final noSession = await unauthenticated.purchaseCloudUtility(
        itemId: 'utility_xp_boost_1d',
      );
      expect(noSession.failure?.code, ShopPurchaseFailureCode.unauthenticated);
    });

    test('returns cloudWalletMissing when the remote wallet is absent',
        () async {
      final useCase = PurchaseCloudUtilityUseCase(
        purchaseRepository:
            ShopCloudPurchaseRepository(dataSource: _NoopPurchaseDataSource()),
        pendingOperationStore: _MemoryPendingShopOperationStore(),
        cloudReadRepository: _FakeShopCloudReadRepository(
          currentUserIdProvider: () => 'user-1',
          walletCoins: null,
        ),
        currentUserIdProvider: () => 'user-1',
        purchaseEnabled: true,
        readEnabled: true,
      );

      final result = await useCase.purchaseCloudUtility(
        itemId: 'utility_xp_boost_1d',
      );

      expect(result.failure?.code, ShopPurchaseFailureCode.cloudWalletMissing);
    });

    test('rejects cloud utility when active catalog does not expose it',
        () async {
      final readRepo = _FakeShopCloudReadRepository(
        currentUserIdProvider: () => 'user-1',
        walletCoins: 5000,
        activeCatalog: <RemoteShopItemDto>[
          _remoteUtility('utility_xp_boost_1d', isActive: false),
          _remoteCosmetic('wallpaper_mist_blue'),
        ],
      );
      final purchaseDataSource = _FakePurchaseDataSource();
      final useCase = PurchaseCloudUtilityUseCase(
        purchaseRepository:
            ShopCloudPurchaseRepository(dataSource: purchaseDataSource),
        pendingOperationStore: _MemoryPendingShopOperationStore(),
        cloudReadRepository: readRepo,
        currentUserIdProvider: () => 'user-1',
        purchaseEnabled: true,
        readEnabled: true,
      );

      final result = await useCase.purchaseCloudUtility(
        itemId: 'utility_xp_boost_1d',
      );

      expect(
          result.failure?.code, ShopPurchaseFailureCode.itemNotFoundOrInactive);
      expect(purchaseDataSource.calls, 0);
    });

    test('purchases supported utility using only remote catalog authority',
        () async {
      final purchaseDataSource = _FakePurchaseDataSource();
      final useCase = PurchaseCloudUtilityUseCase(
        purchaseRepository:
            ShopCloudPurchaseRepository(dataSource: purchaseDataSource),
        pendingOperationStore: _MemoryPendingShopOperationStore(),
        cloudReadRepository: _FakeShopCloudReadRepository(
          currentUserIdProvider: () => 'user-1',
          walletCoins: 5000,
          activeCatalog: <RemoteShopItemDto>[
            _remoteUtility('utility_mystery_box_basic'),
          ],
        ),
        currentUserIdProvider: () => 'user-1',
        purchaseEnabled: true,
        readEnabled: true,
      );

      final result = await useCase.purchaseCloudUtility(
        itemId: 'utility_mystery_box_basic',
      );

      expect(result.isSuccess, isTrue);
      expect(purchaseDataSource.calls, 1);
    });

    test('reuses the same requestId across retries and pending resolution',
        () async {
      final currentUser = _CurrentUserHolder('user-1');
      final pendingStore = _MemoryPendingShopOperationStore();
      var firstCall = true;
      final purchaseDataSource = _FakePurchaseDataSource(
        handler: (itemId, requestId) {
          if (firstCall) {
            firstCall = false;
            throw ShopCloudPurchaseException(
              code: ShopPurchaseFailureCode.timeout,
              message: 'timeout',
              retryable: true,
            );
          }
          return <String, dynamic>{
            'requestId': requestId,
            'operation': 'purchase',
            'itemId': itemId,
            'priceCoins': 75,
            'coins': 4925,
            'walletVersion': 2,
            'inventoryQuantity': 1,
          };
        },
      );
      final purchaseRepo =
          ShopCloudPurchaseRepository(dataSource: purchaseDataSource);
      final useCase = PurchaseCloudUtilityUseCase(
        purchaseRepository: purchaseRepo,
        pendingOperationStore: pendingStore,
        cloudReadRepository: _FakeShopCloudReadRepository(
          currentUserIdProvider: () => currentUser.value,
          walletCoins: 5000,
        ),
        currentUserIdProvider: () => currentUser.value,
        purchaseEnabled: true,
        readEnabled: true,
        maxAutoRetries: 0,
      );

      final initial = await useCase.purchaseCloudUtility(
        itemId: 'utility_xp_boost_1d',
      );
      expect(initial.isPending, isTrue);
      final pending = await pendingStore.loadPendingPurchases('user-1');
      expect(pending.single.requestId, initial.requestId);

      final resolved = await useCase.purchaseCloudUtility(
        itemId: 'utility_xp_boost_1d',
      );
      expect(resolved.isSuccess, isTrue);
      expect(resolved.requestId, initial.requestId);
      expect(purchaseDataSource.calls, 2);
      expect(await pendingStore.loadPendingPurchases('user-1'), isEmpty);
    });

    test('keeps the purchase pending when the session changes mid-flight',
        () async {
      final currentUser = _CurrentUserHolder('user-1');
      final pendingStore = _MemoryPendingShopOperationStore();
      final purchaseDataSource = _FakePurchaseDataSource(
        handler: (itemId, requestId) {
          currentUser.value = 'user-2';
          return <String, dynamic>{
            'requestId': requestId,
            'operation': 'purchase',
            'itemId': itemId,
            'priceCoins': 75,
            'coins': 4925,
            'walletVersion': 1,
            'inventoryQuantity': 1,
          };
        },
      );
      final useCase = PurchaseCloudUtilityUseCase(
        purchaseRepository:
            ShopCloudPurchaseRepository(dataSource: purchaseDataSource),
        pendingOperationStore: pendingStore,
        cloudReadRepository: _FakeShopCloudReadRepository(
          currentUserIdProvider: () => currentUser.value,
          walletCoins: 5000,
        ),
        currentUserIdProvider: () => currentUser.value,
        purchaseEnabled: true,
        readEnabled: true,
      );

      final result = await useCase.purchaseCloudUtility(
        itemId: 'utility_xp_boost_1d',
      );

      expect(result.isPending, isTrue);
      expect(result.failure?.code, ShopPurchaseFailureCode.sessionChanged);
      expect(await pendingStore.loadPendingPurchases('user-1'), hasLength(1));
    });
  });
}

class _FakePurchaseDataSource implements ShopCloudPurchaseDataSource {
  _FakePurchaseDataSource({
    this.handler,
  });

  final Object? Function(String itemId, String requestId)? handler;
  int calls = 0;

  @override
  Future<Object?> purchaseShopItem({
    required String itemId,
    required String requestId,
  }) async {
    calls += 1;
    final callback = handler;
    if (callback == null) {
      return <String, dynamic>{
        'requestId': requestId,
        'operation': 'purchase',
        'itemId': itemId,
        'priceCoins': 75,
        'coins': 4925,
        'walletVersion': 1,
        'inventoryQuantity': 1,
      };
    }
    return callback(itemId, requestId);
  }

  @override
  Future<Object?> purchaseShopBundle({
    required String bundleId,
    required String requestId,
  }) async {
    return <String, dynamic>{
      'requestId': requestId,
      'bundleId': bundleId,
      'userId': 'user-1',
      'coinsDelta': -325,
      'walletCoinsAfter': 4675,
      'wallpaperItemId': 'wallpaper_rutio_beige',
      'habitCardItemId': 'habit_card_warm_beige',
      'userCardItemId': 'user_card_warm_beige',
      'isIdempotent': false,
      'createdAt': '2026-07-22T12:00:00Z',
    };
  }
}

class _NoopPurchaseDataSource implements ShopCloudPurchaseDataSource {
  @override
  Future<Object?> purchaseShopItem({
    required String itemId,
    required String requestId,
  }) async {
    return <String, dynamic>{
      'requestId': requestId,
      'operation': 'purchase',
      'itemId': itemId,
      'priceCoins': 75,
      'coins': 4925,
      'walletVersion': 1,
      'inventoryQuantity': 1,
    };
  }

  @override
  Future<Object?> purchaseShopBundle({
    required String bundleId,
    required String requestId,
  }) async {
    return <String, dynamic>{
      'requestId': requestId,
      'bundleId': bundleId,
      'userId': 'user-1',
      'coinsDelta': -325,
      'walletCoinsAfter': 4675,
      'wallpaperItemId': 'wallpaper_rutio_beige',
      'habitCardItemId': 'habit_card_warm_beige',
      'userCardItemId': 'user_card_warm_beige',
      'isIdempotent': false,
      'createdAt': '2026-07-22T12:00:00Z',
    };
  }
}

class _FakeShopCloudReadRepository extends ShopCloudReadRepository {
  _FakeShopCloudReadRepository({
    required String? Function() currentUserIdProvider,
    int? walletCoins,
    List<RemoteShopItemDto>? activeCatalog,
  })  : _currentUserIdProvider = currentUserIdProvider,
        _walletCoins = walletCoins,
        _activeCatalog = activeCatalog,
        super(
          readEnabled: true,
          currentUserIdProvider: currentUserIdProvider,
        );

  final String? Function() _currentUserIdProvider;
  final int? _walletCoins;
  final List<RemoteShopItemDto>? _activeCatalog;

  @override
  Future<ShopCloudReadResult<RemoteWalletDto?>> fetchWallet() async {
    final userId = _currentUserIdProvider();
    if (userId == null) {
      return const ShopCloudReadResult<RemoteWalletDto?>.failure(
        error: ShopCloudReadError(
          code: ShopCloudErrorCode.unauthenticated,
          message: 'No authenticated user session is available.',
        ),
      );
    }
    if (_walletCoins == null) {
      return const ShopCloudReadResult<RemoteWalletDto?>.failure(
        error: ShopCloudReadError(
          code: ShopCloudErrorCode.walletMissing,
          message: 'Wallet row is missing for the authenticated user.',
        ),
      );
    }
    return ShopCloudReadResult<RemoteWalletDto?>.success(
      data: RemoteWalletDto(
        userId: userId,
        coins: _walletCoins!,
        version: 1,
        createdAt: DateTime.utc(2026, 7, 18),
        updatedAt: DateTime.utc(2026, 7, 18),
      ),
    );
  }

  @override
  Future<ShopCloudReadResult<List<RemoteShopItemDto>>>
      fetchActiveCatalog() async {
    return ShopCloudReadResult<List<RemoteShopItemDto>>.success(
      data: _activeCatalog ??
          <RemoteShopItemDto>[
            _remoteUtility('utility_xp_boost_1d'),
            _remoteUtility(
              'utility_coin_boost_1d',
              subtype: 'coinBoost',
              priceCoins: 100,
              sortOrder: 1,
            ),
            _remoteUtility(
              'utility_streak_recover_1',
              subtype: 'streakRecover',
              priceCoins: 250,
              sortOrder: 2,
            ),
            _remoteUtility(
              'utility_streak_shield_1',
              subtype: 'streakShield',
              priceCoins: 300,
              sortOrder: 3,
            ),
            _remoteUtility(
              'utility_mystery_box_basic',
              subtype: 'mysteryBox',
              priceCoins: 100,
              sortOrder: 4,
            ),
          ],
    );
  }
}

RemoteShopItemDto _remoteUtility(
  String id, {
  String subtype = 'xpBoost',
  int priceCoins = 75,
  int sortOrder = 0,
  bool isActive = true,
}) {
  return RemoteShopItemDto.fromJson(<String, dynamic>{
    'id': id,
    'category': 'utility',
    'subtype': subtype,
    'rarity': 'common',
    'priceCoins': priceCoins,
    'isConsumable': true,
    'isStackable': true,
    'isActive': isActive,
    'sortOrder': sortOrder,
    'catalogVersion': 1,
    'createdAt': '2026-07-18T00:00:00Z',
    'updatedAt': '2026-07-18T00:00:00Z',
  });
}

RemoteShopItemDto _remoteCosmetic(String id) {
  return RemoteShopItemDto.fromJson(<String, dynamic>{
    'id': id,
    'category': 'screen_background',
    'subtype': null,
    'rarity': 'common',
    'priceCoins': 50,
    'isConsumable': false,
    'isStackable': false,
    'maxQuantity': 1,
    'equipSlot': 'screen_background',
    'assetKey': id,
    'localizationKey': id,
    'isActive': true,
    'sortOrder': 0,
    'catalogVersion': 1,
    'createdAt': '2026-07-18T00:00:00Z',
    'updatedAt': '2026-07-18T00:00:00Z',
  });
}

class _MemoryPendingShopOperationStore implements PendingShopOperationStore {
  final Map<String, List<PendingShopPurchase>> _store =
      <String, List<PendingShopPurchase>>{};

  @override
  Future<List<PendingShopPurchase>> loadPendingPurchases(String userId) async {
    return List<PendingShopPurchase>.from(_store[userId] ?? const []);
  }

  @override
  Future<void> savePendingPurchases(
    String userId,
    List<PendingShopPurchase> purchases,
  ) async {
    _store[userId] = List<PendingShopPurchase>.from(purchases);
  }

  @override
  Future<void> clearPendingPurchases(String userId) async {
    _store.remove(userId);
  }
}

class _CurrentUserHolder {
  _CurrentUserHolder(this.value);
  String? value;
}
