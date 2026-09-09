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
  confirmationNotDetected,
  resendRateLimited,
  invalidEmail,
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
    this.password,
  });

  final OnboardingAuthCommand command;
  final OnboardingAuthMethod method;
  final String email;
  final String operationId;

  /// Ephemeral submit input. It is deliberately absent from every draft and
  /// persistence contract and must be discarded as soon as the request ends.
  final String? password;
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

/// Optional AUTH-4B capabilities. Keeping these outside the base port keeps
/// AUTH-3/4A test doubles and non-email providers source-compatible.
abstract interface class OnboardingEmailConfirmationPort {
  Future<void> resendConfirmation(String email);
  Future<AuthenticatedOnboardingSession?> refreshConfirmedSession();
}

@immutable
class RemoteAccountSnapshot {
  const RemoteAccountSnapshot({
    required this.userId,
    this.profile,
    required this.remoteUserStateAvailable,
    this.isFreshBootstrapProfile = false,
  });

  final String userId;
  final RemoteProfile? profile;
  final bool remoteUserStateAvailable;

  /// True only when the remote profile has the shape of the account bootstrap
  /// shell: it is pending, untouched, and was created with the auth account.
  /// This is deliberately supplied by the data adapter; the domain service
  /// must not infer freshness from the signup button or callback provenance.
  final bool isFreshBootstrapProfile;
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
    final classification = profile == null || snapshot.isFreshBootstrapProfile
        ? OnboardingAccountResolution.newAccount
        : profile.onboardingStatus == OnboardingStatus.completed
            ? OnboardingAccountResolution.existingAccountCompleted
            : OnboardingAccountResolution.existingAccountIncomplete;
    if (kDebugMode) {
      debugPrint(
        '[ONBOARDING_AUTH] event=resolution_decision '
        'user=${_shortId(userId)} profileExists=${profile != null} '
        'remoteStatus=${profile?.onboardingStatus.name ?? 'none'} '
        'remoteCompleted=${profile?.onboardingCompletedAt != null} '
        'freshBootstrap=${snapshot.isFreshBootstrapProfile} '
        'resolution=${classification.name}',
      );
    }
    return OnboardingAccountResolutionResult(
      account: snapshot,
      classification: classification,
    );
  }

  static String _shortId(String value) =>
      value.length <= 8 ? value : value.substring(0, 8);
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

  factory OnboardingCompletionIntent.fromPersistedRecovery({
    required OnboardingDraft draft,
    required String authenticatedUserId,
  }) {
    final normalizedUserId = authenticatedUserId.trim();
    final boundUserId = draft.boundUserId?.trim();
    if (normalizedUserId.isEmpty ||
        boundUserId == null ||
        boundUserId.isEmpty) {
      throw const OnboardingAuthError(
        OnboardingAuthErrorCode.completionRetryable,
      );
    }
    if (boundUserId != normalizedUserId) {
      throw const OnboardingAuthError(OnboardingAuthErrorCode.crossUser);
    }
    final resolution = OnboardingAccountResolution.values
        .where((candidate) =>
            candidate.name == draft.completionAccountResolutionCode)
        .firstOrNull;
    final decision = PreparedHabitDecision.values
        .where((candidate) =>
            candidate.name == draft.completionPreparedHabitDecisionCode)
        .firstOrNull;
    if (resolution == null || decision == null) {
      throw const OnboardingAuthError(
        OnboardingAuthErrorCode.completionRetryable,
      );
    }
    final existing = resolution != OnboardingAccountResolution.newAccount;
    final keepHabit = draft.habit != null &&
        (decision == PreparedHabitDecision.keep || !existing);
    return OnboardingCompletionIntent(
      operationId: draft.onboardingOperationId,
      authenticatedUserId: normalizedUserId,
      accountResolution: resolution,
      preparedHabitDecision: keepHabit ? PreparedHabitDecision.keep : decision,
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
    this.habitId,
    this.preparedHabitApplied = false,
    this.accountResolution,
    this.completedAt,
    this.error,
  });

  final OnboardingCompletionResultKind kind;
  final String operationId;
  final String userId;
  final String? habitId;
  final bool preparedHabitApplied;
  final OnboardingAccountResolution? accountResolution;
  final DateTime? completedAt;
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

/// Local work that must happen after the remote transaction has definitively
/// succeeded. It is deliberately separate from the RPC port because OS
/// notifications are not part of the database transaction.
abstract interface class OnboardingCompletionReconciler {
  Future<void> reconcile({
    required OnboardingCompletionIntent intent,
    required OnboardingCompletionResult result,
  });
}

abstract interface class OnboardingAuthDraftPersistence {
  Future<void> save(OnboardingDraft draft);
  Future<void> clear(OnboardingDraft draft);
}
