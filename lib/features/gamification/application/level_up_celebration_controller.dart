import '../domain/level_event.dart';
import '../domain/level_event_resolver.dart';
import '../domain/level_progression.dart';

class LevelUpCelebrationDecision {
  const LevelUpCelebrationDecision({
    required this.event,
    required this.lastCelebratedLevel,
  });

  final LevelEvent? event;
  final int lastCelebratedLevel;
}

class LevelUpCelebrationController {
  const LevelUpCelebrationController({
    LevelEventResolver levelEventResolver = const LevelEventResolver(),
  }) : _levelEventResolver = levelEventResolver;

  final LevelEventResolver _levelEventResolver;

  LevelUpCelebrationDecision evaluateXpChange({
    required int previousXp,
    required int newXp,
    required int lastCelebratedLevel,
  }) {
    final safePreviousXp = previousXp < 0 ? 0 : previousXp;
    final safeNewXp = newXp < 0 ? 0 : newXp;
    final safeLastCelebratedLevel = lastCelebratedLevel < 0
        ? 0
        : lastCelebratedLevel;

    final previousLevel = LevelProgression.fromTotalXp(safePreviousXp).level;
    final currentLevel = LevelProgression.fromTotalXp(safeNewXp).level;

    if (currentLevel <= previousLevel) {
      return LevelUpCelebrationDecision(
        event: null,
        lastCelebratedLevel: safeLastCelebratedLevel,
      );
    }

    // For now we only celebrate the final reached level when one XP grant
    // crosses multiple levels.
    final finalReachedLevel = currentLevel;
    if (finalReachedLevel <= safeLastCelebratedLevel) {
      return LevelUpCelebrationDecision(
        event: null,
        lastCelebratedLevel: safeLastCelebratedLevel,
      );
    }

    return LevelUpCelebrationDecision(
      event: LevelEvent(
        level: finalReachedLevel,
        type: _levelEventResolver.eventTypeForLevel(finalReachedLevel),
      ),
      lastCelebratedLevel: finalReachedLevel,
    );
  }
}
