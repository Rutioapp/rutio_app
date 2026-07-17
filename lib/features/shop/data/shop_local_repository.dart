import 'dart:convert';

import 'package:rutio/features/shop/data/shop_catalog.dart';
import 'package:rutio/features/shop/domain/models/backpack_item.dart';
import 'package:rutio/features/shop/domain/models/equipped_cosmetics.dart';
import 'package:rutio/features/shop/domain/models/owned_shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rutio/features/shop/domain/shop_state.dart';

class ShopLocalRepository {
  ShopLocalRepository({
    Future<SharedPreferences> Function()? sharedPreferencesProvider,
    String? Function()? scopeResolver,
  })  : _sharedPreferencesProvider =
            sharedPreferencesProvider ?? SharedPreferences.getInstance,
        _scopeResolver = scopeResolver;

  static const String storageKey = 'rutio_shop_state_v1';
  static const String legacyScopeOwnerKey = 'rutio_shop_state_v1_owner';

  final Future<SharedPreferences> Function() _sharedPreferencesProvider;
  final String? Function()? _scopeResolver;

  Future<ShopState> load() async {
    try {
      final prefs = await _sharedPreferencesProvider();
      final scope = _resolvedScope();
      final scopedStorageKey = _storageKeyForScope(scope);
      final rawScoped =
          scopedStorageKey == null ? null : prefs.getString(scopedStorageKey);
      final rawLegacy = prefs.getString(storageKey);
      final legacyScopeOwner = prefs.getString(legacyScopeOwnerKey)?.trim();
      final canUseLegacyForScope = scope == null ||
          legacyScopeOwner == null ||
          legacyScopeOwner.isEmpty ||
          legacyScopeOwner == scope;
      final raw = (rawScoped != null && rawScoped.trim().isNotEmpty)
          ? rawScoped
          : canUseLegacyForScope
              ? rawLegacy
              : null;

      if (raw == null || raw.trim().isEmpty) {
        return const ShopState.initial();
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const ShopState.initial();
      }

      final state = ShopState.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      final sanitized = _sanitizeState(state);

      if ((rawScoped == null || rawScoped.trim().isEmpty) &&
          scopedStorageKey != null &&
          rawLegacy != null &&
          rawLegacy.trim().isNotEmpty &&
          canUseLegacyForScope) {
        await prefs.setString(scopedStorageKey, rawLegacy);
        await prefs.setString(legacyScopeOwnerKey, scope!);
      }

      if (sanitized != state) {
        await save(sanitized);
      }

      return sanitized;
    } catch (_) {
      return const ShopState.initial();
    }
  }

  Future<void> save(ShopState state) async {
    final prefs = await _sharedPreferencesProvider();
    final scope = _resolvedScope();
    final scopedStorageKey = _storageKeyForScope(scope);
    final encoded = jsonEncode(state.toJson());
    if (scopedStorageKey != null) {
      await prefs.setString(scopedStorageKey, encoded);
      await prefs.setString(legacyScopeOwnerKey, scope!);
    }
    await prefs.setString(
      storageKey,
      encoded,
    );
  }

  Future<void> clear() async {
    final prefs = await _sharedPreferencesProvider();
    final scopedStorageKey = _storageKeyForScope(_resolvedScope());
    if (scopedStorageKey != null) {
      await prefs.remove(scopedStorageKey);
    }
    await prefs.remove(storageKey);
    await prefs.remove(legacyScopeOwnerKey);
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
}
