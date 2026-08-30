import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../utils/app_theme.dart';
import '../../domain/feedback_category.dart';
import '../../domain/feedback_report.dart';
import '../../domain/feedback_status.dart';
import '../mock/feedback_mock_reports.dart';
import '../widgets/feedback_progress_indicator.dart';
import '../widgets/feedback_status_chip.dart';

class FeedbackSuccessScreen extends StatelessWidget {
  const FeedbackSuccessScreen({
    super.key,
    this.report,
  });

  static const route = '/feedback/success';

  final FeedbackReport? report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final resolvedReport =
        report ?? FeedbackMockReports.fallbackSubmittedReport;
    final categoryLabel = _categoryLabel(l10n, resolvedReport.category);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        surfaceTintColor: AppColors.cream,
        elevation: 0,
        centerTitle: true,
        title: Text(l10n.feedbackSuccessTitle),
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
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.sage.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.verified_outlined,
                      color: AppColors.sage,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.feedbackSuccessTitle,
                    style: AppTextStyles.welcomeTitle.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.feedbackSuccessBody,
                    style: AppTextStyles.welcomeSub.copyWith(
                      fontSize: 14,
                      height: 1.55,
                    ),
                  ),
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
                  Text(
                    l10n.feedbackSuccessSummaryLabel,
                    style: AppTextStyles.fieldLabel.copyWith(
                      color: AppColors.earth,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              categoryLabel,
                              style: AppTextStyles.authTitle.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.feedbackSuccessCanEditDelete,
                              style: AppTextStyles.welcomeSub.copyWith(
                                fontSize: 13.5,
                                height: 1.45,
                                color: AppColors.inkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      FeedbackStatusChip(status: FeedbackStatus.submitted),
                    ],
                  ),
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
                    l10n.feedbackSuccessProgressLabel,
                    style: AppTextStyles.fieldLabel.copyWith(
                      color: AppColors.earth,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FeedbackProgressIndicator(status: FeedbackStatus.submitted),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pushNamed(
                  '/feedback/mine',
                );
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(l10n.feedbackSuccessMineAction),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).popUntil(
                  (route) => route.settings.name == '/feedback',
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(l10n.feedbackSuccessHomeAction),
            ),
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
