import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShopCosmeticsRepository {
  ShopCosmeticsRepository({
    Future<SharedPreferences> Function()? sharedPreferencesProvider,
    String? Function()? scopeResolver,
  }) : _sharedPreferencesProvider =
            sharedPreferencesProvider ?? SharedPreferences.getInstance,
        _scopeResolver = scopeResolver;

  static const String legacyStorageKey = 'rutio_shop_cosmetics_v1';
  static const String legacyScopeOwnerKey = 'rutio_shop_cosmetics_v1_owner';

  final Future<SharedPreferences> Function() _sharedPreferencesProvider;
  final String? Function()? _scopeResolver;

  Future<ShopCosmeticsState> load() async {
    try {
      final prefs = await _sharedPreferencesProvider();
      final scope = _resolvedScope();
      final scopedStorageKey = _storageKeyForScope(scope);
      final rawScoped = scopedStorageKey == null
          ? null
          : prefs.getString(scopedStorageKey);
      final rawLegacy = prefs.getString(legacyStorageKey);
      final legacyScopeOwner = prefs.getString(legacyScopeOwnerKey)?.trim();
      final canUseLegacyForScope = scope == null ||
          legacyScopeOwner == null ||
          legacyScopeOwner.isEmpty ||
          legacyScopeOwner == scope;

      final resolvedRaw = (rawScoped != null && rawScoped.trim().isNotEmpty)
          ? rawScoped
          : canUseLegacyForScope
              ? rawLegacy
              : null;
      final sourceKey = (rawScoped != null && rawScoped.trim().isNotEmpty)
          ? scopedStorageKey
          : canUseLegacyForScope
              ? legacyStorageKey
              : scopedStorageKey;

      if (resolvedRaw == null || resolvedRaw.trim().isEmpty) {
        const initial = ShopCosmeticsState.initial();
        _log(
          'loadState scope=${scope ?? 'guest'} storageKey=${scopedStorageKey ?? legacyStorageKey} source=empty '
          'ownedAssetIds=${initial.ownedAssetIds} ownedBundleIds=${initial.ownedBundleIds} '
          'equippedWallpaperId=${initial.equippedWallpaperId} '
          'equippedHabitCardSkinId=${initial.equippedHabitCardSkinId} '
          'equippedUserCardSkinId=${initial.equippedUserCardSkinId}',
        );
        return initial;
      }

      final decoded = jsonDecode(resolvedRaw);
      if (decoded is! Map) {
        _log(
          'loadState scope=${scope ?? 'guest'} storageKey=$sourceKey source=invalid-json-map',
        );
        return const ShopCosmeticsState.initial();
      }

      final state = ShopCosmeticsState.fromJson(Map<String, dynamic>.from(decoded));
      _log(
        'loadState scope=${scope ?? 'guest'} storageKey=$sourceKey '
        'ownedAssetIds=${state.ownedAssetIds} ownedBundleIds=${state.ownedBundleIds} '
        'equippedWallpaperId=${state.equippedWallpaperId} '
        'equippedHabitCardSkinId=${state.equippedHabitCardSkinId} '
        'equippedUserCardSkinId=${state.equippedUserCardSkinId}',
      );

      if ((rawScoped == null || rawScoped.trim().isEmpty) &&
          scopedStorageKey != null &&
          rawLegacy != null &&
          rawLegacy.trim().isNotEmpty &&
          canUseLegacyForScope) {
        await prefs.setString(scopedStorageKey, resolvedRaw);
        await prefs.setString(legacyScopeOwnerKey, scope!);
        _log(
          'migrateLegacyState scope=$scope from=$legacyStorageKey to=$scopedStorageKey',
        );
      }

      return state;
    } catch (_) {
      _log('loadState failed, returning initial state');
      return const ShopCosmeticsState.initial();
    }
  }

  Future<void> save(ShopCosmeticsState state) async {
    final prefs = await _sharedPreferencesProvider();
    final encoded = jsonEncode(state.toJson());
    final scope = _resolvedScope();
    final scopedStorageKey = _storageKeyForScope(scope);

    if (scopedStorageKey != null) {
      await prefs.setString(scopedStorageKey, encoded);
      await prefs.setString(legacyScopeOwnerKey, scope!);
    }
    await prefs.setString(legacyStorageKey, encoded);
    _log(
      'saveState scope=${scope ?? 'guest'} storageKey=${scopedStorageKey ?? legacyStorageKey} '
      'ownedAssetIds=${state.ownedAssetIds} ownedBundleIds=${state.ownedBundleIds} '
      'equippedWallpaperId=${state.equippedWallpaperId} '
      'equippedHabitCardSkinId=${state.equippedHabitCardSkinId} '
      'equippedUserCardSkinId=${state.equippedUserCardSkinId}',
    );
  }

  Future<void> clear() async {
    final prefs = await _sharedPreferencesProvider();
    final scope = _resolvedScope();
    final scopedStorageKey = _storageKeyForScope(scope);
    if (scopedStorageKey != null) {
      await prefs.remove(scopedStorageKey);
    }
    await prefs.remove(legacyStorageKey);
    await prefs.remove(legacyScopeOwnerKey);
    _log(
      'clearState scope=${scope ?? 'guest'} storageKey=${scopedStorageKey ?? legacyStorageKey}',
    );
  }

  String? _resolvedScope() {
    final raw = _scopeResolver?.call()?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  String? _storageKeyForScope(String? scope) {
    if (scope == null || scope.isEmpty) return null;
    return '${legacyStorageKey}_$scope';
  }

  void _log(String message) {
    if (!kDebugMode) return;
    debugPrint('[ShopCosmetics] $message');
  }
}
