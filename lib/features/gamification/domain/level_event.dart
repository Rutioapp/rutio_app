enum LevelEventType {
  normalLevelUp,
  firstMilestone,
  majorMilestone,
}

enum XpMutationOrigin {
  hydration,
  localRestore,
  remoteSync,
  demoSeed,
  userAction,
  gameplayReward,
  adminAdjustment,
}

class LevelEvent {
  const LevelEvent({
    required this.level,
    required this.type,
  });

  final int level;
  final LevelEventType type;
}
