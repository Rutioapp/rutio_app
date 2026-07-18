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
    XpMutationOrigin origin = XpMutationOrigin.gameplayReward,
  }) {
    final safePreviousXp = previousXp < 0 ? 0 : previousXp;
    final safeNewXp = newXp < 0 ? 0 : newXp;
    final safeLastCelebratedLevel =
        lastCelebratedLevel < 0 ? 0 : lastCelebratedLevel;

    if (!_shouldCelebrateOrigin(origin)) {
      return LevelUpCelebrationDecision(
        event: null,
        lastCelebratedLevel: safeLastCelebratedLevel,
      );
    }

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
    if (!_levelEventResolver.isCelebrationEligibleLevel(finalReachedLevel)) {
      return LevelUpCelebrationDecision(
        event: null,
        lastCelebratedLevel: safeLastCelebratedLevel,
      );
    }
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
      // Celebration persistence is intentionally deferred until the overlay is
      // actually consumed by the user.
      lastCelebratedLevel: safeLastCelebratedLevel,
    );
  }

  bool _shouldCelebrateOrigin(XpMutationOrigin origin) {
    switch (origin) {
      case XpMutationOrigin.userAction:
      case XpMutationOrigin.gameplayReward:
        return true;
      case XpMutationOrigin.hydration:
      case XpMutationOrigin.localRestore:
      case XpMutationOrigin.remoteSync:
      case XpMutationOrigin.demoSeed:
      case XpMutationOrigin.adminAdjustment:
        return false;
    }
  }
}
