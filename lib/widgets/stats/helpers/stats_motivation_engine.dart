enum StatsMotivationTone {
  strongStreak,
  weeklyImprovement,
  steadyProgress,
  bestTime,
  goodCompliance,
  neutral,
}

class StatsMotivationInput {
  const StatsMotivationInput({
    required this.streakDays,
    required this.thisWeekDoneDays,
    required this.lastWeekDoneDays,
    required this.hasBestTime,
    required this.compliancePct,
  });

  final int streakDays;
  final int thisWeekDoneDays;
  final int lastWeekDoneDays;
  final bool hasBestTime;
  final int compliancePct;
}

class StatsMotivationPick {
  const StatsMotivationPick({
    required this.tone,
    required this.variant,
  });

  final StatsMotivationTone tone;
  final int variant;
}

class StatsMotivationEngine {
  const StatsMotivationEngine._();

  static StatsMotivationPick pick(StatsMotivationInput input) {
    final candidates = <StatsMotivationTone>[];
    final weeklyDelta = input.thisWeekDoneDays - input.lastWeekDoneDays;

    if (input.streakDays >= 7) {
      candidates.add(StatsMotivationTone.strongStreak);
    }
    if (weeklyDelta > 0) {
      candidates.add(StatsMotivationTone.weeklyImprovement);
    }
    if (weeklyDelta == 0 && input.thisWeekDoneDays > 0) {
      candidates.add(StatsMotivationTone.steadyProgress);
    }
    if (input.hasBestTime) {
      candidates.add(StatsMotivationTone.bestTime);
    }
    if (input.compliancePct >= 65) {
      candidates.add(StatsMotivationTone.goodCompliance);
    }

    if (candidates.isEmpty) {
      candidates.add(StatsMotivationTone.neutral);
    }

    final seed =
        (input.streakDays * 31) +
        (input.thisWeekDoneDays * 17) +
        (input.lastWeekDoneDays * 13) +
        (input.compliancePct * 7) +
        (input.hasBestTime ? 5 : 0);

    final idx = seed.abs() % candidates.length;
    final variant = (seed.abs() ~/ candidates.length) % 3;

    return StatsMotivationPick(
      tone: candidates[idx],
      variant: variant,
    );
  }
}
