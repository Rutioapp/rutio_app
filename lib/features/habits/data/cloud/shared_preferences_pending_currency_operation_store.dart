import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/pending_currency_operation.dart';
import '../../domain/pending_currency_operation_store.dart';

class SharedPreferencesPendingCurrencyOperationStore
    implements PendingCurrencyOperationStore {
  SharedPreferencesPendingCurrencyOperationStore({
    Future<SharedPreferences> Function()? sharedPreferencesProvider,
  }) : _sharedPreferencesProvider =
            sharedPreferencesProvider ?? SharedPreferences.getInstance;

  static const String storagePrefix =
      'rutio_habit_pending_currency_operation_v1';

  final Future<SharedPreferences> Function() _sharedPreferencesProvider;

  @override
  Future<List<PendingCurrencyOperation>> loadPendingOperations(
    String userId,
  ) async {
    final prefs = await _sharedPreferencesProvider();
    final raw = prefs.getString(_storageKey(userId));
    if (raw == null || raw.trim().isEmpty) {
      return const <PendingCurrencyOperation>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <PendingCurrencyOperation>[];
      }

      final pending = <PendingCurrencyOperation>[];
      for (final value in decoded) {
        if (value is! Map) continue;
        try {
          pending.add(
            PendingCurrencyOperation.fromJson(
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
      return const <PendingCurrencyOperation>[];
    }
  }

  @override
  Future<void> savePendingOperations(
    String userId,
    List<PendingCurrencyOperation> operations,
  ) async {
    final prefs = await _sharedPreferencesProvider();
    final encoded = jsonEncode(
      operations.map((operation) => operation.toJson()).toList(growable: false),
    );
    await prefs.setString(_storageKey(userId), encoded);
  }

  @override
  Future<void> clearPendingOperations(String userId) async {
    final prefs = await _sharedPreferencesProvider();
    await prefs.remove(_storageKey(userId));
  }

  String _storageKey(String userId) {
    return '${storagePrefix}_${userId.trim()}';
  }
}
