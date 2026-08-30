import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../data/repositories/repository_result.dart';
import '../../../../l10n/l10n.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../utils/app_theme.dart';
import '../../application/feedback_edit_controller.dart';
import '../../application/feedback_form_controller.dart';
import '../../application/feedback_mutation_result.dart';
import '../../data/feedback_image_service.dart';
import '../../data/feedback_repository.dart';
import '../../data/feedback_storage_service.dart';
import '../../domain/feedback_category.dart';
import '../../domain/feedback_report.dart';
import '../widgets/feedback_category_card.dart';
import '../widgets/feedback_status_chip.dart';

class FeedbackEditScreen extends StatefulWidget {
  const FeedbackEditScreen({
    super.key,
    required this.report,
    this.controller,
    this.repository,
    this.imageService,
    this.storageService,
    this.currentUserIdProvider,
  });

  static const route = '/feedback/edit';

  final FeedbackReport report;
  final FeedbackEditController? controller;
  final FeedbackRepository? repository;
  final FeedbackImageService? imageService;
  final FeedbackStorageService? storageService;
  final FeedbackCurrentUserIdProvider? currentUserIdProvider;

  @override
  State<FeedbackEditScreen> createState() => _FeedbackEditScreenState();
}

class _FeedbackEditScreenState extends State<FeedbackEditScreen> {
  late final FeedbackEditController _controller;
  late final bool _ownsController;
  late final FeedbackStorageService _storageService;
  Future<String>? _currentScreenshotSignedUrlFuture;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _storageService = widget.storageService ??
        FeedbackStorageService(
          currentUserIdProvider: widget.currentUserIdProvider,
        );
    _controller = widget.controller ??
        FeedbackEditController(
          report: widget.report,
          repository: widget.repository,
          imageService: widget.imageService,
          storageService: widget.storageService,
          currentUserIdProvider: widget.currentUserIdProvider,
        );
    _refreshCurrentScreenshotFuture();
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _refreshCurrentScreenshotFuture() {
    final path = _controller.currentScreenshotPath;
    if (path == null) {
      _currentScreenshotSignedUrlFuture = null;
      return;
    }

    _currentScreenshotSignedUrlFuture = _storageService.createSignedScreenshotUrl(
      path: path,
    );
  }

  Future<void> _handleSave(BuildContext context) async {
    final result = await _controller.save();
    if (!context.mounted || result == null) return;

    if (result.isSuccess && result.data != null) {
      Navigator.of(context).pop(FeedbackMutationResult.saved(result.data!));
      return;
    }

    final error = result.error;
    if (_isNoLongerEditable(error)) {
      Navigator.of(context).pop(FeedbackMutationResult.stale(
        error ??
            const RepositoryError(
              code: RepositoryErrorCode.permissionDenied,
              message: 'This feedback is no longer editable.',
            ),
      ));
      return;
    }

    if (_controller.imageIssue != null) {
      return;
    }

    _showSaveError(context, error);
  }

  Future<bool> _confirmDiscard(BuildContext context) async {
    final l10n = context.l10n;
    final platform = Theme.of(context).platform;

    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      final result = await showCupertinoDialog<bool>(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: Text(l10n.feedbackExitConfirmTitle),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(l10n.feedbackExitConfirmMessage),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.feedbackExitConfirmStay),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.feedbackExitConfirmLeave),
            ),
          ],
        ),
      );
      return result == true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.feedbackExitConfirmTitle),
        content: Text(l10n.feedbackExitConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.feedbackExitConfirmStay),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.feedbackExitConfirmLeave),
          ),
        ],
      ),
    );

    return result == true;
  }

  Future<void> _retryCurrentScreenshot() async {
    setState(() {
      _refreshCurrentScreenshotFuture();
    });
    final future = _currentScreenshotSignedUrlFuture;
    if (future != null) {
      await future;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final category = _controller.category;
    final categoryHelp = _categoryHelpText(l10n, category);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return PopScope(
          canPop: !_controller.isDirty && !_controller.isSaving,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop || _controller.isSaving) return;
            if (!_controller.isDirty) return;

            final shouldDiscard = await _confirmDiscard(context);
            if (shouldDiscard && context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Scaffold(
            backgroundColor: AppColors.cream,
            appBar: AppBar(
              backgroundColor: AppColors.cream,
              surfaceTintColor: AppColors.cream,
              elevation: 0,
              centerTitle: true,
              title: Text(l10n.feedbackEditTitle),
            ),
            body: SafeArea(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(18, 14, 18, 24 + bottomInset),
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
                                Icons.edit_outlined,
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
                                    l10n.feedbackEditTitle,
                                    style: AppTextStyles.welcomeTitle.copyWith(
                                      fontSize: 26,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  FeedbackStatusChip(status: _controller.report.status),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l10n.feedbackEditIntro,
                          style: AppTextStyles.welcomeSub.copyWith(
                            fontSize: 14,
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l10n.feedbackCategorySectionTitle,
                    style: AppTextStyles.fieldLabel.copyWith(
                      color: AppColors.earth,
                    ),
                  ),
                  const SizedBox(height: 10),
                  IgnorePointer(
                    child: FeedbackCategoryCard(
                      title: _categoryTitle(l10n, category),
                      subtitle: categoryHelp,
                      icon: _categoryIcon(category),
                      selected: true,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.feedbackEditCategoryLockedNote,
                    style: AppTextStyles.welcomeSub.copyWith(
                      fontSize: 11.5,
                      color: AppColors.inkSoft,
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
                          l10n.feedbackDescriptionLabel,
                          style: AppTextStyles.fieldLabel.copyWith(
                            color: AppColors.earth,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          categoryHelp,
                          style: AppTextStyles.welcomeSub.copyWith(
                            fontSize: 13.5,
                            height: 1.45,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _controller.descriptionController,
                          onChanged: _controller.setDescription,
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.newline,
                          maxLines: 8,
                          minLines: 5,
                          maxLength: feedbackDescriptionMaxLength,
                          decoration: InputDecoration(
                            hintText: l10n.feedbackDescriptionHint,
                            alignLabelWithHint: true,
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.feedbackDescriptionRequirements,
                                style: AppTextStyles.welcomeSub.copyWith(
                                  fontSize: 11.5,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              l10n.feedbackDescriptionCounter(
                                _controller.descriptionLength,
                                feedbackDescriptionMaxLength,
                              ),
                              style: AppTextStyles.welcomeSub.copyWith(
                                fontSize: 11.5,
                                color: _controller.isDescriptionValid
                                    ? AppColors.inkSoft
                                    : AppColors.rust,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _FeedbackEditScreenshotCard(
                    controller: _controller,
                    currentSignedUrlFuture: _currentScreenshotSignedUrlFuture,
                    onRetryCurrentScreenshot: _retryCurrentScreenshot,
                    onSelectScreenshot: _controller.canEditScreenshot
                        ? _controller.selectScreenshot
                        : null,
                    onRemoveScreenshot: _controller.canEditScreenshot &&
                            (_controller.hasSelectedScreenshot ||
                                _controller.hasExistingScreenshot)
                        ? _controller.removeScreenshot
                        : null,
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppColors.earthSoft.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.feedbackContactTitle,
                          style: AppTextStyles.authTitle.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.feedbackContactDescription,
                          style: AppTextStyles.welcomeSub.copyWith(
                            fontSize: 13.5,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.feedbackContactSwitchLabel,
                                style: AppTextStyles.authSub.copyWith(
                                  fontSize: 13.5,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            Switch.adaptive(
                              value: _controller.contactAllowed,
                              onChanged: _controller.setContactAllowed,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.feedbackTechnicalNote,
                          style: AppTextStyles.welcomeSub.copyWith(
                            fontSize: 11.5,
                            color: AppColors.inkSoft,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _controller.canSave
                        ? () => _handleSave(context)
                        : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: _controller.isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(l10n.feedbackEditSaveAction),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isNoLongerEditable(RepositoryError? error) {
    return error?.code == RepositoryErrorCode.permissionDenied ||
        error?.code == RepositoryErrorCode.notFound;
  }

  void _showSaveError(
    BuildContext context,
    RepositoryError? error,
  ) {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final message = switch (error?.code) {
      RepositoryErrorCode.notAuthenticated =>
        l10n.feedbackMineErrorSessionExpired,
      RepositoryErrorCode.network => l10n.feedbackMineErrorNetwork,
      RepositoryErrorCode.permissionDenied =>
        l10n.feedbackEditErrorNoLongerEditable,
      RepositoryErrorCode.notFound => l10n.feedbackEditErrorNoLongerEditable,
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

  String _categoryTitle(AppLocalizations l10n, FeedbackCategory category) {
    return switch (category) {
      FeedbackCategory.bug => l10n.feedbackCategoryBugTitle,
      FeedbackCategory.suggestion => l10n.feedbackCategorySuggestionTitle,
      FeedbackCategory.improvement => l10n.feedbackCategoryImprovementTitle,
      FeedbackCategory.other => l10n.feedbackCategoryOtherTitle,
    };
  }

  String _categoryHelpText(
    AppLocalizations l10n,
    FeedbackCategory category,
  ) {
    return switch (category) {
      FeedbackCategory.bug => l10n.feedbackCategoryBugHelp,
      FeedbackCategory.suggestion => l10n.feedbackCategorySuggestionHelp,
      FeedbackCategory.improvement => l10n.feedbackCategoryImprovementHelp,
      FeedbackCategory.other => l10n.feedbackCategoryOtherHelp,
    };
  }

  IconData _categoryIcon(FeedbackCategory category) {
    return switch (category) {
      FeedbackCategory.bug => Icons.bug_report_outlined,
      FeedbackCategory.suggestion => Icons.lightbulb_outline_rounded,
      FeedbackCategory.improvement => Icons.tune_rounded,
      FeedbackCategory.other => Icons.chat_bubble_outline_rounded,
    };
  }
}

class _FeedbackEditScreenshotCard extends StatelessWidget {
  const _FeedbackEditScreenshotCard({
    required this.controller,
    required this.currentSignedUrlFuture,
    required this.onRetryCurrentScreenshot,
    required this.onSelectScreenshot,
    required this.onRemoveScreenshot,
  });

  final FeedbackEditController controller;
  final Future<String>? currentSignedUrlFuture;
  final Future<void> Function() onRetryCurrentScreenshot;
  final Future<void> Function()? onSelectScreenshot;
  final VoidCallback? onRemoveScreenshot;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasLocalSelection = controller.hasSelectedScreenshot;
    final hasVisibleCurrentScreenshot = controller.hasVisibleCurrentScreenshot;

    Widget preview;
    if (hasLocalSelection) {
      preview = _LocalScreenshotPreview(
        previewBytes: controller.selectedScreenshotPreviewBytes!,
      );
    } else if (hasVisibleCurrentScreenshot && currentSignedUrlFuture != null) {
      preview = FutureBuilder<String>(
        future: currentSignedUrlFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _ScreenshotPlaceholder(
              icon: Icons.downloading_outlined,
              message: l10n.feedbackDetailScreenshotLoading,
              child: const CircularProgressIndicator(
                color: AppColors.sage,
              ),
            );
          }

          if (snapshot.hasError || snapshot.data == null) {
            return _ScreenshotPlaceholder(
              icon: Icons.broken_image_outlined,
              message: l10n.feedbackDetailScreenshotError,
              actionLabel: l10n.feedbackDetailRetryAction,
              onAction: () {
                unawaited(onRetryCurrentScreenshot());
              },
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
                child: Image.network(
                  snapshot.data!,
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
                        unawaited(onRetryCurrentScreenshot());
                      },
                    );
                  },
                ),
              ),
            ),
          );
        },
      );
    } else {
      preview = _ScreenshotPlaceholder(
        icon: Icons.image_outlined,
        message: l10n.feedbackEditNoScreenshot,
      );
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
            l10n.feedbackDetailScreenshotLabel,
            style: AppTextStyles.fieldLabel.copyWith(
              color: AppColors.earth,
            ),
          ),
          const SizedBox(height: 10),
          preview,
          const SizedBox(height: 12),
          if (controller.canEditScreenshot)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.tonal(
                  onPressed: onSelectScreenshot == null
                      ? null
                      : () {
                          unawaited(onSelectScreenshot!());
                        },
                  child: Text(
                    hasLocalSelection || hasVisibleCurrentScreenshot
                        ? l10n.feedbackScreenshotReplaceAction
                        : l10n.feedbackScreenshotSelectAction,
                  ),
                ),
                if (hasLocalSelection || hasVisibleCurrentScreenshot)
                  TextButton(
                    onPressed: onRemoveScreenshot,
                    child: Text(l10n.feedbackScreenshotRemoveAction),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _LocalScreenshotPreview extends StatelessWidget {
  const _LocalScreenshotPreview({
    required this.previewBytes,
  });

  final Uint8List previewBytes;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Image.memory(
          previewBytes,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
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

