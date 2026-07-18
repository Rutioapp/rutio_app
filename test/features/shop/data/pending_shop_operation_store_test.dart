import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/data/pending_shop_operation_store.dart';
import 'package:rutio/features/shop/domain/models/pending_shop_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SharedPreferencesPendingShopOperationStore', () {
    late SharedPreferencesPendingShopOperationStore store;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      store = SharedPreferencesPendingShopOperationStore();
    });

    test('saves and loads pending purchases per user', () async {
      final pending = PendingShopPurchase(
        userId: 'user-1',
        requestId: 'req-1',
        itemId: 'utility_xp_boost_1d',
        createdAtMillis: 10,
        lastAttemptAtMillis: 11,
        attemptCount: 1,
        status: PendingShopPurchaseStatus.pending,
      );

      await store
          .savePendingPurchases('user-1', <PendingShopPurchase>[pending]);

      final loaded = await store.loadPendingPurchases('user-1');

      expect(loaded, hasLength(1));
      expect(loaded.single.requestId, 'req-1');
      expect(await store.loadPendingPurchases('user-2'), isEmpty);
    });

    test('does not mix users and persists after recreation', () async {
      final first = PendingShopPurchase(
        userId: 'user-1',
        requestId: 'req-1',
        itemId: 'utility_xp_boost_1d',
        createdAtMillis: 10,
        lastAttemptAtMillis: 11,
        attemptCount: 1,
        status: PendingShopPurchaseStatus.pending,
      );
      final second = PendingShopPurchase(
        userId: 'user-2',
        requestId: 'req-2',
        itemId: 'utility_coin_boost_1d',
        createdAtMillis: 20,
        lastAttemptAtMillis: 21,
        attemptCount: 1,
        status: PendingShopPurchaseStatus.awaitingResolution,
      );

      await store.savePendingPurchases('user-1', <PendingShopPurchase>[first]);
      await store.savePendingPurchases('user-2', <PendingShopPurchase>[second]);

      store = SharedPreferencesPendingShopOperationStore();

      final user1 = await store.loadPendingPurchases('user-1');
      final user2 = await store.loadPendingPurchases('user-2');

      expect(user1.single.requestId, 'req-1');
      expect(user2.single.requestId, 'req-2');
    });

    test('clear removes a user bucket only', () async {
      final pending = PendingShopPurchase(
        userId: 'user-1',
        requestId: 'req-1',
        itemId: 'utility_xp_boost_1d',
        createdAtMillis: 10,
        lastAttemptAtMillis: 11,
        attemptCount: 1,
        status: PendingShopPurchaseStatus.pending,
      );
      await store
          .savePendingPurchases('user-1', <PendingShopPurchase>[pending]);
      await store.clearPendingPurchases('user-1');

      expect(await store.loadPendingPurchases('user-1'), isEmpty);
    });
  });
}
