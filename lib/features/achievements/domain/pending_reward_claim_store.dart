import 'models/pending_reward_claim.dart';

abstract interface class PendingRewardClaimStore {
  Future<List<PendingRewardClaim>> loadPendingClaims(String userId);

  Future<void> savePendingClaims(
    String userId,
    List<PendingRewardClaim> claims,
  );

  Future<void> clearPendingClaims(String userId);
}
