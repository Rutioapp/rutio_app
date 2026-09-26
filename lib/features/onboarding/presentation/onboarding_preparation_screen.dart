import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/backgrounds/rutio_sky_background.dart';

/// Stable preparation surface used while an authenticated onboarding handoff
/// is still being finalized and Bootstrap is preparing Home.
class OnboardingPreparationScreen extends StatelessWidget {
  const OnboardingPreparationScreen({
    super.key,
    this.phase = 0,
  });

  final double phase;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        fit: StackFit.expand,
        children: [
          RutioSkyBackground(
            showBottomFade: true,
            phase: phase,
            initialPhase: phase,
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(strokeWidth: 2),
                  const SizedBox(height: 18),
                  Text(context.l10n.onboardingLoading),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
