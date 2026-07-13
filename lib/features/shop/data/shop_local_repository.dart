import 'dart:convert';

import 'package:rutio/features/shop/data/shop_catalog.dart';
import 'package:rutio/features/shop/domain/models/equipped_cosmetics.dart';
import 'package:rutio/features/shop/domain/models/owned_shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
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

      final state = ShopState.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      return _sanitizeState(state);
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

  ShopState _sanitizeState(ShopState state) {
    final validItemIds = ShopCatalog.allItems.map((item) => item.id).toSet();
    final inventory = state.inventory
        .where((OwnedShopItem item) => validItemIds.contains(item.itemId))
        .toList(growable: false);
    final ownedIds = inventory.map((item) => item.itemId).toSet();
    final backpackItems = state.backpackItems
        .where((item) => validItemIds.contains(item.itemId))
        .toList(growable: false);

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
