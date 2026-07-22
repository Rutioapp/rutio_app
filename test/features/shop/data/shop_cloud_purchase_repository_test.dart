import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_purchase_data_sources.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_purchase_repository.dart';
import 'package:rutio/features/shop/domain/shop_purchase_failure.dart';

void main() {
  group('ShopCloudPurchaseRepository', () {
    test('calls RPC with the expected params and parses the response',
        () async {
      final dataSource = _FakePurchaseDataSource(
        response: <String, dynamic>{
          'requestId': '9f5a1f2a-4a69-4d7c-8cf6-71b0f7df0d8d',
          'operation': 'purchase',
          'itemId': 'utility_xp_boost_1d',
          'priceCoins': 75,
          'coins': 4925,
          'walletVersion': 1,
          'inventoryQuantity': 1,
        },
      );
      final repository = ShopCloudPurchaseRepository(dataSource: dataSource);

      final result = await repository.purchaseShopItem(
        itemId: 'utility_xp_boost_1d',
        requestId: '9f5a1f2a-4a69-4d7c-8cf6-71b0f7df0d8d',
      );

      expect(dataSource.itemIdCalls, ['utility_xp_boost_1d']);
      expect(
          dataSource.requestIdCalls, ['9f5a1f2a-4a69-4d7c-8cf6-71b0f7df0d8d']);
      expect(result.itemId, 'utility_xp_boost_1d');
      expect(result.coins, 4925);
      expect(result.inventoryQuantity, 1);
    });

    test('maps business-rule errors from PostgrestException', () async {
      final repository = ShopCloudPurchaseRepository(
        dataSource: _FakePurchaseDataSource(
          error: const PostgrestException(
            message: 'insufficient wallet balance',
            code: 'P0001',
          ),
        ),
      );

      final future = repository.purchaseShopItem(
        itemId: 'utility_xp_boost_1d',
        requestId: '9f5a1f2a-4a69-4d7c-8cf6-71b0f7df0d8d',
      );

      await expectLater(
        future,
        throwsA(
          isA<ShopCloudPurchaseException>().having(
            (error) => error.code,
            'code',
            ShopPurchaseFailureCode.insufficientFunds,
          ),
        ),
      );
    });

    test('maps network errors and timeouts', () async {
      final networkRepository = ShopCloudPurchaseRepository(
        dataSource: _FakePurchaseDataSource(
          error: const SocketException('network down'),
        ),
      );
      await expectLater(
        networkRepository.purchaseShopItem(
          itemId: 'utility_xp_boost_1d',
          requestId: '9f5a1f2a-4a69-4d7c-8cf6-71b0f7df0d8d',
        ),
        throwsA(
          isA<ShopCloudPurchaseException>().having(
            (error) => error.code,
            'code',
            ShopPurchaseFailureCode.networkUnavailable,
          ),
        ),
      );

      final timeoutRepository = ShopCloudPurchaseRepository(
        timeout: const Duration(milliseconds: 10),
        dataSource: _FakePurchaseDataSource(
          response: Completer<Object?>().future,
        ),
      );
      await expectLater(
        timeoutRepository.purchaseShopItem(
          itemId: 'utility_xp_boost_1d',
          requestId: '9f5a1f2a-4a69-4d7c-8cf6-71b0f7df0d8d',
        ),
        throwsA(
          isA<ShopCloudPurchaseException>().having(
            (error) => error.code,
            'code',
            ShopPurchaseFailureCode.timeout,
          ),
        ),
      );
    });

    test('maps malformed responses to a controlled error', () async {
      final repository = ShopCloudPurchaseRepository(
        dataSource: _FakePurchaseDataSource(
          response: <String, dynamic>{
            'requestId': '9f5a1f2a-4a69-4d7c-8cf6-71b0f7df0d8d',
            'operation': 'purchase',
            'itemId': 'utility_xp_boost_1d',
            'coins': 4925,
          },
        ),
      );

      await expectLater(
        repository.purchaseShopItem(
          itemId: 'utility_xp_boost_1d',
          requestId: '9f5a1f2a-4a69-4d7c-8cf6-71b0f7df0d8d',
        ),
        throwsA(
          isA<ShopCloudPurchaseException>().having(
            (error) => error.code,
            'code',
            ShopPurchaseFailureCode.malformedResponse,
          ),
        ),
      );
    });

    test('purchases bundles and parses the result', () async {
      final dataSource = _FakePurchaseDataSource(
        bundleResponse: <String, dynamic>{
          'request_id': 'd2b5d4d7-6b8e-4f28-9c33-8e0d0c1cb001',
          'bundle_id': 'pack_beige_rutio',
          'user_id': 'd1b5d4d7-6b8e-4f28-9c33-8e0d0c1cb002',
          'coins_delta': -325,
          'wallet_coins_after': 675,
          'wallpaper_item_id': 'wallpaper_rutio_beige',
          'habit_card_item_id': 'habit_card_warm_beige',
          'user_card_item_id': 'user_card_warm_beige',
          'is_idempotent': true,
          'created_at': '2026-07-22T12:00:00Z',
        },
      );
      final repository = ShopCloudPurchaseRepository(dataSource: dataSource);

      final result = await repository.purchaseShopBundle(
        bundleId: 'pack_beige_rutio',
        requestId: 'd2b5d4d7-6b8e-4f28-9c33-8e0d0c1cb001',
      );

      expect(dataSource.bundleIdCalls, ['pack_beige_rutio']);
      expect(
        dataSource.bundleRequestIdCalls,
        ['d2b5d4d7-6b8e-4f28-9c33-8e0d0c1cb001'],
      );
      expect(result.bundleId, 'pack_beige_rutio');
      expect(result.walletCoinsAfter, 675);
      expect(result.isIdempotent, isTrue);
    });

    test('maps bundle-specific RPC errors', () async {
      final repository = ShopCloudPurchaseRepository(
        dataSource: _FakePurchaseDataSource(
          error: const PostgrestException(
            message: 'bundle contains owned items',
            code: 'P0001',
          ),
        ),
      );

      await expectLater(
        repository.purchaseShopBundle(
          bundleId: 'pack_beige_rutio',
          requestId: 'd2b5d4d7-6b8e-4f28-9c33-8e0d0c1cb001',
        ),
        throwsA(
          isA<ShopCloudPurchaseException>().having(
            (error) => error.code,
            'code',
            ShopPurchaseFailureCode.bundleContainsOwnedItems,
          ),
        ),
      );
    });
  });
}

class _FakePurchaseDataSource implements ShopCloudPurchaseDataSource {
  _FakePurchaseDataSource({
    this.response,
    this.bundleResponse,
    this.error,
  });

  final Object? response;
  final Object? bundleResponse;
  final Object? error;
  final List<String> itemIdCalls = <String>[];
  final List<String> requestIdCalls = <String>[];
  final List<String> bundleIdCalls = <String>[];
  final List<String> bundleRequestIdCalls = <String>[];

  @override
  Future<Object?> purchaseShopItem({
    required String itemId,
    required String requestId,
  }) async {
    itemIdCalls.add(itemId);
    requestIdCalls.add(requestId);
    if (error != null) {
      throw error!;
    }
    if (response is Future<Object?>) {
      return response;
    }
    return response;
  }

  @override
  Future<Object?> purchaseShopBundle({
    required String bundleId,
    required String requestId,
  }) async {
    bundleIdCalls.add(bundleId);
    bundleRequestIdCalls.add(requestId);
    if (error != null) {
      throw error!;
    }
    if (bundleResponse is Future<Object?>) {
      return bundleResponse;
    }
    return bundleResponse;
  }
}
