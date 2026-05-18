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
  final int? previousWeekCompleted;
  final int? currentWeekCompleted;
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
  final Map<DateTime, int> completionTimesByDay;

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
    required this.previousWeekCompleted,
    required this.currentWeekCompleted,
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
    required this.completionTimesByDay,
  });

  bool get isCheckHabit => !isCounter;

  String get familyAndObjective => objectiveSummary.isEmpty
      ? familyName
      : '$familyName ${String.fromCharCode(0x00B7)} $objectiveSummary';

  int countForDate(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    return countsByDay[key] ?? 0;
  }

  num countValueForDate(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    final value = countValuesByDay[key];
    if (value == null || value < 0) return 0;
    return value;
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

class HabitStatsBestMoment {
  final HabitStatsBestMomentSlot slot;
  final int completionCount;

  const HabitStatsBestMoment({
    required this.slot,
    required this.completionCount,
  });
}

enum HabitStatsMonthDayStatus {
  completed,
  skipped,
  missed,
  future,
  notScheduled,
}

enum HabitStatsMonthlyObjectiveUnit {
  days,
  times,
}

enum HabitStatsComparisonTrend {
  better,
  same,
  worse,
  unavailable,
}

class HabitStatsMonthDayState {
  final DateTime date;
  final HabitStatsMonthDayStatus status;

  const HabitStatsMonthDayState({
    required this.date,
    required this.status,
  });
}

class HabitStatsMonthlyComparisonData {
  final int currentCompleted;
  final int previousCompleted;
  final int delta;
  final bool hasComparison;
  final HabitStatsComparisonTrend trend;

  const HabitStatsMonthlyComparisonData({
    required this.currentCompleted,
    required this.previousCompleted,
    required this.delta,
    required this.hasComparison,
    required this.trend,
  });
}

class HabitStatsMonthlyData {
  final int monthlyObjective;
  final int elapsedTrackableDays;
  final int expectedToDate;
  final int futureScheduledDays;
  final HabitStatsMonthlyObjectiveUnit objectiveUnit;
  final int completedDays;
  final int skippedDays;
  final int missedDays;
  final int totalTrackableDays;
  final double consistency;
  final int bestStreak;
  final int totalDone;
  final HabitStatsBestMoment? bestMoment;
  final List<HabitStatsMonthDayState> days;

  const HabitStatsMonthlyData({
    required this.monthlyObjective,
    required this.elapsedTrackableDays,
    required this.expectedToDate,
    required this.futureScheduledDays,
    required this.objectiveUnit,
    required this.completedDays,
    required this.skippedDays,
    required this.missedDays,
    required this.totalTrackableDays,
    required this.consistency,
    required this.bestStreak,
    required this.totalDone,
    required this.bestMoment,
    required this.days,
  });
}

class HabitStatsYearMonthSummary {
  final int month;
  final int completedDays;
  final num accumulatedValue;
  final int trackableDays;
  final HabitStatsYearMonthStatus status;
  final int? performancePct;
  final bool isCurrentMonth;

  const HabitStatsYearMonthSummary({
    required this.month,
    required this.completedDays,
    required this.accumulatedValue,
    required this.trackableDays,
    this.status = HabitStatsYearMonthStatus.empty,
    this.performancePct,
    this.isCurrentMonth = false,
  });

  HabitStatsYearMonthSummary copyWith({
    HabitStatsYearMonthStatus? status,
    int? performancePct,
    bool clearPerformancePct = false,
    bool? isCurrentMonth,
  }) {
    return HabitStatsYearMonthSummary(
      month: month,
      completedDays: completedDays,
      accumulatedValue: accumulatedValue,
      trackableDays: trackableDays,
      status: status ?? this.status,
      performancePct: clearPerformancePct
          ? null
          : (performancePct ?? this.performancePct),
      isCurrentMonth: isCurrentMonth ?? this.isCurrentMonth,
    );
  }
}

enum HabitStatsYearMonthStatus {
  unavailable,
  future,
  empty,
  low,
  medium,
  high,
}

extension HabitStatsYearMonthStatusX on HabitStatsYearMonthStatus {
  bool get hasActivity =>
      this == HabitStatsYearMonthStatus.low ||
      this == HabitStatsYearMonthStatus.medium ||
      this == HabitStatsYearMonthStatus.high;
}

class HabitStatsYearMetrics {
  final int year;
  final int completedTotal;
  final int trackableTotal;
  final num accumulatedTotal;
  final int consistencyPct;
  final int activeMonths;
  final HabitStatsYearMonthSummary? bestMonth;
  final List<HabitStatsYearMonthSummary> months;

  const HabitStatsYearMetrics({
    required this.year,
    required this.completedTotal,
    required this.trackableTotal,
    required this.accumulatedTotal,
    required this.consistencyPct,
    required this.activeMonths,
    required this.bestMonth,
    required this.months,
  });
}
