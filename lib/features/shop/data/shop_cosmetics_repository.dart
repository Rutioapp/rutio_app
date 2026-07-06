import 'dart:convert';

import 'package:rutio/features/shop/domain/models/shop_cosmetics_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShopCosmeticsRepository {
  ShopCosmeticsRepository({
    Future<SharedPreferences> Function()? sharedPreferencesProvider,
  }) : _sharedPreferencesProvider =
            sharedPreferencesProvider ?? SharedPreferences.getInstance;

  static const String storageKey = 'rutio_shop_cosmetics_v1';

  final Future<SharedPreferences> Function() _sharedPreferencesProvider;

  Future<ShopCosmeticsState> load() async {
    try {
      final prefs = await _sharedPreferencesProvider();
      final raw = prefs.getString(storageKey);
      if (raw == null || raw.trim().isEmpty) {
        return const ShopCosmeticsState.initial();
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const ShopCosmeticsState.initial();
      }

      return ShopCosmeticsState.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return const ShopCosmeticsState.initial();
    }
  }

  Future<void> save(ShopCosmeticsState state) async {
    final prefs = await _sharedPreferencesProvider();
    await prefs.setString(storageKey, jsonEncode(state.toJson()));
  }

  Future<void> clear() async {
    final prefs = await _sharedPreferencesProvider();
    await prefs.remove(storageKey);
  }
}
