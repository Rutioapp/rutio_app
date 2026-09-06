import 'package:flutter/material.dart';

import '../features/onboarding/presentation/onboarding_v1_screen.dart';

/// Compatibility route retained for existing deep links and bootstrap tests.
/// The V1 screen owns the actual Welcome and onboarding presentation.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const OnboardingV1Screen();
}
