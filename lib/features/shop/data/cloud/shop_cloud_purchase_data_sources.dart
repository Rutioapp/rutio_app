import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/rutio_supabase_client.dart';

abstract class ShopCloudPurchaseDataSource {
  Future<Object?> purchaseShopItem({
    required String itemId,
    required String requestId,
  });
}

class SupabaseShopCloudPurchaseDataSource
    implements ShopCloudPurchaseDataSource {
  SupabaseShopCloudPurchaseDataSource({SupabaseClient? client})
      : _client = client;

  final SupabaseClient? _client;

  SupabaseClient get _clientOrInstance =>
      _client ?? RutioSupabaseClient.instance;

  @override
  Future<Object?> purchaseShopItem({
    required String itemId,
    required String requestId,
  }) {
    return _clientOrInstance.rpc(
      'purchase_shop_item',
      params: <String, dynamic>{
        'p_item_id': itemId,
        'p_request_id': requestId,
      },
    );
  }
}
