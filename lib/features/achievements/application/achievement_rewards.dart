import '../domain/models/achievement.dart';

class AchievementRewardValues {
  const AchievementRewardValues({
    required this.xp,
    required this.ambar,
  });

  final int xp;
  final int ambar;
}

class AchievementRewards {
  const AchievementRewards._();

  static const int defaultXp = 20;
  static const int defaultAmbar = 20;

  // TODO: Add per-achievement overrides here when difficulty-based rewards are defined.
  static const Map<String, AchievementRewardValues> _overrides =
      <String, AchievementRewardValues>{};

  static AchievementRewardValues resolveForAchievement(
    String achievementId, {
    int? xpReward,
    int? ambarReward,
  }) {
    final override = _overrides[achievementId];
    return AchievementRewardValues(
      xp: xpReward ?? override?.xp ?? defaultXp,
      ambar: ambarReward ?? override?.ambar ?? defaultAmbar,
    );
  }

  static Achievement applyDefaults(Achievement achievement) {
    final rewards = resolveForAchievement(
      achievement.id,
      xpReward: achievement.xpReward > 0 ? achievement.xpReward : null,
      ambarReward: achievement.ambarReward > 0 ? achievement.ambarReward : null,
    );

    return Achievement(
      id: achievement.id,
      type: achievement.type,
      tier: achievement.tier,
      title: achievement.title,
      description: achievement.description,
      hidden: achievement.hidden,
      targetValue: achievement.targetValue,
      assetPath: achievement.assetPath,
      sortOrder: achievement.sortOrder,
      habitId: achievement.habitId,
      habitName: achievement.habitName,
      familyId: achievement.familyId,
      xpReward: rewards.xp,
      ambarReward: rewards.ambar,
      collection: achievement.collection,
    );
  }
}
