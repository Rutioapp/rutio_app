import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rutio/l10n/l10n.dart';

import '../../../../stores/user_state_store.dart';
import '../../application/adapters/statistics_data_adapter.dart';
import '../../domain/statistics_period.dart';
import 'statistics_habit_detail_screen.dart';
import '../widgets/statistics_habits_tab.dart';
import '../widgets/statistics_overview_tab.dart';
import '../widgets/statistics_period_selector.dart';

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
      backgroundColor: const Color(0xFFF8F5EF),
      appBar: AppBar(
        title: Text(context.l10n.statisticsV2Title),
        centerTitle: true,
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
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFF1D1B18),
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.black.withValues(alpha: 0.6),
                labelStyle:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
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


