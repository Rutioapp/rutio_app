import 'achievement.dart';
import 'unlocked_achievement_record.dart';

class AchievementProgress {
  const AchievementProgress({
    required this.achievement,
    required this.currentValue,
    required this.targetValue,
    required this.status,
    required this.progress,
    this.unlockedAt,
    this.record,
  });

  final Achievement achievement;
  final int currentValue;
  final int targetValue;
  final AchievementStatus status;
  final double progress;
  final DateTime? unlockedAt;
  final UnlockedAchievementRecord? record;

  bool get isHiddenLocked =>
      achievement.hidden && status != AchievementStatus.unlocked;
}
