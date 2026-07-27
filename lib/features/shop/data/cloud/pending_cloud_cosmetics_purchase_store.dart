import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/pending_cloud_cosmetics_purchase.dart';
import '../../domain/pending_cloud_cosmetics_purchase_store.dart';

class SharedPreferencesPendingCloudCosmeticsPurchaseStore
    implements PendingCloudCosmeticsPurchaseStore {
  SharedPreferencesPendingCloudCosmeticsPurchaseStore({
    Future<SharedPreferences> Function()? sharedPreferencesProvider,
  }) : _sharedPreferencesProvider =
            sharedPreferencesProvider ?? SharedPreferences.getInstance;

  static const String storagePrefix =
      'rutio_shop_cosmetics_pending_operations_v1';

  final Future<SharedPreferences> Function() _sharedPreferencesProvider;

  @override
  Future<List<PendingCloudCosmeticsPurchase>> loadPendingPurchases(
    String userId,
  ) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return const <PendingCloudCosmeticsPurchase>[];
    }

    final prefs = await _sharedPreferencesProvider();
    final raw = prefs.getString(_storageKey(normalizedUserId));
    if (raw == null || raw.trim().isEmpty) {
      return const <PendingCloudCosmeticsPurchase>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <PendingCloudCosmeticsPurchase>[];
      }

      final pending = <PendingCloudCosmeticsPurchase>[];
      final seenKeys = <String>{};
      for (final value in decoded) {
        if (value is! Map) continue;
        try {
          final purchase = PendingCloudCosmeticsPurchase.fromJson(
            Map<String, dynamic>.from(value.cast<String, dynamic>()),
          );
          if (purchase.userId != normalizedUserId) continue;
          if (purchase.resourceId.trim().isEmpty) continue;
          if (!seenKeys.add(purchase.logicalKey)) continue;
          pending.add(purchase);
        } catch (_) {}
      }

      pending.sort((a, b) {
        final byCreated = a.createdAtMillis.compareTo(b.createdAtMillis);
        if (byCreated != 0) return byCreated;
        return a.logicalKey.compareTo(b.logicalKey);
      });
      return pending;
    } catch (_) {
      return const <PendingCloudCosmeticsPurchase>[];
    }
  }

  @override
  Future<void> savePendingPurchases(
    String userId,
    List<PendingCloudCosmeticsPurchase> purchases,
  ) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return;

    final byKey = <String, PendingCloudCosmeticsPurchase>{};
    for (final purchase in purchases) {
      if (purchase.userId != normalizedUserId) continue;
      byKey[purchase.logicalKey] = purchase;
    }
    final normalized = byKey.values.toList(growable: false)
      ..sort((a, b) {
        final byCreated = a.createdAtMillis.compareTo(b.createdAtMillis);
        if (byCreated != 0) return byCreated;
        return a.logicalKey.compareTo(b.logicalKey);
      });

    final prefs = await _sharedPreferencesProvider();
    final encoded = jsonEncode(
      normalized.map((purchase) => purchase.toJson()).toList(growable: false),
    );
    await prefs.setString(_storageKey(normalizedUserId), encoded);
  }

  @override
  Future<void> clearPendingPurchases(String userId) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return;

    final prefs = await _sharedPreferencesProvider();
    await prefs.remove(_storageKey(normalizedUserId));
  }

  String _storageKey(String userId) {
    return '${storagePrefix}_${userId.trim()}';
  }
}
