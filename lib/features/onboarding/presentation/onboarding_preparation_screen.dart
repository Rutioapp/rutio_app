import 'package:flutter/material.dart';

import '../../../widgets/loading/rutio_loading_screen.dart';

/// Stable preparation surface used while an authenticated onboarding handoff
/// is still being finalized and Bootstrap is preparing Home.
class OnboardingPreparationScreen extends StatelessWidget {
  const OnboardingPreparationScreen({
    super.key,
    this.phase = 0,
    this.isOperationComplete = false,
    this.onFinished,
    this.startJourney = true,
  });

  final double phase;
  final bool isOperationComplete;
  final VoidCallback? onFinished;
  final bool startJourney;

  @override
  Widget build(BuildContext context) {
    return RutioLoadingScreen(
      initialProgress: phase,
      isOperationComplete: isOperationComplete,
      startJourney: startJourney,
      onCompleted: onFinished,
    );
  }
}
