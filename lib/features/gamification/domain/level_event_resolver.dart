import 'level_event.dart';

class LevelEventResolver {
  const LevelEventResolver();

  static const int minimumCelebrationLevel = 2;
  static const int firstMilestoneLevel = 5;
  static const int majorMilestoneStep = 10;

  bool isCelebrationEligibleLevel(int level) =>
      level >= minimumCelebrationLevel;

  LevelEventType eventTypeForLevel(int level) {
    final safeLevel =
        level < minimumCelebrationLevel ? minimumCelebrationLevel : level;
    if (safeLevel == firstMilestoneLevel) {
      return LevelEventType.firstMilestone;
    }
    if (safeLevel % majorMilestoneStep == 0) {
      return LevelEventType.majorMilestone;
    }
    return LevelEventType.normalLevelUp;
  }

  List<LevelEvent> resolveLevelUps({
    required int previousLevel,
    required int currentLevel,
  }) {
    final fromLevel = previousLevel < 1 ? 1 : previousLevel;
    final toLevel = currentLevel < 1 ? 1 : currentLevel;
    if (toLevel <= fromLevel) return const <LevelEvent>[];
    if (toLevel < minimumCelebrationLevel) return const <LevelEvent>[];

    final startLevel = (fromLevel + 1) < minimumCelebrationLevel
        ? minimumCelebrationLevel
        : fromLevel + 1;

    final events = <LevelEvent>[];
    for (var level = startLevel; level <= toLevel; level++) {
      events.add(
        LevelEvent(
          level: level,
          type: eventTypeForLevel(level),
        ),
      );
    }
    return events;
  }
}
