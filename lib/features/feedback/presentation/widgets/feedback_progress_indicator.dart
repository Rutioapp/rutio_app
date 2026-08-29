import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../utils/app_theme.dart';
import '../../domain/feedback_status.dart';

class FeedbackProgressIndicator extends StatelessWidget {
  const FeedbackProgressIndicator({
    super.key,
    required this.status,
  });

  final FeedbackStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final terminalLabel = switch (status) {
      FeedbackStatus.resolved => l10n.feedbackStatusResolved,
      FeedbackStatus.dismissed => l10n.feedbackStatusDismissed,
      _ => l10n.feedbackProgressTerminalLabel,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 420;
        final steps = [
          _ProgressStep(
            index: 1,
            label: l10n.feedbackProgressSubmitted,
            isActive: true,
            isCompleted: true,
          ),
          _ProgressStep(
            index: 2,
            label: l10n.feedbackProgressInReview,
            isActive: status.index >= FeedbackStatus.inReview.index,
            isCompleted: status.index >= FeedbackStatus.inReview.index,
          ),
          _ProgressStep(
            index: 3,
            label: terminalLabel,
            isActive: status.index >= FeedbackStatus.resolved.index,
            isCompleted: status == FeedbackStatus.resolved ||
                status == FeedbackStatus.dismissed,
            isTerminal: true,
          ),
        ];

        if (isWide) {
          return Row(
            children: [
              Expanded(child: _FeedbackProgressStepTile(step: steps[0])),
              const SizedBox(width: 10),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xFFB49F83),
              ),
              const SizedBox(width: 10),
              Expanded(child: _FeedbackProgressStepTile(step: steps[1])),
              const SizedBox(width: 10),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xFFB49F83),
              ),
              const SizedBox(width: 10),
              Expanded(child: _FeedbackProgressStepTile(step: steps[2])),
            ],
          );
        }

        return Column(
          children: [
            _FeedbackProgressStepTile(step: steps[0]),
            _ProgressConnector(active: true),
            _FeedbackProgressStepTile(step: steps[1]),
            _ProgressConnector(
                active: status.index >= FeedbackStatus.inReview.index),
            _FeedbackProgressStepTile(step: steps[2]),
          ],
        );
      },
    );
  }
}

class _FeedbackProgressStepTile extends StatelessWidget {
  const _FeedbackProgressStepTile({
    required this.step,
  });

  final _ProgressStep step;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = step.isActive
        ? AppColors.sage.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.75);
    final borderColor = step.isActive
        ? AppColors.sage.withValues(alpha: 0.24)
        : AppColors.earthSoft.withValues(alpha: 0.18);
    final labelColor = step.isActive ? AppColors.ink : AppColors.inkSoft;

    return Semantics(
      label: step.label,
      selected: step.isActive,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: step.isActive
                    ? AppColors.sage
                    : AppColors.cream2.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: step.isCompleted
                    ? Icon(
                        step.isTerminal
                            ? Icons.flag_rounded
                            : Icons.check_rounded,
                        size: 16,
                        color: step.isActive ? Colors.white : AppColors.inkSoft,
                      )
                    : Text(
                        step.index.toString(),
                        style: AppTextStyles.welcomeSub.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color:
                              step.isActive ? Colors.white : AppColors.inkSoft,
                          height: 1,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.label,
                    style: AppTextStyles.authTitle.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: labelColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.index == 1
                        ? context.l10n.feedbackProgressSubmittedSubtitle
                        : step.index == 2
                            ? context.l10n.feedbackProgressInReviewSubtitle
                            : context.l10n.feedbackProgressTerminalSubtitle,
                    style: AppTextStyles.welcomeSub.copyWith(
                      fontSize: 11.5,
                      height: 1.35,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressConnector extends StatelessWidget {
  const _ProgressConnector({
    required this.active,
  });

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: active ? AppColors.sage : AppColors.earthSoft,
          ),
          Container(
            width: 2,
            height: 18,
            decoration: BoxDecoration(
              color: active
                  ? AppColors.sage.withValues(alpha: 0.45)
                  : AppColors.earthSoft.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressStep {
  const _ProgressStep({
    required this.index,
    required this.label,
    required this.isActive,
    required this.isCompleted,
    this.isTerminal = false,
  });

  final int index;
  final String label;
  final bool isActive;
  final bool isCompleted;
  final bool isTerminal;
}
