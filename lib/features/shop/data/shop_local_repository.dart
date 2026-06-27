import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:rutio/features/shop/domain/shop_state.dart';

class ShopLocalRepository {
  ShopLocalRepository({
    Future<SharedPreferences> Function()? sharedPreferencesProvider,
  }) : _sharedPreferencesProvider =
            sharedPreferencesProvider ?? SharedPreferences.getInstance;

  static const String storageKey = 'rutio_shop_state_v1';

  final Future<SharedPreferences> Function() _sharedPreferencesProvider;

  Future<ShopState> load() async {
    try {
      final prefs = await _sharedPreferencesProvider();
      final raw = prefs.getString(storageKey);
      if (raw == null || raw.trim().isEmpty) {
        return const ShopState.initial();
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const ShopState.initial();
      }

      return ShopState.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      return const ShopState.initial();
    }
  }

  Future<void> save(ShopState state) async {
    final prefs = await _sharedPreferencesProvider();
    await prefs.setString(
      storageKey,
      jsonEncode(state.toJson()),
    );
  }

  Future<void> clear() async {
    final prefs = await _sharedPreferencesProvider();
    await prefs.remove(storageKey);
  }
}
