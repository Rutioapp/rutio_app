import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../utils/app_theme.dart';
import '../../domain/feedback_category.dart';
import '../../domain/feedback_report.dart';
import '../../domain/feedback_status.dart';
import '../widgets/feedback_progress_indicator.dart';
import '../widgets/feedback_response_card.dart';
import '../widgets/feedback_status_chip.dart';

class FeedbackDetailScreen extends StatelessWidget {
  const FeedbackDetailScreen({
    super.key,
    required this.report,
  });

  static const route = '/feedback/detail';

  final FeedbackReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localizations = MaterialLocalizations.of(context);
    final resolvedReport = report;
    final categoryLabel = _categoryLabel(l10n, resolvedReport.category);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        surfaceTintColor: AppColors.cream,
        elevation: 0,
        centerTitle: true,
        title: Text(l10n.feedbackDetailTitle),
      ),
      body: SafeArea(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFDFBF5),
                    Color(0xFFF0E6D2),
                  ],
                ),
                border: Border.all(
                  color: AppColors.earthSoft.withValues(alpha: 0.16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: AppColors.sage.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.description_outlined,
                          color: AppColors.sage,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              categoryLabel,
                              style: AppTextStyles.welcomeTitle.copyWith(
                                fontSize: 26,
                              ),
                            ),
                            const SizedBox(height: 8),
                            FeedbackStatusChip(status: resolvedReport.status),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FeedbackProgressIndicator(status: resolvedReport.status),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.earthSoft.withValues(alpha: 0.16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(
                    label: l10n.feedbackDetailSentDateLabel,
                    value: localizations
                        .formatMediumDate(resolvedReport.createdAt),
                  ),
                  if (resolvedReport.reviewStartedAt != null) ...[
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: l10n.feedbackDetailReviewDateLabel,
                      value: localizations.formatMediumDate(
                        resolvedReport.reviewStartedAt!,
                      ),
                    ),
                  ],
                  if (resolvedReport.closedAt != null) ...[
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: l10n.feedbackDetailClosedDateLabel,
                      value: localizations.formatMediumDate(
                        resolvedReport.closedAt!,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.earthSoft.withValues(alpha: 0.16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.feedbackDetailDescriptionLabel,
                    style: AppTextStyles.fieldLabel.copyWith(
                      color: AppColors.earth,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    resolvedReport.description.trim(),
                    style: AppTextStyles.welcomeSub.copyWith(
                      fontSize: 14,
                      height: 1.55,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            if (resolvedReport.hasScreenshot) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppColors.earthSoft.withValues(alpha: 0.16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.feedbackDetailScreenshotLabel,
                      style: AppTextStyles.fieldLabel.copyWith(
                        color: AppColors.earth,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.sage.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.sage.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.image_outlined,
                              color: AppColors.sage,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              l10n.feedbackDetailScreenshotPlaceholder(
                                resolvedReport.screenshotPath ?? '',
                              ),
                              style: AppTextStyles.welcomeSub.copyWith(
                                fontSize: 13.5,
                                height: 1.45,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            FeedbackResponseCard(response: resolvedReport.teamResponse),
            if (resolvedReport.status == FeedbackStatus.submitted) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppColors.earthSoft.withValues(alpha: 0.16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.feedbackDetailActionsLabel,
                      style: AppTextStyles.fieldLabel.copyWith(
                        color: AppColors.earth,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            child: Text(l10n.feedbackEditAction),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.tonal(
                            onPressed: () {},
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            child: Text(l10n.feedbackDeleteAction),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _categoryLabel(AppLocalizations l10n, FeedbackCategory category) {
    switch (category) {
      case FeedbackCategory.bug:
        return l10n.feedbackCategoryBugTitle;
      case FeedbackCategory.suggestion:
        return l10n.feedbackCategorySuggestionTitle;
      case FeedbackCategory.improvement:
        return l10n.feedbackCategoryImprovementTitle;
      case FeedbackCategory.other:
        return l10n.feedbackCategoryOtherTitle;
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: AppTextStyles.fieldLabel.copyWith(
              color: AppColors.earth,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 6,
          child: Text(
            value,
            style: AppTextStyles.welcomeSub.copyWith(
              fontSize: 13.5,
              height: 1.45,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}
