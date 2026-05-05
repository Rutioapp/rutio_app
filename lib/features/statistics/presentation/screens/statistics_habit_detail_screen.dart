import 'package:flutter/material.dart';

import '../../domain/statistics_period.dart';

/// Compatibility screen kept for Phase 1 references.
/// The modular detail implementation currently lives in
/// `statistics_habit_detail_page.dart`.
class StatisticsHabitDetailScreen extends StatelessWidget {
  const StatisticsHabitDetailScreen({
    super.key,
    required this.habitId,
    this.initialPeriod = StatisticsPeriod.week,
  });

  final String habitId;
  final StatisticsPeriod initialPeriod;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de habito')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Compat wrapper activo para $habitId (${initialPeriod.name}).',
        ),
      ),
    );
  }
}

