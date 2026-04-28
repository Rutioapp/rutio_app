import '../domain/models/achievement.dart';

class AchievementRewardValues {
  const AchievementRewardValues({
    required this.rewardXp,
    required this.rewardAmber,
  });

  final int rewardXp;
  final int rewardAmber;

  int get xp => rewardXp;
  int get ambar => rewardAmber;
}

class AchievementRewards {
  const AchievementRewards._();

  static const Map<AchievementTier, AchievementRewardValues> _tierRewards =
      <AchievementTier, AchievementRewardValues>{
        AchievementTier.oldWood: AchievementRewardValues(
          rewardXp: 50,
          rewardAmber: 25,
        ),
        AchievementTier.wood: AchievementRewardValues(
          rewardXp: 50,
          rewardAmber: 25,
        ),
        AchievementTier.stone: AchievementRewardValues(
          rewardXp: 100,
          rewardAmber: 50,
        ),
        AchievementTier.bronze: AchievementRewardValues(
          rewardXp: 200,
          rewardAmber: 100,
        ),
        AchievementTier.silver: AchievementRewardValues(
          rewardXp: 400,
          rewardAmber: 200,
        ),
        AchievementTier.gold: AchievementRewardValues(
          rewardXp: 800,
          rewardAmber: 400,
        ),
        AchievementTier.diamond: AchievementRewardValues(
          rewardXp: 1600,
          rewardAmber: 750,
        ),
        AchievementTier.prismaticDiamond: AchievementRewardValues(
          rewardXp: 3500,
          rewardAmber: 1500,
        ),
      };

  // TODO: Add per-achievement overrides here when difficulty-based rewards are defined.
  static const Map<String, AchievementRewardValues> _overrides =
      <String, AchievementRewardValues>{};

  static AchievementRewardValues getAchievementReward(AchievementTier tier) {
    return _tierRewards[tier] ?? _tierRewards[AchievementTier.wood]!;
  }

  static AchievementRewardValues resolveForAchievement(
    String achievementId, {
    AchievementTier? tier,
    int? xpReward,
    int? ambarReward,
  }) {
    final override = _overrides[achievementId];
    final tierReward = tier == null ? null : getAchievementReward(tier);
    return AchievementRewardValues(
      rewardXp: xpReward ?? override?.rewardXp ?? tierReward?.rewardXp ?? 0,
      rewardAmber:
          ambarReward ?? override?.rewardAmber ?? tierReward?.rewardAmber ?? 0,
    );
  }

  static Achievement applyDefaults(Achievement achievement) {
    final rewards = resolveForAchievement(
      achievement.id,
      tier: achievement.tier,
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
