import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../utils/app_theme.dart';

class FeedbackScreenshotField extends StatelessWidget {
  const FeedbackScreenshotField({
    super.key,
    required this.title,
    required this.emptyLabel,
    required this.selectedLabel,
    required this.selectActionLabel,
    required this.replaceActionLabel,
    required this.removeActionLabel,
    this.previewBytes,
    this.isBusy = false,
    this.busyLabel,
    this.errorText,
    this.onSelect,
    this.onReplace,
    this.onRemove,
  });

  final String title;
  final String emptyLabel;
  final String selectedLabel;
  final String selectActionLabel;
  final String replaceActionLabel;
  final String removeActionLabel;
  final Uint8List? previewBytes;
  final bool isBusy;
  final String? busyLabel;
  final String? errorText;
  final VoidCallback? onSelect;
  final VoidCallback? onReplace;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final hasPreview = previewBytes != null && previewBytes!.isNotEmpty;
    final canInteract = !isBusy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.fieldLabel.copyWith(
            color: AppColors.earth,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 10),
        Semantics(
          button: canInteract,
          label: title,
          child: Material(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: canInteract ? (hasPreview ? onReplace : onSelect) : null,
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.earthSoft.withValues(alpha: 0.18),
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: hasPreview
                      ? _SelectedPreview(
                          key: const ValueKey('feedback-screenshot-selected'),
                          previewBytes: previewBytes!,
                          selectedLabel: selectedLabel,
                          replaceActionLabel: replaceActionLabel,
                          removeActionLabel: removeActionLabel,
                          busyLabel: busyLabel,
                          isBusy: isBusy,
                          onReplace: onReplace,
                          onRemove: onRemove,
                        )
                      : _EmptyPreview(
                          key: const ValueKey('feedback-screenshot-empty'),
                          emptyLabel: emptyLabel,
                          selectActionLabel: selectActionLabel,
                          isBusy: isBusy,
                          busyLabel: busyLabel,
                          onSelect: onSelect,
                        ),
                ),
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            errorText!,
            style: AppTextStyles.welcomeSub.copyWith(
              fontSize: 12,
              color: AppColors.rust,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview({
    super.key,
    required this.emptyLabel,
    required this.selectActionLabel,
    required this.isBusy,
    required this.busyLabel,
    required this.onSelect,
  });

  final String emptyLabel;
  final String selectActionLabel;
  final bool isBusy;
  final String? busyLabel;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final actionEnabled = !isBusy && onSelect != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 128),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.sage.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.sage,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  emptyLabel,
                  style: AppTextStyles.authSub.copyWith(
                    fontSize: 14,
                    height: 1.45,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonal(
                onPressed: actionEnabled ? onSelect : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: isBusy
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      )
                    : Text(selectActionLabel),
              ),
            ),
          ],
        ),
        if (busyLabel != null && isBusy) ...[
          const SizedBox(height: 8),
          Text(
            busyLabel!,
            style: AppTextStyles.welcomeSub.copyWith(
              fontSize: 11.5,
              color: AppColors.inkSoft,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}

class _SelectedPreview extends StatelessWidget {
  const _SelectedPreview({
    super.key,
    required this.previewBytes,
    required this.selectedLabel,
    required this.replaceActionLabel,
    required this.removeActionLabel,
    required this.isBusy,
    required this.busyLabel,
    required this.onReplace,
    required this.onRemove,
  });

  final Uint8List previewBytes;
  final String selectedLabel;
  final String replaceActionLabel;
  final String removeActionLabel;
  final bool isBusy;
  final String? busyLabel;
  final VoidCallback? onReplace;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final actionEnabled = !isBusy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(
                  previewBytes,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.medium,
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text(
                        selectedLabel,
                        style: AppTextStyles.welcomeSub.copyWith(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton(
              onPressed: actionEnabled ? onReplace : null,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                minimumSize: const Size(0, 44),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(replaceActionLabel),
            ),
            TextButton(
              onPressed: actionEnabled ? onRemove : null,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                minimumSize: const Size(0, 44),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(removeActionLabel),
            ),
          ],
        ),
        if (busyLabel != null && isBusy) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.sage,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  busyLabel!,
                  style: AppTextStyles.welcomeSub.copyWith(
                    fontSize: 11.5,
                    color: AppColors.inkSoft,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
