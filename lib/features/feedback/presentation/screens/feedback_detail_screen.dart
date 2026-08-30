import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../data/repositories/repository_result.dart';
import '../../../../l10n/l10n.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../utils/app_theme.dart';
import '../../application/feedback_detail_controller.dart';
import '../../application/feedback_mutation_result.dart';
import '../../data/feedback_repository.dart';
import '../../data/feedback_storage_service.dart';
import '../../data/supabase_feedback_repository.dart';
import '../../domain/feedback_category.dart';
import '../../domain/feedback_report.dart';
import 'feedback_edit_screen.dart';
import '../widgets/feedback_progress_indicator.dart';
import '../widgets/feedback_response_card.dart';
import '../widgets/feedback_status_chip.dart';

class FeedbackDetailScreen extends StatefulWidget {
  const FeedbackDetailScreen({
    super.key,
    required this.report,
    this.controller,
    this.repository,
    this.storageService,
    this.currentUserIdProvider,
    this.screenshotPreviewBuilder,
  });

  static const route = '/feedback/detail';

  final FeedbackReport report;
  final FeedbackDetailController? controller;
  final FeedbackRepository? repository;
  final FeedbackStorageService? storageService;
  final FeedbackCurrentUserIdProvider? currentUserIdProvider;
  final Widget Function(BuildContext context, String signedUrl)?
      screenshotPreviewBuilder;

  @override
  State<FeedbackDetailScreen> createState() => _FeedbackDetailScreenState();
}

class _FeedbackDetailScreenState extends State<FeedbackDetailScreen> {
  late final FeedbackDetailController _controller;
  late final bool _ownsController;
  FeedbackRepository? _repositoryInstance;
  FeedbackStorageService? _storageServiceInstance;
  FeedbackMutationResult? _pendingMyFeedbackResult;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ??
        FeedbackDetailController(
          repository: _repository,
          storageService: _storageService,
          currentUserIdProvider: widget.currentUserIdProvider,
        );

    if (_controller.state.status == FeedbackDetailStatus.initial) {
      unawaited(
        _controller.load(
          widget.report.id,
          initialReport: widget.report,
        ),
      );
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  FeedbackRepository get _repository =>
      _repositoryInstance ??=
          widget.repository ??
          SupabaseFeedbackRepository(
            currentUserIdProvider: widget.currentUserIdProvider,
          );

  FeedbackStorageService get _storageService =>
      _storageServiceInstance ??=
          widget.storageService ??
          FeedbackStorageService(
            currentUserIdProvider: widget.currentUserIdProvider,
          );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _isDeleting) return;
        Navigator.of(context).pop(_pendingMyFeedbackResult);
      },
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.cream,
          surfaceTintColor: AppColors.cream,
          elevation: 0,
          centerTitle: true,
          title: Text(l10n.feedbackDetailTitle),
        ),
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final state = _controller.state;
              final report = state.report;

              return RefreshIndicator(
                onRefresh: _controller.refresh,
                color: AppColors.sage,
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                  children: [
                    if (_isDeleting)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: LinearProgressIndicator(
                          color: AppColors.sage,
                          minHeight: 2,
                        ),
                      ),
                    if (state.status == FeedbackDetailStatus.loading &&
                        state.hasReport)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: LinearProgressIndicator(
                          color: AppColors.sage,
                          minHeight: 2,
                        ),
                      ),
                    if (state.status == FeedbackDetailStatus.loading &&
                        !state.hasReport)
                      const _FeedbackDetailLoadingState(),
                    if (state.status == FeedbackDetailStatus.error)
                      _FeedbackDetailMessageState(
                        title: l10n.feedbackDetailErrorTitle,
                        message: _detailErrorMessage(l10n, state.error),
                        actionLabel: l10n.feedbackDetailRetryAction,
                        onAction: _controller.refresh,
                      ),
                    if (state.status == FeedbackDetailStatus.notFound)
                      _FeedbackDetailMessageState(
                        title: l10n.feedbackDetailNotAvailableTitle,
                        message: l10n.feedbackDetailNotAvailableMessage,
                        actionLabel: l10n.feedbackDetailRetryAction,
                        onAction: _controller.refresh,
                      ),
                    if (report != null) ...[
                      _FeedbackDetailHeader(report: report),
                      const SizedBox(height: 18),
                      _FeedbackDetailDates(report: report),
                      const SizedBox(height: 16),
                      _FeedbackDetailDescription(report: report),
                      if (report.hasScreenshot) ...[
                        const SizedBox(height: 16),
                        _FeedbackDetailScreenshot(
                          state: state,
                          onRetry: _controller.retryScreenshot,
                          screenshotPreviewBuilder:
                              widget.screenshotPreviewBuilder,
                        ),
                      ],
                      const SizedBox(height: 16),
                      FeedbackResponseCard(response: report.teamResponse),
                      if (state.canEdit || state.canDelete) ...[
                        const SizedBox(height: 16),
                        _FeedbackDetailActions(
                          showActions: state.canEdit && state.canDelete,
                          isBusy: _isDeleting,
                          onEdit:
                              state.canEdit ? () => _handleEdit(context) : null,
                          onDelete: state.canDelete
                              ? () => _handleDelete(context)
                              : null,
                        ),
                      ],
                    ],
                    if (report == null &&
                        state.status == FeedbackDetailStatus.initial)
                      const _FeedbackDetailLoadingState(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _detailErrorMessage(
    AppLocalizations l10n,
    RepositoryError? error,
  ) {
    switch (error?.code) {
      case RepositoryErrorCode.notFound:
      case RepositoryErrorCode.permissionDenied:
        return l10n.feedbackDetailNotAvailableMessage;
      case RepositoryErrorCode.notAuthenticated:
        return l10n.feedbackDetailNotAvailableMessage;
      case RepositoryErrorCode.network:
      case RepositoryErrorCode.invalidResponse:
      case RepositoryErrorCode.unknown:
      case null:
        return l10n.feedbackDetailLoadErrorMessage;
    }
  }

  Future<void> _handleEdit(BuildContext context) async {
    final report = _controller.state.report;
    if (report == null || _isDeleting) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    final result =
        await navigator.pushNamed<Object?>(
      FeedbackEditScreen.route,
      arguments: report,
    );

    if (!mounted || result is! FeedbackMutationResult) return;
    final mutationResult = result;

    if (mutationResult.isSaved && mutationResult.report != null) {
      await _controller.load(
        mutationResult.report!.id,
        initialReport: mutationResult.report,
      );
      if (!mounted) return;
      _pendingMyFeedbackResult = mutationResult;
      return;
    }

    if (mutationResult.isStale) {
      await _controller.refresh();
      if (!mounted) return;
      _showMutationStaleMessage(
        messenger: messenger,
        l10n: l10n,
        error: mutationResult.error,
      );
      return;
    }
  }

  Future<void> _handleDelete(BuildContext context) async {
    final report = _controller.state.report;
    if (report == null || _isDeleting) return;
    if (!report.canDelete) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    final shouldDelete = await _confirmDelete(context);
    if (!shouldDelete || !mounted) return;

    _isDeleting = true;
    setState(() {});

    try {
      final result = await _repository.deleteMyFeedback(
        feedbackId: report.id,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        final screenshotPath = result.data?.trim().isEmpty == true
            ? null
            : result.data?.trim();
        if (screenshotPath != null) {
          try {
            await _storageService.removeScreenshot(path: screenshotPath);
          } catch (error) {
            if (kDebugMode) {
              debugPrint(
                '[feedback_detail_screen] screenshot cleanup after delete '
                'failed: ${error.runtimeType}',
              );
            }
          }
        }

        navigator.pop(
          FeedbackMutationResult.deleted(screenshotPath: screenshotPath),
        );
        return;
      }

      final error = result.error;
      if (_isNoLongerEditable(error)) {
        await _controller.refresh();
        if (!mounted) return;
        _showMutationStaleMessage(
          messenger: messenger,
          l10n: l10n,
          error: error,
        );
        return;
      }

      _showDeleteError(
        messenger: messenger,
        l10n: l10n,
        error: error,
      );
    } finally {
      if (mounted) {
        _isDeleting = false;
        setState(() {});
      }
    }
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final l10n = context.l10n;
    final platform = Theme.of(context).platform;

    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      final result = await showCupertinoDialog<bool>(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: Text(l10n.feedbackDeleteConfirmTitle),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(l10n.feedbackDeleteConfirmMessage),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.feedbackDeleteConfirmCancel),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.feedbackDeleteConfirmDelete),
            ),
          ],
        ),
      );
      return result == true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.feedbackDeleteConfirmTitle),
        content: Text(l10n.feedbackDeleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.feedbackDeleteConfirmCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.feedbackDeleteConfirmDelete),
          ),
        ],
      ),
    );

    return result == true;
  }

  bool _isNoLongerEditable(RepositoryError? error) {
    return error?.code == RepositoryErrorCode.permissionDenied ||
        error?.code == RepositoryErrorCode.notFound;
  }

  void _showMutationStaleMessage({
    required ScaffoldMessengerState messenger,
    required AppLocalizations l10n,
    RepositoryError? error,
  }) {
    final message = error?.code == RepositoryErrorCode.notFound
        ? l10n.feedbackDetailNotAvailableMessage
        : l10n.feedbackEditErrorNoLongerEditable;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _showDeleteError({
    required ScaffoldMessengerState messenger,
    required AppLocalizations l10n,
    RepositoryError? error,
  }) {
    final message = switch (error?.code) {
      RepositoryErrorCode.notAuthenticated =>
        l10n.feedbackMineErrorSessionExpired,
      RepositoryErrorCode.network => l10n.feedbackMineErrorNetwork,
      RepositoryErrorCode.permissionDenied =>
        l10n.feedbackEditSaveErrorGeneric,
      RepositoryErrorCode.notFound => l10n.feedbackDetailNotAvailableMessage,
      RepositoryErrorCode.invalidResponse => l10n.feedbackEditSaveErrorGeneric,
      RepositoryErrorCode.unknown => l10n.feedbackEditSaveErrorGeneric,
      null => l10n.feedbackEditSaveErrorGeneric,
    };

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _FeedbackDetailHeader extends StatelessWidget {
  const _FeedbackDetailHeader({
    required this.report,
  });

  final FeedbackReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final categoryLabel = _categoryLabel(l10n, report.category);

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
                    FeedbackStatusChip(status: report.status),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FeedbackProgressIndicator(status: report.status),
        ],
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

class _FeedbackDetailDates extends StatelessWidget {
  const _FeedbackDetailDates({
    required this.report,
  });

  final FeedbackReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localizations = MaterialLocalizations.of(context);

    return Container(
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
            value: localizations.formatMediumDate(report.createdAt),
          ),
          if (report.reviewStartedAt != null) ...[
            const SizedBox(height: 12),
            _DetailRow(
              label: l10n.feedbackDetailReviewDateLabel,
              value: localizations.formatMediumDate(report.reviewStartedAt!),
            ),
          ],
          if (report.closedAt != null) ...[
            const SizedBox(height: 12),
            _DetailRow(
              label: l10n.feedbackDetailClosedDateLabel,
              value: localizations.formatMediumDate(report.closedAt!),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeedbackDetailDescription extends StatelessWidget {
  const _FeedbackDetailDescription({
    required this.report,
  });

  final FeedbackReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
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
            report.description.trim(),
            style: AppTextStyles.welcomeSub.copyWith(
              fontSize: 14,
              height: 1.55,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackDetailScreenshot extends StatelessWidget {
  const _FeedbackDetailScreenshot({
    required this.state,
    required this.onRetry,
    this.screenshotPreviewBuilder,
  });

  final FeedbackDetailState state;
  final Future<void> Function() onRetry;
  final Widget Function(BuildContext context, String signedUrl)?
      screenshotPreviewBuilder;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
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
          _ScreenshotContent(
            state: state,
            onRetry: onRetry,
            screenshotPreviewBuilder: screenshotPreviewBuilder,
          ),
        ],
      ),
    );
  }
}

class _ScreenshotContent extends StatelessWidget {
  const _ScreenshotContent({
    required this.state,
    required this.onRetry,
    this.screenshotPreviewBuilder,
  });

  final FeedbackDetailState state;
  final Future<void> Function() onRetry;
  final Widget Function(BuildContext context, String signedUrl)?
      screenshotPreviewBuilder;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (state.isScreenshotLoading) {
      return _ScreenshotPlaceholder(
        icon: Icons.downloading_outlined,
        message: l10n.feedbackDetailScreenshotLoading,
        child: const CircularProgressIndicator(color: AppColors.sage),
      );
    }

    if (state.isScreenshotError) {
      return _ScreenshotPlaceholder(
        icon: Icons.broken_image_outlined,
        message: l10n.feedbackDetailScreenshotError,
        actionLabel: l10n.feedbackDetailRetryAction,
        onAction: () {
          unawaited(onRetry());
        },
      );
    }

    final signedUrl = state.screenshotSignedUrl;
    if (signedUrl == null || signedUrl.trim().isEmpty) {
      return _ScreenshotPlaceholder(
        icon: Icons.image_outlined,
        message: l10n.feedbackDetailScreenshotLoading,
        child: const CircularProgressIndicator(color: AppColors.sage),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.cream2.withValues(alpha: 0.55),
          border: Border.all(
            color: AppColors.earthSoft.withValues(alpha: 0.16),
          ),
        ),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: screenshotPreviewBuilder?.call(context, signedUrl) ??
              Image.network(
                signedUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _ScreenshotPlaceholder(
                    icon: Icons.downloading_outlined,
                    message: l10n.feedbackDetailScreenshotLoading,
                    child: const CircularProgressIndicator(
                      color: AppColors.sage,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return _ScreenshotPlaceholder(
                    icon: Icons.broken_image_outlined,
                    message: l10n.feedbackDetailScreenshotError,
                    actionLabel: l10n.feedbackDetailRetryAction,
                    onAction: () {
                      unawaited(onRetry());
                    },
                  );
                },
              ),
        ),
      ),
    );
  }
}

class _ScreenshotPlaceholder extends StatelessWidget {
  const _ScreenshotPlaceholder({
    required this.icon,
    required this.message,
    this.child,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final Widget? child;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sage.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.sage.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              icon,
              color: AppColors.sage,
              size: 28,
            ),
          ),
          if (child != null) ...[
            const SizedBox(height: 14),
            child!,
          ],
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.welcomeSub.copyWith(
              fontSize: 13.5,
              height: 1.45,
              color: AppColors.ink,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeedbackDetailActions extends StatelessWidget {
  const _FeedbackDetailActions({
    required this.showActions,
    required this.isBusy,
    required this.onEdit,
    required this.onDelete,
  });

  final bool showActions;
  final bool isBusy;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (!showActions) {
      return const SizedBox.shrink();
    }

    return Container(
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
                  key: const ValueKey('feedback-detail-edit-action'),
                  onPressed: isBusy ? null : onEdit,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text(l10n.feedbackEditAction),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: isBusy ? null : onDelete,
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
    );
  }
}
class _FeedbackDetailMessageState extends StatelessWidget {
  const _FeedbackDetailMessageState({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
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
            title,
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
              unawaited(onAction());
            },
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _FeedbackDetailLoadingState extends StatelessWidget {
  const _FeedbackDetailLoadingState();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.earthSoft.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          const CircularProgressIndicator(
            color: AppColors.sage,
          ),
          const SizedBox(height: 14),
          Text(
            l10n.feedbackDetailLoadingState,
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
