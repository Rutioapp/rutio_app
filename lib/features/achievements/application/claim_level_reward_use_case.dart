import '../data/cloud/achievement_level_reward_errors.dart';
import '../data/cloud/achievement_level_reward_ledger.dart';
import '../data/cloud/achievement_level_reward_repository.dart';

class ClaimLevelRewardUseCase {
  ClaimLevelRewardUseCase({
    AchievementLevelRewardRepository? repository,
  }) : _repository = repository ?? SupabaseAchievementLevelRewardRepository();

  final AchievementLevelRewardRepository _repository;

  Future<AchievementLevelRewardResult<AchievementLevelRewardLedgerEntry>>
      call({
    required String requestId,
    required int level,
  }) {
    return _repository.claimLevelReward(
      requestId: requestId,
      level: level,
    );
  }
}
