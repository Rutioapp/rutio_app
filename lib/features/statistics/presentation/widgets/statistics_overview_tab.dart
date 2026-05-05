import 'package:flutter/material.dart';

import '../../../../utils/family_theme.dart';
import '../../../../widgets/stats/helpers/stats_card_surface.dart';
import '../../../../widgets/stats/stats_best_time_of_day_card.dart';
import '../../../../widgets/stats/stats_month_heatmap.dart';
import '../../domain/statistics_models.dart';

class StatisticsOverviewTab extends StatelessWidget {
  const StatisticsOverviewTab({
    super.key,
    required this.summary,
  });

  final StatisticsOverviewSummary summary;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      children: [
        _overviewHeader(context),
        const SizedBox(height: 12),
        _topHabitsCard(),
        const SizedBox(height: 12),
        _familyCard(),
        const SizedBox(height: 12),
        _bestMomentCard(),
        const SizedBox(height: 12),
        _consistencyCalendarCard(),
      ],
    );
  }

  Widget _overviewHeader(BuildContext context) {
    return Container(
      decoration: StatsCardSurface.decoration(
        context,
        tint: const Color(0xFFF7F3EB),
      ),
      padding: StatsCardSurface.padding,
      child: Row(
        children: [
          Expanded(
            child: _metricTile(
              label: 'Habitos',
              value: summary.totalHabits.toString(),
            ),
          ),
          Expanded(
            child: _metricTile(
              label: 'Consistencia',
              value: '${summary.overallConsistencyPct}%',
            ),
          ),
          Expanded(
            child: _metricTile(
              label: 'Familias',
              value: summary.totalFamilies.toString(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricTile({required String label, required String value}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.black.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }

  Widget _topHabitsCard() {
    return _sectionCard(
      title: 'Mejores habitos',
      child: Column(
        children: summary.topHabits.map((habit) {
          final color = FamilyTheme.colorOf(habit.familyId);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    habit.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${habit.completionPct}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.black.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ),
          );
        }).toList(growable: false),
      ),
    );
  }

  Widget _familyCard() {
    return _sectionCard(
      title: 'Familias',
      child: Column(
        children: summary.familyConsistencyPct.entries.map((entry) {
          final familyName = FamilyTheme.nameOf(entry.key);
          final familyColor = FamilyTheme.colorOf(entry.key);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    familyName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: LinearProgressIndicator(
                    value: (entry.value / 100).clamp(0.0, 1.0),
                    minHeight: 7,
                    backgroundColor: familyColor.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(familyColor),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${entry.value}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withValues(alpha: 0.64),
                  ),
                ),
              ],
            ),
          );
        }).toList(growable: false),
      ),
    );
  }

  Widget _bestMomentCard() {
    final p = summary.bestMomentPercents;
    return _sectionCard(
      title: 'Mejor momento${summary.bestMomentLabel.isEmpty ? '' : ': ${summary.bestMomentLabel}'}',
      child: StatsBestTimeOfDayCard(
        accent: const Color(0xFF4A7A64),
        morningPct: p['morning'] ?? 0,
        afternoonPct: p['afternoon'] ?? 0,
        eveningPct: p['evening'] ?? 0,
        nightPct: p['night'] ?? 0,
      ),
    );
  }

  Widget _consistencyCalendarCard() {
    return _sectionCard(
      title: 'Calendario de consistencia',
      child: StatsMonthHeatmap(
        month: summary.range.end,
        accent: const Color(0xFF507865),
        intensityByDay: summary.monthConsistencyByDay,
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Builder(
      builder: (context) => Container(
        decoration: StatsCardSurface.decoration(context),
        padding: StatsCardSurface.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
