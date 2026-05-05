class CountHabitProgress {
  const CountHabitProgress({
    required this.date,
    required this.rawValue,
    required this.normalizedProgress,
    required this.goalCompleted,
  });

  final DateTime date;
  final int rawValue;
  final double normalizedProgress;
  final bool goalCompleted;
}
