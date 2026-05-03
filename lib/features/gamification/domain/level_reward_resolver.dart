class LevelRewardResolver {
  const LevelRewardResolver();

  static const Map<int, int> _fixedMilestoneRewards = <int, int>{
    5: 50,
    10: 150,
    20: 300,
    30: 500,
    40: 750,
    50: 1000,
  };

  int rewardForLevel(int level) {
    if (level <= 0) return 0;

    final fixedReward = _fixedMilestoneRewards[level];
    if (fixedReward != null) return fixedReward;

    if (level > 50 && level % 10 == 0) {
      return level * 20;
    }

    return 0;
  }

  bool hasRewardForLevel(int level) => rewardForLevel(level) > 0;
}
