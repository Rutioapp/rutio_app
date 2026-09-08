import 'package:flutter/foundation.dart';

import '../data/bundled_recommendation_catalog_repository.dart';
import '../data/onboarding_habit_draft_adapter.dart';
import '../data/onboarding_reminder_draft_adapter.dart';
import '../data/recommendation_catalog_repository.dart';
import '../domain/models/onboarding_draft.dart';
import '../domain/models/onboarding_habit_configuration.dart';
import '../domain/models/onboarding_recommendation.dart';
import '../domain/models/onboarding_reminder_configuration.dart';
import '../domain/models/onboarding_types.dart';
import '../domain/onboarding_draft_store.dart';
import '../domain/onboarding_habit_configuration_validator.dart';
import '../domain/onboarding_reminder_configuration_validator.dart';
import '../domain/onboarding_recommendation_catalog_validator.dart';
import '../domain/onboarding_recommendation_ranking.dart';
import '../domain/onboarding_validation.dart';
import 'onboarding_draft_service.dart';
import 'onboarding_reminder_permission_gateway.dart';

enum OnboardingCoordinatorStatus {
  loading,
  ready,
  persisting,
  refreshing,
  recoverableError,
}

enum OnboardingCoordinatorErrorType {
  persistence,
  recovery,
  invalidDraft,
  completedDraft,
  catalog,
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
    this.recommendations,
  });

  final OnboardingCoordinatorStatus status;
  final OnboardingDraft? draft;
  final OnboardingStep? effectiveStep;
  final bool isAtWelcome;
  final OnboardingCoordinatorError? error;
  final OnboardingValidationResult? validation;
  final List<OnboardingRecommendation>? recommendations;

  bool get isLoading => status == OnboardingCoordinatorStatus.loading;
  bool get isPersisting => status == OnboardingCoordinatorStatus.persisting;
  bool get isRefreshing => status == OnboardingCoordinatorStatus.refreshing;
  bool get isRecoverableError =>
      status == OnboardingCoordinatorStatus.recoverableError;
  bool get hasDraft => draft != null;
  bool get canGoBack => draft != null && !isAtWelcome && effectiveStep != null;
  bool get canAdvance =>
      draft != null &&
      !isAtWelcome &&
      effectiveStep != null &&
      effectiveStep != OnboardingStep.preview &&
      !isPersisting &&
      !isRefreshing &&
      !isLoading;

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
    Object? recommendations = _unset,
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
      recommendations: identical(recommendations, _unset)
          ? this.recommendations
          : recommendations as List<OnboardingRecommendation>?,
    );
  }

  static const Object _unset = Object();
}

/// The single authority for the anonymous onboarding flow.
///
/// Presentation emits intents to this class. It owns recovery, step guards,
/// persistence ordering and the run epoch used to ignore stale async results.
class OnboardingCoordinator extends ChangeNotifier {
  OnboardingCoordinator({
    required OnboardingDraftService draftService,
    RecommendationCatalogRepository? catalogRepository,
    OnboardingRecommendationRankingService? rankingService,
    OnboardingReminderPermissionGateway? reminderPermissionGateway,
  })  : _draftService = draftService,
        _catalogRepository =
            catalogRepository ?? const BundledRecommendationCatalogRepository(),
        _rankingService =
            rankingService ?? const OnboardingRecommendationRankingService(),
        _reminderPermissionGateway = reminderPermissionGateway ??
            AppOnboardingReminderPermissionGateway();

  static const List<OnboardingStep> internalSteps = <OnboardingStep>[
    OnboardingStep.name,
    OnboardingStep.goals,
    OnboardingStep.pace,
    OnboardingStep.recommendations,
    OnboardingStep.habit,
    OnboardingStep.reminder,
    OnboardingStep.preview,
    OnboardingStep.auth,
    OnboardingStep.emailConfirmation,
    OnboardingStep.resolvingAccount,
  ];

  final OnboardingDraftService _draftService;
  final RecommendationCatalogRepository _catalogRepository;
  final OnboardingRecommendationRankingService _rankingService;
  final OnboardingReminderPermissionGateway _reminderPermissionGateway;
  OnboardingRecommendationCatalogSnapshot? _catalogSnapshot;
  OnboardingCoordinatorState _state = const OnboardingCoordinatorState(
    status: OnboardingCoordinatorStatus.loading,
  );
  int _runEpoch = 0;
  int? _scopeEpoch;
  bool _reminderSubmitInFlight = false;
  bool _returnToPreviewAfterEdit = false;
  _PendingReminderSubmission? _pendingReminderSubmission;

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
      final safeDraft = loaded.copyWith(currentStep: safeStep);
      _publish(OnboardingCoordinatorState(
        status: OnboardingCoordinatorStatus.ready,
        draft: safeDraft,
        effectiveStep: safeStep,
      ));
      if (_stepIndex(safeStep) >= _stepIndex(OnboardingStep.recommendations) &&
          _stepIndex(safeStep) < _stepIndex(OnboardingStep.auth)) {
        await _loadRecommendationsForDraft(safeDraft, epoch: epoch);
      }
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
    _clearPendingReminderSubmission();
    _returnToPreviewAfterEdit = false;
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

  /// Refreshes coordinator state after AUTH-3 has completed and cleared the
  /// local draft. Bootstrap remains the authority for the final Home handoff.
  Future<void> refreshAfterAuthCompletion() => resume();

  Future<void> restart() async {
    _clearPendingReminderSubmission();
    _returnToPreviewAfterEdit = false;
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

  /// Loads the exact catalog version pinned by the draft. The locale is an
  /// input to the repository; the coordinator does not inspect platform
  /// locale or mix localization with ranking.
  Future<bool> loadRecommendations({String locale = 'es'}) async {
    final current = _state.draft;
    if (current == null || current.pace == null || current.goalCodes.isEmpty) {
      return false;
    }
    final epoch = _beginOperation();
    return _loadRecommendationsForDraft(current, epoch: epoch, locale: locale);
  }

  Future<bool> refreshRecommendations({String locale = 'es'}) async {
    final current = _state.draft;
    final visible =
        _state.recommendations ?? const <OnboardingRecommendation>[];
    if (current == null ||
        _state.effectiveStep != OnboardingStep.recommendations ||
        _catalogSnapshot == null) {
      return false;
    }
    final epoch = _beginOperation();
    final discarded = <String>{...current.discardedRecommendationIds};
    for (final recommendation in visible) {
      if (recommendation.id != current.selectedRecommendationId) {
        discarded.add(recommendation.id);
      }
    }
    final base = current.copyWith(discardedRecommendationIds: discarded);
    _publish(_state.copyWith(
      status: OnboardingCoordinatorStatus.refreshing,
      draft: base,
      error: null,
      validation: null,
    ));
    try {
      final snapshot = await _catalogRepository.resolve(
        catalogVersion: base.catalogVersion,
        locale: locale,
      );
      if (!_isCurrent(epoch)) return false;
      _catalogSnapshot = snapshot;
      final batch = _rank(base, snapshot);
      if (batch.isEmpty) throw const _NoRecommendationsException();
      final updated = base.copyWith(
        shownRecommendationIds: {
          ...base.shownRecommendationIds,
          ...batch.map((recommendation) => recommendation.id),
        },
      );
      await _draftService.saveAnonymousDraft(updated);
      if (!_isCurrent(epoch)) return false;
      _publish(OnboardingCoordinatorState(
        status: OnboardingCoordinatorStatus.ready,
        draft: updated,
        effectiveStep: OnboardingStep.recommendations,
        isAtWelcome: false,
        recommendations: batch,
      ));
      return true;
    } catch (error) {
      if (!_isCurrent(epoch)) return false;
      _publish(_state.copyWith(
        status: OnboardingCoordinatorStatus.recoverableError,
        draft: current,
        recommendations: visible,
        error: OnboardingCoordinatorError(
          type: error is RecommendationCatalogException
              ? OnboardingCoordinatorErrorType.catalog
              : OnboardingCoordinatorErrorType.persistence,
          cause: error,
        ),
      ));
      return false;
    }
  }

  /// Stores only the selected template id. It deliberately does not write a
  /// habit or call any habit, notification, sync or remote service.
  Future<bool> selectRecommendation(String id) async {
    final current = _state.draft;
    final snapshot = _catalogSnapshot;
    if (current == null ||
        snapshot == null ||
        _state.effectiveStep != OnboardingStep.recommendations) {
      return false;
    }
    final recommendation = snapshot.findById(id);
    if (recommendation == null || !recommendation.active) return false;
    return _persistStep(
      current.copyWith(selectedRecommendationId: id),
      OnboardingStep.habit,
      _beginOperation(),
      validate: false,
    );
  }

  /// Persists the custom route intent (null recommendation) before opening
  /// HabitStep. It does not create or persist a habit yet.
  Future<bool> createHabitFromScratch() async {
    final current = _state.draft;
    if (current == null ||
        _state.effectiveStep != OnboardingStep.recommendations) {
      return false;
    }
    return _persistStep(
      current.copyWith(selectedRecommendationId: null),
      OnboardingStep.habit,
      _beginOperation(),
      validate: false,
    );
  }

  /// Returns the typed editor value without overwriting an already confirmed
  /// draft configuration. A missing recommendation snapshot is recoverable by
  /// the caller and never becomes arbitrary habit data.
  OnboardingHabitConfiguration? habitConfigurationForDraft({
    String locale = 'es',
  }) {
    final current = _state.draft;
    if (current == null) return null;
    if (current.habit != null) {
      return OnboardingHabitDraftAdapter.tryDecode(current.habit);
    }
    final selectedId = current.selectedRecommendationId;
    if (selectedId == null) return OnboardingHabitConfiguration.custom();
    final recommendation = _catalogSnapshot?.findById(selectedId);
    if (recommendation == null || !recommendation.active) return null;
    try {
      return OnboardingHabitConfiguration.fromRecommendation(
        recommendation,
        locale: locale,
      );
    } on FormatException {
      return null;
    }
  }

  /// Validates and persists only the typed habit configuration in the draft.
  /// No UserStateStore, notifications, sync or remote repository is involved.
  Future<bool> submitHabit(OnboardingHabitConfiguration configuration) async {
    final current = _state.draft;
    if (current == null ||
        _state.isAtWelcome ||
        _state.effectiveStep != OnboardingStep.habit) {
      return false;
    }
    if (!OnboardingDraftValidator.validateFirstName(
                current.firstName)
            .isValid ||
        !OnboardingDraftValidator.validateGoalCodes(current.goalCodes)
            .isValid ||
        !OnboardingDraftValidator.validatePace(current.pace).isValid) {
      _publish(_state.copyWith(
        status: OnboardingCoordinatorStatus.ready,
        validation:
            const OnboardingValidationResult(<OnboardingValidationIssue>[
          OnboardingValidationIssue(
            OnboardingValidationCode.required,
            'Habit prerequisites are incomplete.',
          ),
        ]),
      ));
      return false;
    }
    if (current.selectedRecommendationId != null &&
        _catalogSnapshot?.findById(current.selectedRecommendationId) == null) {
      _publish(_state.copyWith(
        status: OnboardingCoordinatorStatus.recoverableError,
        error: const OnboardingCoordinatorError(
          type: OnboardingCoordinatorErrorType.catalog,
        ),
      ));
      return false;
    }
    final validation = OnboardingHabitConfigurationValidator.validate(
      configuration,
    );
    if (!validation.isValid) {
      _publish(_state.copyWith(
        status: OnboardingCoordinatorStatus.ready,
        validation: validation,
        error: null,
      ));
      return false;
    }
    final encoded = OnboardingHabitDraftAdapter.encode(configuration);
    final returnToPreview = _returnToPreviewAfterEdit;
    final result = await _persistStep(
      current.copyWith(habit: encoded),
      returnToPreview ? OnboardingStep.preview : OnboardingStep.reminder,
      _beginOperation(),
    );
    if (result && returnToPreview) _returnToPreviewAfterEdit = false;
    return result;
  }

  /// Opens one of the editable Preview blocks without changing the draft's
  /// identity or creating a persisted return route. The flag is process-local
  /// and is consumed only after the edited step saves successfully.
  Future<bool> goToStepForEditing(OnboardingStep step) async {
    final current = _state.draft;
    if (current == null ||
        _state.isAtWelcome ||
        _state.effectiveStep != OnboardingStep.preview ||
        _state.isPersisting ||
        _state.isRefreshing ||
        _state.isLoading ||
        !const <OnboardingStep>{
          OnboardingStep.goals,
          OnboardingStep.pace,
          OnboardingStep.habit,
          OnboardingStep.reminder,
        }.contains(step) ||
        !OnboardingDraftValidator.isStepDataValid(current, step)) {
      return false;
    }
    _returnToPreviewAfterEdit = true;
    return _persistStep(
      current,
      step,
      _beginOperation(),
      validate: false,
    );
  }

  /// Advances to the Auth boundary only. Auth, account creation and remote
  /// completion are deliberately owned by the next onboarding phase.
  Future<bool> continueFromPreview() async {
    final current = _state.draft;
    if (current == null ||
        _state.isAtWelcome ||
        _state.effectiveStep != OnboardingStep.preview ||
        !_isPreviewDraftValid(current)) {
      return false;
    }
    _returnToPreviewAfterEdit = false;
    return _persistStep(
      current,
      OnboardingStep.auth,
      _beginOperation(),
    );
  }

  /// Returns the persisted reminder or a calm initial suggestion. A catalog
  /// suggestion is only a time prefill; it never enables the reminder.
  OnboardingReminderConfiguration? reminderConfigurationForDraft() {
    final current = _state.draft;
    if (current == null) return null;
    if (current.reminder != null) {
      return OnboardingReminderDraftAdapter.tryDecode(current.reminder);
    }

    final recommendation = _catalogSnapshot?.findById(
      current.selectedRecommendationId,
    );
    final suggested = _parseReminderTime(recommendation?.suggestedReminderTime);
    return OnboardingReminderConfiguration.suggestion(
      selectedTime:
          suggested ?? const OnboardingReminderTime(hour: 8, minute: 0),
    );
  }

  /// Commits an explicit reminder decision. Permission is requested only for
  /// an enabled reminder and only when the system state has not been resolved
  /// previously. No scheduling API is called because there is no canonical
  /// habit id in this phase.
  Future<bool> submitReminder(
    OnboardingReminderConfiguration configuration,
  ) async {
    final current = _state.draft;
    if (current == null ||
        _state.isAtWelcome ||
        _state.effectiveStep != OnboardingStep.reminder ||
        _reminderSubmitInFlight) {
      return false;
    }
    final validation = OnboardingReminderConfigurationValidator.validate(
      configuration,
    );
    if (!validation.isValid) {
      _publish(_state.copyWith(
        status: OnboardingCoordinatorStatus.ready,
        validation: validation,
        error: null,
      ));
      return false;
    }

    _reminderSubmitInFlight = true;
    final epoch = _beginOperation();
    try {
      if (!configuration.enabled) {
        final previous = OnboardingReminderDraftAdapter.tryDecode(
          current.reminder,
        );
        final disabled = OnboardingReminderConfiguration.disabled(
          permissionState:
              previous?.permissionState ?? ReminderPermissionState.notRequested,
        );
        final result = await _persistStep(
          current.copyWith(
            reminder: OnboardingReminderDraftAdapter.encode(disabled),
          ),
          OnboardingStep.preview,
          epoch,
        );
        if (result) {
          _clearPendingReminderSubmission();
          _returnToPreviewAfterEdit = false;
        }
        return result;
      }

      final previous = OnboardingReminderDraftAdapter.tryDecode(
        current.reminder,
      );
      final cached = _pendingReminderSubmission;
      final sameTime = cached != null &&
          cached.draftId == current.draftId &&
          cached.configuration.selectedTime == configuration.selectedTime;
      final permission = sameTime
          ? cached.permissionState
          : previous != null &&
                  previous.permissionState !=
                      ReminderPermissionState.notRequested
              ? previous.permissionState
              : await _requestReminderPermission(epoch);
      if (!_isCurrent(epoch)) return false;

      final scheduling = permission == ReminderPermissionState.authorized ||
              permission == ReminderPermissionState.provisional
          ? ReminderSchedulingState.readyToSchedule
          : ReminderSchedulingState.pendingRetry;
      final resolved = configuration.copyWith(
        permissionState: permission,
        schedulingState: scheduling,
      );
      _pendingReminderSubmission = _PendingReminderSubmission(
        draftId: current.draftId,
        configuration: configuration,
        permissionState: permission,
      );
      final result = await _persistStep(
        current.copyWith(
            reminder: OnboardingReminderDraftAdapter.encode(resolved)),
        OnboardingStep.preview,
        epoch,
      );
      if (result) {
        _clearPendingReminderSubmission();
        _returnToPreviewAfterEdit = false;
      }
      return result;
    } finally {
      _reminderSubmitInFlight = false;
    }
  }

  Future<ReminderPermissionState> _requestReminderPermission(int epoch) async {
    final result = await _reminderPermissionGateway.requestPermission();
    if (!_isCurrent(epoch)) return ReminderPermissionState.notRequested;
    return result;
  }

  Future<bool> goBack() async {
    final current = _state.draft;
    final step = _state.effectiveStep;
    if (current == null || step == null || _state.isAtWelcome) return false;
    _returnToPreviewAfterEdit = false;
    if (step != OnboardingStep.reminder) _clearPendingReminderSubmission();
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

    return _persistStep(
      current,
      internalSteps[index - 1],
      _beginOperation(),
      validate: false,
    );
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
    var candidate = current.copyWith(goalCodes: goalCodes);
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
    final selected = candidate.selectedRecommendationId;
    final selectedRecommendation = _catalogSnapshot?.findById(selected);
    if (selected != null &&
        (selectedRecommendation == null ||
            selectedRecommendation.goalCodes
                .intersection(candidate.goalCodes)
                .isEmpty)) {
      candidate = candidate.copyWith(selectedRecommendationId: null);
    }
    return _persistEditedOrNormalStep(candidate, OnboardingStep.pace);
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
    return _persistEditedOrNormalStep(
      candidate,
      OnboardingStep.recommendations,
    );
  }

  /// Temporary shell-only data source. It is deliberately outside Domain and
  /// contains no production flags; remove it when real step presenters land.
  Future<bool> submitPlaceholderStep() {
    final current = _state.draft;
    final step = _state.effectiveStep;
    if (current == null || step == null) return Future<bool>.value(false);
    switch (step) {
      case OnboardingStep.recommendations:
        // Real recommendation actions use selectRecommendation or
        // createHabitFromScratch. Recommendations have no placeholder path.
        return Future<bool>.value(false);
      case OnboardingStep.habit:
        // HabitStep is real. It submits a typed configuration through
        // submitHabit; this method is reserved for remaining placeholders.
        return Future<bool>.value(false);
      case OnboardingStep.reminder:
        // Reminder is real. Its explicit actions use submitReminder().
        return Future<bool>.value(false);
      case OnboardingStep.preview:
        return Future<bool>.value(false);
      default:
        // Name and non-placeholder terminal steps have no fake data path.
        return Future<bool>.value(false);
    }
  }

  /// Invalidates pending results for logout, scope switches and restart.
  void invalidateAsyncOperations({int? scopeEpoch}) {
    _runEpoch++;
    _scopeEpoch = scopeEpoch;
    _clearPendingReminderSubmission();
    _returnToPreviewAfterEdit = false;
  }

  /// Computes the first step that is safe to show, clamped by the persisted
  /// cursor. Thus an advanced cursor can never bypass an invalid prerequisite.
  OnboardingStep effectiveStepFor(OnboardingDraft draft) {
    if (draft.currentStep == OnboardingStep.habit &&
        draft.selectedRecommendationId == null &&
        OnboardingDraftValidator.validateFirstName(draft.firstName).isValid &&
        OnboardingDraftValidator.validateGoalCodes(draft.goalCodes).isValid &&
        OnboardingDraftValidator.validatePace(draft.pace).isValid) {
      return OnboardingStep.habit;
    }
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
    int epoch, {
    bool validate = true,
  }) async {
    if (validate) {
      final validation = _validateCandidate(candidate, _state.effectiveStep!);
      if (!validation.isValid) {
        _publish(_state.copyWith(
          status: OnboardingCoordinatorStatus.ready,
          validation: validation,
        ));
        return false;
      }
    }
    final persisted = candidate.copyWith(currentStep: step);
    _publish(_state.copyWith(
      status: OnboardingCoordinatorStatus.persisting,
      error: null,
      validation: null,
    ));
    try {
      await _draftService.saveAnonymousDraft(persisted);
      if (!_isCurrent(epoch)) return false;
      if (step == OnboardingStep.recommendations) {
        return _loadRecommendationsForDraft(persisted, epoch: epoch);
      }
      _publish(OnboardingCoordinatorState(
        status: OnboardingCoordinatorStatus.ready,
        draft: persisted,
        effectiveStep: step,
        isAtWelcome: false,
        recommendations: _state.recommendations,
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
        return OnboardingHabitConfigurationValidator.validateDraftMap(
          candidate.habit,
        );
      case OnboardingStep.reminder:
        return OnboardingReminderConfigurationValidator.validateDraftMap(
          candidate.reminder,
        );
      case OnboardingStep.preview:
        return _isPreviewDraftValid(candidate)
            ? const OnboardingValidationResult.valid()
            : const OnboardingValidationResult(<OnboardingValidationIssue>[
                OnboardingValidationIssue(
                  OnboardingValidationCode.required,
                  'Preview prerequisites are incomplete.',
                ),
              ]);
      case OnboardingStep.auth:
      case OnboardingStep.emailConfirmation:
      case OnboardingStep.resolvingAccount:
      case OnboardingStep.finalizing:
        return const OnboardingValidationResult.valid();
    }
  }

  Future<bool> _loadRecommendationsForDraft(
    OnboardingDraft draft, {
    required int epoch,
    String locale = 'es',
  }) async {
    if (!_isCurrent(epoch)) return false;
    final step = effectiveStepFor(draft);
    _publish(OnboardingCoordinatorState(
      status: OnboardingCoordinatorStatus.loading,
      draft: draft,
      effectiveStep: step,
      isAtWelcome: _state.isAtWelcome,
      recommendations: _state.recommendations,
    ));
    try {
      final snapshot = await _catalogRepository.resolve(
        catalogVersion: draft.catalogVersion,
        locale: locale,
      );
      if (!_isCurrent(epoch)) return false;
      if (snapshot.version != draft.catalogVersion) {
        throw RecommendationCatalogException(
          message: 'Resolved catalog did not match the pinned version.',
          catalogVersion: draft.catalogVersion,
        );
      }
      final validation = OnboardingRecommendationCatalogValidator.validate(
        snapshot,
        expectedVersion: draft.catalogVersion,
      );
      if (validation.validRecommendations.isEmpty) {
        throw const _NoRecommendationsException();
      }
      _catalogSnapshot = snapshot;
      var effectiveDraft = draft;
      if (draft.selectedRecommendationId != null &&
          snapshot.findById(draft.selectedRecommendationId) == null) {
        // An unknown selection is invalidated only after the pinned snapshot
        // has been resolved. Version failures above leave the draft untouched.
        effectiveDraft = draft.copyWith(
          currentStep: OnboardingStep.recommendations,
          selectedRecommendationId: null,
        );
      }
      final batch = _rank(effectiveDraft, snapshot);
      if (batch.isEmpty) throw const _NoRecommendationsException();
      final updated = effectiveDraft.copyWith(
        shownRecommendationIds: {
          ...effectiveDraft.shownRecommendationIds,
          ...batch.map((recommendation) => recommendation.id),
        },
      );
      await _draftService.saveAnonymousDraft(updated);
      if (!_isCurrent(epoch)) return false;
      _publish(OnboardingCoordinatorState(
        status: OnboardingCoordinatorStatus.ready,
        draft: updated,
        effectiveStep: effectiveStepFor(updated),
        isAtWelcome: _state.isAtWelcome,
        recommendations: batch,
      ));
      return true;
    } catch (error) {
      if (!_isCurrent(epoch)) return false;
      _publish(OnboardingCoordinatorState(
        status: OnboardingCoordinatorStatus.recoverableError,
        draft: draft,
        effectiveStep: step,
        isAtWelcome: _state.isAtWelcome,
        recommendations: _state.recommendations,
        error: OnboardingCoordinatorError(
          type: error is RecommendationCatalogException ||
                  error is _NoRecommendationsException
              ? OnboardingCoordinatorErrorType.catalog
              : OnboardingCoordinatorErrorType.persistence,
          cause: error,
        ),
      ));
      return false;
    }
  }

  List<OnboardingRecommendation> _rank(
    OnboardingDraft draft,
    OnboardingRecommendationCatalogSnapshot snapshot,
  ) {
    return _rankingService.rank(
      OnboardingRecommendationRankingRequest(
        snapshot: snapshot,
        selectedGoalCodes: draft.goalCodes,
        pace: draft.pace!,
        shownRecommendationIds: draft.shownRecommendationIds,
        discardedRecommendationIds: draft.discardedRecommendationIds,
      ),
    );
  }

  int _stepIndex(OnboardingStep step) => internalSteps.indexOf(step);

  Future<bool> _persistEditedOrNormalStep(
    OnboardingDraft candidate,
    OnboardingStep normalNextStep,
  ) async {
    final returnToPreview = _returnToPreviewAfterEdit;
    final result = await _persistStep(
      candidate,
      returnToPreview ? OnboardingStep.preview : normalNextStep,
      _beginOperation(),
    );
    if (result && returnToPreview) _returnToPreviewAfterEdit = false;
    return result;
  }

  bool _isPreviewDraftValid(OnboardingDraft draft) {
    if (!OnboardingDraftValidator.isStepDataValid(
      draft,
      OnboardingStep.preview,
    )) {
      return false;
    }
    // A null selection is the valid custom-habit route. A selected
    // recommendation still needs to resolve against the pinned snapshot.
    if (draft.selectedRecommendationId == null) return true;
    final recommendation = _catalogSnapshot?.findById(
      draft.selectedRecommendationId,
    );
    return recommendation != null && recommendation.active;
  }

  void _clearPendingReminderSubmission() {
    _pendingReminderSubmission = null;
  }

  OnboardingReminderTime? _parseReminderTime(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value);
    if (match == null) return null;
    final time = OnboardingReminderTime(
      hour: int.parse(match.group(1)!),
      minute: int.parse(match.group(2)!),
    );
    return time.isValid ? time : null;
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

class _PendingReminderSubmission {
  const _PendingReminderSubmission({
    required this.draftId,
    required this.configuration,
    required this.permissionState,
  });

  final String draftId;
  final OnboardingReminderConfiguration configuration;
  final ReminderPermissionState permissionState;
}

class _NoRecommendationsException implements Exception {
  const _NoRecommendationsException();
}
