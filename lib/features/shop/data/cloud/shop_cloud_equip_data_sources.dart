import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/rutio_supabase_client.dart';

typedef ShopCloudEquipRpcInvoker = Future<Object?> Function(
  String function, {
  required Map<String, dynamic> params,
});

abstract class ShopCloudEquipDataSource {
  Future<Object?> equipShopCosmetic({
    required String itemId,
    required String slot,
    required String requestId,
  });
}

class SupabaseShopCloudEquipDataSource implements ShopCloudEquipDataSource {
  SupabaseShopCloudEquipDataSource({SupabaseClient? client})
      : _client = client,
        _rpcInvoker = null;

  SupabaseShopCloudEquipDataSource.test({
    required ShopCloudEquipRpcInvoker rpcInvoker,
  })  : _client = null,
        _rpcInvoker = rpcInvoker;

  final SupabaseClient? _client;
  final ShopCloudEquipRpcInvoker? _rpcInvoker;

  SupabaseClient get _clientOrInstance =>
      _client ?? RutioSupabaseClient.instance;

  @override
  Future<Object?> equipShopCosmetic({
    required String itemId,
    required String slot,
    required String requestId,
  }) {
    final rpcInvoker = _rpcInvoker;
    if (rpcInvoker != null) {
      return rpcInvoker(
        'equip_shop_cosmetic',
        params: <String, dynamic>{
          'p_item_id': itemId,
          'p_slot': slot,
          'p_request_id': requestId,
        },
      );
    }

    return _clientOrInstance.rpc(
      'equip_shop_cosmetic',
      params: <String, dynamic>{
        'p_item_id': itemId,
        'p_slot': slot,
        'p_request_id': requestId,
      },
    );
  }
}
