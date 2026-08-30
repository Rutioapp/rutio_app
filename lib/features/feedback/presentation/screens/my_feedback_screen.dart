import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../data/repositories/repository_result.dart';
import '../../../../l10n/l10n.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../utils/app_theme.dart';
import '../../application/my_feedback_controller.dart';
import '../../application/feedback_mutation_result.dart';
import '../../data/feedback_repository.dart';
import '../../domain/feedback_category.dart';
import '../../domain/feedback_report.dart';
import '../widgets/feedback_status_chip.dart';

class MyFeedbackScreen extends StatefulWidget {
  const MyFeedbackScreen({
    super.key,
    this.controller,
    this.repository,
    this.currentUserIdProvider,
  });

  static const route = '/feedback/mine';

  final FeedbackMineController? controller;
  final FeedbackRepository? repository;
  final FeedbackCurrentUserIdProvider? currentUserIdProvider;

  @override
  State<MyFeedbackScreen> createState() => _MyFeedbackScreenState();
}

class _MyFeedbackScreenState extends State<MyFeedbackScreen> {
  late final FeedbackMineController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ??
        FeedbackMineController(
          repository: widget.repository,
          currentUserIdProvider: widget.currentUserIdProvider,
        );

    if (_controller.state.status == FeedbackMineStatus.initial) {
      unawaited(_controller.load());
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

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
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final state = _controller.state;
            final visibleReports = _controller.visibleReports;

            return RefreshIndicator(
              onRefresh: _controller.refresh,
              color: AppColors.sage,
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                children: [
                  _HeaderCard(
                    heading: l10n.feedbackMineHeading,
                    intro: l10n.feedbackMineIntro,
                  ),
                  const SizedBox(height: 18),
                  _FilterRow(
                    currentFilter: _controller.filter,
                    onFilterSelected: _controller.setFilter,
                  ),
                  const SizedBox(height: 16),
                  _StateSection(
                    state: state,
                    visibleReports: visibleReports,
                    onRetry: _controller.retry,
                    onReportTap: _openDetail,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openDetail(
    BuildContext context,
    FeedbackReport report,
  ) async {
    final result = await Navigator.of(context).pushNamed(
      '/feedback/detail',
      arguments: report,
    );

    if (!mounted) return;

    if (result is FeedbackMutationResult && result.shouldRefreshMyFeedback) {
      await _controller.refresh();
    }
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.heading,
    required this.intro,
  });

  final String heading;
  final String intro;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            heading,
            style: AppTextStyles.welcomeTitle.copyWith(fontSize: 28),
          ),
          const SizedBox(height: 10),
          Text(
            intro,
            style: AppTextStyles.welcomeSub.copyWith(
              fontSize: 14,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.currentFilter,
    required this.onFilterSelected,
  });

  final FeedbackMineFilter currentFilter;
  final ValueChanged<FeedbackMineFilter> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _FilterChip(
          label: l10n.feedbackFilterAll,
          selected: currentFilter == FeedbackMineFilter.all,
          onTap: () => onFilterSelected(FeedbackMineFilter.all),
        ),
        _FilterChip(
          label: l10n.feedbackFilterSubmitted,
          selected: currentFilter == FeedbackMineFilter.submitted,
          onTap: () => onFilterSelected(FeedbackMineFilter.submitted),
        ),
        _FilterChip(
          label: l10n.feedbackFilterInReview,
          selected: currentFilter == FeedbackMineFilter.inReview,
          onTap: () => onFilterSelected(FeedbackMineFilter.inReview),
        ),
        _FilterChip(
          label: l10n.feedbackFilterClosed,
          selected: currentFilter == FeedbackMineFilter.closed,
          onTap: () => onFilterSelected(FeedbackMineFilter.closed),
        ),
      ],
    );
  }
}

class _StateSection extends StatelessWidget {
  const _StateSection({
    required this.state,
    required this.visibleReports,
    required this.onRetry,
    required this.onReportTap,
  });

  final FeedbackMineState state;
  final List<FeedbackReport> visibleReports;
  final Future<void> Function() onRetry;
  final Future<void> Function(BuildContext context, FeedbackReport report)
      onReportTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    switch (state.status) {
      case FeedbackMineStatus.initial:
      case FeedbackMineStatus.loading:
        return const _LoadingState();
      case FeedbackMineStatus.error:
        return _ErrorState(
          message: _errorMessage(l10n, state.error),
          onRetry: onRetry,
        );
      case FeedbackMineStatus.empty:
        return _EmptyState(message: l10n.feedbackMineEmptyState);
      case FeedbackMineStatus.loaded:
        if (visibleReports.isEmpty) {
          return _EmptyState(message: l10n.feedbackMineFilteredEmptyState);
        }
        return Column(
          children: [
            for (final report in visibleReports)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _FeedbackReportCard(
                  report: report,
                  onTap: () => onReportTap(context, report),
                ),
              ),
          ],
        );
    }
  }

  String _errorMessage(
    AppLocalizations l10n,
    RepositoryError? error,
  ) {
    switch (error?.code) {
      case RepositoryErrorCode.notAuthenticated:
        return l10n.feedbackMineErrorSessionExpired;
      case RepositoryErrorCode.network:
        return l10n.feedbackMineErrorNetwork;
      case RepositoryErrorCode.permissionDenied:
      case RepositoryErrorCode.invalidResponse:
      case RepositoryErrorCode.notFound:
      case RepositoryErrorCode.unknown:
      case null:
        return l10n.feedbackMineErrorGeneric;
    }
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

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.earthSoft.withValues(alpha: 0.16)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          const CircularProgressIndicator(
            color: AppColors.sage,
          ),
          const SizedBox(height: 14),
          Text(
            l10n.feedbackMineLoadingState,
            textAlign: TextAlign.center,
            style: AppTextStyles.welcomeSub.copyWith(
              fontSize: 13.5,
              height: 1.45,
              color: AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.earthSoft.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.feedbackMineErrorTitle,
            style: AppTextStyles.authTitle.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: AppTextStyles.welcomeSub.copyWith(
              fontSize: 13.5,
              height: 1.45,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              unawaited(onRetry());
            },
            child: Text(l10n.feedbackMineRetryAction),
          ),
        ],
      ),
    );
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
