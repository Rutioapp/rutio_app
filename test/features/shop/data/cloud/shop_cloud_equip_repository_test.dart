import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_equip_data_sources.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_equip_repository.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';

void main() {
  group('SupabaseShopCloudEquipDataSource', () {
    test('sends the exact rpc params expected by Supabase', () async {
      Map<String, dynamic>? capturedParams;
      String? capturedFunction;
      final dataSource = SupabaseShopCloudEquipDataSource.test(
        rpcInvoker: (String function,
            {required Map<String, dynamic> params}) async {
          capturedFunction = function;
          capturedParams = params;
          return <String, dynamic>{
            'requestId': 'req-1',
            'operation': 'equip',
            'itemId': 'wallpaper_mist_blue',
            'slot': 'screen_background',
            'createdAt': '2026-07-19T12:00:00Z',
          };
        },
      );

      final response = await dataSource.equipShopCosmetic(
        itemId: 'wallpaper_mist_blue',
        slot: CosmeticSlot.background.remoteDbKey,
        requestId: 'req-1',
      );

      expect(capturedFunction, 'equip_shop_cosmetic');
      expect(
        capturedParams,
        equals(<String, dynamic>{
          'p_item_id': 'wallpaper_mist_blue',
          'p_slot': 'screen_background',
          'p_request_id': 'req-1',
        }),
      );
      expect(response, isA<Map<String, dynamic>>());
    });
  });

  group('ShopCloudEquipRepository', () {
    test('forwards slot to the data source and parses the result', () async {
      final dataSource = _FakeEquipDataSource(
        response: <String, dynamic>{
          'requestId': 'req-1',
          'operation': 'equip',
          'itemId': 'wallpaper_mist_blue',
          'slot': 'screen_background',
          'createdAt': '2026-07-19T12:00:00Z',
        },
      );
      final repository = ShopCloudEquipRepository(dataSource: dataSource);

      final result = await repository.equipShopCosmetic(
        itemId: 'wallpaper_mist_blue',
        slot: CosmeticSlot.background.remoteDbKey,
        requestId: 'req-1',
      );

      expect(
          dataSource.calls.single,
          equals(<String, String>{
            'itemId': 'wallpaper_mist_blue',
            'slot': 'screen_background',
            'requestId': 'req-1',
          }));
      expect(result.itemId, 'wallpaper_mist_blue');
      expect(result.slot, 'screen_background');
    });

    test('keeps the same requestId stable across repeated calls', () async {
      final dataSource = _FakeEquipDataSource(
        response: <String, dynamic>{
          'requestId': 'req-1',
          'operation': 'equip',
          'itemId': 'wallpaper_mist_blue',
          'slot': 'screen_background',
          'createdAt': '2026-07-19T12:00:00Z',
        },
      );
      final repository = ShopCloudEquipRepository(dataSource: dataSource);

      final first = await repository.equipShopCosmetic(
        itemId: 'wallpaper_mist_blue',
        slot: CosmeticSlot.background.remoteDbKey,
        requestId: 'req-1',
      );
      final second = await repository.equipShopCosmetic(
        itemId: 'wallpaper_mist_blue',
        slot: CosmeticSlot.background.remoteDbKey,
        requestId: 'req-1',
      );

      expect(first.requestId, 'req-1');
      expect(second.requestId, 'req-1');
      expect(dataSource.calls.map((call) => call['requestId']),
          everyElement('req-1'));
      expect(dataSource.calls, hasLength(2));
    });

    test('maps business-rule errors from PostgrestException', () async {
      await expectLater(
        _repositoryWithError(
          const PostgrestException(
            message: 'INVALID_EQUIP_SLOT',
            code: 'P0001',
          ),
        ).equipShopCosmetic(
          itemId: 'wallpaper_mist_blue',
          slot: CosmeticSlot.background.remoteDbKey,
          requestId: 'req-1',
        ),
        throwsA(
          isA<ShopCloudEquipException>().having(
            (error) => error.code,
            'code',
            ShopCosmeticsOperationFailureCode.invalidEquipSlot,
          ),
        ),
      );

      await expectLater(
        _repositoryWithError(
          const PostgrestException(
            message: 'request_id already used by another user',
            code: '23505',
          ),
        ).equipShopCosmetic(
          itemId: 'wallpaper_mist_blue',
          slot: CosmeticSlot.background.remoteDbKey,
          requestId: 'req-1',
        ),
        throwsA(
          isA<ShopCloudEquipException>().having(
            (error) => error.code,
            'code',
            ShopCosmeticsOperationFailureCode.requestConflict,
          ),
        ),
      );

      await expectLater(
        _repositoryWithError(
          const PostgrestException(
            message: 'UNAUTHENTICATED',
            code: 'P0001',
          ),
        ).equipShopCosmetic(
          itemId: 'wallpaper_mist_blue',
          slot: CosmeticSlot.background.remoteDbKey,
          requestId: 'req-1',
        ),
        throwsA(
          isA<ShopCloudEquipException>().having(
            (error) => error.code,
            'code',
            ShopCosmeticsOperationFailureCode.unauthenticated,
          ),
        ),
      );
    });

    test('treats a mismatched slot response as malformed', () async {
      final repository = ShopCloudEquipRepository(
        dataSource: _FakeEquipDataSource(
          response: <String, dynamic>{
            'requestId': 'req-1',
            'operation': 'equip',
            'itemId': 'wallpaper_mist_blue',
            'slot': 'habit_card_background',
            'createdAt': '2026-07-19T12:00:00Z',
          },
        ),
      );

      await expectLater(
        repository.equipShopCosmetic(
          itemId: 'wallpaper_mist_blue',
          slot: CosmeticSlot.background.remoteDbKey,
          requestId: 'req-1',
        ),
        throwsA(
          isA<ShopCloudEquipException>().having(
            (error) => error.code,
            'code',
            ShopCosmeticsOperationFailureCode.malformedResponse,
          ),
        ),
      );
    });

    test('accepts wrapped snake_case rpc payloads from Supabase', () async {
      final repository = ShopCloudEquipRepository(
        dataSource: _FakeEquipDataSource(
          response: <String, dynamic>{
            'data': <String, dynamic>{
              'request_id': 'req-1',
              'operation': 'equip',
              'item_id': 'wallpaper_mist_blue',
              'slot': 'screen_background',
            },
          },
        ),
      );

      final result = await repository.equipShopCosmetic(
        itemId: 'wallpaper_mist_blue',
        slot: CosmeticSlot.background.remoteDbKey,
        requestId: 'req-1',
      );

      expect(result.requestId, 'req-1');
      expect(result.operation, 'equip');
      expect(result.itemId, 'wallpaper_mist_blue');
      expect(result.slot, 'screen_background');
      expect(result.createdAt, isA<DateTime>());
    });
  });
}

ShopCloudEquipRepository _repositoryWithError(Object error) {
  return ShopCloudEquipRepository(
    dataSource: _FakeEquipDataSource(error: error),
  );
}

class _FakeEquipDataSource implements ShopCloudEquipDataSource {
  _FakeEquipDataSource({
    this.response,
    this.error,
  });

  final Object? response;
  final Object? error;
  final List<Map<String, String>> calls = <Map<String, String>>[];

  @override
  Future<Object?> equipShopCosmetic({
    required String itemId,
    required String slot,
    required String requestId,
  }) async {
    calls.add(<String, String>{
      'itemId': itemId,
      'slot': slot,
      'requestId': requestId,
    });
    if (error != null) {
      throw error!;
    }
    if (response is Future<Object?>) {
      return response;
    }
    return response;
  }
}
