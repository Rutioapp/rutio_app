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
                            l10n.statisticsV3SummaryCompletedLabel,
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
                        body: viewData.bestMoment.hasData
                            ? l10n.statisticsV3BestMomentWithCount(
                                viewData.bestMoment.label,
                                viewData.bestMoment.count,
                              )
                            : l10n.statisticsV3BestMomentFallback,
                      ),
                      StatisticsV3HighlightedHabitCard(
                        title: l10n.statisticsV3HighlightedHabitCardTitle,
                        emptyLabel: l10n.statisticsV3HighlightedHabitEmpty,
                        items: viewData.highlightedHabits,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  StatisticsV3ProgressMessageChip(
                    message: _progressMessage(viewData, l10n),
                  ),
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
    if (viewData.consistencyPct <= 0) return l10n.statisticsV3ProgressMessageEmpty;
    if (viewData.consistencyPct >= 100) {
      return l10n.statisticsV3ProgressMessageComplete;
    }
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
