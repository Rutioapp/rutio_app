import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../ui/foundations/ios_foundations.dart';
import '../controllers/onboarding_controller.dart';
import '../models/onboarding_step.dart';
import 'onboarding_dialog_card.dart';

class OnboardingOverlay extends StatelessWidget {
  const OnboardingOverlay({
    super.key,
    required this.onContinue,
    required this.onDismiss,
  });

  static const Duration transitionDuration = Duration(milliseconds: 280);
  static const Duration reverseTransitionDuration = Duration(milliseconds: 220);
  static const Duration sheetLaunchDelay = Duration(milliseconds: 240);
  static const double homeBottomSpacing = 92;
  static const double homeReservedScrollPadding = 236;

  final Future<void> Function(OnboardingStep step) onContinue;
  final Future<void> Function(OnboardingStep step) onDismiss;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(
            IosSpacing.lg,
            0,
            IosSpacing.lg,
            homeBottomSpacing,
          ),
          child: Consumer<OnboardingController>(
            builder: (context, controller, _) {
              final step = controller.currentStep;
              final isBusy = controller.isMutating;

              return IgnorePointer(
                ignoring: step == null || isBusy,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: AnimatedSwitcher(
                    duration: transitionDuration,
                    reverseDuration: reverseTransitionDuration,
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final curved = CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                        reverseCurve: Curves.easeInCubic,
                      );

                      return FadeTransition(
                        opacity: curved,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.08),
                            end: Offset.zero,
                          ).animate(curved),
                          child: child,
                        ),
                      );
                    },
                    child: step == null
                        ? const SizedBox.shrink(
                            key: ValueKey<String>('onboarding-overlay-empty'),
                          )
                        : OnboardingDialogCard(
                            key: ValueKey<String>(step.id),
                            step: step,
                            isBusy: isBusy,
                            onContinue: onContinue,
                            onDismiss: onDismiss,
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
