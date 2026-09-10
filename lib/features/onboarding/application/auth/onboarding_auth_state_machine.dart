import 'package:flutter/foundation.dart';

import '../../../../core/diagnostics/onboarding_runtime_trace.dart';

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

enum OnboardingAuthFailureStage {
  authentication,
  accountResolution,
  completion,
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
    this.failureStage,
    this.error,
  });

  final OnboardingAuthPhase phase;
  final OnboardingDraft draft;
  final String? authenticatedUserId;
  final OnboardingAuthRequest? pendingAuthRequest;
  final OnboardingAccountResolutionResult? resolution;
  final PreparedHabitDecision preparedHabitDecision;
  final OnboardingCompletionIntent? intent;
  final OnboardingAuthFailureStage? failureStage;
  final OnboardingAuthError? error;
}

class OnboardingAuthStateMachine extends ChangeNotifier {
  OnboardingAuthStateMachine({
    required OnboardingDraft draft,
    required OnboardingAuthPort auth,
    required OnboardingAccountResolutionService accountResolution,
    required OnboardingCompletionPort completion,
    OnboardingCompletionReconciler? reconciler,
    OnboardingAuthDraftPersistence? draftPersistence,
    Future<void> Function({
      required String operationId,
      required bool habitPresent,
    })? onCompletionHandoff,
  })  : _auth = auth,
        _accountResolution = accountResolution,
        _completion = completion,
        _reconciler = reconciler,
        _draftPersistence = draftPersistence,
        _onCompletionHandoff = onCompletionHandoff,
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
  final OnboardingCompletionReconciler? _reconciler;
  final OnboardingAuthDraftPersistence? _draftPersistence;
  final Future<void> Function({
    required String operationId,
    required bool habitPresent,
  })? _onCompletionHandoff;
  OnboardingAuthState _state;
  String? _lastSessionUserId;
  bool _resendInFlight = false;
  bool _manualCheckInFlight = false;

  OnboardingAuthState get state => _state;
  bool get resendInFlight => _resendInFlight;
  bool get manualCheckInFlight => _manualCheckInFlight;

  Future<bool> resendConfirmation() async {
    if (_resendInFlight ||
        _state.phase != OnboardingAuthPhase.awaitingEmailConfirmation) {
      return false;
    }
    final port = _auth is OnboardingEmailConfirmationPort
        ? _auth as OnboardingEmailConfirmationPort
        : null;
    if (port == null) return false;
    _resendInFlight = true;
    _trace(
        'event=resend_started op=${_shortId(_state.draft.onboardingOperationId)}');
    try {
      await port.resendConfirmation(_state.draft.authEmail ?? '');
      _trace(
          'event=resend_succeeded op=${_shortId(_state.draft.onboardingOperationId)}');
      return true;
    } on OnboardingAuthError catch (error) {
      _publish(OnboardingAuthState(
        phase: OnboardingAuthPhase.awaitingEmailConfirmation,
        draft: _state.draft,
        pendingAuthRequest: _state.pendingAuthRequest,
        failureStage: OnboardingAuthFailureStage.authentication,
        error: error,
      ));
      _trace(
          'event=resend_failed op=${_shortId(_state.draft.onboardingOperationId)} result=${error.code.name}');
      return false;
    } finally {
      _resendInFlight = false;
    }
  }

  Future<bool> checkEmailConfirmation() async {
    if (_manualCheckInFlight ||
        _state.phase != OnboardingAuthPhase.awaitingEmailConfirmation) {
      return false;
    }
    final port = _auth is OnboardingEmailConfirmationPort
        ? _auth as OnboardingEmailConfirmationPort
        : null;
    if (port == null) return false;
    _manualCheckInFlight = true;
    _trace(
        'event=manual_check_started op=${_shortId(_state.draft.onboardingOperationId)}');
    try {
      final session = await port.refreshConfirmedSession();
      if (session == null) {
        _publish(OnboardingAuthState(
          phase: OnboardingAuthPhase.awaitingEmailConfirmation,
          draft: _state.draft,
          pendingAuthRequest: _state.pendingAuthRequest,
          error: const OnboardingAuthError(
              OnboardingAuthErrorCode.confirmationNotDetected),
        ));
        _trace(
            'event=still_unconfirmed op=${_shortId(_state.draft.onboardingOperationId)} result=none');
        return false;
      }
      _trace(
          'event=session_detected op=${_shortId(_state.draft.onboardingOperationId)} hasSession=true');
      return onAuthenticatedSessionAvailable(session);
    } on OnboardingAuthError catch (error) {
      _publish(OnboardingAuthState(
        phase: OnboardingAuthPhase.awaitingEmailConfirmation,
        draft: _state.draft,
        pendingAuthRequest: _state.pendingAuthRequest,
        error: error,
      ));
      return false;
    } finally {
      _manualCheckInFlight = false;
    }
  }

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
    final hasFrozenCompletionIntent = _state.draft.completionState ==
        OnboardingCompletionState.remoteInProgress;
    final pendingDraft = _state.draft.copyWith(
      authIntent: command == OnboardingAuthCommand.signUpWithEmail
          ? AuthIntent.signUp
          : AuthIntent.signIn,
      completionState: hasFrozenCompletionIntent
          ? OnboardingCompletionState.remoteInProgress
          : OnboardingCompletionState.authPending,
      currentStep: OnboardingStep.auth,
      authEmail: email.trim(),
    );
    _trace(
      'event=auth_start op=${_shortId(pendingDraft.onboardingOperationId)} '
      'authAction=${command == OnboardingAuthCommand.signUpWithEmail ? 'signup' : 'login'} '
      'stateFrom=${_state.phase.name} stateTo=${OnboardingAuthPhase.authenticating.name}',
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
    _trace(
      'event=auth_result op=${_shortId(pendingDraft.onboardingOperationId)} '
      'result=${result.runtimeType}',
    );
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
      if (result.error.code == OnboardingAuthErrorCode.providerCancelled) {
        _publish(OnboardingAuthState(phase: OnboardingAuthPhase.ready, draft: _state.draft));
        return true;
      }
      _publish(OnboardingAuthState(
        phase: OnboardingAuthPhase.failure,
        draft: pendingDraft,
        failureStage: OnboardingAuthFailureStage.authentication,
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
    final boundUserId = _state.authenticatedUserId?.trim();
    if (boundUserId != null &&
        boundUserId.isNotEmpty &&
        boundUserId != userId) {
      _trace(
        'event=cross_user_rejected op=${_shortId(_state.draft.onboardingOperationId)} '
        'boundUser=${_shortId(boundUserId)} incomingUser=${_shortId(userId)}',
      );
      return false;
    }
    final draftBoundUserId = _state.draft.boundUserId?.trim();
    if (draftBoundUserId != null &&
        draftBoundUserId.isNotEmpty &&
        draftBoundUserId != userId) {
      _trace(
        'event=cross_user_rejected op=${_shortId(_state.draft.onboardingOperationId)} '
        'boundUser=${_shortId(draftBoundUserId)} incomingUser=${_shortId(userId)}',
      );
      return false;
    }
    if (userId.isEmpty ||
        _lastSessionUserId == userId ||
        _state.phase == OnboardingAuthPhase.completing ||
        _state.phase == OnboardingAuthPhase.completed) {
      return false;
    }
    _lastSessionUserId = userId;
    _trace(
      'event=session_available op=${_shortId(_state.draft.onboardingOperationId)} '
      'user=${_shortId(userId)} stateFrom=${_state.phase.name} '
      'stateTo=${OnboardingAuthPhase.resolvingAccount.name}',
    );
    final recoveryDraft = _adoptLegacyRecoveryEnvelope(
      draft: _state.draft,
      userId: userId,
    );
    final resolvingDraft = recoveryDraft.copyWith(
      currentStep: OnboardingStep.resolvingAccount,
    );
    await _persist(resolvingDraft);
    _publish(OnboardingAuthState(
      phase: OnboardingAuthPhase.resolvingAccount,
      draft: resolvingDraft,
      authenticatedUserId: userId,
    ));
    try {
      final recoveryIntent = _recoveryIntentIfAvailable(
        draft: resolvingDraft,
        userId: userId,
      );
      if (recoveryIntent != null) {
        _trace(
          'event=recovery_intent_restored '
          'op=${_shortId(recoveryIntent.operationId)} '
          'boundUser=${_shortId(recoveryIntent.authenticatedUserId)} '
          'frozenResolution=${recoveryIntent.accountResolution.name} '
          'frozenDecision=${recoveryIntent.preparedHabitDecision.name}',
        );
      }
      final resolution = await _accountResolution.resolve(userId);
      _trace(
        'event=account_resolved op=${_shortId(resolvingDraft.onboardingOperationId)} '
        'user=${_shortId(userId)} '
        'remoteResolution=${resolution.classification.name}',
      );
      if (recoveryIntent != null) {
        final recoveryDecision = recoveryIntent.preparedHabitDecision;
        _publish(OnboardingAuthState(
          phase: OnboardingAuthPhase.readyToComplete,
          draft: resolvingDraft.copyWith(currentStep: OnboardingStep.auth),
          authenticatedUserId: userId,
          resolution: resolution,
          preparedHabitDecision: recoveryDecision,
          intent: recoveryIntent,
        ));
        _trace(
          'event=recovery_replay_start '
          'op=${_shortId(recoveryIntent.operationId)} '
          'user=${_shortId(userId)}',
        );
        await complete();
        return true;
      }
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
      _trace(
        'event=ready_for_completion op=${_shortId(resolvingDraft.onboardingOperationId)} '
        'resolution=${resolution.classification.name} '
        'completionInvoked=false',
      );
      return true;
    } on OnboardingAuthError catch (error) {
      _publish(OnboardingAuthState(
        phase: OnboardingAuthPhase.failure,
        draft: _state.draft,
        authenticatedUserId: userId,
        failureStage: OnboardingAuthFailureStage.accountResolution,
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
    // Recovery owns the payload. The remote account resolution above is only
    // validation; it must never replace the frozen intent restored from the
    // persisted envelope.
    final frozenRecoveryIntent = _state.intent;
    final intent = frozenRecoveryIntent ??
        OnboardingCompletionIntent.fromDraft(
          draft: _state.draft,
          authenticatedUserId: _state.authenticatedUserId!,
          resolution: _state.resolution!,
          preparedHabitDecision: _state.preparedHabitDecision,
        );
    final handoffRunId = OnboardingRuntimeTrace.activeHandoffRunId;
    _trace(
      'event=completion_payload_built '
      'op=${_shortId(intent.operationId)} '
      'source=${frozenRecoveryIntent != null ? 'frozenRecovery' : 'fresh'} '
      'resolution=${intent.accountResolution.name} '
      'decision=${intent.preparedHabitDecision.name}',
    );
    final pendingDraft = _state.draft.copyWith(
      completionState: OnboardingCompletionState.remoteInProgress,
      completionAccountResolutionCode: intent.accountResolution.name,
      completionPreparedHabitDecisionCode: intent.preparedHabitDecision.name,
      boundUserId: _state.authenticatedUserId,
      currentStep: OnboardingStep.auth,
    );
    _publish(OnboardingAuthState(
      phase: OnboardingAuthPhase.completing,
      draft: pendingDraft,
      authenticatedUserId: _state.authenticatedUserId,
      resolution: _state.resolution,
      preparedHabitDecision: _state.preparedHabitDecision,
      intent: intent,
    ));
    _trace(
      'event=completion_invoked op=${_shortId(intent.operationId)} '
      'user=${_shortId(intent.authenticatedUserId)} '
      'resolution=${intent.accountResolution.name} completionInvoked=true',
    );
    try {
      await _persist(pendingDraft);
    } catch (error) {
      _trace(
        'event=completion_failed op=${_shortId(intent.operationId)} '
        'user=${_shortId(intent.authenticatedUserId)} error=${error.runtimeType} '
        'retryable=true stage=completion_persist',
      );
      _publish(OnboardingAuthState(
        phase: OnboardingAuthPhase.failure,
        draft: pendingDraft,
        authenticatedUserId: _state.authenticatedUserId,
        resolution: _state.resolution,
        preparedHabitDecision: _state.preparedHabitDecision,
        intent: intent,
        failureStage: OnboardingAuthFailureStage.completion,
        error: OnboardingAuthError(
          OnboardingAuthErrorCode.completionRetryable,
          cause: error,
        ),
      ));
      return false;
    }
    late final OnboardingCompletionResult result;
    try {
      result = await _completion.completeOnboarding(intent);
    } catch (error) {
      _trace(
        'event=completion_failed op=${_shortId(intent.operationId)} '
        'user=${_shortId(intent.authenticatedUserId)} error=${error.runtimeType} '
        'retryable=true stage=completion',
      );
      final retryable = const OnboardingAuthError(
        OnboardingAuthErrorCode.completionRetryable,
      );
      _publish(OnboardingAuthState(
        phase: OnboardingAuthPhase.failure,
        draft: _state.draft,
        authenticatedUserId: _state.authenticatedUserId,
        resolution: _state.resolution,
        preparedHabitDecision: _state.preparedHabitDecision,
        intent: intent,
        failureStage: OnboardingAuthFailureStage.completion,
        error: OnboardingAuthError(retryable.code, cause: error),
      ));
      return false;
    }
    if (result.operationId != intent.operationId ||
        result.userId != intent.authenticatedUserId) {
      _trace(
        'event=completion_failed op=${_shortId(intent.operationId)} '
        'user=${_shortId(intent.authenticatedUserId)} error=operationConflict '
        'retryable=false stage=completion',
      );
      _publish(OnboardingAuthState(
        phase: OnboardingAuthPhase.failure,
        draft: _state.draft,
        authenticatedUserId: _state.authenticatedUserId,
        resolution: _state.resolution,
        preparedHabitDecision: _state.preparedHabitDecision,
        intent: intent,
        failureStage: OnboardingAuthFailureStage.completion,
        error: const OnboardingAuthError(
            OnboardingAuthErrorCode.operationConflict),
      ));
      return false;
    }
    if (!result.isSuccess) {
      final failure = result.error ??
          OnboardingAuthError(
            result.kind == OnboardingCompletionResultKind.retryableFailure
                ? OnboardingAuthErrorCode.completionRetryable
                : result.kind == OnboardingCompletionResultKind.conflict
                    ? OnboardingAuthErrorCode.operationConflict
                    : OnboardingAuthErrorCode.completionFailed,
          );
      _trace(
        'event=completion_failed op=${_shortId(intent.operationId)} '
        'user=${_shortId(intent.authenticatedUserId)} error=${failure.code.name} '
        'retryable=${result.kind == OnboardingCompletionResultKind.retryableFailure} '
        'stage=completion',
      );
      _publish(OnboardingAuthState(
        phase: OnboardingAuthPhase.failure,
        draft: _state.draft,
        authenticatedUserId: _state.authenticatedUserId,
        resolution: _state.resolution,
        preparedHabitDecision: _state.preparedHabitDecision,
        intent: intent,
        failureStage: OnboardingAuthFailureStage.completion,
        error: failure,
      ));
      return false;
    }
    OnboardingRuntimeTrace.log(
      'ONBOARDING_HANDOFF',
      'event=remote_completion_success operationId=${_shortId(intent.operationId)} '
          'userId=${_shortId(intent.authenticatedUserId)} draftPresent=true',
      handoffRunId: handoffRunId,
    );
    try {
      OnboardingRuntimeTrace.log(
        'ONBOARDING_HANDOFF',
        'event=reconcile_start operationId=${_shortId(intent.operationId)} '
            'userId=${_shortId(intent.authenticatedUserId)} draftPresent=true',
        handoffRunId: handoffRunId,
      );
      await _reconciler?.reconcile(intent: intent, result: result);
      OnboardingRuntimeTrace.log(
        'ONBOARDING_HANDOFF',
        'event=reconcile_done operationId=${_shortId(intent.operationId)} '
            'userId=${_shortId(intent.authenticatedUserId)} draftPresent=true',
        handoffRunId: handoffRunId,
      );
    } catch (error) {
      _trace(
        'event=completion_failed op=${_shortId(intent.operationId)} '
        'user=${_shortId(intent.authenticatedUserId)} error=${error.runtimeType} '
        'retryable=true stage=completion_reconcile',
      );
      _publish(OnboardingAuthState(
        phase: OnboardingAuthPhase.failure,
        draft: _state.draft,
        authenticatedUserId: _state.authenticatedUserId,
        resolution: _state.resolution,
        preparedHabitDecision: _state.preparedHabitDecision,
        intent: intent,
        failureStage: OnboardingAuthFailureStage.completion,
        error: OnboardingAuthError(
          OnboardingAuthErrorCode.completionRetryable,
          cause: error,
        ),
      ));
      return false;
    }
    _trace(
      'event=completion_reconcile_success op=${_shortId(intent.operationId)} '
      'user=${_shortId(intent.authenticatedUserId)}',
    );
    _handoffTrace(
      'cleanup_finished',
      operationId: intent.operationId,
      draftPresent: true,
    );
    final completed = pendingDraft.copyWith(
      completionState: OnboardingCompletionState.completed,
      completedAt: DateTime.now().toUtc(),
      currentStep: OnboardingStep.finalizing,
    );
    try {
      _trace(
        'event=draft_clear_start op=${_shortId(intent.operationId)} '
        'user=${_shortId(intent.authenticatedUserId)} '
        'habitPresent=${result.preparedHabitApplied}',
      );
      await _draftPersistence?.clear(pendingDraft);
      OnboardingRuntimeTrace.log(
        'ONBOARDING_HANDOFF',
        'event=draft_clear_done operationId=${_shortId(intent.operationId)} '
            'userId=${_shortId(intent.authenticatedUserId)} draftPresent=false',
        handoffRunId: handoffRunId,
      );
      _trace(
        'event=draft_clear_success op=${_shortId(intent.operationId)} '
        'user=${_shortId(intent.authenticatedUserId)} '
        'habitPresent=${result.preparedHabitApplied}',
      );
      _handoffTrace(
        'draft_cleared',
        operationId: intent.operationId,
        draftPresent: false,
      );
    } catch (error) {
      _trace(
        'event=error op=${_shortId(intent.operationId)} '
        'user=${_shortId(intent.authenticatedUserId)} error=${error.runtimeType} '
        'stage=draft_clear',
      );
      _publish(OnboardingAuthState(
        phase: OnboardingAuthPhase.failure,
        draft: pendingDraft,
        authenticatedUserId: _state.authenticatedUserId,
        resolution: _state.resolution,
        preparedHabitDecision: _state.preparedHabitDecision,
        intent: intent,
        failureStage: OnboardingAuthFailureStage.completion,
        error: OnboardingAuthError(
          OnboardingAuthErrorCode.completionRetryable,
          cause: error,
        ),
      ));
      return false;
    }
    _publish(OnboardingAuthState(
      phase: OnboardingAuthPhase.completed,
      draft: completed,
      authenticatedUserId: _state.authenticatedUserId,
      resolution: _state.resolution,
      preparedHabitDecision: _state.preparedHabitDecision,
      intent: intent,
    ));
    _trace(
      'event=completion_succeeded op=${_shortId(intent.operationId)} '
      'stateTo=${OnboardingAuthPhase.completed.name}',
    );
    try {
      OnboardingRuntimeTrace.log(
        'ONBOARDING_HANDOFF',
        'event=handoff_callback_start operationId=${_shortId(intent.operationId)} '
            'userId=${_shortId(intent.authenticatedUserId)} draftPresent=false',
        handoffRunId: handoffRunId,
      );
      await _onCompletionHandoff?.call(
        operationId: intent.operationId,
        habitPresent: result.preparedHabitApplied,
      );
    } catch (error) {
      _trace(
        'event=error op=${_shortId(intent.operationId)} '
        'user=${_shortId(intent.authenticatedUserId)} error=${error.runtimeType} '
        'stage=handoff',
      );
    }
    return true;
  }

  Future<void> _persist(OnboardingDraft draft) async {
    await _draftPersistence?.save(draft);
  }

  OnboardingDraft _adoptLegacyRecoveryEnvelope({
    required OnboardingDraft draft,
    required String userId,
  }) {
    if (draft.completionState != OnboardingCompletionState.remoteInProgress ||
        draft.boundUserId?.trim().isNotEmpty == true) {
      return draft;
    }
    _trace(
      'event=recovery_envelope_bound '
      'op=${_shortId(draft.onboardingOperationId)} '
      'user=${_shortId(userId)}',
    );
    return draft.copyWith(boundUserId: userId);
  }

  OnboardingCompletionIntent? _recoveryIntentIfAvailable({
    required OnboardingDraft draft,
    required String userId,
  }) {
    if (draft.completionState != OnboardingCompletionState.remoteInProgress) {
      return null;
    }
    return OnboardingCompletionIntent.fromPersistedRecovery(
      draft: draft,
      authenticatedUserId: userId,
    );
  }

  void _publish(OnboardingAuthState state) {
    if (_state.phase != state.phase) {
      _trace(
        'event=state_transition op=${_shortId(state.draft.onboardingOperationId)} '
        'stateFrom=${_state.phase.name} stateTo=${state.phase.name}',
      );
    }
    _state = state;
    notifyListeners();
  }

  static String _shortId(String value) =>
      value.length <= 8 ? value : value.substring(0, 8);

  static void _trace(String message) {
    if (kDebugMode) debugPrint('[ONBOARDING_AUTH] $message');
  }

  static void _handoffTrace(
    String event, {
    required String operationId,
    required bool draftPresent,
  }) {
    if (!kDebugMode) return;
    debugPrint(
      '[ONBOARDING_HANDOFF] event=$event '
      'operationId=${_shortId(operationId)} '
      'draftPresent=$draftPresent',
    );
  }
}
