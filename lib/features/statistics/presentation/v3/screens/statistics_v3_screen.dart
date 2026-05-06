import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rutio/features/statistics/presentation/v3/widgets/statistics_v3_best_moment_card.dart';
import 'package:rutio/features/statistics/presentation/v3/models/statistics_v3_period.dart';
import 'package:rutio/features/statistics/presentation/v3/widgets/statistics_v3_consistency_card.dart';
import 'package:rutio/features/statistics/presentation/v3/widgets/statistics_v3_family_chips_card.dart';
import 'package:rutio/features/statistics/presentation/v3/widgets/statistics_v3_header.dart';
import 'package:rutio/features/statistics/presentation/v3/widgets/statistics_v3_highlighted_habit_card.dart';
import 'package:rutio/features/statistics/presentation/v3/widgets/statistics_v3_period_selector.dart';
import 'package:rutio/features/statistics/presentation/v3/widgets/statistics_v3_progress_message_chip.dart';
import 'package:rutio/features/statistics/presentation/v3/widgets/statistics_v3_summary_card.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/screens/diary/diary_screen.dart';
import 'package:rutio/screens/habit_archived_screen.dart';
import 'package:rutio/screens/habit_monthly_screen.dart';
import 'package:rutio/screens/habit_stats_overview_screen.dart';
import 'package:rutio/screens/habit_weekly_screen.dart';
import 'package:rutio/screens/home/home_screen.dart';
import 'package:rutio/screens/profile/profile_screen.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:rutio/utils/family_theme.dart';
import 'package:rutio/widgets/app_view_drawer.dart';
import 'package:rutio/widgets/backgrounds/home_landscape_background.dart';

void _navReplace(BuildContext context, Widget screen) {
  final scaffold = Scaffold.maybeOf(context);
  if (scaffold != null && scaffold.isDrawerOpen) {
    Navigator.of(context).pop();
  }
  Navigator.of(context).pushReplacement(
    CupertinoPageRoute(builder: (_) => screen),
  );
}

class StatisticsV3Screen extends StatefulWidget {
  const StatisticsV3Screen({super.key});

  static const route = '/stats-v3';

  @override
  State<StatisticsV3Screen> createState() => _StatisticsV3ScreenState();
}

class _StatisticsV3ScreenState extends State<StatisticsV3Screen> {
  StatisticsV3Period _period = StatisticsV3Period.week;
  bool _showHabitView = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final store = context.watch<UserStateStore>();
    final viewData = _buildViewData(store, _period, l10n);

    return Stack(
      children: [
        const HomeBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          drawer: AppViewDrawer(
            selected: 'stats_v3',
            onGoDaily: () => _navReplace(context, const HomeScreen()),
            onGoWeekly: () => _navReplace(context, const HabitWeeklyScreen()),
            onGoMonthly: () => _navReplace(context, const HabitMonthlyScreen()),
            onGoTodo: () => Navigator.pushNamed(context, '/todo'),
            onGoDiary: () => _navReplace(context, const DiaryScreen()),
            onGoArchived: () =>
                _navReplace(context, const ArchivedHabitsScreen()),
            onGoStats: () => _navReplace(context, const HabitStatsOverviewHost()),
            onGoStatsV3: () {},
            onGoProfile: () => _navReplace(context, const ProfileScreen()),
          ),
          body: SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 104),
              children: [
                Builder(
                  builder: (ctx) => StatisticsV3Header(
                    title: l10n.habitStatsTitle,
                    subtitle: l10n.statisticsV3Subtitle,
                    isHabitView: _showHabitView,
                    onToggleView: () =>
                        setState(() => _showHabitView = !_showHabitView),
                    onMenuTap: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
                const SizedBox(height: 14),
                StatisticsV3PeriodSelector(
                  value: _period,
                  onChanged: (next) => setState(() => _period = next),
                ),
                const SizedBox(height: 12),
                if (_showHabitView)
                  _HabitViewPlaceholderCard(
                    title: l10n.statisticsV3HabitViewPlaceholderTitle,
                    body: l10n.statisticsV3HabitViewPlaceholderBody,
                  )
                else ...[
                  StatisticsV3SummaryCard(
                    title: l10n.statisticsV3SummaryCardTitle,
                    completedLabel: l10n.statisticsV3SummaryCompletedLabel,
                    completedHabits: viewData.completedHabits,
                    xpLabel: l10n.statisticsV3SummaryXpLabel,
                    xpGained: viewData.xpGained,
                    amberLabel: l10n.statisticsV3SummaryAmberLabel,
                    amberGained: viewData.amberGained,
                  ),
                  const SizedBox(height: 14),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.94,
                    children: [
                      StatisticsV3ConsistencyCard(
                        title: l10n.statisticsV3ConsistencyCardTitle,
                        activeDaysLabel:
                            l10n.statisticsV3ConsistencyActiveDays,
                        completionLabel:
                            l10n.statisticsV3ConsistencyCompletionLabel,
                        activeDays: viewData.activeDays,
                        totalDays: viewData.totalDays,
                        completionPct: viewData.consistencyPct,
                      ),
                      StatisticsV3FamilyChipsCard(
                        title: l10n.statisticsV3FamiliesCardTitle,
                        emptyLabel: l10n.statisticsV3FamiliesEmpty,
                        items: viewData.families,
                      ),
                      StatisticsV3BestMomentCard(
                        title: l10n.statisticsV3BestMomentCardTitle,
                        body: l10n.statisticsV3BestMomentFallback,
                      ),
                      StatisticsV3HighlightedHabitCard(
                        title: l10n.statisticsV3HighlightedHabitCardTitle,
                        emptyLabel: l10n.statisticsV3HighlightedHabitEmpty,
                        habitName: viewData.highlightedHabitName,
                        habitEmoji: viewData.highlightedHabitEmoji,
                        metricLabel: viewData.highlightedMetricLabel ??
                            l10n.statisticsV3HighlightedHabitEmpty,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  StatisticsV3ProgressMessageChip(
                    message: _progressMessage(l10n, viewData.consistencyPct),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  _StatisticsV3ViewData _buildViewData(
    UserStateStore store,
    StatisticsV3Period period,
    AppLocalizations l10n,
  ) {
    final today = DateTime.now();
    final end = DateTime(today.year, today.month, today.day);
    final days = List<DateTime>.generate(
      period.trailingDays,
      (index) => end.subtract(Duration(days: period.trailingDays - 1 - index)),
      growable: false,
    );

    final root = store.state ?? const <String, dynamic>{};
    final userState = _map(root['userState']);
    final history = _map(userState['history']);
    final completionsRoot = _map(history['habitCompletions']);
    final habits = store.activeHabits;

    final habitsById = <String, Map<String, dynamic>>{};
    for (final habit in habits) {
      final id = _habitId(habit);
      if (id.isNotEmpty) {
        habitsById[id] = habit;
      }
    }

    final completedByFamily = <String, int>{};
    final completedByHabit = <String, int>{};
    var completedHabits = 0;
    var activeDays = 0;

    for (final day in days) {
      final dayMap = _map(completionsRoot[_dateKey(day)]);
      var anyCompleted = false;
      for (final entry in dayMap.entries) {
        if (entry.value != true) continue;
        anyCompleted = true;
        completedHabits++;

        final habitId = entry.key.toString();
        completedByHabit[habitId] = (completedByHabit[habitId] ?? 0) + 1;

        final familyId = _normalizedFamilyId(habitsById[habitId]?['familyId']);
        completedByFamily[familyId] = (completedByFamily[familyId] ?? 0) + 1;
      }
      if (anyCompleted) activeDays++;
    }

    final families = completedByFamily.entries.toList(growable: false)
      ..sort((a, b) => b.value.compareTo(a.value));
    final topFamilies = families.take(4).map((entry) {
      final familyId = entry.key;
      return StatisticsV3FamilyChipItem(
        name: l10n.familyName(familyId),
        emoji: FamilyTheme.emojiOf(familyId),
        color: FamilyTheme.colorOf(familyId),
        completedCount: entry.value,
      );
    }).toList(growable: false);

    String? highlightedHabitName;
    String? highlightedHabitEmoji;
    String? highlightedMetricLabel;

    if (completedByHabit.isNotEmpty) {
      final bestHabitId = completedByHabit.keys.reduce((a, b) {
        final countA = completedByHabit[a] ?? 0;
        final countB = completedByHabit[b] ?? 0;
        if (countA != countB) return countA > countB ? a : b;

        final streakA = store.habitStreakSnapshotForHabitId(a).currentStreak;
        final streakB = store.habitStreakSnapshotForHabitId(b).currentStreak;
        return streakA >= streakB ? a : b;
      });

      final highlightedHabit = habitsById[bestHabitId];
      highlightedHabitName = _habitName(highlightedHabit);
      highlightedHabitEmoji = _habitEmoji(highlightedHabit);
      final completedDays = completedByHabit[bestHabitId] ?? 0;
      highlightedMetricLabel =
          l10n.statisticsV3HighlightedCompletedDays(completedDays);
    }

    final totalDays = math.max(days.length, 1);
    final consistencyPct = ((activeDays / totalDays) * 100).round();
    final xpGained = completedHabits * 10;
    final amberGained = completedHabits * 4;

    return _StatisticsV3ViewData(
      totalDays: totalDays,
      completedHabits: completedHabits,
      xpGained: xpGained,
      amberGained: amberGained,
      activeDays: activeDays,
      consistencyPct: consistencyPct,
      families: topFamilies,
      highlightedHabitName: highlightedHabitName,
      highlightedHabitEmoji: highlightedHabitEmoji,
      highlightedMetricLabel: highlightedMetricLabel,
    );
  }

  String _progressMessage(AppLocalizations l10n, int consistencyPct) {
    if (consistencyPct <= 0) return l10n.statisticsV3ProgressMessageEmpty;
    if (consistencyPct >= 100) return l10n.statisticsV3ProgressMessageComplete;
    return l10n.statisticsV3ProgressMessageInProgress;
  }
}

class _HabitViewPlaceholderCard extends StatelessWidget {
  const _HabitViewPlaceholderCard({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE9E3D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2F251C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 15,
              height: 1.35,
              color: Color(0xFF60574D),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticsV3ViewData {
  const _StatisticsV3ViewData({
    required this.totalDays,
    required this.completedHabits,
    required this.xpGained,
    required this.amberGained,
    required this.activeDays,
    required this.consistencyPct,
    required this.families,
    required this.highlightedHabitName,
    required this.highlightedHabitEmoji,
    required this.highlightedMetricLabel,
  });

  final int totalDays;
  final int completedHabits;
  final int xpGained;
  final int amberGained;
  final int activeDays;
  final int consistencyPct;
  final List<StatisticsV3FamilyChipItem> families;
  final String? highlightedHabitName;
  final String? highlightedHabitEmoji;
  final String? highlightedMetricLabel;
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

String _dateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

String _habitId(Map<String, dynamic> habit) {
  return (habit['id'] ?? habit['habitId'] ?? habit['uuid'] ?? habit['key'] ?? '')
      .toString()
      .trim();
}

String _habitName(Map<String, dynamic>? habit) {
  if (habit == null) return '';
  return (habit['title'] ??
          habit['name'] ??
          habit['habitName'] ??
          habit['label'] ??
          '')
      .toString()
      .trim();
}

String _habitEmoji(Map<String, dynamic>? habit) {
  if (habit == null) return '✨';
  final emoji = (habit['emoji'] ?? '').toString().trim();
  return emoji.isEmpty ? '✨' : emoji;
}

String _normalizedFamilyId(dynamic rawFamilyId) {
  final familyId = (rawFamilyId ?? FamilyTheme.fallbackId).toString();
  if (FamilyTheme.colors.containsKey(familyId)) return familyId;
  return FamilyTheme.fallbackId;
}
