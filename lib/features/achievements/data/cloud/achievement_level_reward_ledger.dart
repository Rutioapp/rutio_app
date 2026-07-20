import 'package:flutter/foundation.dart';

@immutable
class AchievementLevelRewardLedgerEntry {
  const AchievementLevelRewardLedgerEntry({
    required this.id,
    required this.userId,
    required this.requestId,
    required this.operationType,
    required this.sourceType,
    required this.sourceId,
    required this.coinDelta,
    required this.balanceAfter,
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
  final int coinDelta;
  final int balanceAfter;
  final DateTime createdAt;
  final bool isIdempotent;
  final String? relatedLedgerId;

  factory AchievementLevelRewardLedgerEntry.fromMap(
    Map<String, dynamic> map,
  ) {
    return AchievementLevelRewardLedgerEntry(
      id: (map['id'] ?? '').toString().trim(),
      userId: (map['user_id'] ?? '').toString().trim(),
      requestId: (map['request_id'] ?? '').toString().trim(),
      operationType: (map['operation_type'] ?? '').toString().trim(),
      sourceType: (map['source_type'] ?? '').toString().trim(),
      sourceId: (map['source_id'] ?? '').toString().trim(),
      coinDelta: _safeInt(map['coin_delta']),
      balanceAfter: _safeInt(map['balance_after']),
      createdAt: _safeDateTime(map['created_at']),
      isIdempotent: map['is_idempotent'] == true ||
          (map['is_idempotent']?.toString().trim().toLowerCase() == 'true'),
      relatedLedgerId: _nullableTrim(map['related_ledger_id']),
    );
  }

  bool get isAchievementClaim => sourceType == 'achievement_reward';

  bool get isLevelClaim => sourceType == 'level_reward';

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
