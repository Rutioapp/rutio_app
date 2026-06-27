import '../domain/models/achievement.dart';
import '../domain/models/unlocked_achievement_record.dart';
import 'achievement_catalog.dart';
import 'achievement_rewards.dart';

class AchievementRewardResolver {
  const AchievementRewardResolver._();

  static AchievementRewardValues resolveForUnlockedRecord(
    UnlockedAchievementRecord record, {
    Achievement? achievement,
  }) {
    final resolvedAchievement =
        achievement ?? AchievementCatalog.achievementForRecord(record);
    return AchievementRewards.resolveForAchievement(
      record.id,
      tier: record.tier,
      xpReward: resolvedAchievement?.xpReward,
      ambarReward: resolvedAchievement?.ambarReward,
    );
  }
}
