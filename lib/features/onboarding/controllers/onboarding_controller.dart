import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/onboarding_step.dart';
import '../services/onboarding_persistence_service.dart';

class OnboardingController extends ChangeNotifier {
  OnboardingController({
    required OnboardingPersistenceService persistenceService,
  }) : _persistenceService = persistenceService;

  final OnboardingPersistenceService _persistenceService;

  final Map<String, OnboardingStepProgress> _stepProgress =
      <String, OnboardingStepProgress>{};
  List<OnboardingStep> _steps = const <OnboardingStep>[];

  OnboardingDisplayContext? _displayContext;
  int? _currentStepIndex;
  bool _isLoading = false;
  bool _isMutating = false;
  String? _lastConfigurationSignature;

  bool get isLoading => _isLoading;
  bool get isMutating => _isMutating;
  bool get isVisible => !_isLoading && currentStep != null;
  OnboardingDisplayContext? get displayContext => _displayContext;
  String? get currentTargetId => currentStep?.targetId;
  String? get currentTargetEntityId => currentStep?.targetEntityId;
  UnmodifiableListView<OnboardingStep> get steps =>
      UnmodifiableListView<OnboardingStep>(_steps);
  OnboardingStep? get currentStep {
    final index = _currentStepIndex;
    if (index == null || index < 0 || index >= _steps.length) {
      return null;
    }

    return _steps[index];
  }

  OnboardingStepProgress progressFor(String stepId) {
    return _stepProgress[stepId] ?? const OnboardingStepProgress();
  }

  OnboardingStepProgress? get currentProgress {
    final step = currentStep;
    if (step == null) {
      return null;
    }

    return progressFor(step.id);
  }

  bool isCurrentTarget(
    String targetId, {
    String? targetEntityId,
  }) {
    if (currentTargetId != targetId) {
      return false;
    }

    if (targetEntityId == null) {
      return true;
    }

    return currentTargetEntityId == targetEntityId;
  }

  bool shouldEmphasizeTarget(
    String targetId, {
    String? targetEntityId,
  }) {
    return isVisible &&
        !_isMutating &&
        isCurrentTarget(
          targetId,
          targetEntityId: targetEntityId,
        );
  }

  bool isTargetActive(
    String targetId, {
    String? targetEntityId,
  }) {
    return shouldEmphasizeTarget(
      targetId,
      targetEntityId: targetEntityId,
    );
  }

  Future<void> configure({
    required List<OnboardingStep> steps,
    required OnboardingDisplayContext displayContext,
  }) async {
    final orderedSteps = List<OnboardingStep>.from(steps)
      ..sort((left, right) => left.priority.compareTo(right.priority));
    final signature = _buildConfigurationSignature(
      steps: orderedSteps,
      displayContext: displayContext,
    );

    _steps = orderedSteps;
    _displayContext = displayContext;

    if (_lastConfigurationSignature == signature) {
      _selectCurrentStep();
      notifyListeners();
      return;
    }

    _lastConfigurationSignature = signature;
    _isLoading = true;
    notifyListeners();

    try {
      final stepProgress = await _persistenceService.readStepProgressMap(
        scopeId: displayContext.userScopeId,
      );
      _stepProgress
        ..clear()
        ..addAll(stepProgress);
    } catch (_) {
      _stepProgress.clear();
    } finally {
      _selectCurrentStep();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> dismissCurrent() async {
    if (_isMutating) {
      return false;
    }

    final step = currentStep;
    if (step == null) {
      return false;
    }

    if (!step.dismissible) {
      return false;
    }

    return _applyProgressMutation(
      step: step,
      mutation: () => _persistenceService.markStepDismissed(
        step.id,
        scopeId: _displayContext?.userScopeId,
      ),
    );
  }

  Future<bool> completeCurrent() async {
    if (_isMutating) {
      return false;
    }

    final step = currentStep;
    if (step == null) {
      return false;
    }

    return _applyProgressMutation(
      step: step,
      mutation: () => _persistenceService.markStepCompleted(
        step.id,
        scopeId: _displayContext?.userScopeId,
      ),
    );
  }

  Future<bool> _applyProgressMutation({
    required OnboardingStep step,
    required Future<OnboardingStepProgress> Function() mutation,
  }) async {
    _isMutating = true;
    notifyListeners();

    try {
      final updatedProgress = await mutation();
      _stepProgress[step.id] = updatedProgress;
      _selectCurrentStep();
      return true;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  void _selectCurrentStep() {
    final context = _displayContext;
    if (context == null) {
      _currentStepIndex = null;
      return;
    }

    for (var index = 0; index < _steps.length; index += 1) {
      final step = _steps[index];

      if (_canPresentStep(step, context)) {
        _currentStepIndex = index;
        return;
      }
    }

    _currentStepIndex = null;
  }

  bool _canPresentStep(
    OnboardingStep step,
    OnboardingDisplayContext context,
  ) {
    final progress = progressFor(step.id);
    if (progress.isCompleted) {
      return false;
    }

    if (_persistenceService.isDismissedInSession(
      step.id,
      scopeId: context.userScopeId,
    )) {
      return false;
    }

    return step.isEligibleFor(context);
  }

  String _buildConfigurationSignature({
    required List<OnboardingStep> steps,
    required OnboardingDisplayContext displayContext,
  }) {
    final orderedIds = steps.map((step) => step.id).join(',');
    return '${displayContext.signature}|$orderedIds';
  }
}
