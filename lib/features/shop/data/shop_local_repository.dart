import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:rutio/features/shop/data/shop_catalog.dart';
import 'package:rutio/features/shop/domain/models/backpack_item.dart';
import 'package:rutio/features/shop/domain/models/equipped_cosmetics.dart';
import 'package:rutio/features/shop/domain/models/owned_shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/domain/shop_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShopLocalRepository {
  ShopLocalRepository({
    Future<SharedPreferences> Function()? sharedPreferencesProvider,
    String? Function()? scopeResolver,
  })  : _sharedPreferencesProvider =
            sharedPreferencesProvider ?? SharedPreferences.getInstance,
        _scopeResolver = scopeResolver;

  static const String storageKey = 'rutio_shop_state_v1';
  static const String legacyScopeOwnerKey = 'rutio_shop_state_v1_owner';
  static const String guestStorageKey = 'rutio_shop_state_v1_guest';

  static Future<void> _operationQueue = Future<void>.value();

  final Future<SharedPreferences> Function() _sharedPreferencesProvider;
  final String? Function()? _scopeResolver;

  Future<ShopState> load() {
    return _runExclusive(() async {
      try {
        final prefs = await _sharedPreferencesProvider();
        final scope = _resolvedScope();
        final guest = scope == null;
        final scopedStorageKey = _storageKeyForScope(scope);

        if (guest) {
          final rawGuest = prefs.getString(guestStorageKey);
          final guestState = _stateFromRaw(rawGuest);
          if (guestState == null) {
            _log('loadState scope=guest source=guest-empty');
            return const ShopState.initial();
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

        final rawScoped = prefs.getString(scopedStorageKey!);
        final scopedState = _stateFromRaw(rawScoped);
        if (scopedState != null) {
          await _cleanupLegacyStateIfNeeded(
            prefs,
            scope: scope,
            rawLegacy: prefs.getString(storageKey),
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

        final rawLegacy = prefs.getString(storageKey);
        final legacyOwner = prefs.getString(legacyScopeOwnerKey)?.trim();
        if (rawLegacy == null || rawLegacy.trim().isEmpty) {
          _log('loadState scope=$scope source=empty');
          return const ShopState.initial();
        }

        if (legacyOwner == null || legacyOwner.isEmpty) {
          await _discardUnsafeLegacyState(
            prefs,
            reason: 'missing_owner',
          );
          return const ShopState.initial();
        }

        if (legacyOwner != scope) {
          await _discardUnsafeLegacyState(
            prefs,
            reason: 'owner_mismatch',
          );
          return const ShopState.initial();
        }

        ShopState? legacyState;
        try {
          legacyState = _stateFromRaw(rawLegacy);
        } catch (_) {
          await _discardUnsafeLegacyState(
            prefs,
            reason: 'invalid_json',
          );
          return const ShopState.initial();
        }

        if (legacyState == null) {
          await _discardUnsafeLegacyState(
            prefs,
            reason: 'invalid_json',
          );
          return const ShopState.initial();
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
        return const ShopState.initial();
      }
    });
  }

  Future<void> save(ShopState state) {
    return _runExclusive(() async {
      final prefs = await _sharedPreferencesProvider();
      final scope = _resolvedScope();
      final storageKeyForScope = _storageKeyForScope(scope);
      final encoded = jsonEncode(_sanitizeState(state).toJson());

      if (storageKeyForScope == null) {
        await prefs.setString(guestStorageKey, encoded);
        _log('saveState scope=guest destination=guest');
        return;
      }

      await prefs.setString(storageKeyForScope, encoded);
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

      final scopedStorageKey = _storageKeyForScope(scope);
      await prefs.remove(scopedStorageKey!);
      await _removeLegacyStateIfOwnedBy(prefs, scope: scope);
      _log('clearState scope=$scope destination=scoped');
    });
  }

  Future<T> _runExclusive<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    final previous = _operationQueue;
    final next = previous.then((_) async {
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      }
    });
    _operationQueue = next.catchError((_) {});
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
    await prefs.remove(storageKey);
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
    required ShopState state,
  }) async {
    await prefs.setString(storageKey, jsonEncode(state.toJson()));
  }

  ShopState? _stateFromRaw(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    return ShopState.fromJson(Map<String, dynamic>.from(decoded));
  }

  ShopState _sanitizeState(ShopState state) {
    final validItemIds = ShopCatalog.allItems.map((item) => item.id).toSet();
    final inventory = state.inventory
        .where((OwnedShopItem item) => validItemIds.contains(item.itemId))
        .toList(growable: false);
    final ownedIds = inventory.map((item) => item.itemId).toSet();
    final Map<String, BackpackItem> mergedBackpack = <String, BackpackItem>{};
    for (final item in state.backpackItems) {
      final catalogItem = ShopCatalog.getItemById(item.itemId);
      if (catalogItem == null ||
          catalogItem.category != ShopItemCategory.utility ||
          item.quantity <= 0) {
        continue;
      }

      final current = mergedBackpack[item.itemId];
      if (current == null) {
        mergedBackpack[item.itemId] = item;
        continue;
      }

      mergedBackpack[item.itemId] = current.copyWith(
        quantity: current.quantity + item.quantity,
        updatedAtMillis: _maxUpdatedAt(
          current.updatedAtMillis,
          item.updatedAtMillis,
        ),
      );
    }
    final backpackItems = mergedBackpack.values.toList(growable: false);

    return state.copyWith(
      inventory: inventory,
      backpackItems: backpackItems,
      equippedCosmetics: EquippedCosmetics(
        backgroundItemId: _sanitizeEquippedItemId(
          state.equippedCosmetics.backgroundItemId,
          ShopItemType.background,
          ownedIds,
        ),
        habitCardItemId: _sanitizeEquippedItemId(
          state.equippedCosmetics.habitCardItemId,
          ShopItemType.habitCard,
          ownedIds,
        ),
        userCardItemId: _sanitizeEquippedItemId(
          state.equippedCosmetics.userCardItemId,
          ShopItemType.userCard,
          ownedIds,
        ),
      ),
    );
  }

  String? _resolvedScope() {
    final raw = _scopeResolver?.call()?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  String? _storageKeyForScope(String? scope) {
    if (scope == null || scope.isEmpty) return null;
    return '${storageKey}_$scope';
  }

  int? _maxUpdatedAt(int? left, int? right) {
    if (left == null) return right;
    if (right == null) return left;
    return left >= right ? left : right;
  }

  String? _sanitizeEquippedItemId(
    String? itemId,
    ShopItemType expectedType,
    Set<String> ownedIds,
  ) {
    final cleaned = itemId?.trim();
    if (cleaned == null || cleaned.isEmpty) return null;
    final item = ShopCatalog.getItemById(cleaned);
    if (item == null ||
        item.type != expectedType ||
        !ownedIds.contains(cleaned)) {
      return null;
    }
    return cleaned;
  }

  void _log(String message) {
    if (!kDebugMode) return;
    debugPrint('[ShopLocal] $message');
  }
}
