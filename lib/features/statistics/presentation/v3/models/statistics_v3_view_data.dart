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
    required this.label,
    required this.count,
  });

  final bool hasData;
  final String label;
  final int count;
}

class StatisticsV3HighlightedHabitItem {
  const StatisticsV3HighlightedHabitItem({
    required this.name,
    required this.emoji,
    required this.completedCount,
  });

  final String name;
  final String emoji;
  final int completedCount;
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
}
