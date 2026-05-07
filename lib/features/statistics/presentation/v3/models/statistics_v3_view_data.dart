import 'package:flutter/material.dart';

class StatisticsV3FamilyItem {
  const StatisticsV3FamilyItem({
    required this.name,
    required this.emoji,
    required this.color,
    required this.completedCount,
  });

  final String name;
  final String emoji;
  final Color color;
  final int completedCount;
}

class StatisticsV3BestMomentInsight {
  const StatisticsV3BestMomentInsight({
    required this.hasData,
    required this.slot,
    required this.label,
    required this.count,
  });

  final bool hasData;
  final StatisticsV3BestMomentSlot slot;
  final String label;
  final int count;
}

enum StatisticsV3BestMomentSlot {
  morning,
  noon,
  afternoon,
  night,
}

class StatisticsV3HighlightedHabitItem {
  const StatisticsV3HighlightedHabitItem({
    required this.habitId,
    required this.name,
    required this.emoji,
    required this.completedCount,
  });

  final String habitId;
  final String name;
  final String emoji;
  final int completedCount;
}

class StatisticsV3WeeklyActivityDay {
  const StatisticsV3WeeklyActivityDay({
    required this.date,
    required this.completedCount,
    required this.expectedCount,
    required this.percentage,
    required this.isToday,
    required this.isFuture,
  });

  final DateTime date;
  final int completedCount;
  final int expectedCount;
  final int percentage;
  final bool isToday;
  final bool isFuture;
}

class StatisticsV3WeeklyImprovementData {
  const StatisticsV3WeeklyImprovementData({
    required this.hasComparison,
    required this.currentWeekPercentage,
    required this.previousWeekPercentage,
    required this.deltaPercentage,
  });

  final bool hasComparison;
  final int currentWeekPercentage;
  final int previousWeekPercentage;
  final int deltaPercentage;
}

class StatisticsV3ViewData {
  const StatisticsV3ViewData({
    required this.totalDays,
    required this.completedHabits,
    required this.xpGained,
    required this.amberGained,
    required this.activeDays,
    required this.consistencyPct,
    required this.families,
    required this.bestMoment,
    required this.highlightedHabits,
    required this.weeklyActivity,
    required this.weeklyImprovement,
  });

  final int totalDays;
  final int completedHabits;
  final int xpGained;
  final int amberGained;
  final int activeDays;
  final int consistencyPct;
  final List<StatisticsV3FamilyItem> families;
  final StatisticsV3BestMomentInsight bestMoment;
  final List<StatisticsV3HighlightedHabitItem> highlightedHabits;
  final List<StatisticsV3WeeklyActivityDay> weeklyActivity;
  final StatisticsV3WeeklyImprovementData weeklyImprovement;
}
