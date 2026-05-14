import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import 'habit_stats/habit_stats_header.dart';
import 'habit_stats/habit_stats_helpers.dart';
import 'habit_stats/habit_stats_hero_card.dart';
import 'habit_stats/habit_stats_insight_card.dart';
import 'habit_stats/habit_stats_metric_grid.dart';
import 'habit_stats/habit_stats_models.dart';
import 'habit_stats/habit_stats_period_selector.dart';
import 'habit_stats/habit_stats_section_card.dart';

class HabitStatsTab extends StatefulWidget {
  final dynamic habit;
  final Color familyColor;
  final bool scrollable;

  const HabitStatsTab({
    super.key,
    required this.habit,
    required this.familyColor,
    this.scrollable = true,
  });

  @override
  State<HabitStatsTab> createState() => _HabitStatsTabState();
}

class _HabitStatsTabState extends State<HabitStatsTab> {
  HabitStatsPeriod _selectedPeriod = HabitStatsPeriod.week;

  @override
  Widget build(BuildContext context) {
    final shellData = buildHabitStatsShellData(context, widget.habit);
    final borderColor = widget.familyColor.withValues(alpha: 0.18);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HabitStatsHeader(
          title: shellData.title,
          subtitle: shellData.subtitle,
          typeLabel: shellData.typeLabel,
          familyColor: widget.familyColor,
        ),
        const SizedBox(height: 16),
        HabitStatsPeriodSelector(
          selectedPeriod: _selectedPeriod,
          familyColor: widget.familyColor,
          onPeriodChanged: (period) {
            setState(() => _selectedPeriod = period);
          },
        ),
        const SizedBox(height: 16),
        HabitStatsHeroCard(
          shellData: shellData,
          selectedPeriod: _selectedPeriod,
          familyColor: widget.familyColor,
        ),
        const SizedBox(height: 14),
        HabitStatsSectionCard(
          title: context.l10n.habitStatsTabLastDaysTitle(7),
          familyColor: widget.familyColor,
          borderColor: borderColor,
          child: _LastSevenDaysPlaceholder(
            shellData: shellData,
            familyColor: widget.familyColor,
          ),
        ),
        const SizedBox(height: 14),
        HabitStatsSectionCard(
          title: context.l10n.habitStatsTabSummaryTitle,
          familyColor: widget.familyColor,
          borderColor: borderColor,
          child: HabitStatsMetricGrid(
            shellData: shellData,
            selectedPeriod: _selectedPeriod,
            familyColor: widget.familyColor,
          ),
        ),
        const SizedBox(height: 14),
        HabitStatsInsightCard(
          shellData: shellData,
          selectedPeriod: _selectedPeriod,
          familyColor: widget.familyColor,
        ),
      ],
    );

    final body = widget.scrollable
        ? SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            child: content,
          )
        : Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            child: content,
          );

    return ColoredBox(
      color: const Color(0xFFF7F1E7),
      child: body,
    );
  }
}

class _LastSevenDaysPlaceholder extends StatelessWidget {
  final HabitStatsShellData shellData;
  final Color familyColor;

  const _LastSevenDaysPlaceholder({
    required this.shellData,
    required this.familyColor,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final week = List<DateTime>.generate(
      7,
      (i) => DateTime(today.year, today.month, today.day - (6 - i)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.habitStatsTabCheckHint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.black.withValues(alpha: 0.58),
              ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final day in week)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _DayDot(
                    active: shellData.countForDate(day) > 0,
                    familyColor: familyColor,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _DayDot extends StatelessWidget {
  final bool active;
  final Color familyColor;

  const _DayDot({
    required this.active,
    required this.familyColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: active
            ? familyColor.withValues(alpha: 0.22)
            : const Color(0xFFF4EDE1),
        border: Border.all(
          color:
              active ? familyColor.withValues(alpha: 0.36) : const Color(0xFFE7DBC9),
        ),
      ),
      child: Center(
        child: Icon(
          active ? Icons.check_rounded : Icons.remove_rounded,
          size: 16,
          color: active ? familyColor : Colors.black.withValues(alpha: 0.38),
        ),
      ),
    );
  }
}
