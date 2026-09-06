import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_theme.dart';
import '../domain/models/onboarding_types.dart';

/// Common layout for the temporary V1 step presenters.
class OnboardingShell extends StatelessWidget {
  const OnboardingShell({
    super.key,
    required this.step,
    required this.progress,
    required this.canGoBack,
    required this.isBusy,
    required this.onBack,
    required this.onContinue,
    this.content,
    this.showStepHeader = true,
    this.continueEnabled = true,
    this.errorMessage,
  });

  final OnboardingStep step;
  final double progress;
  final bool canGoBack;
  final bool isBusy;
  final VoidCallback onBack;
  final VoidCallback? onContinue;
  final Widget? content;
  final bool showStepHeader;
  final bool continueEnabled;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final title = _title(l10n, step);

    return Scaffold(
      backgroundColor: AppColors.cream,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 24, 0),
              child: Row(
                children: [
                  Semantics(
                    button: true,
                    label: l10n.onboardingBack,
                    child: IconButton(
                      tooltip: l10n.onboardingBack,
                      onPressed: canGoBack && !isBusy ? onBack : null,
                      icon: const Icon(CupertinoIcons.chevron_left),
                    ),
                  ),
                  Expanded(
                    child: Semantics(
                      container: true,
                      label: title,
                      child: ExcludeSemantics(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: progress),
                          duration: disableAnimations
                              ? Duration.zero
                              : const Duration(milliseconds: 280),
                          curve: Curves.easeOut,
                          builder: (context, value, _) => ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              minHeight: 6,
                              value: value,
                              backgroundColor:
                                  AppColors.ink.withValues(alpha: 0.10),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.rust.withValues(alpha: 0.86),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(26, 30, 26, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showStepHeader) ...[
                        Text(
                          title,
                          style: AppTextStyles.welcomeTitle.copyWith(
                            fontSize: 32,
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (content == null)
                        Text(
                          l10n.onboardingPlaceholderBody,
                          style: AppTextStyles.welcomeSub.copyWith(
                            color: AppColors.ink.withValues(alpha: 0.68),
                          ),
                        ),
                      const SizedBox(height: 28),
                      content ??
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: AppColors.cream2.withValues(alpha: 0.72),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: AppColors.ink.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Text(
                              title,
                              style: AppTextStyles.authTitle.copyWith(
                                fontSize: 22,
                              ),
                            ),
                          ),
                      if (errorMessage != null) ...[
                        const SizedBox(height: 18),
                        Text(
                          errorMessage!,
                          style: AppTextStyles.authSub.copyWith(
                            color: AppColors.rust,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                26,
                10,
                26,
                18 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: isBusy || !continueEnabled ? null : onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: AppColors.cream,
                      shape: const StadiumBorder(),
                      textStyle: AppTextStyles.buttonPrimary,
                    ),
                    child: isBusy
                        ? const CupertinoActivityIndicator(
                            color: AppColors.cream)
                        : Text(l10n.onboardingContinue),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _title(dynamic l10n, OnboardingStep value) {
    switch (value) {
      case OnboardingStep.name:
        return l10n.onboardingStepName;
      case OnboardingStep.goals:
        return l10n.onboardingStepGoals;
      case OnboardingStep.pace:
        return l10n.onboardingStepPace;
      case OnboardingStep.recommendations:
        return l10n.onboardingStepRecommendations;
      case OnboardingStep.habit:
        return l10n.onboardingStepHabit;
      case OnboardingStep.reminder:
        return l10n.onboardingStepReminder;
      case OnboardingStep.preview:
        return l10n.onboardingStepPreview;
      case OnboardingStep.auth:
      case OnboardingStep.emailConfirmation:
      case OnboardingStep.resolvingAccount:
      case OnboardingStep.finalizing:
        return value.code;
    }
  }
}
