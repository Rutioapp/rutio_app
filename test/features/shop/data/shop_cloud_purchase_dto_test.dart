import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_purchase_dtos.dart';

void main() {
  group('RemoteShopPurchaseResultDto', () {
    test('parses a valid purchase response', () {
      final dto = RemoteShopPurchaseResultDto.fromRpcResponse(
        <String, dynamic>{
          'requestId': '9f5a1f2a-4a69-4d7c-8cf6-71b0f7df0d8d',
          'operation': 'purchase',
          'itemId': 'utility_xp_boost_1d',
          'priceCoins': 75,
          'coins': 4925,
          'walletVersion': 1,
          'inventoryQuantity': 1,
        },
        requestedItemId: 'utility_xp_boost_1d',
        requestId: '9f5a1f2a-4a69-4d7c-8cf6-71b0f7df0d8d',
      );

      expect(dto.itemId, 'utility_xp_boost_1d');
      expect(dto.priceCoins, 75);
      expect(dto.coins, 4925);
      expect(dto.walletVersion, 1);
      expect(dto.inventoryQuantity, 1);
    });

    test('rejects invalid requestId and malformed JSON', () {
      expect(
        () => RemoteShopPurchaseResultDto.fromRpcResponse(
          <String, dynamic>{
            'requestId': 'not-a-uuid',
            'operation': 'purchase',
            'itemId': 'utility_xp_boost_1d',
            'priceCoins': 75,
            'coins': 4925,
            'walletVersion': 1,
            'inventoryQuantity': 1,
          },
          requestedItemId: 'utility_xp_boost_1d',
          requestId: 'not-a-uuid',
        ),
        throwsFormatException,
      );

      expect(
        () => RemoteShopPurchaseResultDto.fromRpcResponse(
          <String, dynamic>{
            'requestId': '9f5a1f2a-4a69-4d7c-8cf6-71b0f7df0d8d',
            'operation': 'equip',
            'itemId': 'utility_xp_boost_1d',
            'priceCoins': 75,
            'coins': 4925,
            'walletVersion': 1,
            'inventoryQuantity': 1,
          },
          requestedItemId: 'utility_xp_boost_1d',
          requestId: '9f5a1f2a-4a69-4d7c-8cf6-71b0f7df0d8d',
        ),
        throwsFormatException,
      );

      expect(
        () => RemoteShopPurchaseResultDto.fromRpcResponse(
          <String, dynamic>{
            'requestId': '9f5a1f2a-4a69-4d7c-8cf6-71b0f7df0d8d',
            'operation': 'purchase',
            'itemId': 'utility_coin_boost_1d',
            'priceCoins': 75,
            'coins': 4925,
            'walletVersion': 1,
            'inventoryQuantity': 1,
          },
          requestedItemId: 'utility_xp_boost_1d',
          requestId: '9f5a1f2a-4a69-4d7c-8cf6-71b0f7df0d8d',
        ),
        throwsFormatException,
      );
    });

    test('rejects negative values and incomplete payloads', () {
      expect(
        () => RemoteShopPurchaseResultDto.fromRpcResponse(
          <String, dynamic>{
            'requestId': '9f5a1f2a-4a69-4d7c-8cf6-71b0f7df0d8d',
            'operation': 'purchase',
            'itemId': 'utility_xp_boost_1d',
            'priceCoins': -1,
            'coins': 4925,
            'walletVersion': 1,
            'inventoryQuantity': 1,
          },
          requestedItemId: 'utility_xp_boost_1d',
          requestId: '9f5a1f2a-4a69-4d7c-8cf6-71b0f7df0d8d',
        ),
        throwsFormatException,
      );

      expect(
        () => RemoteShopPurchaseResultDto.fromRpcResponse(
          <String, dynamic>{
            'requestId': '9f5a1f2a-4a69-4d7c-8cf6-71b0f7df0d8d',
            'operation': 'purchase',
            'itemId': 'utility_xp_boost_1d',
            'priceCoins': 75,
            'coins': -1,
            'walletVersion': 1,
            'inventoryQuantity': 1,
          },
          requestedItemId: 'utility_xp_boost_1d',
          requestId: '9f5a1f2a-4a69-4d7c-8cf6-71b0f7df0d8d',
        ),
        throwsFormatException,
      );

      expect(
        () => RemoteShopPurchaseResultDto.fromRpcResponse(
          <String, dynamic>{
            'requestId': '9f5a1f2a-4a69-4d7c-8cf6-71b0f7df0d8d',
            'operation': 'purchase',
            'itemId': 'utility_xp_boost_1d',
            'priceCoins': 75,
            'coins': 4925,
            'walletVersion': -1,
            'inventoryQuantity': 1,
          },
          requestedItemId: 'utility_xp_boost_1d',
          requestId: '9f5a1f2a-4a69-4d7c-8cf6-71b0f7df0d8d',
        ),
        throwsFormatException,
      );

      expect(
        () => RemoteShopPurchaseResultDto.fromRpcResponse(
          <String, dynamic>{
            'requestId': '9f5a1f2a-4a69-4d7c-8cf6-71b0f7df0d8d',
            'operation': 'purchase',
            'itemId': 'utility_xp_boost_1d',
            'priceCoins': 75,
            'coins': 4925,
            'walletVersion': 1,
            'inventoryQuantity': 0,
          },
          requestedItemId: 'utility_xp_boost_1d',
          requestId: '9f5a1f2a-4a69-4d7c-8cf6-71b0f7df0d8d',
        ),
        throwsFormatException,
      );

      expect(
        () => RemoteShopPurchaseResultDto.fromRpcResponse(
          <String, dynamic>{
            'requestId': '9f5a1f2a-4a69-4d7c-8cf6-71b0f7df0d8d',
            'operation': 'purchase',
            'itemId': 'utility_xp_boost_1d',
            'priceCoins': 75,
            'coins': 4925,
          },
          requestedItemId: 'utility_xp_boost_1d',
          requestId: '9f5a1f2a-4a69-4d7c-8cf6-71b0f7df0d8d',
        ),
        throwsFormatException,
      );
    });
  });

  group('RemoteShopBundlePurchaseResultDto', () {
    test('parses a valid bundle purchase response', () {
      final dto = RemoteShopBundlePurchaseResultDto.fromRpcResponse(
        <String, dynamic>{
          'request_id': 'd2b5d4d7-6b8e-4f28-9c33-8e0d0c1cb001',
          'bundle_id': 'pack_beige_rutio',
          'user_id': 'd1b5d4d7-6b8e-4f28-9c33-8e0d0c1cb002',
          'coins_delta': -325,
          'wallet_coins_after': 675,
          'wallpaper_item_id': 'wallpaper_rutio_beige',
          'habit_card_item_id': 'habit_card_warm_beige',
          'user_card_item_id': 'user_card_warm_beige',
          'is_idempotent': false,
          'created_at': '2026-07-22T12:00:00Z',
        },
        requestedBundleId: 'pack_beige_rutio',
        requestId: 'd2b5d4d7-6b8e-4f28-9c33-8e0d0c1cb001',
      );

      expect(dto.bundleId, 'pack_beige_rutio');
      expect(dto.userId, 'd1b5d4d7-6b8e-4f28-9c33-8e0d0c1cb002');
      expect(dto.coinsDelta, -325);
      expect(dto.walletCoinsAfter, 675);
      expect(dto.isIdempotent, isFalse);
    });

    test('rejects snake_case mismatch and invalid cosmetic ids', () {
      expect(
        () => RemoteShopBundlePurchaseResultDto.fromRpcResponse(
          <String, dynamic>{
            'request_id': 'd2b5d4d7-6b8e-4f28-9c33-8e0d0c1cb001',
            'bundle_id': 'pack_beige_rutio',
            'user_id': 'd1b5d4d7-6b8e-4f28-9c33-8e0d0c1cb002',
            'coins_delta': -325,
            'wallet_coins_after': 675,
            'wallpaper_item_id': 'wallpaper_rutio_beige',
            'habit_card_item_id': 'habit_card_warm_beige',
            'user_card_item_id': 'habit_card_warm_beige',
            'is_idempotent': false,
            'created_at': '2026-07-22T12:00:00Z',
          },
          requestedBundleId: 'pack_beige_rutio',
          requestId: 'd2b5d4d7-6b8e-4f28-9c33-8e0d0c1cb001',
        ),
        throwsFormatException,
      );

      expect(
        () => RemoteShopBundlePurchaseResultDto.fromRpcResponse(
          <String, dynamic>{
            'request_id': 'd2b5d4d7-6b8e-4f28-9c33-8e0d0c1cb001',
            'bundle_id': 'pack_other',
            'user_id': 'd1b5d4d7-6b8e-4f28-9c33-8e0d0c1cb002',
            'coins_delta': -325,
            'wallet_coins_after': 675,
            'wallpaper_item_id': 'wallpaper_rutio_beige',
            'habit_card_item_id': 'habit_card_warm_beige',
            'user_card_item_id': 'user_card_warm_beige',
            'is_idempotent': false,
            'created_at': '2026-07-22T12:00:00Z',
          },
          requestedBundleId: 'pack_beige_rutio',
          requestId: 'd2b5d4d7-6b8e-4f28-9c33-8e0d0c1cb001',
        ),
        throwsFormatException,
      );
    });
  });
}
