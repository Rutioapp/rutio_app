import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/data/cloud/pending_cloud_cosmetics_purchase_store.dart';
import 'package:rutio/features/shop/domain/models/pending_cloud_cosmetics_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPreferencesPendingCloudCosmeticsPurchaseStore', () {
    test('saves, loads, updates, and removes pending purchases', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final store = SharedPreferencesPendingCloudCosmeticsPurchaseStore();
      final pending = _pending(
        userId: 'user-a',
        requestId: 'request-a',
        operationType: PendingCloudCosmeticsPurchaseType.cosmeticPurchase,
        resourceId: 'wallpaper_mist_blue',
      );

      await store
          .savePendingPurchases('user-a', <PendingCloudCosmeticsPurchase>[
        pending,
      ]);

      var loaded = await store.loadPendingPurchases('user-a');
      expect(loaded, hasLength(1));
      expect(loaded.single.requestId, 'request-a');
      expect(loaded.single.logicalKey, 'cosmetic:wallpaper_mist_blue');

      await store
          .savePendingPurchases('user-a', <PendingCloudCosmeticsPurchase>[
        pending.copyWith(
          status: PendingCloudCosmeticsPurchaseStatus.awaitingResolution,
          updatedAtMillis: 2,
          lastFailureCode: 'timeout',
        ),
      ]);

      loaded = await store.loadPendingPurchases('user-a');
      expect(loaded.single.status,
          PendingCloudCosmeticsPurchaseStatus.awaitingResolution);
      expect(loaded.single.lastFailureCode, 'timeout');

      await store.clearPendingPurchases('user-a');
      expect(await store.loadPendingPurchases('user-a'), isEmpty);
    });

    test('keeps users isolated', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final store = SharedPreferencesPendingCloudCosmeticsPurchaseStore();

      await store
          .savePendingPurchases('user-a', <PendingCloudCosmeticsPurchase>[
        _pending(userId: 'user-a', requestId: 'request-a'),
      ]);
      await store
          .savePendingPurchases('user-b', <PendingCloudCosmeticsPurchase>[
        _pending(userId: 'user-b', requestId: 'request-b'),
      ]);

      expect((await store.loadPendingPurchases('user-a')).single.requestId,
          'request-a');
      expect((await store.loadPendingPurchases('user-b')).single.requestId,
          'request-b');
    });

    test('cosmetic and bundle with the same id do not collide', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final store = SharedPreferencesPendingCloudCosmeticsPurchaseStore();

      await store
          .savePendingPurchases('user-a', <PendingCloudCosmeticsPurchase>[
        _pending(
          userId: 'user-a',
          requestId: 'request-cosmetic',
          operationType: PendingCloudCosmeticsPurchaseType.cosmeticPurchase,
          resourceId: 'shared-id',
        ),
        _pending(
          userId: 'user-a',
          requestId: 'request-bundle',
          operationType: PendingCloudCosmeticsPurchaseType.bundlePurchase,
          resourceId: 'shared-id',
        ),
      ]);

      final loaded = await store.loadPendingPurchases('user-a');
      expect(
          loaded.map((entry) => entry.logicalKey),
          containsAll(<String>[
            'cosmetic:shared-id',
            'bundle:shared-id',
          ]));
    });

    test('ignores corrupt rows and rows for a different user', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'rutio_shop_cosmetics_pending_operations_v1_user-a':
            '[{"userId":"user-b","requestId":"wrong","operationType":"cosmeticPurchase","resourceId":"x","createdAtMillis":1,"updatedAtMillis":1,"status":"pending"},"broken",{"userId":"user-a"}]',
      });
      final store = SharedPreferencesPendingCloudCosmeticsPurchaseStore();

      expect(await store.loadPendingPurchases('user-a'), isEmpty);
    });

    test('survives recreating the store', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await SharedPreferencesPendingCloudCosmeticsPurchaseStore()
          .savePendingPurchases('user-a', <PendingCloudCosmeticsPurchase>[
        _pending(userId: 'user-a', requestId: 'request-a'),
      ]);

      final recreated = SharedPreferencesPendingCloudCosmeticsPurchaseStore();

      expect((await recreated.loadPendingPurchases('user-a')).single.requestId,
          'request-a');
    });
  });
}

PendingCloudCosmeticsPurchase _pending({
  String userId = 'user-a',
  String requestId = 'request-id',
  PendingCloudCosmeticsPurchaseType operationType =
      PendingCloudCosmeticsPurchaseType.cosmeticPurchase,
  String resourceId = 'wallpaper_mist_blue',
}) {
  return PendingCloudCosmeticsPurchase(
    userId: userId,
    requestId: requestId,
    operationType: operationType,
    resourceId: resourceId,
    createdAtMillis: 1,
    updatedAtMillis: 1,
    status: PendingCloudCosmeticsPurchaseStatus.pending,
  );
}
