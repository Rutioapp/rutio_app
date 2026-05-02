enum LevelEventType {
  normalLevelUp,
  firstMilestone,
  majorMilestone,
}

class LevelEvent {
  const LevelEvent({
    required this.level,
    required this.type,
  });

  final int level;
  final LevelEventType type;
}
