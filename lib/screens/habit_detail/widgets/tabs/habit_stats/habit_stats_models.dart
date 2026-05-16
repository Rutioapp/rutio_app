enum HabitStatsPeriod {
  week,
  month,
  year,
}

enum HabitStatsDayState {
  completed,
  skipped,
  pending,
  future,
}

enum HabitStatsBestMomentSlot {
  morning,
  noon,
  afternoon,
  night,
  unknown,
}

enum HabitStatsInsightTone {
  neutral,
  positive,
  amber,
  recovery,
  paused,
}

class HabitStatsInsight {
  final String title;
  final String body;
  final HabitStatsInsightTone tone;

  const HabitStatsInsight({
    required this.title,
    required this.body,
    required this.tone,
  });
}

class HabitStatsLast7DayItem {
  final DateTime date;
  final String weekdayLabel;
  final HabitStatsDayState state;

  const HabitStatsLast7DayItem({
    required this.date,
    required this.weekdayLabel,
    required this.state,
  });
}

class HabitStatsCountLast7DayItem {
  final DateTime date;
  final String weekdayLabel;
  final num value;
  final String valueLabel;
  final double fillRatio;

  const HabitStatsCountLast7DayItem({
    required this.date,
    required this.weekdayLabel,
    required this.value,
    required this.valueLabel,
    required this.fillRatio,
  });
}

class HabitStatsShellData {
  final String habitId;
  final String title;
  final String familyName;
  final String objectiveSummary;
  final String typeLabel;
  final bool isCounter;
  final int currentStreak;
  final int bestStreak;
  final int weeklyTarget;
  final int weeklyCompleted;
  final int weeklyConsistencyPct;
  final int? weeklyComparisonDeltaPct;
  final String bestMomentLabel;
  final HabitStatsBestMomentSlot bestMomentSlot;
  final bool hasBestMomentData;
  final List<HabitStatsLast7DayItem> last7Days;
  final List<HabitStatsCountLast7DayItem> countLast7Days;
  final num countDailyTarget;
  final String countUnitLabel;
  final Map<DateTime, int> countsByDay;
  final Map<DateTime, num> countValuesByDay;
  final Map<DateTime, bool> skipsByDay;

  const HabitStatsShellData({
    required this.habitId,
    required this.title,
    required this.familyName,
    required this.objectiveSummary,
    required this.typeLabel,
    required this.isCounter,
    required this.currentStreak,
    required this.bestStreak,
    required this.weeklyTarget,
    required this.weeklyCompleted,
    required this.weeklyConsistencyPct,
    required this.weeklyComparisonDeltaPct,
    required this.bestMomentLabel,
    required this.bestMomentSlot,
    required this.hasBestMomentData,
    required this.last7Days,
    required this.countLast7Days,
    required this.countDailyTarget,
    required this.countUnitLabel,
    required this.countsByDay,
    required this.countValuesByDay,
    required this.skipsByDay,
  });

  bool get isCheckHabit => !isCounter;

  String get familyAndObjective => objectiveSummary.isEmpty
      ? familyName
      : '$familyName ${String.fromCharCode(0x00B7)} $objectiveSummary';

  int countForDate(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    return countsByDay[key] ?? 0;
  }

  bool skippedForDate(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    return skipsByDay[key] == true;
  }
}

class HabitStatsCountMetricSummary {
  final num dailyTarget;
  final num weeklyTotal;
  final num dailyAverage;
  final int completionPct;
  final int expectedDays;
  final String unitLabel;

  const HabitStatsCountMetricSummary({
    required this.dailyTarget,
    required this.weeklyTotal,
    required this.dailyAverage,
    required this.completionPct,
    required this.expectedDays,
    required this.unitLabel,
  });
}

class HabitStatsCountBestDaySummary {
  final bool hasData;
  final String weekdayLabel;
  final num value;
  final String valueLabel;

  const HabitStatsCountBestDaySummary({
    required this.hasData,
    required this.weekdayLabel,
    required this.value,
    required this.valueLabel,
  });
}
