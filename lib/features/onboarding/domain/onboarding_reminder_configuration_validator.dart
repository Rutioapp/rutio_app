import '../data/onboarding_reminder_draft_adapter.dart';
import 'models/onboarding_reminder_configuration.dart';
import 'onboarding_validation.dart';

class OnboardingReminderConfigurationValidator {
  const OnboardingReminderConfigurationValidator._();

  static OnboardingValidationResult validate(
    OnboardingReminderConfiguration value,
  ) {
    try {
      OnboardingReminderDraftAdapter.encode(value);
      return const OnboardingValidationResult.valid();
    } on OnboardingReminderDraftAdapterException catch (error) {
      return OnboardingValidationResult(<OnboardingValidationIssue>[
        OnboardingValidationIssue(
          OnboardingValidationCode.required,
          error.message,
        ),
      ]);
    }
  }

  static OnboardingValidationResult validateDraftMap(
    Map<String, dynamic>? value,
  ) {
    final decoded = OnboardingReminderDraftAdapter.tryDecode(value);
    return decoded == null
        ? const OnboardingValidationResult(<OnboardingValidationIssue>[
            OnboardingValidationIssue(
              OnboardingValidationCode.required,
              'Reminder draft is invalid.',
            ),
          ])
        : validate(decoded);
  }
}
