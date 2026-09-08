import 'package:flutter/foundation.dart';

import '../../domain/auth/onboarding_auth_contracts.dart';
import '../../domain/models/onboarding_draft.dart';
import '../../domain/models/onboarding_types.dart';

enum OnboardingAuthPhase {
  idle,
  ready,
  authenticating,
  awaitingEmailConfirmation,
  authenticated,
  resolvingAccount,
  awaitingPreparedHabitDecision,
  readyToComplete,
  completing,
  completed,
  failure,
}

@immutable
class OnboardingAuthState {
  const OnboardingAuthState({
    required this.phase,
    required this.draft,
    this.authenticatedUserId,
    this.pendingAuthRequest,
    this.resolution,
    this.preparedHabitDecision = PreparedHabitDecision.undecided,
    this.intent,
    this.error,
  });

  final OnboardingAuthPhase phase;
  final OnboardingDraft draft;
  final String? authenticatedUserId;
  final OnboardingAuthRequest? pendingAuthRequest;
  final OnboardingAccountResolutionResult? resolution;
  final PreparedHabitDecision preparedHabitDecision;
  final OnboardingCompletionIntent? intent;
  final OnboardingAuthError? error;
}

class OnboardingAuthStateMachine extends ChangeNotifier {
  OnboardingAuthStateMachine({
    required OnboardingDraft draft,
    required OnboardingAuthPort auth,
    required OnboardingAccountResolutionService accountResolution,
    required OnboardingCompletionPort completion,
    OnboardingAuthDraftPersistence? draftPersistence,
  })  : _auth = auth,
        _accountResolution = accountResolution,
        _completion = completion,
        _draftPersistence = draftPersistence,
        _state = OnboardingAuthState(
          phase: draft.currentStep == OnboardingStep.emailConfirmation
              ? OnboardingAuthPhase.awaitingEmailConfirmation
              : draft.currentStep == OnboardingStep.auth
                  ? OnboardingAuthPhase.ready
                  : OnboardingAuthPhase.idle,
          draft: draft,
        );

  final OnboardingAuthPort _auth;
  final OnboardingAccountResolutionService _accountResolution;
  final OnboardingCompletionPort _completion;
  final OnboardingAuthDraftPersistence? _draftPersistence;
  OnboardingAuthState _state;
  String? _lastSessionUserId;

  OnboardingAuthState get state => _state;

  Future<bool> authenticate({
    required OnboardingAuthCommand command,
    required String email,
    String password = '',
    OnboardingAuthMethod method = OnboardingAuthMethod.emailPassword,
  }) async {
    if (_state.phase == OnboardingAuthPhase.authenticating ||
        _state.phase == OnboardingAuthPhase.completing ||
        _state.phase == OnboardingAuthPhase.completed) {
      return false;
    }
    final pendingDraft = _state.draft.copyWith(
      authIntent: command == OnboardingAuthCommand.signUpWithEmail
          ? AuthIntent.signUp
          : AuthIntent.signIn,
      completionState: OnboardingCompletionState.authPending,
      currentStep: OnboardingStep.auth,
      authEmail: email.trim(),
    );
    _publish(OnboardingAuthState(
      phase: OnboardingAuthPhase.authenticating,
      draft: pendingDraft,
      pendingAuthRequest: OnboardingAuthRequest(
        command: command,
        method: method,
        email: email.trim(),
        password: password,
        operationId: pendingDraft.onboardingOperationId,
      ),
    ));
    // Publish the in-flight phase before the first await so a second tap in
    // the same event turn cannot start another network request.
    await _persist(pendingDraft);
    final result = await _auth.authenticate(OnboardingAuthRequest(
      command: command,
      method: method,
      email: email.trim(),
      operationId: pendingDraft.onboardingOperationId,
      password: password,
    ));
    if (result is OnboardingConfirmationRequired) {
      _publish(OnboardingAuthState(
        phase: OnboardingAuthPhase.awaitingEmailConfirmation,
        draft: pendingDraft.copyWith(
            currentStep: OnboardingStep.emailConfirmation),
        pendingAuthRequest: OnboardingAuthRequest(
          command: command,
          method: method,
          email: email.trim(),
          operationId: pendingDraft.onboardingOperationId,
        ),
      ));
      await _persist(
          pendingDraft.copyWith(currentStep: OnboardingStep.emailConfirmation));
      return true;
    }
    if (result is OnboardingAuthenticationFailed) {
      _publish(OnboardingAuthState(
        phase: OnboardingAuthPhase.failure,
        draft: pendingDraft,
        error: result.error,
      ));
      return false;
    }
    return onAuthenticatedSessionAvailable(
      (result as OnboardingAuthenticated).session,
    );
  }

  Future<bool> onAuthenticatedSessionAvailable(
    AuthenticatedOnboardingSession session,
  ) async {
    final userId = session.userId.trim();
    if (userId.isEmpty ||
        _lastSessionUserId == userId ||
        _state.phase == OnboardingAuthPhase.completing ||
        _state.phase == OnboardingAuthPhase.completed) {
      return false;
    }
    _lastSessionUserId = userId;
    final resolvingDraft = _state.draft.copyWith(
      currentStep: OnboardingStep.resolvingAccount,
    );
    await _persist(resolvingDraft);
    _publish(OnboardingAuthState(
      phase: OnboardingAuthPhase.resolvingAccount,
      draft: resolvingDraft,
      authenticatedUserId: userId,
    ));
    try {
      final resolution = await _accountResolution.resolve(userId);
      final isExisting =
          resolution.classification != OnboardingAccountResolution.newAccount;
      final decision = isExisting && _state.draft.habit != null
          ? PreparedHabitDecision.undecided
          : resolution.classification ==
                      OnboardingAccountResolution.newAccount &&
                  _state.draft.habit != null
              ? PreparedHabitDecision.keep
              : PreparedHabitDecision.discard;
      _publish(OnboardingAuthState(
        phase: isExisting && _state.draft.habit != null
            ? OnboardingAuthPhase.awaitingPreparedHabitDecision
            : OnboardingAuthPhase.readyToComplete,
        draft: resolvingDraft.copyWith(currentStep: OnboardingStep.auth),
        authenticatedUserId: userId,
        resolution: resolution,
        preparedHabitDecision: decision,
      ));
      return true;
    } on OnboardingAuthError catch (error) {
      _publish(OnboardingAuthState(
        phase: OnboardingAuthPhase.failure,
        draft: _state.draft,
        authenticatedUserId: userId,
        error: error,
      ));
      _lastSessionUserId = null;
      return false;
    }
  }

  void choosePreparedHabit(PreparedHabitDecision decision) {
    if (_state.phase != OnboardingAuthPhase.awaitingPreparedHabitDecision ||
        decision == PreparedHabitDecision.undecided) {
      return;
    }
    _publish(OnboardingAuthState(
      phase: OnboardingAuthPhase.readyToComplete,
      draft: _state.draft,
      authenticatedUserId: _state.authenticatedUserId,
      resolution: _state.resolution,
      preparedHabitDecision: decision,
    ));
  }

  Future<bool> complete() async {
    final retrying = _state.phase == OnboardingAuthPhase.failure &&
        _state.intent != null &&
        _state.error?.code == OnboardingAuthErrorCode.completionRetryable;
    if ((!retrying && _state.phase != OnboardingAuthPhase.readyToComplete) ||
        _state.authenticatedUserId == null ||
        _state.resolution == null) {
      return false;
    }
    final intent = _state.intent ??
        OnboardingCompletionIntent.fromDraft(
          draft: _state.draft,
          authenticatedUserId: _state.authenticatedUserId!,
          resolution: _state.resolution!,
          preparedHabitDecision: _state.preparedHabitDecision,
        );
    _publish(OnboardingAuthState(
      phase: OnboardingAuthPhase.completing,
      draft: _state.draft.copyWith(
          completionState: OnboardingCompletionState.remoteInProgress),
      authenticatedUserId: _state.authenticatedUserId,
      resolution: _state.resolution,
      preparedHabitDecision: _state.preparedHabitDecision,
      intent: intent,
    ));
    final result = await _completion.completeOnboarding(intent);
    if (result.operationId != intent.operationId ||
        result.userId != intent.authenticatedUserId) {
      _publish(OnboardingAuthState(
        phase: OnboardingAuthPhase.failure,
        draft: _state.draft,
        authenticatedUserId: _state.authenticatedUserId,
        resolution: _state.resolution,
        preparedHabitDecision: _state.preparedHabitDecision,
        intent: intent,
        error: const OnboardingAuthError(
            OnboardingAuthErrorCode.operationConflict),
      ));
      return false;
    }
    if (!result.isSuccess) {
      _publish(OnboardingAuthState(
        phase: OnboardingAuthPhase.failure,
        draft: _state.draft,
        authenticatedUserId: _state.authenticatedUserId,
        resolution: _state.resolution,
        preparedHabitDecision: _state.preparedHabitDecision,
        intent: intent,
        error: result.error ??
            OnboardingAuthError(
              result.kind == OnboardingCompletionResultKind.retryableFailure
                  ? OnboardingAuthErrorCode.completionRetryable
                  : result.kind == OnboardingCompletionResultKind.conflict
                      ? OnboardingAuthErrorCode.operationConflict
                      : OnboardingAuthErrorCode.completionFailed,
            ),
      ));
      return false;
    }
    final completed = _state.draft.copyWith(
      completionState: OnboardingCompletionState.completed,
      completedAt: DateTime.now().toUtc(),
      currentStep: OnboardingStep.finalizing,
    );
    await _draftPersistence?.clear(completed);
    _publish(OnboardingAuthState(
      phase: OnboardingAuthPhase.completed,
      draft: completed,
      authenticatedUserId: _state.authenticatedUserId,
      resolution: _state.resolution,
      preparedHabitDecision: _state.preparedHabitDecision,
      intent: intent,
    ));
    return true;
  }

  Future<void> _persist(OnboardingDraft draft) async {
    await _draftPersistence?.save(draft);
  }

  void _publish(OnboardingAuthState state) {
    _state = state;
    notifyListeners();
  }
}
