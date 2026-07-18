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
}
