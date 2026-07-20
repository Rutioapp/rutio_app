import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/rutio_supabase_client.dart';

abstract class ShopCloudEquipDataSource {
  Future<Object?> equipShopCosmetic({
    required String itemId,
    required String requestId,
  });
}

class SupabaseShopCloudEquipDataSource implements ShopCloudEquipDataSource {
  SupabaseShopCloudEquipDataSource({SupabaseClient? client})
      : _client = client;

  final SupabaseClient? _client;

  SupabaseClient get _clientOrInstance =>
      _client ?? RutioSupabaseClient.instance;

  @override
  Future<Object?> equipShopCosmetic({
    required String itemId,
    required String requestId,
  }) {
    return _clientOrInstance.rpc(
      'equip_shop_cosmetic',
      params: <String, dynamic>{
        'p_item_id': itemId,
        'p_request_id': requestId,
      },
    );
  }
}
