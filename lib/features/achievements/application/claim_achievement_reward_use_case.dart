import '../data/cloud/achievement_level_reward_errors.dart';
import '../data/cloud/achievement_level_reward_ledger.dart';
import '../data/cloud/achievement_level_reward_repository.dart';

class ClaimAchievementRewardUseCase {
  ClaimAchievementRewardUseCase({
    AchievementLevelRewardRepository? repository,
  }) : _repository = repository ?? SupabaseAchievementLevelRewardRepository();

  final AchievementLevelRewardRepository _repository;

  Future<AchievementLevelRewardResult<AchievementLevelRewardLedgerEntry>>
      call({
    required String requestId,
    required String achievementId,
  }) {
    return _repository.claimAchievementReward(
      requestId: requestId,
      achievementId: achievementId,
    );
  }
}
