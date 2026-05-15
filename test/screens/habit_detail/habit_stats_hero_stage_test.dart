import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats/habit_stats_hero_stage.dart';

void main() {
  group('heroStageForStreak', () {
    test('maps streak thresholds correctly', () {
      expect(heroStageForStreak(0), HabitStatsHeroStage.day1);
      expect(heroStageForStreak(1), HabitStatsHeroStage.day1);
      expect(heroStageForStreak(3), HabitStatsHeroStage.day3);
      expect(heroStageForStreak(7), HabitStatsHeroStage.day7);
      expect(heroStageForStreak(14), HabitStatsHeroStage.day14);
      expect(heroStageForStreak(30), HabitStatsHeroStage.day30);
      expect(heroStageForStreak(100), HabitStatsHeroStage.day100);
    });
  });
}
