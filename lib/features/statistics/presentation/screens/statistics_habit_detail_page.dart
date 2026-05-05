import 'statistics_habit_detail_screen.dart';
import '../../domain/statistics_period.dart';

/// Backward-compatible wrapper kept to avoid fragile imports while migrating
/// callers to [StatisticsHabitDetailScreen].
class StatisticsHabitDetailPage extends StatisticsHabitDetailScreen {
  const StatisticsHabitDetailPage({
    super.key,
    required super.habitId,
    super.initialPeriod = StatisticsPeriod.week,
  });
}
