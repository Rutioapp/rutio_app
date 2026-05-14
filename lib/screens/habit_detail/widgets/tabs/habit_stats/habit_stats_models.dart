enum HabitStatsPeriod {
  week,
  month,
  year,
}

class HabitStatsShellData {
  final String title;
  final String subtitle;
  final String typeLabel;
  final bool isCounter;
  final int currentStreak;
  final int bestStreak;
  final int completedDays;
  final int totalCompletions;
  final int targetValue;
  final Map<DateTime, int> countsByDay;

  const HabitStatsShellData({
    required this.title,
    required this.subtitle,
    required this.typeLabel,
    required this.isCounter,
    required this.currentStreak,
    required this.bestStreak,
    required this.completedDays,
    required this.totalCompletions,
    required this.targetValue,
    required this.countsByDay,
  });

  int countForDate(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    return countsByDay[key] ?? 0;
  }
}
