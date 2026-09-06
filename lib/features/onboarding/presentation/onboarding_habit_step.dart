import 'package:flutter/material.dart';

import '../domain/models/onboarding_habit_configuration.dart';
import 'onboarding_habit_form.dart';

/// Onboarding boundary around the reusable real habit-editor body.
///
/// This stateful shell intentionally keeps the public onboarding API stable:
/// the Coordinator still receives only a typed configuration on submit.
class OnboardingHabitStep extends StatefulWidget {
  const OnboardingHabitStep({
    super.key,
    required this.initialConfiguration,
    required this.onSubmit,
    this.errorMessage,
  });

  final OnboardingHabitConfiguration? initialConfiguration;
  final ValueChanged<OnboardingHabitConfiguration> onSubmit;
  final String? errorMessage;

  @override
  OnboardingHabitStepState createState() => OnboardingHabitStepState();
}

class OnboardingHabitStepState extends State<OnboardingHabitStep> {
  final GlobalKey<OnboardingHabitFormState> _formKey =
      GlobalKey<OnboardingHabitFormState>();

  void submit() => _formKey.currentState?.submit();

  @override
  Widget build(BuildContext context) {
    final configuration = widget.initialConfiguration;
    if (configuration == null) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return OnboardingHabitForm(
      key: _formKey,
      initialConfiguration: configuration,
      errorMessage: widget.errorMessage,
      onSubmit: widget.onSubmit,
    );
  }
}
