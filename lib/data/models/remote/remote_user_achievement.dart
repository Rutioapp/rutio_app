import 'package:flutter/foundation.dart';

@immutable
class RemoteUserAchievement {
  const RemoteUserAchievement({
    this.id,
    required this.userId,
    required this.achievementId,
    this.familyId,
    required this.tier,
    required this.unlockedAt,
    required this.rewardXp,
    required this.rewardAmbar,
    required this.rewardApplied,
    this.createdAt,
    this.updatedAt,
    this.raw = const <String, dynamic>{},
  });

  final String? id;
  final String userId;
  final String achievementId;
  final String? familyId;
  final String tier;
  final DateTime unlockedAt;
  final int rewardXp;
  final int rewardAmbar;
  final bool rewardApplied;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> raw;

  factory RemoteUserAchievement.fromMap(Map<String, dynamic> map) {
    return RemoteUserAchievement(
      id: _nullableTrim(map['id']),
      userId: (map['user_id'] ?? map['userId'] ?? '').toString().trim(),
      achievementId: (map['achievement_id'] ?? map['achievementId'] ?? '')
          .toString()
          .trim(),
      familyId: _nullableTrim(map['family_id'] ?? map['familyId']),
      tier: (map['tier'] ?? '').toString().trim(),
      unlockedAt: _nullableDateTime(map['unlocked_at']) ?? DateTime.now(),
      rewardXp: _safeInt(map['reward_xp'], fallback: 0),
      rewardAmbar: _safeInt(map['reward_ambar'], fallback: 0),
      rewardApplied: _safeBool(map['reward_applied']),
      createdAt: _nullableDateTime(map['created_at']),
      updatedAt: _nullableDateTime(map['updated_at']),
      raw: Map<String, dynamic>.from(map),
    );
  }

  Map<String, dynamic> toUpsertMap() {
    final payload = <String, dynamic>{
      'user_id': userId,
      'achievement_id': achievementId,
      'family_id': familyId,
      'tier': tier,
      'unlocked_at': unlockedAt.toUtc().toIso8601String(),
      'reward_xp': rewardXp,
      'reward_ambar': rewardAmbar,
      'reward_applied': rewardApplied,
    };

    final remoteId = _nullableTrim(id);
    if (remoteId != null) {
      payload['id'] = remoteId;
    }

    payload.removeWhere((_, value) => value == null);
    return payload;
  }

  static String? _nullableTrim(dynamic value) {
    final normalized = (value ?? '').toString().trim();
    return normalized.isEmpty ? null : normalized;
  }

  static DateTime? _nullableDateTime(dynamic value) {
    if (value == null) return null;
    final normalized = (value ?? '').toString().trim();
    if (normalized.isEmpty) return null;
    return DateTime.tryParse(normalized);
  }

  static int _safeInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString().trim()) ?? fallback;
  }

  static bool _safeBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value > 0;
    final normalized = (value ?? '').toString().trim().toLowerCase();
    return normalized == 'true' || normalized == '1';
  }
}
