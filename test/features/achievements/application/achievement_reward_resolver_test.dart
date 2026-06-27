import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/achievements/application/achievement_reward_resolver.dart';
import 'package:rutio/features/achievements/domain/models/achievement.dart';
import 'package:rutio/features/achievements/domain/models/unlocked_achievement_record.dart';

void main() {
  group('AchievementRewardResolver', () {
    test('uses catalog-backed rewards for unlocked records', () {
      final record = UnlockedAchievementRecord(
        id: 'special:flash',
        type: AchievementType.special,
        tier: AchievementTier.bronze,
        unlockedAt: DateTime(2026, 1, 1),
        habitId: 'special:flash',
        habitName: 'Flash',
        familyId: 'special',
        targetValue: 8,
      );

      final reward = AchievementRewardResolver.resolveForUnlockedRecord(record);

      expect(reward.rewardXp, 200);
      expect(reward.rewardAmber, 100);
    });

    test('keeps wallet reward at zero when achievement has no coin reward', () {
      final record = UnlockedAchievementRecord(
        id: 'custom:no-coin',
        type: AchievementType.special,
        tier: AchievementTier.gold,
        unlockedAt: DateTime(2026, 1, 1),
        habitId: 'custom:no-coin',
        habitName: 'No Coin',
        familyId: 'special',
        targetValue: 1,
      );
      final achievement = Achievement(
        id: record.id,
        type: record.type,
        tier: record.tier,
        title: record.habitName,
        description: '',
        hidden: false,
        targetValue: record.targetValue,
        assetPath: 'assets/achievements/no-coin.png',
        sortOrder: 0,
        habitId: record.habitId,
        habitName: record.habitName,
        familyId: record.familyId,
        xpReward: 75,
        ambarReward: 0,
      );

      final reward = AchievementRewardResolver.resolveForUnlockedRecord(
        record,
        achievement: achievement,
      );

      expect(reward.rewardXp, 75);
      expect(reward.rewardAmber, 0);
    });
  });
}
