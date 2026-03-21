part of 'package:rutio/screens/home/home_screen.dart';

/// Data ya preparada para pintar Home sin hacer cálculos dentro de `build()`.
class HomeViewData {
  final List<Map<String, dynamic>> visibleHabits;
  final List<Map<String, dynamic>> viewHabits;
  final List<Map<String, dynamic>> pendingHabits;
  final List<Map<String, dynamic>> completedHabits;
  final List<Map<String, dynamic>> skippedHabits;

  final int doneCount;
  final int totalCount;
  final String dayLabel;

  final int xpTotal;
  final int level;
  final int xpInLevel;
  final int xpToNext;
  final int coins;

  const HomeViewData({
    required this.visibleHabits,
    required this.viewHabits,
    required this.pendingHabits,
    required this.completedHabits,
    required this.skippedHabits,
    required this.doneCount,
    required this.totalCount,
    required this.dayLabel,
    required this.xpTotal,
    required this.level,
    required this.xpInLevel,
    required this.xpToNext,
    required this.coins,
  });
}
