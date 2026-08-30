import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../utils/app_theme.dart';
import '../../application/feedback_form_controller.dart';
import '../../data/feedback_image_service.dart';
import '../../domain/feedback_category.dart';
import '../../../../data/repositories/repository_result.dart';
import '../widgets/feedback_category_card.dart';
import '../widgets/feedback_screenshot_field.dart';

class FeedbackFormScreen extends StatefulWidget {
  const FeedbackFormScreen({
    super.key,
    this.controller,
  });

  static const route = '/feedback/new';

  final FeedbackFormController? controller;

  @override
  State<FeedbackFormScreen> createState() => _FeedbackFormScreenState();
}

class _FeedbackFormScreenState extends State<FeedbackFormScreen> {
  late final FeedbackFormController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? FeedbackFormController();
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSubmit(BuildContext context) async {
    final result = await _controller.submit();
    if (!context.mounted || result == null) return;

    if (result.isSuccess && result.data != null) {
      await Navigator.of(context).pushReplacementNamed(
        '/feedback/success',
        arguments: result.data,
      );
      return;
    }

    if (_controller.imageIssue != null) {
      return;
    }

    _showSubmitError(context, result.error);
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final l10n = context.l10n;
        final selectedCategory = _controller.category;
        final categoryHelp = _categoryHelpText(l10n, selectedCategory);
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;

        return PopScope(
          canPop: !_controller.isDirty && !_controller.isSubmitting,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop || _controller.isSubmitting) return;
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
              title: Text(l10n.feedbackNewTitle),
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
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: AppColors.sage.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.forum_outlined,
                            color: AppColors.sage,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.feedbackNewTitle,
                          style: AppTextStyles.welcomeTitle.copyWith(
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.feedbackNewIntro,
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
                  GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.02,
                    children: [
                      FeedbackCategoryCard(
                        key: ValueKey(
                            'feedback-category-${FeedbackCategory.bug.name}'),
                        title: l10n.feedbackCategoryBugTitle,
                        subtitle: l10n.feedbackCategoryBugHelp,
                        icon: Icons.bug_report_outlined,
                        selected: selectedCategory == FeedbackCategory.bug,
                        onTap: () =>
                            _controller.selectCategory(FeedbackCategory.bug),
                      ),
                      FeedbackCategoryCard(
                        key: ValueKey(
                          'feedback-category-${FeedbackCategory.suggestion.name}',
                        ),
                        title: l10n.feedbackCategorySuggestionTitle,
                        subtitle: l10n.feedbackCategorySuggestionHelp,
                        icon: Icons.lightbulb_outline_rounded,
                        selected:
                            selectedCategory == FeedbackCategory.suggestion,
                        onTap: () => _controller
                            .selectCategory(FeedbackCategory.suggestion),
                      ),
                      FeedbackCategoryCard(
                        key: ValueKey(
                          'feedback-category-${FeedbackCategory.improvement.name}',
                        ),
                        title: l10n.feedbackCategoryImprovementTitle,
                        subtitle: l10n.feedbackCategoryImprovementHelp,
                        icon: Icons.tune_rounded,
                        selected:
                            selectedCategory == FeedbackCategory.improvement,
                        onTap: () => _controller
                            .selectCategory(FeedbackCategory.improvement),
                      ),
                      FeedbackCategoryCard(
                        key: ValueKey(
                          'feedback-category-${FeedbackCategory.other.name}',
                        ),
                        title: l10n.feedbackCategoryOtherTitle,
                        subtitle: l10n.feedbackCategoryOtherHelp,
                        icon: Icons.chat_bubble_outline_rounded,
                        selected: selectedCategory == FeedbackCategory.other,
                        onTap: () =>
                            _controller.selectCategory(FeedbackCategory.other),
                      ),
                    ],
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
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: Container(
                            key: ValueKey<String>(
                              selectedCategory?.name ?? 'none',
                            ),
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.sage.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(
                              categoryHelp,
                              style: AppTextStyles.welcomeSub.copyWith(
                                fontSize: 13.5,
                                height: 1.45,
                                color: AppColors.ink,
                              ),
                            ),
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
                  FeedbackScreenshotField(
                    title: l10n.feedbackScreenshotTitle,
                    emptyLabel: l10n.feedbackScreenshotPlaceholder,
                    selectedLabel: l10n.feedbackScreenshotSelectedLabel,
                    selectActionLabel: l10n.feedbackScreenshotSelectAction,
                    replaceActionLabel: l10n.feedbackScreenshotReplaceAction,
                    removeActionLabel: l10n.feedbackScreenshotRemoveAction,
                    previewBytes: _controller.screenshotPreviewBytes,
                    isBusy: _controller.isSubmitting ||
                        _controller.isSelectingScreenshot,
                    busyLabel: l10n.feedbackScreenshotPreparing,
                    errorText: _screenshotErrorText(
                      l10n,
                      _controller.imageIssue,
                    ),
                    onSelect: _controller.canEditScreenshot
                        ? _controller.selectScreenshot
                        : null,
                    onReplace: _controller.canEditScreenshot
                        ? _controller.selectScreenshot
                        : null,
                    onRemove: _controller.canEditScreenshot &&
                            _controller.hasScreenshotSelection
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
                    onPressed: _controller.canSubmit
                        ? () => _handleSubmit(context)
                        : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: _controller.isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(l10n.feedbackSubmitAction),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _categoryHelpText(
    AppLocalizations l10n,
    FeedbackCategory? category,
  ) {
    switch (category) {
      case FeedbackCategory.bug:
        return l10n.feedbackCategoryBugHelp;
      case FeedbackCategory.suggestion:
        return l10n.feedbackCategorySuggestionHelp;
      case FeedbackCategory.improvement:
        return l10n.feedbackCategoryImprovementHelp;
      case FeedbackCategory.other:
        return l10n.feedbackCategoryOtherHelp;
      case null:
        return l10n.feedbackCategoryGeneralHelp;
    }
  }

  void _showSubmitError(
    BuildContext context,
    RepositoryError? error,
  ) {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final message = switch (error?.code) {
      RepositoryErrorCode.notAuthenticated =>
        l10n.feedbackSubmitErrorSessionExpired,
      RepositoryErrorCode.network => l10n.feedbackSubmitErrorNetwork,
      RepositoryErrorCode.invalidResponse => l10n.feedbackSubmitErrorRejected,
      RepositoryErrorCode.permissionDenied => l10n.feedbackSubmitErrorRejected,
      RepositoryErrorCode.notFound => l10n.feedbackSubmitErrorGeneric,
      RepositoryErrorCode.unknown => l10n.feedbackSubmitErrorGeneric,
      null => l10n.feedbackSubmitErrorGeneric,
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

  String? _screenshotErrorText(
    AppLocalizations l10n,
    FeedbackImageErrorType? error,
  ) {
    if (error == null) return null;

    return switch (error) {
      FeedbackImageErrorType.unsupportedType =>
        l10n.feedbackScreenshotErrorUnsupported,
      FeedbackImageErrorType.notProcessable =>
        l10n.feedbackScreenshotErrorNotProcessable,
      FeedbackImageErrorType.compressionFailed =>
        l10n.feedbackScreenshotErrorCompressionFailed,
      FeedbackImageErrorType.tooLarge =>
        l10n.feedbackScreenshotErrorTooLarge,
      FeedbackImageErrorType.uploadFailed =>
        l10n.feedbackScreenshotErrorUploadFailed,
      FeedbackImageErrorType.cleanupFailed =>
        l10n.feedbackScreenshotErrorCleanupFailed,
    };
  }
}
