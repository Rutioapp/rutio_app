import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats/habit_stats_hero_milestone.dart';

void main() {
  group('habitStatsHeroMilestoneProgressForStreak', () {
    test('maps streak thresholds correctly', () {
      expect(habitStatsHeroMilestoneProgressForStreak(0).to, 3);
      expect(habitStatsHeroMilestoneProgressForStreak(1).to, 3);
      expect(habitStatsHeroMilestoneProgressForStreak(3).to, 7);
      expect(habitStatsHeroMilestoneProgressForStreak(7).to, 14);
      expect(habitStatsHeroMilestoneProgressForStreak(14).to, 30);
      expect(habitStatsHeroMilestoneProgressForStreak(30).to, 60);
      expect(habitStatsHeroMilestoneProgressForStreak(60).to, 100);
      expect(habitStatsHeroMilestoneProgressForStreak(100).to, 180);
      expect(habitStatsHeroMilestoneProgressForStreak(180).to, 365);
    });

    test('progress is relative to the active interval', () {
      expect(habitStatsHeroMilestoneProgressForStreak(0).progress, 0);
      expect(habitStatsHeroMilestoneProgressForStreak(1).progress, closeTo(1 / 3, 0.0001));
      expect(habitStatsHeroMilestoneProgressForStreak(2).progress, closeTo(2 / 3, 0.0001));
      expect(habitStatsHeroMilestoneProgressForStreak(3).progress, 0);
      expect(habitStatsHeroMilestoneProgressForStreak(5).progress, closeTo(2 / 4, 0.0001));
      expect(habitStatsHeroMilestoneProgressForStreak(30).progress, 0);
    });
  });
}
