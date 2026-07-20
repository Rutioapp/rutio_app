import 'package:flutter/foundation.dart';

import '../../domain/models/active_utility_effect.dart';

@immutable
class UtilityConsumptionLedgerEntry {
  const UtilityConsumptionLedgerEntry({
    required this.id,
    required this.userId,
    required this.requestId,
    required this.operationType,
    required this.sourceType,
    required this.sourceId,
    required this.utilityId,
    required this.utilityType,
    required this.effectId,
    required this.totalUses,
    required this.remainingUses,
    required this.createdAt,
    required this.isIdempotent,
    this.relatedLedgerId,
  });

  final String id;
  final String userId;
  final String requestId;
  final String operationType;
  final String sourceType;
  final String sourceId;
  final String utilityId;
  final ActiveUtilityEffectType utilityType;
  final String effectId;
  final int totalUses;
  final int remainingUses;
  final DateTime createdAt;
  final bool isIdempotent;
  final String? relatedLedgerId;

  factory UtilityConsumptionLedgerEntry.fromMap(Map<String, dynamic> map) {
    return UtilityConsumptionLedgerEntry(
      id: (map['id'] ?? '').toString().trim(),
      userId: (map['user_id'] ?? '').toString().trim(),
      requestId: (map['request_id'] ?? '').toString().trim(),
      operationType: (map['operation_type'] ?? '').toString().trim(),
      sourceType: (map['source_type'] ?? '').toString().trim(),
      sourceId: (map['source_id'] ?? '').toString().trim(),
      utilityId: (map['utility_id'] ?? '').toString().trim(),
      utilityType: _parseUtilityType(map['utility_type']),
      effectId: (map['effect_id'] ?? '').toString().trim(),
      totalUses: _safeInt(map['total_uses']),
      remainingUses: _safeInt(map['remaining_uses']),
      createdAt: _safeDateTime(map['created_at']),
      isIdempotent: map['is_idempotent'] == true ||
          (map['is_idempotent']?.toString().trim().toLowerCase() == 'true'),
      relatedLedgerId: _nullableTrim(map['related_ledger_id']),
    );
  }

  bool get isActivate => operationType == 'activate';
  bool get isConsume => operationType == 'consume';
  bool get isRecover => operationType == 'recover';

  static ActiveUtilityEffectType _parseUtilityType(dynamic value) {
    switch ((value ?? '').toString().trim()) {
      case 'coinBoost':
        return ActiveUtilityEffectType.coinBoost;
      case 'streakShield':
        return ActiveUtilityEffectType.streakShield;
      case 'xpBoost':
      default:
        return ActiveUtilityEffectType.xpBoost;
    }
  }

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
}
