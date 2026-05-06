import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/utils/app_theme.dart';

import '../../../../stores/user_state_store.dart';
import '../../application/adapters/statistics_data_adapter.dart';
import '../../domain/statistics_period.dart';
import 'statistics_habit_detail_screen.dart';
import '../widgets/statistics_habits_tab.dart';
import '../widgets/statistics_overview_tab.dart';
import '../widgets/statistics_period_selector.dart';
import '../widgets/statistics_v2_tokens.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  static const String route = '/stats-v2';

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  StatisticsPeriod _period = StatisticsPeriod.week;
  final StatisticsDataAdapter _adapter = const StatisticsDataAdapter();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<UserStateStore>();
    final overview = _adapter.buildOverview(store: store, period: _period);

    return Scaffold(
      backgroundColor: StatisticsV2Tokens.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 94,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.statisticsV2Title,
              style: AppTextStyles.welcomeTitle.copyWith(
                fontSize: 40,
                color: StatisticsV2Tokens.ink,
              ),
            ),
            Text(
              context.l10n.statisticsV2HeaderSubtitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: StatisticsV2Tokens.ink.withValues(alpha: 0.62),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 39,
              height: 39,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
              ),
              child: Icon(
                Icons.bar_chart_rounded,
                size: 19,
                color: StatisticsV2Tokens.accent,
              ),
            ),
          ),
        ],
        centerTitle: false,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: StatisticsPeriodSelector(
              value: _period,
              periods: const [
                StatisticsPeriod.day,
                StatisticsPeriod.week,
                StatisticsPeriod.month,
              ],
              onChanged: (period) {
                setState(() {
                  _period = period;
                });
              },
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 42,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: StatisticsV2Tokens.surfaceSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: StatisticsV2Tokens.accent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                dividerColor: Colors.transparent,
                unselectedLabelColor:
                    StatisticsV2Tokens.ink.withValues(alpha: 0.64),
                labelStyle:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                unselectedLabelStyle:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                tabs: [
                  Tab(text: context.l10n.statisticsV2TabOverview),
                  Tab(text: context.l10n.statisticsV2TabHabits),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                StatisticsOverviewTab(summary: overview),
                StatisticsHabitsTab(
                  adapter: _adapter,
                  store: store,
                  period: _period,
                  onOpenHabit: (habitId) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StatisticsHabitDetailScreen(
                          habitId: habitId,
                          initialPeriod: _period,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


