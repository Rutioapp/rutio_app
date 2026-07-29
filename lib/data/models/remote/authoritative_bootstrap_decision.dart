import 'package:flutter/foundation.dart';

import 'remote_profile.dart';

enum AuthoritativeBootstrapDestination {
  home,
  onboarding,
  profileUninitialized,
  profileDeleted,
  accountSuspended,
  accountPendingDeletion,
  invalidProfile;

  static AuthoritativeBootstrapDestination fromSupabase(String value) {
    final normalized = value.trim();
    switch (normalized) {
      case 'home':
        return AuthoritativeBootstrapDestination.home;
      case 'onboarding':
        return AuthoritativeBootstrapDestination.onboarding;
      case 'profile_uninitialized':
        return AuthoritativeBootstrapDestination.profileUninitialized;
      case 'profile_deleted':
        return AuthoritativeBootstrapDestination.profileDeleted;
      case 'account_suspended':
        return AuthoritativeBootstrapDestination.accountSuspended;
      case 'account_pending_deletion':
        return AuthoritativeBootstrapDestination.accountPendingDeletion;
      case 'invalid_profile':
        return AuthoritativeBootstrapDestination.invalidProfile;
    }
    throw AuthoritativeBootstrapDecisionParseException(
      'Unknown decision "$value".',
    );
  }
}

enum BootstrapAccountStatus {
  active,
  suspended,
  pendingDeletion;

  static BootstrapAccountStatus fromSupabase(String value) {
    final normalized = value.trim();
    switch (normalized) {
      case 'active':
        return BootstrapAccountStatus.active;
      case 'suspended':
        return BootstrapAccountStatus.suspended;
      case 'pending_deletion':
        return BootstrapAccountStatus.pendingDeletion;
    }
    throw AuthoritativeBootstrapDecisionParseException(
      'Unknown account_status "$value".',
    );
  }
}

enum BootstrapProfileState {
  uninitialized,
  ready,
  deleted;

  static BootstrapProfileState fromSupabase(String value) {
    final normalized = value.trim();
    switch (normalized) {
      case 'uninitialized':
        return BootstrapProfileState.uninitialized;
      case 'ready':
        return BootstrapProfileState.ready;
      case 'deleted':
        return BootstrapProfileState.deleted;
    }
    throw AuthoritativeBootstrapDecisionParseException(
      'Unknown profile_state "$value".',
    );
  }
}

enum BootstrapOnboardingEnforcement {
  advisory,
  required;

  static BootstrapOnboardingEnforcement fromSupabase(String value) {
    final normalized = value.trim();
    switch (normalized) {
      case 'advisory':
        return BootstrapOnboardingEnforcement.advisory;
      case 'required':
        return BootstrapOnboardingEnforcement.required;
    }
    throw AuthoritativeBootstrapDecisionParseException(
      'Unknown onboarding_enforcement "$value".',
    );
  }
}

enum AuthoritativeBootstrapDecisionFailureCode {
  notAuthenticated,
  rpcUnavailable,
  emptyResponse,
  invalidPayload,
  identityMismatch,
  unknownDecision,
  inconsistentContract,
  staleResult,
}

enum AuthoritativeBootstrapShadowComparisonKind {
  matchHome,
  matchOnboarding,
  authoritativeProfileUninitialized,
  authoritativeProfileDeleted,
  authoritativeAccountSuspended,
  authoritativeAccountPendingDeletion,
  authoritativeInvalidProfile,
  destinationMismatch,
  identityMismatch,
  shadowError,
  staleDiscard,
}

@immutable
class AuthoritativeBootstrapDecision {
  const AuthoritativeBootstrapDecision({
    required this.userId,
    required this.decision,
    required this.accountStatus,
    required this.profileState,
    required this.onboardingStatus,
    required this.completedOnboardingVersion,
    required this.requiredOnboardingVersion,
    required this.onboardingEnforcement,
    required this.onboardingCompletedAt,
    required this.profileRevision,
    required this.policyRevision,
  });

  final String userId;
  final AuthoritativeBootstrapDestination decision;
  final BootstrapAccountStatus accountStatus;
  final BootstrapProfileState profileState;
  final OnboardingStatus? onboardingStatus;
  final int? completedOnboardingVersion;
  final int requiredOnboardingVersion;
  final BootstrapOnboardingEnforcement onboardingEnforcement;
  final DateTime? onboardingCompletedAt;
  final int profileRevision;
  final int policyRevision;

  factory AuthoritativeBootstrapDecision.fromMap(
    Map<String, dynamic> map, {
    required String expectedUserId,
  }) {
    final userId = _requiredTrim(map, 'user_id');
    if (userId != expectedUserId) {
      throw AuthoritativeBootstrapDecisionParseException(
        'Decision user_id "$userId" did not match the authenticated user.',
      );
    }

    final decision = AuthoritativeBootstrapDestination.fromSupabase(
      _requiredTrim(map, 'decision'),
    );
    final accountStatus = BootstrapAccountStatus.fromSupabase(
      _requiredTrim(map, 'account_status'),
    );
    final profileState = BootstrapProfileState.fromSupabase(
      _requiredTrim(map, 'profile_state'),
    );
    final onboardingStatus = _readOnboardingStatus(
      map['onboarding_status'] ?? map['onboardingStatus'],
    );
    final completedOnboardingVersion = _readNullablePositiveInt(
      map['completed_onboarding_version'] ?? map['completedOnboardingVersion'],
      allowZero: false,
    );
    final requiredOnboardingVersion = _requiredPositiveInt(
      map,
      'required_onboarding_version',
    );
    final onboardingEnforcement = BootstrapOnboardingEnforcement.fromSupabase(
      _requiredTrim(map, 'onboarding_enforcement'),
    );
    final onboardingCompletedAt = _readNullableDateTime(
      map['onboarding_completed_at'] ?? map['onboardingCompletedAt'],
    );
    final profileRevision = _requiredNonNegativeInt(map, 'profile_revision');
    final policyRevision = _requiredPositiveInt(map, 'policy_revision');

    _validateContract(
      decision: decision,
      accountStatus: accountStatus,
      profileState: profileState,
      onboardingStatus: onboardingStatus,
      completedOnboardingVersion: completedOnboardingVersion,
      requiredOnboardingVersion: requiredOnboardingVersion,
      onboardingEnforcement: onboardingEnforcement,
      onboardingCompletedAt: onboardingCompletedAt,
    );

    return AuthoritativeBootstrapDecision(
      userId: userId,
      decision: decision,
      accountStatus: accountStatus,
      profileState: profileState,
      onboardingStatus: onboardingStatus,
      completedOnboardingVersion: completedOnboardingVersion,
      requiredOnboardingVersion: requiredOnboardingVersion,
      onboardingEnforcement: onboardingEnforcement,
      onboardingCompletedAt: onboardingCompletedAt,
      profileRevision: profileRevision,
      policyRevision: policyRevision,
    );
  }

  BootstrapProfileDecision? toBootstrapProfileDecision() {
    final onboardingStatus = this.onboardingStatus;
    if (onboardingStatus == null) return null;
    final completedVersion = completedOnboardingVersion ??
        (onboardingStatus == OnboardingStatus.completed
            ? requiredOnboardingVersion
            : null);
    return BootstrapProfileDecision(
      userId: userId,
      onboardingStatus: onboardingStatus,
      onboardingVersion: completedVersion ?? requiredOnboardingVersion,
      onboardingCompletedAt: onboardingCompletedAt,
    );
  }
}

@immutable
class AuthoritativeBootstrapShadowComparison {
  const AuthoritativeBootstrapShadowComparison({
    required this.kind,
    required this.current,
    required this.authoritative,
  });

  final AuthoritativeBootstrapShadowComparisonKind kind;
  final BootstrapProfileDecision current;
  final AuthoritativeBootstrapDecision authoritative;

  static AuthoritativeBootstrapShadowComparison compare({
    required BootstrapProfileDecision current,
    required AuthoritativeBootstrapDecision authoritative,
  }) {
    if (current.userId != authoritative.userId) {
      return AuthoritativeBootstrapShadowComparison(
        kind: AuthoritativeBootstrapShadowComparisonKind.identityMismatch,
        current: current,
        authoritative: authoritative,
      );
    }

    switch (authoritative.decision) {
      case AuthoritativeBootstrapDestination.home:
        final matches = current.onboardingStatus == OnboardingStatus.completed;
        return AuthoritativeBootstrapShadowComparison(
          kind: matches
              ? AuthoritativeBootstrapShadowComparisonKind.matchHome
              : AuthoritativeBootstrapShadowComparisonKind.destinationMismatch,
          current: current,
          authoritative: authoritative,
        );
      case AuthoritativeBootstrapDestination.onboarding:
        final matches = current.onboardingStatus != OnboardingStatus.completed;
        return AuthoritativeBootstrapShadowComparison(
          kind: matches
              ? AuthoritativeBootstrapShadowComparisonKind.matchOnboarding
              : AuthoritativeBootstrapShadowComparisonKind.destinationMismatch,
          current: current,
          authoritative: authoritative,
        );
      case AuthoritativeBootstrapDestination.profileUninitialized:
        return AuthoritativeBootstrapShadowComparison(
          kind: AuthoritativeBootstrapShadowComparisonKind
              .authoritativeProfileUninitialized,
          current: current,
          authoritative: authoritative,
        );
      case AuthoritativeBootstrapDestination.profileDeleted:
        return AuthoritativeBootstrapShadowComparison(
          kind: AuthoritativeBootstrapShadowComparisonKind
              .authoritativeProfileDeleted,
          current: current,
          authoritative: authoritative,
        );
      case AuthoritativeBootstrapDestination.accountSuspended:
        return AuthoritativeBootstrapShadowComparison(
          kind: AuthoritativeBootstrapShadowComparisonKind
              .authoritativeAccountSuspended,
          current: current,
          authoritative: authoritative,
        );
      case AuthoritativeBootstrapDestination.accountPendingDeletion:
        return AuthoritativeBootstrapShadowComparison(
          kind: AuthoritativeBootstrapShadowComparisonKind
              .authoritativeAccountPendingDeletion,
          current: current,
          authoritative: authoritative,
        );
      case AuthoritativeBootstrapDestination.invalidProfile:
        return AuthoritativeBootstrapShadowComparison(
          kind: AuthoritativeBootstrapShadowComparisonKind
              .authoritativeInvalidProfile,
          current: current,
          authoritative: authoritative,
        );
    }
  }
}

@immutable
class AuthoritativeBootstrapDecisionReadException implements Exception {
  const AuthoritativeBootstrapDecisionReadException({
    required this.code,
    required this.message,
    this.cause,
  });

  final AuthoritativeBootstrapDecisionFailureCode code;
  final String message;
  final Object? cause;
}

class AuthoritativeBootstrapDecisionParseException implements FormatException {
  const AuthoritativeBootstrapDecisionParseException(this.message);

  @override
  final String message;

  @override
  dynamic get source => null;

  @override
  int? get offset => null;
}

String _requiredTrim(Map<String, dynamic> map, String key) {
  final normalized = _nullableTrim(map[key]);
  if (normalized == null) {
    throw AuthoritativeBootstrapDecisionParseException(
      'Missing required "$key".',
    );
  }
  return normalized;
}

String? _nullableTrim(dynamic value) {
  final normalized = (value ?? '').toString().trim();
  return normalized.isEmpty ? null : normalized;
}

int _requiredPositiveInt(Map<String, dynamic> map, String key) {
  final parsed = _readNullablePositiveInt(map[key], allowZero: false);
  if (parsed == null) {
    throw AuthoritativeBootstrapDecisionParseException(
      'Invalid "$key".',
    );
  }
  return parsed;
}

int _requiredNonNegativeInt(Map<String, dynamic> map, String key) {
  final parsed = _readNullablePositiveInt(map[key], allowZero: true);
  if (parsed == null) {
    throw AuthoritativeBootstrapDecisionParseException(
      'Invalid "$key".',
    );
  }
  return parsed;
}

int? _readNullablePositiveInt(dynamic value, {required bool allowZero}) {
  final parsed = value is int
      ? value
      : value is num
          ? value.toInt()
          : int.tryParse((value ?? '').toString().trim());
  if (parsed == null) return null;
  if (parsed < 0) return null;
  if (!allowZero && parsed < 1) return null;
  return parsed;
}

OnboardingStatus? _readOnboardingStatus(dynamic value) {
  final normalized = _nullableTrim(value);
  if (normalized == null) return null;
  try {
    return OnboardingStatus.fromSupabase(normalized);
  } on RemoteProfileParseException catch (error) {
    throw AuthoritativeBootstrapDecisionParseException(error.message);
  }
}

DateTime? _readNullableDateTime(dynamic value) {
  final normalized = _nullableTrim(value);
  if (normalized == null) return null;
  final parsed = DateTime.tryParse(normalized);
  if (parsed == null) {
    throw AuthoritativeBootstrapDecisionParseException(
      'Invalid date-time value "$normalized".',
    );
  }
  return parsed.toUtc();
}

void _validateContract({
  required AuthoritativeBootstrapDestination decision,
  required BootstrapAccountStatus accountStatus,
  required BootstrapProfileState profileState,
  required OnboardingStatus? onboardingStatus,
  required int? completedOnboardingVersion,
  required int requiredOnboardingVersion,
  required BootstrapOnboardingEnforcement onboardingEnforcement,
  required DateTime? onboardingCompletedAt,
}) {
  if (requiredOnboardingVersion < 1) {
    throw AuthoritativeBootstrapDecisionParseException(
      'required_onboarding_version must be >= 1.',
    );
  }

  switch (decision) {
    case AuthoritativeBootstrapDestination.home:
      if (accountStatus != BootstrapAccountStatus.active ||
          profileState != BootstrapProfileState.ready ||
          onboardingStatus != OnboardingStatus.completed ||
          completedOnboardingVersion == null ||
          completedOnboardingVersion < 1 ||
          onboardingCompletedAt == null) {
        throw AuthoritativeBootstrapDecisionParseException(
          'Home decision is not coherent.',
        );
      }
      if (onboardingEnforcement == BootstrapOnboardingEnforcement.required &&
          completedOnboardingVersion < requiredOnboardingVersion) {
        throw AuthoritativeBootstrapDecisionParseException(
          'Home decision violates the required onboarding policy.',
        );
      }
      return;
    case AuthoritativeBootstrapDestination.onboarding:
      if (accountStatus != BootstrapAccountStatus.active ||
          profileState != BootstrapProfileState.ready ||
          onboardingStatus == null) {
        throw AuthoritativeBootstrapDecisionParseException(
          'Onboarding decision is not coherent.',
        );
      }
      if (onboardingStatus == OnboardingStatus.completed) {
        if (completedOnboardingVersion == null ||
            completedOnboardingVersion < 1 ||
            onboardingCompletedAt == null ||
            onboardingEnforcement != BootstrapOnboardingEnforcement.required ||
            completedOnboardingVersion < requiredOnboardingVersion) {
          throw AuthoritativeBootstrapDecisionParseException(
            'Onboarding decision is not coherent.',
          );
        }
        return;
      }
      if (onboardingStatus != OnboardingStatus.pending &&
          onboardingStatus != OnboardingStatus.inProgress) {
        throw AuthoritativeBootstrapDecisionParseException(
          'Onboarding decision is not coherent.',
        );
      }
      if (completedOnboardingVersion != null || onboardingCompletedAt != null) {
        throw AuthoritativeBootstrapDecisionParseException(
          'Onboarding decision is not coherent.',
        );
      }
      return;
    case AuthoritativeBootstrapDestination.profileUninitialized:
      if (accountStatus != BootstrapAccountStatus.active ||
          profileState != BootstrapProfileState.uninitialized ||
          onboardingStatus != null ||
          completedOnboardingVersion != null ||
          onboardingCompletedAt != null) {
        throw AuthoritativeBootstrapDecisionParseException(
          'Profile uninitialized decision is not coherent.',
        );
      }
      return;
    case AuthoritativeBootstrapDestination.profileDeleted:
      if (accountStatus != BootstrapAccountStatus.active ||
          profileState != BootstrapProfileState.deleted ||
          onboardingStatus != null ||
          completedOnboardingVersion != null ||
          onboardingCompletedAt != null) {
        throw AuthoritativeBootstrapDecisionParseException(
          'Profile deleted decision is not coherent.',
        );
      }
      return;
    case AuthoritativeBootstrapDestination.accountSuspended:
    case AuthoritativeBootstrapDestination.accountPendingDeletion:
      if (accountStatus == BootstrapAccountStatus.active) {
        throw AuthoritativeBootstrapDecisionParseException(
          'Account lifecycle decision is not coherent.',
        );
      }
      if (onboardingStatus != null ||
          completedOnboardingVersion != null ||
          onboardingCompletedAt != null) {
        throw AuthoritativeBootstrapDecisionParseException(
          'Account lifecycle decision is not coherent.',
        );
      }
      return;
    case AuthoritativeBootstrapDestination.invalidProfile:
      if (accountStatus != BootstrapAccountStatus.active ||
          profileState != BootstrapProfileState.ready) {
        throw AuthoritativeBootstrapDecisionParseException(
          'Invalid profile decision is not coherent.',
        );
      }
      final pendingInconsistent = onboardingStatus == null ||
          (onboardingStatus == OnboardingStatus.completed &&
              (completedOnboardingVersion == null ||
                  completedOnboardingVersion < 1 ||
                  onboardingCompletedAt == null)) ||
          ((onboardingStatus == OnboardingStatus.pending ||
                  onboardingStatus == OnboardingStatus.inProgress) &&
              onboardingCompletedAt != null);
      if (!pendingInconsistent) {
        throw AuthoritativeBootstrapDecisionParseException(
          'Invalid profile decision is not coherent.',
        );
      }
      return;
  }
}
