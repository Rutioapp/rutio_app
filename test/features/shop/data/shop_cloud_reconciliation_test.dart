import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_dtos.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_errors.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_reconciliation.dart';

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
        _utility('utility_xp_boost_1d', 999, 'xpBoost', isStackable: false),
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
}

RemoteShopItemDto _utility(
  String id,
  int priceCoins,
  String subtype, {
  bool isStackable = true,
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
    'assetKey': 'assets/shop/utilities/$id.png',
    'localizationKey': 'key_$id',
    'isActive': true,
    'sortOrder': 0,
    'catalogVersion': 1,
    'createdAt': '2026-07-17T00:00:00Z',
    'updatedAt': '2026-07-17T00:00:00Z',
  });
}
