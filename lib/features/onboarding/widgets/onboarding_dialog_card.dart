import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rutio/utils/app_theme.dart';

import '../../../ui/foundations/ios_foundations.dart';
import '../models/onboarding_step.dart';
import 'onboarding_avatar_placeholder.dart';

class OnboardingDialogCard extends StatelessWidget {
  const OnboardingDialogCard({
    super.key,
    required this.step,
    required this.isBusy,
    required this.onContinue,
    required this.onDismiss,
  });

  final OnboardingStep step;
  final bool isBusy;
  final Future<void> Function(OnboardingStep step) onContinue;
  final Future<void> Function(OnboardingStep step) onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IosFrostedCard(
      elevated: true,
      padding: const EdgeInsets.fromLTRB(
        IosSpacing.md,
        IosSpacing.md,
        IosSpacing.md,
        IosSpacing.md,
      ),
      backgroundColor: Colors.white.withValues(alpha: 0.78),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 44),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const OnboardingAvatarPlaceholder(),
                const SizedBox(width: IosSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if ((step.title ?? '').trim().isNotEmpty) ...[
                        Text(
                          step.title!.trim(),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.earth,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: IosSpacing.xs),
                      ],
                      Text(
                        step.message,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppColors.ink.withValues(alpha: 0.92),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: IosSpacing.md),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: IosSpacing.md,
                          vertical: IosSpacing.sm,
                        ),
                        color: AppColors.ink.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(
                          IosCornerRadius.control,
                        ),
                        onPressed: isBusy ? null : () => onContinue(step),
                        child: Text(
                          step.primaryLabel,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.cream,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (step.dismissible)
            Positioned(
              top: -6,
              right: -10,
              child: CupertinoButton(
                minimumSize: const Size(32, 32),
                padding: const EdgeInsets.all(IosSpacing.xs),
                borderRadius: BorderRadius.circular(IosCornerRadius.pill),
                color: Colors.white.withValues(alpha: 0.66),
                onPressed: isBusy ? null : () => onDismiss(step),
                child: Icon(
                  CupertinoIcons.xmark,
                  size: 16,
                  color: AppColors.ink.withValues(alpha: 0.72),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
