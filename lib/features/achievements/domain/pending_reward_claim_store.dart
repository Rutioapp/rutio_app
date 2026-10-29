import 'models/pending_reward_claim.dart';
import '../../../core/storage/pending_queue_storage.dart';

abstract interface class PendingRewardClaimStore {
  Future<List<PendingRewardClaim>> loadPendingClaims(String userId);

  Future<void> savePendingClaims(
    String userId,
    List<PendingRewardClaim> claims,
  );

  Future<void> clearPendingClaims(String userId);
}

abstract interface class PendingRewardClaimStoreWithStatus {
  Future<PendingQueueReadResult<PendingRewardClaim>>
      loadPendingClaimsWithStatus(String userId);
  Future<bool> savePendingClaimsConfirmed(
    String userId,
    List<PendingRewardClaim> claims,
  );
}

extension PendingRewardClaimStoreStatusAccess on PendingRewardClaimStore {
  Future<PendingQueueReadResult<PendingRewardClaim>>
      loadPendingClaimsWithStatus(String userId) {
    final store = this;
    if (store is PendingRewardClaimStoreWithStatus) {
      return (store as PendingRewardClaimStoreWithStatus)
          .loadPendingClaimsWithStatus(userId);
    }
    return loadPendingClaims(userId).then(
      (values) => PendingQueueReadResult<PendingRewardClaim>(
        status: PendingQueueReadStatus.valid,
        values: values,
      ),
    );
  }

  Future<bool> savePendingClaimsConfirmed(
    String userId,
    List<PendingRewardClaim> claims,
  ) {
    final store = this;
    if (store is PendingRewardClaimStoreWithStatus) {
      return (store as PendingRewardClaimStoreWithStatus)
          .savePendingClaimsConfirmed(userId, claims);
    }
    return savePendingClaims(userId, claims)
        .then((_) => true)
        .catchError((_) => false);
  }
}
