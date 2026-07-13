import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:rutio/features/shop/data/shop_assets_catalog.dart';
import 'package:rutio/features/shop/domain/models/shop_asset_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShopCosmeticsRepository {
  ShopCosmeticsRepository({
    Future<SharedPreferences> Function()? sharedPreferencesProvider,
    String? Function()? scopeResolver,
  })  : _sharedPreferencesProvider =
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
      final rawScoped =
          scopedStorageKey == null ? null : prefs.getString(scopedStorageKey);
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

      final rawState =
          ShopCosmeticsState.fromJson(Map<String, dynamic>.from(decoded));
      final state = _sanitizeState(rawState);
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

      if (state != rawState) {
        await save(state);
        _log(
          'sanitizeState scope=${scope ?? 'guest'} storageKey=$sourceKey '
          'ownedAssetIds=${state.ownedAssetIds} ownedBundleIds=${state.ownedBundleIds} '
          'equippedWallpaperId=${state.equippedWallpaperId}',
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

  ShopCosmeticsState _sanitizeState(ShopCosmeticsState state) {
    final validAssetIds =
        ShopAssetsCatalog.allAssets.map((asset) => asset.id).toSet();
    final validBundleIds =
        ShopAssetsCatalog.allBundles.map((bundle) => bundle.id).toSet();

    final sanitized = state.copyWith(
      ownedAssetIds: state.ownedAssetIds
          .where(validAssetIds.contains)
          .toList(growable: false),
      ownedBundleIds: state.ownedBundleIds
          .where(validBundleIds.contains)
          .toList(growable: false),
      equippedWallpaperId: _sanitizeEquippedId(
        state.equippedWallpaperId,
        ShopAssetCategory.wallpaper,
      ),
      equippedHabitCardSkinId: _sanitizeEquippedId(
        state.equippedHabitCardSkinId,
        ShopAssetCategory.habitCard,
      ),
      equippedUserCardSkinId: _sanitizeEquippedId(
        state.equippedUserCardSkinId,
        ShopAssetCategory.userCard,
      ),
    );

    return sanitized.copyWith(
      equippedWallpaperId: sanitized.isAssetOwned(
        sanitized.equippedWallpaperId ?? '',
        bundles: ShopAssetsCatalog.allBundles,
      )
          ? sanitized.equippedWallpaperId
          : null,
      equippedHabitCardSkinId: sanitized.isAssetOwned(
        sanitized.equippedHabitCardSkinId ?? '',
        bundles: ShopAssetsCatalog.allBundles,
      )
          ? sanitized.equippedHabitCardSkinId
          : null,
      equippedUserCardSkinId: sanitized.isAssetOwned(
        sanitized.equippedUserCardSkinId ?? '',
        bundles: ShopAssetsCatalog.allBundles,
      )
          ? sanitized.equippedUserCardSkinId
          : null,
    );
  }

  String? _sanitizeEquippedId(String? assetId, ShopAssetCategory category) {
    final cleaned = assetId?.trim();
    if (cleaned == null || cleaned.isEmpty) return null;
    final asset = ShopAssetsCatalog.getAssetById(cleaned);
    if (asset == null || asset.category != category) {
      return null;
    }
    return cleaned;
  }
}
