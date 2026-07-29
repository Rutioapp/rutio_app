import '../../data/local/authoritative_bootstrap_cache_v2.dart';
import '../../data/models/remote/authoritative_bootstrap_decision.dart';

enum AuthoritativeBootstrapCacheComparisonKindV2 {
  matchHome,
  matchOnboarding,
  matchBlocked,
  mismatchDestination,
  mismatchAccountStatus,
  mismatchProfileState,
  mismatchOnboardingEnforcement,
  mismatchOnboardingStatus,
  mismatchRequiredOnboardingVersion,
  mismatchCompletedOnboardingVersion,
  mismatchOnboardingCompletedAt,
  mismatchProfileRevision,
  mismatchPolicyRevision,
  mismatchUserId,
  mismatchEnvironmentId,
  mismatchScopeKey,
  multipleMismatches,
}

class AuthoritativeBootstrapCacheComparisonV2 {
  const AuthoritativeBootstrapCacheComparisonV2({
    required this.kind,
    required this.mismatchedFields,
  });

  final AuthoritativeBootstrapCacheComparisonKindV2 kind;
  final List<String> mismatchedFields;

  bool get hasMismatches => mismatchedFields.isNotEmpty;
}

AuthoritativeBootstrapCacheComparisonV2
    compareAuthoritativeBootstrapCacheV2({
  required AuthoritativeBootstrapCacheEntryV2 cacheEntry,
  required AuthoritativeBootstrapDecision authoritativeDecision,
  required String expectedUserId,
  required String expectedEnvironmentId,
  required String expectedScopeKey,
}) {
  final mismatchedFields = <String>[];

  void addMismatch(String field) {
    if (!mismatchedFields.contains(field)) {
      mismatchedFields.add(field);
    }
  }

  if (cacheEntry.userId != expectedUserId.trim() ||
      authoritativeDecision.userId != expectedUserId.trim()) {
    addMismatch('userId');
  }
  if (cacheEntry.environmentId != expectedEnvironmentId.trim()) {
    addMismatch('environmentId');
  }
  if (cacheEntry.scopeKey != expectedScopeKey.trim()) {
    addMismatch('scopeKey');
  }
  if (cacheEntry.destination != authoritativeDecision.decision) {
    addMismatch('destination');
  }
  if (cacheEntry.accountStatus != authoritativeDecision.accountStatus) {
    addMismatch('accountStatus');
  }
  if (cacheEntry.profileState != authoritativeDecision.profileState) {
    addMismatch('profileState');
  }
  if (cacheEntry.onboardingEnforcement !=
      authoritativeDecision.onboardingEnforcement) {
    addMismatch('onboardingEnforcement');
  }
  if (cacheEntry.onboardingStatus != authoritativeDecision.onboardingStatus) {
    addMismatch('onboardingStatus');
  }
  if (cacheEntry.requiredOnboardingVersion !=
      authoritativeDecision.requiredOnboardingVersion) {
    addMismatch('requiredOnboardingVersion');
  }
  if (cacheEntry.completedOnboardingVersion !=
      (authoritativeDecision.completedOnboardingVersion ?? 0)) {
    addMismatch('completedOnboardingVersion');
  }
  if (cacheEntry.onboardingCompletedAt?.toUtc() !=
      authoritativeDecision.onboardingCompletedAt?.toUtc()) {
    addMismatch('onboardingCompletedAt');
  }
  if (cacheEntry.profileRevision != authoritativeDecision.profileRevision) {
    addMismatch('profileRevision');
  }
  if (cacheEntry.policyRevision != authoritativeDecision.policyRevision) {
    addMismatch('policyRevision');
  }

  if (mismatchedFields.isEmpty) {
    final kind = switch (cacheEntry.destination) {
      AuthoritativeBootstrapDestination.home =>
        AuthoritativeBootstrapCacheComparisonKindV2.matchHome,
      AuthoritativeBootstrapDestination.onboarding =>
        AuthoritativeBootstrapCacheComparisonKindV2.matchOnboarding,
      _ => AuthoritativeBootstrapCacheComparisonKindV2.matchBlocked,
    };
    return AuthoritativeBootstrapCacheComparisonV2(
      kind: kind,
      mismatchedFields: const <String>[],
    );
  }

  if (mismatchedFields.length == 1) {
    final single = mismatchedFields.single;
    return AuthoritativeBootstrapCacheComparisonV2(
      kind: switch (single) {
        'destination' =>
          AuthoritativeBootstrapCacheComparisonKindV2.mismatchDestination,
        'accountStatus' =>
          AuthoritativeBootstrapCacheComparisonKindV2.mismatchAccountStatus,
        'profileState' =>
          AuthoritativeBootstrapCacheComparisonKindV2.mismatchProfileState,
        'onboardingEnforcement' => AuthoritativeBootstrapCacheComparisonKindV2
            .mismatchOnboardingEnforcement,
        'onboardingStatus' => AuthoritativeBootstrapCacheComparisonKindV2
            .mismatchOnboardingStatus,
        'requiredOnboardingVersion' => AuthoritativeBootstrapCacheComparisonKindV2
            .mismatchRequiredOnboardingVersion,
        'completedOnboardingVersion' => AuthoritativeBootstrapCacheComparisonKindV2
            .mismatchCompletedOnboardingVersion,
        'onboardingCompletedAt' => AuthoritativeBootstrapCacheComparisonKindV2
            .mismatchOnboardingCompletedAt,
        'profileRevision' =>
          AuthoritativeBootstrapCacheComparisonKindV2.mismatchProfileRevision,
        'policyRevision' =>
          AuthoritativeBootstrapCacheComparisonKindV2.mismatchPolicyRevision,
        'userId' => AuthoritativeBootstrapCacheComparisonKindV2.mismatchUserId,
        'environmentId' =>
          AuthoritativeBootstrapCacheComparisonKindV2.mismatchEnvironmentId,
        'scopeKey' =>
          AuthoritativeBootstrapCacheComparisonKindV2.mismatchScopeKey,
        _ => AuthoritativeBootstrapCacheComparisonKindV2.multipleMismatches,
      },
      mismatchedFields: List<String>.unmodifiable(mismatchedFields),
    );
  }

  return AuthoritativeBootstrapCacheComparisonV2(
    kind: AuthoritativeBootstrapCacheComparisonKindV2.multipleMismatches,
    mismatchedFields: List<String>.unmodifiable(mismatchedFields),
  );
}
