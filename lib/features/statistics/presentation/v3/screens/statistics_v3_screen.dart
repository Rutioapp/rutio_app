import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rutio/features/statistics/presentation/v3/application/statistics_v3_data_adapter.dart';
import 'package:rutio/features/statistics/presentation/v3/models/statistics_v3_period.dart';
import 'package:rutio/features/statistics/presentation/v3/models/statistics_v3_view_data.dart';
import 'package:rutio/features/statistics/presentation/v3/widgets/statistics_v3_best_moment_card.dart';
import 'package:rutio/features/statistics/presentation/v3/widgets/statistics_v3_consistency_card.dart';
import 'package:rutio/features/statistics/presentation/v3/widgets/statistics_v3_family_chips_card.dart';
import 'package:rutio/features/statistics/presentation/v3/widgets/statistics_v3_header.dart';
import 'package:rutio/features/statistics/presentation/v3/widgets/statistics_v3_habit_list_view.dart';
import 'package:rutio/features/statistics/presentation/v3/widgets/statistics_v3_highlighted_habit_card.dart';
import 'package:rutio/features/statistics/presentation/v3/widgets/statistics_v3_monthly_calendar_shell.dart';
import 'package:rutio/features/statistics/presentation/v3/widgets/statistics_v3_period_selector.dart';
import 'package:rutio/features/statistics/presentation/v3/widgets/statistics_v3_progress_message_chip.dart';
import 'package:rutio/features/statistics/presentation/v3/widgets/statistics_v3_weekly_activity_shell.dart';
import 'package:rutio/features/statistics/presentation/v3/widgets/statistics_v3_weekly_improvement_chip.dart';
import 'package:rutio/features/statistics/presentation/v3/widgets/statistics_v3_summary_card.dart';
import 'package:rutio/features/statistics/presentation/v3/widgets/statistics_v3_yearly_consistency_shell.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/screens/diary/diary_screen.dart';
import 'package:rutio/screens/habit_archived_screen.dart';
import 'package:rutio/screens/habit_detail/habit_detail_screen.dart';
import 'package:rutio/screens/habit_monthly_screen.dart';
import 'package:rutio/screens/habit_stats_overview_screen.dart';
import 'package:rutio/screens/habit_weekly_screen.dart';
import 'package:rutio/screens/home/home_screen.dart';
import 'package:rutio/screens/profile/profile_screen.dart';
import 'package:rutio/stores/user_state_store.dart';
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
    final viewData = buildStatisticsV3ViewData(
      store: store,
      period: _period,
      l10n: l10n,
    );
    final habitListItems = buildStatisticsV3HabitListData(
      store: store,
      l10n: l10n,
    );
    final currentStreakDays = _currentGlobalStreak(store);
    final highlightedHabitStreakDays =
        _highlightedHabitStreak(store, viewData.highlightedHabits);

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
            onGoStats: () =>
                _navReplace(context, const HabitStatsOverviewHost()),
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
                if (_showHabitView)
                  StatisticsV3HabitListView(
                    items: habitListItems,
                    onPlusTap: () {
                      final messenger = ScaffoldMessenger.maybeOf(context);
                      if (messenger == null) return;
                      messenger
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.statisticsV3HabitListPlusComingSoon,
                            ),
                          ),
                        );
                    },
                    onHabitTap: (item) {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (_) => HabitDetailScreen(
                            habit: item.habit,
                            familyColor: item.familyColor,
                            mode: HabitDetailScreenMode.statsOnly,
                          ),
                        ),
                      );
                    },
                  )
                else ...[
                  StatisticsV3PeriodSelector(
                    value: _period,
                    onChanged: (next) => setState(() => _period = next),
                  ),
                  const SizedBox(height: 12),
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
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.94,
                    children: [
                      StatisticsV3ConsistencyCard(
                        title: l10n.statisticsV3ConsistencyCardTitle,
                        completedHabits: viewData.completedHabits,
                        totalHabits: viewData.totalDays,
                        consistencyPct: viewData.consistencyPct,
                        streakDays: currentStreakDays,
                      ),
                      StatisticsV3FamilyChipsCard(
                        title: l10n.statisticsV3FamiliesCardTitle,
                        subtitle: _featuredFamilySubtitle(_period, l10n),
                        emptyLabel: l10n.statisticsV3FamiliesEmpty,
                        items: viewData.families,
                      ),
                      StatisticsV3BestMomentCard(
                        title: l10n.statisticsV3BestMomentCardTitle,
                        insight: viewData.bestMoment,
                        fallback: l10n.statisticsV3BestMomentFallback,
                      ),
                      StatisticsV3HighlightedHabitCard(
                        title: l10n.statisticsV3HighlightedHabitCardTitle,
                        emptyLabel: l10n.statisticsV3HighlightedHabitEmpty,
                        items: viewData.highlightedHabits,
                        streakDays: highlightedHabitStreakDays,
                      ),
                    ],
                  ),
                  if (_period == StatisticsV3Period.week) ...[
                    const SizedBox(height: 10),
                    _StatisticsV3WeeklySection(
                      improvementTitle: l10n.statisticsV3WeeklyImprovementTitle,
                      improvementSubtitle: _weeklyImprovementSubtitle(
                        viewData.weeklyImprovement,
                        l10n,
                      ),
                      improvementDelta: _weeklyImprovementDelta(
                        viewData.weeklyImprovement,
                      ),
                      activityTitle: l10n.statisticsV3DailyActivityTitle,
                      activitySubtitle: l10n.statisticsV3DailyActivitySubtitle,
                      activityDays: viewData.weeklyActivity,
                    ),
                    const SizedBox(height: 12),
                    StatisticsV3ProgressMessageChip(
                      message: _progressMessage(viewData, l10n),
                    ),
                  ] else if (_period == StatisticsV3Period.month) ...[
                    const SizedBox(height: 12),
                    StatisticsV3MonthlyCalendarShell(
                      title: l10n.statisticsV3MonthlyCalendarTitle,
                      subtitle: l10n.statisticsV3MonthlyCalendarSubtitle,
                      days: viewData.monthlyCalendarDays,
                    ),
                    const SizedBox(height: 12),
                    StatisticsV3ProgressMessageChip(
                      message: _progressMessage(viewData, l10n),
                    ),
                  ] else if (_period == StatisticsV3Period.year) ...[
                    const SizedBox(height: 12),
                    StatisticsV3YearlyConsistencyShell(
                      title: _yearlyConsistencyTitle(context),
                      subtitle: _yearlyConsistencySubtitle(context),
                      months: viewData.yearlyConsistencyMonths,
                    ),
                    const SizedBox(height: 12),
                    StatisticsV3ProgressMessageChip(
                      message: _progressMessage(viewData, l10n),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    StatisticsV3ProgressMessageChip(
                      message: _progressMessage(viewData, l10n),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _progressMessage(
    StatisticsV3ViewData viewData,
    AppLocalizations l10n,
  ) {
    if (viewData.consistencyPct <= 0) {
      return l10n.statisticsV3ProgressMessageEmpty;
    }
    if (viewData.consistencyPct >= 100) {
      return l10n.statisticsV3ProgressMessageComplete;
    }
    return l10n.statisticsV3ProgressMessageInProgress;
  }

  int _currentGlobalStreak(UserStateStore store) {
    final snapshot = store.achievementMetricSnapshots['special:imparable'];
    return snapshot?.currentStreak ?? 0;
  }

  int _highlightedHabitStreak(
    UserStateStore store,
    List<StatisticsV3HighlightedHabitItem> habits,
  ) {
    if (habits.isEmpty) return 0;
    return store
        .habitStreakSnapshotForHabitId(habits.first.habitId)
        .currentStreak;
  }

  String _featuredFamilySubtitle(
    StatisticsV3Period period,
    AppLocalizations l10n,
  ) {
    switch (period) {
      case StatisticsV3Period.day:
        return l10n.statisticsV3FeaturedFamilySubtitleDay;
      case StatisticsV3Period.week:
        return l10n.statisticsV3FeaturedFamilySubtitleWeek;
      case StatisticsV3Period.month:
        return l10n.statisticsV3FeaturedFamilySubtitleMonth;
      case StatisticsV3Period.year:
        return l10n.statisticsV3FeaturedFamilySubtitleYear;
    }
  }

  int? _weeklyImprovementDelta(StatisticsV3WeeklyImprovementData data) {
    if (!data.hasComparison || data.deltaPercentage == 0) {
      return null;
    }
    return data.deltaPercentage;
  }

  String _weeklyImprovementSubtitle(
    StatisticsV3WeeklyImprovementData data,
    AppLocalizations l10n,
  ) {
    if (!data.hasComparison) {
      return l10n.statisticsV3WeeklyImprovementNoComparison;
    }
    if (data.deltaPercentage == 0) {
      return l10n.statisticsV3WeeklyImprovementSameAsLastWeek;
    }
    return l10n.statisticsV3WeeklyImprovementVsLastWeek;
  }

  String _yearlyConsistencyTitle(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode.toLowerCase();
    return locale == 'es' ? 'Constancia anual' : 'Yearly consistency';
  }

  String _yearlyConsistencySubtitle(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode.toLowerCase();
    return locale == 'es'
        ? 'Consistencia por mes en el año actual'
        : 'Month-by-month consistency for the current year';
  }
}

class _StatisticsV3WeeklySection extends StatelessWidget {
  const _StatisticsV3WeeklySection({
    required this.improvementTitle,
    required this.improvementSubtitle,
    required this.improvementDelta,
    required this.activityTitle,
    required this.activitySubtitle,
    required this.activityDays,
  });

  final String improvementTitle;
  final String improvementSubtitle;
  final int? improvementDelta;
  final String activityTitle;
  final String activitySubtitle;
  final List<StatisticsV3WeeklyActivityDay> activityDays;

  static const double _columnGap = 10;
  static const double _stackBreakpoint = 280;
  static const double _cardHeight = 200;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _stackBreakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StatisticsV3WeeklyImprovementChip(
                title: improvementTitle,
                subtitle: improvementSubtitle,
                deltaPercentage: improvementDelta,
              ),
              const SizedBox(height: _columnGap),
              StatisticsV3WeeklyActivityShell(
                title: activityTitle,
                subtitle: activitySubtitle,
                days: activityDays,
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SizedBox(
                height: _cardHeight,
                child: StatisticsV3WeeklyImprovementChip(
                  title: improvementTitle,
                  subtitle: improvementSubtitle,
                  deltaPercentage: improvementDelta,
                ),
              ),
            ),
            const SizedBox(width: _columnGap),
            Expanded(
              child: SizedBox(
                height: _cardHeight,
                child: StatisticsV3WeeklyActivityShell(
                  title: activityTitle,
                  subtitle: activitySubtitle,
                  days: activityDays,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
