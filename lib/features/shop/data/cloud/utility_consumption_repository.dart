import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/rutio_supabase_client.dart';
import '../shop_catalog.dart';
import '../../domain/active_utility_effects_repository.dart';
import '../../domain/models/active_utility_effect.dart';
import '../../domain/models/shop_item.dart';
import '../../domain/models/shop_item_enums.dart';
import 'utility_consumption_config.dart';
import 'utility_consumption_ledger.dart';
import 'utility_consumption_remote_data_source.dart';

abstract interface class UtilityConsumptionRepository
    implements ActiveUtilityEffectsRepository {
  Future<UtilityConsumptionLedgerEntry> activateUtilityEffect({
    required String requestId,
    required String utilityId,
    required String operationType,
    required String sourceType,
    required String sourceId,
    String? habitId,
    String? breakId,
  });

  Future<UtilityConsumptionLedgerEntry> consumeUtilityUse({
    required String requestId,
    required String utilityId,
    required String operationType,
    required String sourceType,
    required String sourceId,
    String? habitId,
    String? breakId,
  });

  Future<UtilityConsumptionLedgerEntry> applyStreakRecover({
    required String requestId,
    required String utilityId,
    required String operationType,
    required String breakId,
  });
}

class SupabaseUtilityConsumptionRepository
    implements UtilityConsumptionRepository {
  SupabaseUtilityConsumptionRepository({
    UtilityConsumptionRemoteDataSource? remoteDataSource,
    bool? enabled,
    String? Function()? currentUserIdProvider,
    DateTime Function()? nowProvider,
    Duration timeout = const Duration(seconds: 12),
  })  : _remoteDataSource =
            remoteDataSource ?? SupabaseUtilityConsumptionRemoteDataSource(),
        _enabled = UtilityConsumptionConfig.resolveEnabled(override: enabled),
        _currentUserIdProvider =
            currentUserIdProvider ?? _defaultCurrentUserIdProvider,
        _nowProvider = nowProvider ?? DateTime.now,
        _timeout = timeout;

  final UtilityConsumptionRemoteDataSource _remoteDataSource;
  final bool _enabled;
  final String? Function() _currentUserIdProvider;
  final DateTime Function() _nowProvider;
  final Duration _timeout;

  @override
  Future<List<ActiveUtilityEffect>> loadEffects(String userScope) async {
    if (!_enabled) return const <ActiveUtilityEffect>[];
    final userId = userScope.trim();
    if (userId.isEmpty) return const <ActiveUtilityEffect>[];

    try {
      final rows =
          await _remoteDataSource.fetchActiveEffectRows(userId: userId);
      final parsed = rows
          .map(ActiveUtilityEffectRow.fromMap)
          .whereType<ActiveUtilityEffectRow>()
          .map(_toEffect)
          .whereType<ActiveUtilityEffect>()
          .where(_isEffectActiveForCurrentLocalDate)
          .toList(growable: false);
      return _dedupeAndSort(parsed);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[utility_consumption] loadEffects failed: $error');
      }
      return const <ActiveUtilityEffect>[];
    }
  }

  @override
  Future<void> saveEffects(
    String userScope,
    List<ActiveUtilityEffect> effects,
  ) async {
    if (!_enabled) return;
    final userId = userScope.trim();
    if (userId.isEmpty) return;

    final current = await loadEffects(userId);
    final currentById = <String, ActiveUtilityEffect>{
      for (final effect in current) effect.id: effect,
    };
    for (final effect in _dedupeAndSort(effects)) {
      final existing = currentById[effect.id];
      if (existing != null) continue;
      final requestId = 'utility:$userId:${effect.id}';
      try {
        await activateUtilityEffect(
          requestId: requestId,
          utilityId: effect.utilityId,
          operationType: 'activate',
          sourceType: 'shop_activation',
          sourceId: effect.id,
          habitId: effect.habitId,
        );
      } catch (error) {
        if (kDebugMode) {
          debugPrint('[utility_consumption] saveEffects failed: $error');
        }
      }
    }
  }

  @override
  Future<UtilityConsumptionLedgerEntry> activateUtilityEffect({
    required String requestId,
    required String utilityId,
    required String operationType,
    required String sourceType,
    required String sourceId,
    String? habitId,
    String? breakId,
  }) async {
    return _executeActivate(
      operationType: operationType,
      requestId: requestId,
      utilityId: utilityId,
      sourceType: sourceType,
      sourceId: sourceId,
      habitId: habitId,
      breakId: breakId,
    );
  }

  @override
  Future<UtilityConsumptionLedgerEntry> consumeUtilityUse({
    required String requestId,
    required String utilityId,
    required String operationType,
    required String sourceType,
    required String sourceId,
    String? habitId,
    String? breakId,
  }) async {
    return _executeConsume(
      operationType: operationType,
      requestId: requestId,
      utilityId: utilityId,
      sourceType: sourceType,
      sourceId: sourceId,
      habitId: habitId,
      breakId: breakId,
    );
  }

  @override
  Future<UtilityConsumptionLedgerEntry> applyStreakRecover({
    required String requestId,
    required String utilityId,
    required String operationType,
    required String breakId,
  }) async {
    return _executeRecover(
      operationType: operationType,
      requestId: requestId,
      utilityId: utilityId,
      sourceType: 'streak_recover',
      sourceId: breakId,
      breakId: breakId,
    );
  }

  Future<UtilityConsumptionLedgerEntry> _executeActivate({
    required String operationType,
    required String requestId,
    required String utilityId,
    required String sourceType,
    required String sourceId,
    String? habitId,
    String? breakId,
  }) async {
    if (!_enabled) {
      throw StateError('Utility cloud consumption is disabled.');
    }

    final userId = _currentUserId();
    if (userId == null) {
      throw StateError('No authenticated user session is available.');
    }

    try {
      final response = await _remoteDataSource
          .activateUtilityEffect(
            requestId: requestId,
            utilityId: utilityId,
            operationType: operationType,
            sourceType: sourceType,
            sourceId: sourceId,
            habitId: habitId,
            breakId: breakId,
          )
          .timeout(_timeout);
      final ledger = UtilityConsumptionLedgerEntry.fromMap(
        Map<String, dynamic>.from(response as Map),
      );
      if (ledger.userId != userId) {
        throw StateError('Authentication session changed during utility sync.');
      }
      return ledger;
    } on TimeoutException catch (error) {
      throw StateError('Utility cloud operation timed out: $error');
    } on SocketException catch (error) {
      throw StateError('Network unavailable while syncing utility: $error');
    } on PostgrestException catch (error) {
      throw StateError(error.message);
    }
  }

  Future<UtilityConsumptionLedgerEntry> _executeConsume({
    required String operationType,
    required String requestId,
    required String utilityId,
    required String sourceType,
    required String sourceId,
    String? habitId,
    String? breakId,
  }) async {
    if (!_enabled) {
      throw StateError('Utility cloud consumption is disabled.');
    }

    final userId = _currentUserId();
    if (userId == null) {
      throw StateError('No authenticated user session is available.');
    }

    try {
      final response = await _remoteDataSource
          .consumeUtilityUse(
            requestId: requestId,
            utilityId: utilityId,
            operationType: operationType,
            sourceType: sourceType,
            sourceId: sourceId,
            habitId: habitId,
            breakId: breakId,
          )
          .timeout(_timeout);
      final ledger = UtilityConsumptionLedgerEntry.fromMap(
        Map<String, dynamic>.from(response as Map),
      );
      if (ledger.userId != userId) {
        throw StateError('Authentication session changed during utility sync.');
      }
      return ledger;
    } on TimeoutException catch (error) {
      throw StateError('Utility cloud operation timed out: $error');
    } on SocketException catch (error) {
      throw StateError('Network unavailable while syncing utility: $error');
    } on PostgrestException catch (error) {
      throw StateError(error.message);
    }
  }

  Future<UtilityConsumptionLedgerEntry> _executeRecover({
    required String operationType,
    required String requestId,
    required String utilityId,
    required String sourceType,
    required String sourceId,
    String? habitId,
    String? breakId,
  }) async {
    if (!_enabled) {
      throw StateError('Utility cloud consumption is disabled.');
    }

    if (sourceType.trim().isEmpty || sourceId.trim().isEmpty) {
      throw StateError('Invalid streak recover source.');
    }
    if (habitId != null) {
      throw StateError('habit_id is not allowed for streak recover.');
    }

    final userId = _currentUserId();
    if (userId == null) {
      throw StateError('No authenticated user session is available.');
    }

    try {
      final response = await _remoteDataSource
          .applyStreakRecover(
            requestId: requestId,
            utilityId: utilityId,
            operationType: operationType,
            breakId: breakId ?? sourceId,
          )
          .timeout(_timeout);
      final ledger = UtilityConsumptionLedgerEntry.fromMap(
        Map<String, dynamic>.from(response as Map),
      );
      if (ledger.userId != userId) {
        throw StateError('Authentication session changed during utility sync.');
      }
      return ledger;
    } on TimeoutException catch (error) {
      throw StateError('Utility cloud operation timed out: $error');
    } on SocketException catch (error) {
      throw StateError('Network unavailable while syncing utility: $error');
    } on PostgrestException catch (error) {
      throw StateError(error.message);
    }
  }

  ActiveUtilityEffect? _toEffect(ActiveUtilityEffectRow row) {
    final catalogItem = row.catalogItem;
    if (catalogItem == null) return null;
    if (row.status != 'active') return null;
    if (row.remainingUses <= 0) return null;
    if (row.utilityType == ActiveUtilityEffectType.xpBoost &&
        catalogItem.type != ShopItemType.xpBoost) {
      return null;
    }
    if (row.utilityType == ActiveUtilityEffectType.coinBoost &&
        catalogItem.type != ShopItemType.coinBoost) {
      return null;
    }
    if (row.utilityType == ActiveUtilityEffectType.streakShield &&
        catalogItem.type != ShopItemType.streakShield) {
      return null;
    }

    return ActiveUtilityEffect(
      id: row.id,
      utilityId: row.utilityId,
      type: row.utilityType,
      activatedAtMillis: row.activatedAtMillis,
      remainingUses: row.remainingUses,
      totalUses: row.totalUses,
      habitId: row.habitId,
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

    return <ActiveUtilityEffect>[
      ...byType.values,
      ...shields,
    ]..sort((a, b) {
        final byActivation = a.activatedAtMillis.compareTo(b.activatedAtMillis);
        if (byActivation != 0) return byActivation;
        return a.id.compareTo(b.id);
      });
  }

  String? _currentUserId() {
    try {
      final userId = _currentUserIdProvider()?.trim();
      if (userId == null || userId.isEmpty) return null;
      return userId;
    } catch (_) {
      return null;
    }
  }

  static String? _defaultCurrentUserIdProvider() {
    try {
      final userId = RutioSupabaseClient.instance.auth.currentUser?.id.trim();
      if (userId == null || userId.isEmpty) return null;
      return userId;
    } catch (_) {
      return null;
    }
  }
}

class ActiveUtilityEffectRow {
  const ActiveUtilityEffectRow({
    required this.id,
    required this.userId,
    required this.utilityId,
    required this.utilityType,
    required this.activatedAtMillis,
    required this.remainingUses,
    required this.totalUses,
    required this.status,
    required this.catalogItem,
    this.habitId,
  });

  final String id;
  final String userId;
  final String utilityId;
  final ActiveUtilityEffectType utilityType;
  final int activatedAtMillis;
  final int remainingUses;
  final int totalUses;
  final String status;
  final ShopItem? catalogItem;
  final String? habitId;

  factory ActiveUtilityEffectRow.fromMap(Map<String, dynamic> map) {
    final utilityId = (map['utility_id'] ?? '').toString().trim();
    final catalogItem = ShopCatalog.getItemById(utilityId);
    return ActiveUtilityEffectRow(
      id: (map['id'] ?? '').toString().trim(),
      userId: (map['user_id'] ?? '').toString().trim(),
      utilityId: utilityId,
      utilityType: _typeFromUtilityId(utilityId),
      activatedAtMillis: (map['activated_at_millis'] as num?)?.toInt() ??
          _dateTimeToMillis(map['activated_at']),
      remainingUses: (map['remaining_uses'] as num?)?.toInt() ?? 0,
      totalUses: (map['total_uses'] as num?)?.toInt() ?? 0,
      status: (map['status'] ?? '').toString().trim(),
      catalogItem: catalogItem,
      habitId: (map['habit_id'] ?? '').toString().trim(),
    );
  }

  static ActiveUtilityEffectType _typeFromUtilityId(String utilityId) {
    final item = ShopCatalog.getItemById(utilityId);
    switch (item?.type) {
      case ShopItemType.coinBoost:
        return ActiveUtilityEffectType.coinBoost;
      case ShopItemType.streakShield:
        return ActiveUtilityEffectType.streakShield;
      case ShopItemType.xpBoost:
      default:
        return ActiveUtilityEffectType.xpBoost;
    }
  }

  static int _dateTimeToMillis(dynamic value) {
    final parsed = DateTime.tryParse((value ?? '').toString().trim());
    return parsed?.toUtc().millisecondsSinceEpoch ?? 0;
  }
}
