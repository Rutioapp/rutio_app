import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../utils/app_theme.dart';
import 'habit_stats/habit_stats_comparison.dart';
import 'habit_stats/habit_stats_header.dart';
import 'habit_stats/habit_stats_helpers.dart';
import 'habit_stats/habit_stats_hero_card.dart';
import 'habit_stats/habit_stats_insight_card.dart';
import 'habit_stats/habit_stats_last_7_days.dart';
import 'habit_stats/habit_stats_metric_grid.dart';
import 'habit_stats/habit_stats_models.dart';
import 'habit_stats/habit_stats_period_selector.dart';

class HabitStatsTab extends StatefulWidget {
  const HabitStatsTab({
    super.key,
    required this.habit,
    required this.familyColor,
    this.scrollable = true,
    this.showHeader = false,
    this.onBackPressed,
    this.onMorePressed,
  });

  final dynamic habit;
  final Color familyColor;
  final bool scrollable;
  final bool showHeader;
  final VoidCallback? onBackPressed;
  final VoidCallback? onMorePressed;

  @override
  State<HabitStatsTab> createState() => _HabitStatsTabState();
}

class _HabitStatsTabState extends State<HabitStatsTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  HabitStatsPeriod _period = HabitStatsPeriod.week;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(_fade);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final today = dateOnly(DateTime.now());
    final data = buildHabitStatsData(
      context: context,
      habit: widget.habit,
      period: _period,
      familyColor: widget.familyColor,
      today: today,
    );

    final main = FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showHeader)
              HabitStatsHeader(
                title: data.title,
                familyColor: widget.familyColor,
                familyAndGoal: data.familyAndGoalLabel,
                onBackPressed: widget.onBackPressed,
                onMorePressed: widget.onMorePressed,
              ),
            if (widget.showHeader) const SizedBox(height: 18),
            HabitStatsPeriodSelector(
              value: _period,
              onChanged: (period) => setState(() => _period = period),
            ),
            const SizedBox(height: 18),
            HabitStatsHeroCard(
              streak: data.currentStreak,
              streakLabel: l10n.habitStatsTabCurrentStreakTitle,
            ),
            const SizedBox(height: 18),
            if (data.isCountHabit)
              HabitStatsCountLast7DaysCard(
                days: data.last7Days,
                values: data.last7Values,
                target: data.countTarget,
                unit: data.countUnit,
              )
            else
              HabitStatsCheckLast7DaysCard(
                days: data.last7Days,
                doneStates: data.last7DoneStates,
                skippedStates: data.last7SkippedStates,
              ),
            const SizedBox(height: 14),
            HabitStatsMetricGrid(cards: data.metricCards),
            const SizedBox(height: 14),
            HabitStatsComparisonCard(
              title: data.comparisonTitle,
              mainText: data.comparisonMain,
              subtitle: data.comparisonSubtitle,
              trendText: data.comparisonTrendText,
              trendPositive: data.comparisonTrendPositive,
              isCountHabit: data.isCountHabit,
            ),
            const SizedBox(height: 14),
            HabitStatsInsightCard(text: data.insightText),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );

    final content = widget.scrollable
        ? SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              22,
              widget.showHeader ? 10 : 16,
              22,
              24,
            ),
            child: main,
          )
        : Padding(
            padding: EdgeInsets.fromLTRB(
              22,
              widget.showHeader ? 10 : 16,
              22,
              24,
            ),
            child: main,
          );

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.cream,
            Color(0xFFF4EEE2),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: HabitStatsBackgroundOrb(
              size: 220,
              color: widget.familyColor.withValues(alpha: 0.08),
            ),
          ),
          const Positioned(
            left: -70,
            top: 220,
            child: HabitStatsBackgroundOrb(
              size: 190,
              color: Color(0x20B8895A),
            ),
          ),
          Positioned.fill(child: content),
        ],
      ),
    );
  }
}
