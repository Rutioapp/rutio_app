import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../utils/app_theme.dart';
import '../../domain/feedback_status.dart';

class FeedbackStatusChip extends StatelessWidget {
  const FeedbackStatusChip({
    super.key,
    required this.status,
  });

  final FeedbackStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final data = _statusData(l10n, status);

    return Semantics(
      label: data.semanticLabel,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: data.backgroundColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: data.borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(data.icon, size: 16, color: data.foregroundColor),
            const SizedBox(width: 6),
            Text(
              data.label,
              style: AppTextStyles.welcomeSub.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: data.foregroundColor,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _StatusChipData _statusData(
    AppLocalizations l10n,
    FeedbackStatus status,
  ) {
    switch (status) {
      case FeedbackStatus.submitted:
        return _StatusChipData(
          label: l10n.feedbackStatusSubmitted,
          semanticLabel: l10n.feedbackStatusSubmitted,
          icon: Icons.send_outlined,
          foregroundColor: AppColors.earth,
          backgroundColor: AppColors.earth.withValues(alpha: 0.12),
          borderColor: AppColors.earth.withValues(alpha: 0.22),
        );
      case FeedbackStatus.inReview:
        return _StatusChipData(
          label: l10n.feedbackStatusInReview,
          semanticLabel: l10n.feedbackStatusInReview,
          icon: Icons.visibility_outlined,
          foregroundColor: AppColors.sage,
          backgroundColor: AppColors.sage.withValues(alpha: 0.12),
          borderColor: AppColors.sage.withValues(alpha: 0.22),
        );
      case FeedbackStatus.resolved:
        return _StatusChipData(
          label: l10n.feedbackStatusResolved,
          semanticLabel: l10n.feedbackStatusResolved,
          icon: Icons.check_circle_outline,
          foregroundColor: AppColors.sage,
          backgroundColor: AppColors.sage.withValues(alpha: 0.14),
          borderColor: AppColors.sage.withValues(alpha: 0.25),
        );
      case FeedbackStatus.dismissed:
        return _StatusChipData(
          label: l10n.feedbackStatusDismissed,
          semanticLabel: l10n.feedbackStatusDismissed,
          icon: Icons.block_outlined,
          foregroundColor: AppColors.rust,
          backgroundColor: AppColors.rust.withValues(alpha: 0.12),
          borderColor: AppColors.rust.withValues(alpha: 0.22),
        );
    }
  }
}

class _StatusChipData {
  const _StatusChipData({
    required this.label,
    required this.semanticLabel,
    required this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  final String label;
  final String semanticLabel;
  final IconData icon;
  final Color foregroundColor;
  final Color backgroundColor;
  final Color borderColor;
}
