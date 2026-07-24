import 'dart:convert';

import 'package:rutio/features/shop/data/shop_catalog.dart';
import 'package:rutio/features/shop/domain/active_utility_effects_repository.dart';
import 'package:rutio/features/shop/domain/models/active_utility_effect.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalActiveUtilityEffectsRepository
    implements ActiveUtilityEffectsRepository {
  LocalActiveUtilityEffectsRepository({
    Future<SharedPreferences> Function()? sharedPreferencesProvider,
    String? Function()? scopeResolver,
    DateTime Function()? nowProvider,
  })  : _sharedPreferencesProvider =
            sharedPreferencesProvider ?? SharedPreferences.getInstance,
        _scopeResolver = scopeResolver,
        _nowProvider = nowProvider ?? DateTime.now;

  static const String storageKey = 'rutio_active_utility_effects_v1';

  final Future<SharedPreferences> Function() _sharedPreferencesProvider;
  final String? Function()? _scopeResolver;
  final DateTime Function() _nowProvider;

  @override
  Future<List<ActiveUtilityEffect>> loadEffects(String userScope) async {
    try {
      final prefs = await _sharedPreferencesProvider();
      final raw = prefs.getString(_storageKeyForScope(userScope));
      if (raw == null || raw.trim().isEmpty) {
        return const <ActiveUtilityEffect>[];
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <ActiveUtilityEffect>[];

      final parsed = decoded
          .whereType<Map>()
          .map((entry) =>
              ActiveUtilityEffect.fromJson(entry.cast<String, dynamic>()))
          .map(_sanitizeEffect)
          .whereType<ActiveUtilityEffect>()
          .where(_isEffectActiveForCurrentLocalDate)
          .toList(growable: false);
      return _dedupeAndSort(parsed);
    } catch (_) {
      return const <ActiveUtilityEffect>[];
    }
  }

  @override
  Future<void> saveEffects(
    String userScope,
    List<ActiveUtilityEffect> effects,
  ) async {
    final prefs = await _sharedPreferencesProvider();
    final sanitized = _dedupeAndSort(
      effects.map(_sanitizeEffect).whereType<ActiveUtilityEffect>().toList(),
    );
    await prefs.setString(
      _storageKeyForScope(userScope),
      jsonEncode(sanitized.map((effect) => effect.toJson()).toList()),
    );
  }

  String? _resolvedScope(String? scope) {
    final resolved = (scope ?? _scopeResolver?.call() ?? '').trim();
    return resolved.isEmpty ? null : resolved;
  }

  String _storageKeyForScope(String? scope) {
    final resolved = _resolvedScope(scope);
    if (resolved == null) return storageKey;
    return '${storageKey}_${_safeKeyFragment(resolved)}';
  }

  String _safeKeyFragment(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
  }

  ActiveUtilityEffect? _sanitizeEffect(ActiveUtilityEffect effect) {
    final catalogItem = ShopCatalog.getItemById(effect.utilityId);
    if (catalogItem == null || effect.id.trim().isEmpty) return null;
    if (effect.type != ActiveUtilityEffectType.xpBoost &&
        effect.type != ActiveUtilityEffectType.coinBoost &&
        effect.type != ActiveUtilityEffectType.streakShield) {
      return null;
    }
    final matchesType = switch (effect.type) {
      ActiveUtilityEffectType.xpBoost =>
        catalogItem.type == ShopItemType.xpBoost,
      ActiveUtilityEffectType.coinBoost =>
        catalogItem.type == ShopItemType.coinBoost,
      ActiveUtilityEffectType.streakShield =>
        catalogItem.type == ShopItemType.streakShield,
    };
    if (!matchesType) {
      return null;
    }

    final totalUses = effect.totalUses <= 0
        ? activeUtilityEffectDefaultTotalUses
        : effect.totalUses;
    final remainingUses = effect.remainingUses.clamp(0, totalUses).toInt();
    if (remainingUses <= 0) return null;

    return effect.copyWith(
      totalUses:
          totalUses <= 0 ? activeUtilityEffectDefaultTotalUses : totalUses,
      remainingUses: remainingUses,
    );
  }

  bool _isEffectActiveForCurrentLocalDate(ActiveUtilityEffect effect) {
    if (effect.type != ActiveUtilityEffectType.streakShield) return true;
    final activatedAt =
        DateTime.fromMillisecondsSinceEpoch(effect.activatedAtMillis).toLocal();
    final now = _nowProvider().toLocal();
    return activatedAt.year == now.year &&
        activatedAt.month == now.month &&
        activatedAt.day == now.day;
  }

  List<ActiveUtilityEffect> _dedupeAndSort(List<ActiveUtilityEffect> effects) {
    final ordered = List<ActiveUtilityEffect>.from(effects)
      ..sort((a, b) {
        final byActivation = b.activatedAtMillis.compareTo(a.activatedAtMillis);
        if (byActivation != 0) return byActivation;
        return b.id.compareTo(a.id);
      });

    final byType = <ActiveUtilityEffectType, ActiveUtilityEffect>{};
    final shields = <ActiveUtilityEffect>[];

    for (final effect in ordered) {
      if (effect.type == ActiveUtilityEffectType.streakShield) {
        if (shields.any((entry) => entry.id == effect.id)) continue;
        shields.add(effect);
        continue;
      }
      byType.putIfAbsent(effect.type, () => effect);
    }

    final deduped = <ActiveUtilityEffect>[
      ...byType.values,
      ...shields,
    ]..sort((a, b) {
        final byActivation = a.activatedAtMillis.compareTo(b.activatedAtMillis);
        if (byActivation != 0) return byActivation;
        return a.id.compareTo(b.id);
      });
    return deduped;
  }
}
