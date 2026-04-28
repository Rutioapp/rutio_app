import 'package:flutter/foundation.dart';

@immutable
class RemoteUserProgress {
  const RemoteUserProgress({
    required this.userId,
    required this.level,
    required this.totalXp,
    required this.currentLevelXp,
    required this.nextLevelXp,
    required this.ambarBalance,
    required this.totalAmbarEarned,
    required this.totalAmbarSpent,
    this.createdAt,
    this.updatedAt,
    this.raw = const <String, dynamic>{},
  });

  final String userId;
  final int level;
  final int totalXp;
  final int currentLevelXp;
  final int nextLevelXp;
  final int ambarBalance;
  final int totalAmbarEarned;
  final int totalAmbarSpent;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> raw;

  factory RemoteUserProgress.fromMap(Map<String, dynamic> map) {
    final parsedTotalXp = _safeInt(map['total_xp'], fallback: 0);
    final fallbackCurrentLevelXp = parsedTotalXp % 100;
    final fallbackNextLevelXp = 100 - fallbackCurrentLevelXp;
    final parsedLevel = _safeInt(
      map['level'],
      fallback: 1 + (parsedTotalXp ~/ 100),
    );

    return RemoteUserProgress(
      userId: (map['user_id'] ?? map['userId'] ?? '').toString().trim(),
      level: parsedLevel < 1 ? 1 : parsedLevel,
      totalXp: parsedTotalXp < 0 ? 0 : parsedTotalXp,
      currentLevelXp: _safeInt(
        map['current_level_xp'],
        fallback: fallbackCurrentLevelXp,
      ),
      nextLevelXp: _safeInt(
        map['next_level_xp'],
        fallback: fallbackNextLevelXp < 1 ? 1 : fallbackNextLevelXp,
      ),
      ambarBalance: _safeInt(map['ambar_balance'], fallback: 0),
      totalAmbarEarned: _safeInt(map['total_ambar_earned'], fallback: 0),
      totalAmbarSpent: _safeInt(map['total_ambar_spent'], fallback: 0),
      createdAt: _nullableDateTime(map['created_at']),
      updatedAt: _nullableDateTime(map['updated_at']),
      raw: Map<String, dynamic>.from(map),
    );
  }

  Map<String, dynamic> toUpsertMap() {
    return <String, dynamic>{
      'user_id': userId,
      'level': level,
      'total_xp': totalXp,
      'current_level_xp': currentLevelXp,
      'next_level_xp': nextLevelXp,
      'ambar_balance': ambarBalance,
      'total_ambar_earned': totalAmbarEarned,
      'total_ambar_spent': totalAmbarSpent,
    };
  }

  static int _safeInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString().trim()) ?? fallback;
  }

  static DateTime? _nullableDateTime(dynamic value) {
    if (value == null) return null;
    final normalized = (value ?? '').toString().trim();
    if (normalized.isEmpty) return null;
    return DateTime.tryParse(normalized);
  }
}
