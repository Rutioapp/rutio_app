import 'statistics_period.dart';
import 'statistics_range.dart';

enum StatisticsHabitType { check, count }

class StatisticsHabitSummary {
  const StatisticsHabitSummary({
    required this.id,
    required this.title,
    required this.familyId,
    required this.type,
    required this.target,
    required this.scheduledDays,
    required this.doneDays,
    required this.currentStreak,
    required this.bestStreak,
    required this.last7Values,
    required this.periodVolume,
    this.countProgress,
  });

  final String id;
  final String title;
  final String familyId;
  final StatisticsHabitType type;
  final int target;
  final int scheduledDays;
  final int doneDays;
  final int currentStreak;
  final int bestStreak;
  final List<int> last7Values;
  final int periodVolume;
  final CountHabitProgressSnapshot? countProgress;

  int get completionPct {
    if (scheduledDays <= 0) return 0;
    return ((doneDays / scheduledDays) * 100).round();
  }

  double get periodAverage {
    if (scheduledDays <= 0) return 0;
    return periodVolume / scheduledDays;
  }
}

class CountHabitProgressSnapshot {
  const CountHabitProgressSnapshot({
    required this.target,
    required this.goalCompletedDays,
    required this.partialProgressDays,
    required this.totalAccumulated,
    required this.activeDays,
    required this.bestDay,
    required this.dailyAverage,
    required this.activeDayAverage,
    required this.compliancePct,
    required this.currentGoalStreak,
  });

  final int target;
  final int goalCompletedDays;
  final int partialProgressDays;
  final int totalAccumulated;
  final int activeDays;
  final int bestDay;
  final double dailyAverage;
  final double activeDayAverage;
  final double compliancePct;
  final int currentGoalStreak;
}

class StatisticsOverviewSummary {
  const StatisticsOverviewSummary({
    required this.period,
    required this.range,
    required this.totalHabits,
    required this.totalFamilies,
    required this.overallConsistencyPct,
    required this.topHabits,
    required this.familyConsistencyPct,
    required this.bestMomentPercents,
    required this.bestMomentLabel,
    required this.monthConsistencyByDay,
  });

  final StatisticsPeriod period;
  final StatisticsRange range;
  final int totalHabits;
  final int totalFamilies;
  final int overallConsistencyPct;
  final List<StatisticsHabitSummary> topHabits;
  final Map<String, int> familyConsistencyPct;
  final Map<String, int> bestMomentPercents;
  final String bestMomentLabel;
  final Map<int, double> monthConsistencyByDay;
}

class StatisticsHabitDetailSummary {
  const StatisticsHabitDetailSummary({
    required this.period,
    required this.range,
    required this.habit,
    required this.thisWeekDoneDays,
    required this.lastWeekDoneDays,
    required this.insight,
  });

  final StatisticsPeriod period;
  final StatisticsRange range;
  final StatisticsHabitSummary habit;
  final int thisWeekDoneDays;
  final int lastWeekDoneDays;
  final String insight;
}
