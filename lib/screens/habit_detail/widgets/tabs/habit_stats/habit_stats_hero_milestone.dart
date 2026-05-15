class HabitStatsHeroMilestoneProgress {
  final int from;
  final int to;
  final int current;

  const HabitStatsHeroMilestoneProgress({
    required this.from,
    required this.to,
    required this.current,
  });

  double get progress {
    final span = (to - from).toDouble();
    if (span <= 0) return 0;
    return ((current - from) / span).clamp(0.0, 1.0);
  }
}

HabitStatsHeroMilestoneProgress habitStatsHeroMilestoneProgressForStreak(int streak) {
  if (streak < 3) {
    return HabitStatsHeroMilestoneProgress(from: 0, to: 3, current: streak);
  }
  if (streak < 7) {
    return HabitStatsHeroMilestoneProgress(from: 3, to: 7, current: streak);
  }
  if (streak < 14) {
    return HabitStatsHeroMilestoneProgress(from: 7, to: 14, current: streak);
  }
  if (streak < 30) {
    return HabitStatsHeroMilestoneProgress(from: 14, to: 30, current: streak);
  }
  if (streak < 60) {
    return HabitStatsHeroMilestoneProgress(from: 30, to: 60, current: streak);
  }
  if (streak < 100) {
    return HabitStatsHeroMilestoneProgress(from: 60, to: 100, current: streak);
  }
  if (streak < 180) {
    return HabitStatsHeroMilestoneProgress(from: 100, to: 180, current: streak);
  }
  return HabitStatsHeroMilestoneProgress(from: 180, to: 365, current: streak);
}
