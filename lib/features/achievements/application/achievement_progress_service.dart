import '../domain/models/achievement.dart';
import '../domain/models/achievement_progress.dart';
import '../domain/models/habit_streak_snapshot.dart';
import '../domain/models/unlocked_achievement_record.dart';

class AchievementProgressService {
  const AchievementProgressService._();

  static List<AchievementProgress> resolve({
    required List<Achievement> achievements,
    required Map<String, HabitStreakSnapshot> snapshotsBySourceId,
    required Map<String, UnlockedAchievementRecord> unlockedById,
  }) {
    return achievements.map((achievement) {
      final snapshot = snapshotsBySourceId[achievement.habitId] ??
          HabitStreakSnapshot(
            habitId: achievement.habitId,
            currentStreak: 0,
            bestStreak: 0,
            totalCompletedDays: 0,
          );
      final currentValue = snapshot.currentStreak;
      final unlockedRecord = unlockedById[achievement.id];
      final status = unlockedRecord != null
          ? AchievementStatus.unlocked
          : currentValue > 0
              ? AchievementStatus.inProgress
              : AchievementStatus.locked;

      return AchievementProgress(
        achievement: achievement,
        currentValue: currentValue,
        targetValue: achievement.targetValue,
        status: status,
        progress: achievement.targetValue <= 0
            ? 0.0
            : (currentValue / achievement.targetValue).clamp(0, 1).toDouble(),
        unlockedAt: unlockedRecord?.unlockedAt,
        record: unlockedRecord,
      );
    }).toList()
      ..sort((a, b) => a.achievement.sortOrder.compareTo(b.achievement.sortOrder));
  }
}
