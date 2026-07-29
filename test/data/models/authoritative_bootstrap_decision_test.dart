import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/models/remote/authoritative_bootstrap_decision.dart';
import 'package:rutio/data/models/remote/remote_profile.dart';

void main() {
  group('AuthoritativeBootstrapDecision', () {
    test('parses a home decision and maps to bootstrap profile decision', () {
      final decision = AuthoritativeBootstrapDecision.fromMap(
        _row(
          decision: 'home',
          onboardingStatus: 'completed',
          completedVersion: 2,
          completedAt: '2026-07-28T10:15:00.000Z',
        ),
        expectedUserId: 'user-1',
      );

      expect(decision.userId, 'user-1');
      expect(decision.decision, AuthoritativeBootstrapDestination.home);
      expect(decision.accountStatus, BootstrapAccountStatus.active);
      expect(decision.profileState, BootstrapProfileState.ready);
      expect(decision.onboardingStatus, OnboardingStatus.completed);
      expect(decision.completedOnboardingVersion, 2);
      expect(decision.requiredOnboardingVersion, 1);
      expect(decision.onboardingEnforcement,
          BootstrapOnboardingEnforcement.required);
      expect(decision.onboardingCompletedAt,
          DateTime.parse('2026-07-28T10:15:00.000Z'));
      expect(decision.profileRevision, 3);
      expect(decision.policyRevision, 4);

      final bootstrapDecision = decision.toBootstrapProfileDecision();
      expect(bootstrapDecision, isNotNull);
      expect(bootstrapDecision!.userId, 'user-1');
      expect(bootstrapDecision.onboardingStatus, OnboardingStatus.completed);
      expect(bootstrapDecision.onboardingVersion, 2);
      expect(
        bootstrapDecision.onboardingCompletedAt,
        DateTime.parse('2026-07-28T10:15:00.000Z'),
      );
    });

    test('parses onboarding decision without a completed timestamp', () {
      final decision = AuthoritativeBootstrapDecision.fromMap(
        _row(
          decision: 'onboarding',
          onboardingStatus: 'pending',
          completedVersion: null,
          completedAt: null,
          accountStatus: 'active',
          profileState: 'ready',
          onboardingEnforcement: 'advisory',
        ),
        expectedUserId: 'user-1',
      );

      expect(decision.decision, AuthoritativeBootstrapDestination.onboarding);
      expect(decision.onboardingStatus, OnboardingStatus.pending);
      expect(decision.toBootstrapProfileDecision(), isNotNull);
    });

    test('rejects identity mismatch', () {
      expect(
        () => AuthoritativeBootstrapDecision.fromMap(
          _row(userId: 'user-2'),
          expectedUserId: 'user-1',
        ),
        throwsA(isA<AuthoritativeBootstrapDecisionParseException>()),
      );
    });

    test('rejects unknown account status', () {
      expect(
        () => AuthoritativeBootstrapDecision.fromMap(
          _row(accountStatus: 'unknown'),
          expectedUserId: 'user-1',
        ),
        throwsA(isA<AuthoritativeBootstrapDecisionParseException>()),
      );
    });

    test('rejects unknown profile state', () {
      expect(
        () => AuthoritativeBootstrapDecision.fromMap(
          _row(profileState: 'mystery'),
          expectedUserId: 'user-1',
        ),
        throwsA(isA<AuthoritativeBootstrapDecisionParseException>()),
      );
    });

    test('rejects unknown onboarding enforcement', () {
      expect(
        () => AuthoritativeBootstrapDecision.fromMap(
          _row(onboardingEnforcement: 'forced'),
          expectedUserId: 'user-1',
        ),
        throwsA(isA<AuthoritativeBootstrapDecisionParseException>()),
      );
    });

    test('rejects unknown decision', () {
      expect(
        () => AuthoritativeBootstrapDecision.fromMap(
          _row(decision: 'mystery'),
          expectedUserId: 'user-1',
        ),
        throwsA(isA<AuthoritativeBootstrapDecisionParseException>()),
      );
    });

    test('rejects incoherent home decision', () {
      expect(
        () => AuthoritativeBootstrapDecision.fromMap(
          _row(
            decision: 'home',
            onboardingStatus: 'pending',
            completedVersion: 1,
            completedAt: '2026-07-28T10:15:00.000Z',
          ),
          expectedUserId: 'user-1',
        ),
        throwsA(isA<AuthoritativeBootstrapDecisionParseException>()),
      );
    });

    test('rejects invalid policy revision', () {
      expect(
        () => AuthoritativeBootstrapDecision.fromMap(
          _row(policyRevision: 0),
          expectedUserId: 'user-1',
        ),
        throwsA(isA<AuthoritativeBootstrapDecisionParseException>()),
      );
    });

    test('rejects negative profile revision', () {
      expect(
        () => AuthoritativeBootstrapDecision.fromMap(
          _row(profileRevision: -1),
          expectedUserId: 'user-1',
        ),
        throwsA(isA<AuthoritativeBootstrapDecisionParseException>()),
      );
    });

    test('rejects invalid required onboarding version', () {
      expect(
        () => AuthoritativeBootstrapDecision.fromMap(
          _row(requiredVersion: 0),
          expectedUserId: 'user-1',
        ),
        throwsA(isA<AuthoritativeBootstrapDecisionParseException>()),
      );
    });

    test('rejects incoherent suspended home decision', () {
      expect(
        () => AuthoritativeBootstrapDecision.fromMap(
          _row(
            decision: 'home',
            accountStatus: 'suspended',
            completedVersion: 1,
            completedAt: '2026-07-28T10:15:00.000Z',
          ),
          expectedUserId: 'user-1',
        ),
        throwsA(isA<AuthoritativeBootstrapDecisionParseException>()),
      );
    });

    test('rejects incoherent deleted home decision', () {
      expect(
        () => AuthoritativeBootstrapDecision.fromMap(
          _row(
            decision: 'home',
            profileState: 'deleted',
            completedVersion: 1,
            completedAt: '2026-07-28T10:15:00.000Z',
          ),
          expectedUserId: 'user-1',
        ),
        throwsA(isA<AuthoritativeBootstrapDecisionParseException>()),
      );
    });

    test('rejects onboarding with required policy and insufficient version',
        () {
      expect(
        () => AuthoritativeBootstrapDecision.fromMap(
          _row(
            decision: 'onboarding',
            onboardingStatus: 'completed',
            completedVersion: 1,
            requiredVersion: 2,
            completedAt: '2026-07-28T10:15:00.000Z',
          ),
          expectedUserId: 'user-1',
        ),
        throwsA(isA<AuthoritativeBootstrapDecisionParseException>()),
      );
    });

    test('comparison classifies match and mismatch cases', () {
      final current = BootstrapProfileDecision(
        userId: 'user-1',
        onboardingStatus: OnboardingStatus.completed,
        onboardingVersion: 2,
        onboardingCompletedAt: DateTime.utc(2026, 7, 28),
      );
      final authoritative = AuthoritativeBootstrapDecision.fromMap(
        _row(
          decision: 'home',
          onboardingStatus: 'completed',
          completedVersion: 2,
          completedAt: '2026-07-28T10:15:00.000Z',
        ),
        expectedUserId: 'user-1',
      );

      final comparison = AuthoritativeBootstrapShadowComparison.compare(
        current: current,
        authoritative: authoritative,
      );

      expect(comparison.kind,
          AuthoritativeBootstrapShadowComparisonKind.matchHome);
      expect(comparison.current, current);
      expect(comparison.authoritative, authoritative);
    });

    test('comparison classifies special authoritative destinations', () {
      final current = BootstrapProfileDecision(
        userId: 'user-1',
        onboardingStatus: OnboardingStatus.completed,
        onboardingVersion: 2,
        onboardingCompletedAt: DateTime.utc(2026, 7, 28),
      );

      final cases = <String, AuthoritativeBootstrapShadowComparisonKind>{
        'profile_uninitialized': AuthoritativeBootstrapShadowComparisonKind
            .authoritativeProfileUninitialized,
        'profile_deleted': AuthoritativeBootstrapShadowComparisonKind
            .authoritativeProfileDeleted,
        'account_suspended': AuthoritativeBootstrapShadowComparisonKind
            .authoritativeAccountSuspended,
        'account_pending_deletion': AuthoritativeBootstrapShadowComparisonKind
            .authoritativeAccountPendingDeletion,
        'invalid_profile': AuthoritativeBootstrapShadowComparisonKind
            .authoritativeInvalidProfile,
      };

      for (final entry in cases.entries) {
        final isInvalidProfile = entry.key == 'invalid_profile';
        final authoritative = AuthoritativeBootstrapDecision.fromMap(
          _row(
            decision: entry.key,
            onboardingStatus: isInvalidProfile ? 'pending' : null,
            completedVersion: null,
            completedAt: isInvalidProfile ? '2026-07-28T10:15:00.000Z' : null,
            accountStatus: entry.key == 'profile_uninitialized'
                ? 'active'
                : entry.key == 'profile_deleted'
                    ? 'active'
                    : entry.key == 'account_suspended'
                        ? 'suspended'
                        : entry.key == 'account_pending_deletion'
                            ? 'pending_deletion'
                            : 'active',
            profileState: entry.key == 'profile_uninitialized'
                ? 'uninitialized'
                : entry.key == 'profile_deleted'
                    ? 'deleted'
                    : 'ready',
            onboardingEnforcement: 'advisory',
          ),
          expectedUserId: 'user-1',
        );

        final comparison = AuthoritativeBootstrapShadowComparison.compare(
          current: current,
          authoritative: authoritative,
        );

        expect(comparison.kind, entry.value);
      }
    });
  });
}

Map<String, dynamic> _row({
  String userId = 'user-1',
  String decision = 'home',
  String accountStatus = 'active',
  String profileState = 'ready',
  String? onboardingStatus = 'completed',
  int? completedVersion = 1,
  int requiredVersion = 1,
  String onboardingEnforcement = 'required',
  Object? completedAt = '2026-07-28T10:15:00.000Z',
  int profileRevision = 3,
  int policyRevision = 4,
}) {
  return <String, dynamic>{
    'user_id': userId,
    'decision': decision,
    'account_status': accountStatus,
    'profile_state': profileState,
    'onboarding_status': onboardingStatus,
    'completed_onboarding_version': completedVersion,
    'required_onboarding_version': requiredVersion,
    'onboarding_enforcement': onboardingEnforcement,
    'onboarding_completed_at': completedAt,
    'profile_revision': profileRevision,
    'policy_revision': policyRevision,
  };
}
