import 'models/onboarding_draft.dart';
import 'models/onboarding_types.dart';

enum OnboardingValidationCode {
  required,
  tooLong,
  invalidUnicode,
  minimum,
  maximum,
  duplicate,
  missing,
}

class OnboardingValidationIssue {
  const OnboardingValidationIssue(this.code, this.message);

  final OnboardingValidationCode code;
  final String message;
}

class OnboardingValidationResult {
  const OnboardingValidationResult(this.issues);

  const OnboardingValidationResult.valid()
      : issues = const <OnboardingValidationIssue>[];

  final List<OnboardingValidationIssue> issues;

  bool get isValid => issues.isEmpty;
}

class OnboardingDraftValidator {
  const OnboardingDraftValidator._();

  static OnboardingValidationResult validateFirstName(
    String? value, {
    bool required = true,
  }) {
    final normalized = (value ?? '').trim();
    if (normalized.isEmpty) {
      return required
          ? const OnboardingValidationResult(<OnboardingValidationIssue>[
              OnboardingValidationIssue(
                OnboardingValidationCode.required,
                'First name is required.',
              ),
            ])
          : const OnboardingValidationResult.valid();
    }
    if (normalized.runes.length > 30) {
      return const OnboardingValidationResult(<OnboardingValidationIssue>[
        OnboardingValidationIssue(
          OnboardingValidationCode.tooLong,
          'First name must be at most 30 characters.',
        ),
      ]);
    }
    if (normalized.runes.any(
      (rune) => rune == 0xfffd || rune < 0x20 || rune == 0x7f,
    )) {
      return const OnboardingValidationResult(<OnboardingValidationIssue>[
        OnboardingValidationIssue(
          OnboardingValidationCode.invalidUnicode,
          'First name contains invalid characters.',
        ),
      ]);
    }
    return const OnboardingValidationResult.valid();
  }

  static OnboardingValidationResult validateGoalCodes(
    Iterable<String> values, {
    int minimum = 1,
    int maximum = 3,
  }) {
    final list = values.toList(growable: false);
    if (list.length < minimum) {
      return const OnboardingValidationResult(<OnboardingValidationIssue>[
        OnboardingValidationIssue(
          OnboardingValidationCode.minimum,
          'At least one goal is required.',
        ),
      ]);
    }
    if (list.length > maximum) {
      return const OnboardingValidationResult(<OnboardingValidationIssue>[
        OnboardingValidationIssue(
          OnboardingValidationCode.maximum,
          'At most three goals are allowed.',
        ),
      ]);
    }
    final normalized = <String>{};
    for (final value in list) {
      final code = value.trim();
      if (code.isEmpty) {
        return const OnboardingValidationResult(<OnboardingValidationIssue>[
          OnboardingValidationIssue(
            OnboardingValidationCode.required,
            'Goal codes must not be empty.',
          ),
        ]);
      }
      if (!normalized.add(code)) {
        return const OnboardingValidationResult(<OnboardingValidationIssue>[
          OnboardingValidationIssue(
            OnboardingValidationCode.duplicate,
            'Goal codes must be unique.',
          ),
        ]);
      }
    }
    return const OnboardingValidationResult.valid();
  }

  static OnboardingValidationResult validatePace(OnboardingPace? pace) {
    return pace == null
        ? const OnboardingValidationResult(<OnboardingValidationIssue>[
            OnboardingValidationIssue(
              OnboardingValidationCode.required,
              'Pace is required.',
            ),
          ])
        : const OnboardingValidationResult.valid();
  }

  static bool isStepDataValid(OnboardingDraft draft, OnboardingStep step) {
    switch (step) {
      case OnboardingStep.name:
        return validateFirstName(draft.firstName).isValid;
      case OnboardingStep.goals:
        return validateGoalCodes(draft.goalCodes).isValid;
      case OnboardingStep.pace:
        return validatePace(draft.pace).isValid;
      case OnboardingStep.recommendations:
        return draft.selectedRecommendationId != null;
      case OnboardingStep.habit:
        return draft.habit != null && draft.habit!.isNotEmpty;
      case OnboardingStep.reminder:
        return draft.reminder != null;
      case OnboardingStep.preview:
        return draft.habit != null && draft.habit!.isNotEmpty;
      case OnboardingStep.auth:
        return draft.authIntent != null;
      case OnboardingStep.emailConfirmation:
      case OnboardingStep.resolvingAccount:
      case OnboardingStep.finalizing:
        return false;
    }
  }

  static Set<OnboardingStep> validSteps(OnboardingDraft draft) {
    return OnboardingStep.values
        .where((step) => isStepDataValid(draft, step))
        .toSet();
  }

  /// Returns the last contiguous step with valid data, independently of the
  /// persisted currentStep. The returned step is where a coordinator can
  /// safely reconstruct state, not proof that later steps are complete.
  static OnboardingStep? lastSafeStep(OnboardingDraft draft) {
    OnboardingStep? last;
    for (final step in OnboardingStep.values) {
      if (!isStepDataValid(draft, step)) break;
      last = step;
    }
    return last;
  }
}
