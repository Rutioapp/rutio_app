import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/application/bootstrap/authoritative_bootstrap_cache_shadow.dart';
import 'package:rutio/data/local/authoritative_bootstrap_cache_v2.dart';
import 'package:rutio/data/models/remote/authoritative_bootstrap_decision.dart';
import 'package:rutio/data/models/remote/remote_profile.dart';

void main() {
  group('compareAuthoritativeBootstrapCacheV2', () {
    test('classifies a matching home snapshot', () {
      final cacheEntry = _entry(
        decision: AuthoritativeBootstrapDestination.home,
        onboardingStatus: OnboardingStatus.completed,
        completedOnboardingVersion: 2,
        onboardingCompletedAt: DateTime.utc(2026, 7, 28, 10, 15),
      );

      final comparison = compareAuthoritativeBootstrapCacheV2(
        cacheEntry: cacheEntry,
        authoritativeDecision: cacheEntry.toAuthoritativeDecision(),
        expectedUserId: 'user-1',
        expectedEnvironmentId: 'dev',
        expectedScopeKey: 'user-1|user-1|1',
      );

      expect(comparison.kind, AuthoritativeBootstrapCacheComparisonKindV2.matchHome);
      expect(comparison.mismatchedFields, isEmpty);
    });

    test('classifies blocked snapshots and multiple mismatches', () {
      final blocked = _entry(
        decision: AuthoritativeBootstrapDestination.accountSuspended,
        accountStatus: BootstrapAccountStatus.suspended,
        profileState: BootstrapProfileState.ready,
        onboardingStatus: null,
        completedOnboardingVersion: 0,
        onboardingCompletedAt: null,
        onboardingEnforcement: BootstrapOnboardingEnforcement.advisory,
      );

      final blockedComparison = compareAuthoritativeBootstrapCacheV2(
        cacheEntry: blocked,
        authoritativeDecision: blocked.toAuthoritativeDecision(),
        expectedUserId: 'user-1',
        expectedEnvironmentId: 'dev',
        expectedScopeKey: 'user-1|user-1|1',
      );
      expect(
        blockedComparison.kind,
        AuthoritativeBootstrapCacheComparisonKindV2.matchBlocked,
      );

      final mismatched = compareAuthoritativeBootstrapCacheV2(
        cacheEntry: blocked,
        authoritativeDecision: _entry(
          decision: AuthoritativeBootstrapDestination.onboarding,
          onboardingStatus: OnboardingStatus.pending,
          accountStatus: BootstrapAccountStatus.active,
          profileState: BootstrapProfileState.ready,
          completedOnboardingVersion: 0,
          onboardingCompletedAt: null,
          onboardingEnforcement: BootstrapOnboardingEnforcement.advisory,
        ).toAuthoritativeDecision(),
        expectedUserId: 'user-1',
        expectedEnvironmentId: 'dev',
        expectedScopeKey: 'user-1|user-1|1',
      );

      expect(mismatched.kind, AuthoritativeBootstrapCacheComparisonKindV2.multipleMismatches);
      expect(mismatched.mismatchedFields, isNotEmpty);
      expect(mismatched.mismatchedFields, contains('destination'));
    });
  });
}

AuthoritativeBootstrapCacheEntryV2 _entry({
  required AuthoritativeBootstrapDestination decision,
  required OnboardingStatus? onboardingStatus,
  required int completedOnboardingVersion,
  required DateTime? onboardingCompletedAt,
  BootstrapAccountStatus accountStatus = BootstrapAccountStatus.active,
  BootstrapProfileState profileState = BootstrapProfileState.ready,
  BootstrapOnboardingEnforcement onboardingEnforcement =
      BootstrapOnboardingEnforcement.required,
}) {
  final authoritativeDecision = AuthoritativeBootstrapDecision(
    userId: 'user-1',
    decision: decision,
    accountStatus: accountStatus,
    profileState: profileState,
    onboardingStatus: onboardingStatus,
    completedOnboardingVersion: onboardingStatus == OnboardingStatus.completed
        ? completedOnboardingVersion
        : null,
    requiredOnboardingVersion: 1,
    onboardingEnforcement: onboardingEnforcement,
    onboardingCompletedAt: onboardingCompletedAt,
    profileRevision: 3,
    policyRevision: 4,
  );
  return AuthoritativeBootstrapCacheEntryV2.fromAuthoritativeDecision(
    decision: authoritativeDecision,
    environmentId: 'dev',
    scopeKey: 'user-1|user-1|1',
    cachedAt: DateTime.utc(2026, 7, 29, 11),
  );
}

extension on AuthoritativeBootstrapCacheEntryV2 {
  AuthoritativeBootstrapDecision toAuthoritativeDecision() {
    return AuthoritativeBootstrapDecision(
      userId: userId,
      decision: destination,
      accountStatus: accountStatus,
      profileState: profileState,
      onboardingStatus: onboardingStatus,
      completedOnboardingVersion:
          completedOnboardingVersion == 0 ? null : completedOnboardingVersion,
      requiredOnboardingVersion: requiredOnboardingVersion,
      onboardingEnforcement: onboardingEnforcement,
      onboardingCompletedAt: onboardingCompletedAt,
      profileRevision: profileRevision,
      policyRevision: policyRevision,
    );
  }
}
