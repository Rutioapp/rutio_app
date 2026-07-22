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
import 'package:rutio/features/shop/application/purchase_cloud_utility_use_case.dart';
import 'package:rutio/features/shop/application/shop_controller.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_dtos.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_errors.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_purchase_data_sources.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_purchase_dtos.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_purchase_repository.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_snapshot.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_read_repository.dart';
import 'package:rutio/features/shop/data/shop_local_repository.dart';
import 'package:rutio/features/shop/domain/models/pending_shop_purchase.dart';
import 'package:rutio/features/shop/domain/shop_state.dart';
import 'package:rutio/features/shop/domain/pending_shop_operation_store.dart';
import 'package:rutio/features/shop/domain/shop_purchase_failure.dart';
import 'package:rutio/features/shop/domain/shop_purchase_result.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShopController cloud purchase', () {
    test('double tap on the same utility reuses a single operation', () async {
      final purchaseUseCase = _FakePurchaseCloudUtilityUseCase(
        completer: Completer<ShopPurchaseResult>(),
      );
      final fixture = await _createController(
        purchaseUseCase: purchaseUseCase,
        cloudSnapshot: _cloudSnapshot(
          walletCoins: 4925,
          itemId: 'utility_xp_boost_1d',
          quantity: 1,
        ),
      );
      final controller = fixture.controller;

      final first = controller.purchaseItem('utility_xp_boost_1d');
      final second = controller.purchaseItem('utility_xp_boost_1d');
      purchaseUseCase.completeWith(
        ShopPurchaseResult.success(
          itemId: 'utility_xp_boost_1d',
          requestId: '9f5a1f2a-4a69-4d7c-8cf6-71b0f7df0d8d',
          remoteResult: RemoteShopPurchaseResultDto(
            requestId: '9f5a1f2a-4a69-4d7c-8cf6-71b0f7df0d8d',
            operation: 'purchase',
            itemId: 'utility_xp_boost_1d',
            priceCoins: 75,
            coins: 4925,
            walletVersion: 1,
            inventoryQuantity: 1,
          ),
        ),
      );

      final firstResult = await first;
      final secondResult = await second;

      expect(firstResult.status, ShopControllerStatus.success);
      expect(secondResult.status, ShopControllerStatus.success);
      expect(purchaseUseCase.calls, 1);
    });

    test(
        'cloud success updates the visible snapshot without mutating local state',
        () async {
      final purchaseUseCase = _FakePurchaseCloudUtilityUseCase(
        resultFactory: () => ShopPurchaseResult.success(
          itemId: 'utility_xp_boost_1d',
          requestId: '9f5a1f2a-4a69-4d7c-8cf6-71b0f7df0d8d',
          remoteResult: RemoteShopPurchaseResultDto(
            requestId: '9f5a1f2a-4a69-4d7c-8cf6-71b0f7df0d8d',
            operation: 'purchase',
            itemId: 'utility_xp_boost_1d',
            priceCoins: 75,
            coins: 4925,
            walletVersion: 1,
            inventoryQuantity: 1,
          ),
        ),
      );
      final fixture = await _createController(
        purchaseUseCase: purchaseUseCase,
        cloudSnapshot: _cloudSnapshot(
          walletCoins: 4925,
          itemId: 'utility_xp_boost_1d',
          quantity: 1,
        ),
      );
      final controller = fixture.controller;

      final result = await controller.purchaseItem('utility_xp_boost_1d');
      final localState = await fixture.shopRepository.load();

      expect(result.status, ShopControllerStatus.success);
      expect(result.walletCoins, 4925);
      expect(result.cloudPurchaseResult?.remoteResult?.inventoryQuantity, 1);
      expect(result.cloudRefreshFailed, isFalse);
      expect(controller.visibleCoinBalance, 4925);
      expect(controller.getWalletCoins(), 5000);
      expect(localState.backpackItems, isEmpty);
    });

    test(
        'cloud success updates the confirmed global wallet balance before reconciliation',
        () async {
      final walletRepo = _FakeCloudWalletRepository()
        ..enqueueSuccess(
          _walletSnapshot(
            userId: 'shop-controller-user',
            coins: 4925,
            version: 2,
            updatedAt: DateTime.utc(2026, 7, 18, 10),
          ),
        );
      final walletController = GlobalWalletController(
        repository: walletRepo,
        cache: _MemoryWalletCache(),
        currentUserIdProvider: () => 'shop-controller-user',
        enabled: true,
      );
      final purchaseUseCase = _FakePurchaseCloudUtilityUseCase(
        resultFactory: () => ShopPurchaseResult.success(
          itemId: 'utility_xp_boost_1d',
          requestId: '9f5a1f2a-4a69-4d7c-8cf6-71b0f7df0d8d',
          remoteResult: RemoteShopPurchaseResultDto(
            requestId: '9f5a1f2a-4a69-4d7c-8cf6-71b0f7df0d8d',
            operation: 'purchase',
            itemId: 'utility_xp_boost_1d',
            priceCoins: 75,
            coins: 4925,
            walletVersion: 2,
            inventoryQuantity: 1,
          ),
        ),
      );
      final fixture = await _createController(
        purchaseUseCase: purchaseUseCase,
        cloudSnapshot: _cloudSnapshot(
          walletCoins: 4925,
          itemId: 'utility_xp_boost_1d',
          quantity: 1,
        ),
        globalWalletController: walletController,
      );

      final result = await fixture.controller.purchaseItem(
        'utility_xp_boost_1d',
      );
      await Future<void>.delayed(Duration.zero);

      expect(result.status, ShopControllerStatus.success);
      expect(walletController.state.status, GlobalWalletStatus.ready);
      expect(walletController.state.coins, 4925);
      expect(walletRepo.calls, 1);
    });

    test('pending cloud purchases keep the operation unresolved', () async {
      final purchaseUseCase = _FakePurchaseCloudUtilityUseCase(
        resultFactory: () => ShopPurchaseResult.pendingResolution(
          itemId: 'utility_xp_boost_1d',
          requestId: '9f5a1f2a-4a69-4d7c-8cf6-71b0f7df0d8d',
          failure: const ShopPurchaseFailure(
            code: ShopPurchaseFailureCode.timeout,
            message: 'timeout',
            retryable: true,
          ),
        ),
      );
      final fixture = await _createController(
        purchaseUseCase: purchaseUseCase,
        cloudSnapshot: _cloudSnapshot(
          walletCoins: 5000,
          itemId: 'utility_xp_boost_1d',
          quantity: 0,
        ),
      );
      final controller = fixture.controller;

      final result = await controller.purchaseItem('utility_xp_boost_1d');

      expect(result.status, ShopControllerStatus.cloudPurchasePending);
      expect(result.purchaseFailure?.code, ShopPurchaseFailureCode.timeout);
      expect(controller.visibleCoinBalance, 5000);
      expect(controller.getWalletCoins(), 5000);
      expect((await fixture.shopRepository.load()).backpackItems, isEmpty);
    });
  });
}

Future<_ControllerFixture> _createController({
  required _FakePurchaseCloudUtilityUseCase purchaseUseCase,
  required _FakeShopCloudReadRepository cloudSnapshot,
  GlobalWalletController? globalWalletController,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final repo = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope('shop-controller-user');
  final store = UserStateStore(
    repo,
    journalEntrySyncService: JournalEntrySyncService(),
  );
  await store.save(
    <String, dynamic>{
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
        'wallet': <String, dynamic>{'coins': 5000},
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
          'lastResetDate': '2026-07-18',
          'xpEarnedToday': 0,
          'coinsEarnedToday': 0,
          'habitsCompletedToday': <String, dynamic>{},
        },
        'history': <String, dynamic>{
          'habitCompletions': <String, dynamic>{},
          'habitCountValues': <String, dynamic>{},
          'habitSkips': <String, dynamic>{},
          'habitCompletionTimes': <String, dynamic>{},
          'habitOccurrenceStatuses': <String, dynamic>{},
          'habitStreakBreaks': <String, dynamic>{},
          'habitStreakShields': <String, dynamic>{},
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

  final shopRepository = ShopLocalRepository();
  await shopRepository.save(const ShopState.initial());

  return _ControllerFixture(
    controller: ShopController(
      userStateStore: store,
      globalWalletController: globalWalletController,
      shopRepository: shopRepository,
      shopCloudReadRepository: cloudSnapshot,
      purchaseCloudUtilityUseCase: purchaseUseCase,
      currentSupabaseUserIdProvider: () => 'shop-controller-user',
      cloudReadEnabled: true,
      cloudPurchaseEnabled: true,
    ),
    shopRepository: shopRepository,
  );
}

_FakeShopCloudReadRepository _cloudSnapshot({
  required int walletCoins,
  required String itemId,
  required int quantity,
}) {
  return _FakeShopCloudReadRepository(
    walletCoins: walletCoins,
    itemId: itemId,
    quantity: quantity,
  );
}

class _FakePurchaseCloudUtilityUseCase extends PurchaseCloudUtilityUseCase {
  _FakePurchaseCloudUtilityUseCase({
    Completer<ShopPurchaseResult>? completer,
    ShopPurchaseResult Function()? resultFactory,
  })  : _completer = completer,
        _resultFactory = resultFactory,
        super(
          purchaseRepository: ShopCloudPurchaseRepository(
            dataSource: _NoopPurchaseDataSource(),
          ),
          pendingOperationStore: _NoopPendingStore(),
          cloudReadRepository: _NoopReadRepository(),
          currentUserIdProvider: () => 'shop-controller-user',
          purchaseEnabled: true,
          readEnabled: true,
        );

  final Completer<ShopPurchaseResult>? _completer;
  final ShopPurchaseResult Function()? _resultFactory;
  int calls = 0;

  void completeWith(ShopPurchaseResult result) {
    _completer?.complete(result);
  }

  @override
  Future<ShopPurchaseResult> purchaseCloudUtility({
    required String itemId,
    String? requestId,
  }) async {
    calls += 1;
    if (_completer != null) {
      return _completer!.future;
    }
    return _resultFactory!();
  }
}

class _FakeShopCloudReadRepository extends ShopCloudReadRepository {
  _FakeShopCloudReadRepository({
    required int walletCoins,
    required String itemId,
    required int quantity,
  })  : _walletCoins = walletCoins,
        _itemId = itemId,
        _quantity = quantity,
        super(
          readEnabled: true,
          currentUserIdProvider: () => 'shop-controller-user',
        );

  final int _walletCoins;
  final String _itemId;
  final int _quantity;

  @override
  Future<ShopCloudReadResult<ShopCloudSnapshot>> fetchShopSnapshot() async {
    return ShopCloudReadResult<ShopCloudSnapshot>.success(
      data: ShopCloudSnapshot(
        authenticatedUserId: 'shop-controller-user',
        catalogItems: <RemoteShopItemDto>[
          RemoteShopItemDto.fromJson(<String, dynamic>{
            'id': 'utility_xp_boost_1d',
            'category': 'utility',
            'subtype': 'xpBoost',
            'priceCoins': 75,
            'isConsumable': true,
            'isStackable': true,
            'isActive': true,
            'sortOrder': 0,
            'catalogVersion': 1,
            'createdAt': '2026-07-18T00:00:00Z',
            'updatedAt': '2026-07-18T00:00:00Z',
          }),
        ],
        wallet: RemoteWalletDto(
          userId: 'shop-controller-user',
          coins: _walletCoins,
          version: 1,
          createdAt: DateTime.utc(2026, 7, 18),
          updatedAt: DateTime.utc(2026, 7, 18),
        ),
        inventory: _quantity > 0
            ? <RemoteInventoryItemDto>[
                RemoteInventoryItemDto.fromJson(
                  <String, dynamic>{
                    'id': 'inv-1',
                    'userId': 'shop-controller-user',
                    'itemId': _itemId,
                    'quantity': _quantity,
                    'acquisitionSource': 'purchase',
                    'acquiredAt': '2026-07-18T00:00:00Z',
                    'updatedAt': '2026-07-18T00:00:00Z',
                  },
                  expectedUserId: 'shop-controller-user',
                ),
              ]
            : const <RemoteInventoryItemDto>[],
        ownedBundles: const <RemoteOwnedBundleDto>[],
        equippedCosmetics: const <RemoteEquippedCosmeticDto>[],
        fetchedAt: DateTime.utc(2026, 7, 18),
        catalogVersion: 1,
        warnings: const <ShopCloudWarning>[],
      ),
    );
  }
}

class _ControllerFixture {
  const _ControllerFixture({
    required this.controller,
    required this.shopRepository,
  });

  final ShopController controller;
  final ShopLocalRepository shopRepository;
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
      'userId': 'shop-controller-user',
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

class _NoopPendingStore implements PendingShopOperationStore {
  @override
  Future<void> clearPendingPurchases(String userId) async {}

  @override
  Future<List<PendingShopPurchase>> loadPendingPurchases(String userId) async {
    return const <PendingShopPurchase>[];
  }

  @override
  Future<void> savePendingPurchases(
    String userId,
    List<PendingShopPurchase> purchases,
  ) async {}
}

class _NoopReadRepository extends ShopCloudReadRepository {
  _NoopReadRepository()
      : super(
          readEnabled: true,
          currentUserIdProvider: () => 'shop-controller-user',
        );
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
