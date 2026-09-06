import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_theme.dart';

/// Welcome presentation for the V1 onboarding entry point.
/// It only emits intents; draft state and restart semantics live in the
/// OnboardingCoordinator.
class WelcomeContent extends StatelessWidget {
  const WelcomeContent({
    super.key,
    required this.onPrepare,
    required this.onLogin,
    required this.onSignup,
    this.onResume,
    this.onRestart,
    this.resumeStep,
    this.errorMessage,
    this.isBusy = false,
  });

  final VoidCallback onPrepare;
  final VoidCallback onLogin;
  final VoidCallback onSignup;
  final VoidCallback? onResume;
  final VoidCallback? onRestart;
  final String? resumeStep;
  final String? errorMessage;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(26, 28, 26, 20 + bottomPad),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 80),
                Text(
                  l10n.welcomeBrand,
                  style: TextStyle(
                    letterSpacing: 3,
                    fontSize: 12,
                    color: AppColors.ink.withValues(alpha: 0.35),
                  ),
                ),
                const SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.welcomeTitle,
                    children: [
                      TextSpan(text: l10n.welcomeTitleLine1),
                      TextSpan(
                        text: l10n.welcomeTitleLine2,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(l10n.welcomeSubtitle,
                    style: AppTextStyles.welcomeSubtitle),
                const SizedBox(height: 30),
                SizedBox(
                  height: 64,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isBusy ? null : onPrepare,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: AppColors.cream,
                      shape: const StadiumBorder(),
                      textStyle: AppTextStyles.buttonPrimary,
                    ),
                    child: Text(l10n.onboardingPrepareTitle),
                  ),
                ),
                if (onResume != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: isBusy ? null : onResume,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ink,
                        shape: const StadiumBorder(),
                        textStyle: AppTextStyles.buttonOutline,
                        side: BorderSide(
                          color: AppColors.ink.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Text(l10n.onboardingResume),
                    ),
                  ),
                  if (resumeStep != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      resumeStep!,
                      style: AppTextStyles.authSub.copyWith(
                        color: AppColors.ink.withValues(alpha: 0.58),
                      ),
                    ),
                  ],
                  Align(
                    alignment: Alignment.center,
                    child: TextButton(
                      onPressed: isBusy ? null : onRestart,
                      child: Text(l10n.onboardingRestart),
                    ),
                  ),
                ],
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.authSub.copyWith(
                      color: AppColors.rust,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: isBusy ? null : onLogin,
                    child: Text(l10n.onboardingExistingAccount),
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: isBusy ? null : onSignup,
                    child: Text(l10n.welcomeSignupButton),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
