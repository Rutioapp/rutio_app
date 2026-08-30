import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../utils/app_theme.dart';
import '../../domain/feedback_category.dart';
import '../../domain/feedback_report.dart';
import '../../domain/feedback_status.dart';
import '../mock/feedback_mock_reports.dart';
import '../widgets/feedback_status_chip.dart';

class MyFeedbackScreen extends StatefulWidget {
  const MyFeedbackScreen({super.key});

  static const route = '/feedback/mine';

  @override
  State<MyFeedbackScreen> createState() => _MyFeedbackScreenState();
}

class _MyFeedbackScreenState extends State<MyFeedbackScreen> {
  FeedbackMineFilter _filter = FeedbackMineFilter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reports = _filteredReports();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        surfaceTintColor: AppColors.cream,
        elevation: 0,
        centerTitle: true,
        title: Text(l10n.feedbackMineTitle),
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
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.sage.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.inbox_outlined,
                      color: AppColors.sage,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.feedbackMineHeading,
                    style: AppTextStyles.welcomeTitle.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.feedbackMineIntro,
                    style: AppTextStyles.welcomeSub.copyWith(
                      fontSize: 14,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _FilterChip(
                  label: l10n.feedbackFilterAll,
                  selected: _filter == FeedbackMineFilter.all,
                  onTap: () => setState(() => _filter = FeedbackMineFilter.all),
                ),
                _FilterChip(
                  label: l10n.feedbackFilterSubmitted,
                  selected: _filter == FeedbackMineFilter.submitted,
                  onTap: () =>
                      setState(() => _filter = FeedbackMineFilter.submitted),
                ),
                _FilterChip(
                  label: l10n.feedbackFilterInReview,
                  selected: _filter == FeedbackMineFilter.inReview,
                  onTap: () =>
                      setState(() => _filter = FeedbackMineFilter.inReview),
                ),
                _FilterChip(
                  label: l10n.feedbackFilterClosed,
                  selected: _filter == FeedbackMineFilter.closed,
                  onTap: () =>
                      setState(() => _filter = FeedbackMineFilter.closed),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (reports.isEmpty)
              _EmptyState(message: l10n.feedbackMineEmptyState)
            else
              ...reports.map(
                (report) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _FeedbackReportCard(
                    report: report,
                    onTap: () => Navigator.of(context).pushNamed(
                      '/feedback/detail',
                      arguments: report,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<FeedbackReport> _filteredReports() {
    final reports = FeedbackMockReports.mineReports();

    return reports.where((report) {
      switch (_filter) {
        case FeedbackMineFilter.all:
          return true;
        case FeedbackMineFilter.submitted:
          return report.status == FeedbackStatus.submitted;
        case FeedbackMineFilter.inReview:
          return report.status == FeedbackStatus.inReview;
        case FeedbackMineFilter.closed:
          return report.status == FeedbackStatus.resolved ||
              report.status == FeedbackStatus.dismissed;
      }
    }).toList(growable: false);
  }
}

class _FeedbackReportCard extends StatelessWidget {
  const _FeedbackReportCard({
    required this.report,
    required this.onTap,
  });

  final FeedbackReport report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);
    final formattedDate = localizations.formatMediumDate(report.createdAt);
    final categoryLabel = _categoryLabel(l10n, report.category);
    final excerpt = report.description.trim();
    final responseAvailable = report.hasTeamResponse;

    return Material(
      color: Colors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoryLabel,
                          style: AppTextStyles.authTitle.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          excerpt,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.welcomeSub.copyWith(
                            fontSize: 13.5,
                            height: 1.45,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FeedbackStatusChip(status: report.status),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 15,
                    color: AppColors.inkSoft,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formattedDate,
                    style: AppTextStyles.welcomeSub.copyWith(
                      fontSize: 12,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  const Spacer(),
                  if (responseAvailable)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.sage.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        l10n.feedbackResponseAvailableBadge,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.sage,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      labelStyle: AppTextStyles.welcomeSub.copyWith(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: selected ? AppColors.ink : AppColors.inkSoft,
      ),
      selectedColor: AppColors.sage.withValues(alpha: 0.16),
      backgroundColor: Colors.white.withValues(alpha: 0.72),
      shape: StadiumBorder(
        side: BorderSide(
          color: selected
              ? AppColors.sage.withValues(alpha: 0.28)
              : AppColors.earthSoft.withValues(alpha: 0.18),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.earthSoft.withValues(alpha: 0.16)),
      ),
      child: Text(
        message,
        style: AppTextStyles.welcomeSub.copyWith(
          fontSize: 13.5,
          height: 1.5,
          color: AppColors.inkSoft,
        ),
      ),
    );
  }
}

enum FeedbackMineFilter {
  all,
  submitted,
  inReview,
  closed,
}
