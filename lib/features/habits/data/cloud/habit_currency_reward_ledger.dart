import 'package:flutter/foundation.dart';

@immutable
class HabitCurrencyRewardLedgerEntry {
  const HabitCurrencyRewardLedgerEntry({
    required this.id,
    required this.userId,
    required this.requestId,
    required this.operationType,
    required this.sourceType,
    required this.sourceId,
    required this.habitId,
    required this.logicalDateKey,
    required this.coinDelta,
    required this.balanceAfter,
    required this.createdAt,
    required this.isIdempotent,
    this.baseXp = 0,
    this.bonusXp = 0,
    this.bonusCoins = 0,
    this.appliedEffectIds = const <String>[],
    this.relatedLedgerId,
  });

  final String id;
  final String userId;
  final String requestId;
  final String operationType;
  final String sourceType;
  final String sourceId;
  final String habitId;
  final String logicalDateKey;
  final int coinDelta;
  final int balanceAfter;
  final DateTime createdAt;
  final bool isIdempotent;
  final int baseXp;
  final int bonusXp;
  final int bonusCoins;
  final List<String> appliedEffectIds;
  final String? relatedLedgerId;

  factory HabitCurrencyRewardLedgerEntry.fromMap(Map<String, dynamic> map) {
    return HabitCurrencyRewardLedgerEntry(
      id: (map['id'] ?? '').toString().trim(),
      userId: (map['user_id'] ?? '').toString().trim(),
      requestId: (map['request_id'] ?? '').toString().trim(),
      operationType: (map['operation_type'] ?? '').toString().trim(),
      sourceType: (map['source_type'] ?? '').toString().trim(),
      sourceId: (map['source_id'] ?? '').toString().trim(),
      habitId: (map['habit_id'] ?? '').toString().trim(),
      logicalDateKey: (map['logical_date_key'] ?? '').toString().trim(),
      coinDelta: _safeInt(map['coin_delta']),
      balanceAfter: _safeInt(map['balance_after']),
      createdAt: _safeDateTime(map['created_at']),
      isIdempotent: map['is_idempotent'] == true ||
          (map['is_idempotent']?.toString().trim().toLowerCase() == 'true'),
      baseXp: _safeInt(map['base_xp']),
      bonusXp: _safeInt(map['bonus_xp']),
      bonusCoins: _safeInt(map['bonus_coins']),
      appliedEffectIds: _stringList(map['applied_effect_ids']),
      relatedLedgerId: _nullableTrim(map['related_ledger_id']),
    );
  }

  bool get isReverse => operationType == 'reverse';

  bool get isApply => operationType == 'apply';

  static int _safeInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString().trim()) ?? 0;
  }

  static DateTime _safeDateTime(dynamic value) {
    if (value is DateTime) return value.toUtc();
    final normalized = (value ?? '').toString().trim();
    final parsed = DateTime.tryParse(normalized);
    return (parsed ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true))
        .toUtc();
  }

  static String? _nullableTrim(dynamic value) {
    final normalized = (value ?? '').toString().trim();
    return normalized.isEmpty ? null : normalized;
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value
          .map((entry) => entry.toString().trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }
}
