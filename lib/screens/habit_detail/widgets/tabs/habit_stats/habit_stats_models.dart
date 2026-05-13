import 'package:flutter/material.dart';

enum HabitStatsPeriod { week, month, year }

class HabitStatsMetricCardData {
  const HabitStatsMetricCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.badgeColor,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color badgeColor;
}

class HabitStatsBestCountDay {
  const HabitStatsBestCountDay({required this.main});

  final String main;
}

class HabitStatsData {
  const HabitStatsData({
    required this.title,
    required this.familyAndGoalLabel,
    required this.isCountHabit,
    required this.countTarget,
    required this.countUnit,
    required this.currentStreak,
    required this.bestStreak,
    required this.totalDone,
    required this.last7Days,
    required this.last7Values,
    required this.last7DoneStates,
    required this.last7SkippedStates,
    required this.metricCards,
    required this.comparisonTitle,
    required this.comparisonMain,
    required this.comparisonSubtitle,
    required this.comparisonTrendText,
    required this.comparisonTrendPositive,
    required this.insightText,
  });

  final String title;
  final String familyAndGoalLabel;
  final bool isCountHabit;
  final double countTarget;
  final String countUnit;
  final int currentStreak;
  final int bestStreak;
  final double totalDone;
  final List<DateTime> last7Days;
  final List<double> last7Values;
  final List<bool> last7DoneStates;
  final List<bool> last7SkippedStates;
  final List<HabitStatsMetricCardData> metricCards;
  final String comparisonTitle;
  final String comparisonMain;
  final String comparisonSubtitle;
  final String comparisonTrendText;
  final bool comparisonTrendPositive;
  final String insightText;
}
