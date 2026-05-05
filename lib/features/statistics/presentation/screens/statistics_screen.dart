import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../stores/user_state_store.dart';
import '../../application/adapters/statistics_data_adapter.dart';
import '../../domain/statistics_period.dart';
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
        title: const Text('Estadisticas (Fase 1)'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: StatisticsPeriodSelector(
              value: _period,
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
                tabs: const [
                  Tab(text: 'Vista general'),
                  Tab(text: 'Habitos'),
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
                        builder: (_) => _StatisticsDetailRoutePage(
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

class _StatisticsDetailRoutePage extends StatelessWidget {
  const _StatisticsDetailRoutePage({
    required this.habitId,
    required this.initialPeriod,
  });

  final String habitId;
  final StatisticsPeriod initialPeriod;

  @override
  Widget build(BuildContext context) {
    final adapter = const StatisticsDataAdapter();
    final store = context.watch<UserStateStore>();
    final detail = adapter.buildHabitDetail(
      store: store,
      habitId: habitId,
      period: initialPeriod,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de habito')),
      body: detail == null
          ? const Center(child: Text('No se encontro el habito.'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detail.habit.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Periodo: ${detail.period.name}'),
                  Text('Racha actual: ${detail.habit.currentStreak} dias'),
                  Text(
                    'Comparacion semanal: ${detail.thisWeekDoneDays} vs ${detail.lastWeekDoneDays}',
                  ),
                  const SizedBox(height: 12),
                  Text(detail.insight),
                ],
              ),
            ),
    );
  }
}


