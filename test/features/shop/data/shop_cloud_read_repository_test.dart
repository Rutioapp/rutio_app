import 'package:flutter/foundation.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_config.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_errors.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_read_repository.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_remote_data_sources.dart';

void main() {
  group('ShopCloudConfig', () {
    test('is disabled by default', () {
      expect(ShopCloudConfig.isReadEnabled, isFalse);
    });
  });

  group('ShopCloudReadRepository', () {
    test('does not query Supabase when disabled', () async {
      final catalog = _FakeCatalogDataSource();
      final userState = _FakeUserStateDataSource();
      final repository = ShopCloudReadRepository(
        catalogRemoteDataSource: catalog,
        userStateRemoteDataSource: userState,
        readEnabled: false,
        currentUserIdProvider: () => 'user-1',
      );

      final result = await repository.fetchShopSnapshot();

      expect(result.isSuccess, isFalse);
      expect(result.error?.code, ShopCloudErrorCode.featureDisabled);
      expect(catalog.calls, 0);
      expect(userState.walletCalls, 0);
      expect(userState.inventoryCalls, 0);
      expect(userState.equippedCalls, 0);
    });

    test('rejects unauthenticated access without querying data sources',
        () async {
      final catalog = _FakeCatalogDataSource();
      final userState = _FakeUserStateDataSource();
      final repository = ShopCloudReadRepository(
        catalogRemoteDataSource: catalog,
        userStateRemoteDataSource: userState,
        readEnabled: true,
        currentUserIdProvider: () => null,
      );

      final result = await repository.fetchWallet();

      expect(result.isSuccess, isFalse);
      expect(result.error?.code, ShopCloudErrorCode.unauthenticated);
      expect(catalog.calls, 0);
      expect(userState.walletCalls, 0);
    });

    test('fetchWallet returns walletMissing when row is absent', () async {
      final repository = ShopCloudReadRepository(
        catalogRemoteDataSource: _FakeCatalogDataSource(),
        userStateRemoteDataSource: _FakeUserStateDataSource(),
        readEnabled: true,
        currentUserIdProvider: () => 'user-1',
      );

      final result = await repository.fetchWallet();

      expect(result.isSuccess, isFalse);
      expect(result.error?.code, ShopCloudErrorCode.walletMissing);
    });

    test('fetchInventory filters invalid rows and keeps valid ones', () async {
      final userState = _FakeUserStateDataSource()
        ..inventoryRows = <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'inv-1',
            'user_id': 'user-1',
            'item_id': 'utility_xp_boost_1d',
            'quantity': 2,
            'acquisition_source': 'purchase',
            'acquired_at': '2026-07-17T00:00:00Z',
            'updated_at': '2026-07-17T00:00:00Z',
          },
          <String, dynamic>{
            'id': 'inv-2',
            'user_id': 'user-1',
            'item_id': 'utility_coin_boost_1d',
            'quantity': 0,
            'acquisition_source': 'purchase',
            'acquired_at': '2026-07-17T00:00:00Z',
            'updated_at': '2026-07-17T00:00:00Z',
          },
        ];
      final repository = ShopCloudReadRepository(
        catalogRemoteDataSource: _FakeCatalogDataSource(),
        userStateRemoteDataSource: userState,
        readEnabled: true,
        currentUserIdProvider: () => 'user-1',
      );

      final result = await repository.fetchInventory();

      expect(result.isSuccess, isTrue);
      expect(result.data, hasLength(1));
      expect(result.data!.single.itemId, 'utility_xp_boost_1d');
      expect(
        result.warnings.any(
          (warning) => warning.code == ShopCloudWarningCode.invalidRemoteItem,
        ),
        isTrue,
      );
    });

    test('fetchInventory keeps admin acquisition_source rows', () async {
      final userState = _FakeUserStateDataSource()
        ..inventoryRows = <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'inv-1',
            'user_id': 'user-1',
            'item_id': 'utility_streak_shield_1',
            'quantity': 2,
            'acquisition_source': 'admin',
            'acquired_at': '2026-07-17T00:00:00Z',
            'updated_at': '2026-07-17T00:00:00Z',
          },
        ];
      final repository = ShopCloudReadRepository(
        catalogRemoteDataSource: _FakeCatalogDataSource(),
        userStateRemoteDataSource: userState,
        readEnabled: true,
        currentUserIdProvider: () => 'user-1',
      );

      final result = await repository.fetchInventory();

      expect(result.isSuccess, isTrue);
      expect(result.data, hasLength(1));
      expect(result.data!.single.itemId, 'utility_streak_shield_1');
      expect(result.data!.single.acquisitionSource, 'admin');
    });

    test('fetchShopSnapshot succeeds with valid diagnostic data', () async {
      final catalog = _FakeCatalogDataSource()
        ..rows = <Map<String, dynamic>>[
          _utilityRow('utility_xp_boost_1d', 75, 'xpBoost'),
          _utilityRow('utility_coin_boost_1d', 100, 'coinBoost'),
          _utilityRow('utility_streak_recover_1', 250, 'streakRecover'),
          _utilityRow('utility_streak_shield_1', 300, 'streakShield'),
          _utilityRow('utility_mystery_box_basic', 100, 'mysteryBox'),
        ]
        ..bundleRows = <Map<String, dynamic>>[
          _bundleRow(
            'pack_beige_rutio',
            familyId: 'pack_beige_rutio',
            rarity: 'common',
            priceCoins: 300,
            originalPriceCoins: 330,
            sortOrder: 0,
            catalogVersion: 3,
          ),
        ]
        ..bundleItemRows = <Map<String, dynamic>>[
          _bundleItemRow(
            'pack_beige_rutio',
            'wallpaper_rutio_beige',
            'screen_background',
          ),
          _bundleItemRow(
            'pack_beige_rutio',
            'habit_card_warm_beige',
            'habit_card_background',
          ),
          _bundleItemRow(
            'pack_beige_rutio',
            'user_card_warm_beige',
            'user_card_background',
          ),
        ];
      final userState = _FakeUserStateDataSource()
        ..walletRow = <String, dynamic>{
          'user_id': 'user-1',
          'coins': 777,
          'version': 1,
          'created_at': '2026-07-17T00:00:00Z',
          'updated_at': '2026-07-17T00:00:00Z',
        }
        ..inventoryRows = <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'inv-1',
            'user_id': 'user-1',
            'item_id': 'utility_xp_boost_1d',
            'quantity': 1,
            'acquisition_source': 'purchase',
            'acquired_at': '2026-07-17T00:00:00Z',
            'updated_at': '2026-07-17T00:00:00Z',
          },
        ]
        ..equippedRows = <Map<String, dynamic>>[
          <String, dynamic>{
            'user_id': 'user-1',
            'slot': 'screen_background',
            'item_id': 'wallpaper_mist_blue',
            'equipped_at': '2026-07-17T00:00:00Z',
          },
        ]
        ..ownedBundleRows = <Map<String, dynamic>>[
          <String, dynamic>{
            'user_id': 'user-1',
            'bundle_id': 'pack_beige_rutio',
            'acquisition_source': 'purchase',
            'acquired_at': '2026-07-17T00:00:00Z',
            'updated_at': '2026-07-17T00:00:00Z',
          },
        ];
      final repository = ShopCloudReadRepository(
        catalogRemoteDataSource: catalog,
        userStateRemoteDataSource: userState,
        readEnabled: true,
        currentUserIdProvider: () => 'user-1',
        nowProvider: () => DateTime.utc(2026, 7, 18),
      );

      final result = await repository.fetchShopSnapshot();

      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);
      expect(result.data!.authenticatedUserId, 'user-1');
      expect(result.data!.catalogItems, hasLength(5));
      expect(result.data!.wallet?.coins, 777);
      expect(result.data!.inventory, hasLength(1));
      expect(result.data!.equippedCosmetics, hasLength(1));
      expect(result.data!.ownedBundles, hasLength(1));
      expect(result.data!.catalogBundles, hasLength(1));
      expect(result.data!.catalogVersion, 3);
      expect(result.data!.fetchedAt, DateTime.utc(2026, 7, 18));
      expect(catalog.calls, 1);
      expect(userState.walletCalls, 1);
    });

    test('detects session changes during a load and stops safely', () async {
      late String? userId;
      final catalog = _SwitchingCatalogDataSource(
        onBeforeComplete: () {
          userId = 'user-2';
        },
      );
      final userState = _FakeUserStateDataSource();
      final repository = ShopCloudReadRepository(
        catalogRemoteDataSource: catalog,
        userStateRemoteDataSource: userState,
        readEnabled: true,
        currentUserIdProvider: () => userId,
      );

      userId = 'user-1';
      final result = await repository.fetchShopSnapshot();

      expect(result.isSuccess, isFalse);
      expect(result.error?.code, ShopCloudErrorCode.sessionChanged);
      expect(userState.walletCalls, 0);
    });

    test('fetchActiveBundleCatalog groups slots and rejects duplicates',
        () async {
      final catalog = _FakeCatalogDataSource()
        ..bundleRows = <Map<String, dynamic>>[
          _bundleRow(
            'pack_beige_rutio',
            familyId: 'pack_beige_rutio',
            rarity: 'common',
            priceCoins: 300,
            originalPriceCoins: 330,
            sortOrder: 0,
            catalogVersion: 2,
          ),
        ]
        ..bundleItemRows = <Map<String, dynamic>>[
          _bundleItemRow(
            'pack_beige_rutio',
            'wallpaper_rutio_beige',
            'screen_background',
          ),
          _bundleItemRow(
            'pack_beige_rutio',
            'habit_card_warm_beige',
            'habit_card_background',
          ),
          _bundleItemRow(
            'pack_beige_rutio',
            'user_card_warm_beige',
            'user_card_background',
          ),
          _bundleItemRow(
            'pack_beige_rutio',
            'user_card_soft_camel',
            'user_card_background',
          ),
        ];
      final repository = ShopCloudReadRepository(
        catalogRemoteDataSource: catalog,
        userStateRemoteDataSource: _FakeUserStateDataSource(),
        readEnabled: true,
        currentUserIdProvider: () => 'user-1',
      );

      final result = await repository.fetchActiveBundleCatalog();

      expect(result.isSuccess, isTrue);
      expect(result.data, isEmpty);
      expect(
        result.warnings.any(
          (warning) => warning.message.contains('duplicate slots'),
        ),
        isTrue,
      );
    });

    test('fetchActiveBundleCatalog warns on incomplete composition', () async {
      final catalog = _FakeCatalogDataSource()
        ..bundleRows = <Map<String, dynamic>>[
          _bundleRow(
            'pack_beige_rutio',
            familyId: 'pack_beige_rutio',
            rarity: 'common',
            priceCoins: 300,
            originalPriceCoins: 330,
            sortOrder: 0,
            catalogVersion: 2,
          ),
        ]
        ..bundleItemRows = <Map<String, dynamic>>[
          _bundleItemRow(
            'pack_beige_rutio',
            'wallpaper_rutio_beige',
            'screen_background',
          ),
          _bundleItemRow(
            'pack_beige_rutio',
            'habit_card_warm_beige',
            'habit_card_background',
          ),
        ];
      final repository = ShopCloudReadRepository(
        catalogRemoteDataSource: catalog,
        userStateRemoteDataSource: _FakeUserStateDataSource(),
        readEnabled: true,
        currentUserIdProvider: () => 'user-1',
      );

      final result = await repository.fetchActiveBundleCatalog();

      expect(result.isSuccess, isTrue);
      expect(result.data, isEmpty);
      expect(
        result.warnings.any(
          (warning) => warning.message.contains('incomplete'),
        ),
        isTrue,
      );
    });

    test('fetchActiveBundleCatalog stops when the session changes mid-read',
        () async {
      late String? userId;
      final catalog = _SwitchingBundleCatalogDataSource(
        onBeforeComplete: () {
          userId = 'user-2';
        },
      );
      final repository = ShopCloudReadRepository(
        catalogRemoteDataSource: catalog,
        userStateRemoteDataSource: _FakeUserStateDataSource(),
        readEnabled: true,
        currentUserIdProvider: () => userId,
      );

      userId = 'user-1';
      final result = await repository.fetchActiveBundleCatalog();

      expect(result.isSuccess, isFalse);
      expect(result.error?.code, ShopCloudErrorCode.sessionChanged);
    });
  });
}

class _FakeCatalogDataSource implements ShopCatalogRemoteDataSource {
  int calls = 0;
  List<Map<String, dynamic>> rows = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> bundleRows = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> bundleItemRows = <Map<String, dynamic>>[];

  @override
  Future<List<Map<String, dynamic>>> fetchActiveCatalogRows() async {
    calls += 1;
    return rows;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchActiveBundleRows() async {
    return bundleRows;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchBundleItemRows() async {
    return bundleItemRows;
  }
}

class _FakeUserStateDataSource implements ShopUserStateRemoteDataSource {
  int walletCalls = 0;
  int inventoryCalls = 0;
  int equippedCalls = 0;
  int ownedBundleCalls = 0;
  Map<String, dynamic>? walletRow;
  List<Map<String, dynamic>> inventoryRows = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> equippedRows = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> ownedBundleRows = <Map<String, dynamic>>[];

  @override
  Future<Map<String, dynamic>?> fetchWalletRow() async {
    walletCalls += 1;
    return walletRow;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchInventoryRows() async {
    inventoryCalls += 1;
    return inventoryRows;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchEquippedCosmeticsRows() async {
    equippedCalls += 1;
    return equippedRows;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchOwnedBundleRows() async {
    ownedBundleCalls += 1;
    return ownedBundleRows;
  }
}

class _SwitchingCatalogDataSource implements ShopCatalogRemoteDataSource {
  _SwitchingCatalogDataSource({required this.onBeforeComplete});

  final VoidCallback onBeforeComplete;

  @override
  Future<List<Map<String, dynamic>>> fetchActiveCatalogRows() async {
    onBeforeComplete();
    return <Map<String, dynamic>>[
      _utilityRow('utility_xp_boost_1d', 75, 'xpBoost'),
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchActiveBundleRows() async {
    onBeforeComplete();
    return <Map<String, dynamic>>[
      _bundleRow(
        'pack_beige_rutio',
        familyId: 'pack_beige_rutio',
        rarity: 'common',
        priceCoins: 300,
        originalPriceCoins: 330,
        sortOrder: 0,
        catalogVersion: 2,
      ),
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchBundleItemRows() async {
    return <Map<String, dynamic>>[
      _bundleItemRow(
        'pack_beige_rutio',
        'wallpaper_rutio_beige',
        'screen_background',
      ),
      _bundleItemRow(
        'pack_beige_rutio',
        'habit_card_warm_beige',
        'habit_card_background',
      ),
      _bundleItemRow(
        'pack_beige_rutio',
        'user_card_warm_beige',
        'user_card_background',
      ),
    ];
  }
}

class _SwitchingBundleCatalogDataSource implements ShopCatalogRemoteDataSource {
  _SwitchingBundleCatalogDataSource({required this.onBeforeComplete});

  final VoidCallback onBeforeComplete;

  @override
  Future<List<Map<String, dynamic>>> fetchActiveCatalogRows() async {
    return const <Map<String, dynamic>>[];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchActiveBundleRows() async {
    onBeforeComplete();
    return <Map<String, dynamic>>[
      _bundleRow(
        'pack_beige_rutio',
        familyId: 'pack_beige_rutio',
        rarity: 'common',
        priceCoins: 300,
        originalPriceCoins: 330,
        sortOrder: 0,
        catalogVersion: 2,
      ),
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchBundleItemRows() async {
    return <Map<String, dynamic>>[
      _bundleItemRow(
        'pack_beige_rutio',
        'wallpaper_rutio_beige',
        'screen_background',
      ),
      _bundleItemRow(
        'pack_beige_rutio',
        'habit_card_warm_beige',
        'habit_card_background',
      ),
      _bundleItemRow(
        'pack_beige_rutio',
        'user_card_warm_beige',
        'user_card_background',
      ),
    ];
  }
}

Map<String, dynamic> _utilityRow(String id, int priceCoins, String subtype) {
  return <String, dynamic>{
    'id': id,
    'category': 'utility',
    'subtype': subtype,
    'rarity': null,
    'priceCoins': priceCoins,
    'isConsumable': true,
    'isStackable': true,
    'maxQuantity': null,
    'equipSlot': null,
    'assetKey': 'assets/shop/utilities/$id.png',
    'localizationKey': 'key_$id',
    'isActive': true,
    'sortOrder': 0,
    'catalogVersion': 1,
    'createdAt': '2026-07-17T00:00:00Z',
    'updatedAt': '2026-07-17T00:00:00Z',
  };
}

Map<String, dynamic> _bundleRow(
  String id, {
  required String familyId,
  required String rarity,
  required int priceCoins,
  required int originalPriceCoins,
  required int sortOrder,
  required int catalogVersion,
}) {
  return <String, dynamic>{
    'id': id,
    'family_id': familyId,
    'rarity': rarity,
    'price_coins': priceCoins,
    'original_price_coins': originalPriceCoins,
    'is_active': true,
    'sort_order': sortOrder,
    'catalog_version': catalogVersion,
    'created_at': '2026-07-17T00:00:00Z',
    'updated_at': '2026-07-17T00:00:00Z',
  };
}

Map<String, dynamic> _bundleItemRow(
  String bundleId,
  String itemId,
  String slot,
) {
  return <String, dynamic>{
    'bundle_id': bundleId,
    'item_id': itemId,
    'slot': slot,
  };
}
