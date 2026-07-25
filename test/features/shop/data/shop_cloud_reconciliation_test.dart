import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_dtos.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_errors.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_reconciliation.dart';
import 'package:rutio/features/shop/data/shop_assets_catalog.dart';
import 'package:rutio/features/shop/domain/models/shop_bundle.dart';

void main() {
  group('ShopCloudCatalogReconciler', () {
    test('recognizes the five remote utilities and flags missing local items',
        () {
      final remoteItems = <RemoteShopItemDto>[
        _utility('utility_xp_boost_1d', 75, 'xpBoost'),
        _utility('utility_coin_boost_1d', 100, 'coinBoost'),
        _utility('utility_streak_recover_1', 250, 'streakRecover'),
        _utility('utility_streak_shield_1', 300, 'streakShield'),
        _utility('utility_mystery_box_basic', 100, 'mysteryBox'),
      ];

      final reconciliation = ShopCloudCatalogReconciler.reconcile(
        remoteItems: remoteItems,
      );

      expect(reconciliation.knownItemIds, hasLength(5));
      expect(reconciliation.unknownRemoteItemIds, isEmpty);
      expect(reconciliation.missingLocalItemIds, isNotEmpty);
      expect(reconciliation.warnings, isNotEmpty);
    });

    test('detects price and configuration mismatches without mutating input',
        () {
      final remoteItems = <RemoteShopItemDto>[
        _utility(
          'utility_xp_boost_1d',
          999,
          'xpBoost',
          isStackable: false,
          assetKey: 'assets/shop/utilities/incorrect.png',
          isActive: false,
        ),
      ];
      final original = List<RemoteShopItemDto>.from(remoteItems);

      final reconciliation = ShopCloudCatalogReconciler.reconcile(
        remoteItems: remoteItems,
      );

      expect(
          reconciliation.priceMismatchItemIds, contains('utility_xp_boost_1d'));
      expect(
        reconciliation.configurationMismatchItemIds,
        contains('utility_xp_boost_1d'),
      );
      final warning = reconciliation.warnings.firstWhere(
        (warning) =>
            warning.code == ShopCloudWarningCode.configMismatch &&
            warning.itemId == 'utility_xp_boost_1d',
      );
      expect(warning.details['remoteAssetKey'],
          'assets/shop/utilities/incorrect.png');
      expect(warning.details['remoteIsActive'], isFalse);
      expect(remoteItems, equals(original));
    });

    test('flags unknown remote ids', () {
      final reconciliation = ShopCloudCatalogReconciler.reconcile(
        remoteItems: <RemoteShopItemDto>[
          _utility('utility_xp_boost_1d', 75, 'xpBoost'),
          _utility('remote_only_item', 20, 'xpBoost'),
        ],
      );

      expect(reconciliation.unknownRemoteItemIds, contains('remote_only_item'));
      expect(
        reconciliation.warnings.any(
          (warning) =>
              warning.code == ShopCloudWarningCode.remoteUnknownCatalogId,
        ),
        isTrue,
      );
    });
  });

  group('ShopCloudBundleCatalogReconciler', () {
    test('flags remote-only bundles and keeps known compositions', () {
      final localBundles = <ShopBundle>[
        ShopAssetsCatalog.getBundleById('pack_beige_rutio')!,
      ];
      final reconciliation = ShopCloudBundleCatalogReconciler.reconcile(
        remoteBundles: <RemoteShopBundleDto>[
          _bundle('pack_beige_rutio', priceCoins: 300),
          _bundle(
            'remote_only_pack',
            priceCoins: 444,
            originalPriceCoins: 500,
          ),
        ],
        remoteCompositionByBundleId: <String, List<RemoteShopBundleItemDto>>{
          'pack_beige_rutio': <RemoteShopBundleItemDto>[
            _bundleItem(
              'pack_beige_rutio',
              'wallpaper_rutio_beige',
              'screen_background',
            ),
            _bundleItem(
              'pack_beige_rutio',
              'habit_card_warm_beige',
              'habit_card_background',
            ),
            _bundleItem(
              'pack_beige_rutio',
              'user_card_warm_beige',
              'user_card_background',
            ),
          ],
        },
        localBundles: localBundles,
      );

      expect(reconciliation.knownBundleIds, contains('pack_beige_rutio'));
      expect(
        reconciliation.unknownRemoteBundleIds,
        contains('remote_only_pack'),
      );
      expect(reconciliation.warnings.any((warning) {
        return warning.code == ShopCloudWarningCode.remoteUnknownCatalogId &&
            warning.itemId == 'remote_only_pack';
      }), isTrue);
    });

    test('detects bundle composition mismatches without price warnings', () {
      final bundle = ShopAssetsCatalog.getBundleById('pack_beige_rutio')!;
      final reconciliation = ShopCloudBundleCatalogReconciler.reconcile(
        remoteBundles: <RemoteShopBundleDto>[
          _bundle(
            bundle.id,
            priceCoins: 999,
            originalPriceCoins: 1111,
          ),
        ],
        remoteCompositionByBundleId: <String, List<RemoteShopBundleItemDto>>{
          bundle.id: <RemoteShopBundleItemDto>[
            _bundleItem(
              bundle.id,
              'wallpaper_rutio_beige',
              'screen_background',
            ),
            _bundleItem(
              bundle.id,
              'habit_card_warm_beige',
              'habit_card_background',
            ),
            _bundleItem(
              bundle.id,
              'user_card_soft_camel',
              'user_card_background',
            ),
          ],
        },
      );

      expect(
        reconciliation.compositionMismatchBundleIds,
        contains(bundle.id),
      );
      final warning = reconciliation.warnings.firstWhere(
        (warning) =>
            warning.code == ShopCloudWarningCode.configMismatch &&
            warning.itemId == bundle.id,
      );
      expect(
          warning.details['localAssetIds'], contains('user_card_warm_beige'));
      expect(
          warning.details['remoteAssetIds'], contains('user_card_soft_camel'));
    });
  });
}

RemoteShopItemDto _utility(
  String id,
  int priceCoins,
  String subtype, {
  bool isStackable = true,
  String? assetKey,
  bool isActive = true,
}) {
  return RemoteShopItemDto.fromJson(<String, dynamic>{
    'id': id,
    'category': 'utility',
    'subtype': subtype,
    'rarity': null,
    'priceCoins': priceCoins,
    'isConsumable': true,
    'isStackable': isStackable,
    'maxQuantity': null,
    'equipSlot': null,
    'assetKey': assetKey ?? 'assets/shop/utilities/$id.png',
    'localizationKey': 'key_$id',
    'isActive': isActive,
    'sortOrder': 0,
    'catalogVersion': 1,
    'createdAt': '2026-07-17T00:00:00Z',
    'updatedAt': '2026-07-17T00:00:00Z',
  });
}

RemoteShopBundleDto _bundle(
  String id, {
  int priceCoins = 300,
  int originalPriceCoins = 330,
}) {
  return RemoteShopBundleDto.fromJson(<String, dynamic>{
    'id': id,
    'family_id': id,
    'rarity': 'common',
    'price_coins': priceCoins,
    'original_price_coins': originalPriceCoins,
    'is_active': true,
    'sort_order': 0,
    'catalog_version': 1,
    'created_at': '2026-07-17T00:00:00Z',
    'updated_at': '2026-07-17T00:00:00Z',
  });
}

RemoteShopBundleItemDto _bundleItem(
  String bundleId,
  String itemId,
  String slot,
) {
  return RemoteShopBundleItemDto.fromJson(<String, dynamic>{
    'bundle_id': bundleId,
    'item_id': itemId,
    'slot': slot,
  });
}
