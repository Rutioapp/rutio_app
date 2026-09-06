import '../data/onboarding_habit_draft_adapter.dart';
import 'models/onboarding_habit_configuration.dart';
import 'onboarding_validation.dart';

/// Domain validation for the typed Habit step. It intentionally delegates the
/// canonical-map boundary check to the adapter so presentation cannot drift
/// from the local habit contract.
class OnboardingHabitConfigurationValidator {
  const OnboardingHabitConfigurationValidator._();

  static OnboardingValidationResult validate(
    OnboardingHabitConfiguration configuration,
  ) {
    try {
      OnboardingHabitDraftAdapter.encode(configuration);
      return const OnboardingValidationResult.valid();
    } on OnboardingHabitDraftAdapterException catch (error) {
      final message = error.message;
      final code = message.contains('required')
          ? OnboardingValidationCode.required
          : message.contains('target')
              ? OnboardingValidationCode.minimum
              : message.contains('too long')
                  ? OnboardingValidationCode.tooLong
                  : OnboardingValidationCode.unknown;
      return OnboardingValidationResult(<OnboardingValidationIssue>[
        OnboardingValidationIssue(code, message),
      ]);
    } on FormatException catch (error) {
      return OnboardingValidationResult(<OnboardingValidationIssue>[
        OnboardingValidationIssue(
          OnboardingValidationCode.unknown,
          error.message,
        ),
      ]);
    }
  }

  static OnboardingValidationResult validateDraftMap(
    Map<String, dynamic>? source,
  ) {
    final configuration = OnboardingHabitDraftAdapter.tryDecode(source);
    if (configuration == null) {
      return const OnboardingValidationResult(<OnboardingValidationIssue>[
        OnboardingValidationIssue(
          OnboardingValidationCode.required,
          'Habit configuration is missing or invalid.',
        ),
      ]);
    }
    return validate(configuration);
  }
}
