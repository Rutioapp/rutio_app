import 'achievement.dart';

class UnlockedAchievementRecord {
  const UnlockedAchievementRecord({
    required this.id,
    required this.type,
    required this.tier,
    required this.unlockedAt,
    required this.habitId,
    required this.habitName,
    required this.familyId,
    required this.targetValue,
  });

  final String id;
  final AchievementType type;
  final AchievementTier tier;
  final DateTime unlockedAt;
  final String habitId;
  final String habitName;
  final String familyId;
  final int targetValue;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.key,
      'tier': tier.key,
      'unlockedAt': unlockedAt.toUtc().toIso8601String(),
      'habitId': habitId,
      'habitName': habitName,
      'familyId': familyId,
      'targetValue': targetValue,
    };
  }

  static UnlockedAchievementRecord? fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? '').toString().trim();
    if (id.isEmpty) return null;

    final unlockedAtRaw = (json['unlockedAt'] ?? '').toString().trim();
    final unlockedAt =
        DateTime.tryParse(unlockedAtRaw)?.toLocal() ?? DateTime.now();

    return UnlockedAchievementRecord(
      id: id,
      type: AchievementTypeX.fromKey((json['type'] ?? '').toString()),
      tier: AchievementTierX.fromKey((json['tier'] ?? '').toString()),
      unlockedAt: unlockedAt,
      habitId: (json['habitId'] ?? '').toString(),
      habitName: (json['habitName'] ?? '').toString(),
      familyId: (json['familyId'] ?? '').toString(),
      targetValue: (json['targetValue'] as num?)?.toInt() ?? 0,
    );
  }
}
