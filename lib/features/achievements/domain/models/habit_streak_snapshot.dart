class HabitStreakSnapshot {
  const HabitStreakSnapshot({
    required this.habitId,
    required this.currentStreak,
    required this.bestStreak,
    required this.totalCompletedDays,
  });

  final String habitId;
  final int currentStreak;
  final int bestStreak;
  final int totalCompletedDays;

  static const empty = HabitStreakSnapshot(
    habitId: '',
    currentStreak: 0,
    bestStreak: 0,
    totalCompletedDays: 0,
  );
}
