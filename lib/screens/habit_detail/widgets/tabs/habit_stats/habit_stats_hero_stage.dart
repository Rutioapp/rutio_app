enum HabitStatsHeroStage {
  day1,
  day3,
  day7,
  day14,
  day30,
  day100,
}

HabitStatsHeroStage heroStageForStreak(int days) {
  if (days >= 100) return HabitStatsHeroStage.day100;
  if (days >= 30) return HabitStatsHeroStage.day30;
  if (days >= 14) return HabitStatsHeroStage.day14;
  if (days >= 7) return HabitStatsHeroStage.day7;
  if (days >= 3) return HabitStatsHeroStage.day3;
  return HabitStatsHeroStage.day1;
}
