import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/rutio_supabase_client.dart';
import 'shop_cloud_errors.dart';

abstract class ShopCatalogRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchActiveCatalogRows();
}

abstract class ShopUserStateRemoteDataSource {
  Future<Map<String, dynamic>?> fetchWalletRow();

  Future<List<Map<String, dynamic>>> fetchInventoryRows();

  Future<List<Map<String, dynamic>>> fetchEquippedCosmeticsRows();
}

class SupabaseShopCatalogRemoteDataSource
    implements ShopCatalogRemoteDataSource {
  SupabaseShopCatalogRemoteDataSource({SupabaseClient? client})
      : _client = client;

  final SupabaseClient? _client;

  SupabaseClient get _clientOrInstance =>
      _client ?? RutioSupabaseClient.instance;

  @override
  Future<List<Map<String, dynamic>>> fetchActiveCatalogRows() async {
    _ensureAuthenticatedUser();
    try {
      final client = _clientOrInstance;
      final rows = await client
          .from('shop_items')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true)
          .order('id', ascending: true);
      return _castRows(rows);
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(
        error,
        fallbackMessage: 'Could not fetch shop catalog.',
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[shop_cloud_read] unexpected catalog fetch error: $error');
      }
      throw ShopCloudReadException(
        code: ShopCloudErrorCode.unknown,
        message: 'Could not fetch shop catalog.',
        cause: error,
      );
    }
  }

  void _ensureAuthenticatedUser() {
    final userId = _clientOrInstance.auth.currentUser?.id.trim();
    if (userId == null || userId.isEmpty) {
      throw const ShopCloudReadException(
        code: ShopCloudErrorCode.unauthenticated,
        message: 'No authenticated user session is available.',
      );
    }
  }
}

class SupabaseShopUserStateRemoteDataSource
    implements ShopUserStateRemoteDataSource {
  SupabaseShopUserStateRemoteDataSource({SupabaseClient? client})
      : _client = client;

  final SupabaseClient? _client;

  SupabaseClient get _clientOrInstance =>
      _client ?? RutioSupabaseClient.instance;

  @override
  Future<Map<String, dynamic>?> fetchWalletRow() async {
    final userId = _currentUserId();
    if (userId == null) {
      throw const ShopCloudReadException(
        code: ShopCloudErrorCode.unauthenticated,
        message: 'No authenticated user session is available.',
      );
    }

    try {
      final row = await _clientOrInstance
          .from('user_wallets')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (row == null) return null;
      return Map<String, dynamic>.from(row);
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(
        error,
        fallbackMessage: 'Could not fetch shop wallet.',
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[shop_cloud_read] unexpected wallet fetch error: $error');
      }
      throw ShopCloudReadException(
        code: ShopCloudErrorCode.unknown,
        message: 'Could not fetch shop wallet.',
        cause: error,
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchInventoryRows() async {
    final userId = _currentUserId();
    if (userId == null) {
      throw const ShopCloudReadException(
        code: ShopCloudErrorCode.unauthenticated,
        message: 'No authenticated user session is available.',
      );
    }

    try {
      final rows = await _clientOrInstance
          .from('user_inventory')
          .select()
          .eq('user_id', userId)
          .order('acquired_at', ascending: false)
          .order('updated_at', ascending: false);
      return _castRows(rows);
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(
        error,
        fallbackMessage: 'Could not fetch shop inventory.',
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
            '[shop_cloud_read] unexpected inventory fetch error: $error');
      }
      throw ShopCloudReadException(
        code: ShopCloudErrorCode.unknown,
        message: 'Could not fetch shop inventory.',
        cause: error,
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchEquippedCosmeticsRows() async {
    final userId = _currentUserId();
    if (userId == null) {
      throw const ShopCloudReadException(
        code: ShopCloudErrorCode.unauthenticated,
        message: 'No authenticated user session is available.',
      );
    }

    try {
      final rows = await _clientOrInstance
          .from('user_equipped_cosmetics')
          .select()
          .eq('user_id', userId)
          .order('equipped_at', ascending: false);
      return _castRows(rows);
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(
        error,
        fallbackMessage: 'Could not fetch equipped cosmetics.',
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[shop_cloud_read] unexpected equipped cosmetics fetch error: $error',
        );
      }
      throw ShopCloudReadException(
        code: ShopCloudErrorCode.unknown,
        message: 'Could not fetch equipped cosmetics.',
        cause: error,
      );
    }
  }

  String? _currentUserId() {
    final userId = _clientOrInstance.auth.currentUser?.id.trim();
    if (userId == null || userId.isEmpty) return null;
    return userId;
  }
}

List<Map<String, dynamic>> _castRows(Object? rows) {
  if (rows is! List) return const <Map<String, dynamic>>[];
  return rows.whereType<Map>().map((row) {
    return Map<String, dynamic>.from(row.cast<String, dynamic>());
  }).toList(growable: false);
}

ShopCloudReadException _mapPostgrestError(
  PostgrestException error, {
  required String fallbackMessage,
}) {
  if (kDebugMode) {
    debugPrint(
      '[shop_cloud_read] postgrest error (${error.code}): ${error.message}',
    );
  }

  final code = (error.code ?? '').trim().toUpperCase();
  if (code == '42P01' || code == 'PGRST204' || code == '42703') {
    return ShopCloudReadException(
      code: ShopCloudErrorCode.malformedResponse,
      message: fallbackMessage,
      cause: error,
    );
  }
  if (code == '42501') {
    return ShopCloudReadException(
      code: ShopCloudErrorCode.malformedResponse,
      message: fallbackMessage,
      cause: error,
    );
  }

  final rawMessage = error.message.toLowerCase();
  if (rawMessage.contains('network') ||
      rawMessage.contains('socket') ||
      rawMessage.contains('connection')) {
    return ShopCloudReadException(
      code: ShopCloudErrorCode.networkUnavailable,
      message: fallbackMessage,
      cause: error,
    );
  }
  if (rawMessage.contains('timeout')) {
    return ShopCloudReadException(
      code: ShopCloudErrorCode.timeout,
      message: fallbackMessage,
      cause: error,
    );
  }

  return ShopCloudReadException(
    code: ShopCloudErrorCode.unknown,
    message: fallbackMessage,
    cause: error,
  );
}
