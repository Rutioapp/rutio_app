import 'package:flutter/foundation.dart';

import '../domain/models/onboarding_draft.dart';
import '../domain/models/onboarding_types.dart';
import '../domain/onboarding_draft_store.dart';
import '../domain/onboarding_validation.dart';
import 'onboarding_draft_service.dart';

enum OnboardingCoordinatorStatus {
  loading,
  ready,
  persisting,
  recoverableError,
}

enum OnboardingCoordinatorErrorType {
  persistence,
  recovery,
  invalidDraft,
  completedDraft,
}

@immutable
class OnboardingCoordinatorError {
  const OnboardingCoordinatorError({required this.type, this.cause});

  final OnboardingCoordinatorErrorType type;
  final Object? cause;
}

@immutable
class OnboardingCoordinatorState {
  const OnboardingCoordinatorState({
    required this.status,
    this.draft,
    this.effectiveStep,
    this.isAtWelcome = true,
    this.error,
    this.validation,
  });

  final OnboardingCoordinatorStatus status;
  final OnboardingDraft? draft;
  final OnboardingStep? effectiveStep;
  final bool isAtWelcome;
  final OnboardingCoordinatorError? error;
  final OnboardingValidationResult? validation;

  bool get isLoading => status == OnboardingCoordinatorStatus.loading;
  bool get isPersisting => status == OnboardingCoordinatorStatus.persisting;
  bool get isRecoverableError =>
      status == OnboardingCoordinatorStatus.recoverableError;
  bool get hasDraft => draft != null;
  bool get canGoBack => draft != null && !isAtWelcome && effectiveStep != null;
  bool get canAdvance =>
      draft != null &&
      !isAtWelcome &&
      effectiveStep != null &&
      effectiveStep != OnboardingStep.preview &&
      !isPersisting;

  double get progress {
    if (isAtWelcome || effectiveStep == null) return 0;
    return (OnboardingCoordinator.internalSteps.indexOf(effectiveStep!) + 1) /
        OnboardingCoordinator.internalSteps.length;
  }

  OnboardingCoordinatorState copyWith({
    OnboardingCoordinatorStatus? status,
    Object? draft = _unset,
    Object? effectiveStep = _unset,
    bool? isAtWelcome,
    Object? error = _unset,
    Object? validation = _unset,
  }) {
    return OnboardingCoordinatorState(
      status: status ?? this.status,
      draft: identical(draft, _unset) ? this.draft : draft as OnboardingDraft?,
      effectiveStep: identical(effectiveStep, _unset)
          ? this.effectiveStep
          : effectiveStep as OnboardingStep?,
      isAtWelcome: isAtWelcome ?? this.isAtWelcome,
      error: identical(error, _unset)
          ? this.error
          : error as OnboardingCoordinatorError?,
      validation: identical(validation, _unset)
          ? this.validation
          : validation as OnboardingValidationResult?,
    );
  }

  static const Object _unset = Object();
}

/// The single authority for the anonymous onboarding flow.
///
/// Presentation emits intents to this class. It owns recovery, step guards,
/// persistence ordering and the run epoch used to ignore stale async results.
class OnboardingCoordinator extends ChangeNotifier {
  OnboardingCoordinator({required OnboardingDraftService draftService})
      : _draftService = draftService;

  static const List<OnboardingStep> internalSteps = <OnboardingStep>[
    OnboardingStep.name,
    OnboardingStep.goals,
    OnboardingStep.pace,
    OnboardingStep.recommendations,
    OnboardingStep.habit,
    OnboardingStep.reminder,
    OnboardingStep.preview,
  ];

  final OnboardingDraftService _draftService;
  OnboardingCoordinatorState _state = const OnboardingCoordinatorState(
    status: OnboardingCoordinatorStatus.loading,
  );
  int _runEpoch = 0;
  int? _scopeEpoch;

  OnboardingCoordinatorState get state => _state;
  OnboardingDraft? get draft => _state.draft;
  OnboardingStep? get effectiveStep => _state.effectiveStep;
  int? get scopeEpoch => _scopeEpoch;

  /// Loads the draft without taking the user past Welcome automatically.
  /// This keeps Welcome as the product decision point on cold start.
  Future<void> resume() async {
    final epoch = _beginOperation();
    _publish(_state.copyWith(
      status: OnboardingCoordinatorStatus.loading,
      error: null,
      validation: null,
    ));
    try {
      final result = await _draftService.loadAnonymousDraftResult();
      if (!_isCurrent(epoch)) return;

      if (result.draft == null) {
        if (result.status == OnboardingDraftLoadStatus.missing) {
          _publish(const OnboardingCoordinatorState(
            status: OnboardingCoordinatorStatus.ready,
          ));
        } else {
          _publish(OnboardingCoordinatorState(
            status: OnboardingCoordinatorStatus.recoverableError,
            error: OnboardingCoordinatorError(
              type: OnboardingCoordinatorErrorType.recovery,
              cause: result.message,
            ),
          ));
        }
        return;
      }

      final loaded = result.draft!;
      if (!loaded.isResumable) {
        _publish(const OnboardingCoordinatorState(
          status: OnboardingCoordinatorStatus.ready,
        ));
        return;
      }

      final safeStep = effectiveStepFor(loaded);
      _publish(OnboardingCoordinatorState(
        status: OnboardingCoordinatorStatus.ready,
        draft: loaded.copyWith(currentStep: safeStep),
        effectiveStep: safeStep,
      ));
    } catch (error) {
      if (!_isCurrent(epoch)) return;
      _publish(OnboardingCoordinatorState(
        status: OnboardingCoordinatorStatus.recoverableError,
        error: OnboardingCoordinatorError(
          type: OnboardingCoordinatorErrorType.recovery,
          cause: error,
        ),
      ));
    }
  }

  Future<void> startNew() async {
    final epoch = _beginOperation();
    _publish(_state.copyWith(
      status: OnboardingCoordinatorStatus.persisting,
      error: null,
      validation: null,
    ));
    try {
      final created = await _draftService.createNew();
      if (!_isCurrent(epoch)) return;
      _publish(OnboardingCoordinatorState(
        status: OnboardingCoordinatorStatus.ready,
        draft: created,
        effectiveStep: OnboardingStep.name,
        isAtWelcome: false,
      ));
    } catch (error) {
      if (!_isCurrent(epoch)) return;
      _publish(OnboardingCoordinatorState(
        status: OnboardingCoordinatorStatus.recoverableError,
        draft: _state.draft,
        effectiveStep: _state.effectiveStep,
        isAtWelcome: true,
        error: OnboardingCoordinatorError(
          type: OnboardingCoordinatorErrorType.persistence,
          cause: error,
        ),
      ));
    }
  }

  /// Enters the already loaded draft from Welcome. No persistence is needed.
  void continueDraft() {
    final current = _state.draft;
    if (current == null || current.isCompleted) return;
    _publish(_state.copyWith(
      status: OnboardingCoordinatorStatus.ready,
      isAtWelcome: false,
      effectiveStep: effectiveStepFor(current),
      error: null,
      validation: null,
    ));
  }

  Future<void> restart() async {
    final epoch = _beginOperation();
    _publish(_state.copyWith(
      status: OnboardingCoordinatorStatus.persisting,
      error: null,
      validation: null,
    ));
    try {
      final created = await _draftService.restart();
      if (!_isCurrent(epoch)) return;
      _publish(OnboardingCoordinatorState(
        status: OnboardingCoordinatorStatus.ready,
        draft: created,
        effectiveStep: OnboardingStep.name,
        isAtWelcome: false,
      ));
    } catch (error) {
      if (!_isCurrent(epoch)) return;
      _publish(OnboardingCoordinatorState(
        status: OnboardingCoordinatorStatus.recoverableError,
        draft: _state.draft,
        effectiveStep: _state.effectiveStep,
        isAtWelcome: true,
        error: OnboardingCoordinatorError(
          type: OnboardingCoordinatorErrorType.persistence,
          cause: error,
        ),
      ));
    }
  }

  Future<bool> goBack() async {
    final current = _state.draft;
    final step = _state.effectiveStep;
    if (current == null || step == null || _state.isAtWelcome) return false;
    final index = internalSteps.indexOf(step);
    if (index <= 0) {
      _publish(_state.copyWith(
        status: OnboardingCoordinatorStatus.ready,
        isAtWelcome: true,
        error: null,
        validation: null,
      ));
      return true;
    }

    return _persistStep(current, internalSteps[index - 1], _beginOperation());
  }

  /// Persists a candidate draft, validates the current step through Domain,
  /// then publishes the next step. The candidate must keep the current draft
  /// identities; the coordinator never creates replacement IDs while moving.
  Future<bool> submitCurrentStep({OnboardingDraft? candidate}) async {
    final current = _state.draft;
    final step = _state.effectiveStep;
    if (current == null || step == null || _state.isAtWelcome) return false;
    final next = candidate ?? current;
    if (next.draftId != current.draftId ||
        next.onboardingOperationId != current.onboardingOperationId) {
      _publish(_state.copyWith(
        status: OnboardingCoordinatorStatus.recoverableError,
        error: const OnboardingCoordinatorError(
          type: OnboardingCoordinatorErrorType.invalidDraft,
        ),
      ));
      return false;
    }
    final validation = _validateCandidate(next, step);
    if (!validation.isValid) {
      _publish(_state.copyWith(
        status: OnboardingCoordinatorStatus.ready,
        validation: validation,
      ));
      return false;
    }
    final index = internalSteps.indexOf(step);
    if (index < 0 || index == internalSteps.length - 1) return false;
    return _persistStep(next, internalSteps[index + 1], _beginOperation());
  }

  /// Commits the real Name step. Normalization and all business validation
  /// remain in Domain; the widget only supplies the edited text.
  Future<bool> submitName(String value) async {
    final current = _state.draft;
    if (current == null ||
        _state.isAtWelcome ||
        _state.effectiveStep != OnboardingStep.name) {
      return false;
    }
    final candidate = current.copyWith(firstName: value.trim());
    final validation = OnboardingDraftValidator.validateFirstName(
      candidate.firstName,
    );
    if (!validation.isValid) {
      _publish(_state.copyWith(
        status: OnboardingCoordinatorStatus.ready,
        validation: validation,
        error: null,
      ));
      return false;
    }
    return _persistStep(candidate, OnboardingStep.goals, _beginOperation());
  }

  /// Commits the locally edited Goals selection and advances only after it is
  /// persisted. The catalog and quantity rules remain in Domain.
  Future<bool> submitGoals(Set<String> goalCodes) async {
    final current = _state.draft;
    if (current == null ||
        _state.isAtWelcome ||
        _state.effectiveStep != OnboardingStep.goals) {
      return false;
    }
    final candidate = current.copyWith(goalCodes: goalCodes);
    final validation = OnboardingDraftValidator.validateGoalCodes(
      candidate.goalCodes,
    );
    if (!validation.isValid) {
      _publish(_state.copyWith(
        status: OnboardingCoordinatorStatus.ready,
        validation: validation,
        error: null,
      ));
      return false;
    }
    return _persistStep(candidate, OnboardingStep.pace, _beginOperation());
  }

  /// Commits the selected initial pace and advances only after persistence.
  Future<bool> submitPace(OnboardingPace pace) async {
    final current = _state.draft;
    if (current == null ||
        _state.isAtWelcome ||
        _state.effectiveStep != OnboardingStep.pace) {
      return false;
    }
    final candidate = current.copyWith(pace: pace);
    final validation = OnboardingDraftValidator.validatePace(candidate.pace);
    if (!validation.isValid) {
      _publish(_state.copyWith(
        status: OnboardingCoordinatorStatus.ready,
        validation: validation,
        error: null,
      ));
      return false;
    }
    return _persistStep(
      candidate,
      OnboardingStep.recommendations,
      _beginOperation(),
    );
  }

  /// Temporary shell-only data source. It is deliberately outside Domain and
  /// contains no production flags; remove it when real step presenters land.
  Future<bool> submitPlaceholderStep() {
    final current = _state.draft;
    final step = _state.effectiveStep;
    if (current == null || step == null) return Future<bool>.value(false);
    var candidate = current;
    switch (step) {
      case OnboardingStep.recommendations:
        candidate = current.copyWith(selectedRecommendationId: 'placeholder');
      case OnboardingStep.habit:
        candidate = current.copyWith(habit: <String, dynamic>{
          'id': 'placeholder-habit',
          'type': 'check',
          'schedule': <String, dynamic>{'type': 'daily'},
        });
      case OnboardingStep.reminder:
        candidate = current.copyWith(reminder: <String, dynamic>{
          'permissionState': ReminderPermissionState.notRequested.code,
        });
      case OnboardingStep.preview:
        return Future<bool>.value(false);
      default:
        // Name and non-placeholder terminal steps have no fake data path.
        return Future<bool>.value(false);
    }
    return submitCurrentStep(candidate: candidate);
  }

  /// Invalidates pending results for logout, scope switches and restart.
  void invalidateAsyncOperations({int? scopeEpoch}) {
    _runEpoch++;
    _scopeEpoch = scopeEpoch;
  }

  /// Computes the first step that is safe to show, clamped by the persisted
  /// cursor. Thus an advanced cursor can never bypass an invalid prerequisite.
  OnboardingStep effectiveStepFor(OnboardingDraft draft) {
    final safe = OnboardingDraftValidator.lastSafeStep(draft);
    final firstInvalidIndex = safe == null
        ? 0
        : (internalSteps.indexOf(safe) + 1).clamp(0, internalSteps.length - 1);
    final persistedIndex = internalSteps.indexOf(draft.currentStep);
    final requestedIndex =
        persistedIndex < 0 ? internalSteps.length - 1 : persistedIndex;
    return internalSteps[requestedIndex < firstInvalidIndex
        ? requestedIndex
        : firstInvalidIndex];
  }

  @override
  void dispose() {
    invalidateAsyncOperations();
    super.dispose();
  }

  Future<bool> _persistStep(
    OnboardingDraft candidate,
    OnboardingStep step,
    int epoch,
  ) async {
    final persisted = candidate.copyWith(currentStep: step);
    _publish(_state.copyWith(
      status: OnboardingCoordinatorStatus.persisting,
      error: null,
      validation: null,
    ));
    try {
      await _draftService.saveAnonymousDraft(persisted);
      if (!_isCurrent(epoch)) return false;
      _publish(OnboardingCoordinatorState(
        status: OnboardingCoordinatorStatus.ready,
        draft: persisted,
        effectiveStep: step,
        isAtWelcome: false,
      ));
      return true;
    } catch (error) {
      if (!_isCurrent(epoch)) return false;
      _publish(_state.copyWith(
        status: OnboardingCoordinatorStatus.recoverableError,
        error: OnboardingCoordinatorError(
          type: OnboardingCoordinatorErrorType.persistence,
          cause: error,
        ),
      ));
      return false;
    }
  }

  OnboardingValidationResult _validateCandidate(
    OnboardingDraft candidate,
    OnboardingStep step,
  ) {
    switch (step) {
      case OnboardingStep.name:
        return OnboardingDraftValidator.validateFirstName(candidate.firstName);
      case OnboardingStep.goals:
        return OnboardingDraftValidator.validateGoalCodes(candidate.goalCodes);
      case OnboardingStep.pace:
        return OnboardingDraftValidator.validatePace(candidate.pace);
      case OnboardingStep.recommendations:
        return candidate.selectedRecommendationId == null
            ? const OnboardingValidationResult(<OnboardingValidationIssue>[
                OnboardingValidationIssue(
                  OnboardingValidationCode.required,
                  'Recommendation is required.',
                ),
              ])
            : const OnboardingValidationResult.valid();
      case OnboardingStep.habit:
        return candidate.habit == null || candidate.habit!.isEmpty
            ? const OnboardingValidationResult(<OnboardingValidationIssue>[
                OnboardingValidationIssue(
                  OnboardingValidationCode.required,
                  'Habit is required.',
                ),
              ])
            : const OnboardingValidationResult.valid();
      case OnboardingStep.reminder:
        return candidate.reminder == null
            ? const OnboardingValidationResult(<OnboardingValidationIssue>[
                OnboardingValidationIssue(
                  OnboardingValidationCode.required,
                  'Reminder is required.',
                ),
              ])
            : const OnboardingValidationResult.valid();
      case OnboardingStep.preview:
      case OnboardingStep.auth:
      case OnboardingStep.emailConfirmation:
      case OnboardingStep.resolvingAccount:
      case OnboardingStep.finalizing:
        return const OnboardingValidationResult.valid();
    }
  }

  int _beginOperation() {
    _runEpoch++;
    return _runEpoch;
  }

  bool _isCurrent(int epoch) => epoch == _runEpoch;

  void _publish(OnboardingCoordinatorState state) {
    _state = state;
    if (hasListeners) notifyListeners();
  }
}
