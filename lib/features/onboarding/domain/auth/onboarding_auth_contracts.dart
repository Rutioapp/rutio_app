import 'package:flutter/foundation.dart';

import '../../../../data/models/remote/remote_profile.dart';
import '../models/onboarding_draft.dart';

enum OnboardingAuthMethod { emailPassword, google, apple }

enum OnboardingAuthCommand { signUpWithEmail, signInWithEmail }

enum OnboardingAuthErrorCode {
  invalidCredentials,
  emailAlreadyRegistered,
  weakPassword,
  confirmationRequired,
  network,
  providerCancelled,
  providerFailure,
  sessionExpired,
  accountResolutionFailed,
  completionRetryable,
  completionFailed,
  operationConflict,
  crossUser,
  unknown,
}

@immutable
class OnboardingAuthError implements Exception {
  const OnboardingAuthError(this.code, {this.cause});

  final OnboardingAuthErrorCode code;
  final Object? cause;

  @override
  String toString() => 'OnboardingAuthError.${code.name}';
}

@immutable
class OnboardingAuthRequest {
  const OnboardingAuthRequest({
    required this.command,
    required this.method,
    required this.email,
    required this.operationId,
  });

  final OnboardingAuthCommand command;
  final OnboardingAuthMethod method;
  final String email;
  final String operationId;
}

@immutable
class AuthenticatedOnboardingSession {
  const AuthenticatedOnboardingSession({required this.userId});

  final String userId;
}

sealed class OnboardingAuthAttemptResult {
  const OnboardingAuthAttemptResult();
}

class OnboardingAuthenticated extends OnboardingAuthAttemptResult {
  const OnboardingAuthenticated(this.session);

  final AuthenticatedOnboardingSession session;
}

class OnboardingConfirmationRequired extends OnboardingAuthAttemptResult {
  const OnboardingConfirmationRequired();
}

class OnboardingAuthenticationFailed extends OnboardingAuthAttemptResult {
  const OnboardingAuthenticationFailed(this.error);

  final OnboardingAuthError error;
}

abstract interface class OnboardingAuthPort {
  Future<OnboardingAuthAttemptResult> authenticate(
      OnboardingAuthRequest request);
}

@immutable
class RemoteAccountSnapshot {
  const RemoteAccountSnapshot({
    required this.userId,
    this.profile,
    required this.remoteUserStateAvailable,
  });

  final String userId;
  final RemoteProfile? profile;
  final bool remoteUserStateAvailable;
}

enum OnboardingAccountResolution {
  newAccount,
  existingAccountCompleted,
  existingAccountIncomplete,
}

@immutable
class OnboardingAccountResolutionResult {
  const OnboardingAccountResolutionResult({
    required this.account,
    required this.classification,
  });

  final RemoteAccountSnapshot account;
  final OnboardingAccountResolution classification;

  bool get remoteWins =>
      classification != OnboardingAccountResolution.newAccount;
}

abstract interface class OnboardingAccountResolver {
  Future<RemoteAccountSnapshot> loadRemoteAccountSnapshot(String userId);
}

class OnboardingAccountResolutionService {
  const OnboardingAccountResolutionService(this._resolver);

  final OnboardingAccountResolver _resolver;

  Future<OnboardingAccountResolutionResult> resolve(
      String authenticatedUserId) async {
    final userId = authenticatedUserId.trim();
    if (userId.isEmpty) {
      throw const OnboardingAuthError(OnboardingAuthErrorCode.crossUser);
    }
    final snapshot = await _resolver.loadRemoteAccountSnapshot(userId);
    if (snapshot.userId.trim() != userId ||
        !snapshot.remoteUserStateAvailable) {
      throw const OnboardingAuthError(
        OnboardingAuthErrorCode.accountResolutionFailed,
      );
    }
    final profile = snapshot.profile;
    final classification = profile == null
        ? OnboardingAccountResolution.newAccount
        : profile.onboardingStatus == OnboardingStatus.completed
            ? OnboardingAccountResolution.existingAccountCompleted
            : OnboardingAccountResolution.existingAccountIncomplete;
    return OnboardingAccountResolutionResult(
      account: snapshot,
      classification: classification,
    );
  }
}

enum PreparedHabitDecision { undecided, keep, discard }

enum OnboardingProfileApplication { applyDraft, preserveRemote }

@immutable
class OnboardingCompletionIntent {
  const OnboardingCompletionIntent({
    required this.operationId,
    required this.authenticatedUserId,
    required this.accountResolution,
    required this.preparedHabitDecision,
    required this.profileApplication,
    this.name,
    this.preparedHabit,
    this.reminder,
  });

  factory OnboardingCompletionIntent.fromDraft({
    required OnboardingDraft draft,
    required String authenticatedUserId,
    required OnboardingAccountResolutionResult resolution,
    required PreparedHabitDecision preparedHabitDecision,
  }) {
    final existing =
        resolution.classification != OnboardingAccountResolution.newAccount;
    if (existing &&
        draft.habit != null &&
        preparedHabitDecision == PreparedHabitDecision.undecided) {
      throw const OnboardingAuthError(OnboardingAuthErrorCode.unknown);
    }
    final keepHabit = draft.habit != null &&
        (preparedHabitDecision == PreparedHabitDecision.keep || !existing);
    return OnboardingCompletionIntent(
      operationId: draft.onboardingOperationId,
      authenticatedUserId: authenticatedUserId,
      accountResolution: resolution.classification,
      preparedHabitDecision:
          keepHabit ? PreparedHabitDecision.keep : preparedHabitDecision,
      profileApplication: existing
          ? OnboardingProfileApplication.preserveRemote
          : OnboardingProfileApplication.applyDraft,
      name: existing ? null : draft.firstName,
      preparedHabit: keepHabit ? draft.habit : null,
      reminder: keepHabit ? draft.reminder : null,
    );
  }

  final String operationId;
  final String authenticatedUserId;
  final OnboardingAccountResolution accountResolution;
  final PreparedHabitDecision preparedHabitDecision;
  final OnboardingProfileApplication profileApplication;
  final String? name;
  final Map<String, dynamic>? preparedHabit;
  final Map<String, dynamic>? reminder;
}

enum OnboardingCompletionResultKind {
  completed,
  alreadyCompletedSameOperation,
  conflict,
  retryableFailure,
  terminalFailure,
}

@immutable
class OnboardingCompletionResult {
  const OnboardingCompletionResult({
    required this.kind,
    required this.operationId,
    required this.userId,
    this.error,
  });

  final OnboardingCompletionResultKind kind;
  final String operationId;
  final String userId;
  final OnboardingAuthError? error;

  bool get isSuccess =>
      kind == OnboardingCompletionResultKind.completed ||
      kind == OnboardingCompletionResultKind.alreadyCompletedSameOperation;
}

abstract interface class OnboardingCompletionPort {
  Future<OnboardingCompletionResult> completeOnboarding(
    OnboardingCompletionIntent intent,
  );
}

abstract interface class OnboardingAuthDraftPersistence {
  Future<void> save(OnboardingDraft draft);
  Future<void> clear(OnboardingDraft draft);
}
