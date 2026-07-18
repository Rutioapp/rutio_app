import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/pending_shop_purchase.dart';
import '../domain/pending_shop_operation_store.dart';

class SharedPreferencesPendingShopOperationStore
    implements PendingShopOperationStore {
  SharedPreferencesPendingShopOperationStore({
    Future<SharedPreferences> Function()? sharedPreferencesProvider,
  }) : _sharedPreferencesProvider =
            sharedPreferencesProvider ?? SharedPreferences.getInstance;

  static const String storagePrefix = 'rutio_shop_pending_purchase_v1';

  final Future<SharedPreferences> Function() _sharedPreferencesProvider;

  @override
  Future<List<PendingShopPurchase>> loadPendingPurchases(String userId) async {
    final prefs = await _sharedPreferencesProvider();
    final raw = prefs.getString(_storageKey(userId));
    if (raw == null || raw.trim().isEmpty) {
      return const <PendingShopPurchase>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <PendingShopPurchase>[];
      }

      final pending = <PendingShopPurchase>[];
      for (final value in decoded) {
        if (value is! Map) continue;
        try {
          pending.add(
            PendingShopPurchase.fromJson(
              Map<String, dynamic>.from(value.cast<String, dynamic>()),
            ),
          );
        } catch (_) {}
      }

      pending.sort((a, b) {
        final byCreated = a.createdAtMillis.compareTo(b.createdAtMillis);
        if (byCreated != 0) return byCreated;
        return a.requestId.compareTo(b.requestId);
      });
      return pending;
    } catch (_) {
      return const <PendingShopPurchase>[];
    }
  }

  @override
  Future<void> savePendingPurchases(
    String userId,
    List<PendingShopPurchase> purchases,
  ) async {
    final prefs = await _sharedPreferencesProvider();
    final encoded = jsonEncode(
      purchases.map((purchase) => purchase.toJson()).toList(growable: false),
    );
    await prefs.setString(_storageKey(userId), encoded);
  }

  @override
  Future<void> clearPendingPurchases(String userId) async {
    final prefs = await _sharedPreferencesProvider();
    await prefs.remove(_storageKey(userId));
  }

  String _storageKey(String userId) {
    return '${storagePrefix}_${userId.trim()}';
  }
}
