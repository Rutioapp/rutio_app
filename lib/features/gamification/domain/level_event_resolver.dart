import 'level_event.dart';

class LevelEventResolver {
  const LevelEventResolver();

  static const int firstMilestoneLevel = 5;
  static const int majorMilestoneStep = 10;

  LevelEventType eventTypeForLevel(int level) {
    final safeLevel = level < 1 ? 1 : level;
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

    final events = <LevelEvent>[];
    for (var level = fromLevel + 1; level <= toLevel; level++) {
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
