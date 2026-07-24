import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:rutio/features/shop/data/shop_assets_catalog.dart';
import 'package:rutio/features/shop/domain/models/shop_asset_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShopCosmeticsRepository {
  static final Map<String, Future<void>> _operationQueuesByStorageKey =
      <String, Future<void>>{};

  ShopCosmeticsRepository({
    Future<SharedPreferences> Function()? sharedPreferencesProvider,
    String? Function()? scopeResolver,
  })  : _sharedPreferencesProvider =
            sharedPreferencesProvider ?? SharedPreferences.getInstance,
        _scopeResolver = scopeResolver;

  static const String legacyStorageKey = 'rutio_shop_cosmetics_v1';
  static const String legacyScopeOwnerKey = 'rutio_shop_cosmetics_v1_owner';
  static const String guestStorageKey = 'rutio_shop_cosmetics_v1_guest';

  final Future<SharedPreferences> Function() _sharedPreferencesProvider;
  final String? Function()? _scopeResolver;

  Future<ShopCosmeticsState> load() {
    return _runExclusive(() async {
      try {
        final prefs = await _sharedPreferencesProvider();
        final scope = _resolvedScope();
        if (scope == null) {
          final rawGuest = prefs.getString(guestStorageKey);
          final guestState = _stateFromRaw(rawGuest);
          if (guestState == null) {
            _log('loadState scope=guest source=empty');
            return const ShopCosmeticsState.initial();
          }

          final sanitized = _sanitizeState(guestState);
          _log('loadState scope=guest source=guest');
          if (sanitized != guestState) {
            await _writeState(
              prefs,
              storageKey: guestStorageKey,
              state: sanitized,
            );
          }
          return sanitized;
        }

        final scopedStorageKey = _storageKeyForScope(scope)!;
        final rawScoped = prefs.getString(scopedStorageKey);
        final scopedState = _stateFromRaw(rawScoped);
        if (scopedState != null) {
          await _cleanupLegacyStateIfNeeded(
            prefs,
            scope: scope,
            rawLegacy: prefs.getString(legacyStorageKey),
            legacyOwner: prefs.getString(legacyScopeOwnerKey),
          );
          final sanitized = _sanitizeState(scopedState);
          _log('loadState scope=$scope source=scoped');
          if (sanitized != scopedState) {
            await _writeState(
              prefs,
              storageKey: scopedStorageKey,
              state: sanitized,
            );
          }
          return sanitized;
        }

        final rawLegacy = prefs.getString(legacyStorageKey);
        final legacyOwner = prefs.getString(legacyScopeOwnerKey)?.trim();
        if (rawLegacy == null || rawLegacy.trim().isEmpty) {
          _log('loadState scope=$scope source=empty');
          return const ShopCosmeticsState.initial();
        }

        if (legacyOwner == null || legacyOwner.isEmpty) {
          await _discardUnsafeLegacyState(
            prefs,
            reason: 'missing_owner',
          );
          return const ShopCosmeticsState.initial();
        }

        if (legacyOwner != scope) {
          await _discardUnsafeLegacyState(
            prefs,
            reason: 'owner_mismatch',
          );
          return const ShopCosmeticsState.initial();
        }

        ShopCosmeticsState? legacyState;
        try {
          legacyState = _stateFromRaw(rawLegacy);
        } catch (_) {
          await _discardUnsafeLegacyState(
            prefs,
            reason: 'invalid_json',
          );
          return const ShopCosmeticsState.initial();
        }

        if (legacyState == null) {
          await _discardUnsafeLegacyState(
            prefs,
            reason: 'invalid_json',
          );
          return const ShopCosmeticsState.initial();
        }

        final sanitized = _sanitizeState(legacyState);
        await _writeState(
          prefs,
          storageKey: scopedStorageKey,
          state: sanitized,
        );
        await _removeLegacyState(prefs);
        _log('migrateLegacyState scope=$scope result=success');
        return sanitized;
      } catch (_) {
        _log('loadState failed, returning initial state');
        return const ShopCosmeticsState.initial();
      }
    });
  }

  Future<void> save(ShopCosmeticsState state) {
    return _runExclusive(() async {
      final prefs = await _sharedPreferencesProvider();
      final encoded = jsonEncode(_sanitizeState(state).toJson());
      final scope = _resolvedScope();
      final scopedStorageKey = _storageKeyForScope(scope);

      if (scopedStorageKey == null) {
        await prefs.setString(guestStorageKey, encoded);
        _log('saveState scope=guest destination=guest');
        return;
      }

      await prefs.setString(scopedStorageKey, encoded);
      _log('saveState scope=$scope destination=scoped');
    });
  }

  Future<void> clear() {
    return _runExclusive(() async {
      final prefs = await _sharedPreferencesProvider();
      final scope = _resolvedScope();
      if (scope == null) {
        await prefs.remove(guestStorageKey);
        _log('clearState scope=guest destination=guest');
        return;
      }

      final scopedStorageKey = _storageKeyForScope(scope)!;
      await prefs.remove(scopedStorageKey);
      await _removeLegacyStateIfOwnedBy(prefs, scope: scope);
      _log('clearState scope=$scope destination=scoped');
    });
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

  Future<T> _runExclusive<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    final storageKey =
        _storageKeyForScope(_resolvedScope()) ?? guestStorageKey;
    final previous = _operationQueuesByStorageKey[storageKey] ??
        Future<void>.value();

    final next = previous.then((_) async {
      try {
        final result = await action();
        completer.complete(result);
      } catch (error, stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      }
    });
    late final Future<void> trackedQueue;
    trackedQueue = next.whenComplete(() {
      // Drop completed queue entries so later test zones do not inherit a
      // stale Future, while preserving serialization for in-flight work.
      if (identical(_operationQueuesByStorageKey[storageKey], trackedQueue)) {
        _operationQueuesByStorageKey.remove(storageKey);
      }
    }).catchError((_) {});
    _operationQueuesByStorageKey[storageKey] = trackedQueue;
    return completer.future;
  }

  Future<void> _cleanupLegacyStateIfNeeded(
    SharedPreferences prefs, {
    required String scope,
    required String? rawLegacy,
    required String? legacyOwner,
  }) async {
    if (rawLegacy == null || rawLegacy.trim().isEmpty) return;
    if (legacyOwner == null || legacyOwner.isEmpty) {
      await _discardUnsafeLegacyState(prefs, reason: 'missing_owner');
      return;
    }
    if (legacyOwner != scope) {
      await _discardUnsafeLegacyState(prefs, reason: 'owner_mismatch');
      return;
    }

    await _removeLegacyState(prefs);
  }

  Future<void> _discardUnsafeLegacyState(
    SharedPreferences prefs, {
    required String reason,
  }) async {
    await _removeLegacyState(prefs);
    _log('discardUnsafeLegacyState reason=$reason');
  }

  Future<void> _removeLegacyState(SharedPreferences prefs) async {
    await prefs.remove(legacyStorageKey);
    await prefs.remove(legacyScopeOwnerKey);
  }

  Future<void> _removeLegacyStateIfOwnedBy(
    SharedPreferences prefs, {
    required String scope,
  }) async {
    final legacyOwner = prefs.getString(legacyScopeOwnerKey)?.trim();
    if (legacyOwner != scope) return;
    await _removeLegacyState(prefs);
  }

  Future<void> _writeState(
    SharedPreferences prefs, {
    required String storageKey,
    required ShopCosmeticsState state,
  }) async {
    await prefs.setString(storageKey, jsonEncode(state.toJson()));
  }

  ShopCosmeticsState? _stateFromRaw(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    return ShopCosmeticsState.fromJson(Map<String, dynamic>.from(decoded));
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
