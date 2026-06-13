import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../diary_v2_mood_visuals.dart';
import 'diary_v2_styles.dart';

class DiaryV2TodayEntryCard extends StatelessWidget {
  const DiaryV2TodayEntryCard({
    super.key,
    required this.title,
    required this.dateLabel,
    required this.excerpt,
    required this.emptyTitle,
    required this.emptyBody,
    required this.selectedMood,
    required this.metadataLabels,
    required this.isEmpty,
    this.extraEntriesLabel,
    this.onViewAllTap,
  });

  final String title;
  final String dateLabel;
  final String excerpt;
  final String emptyTitle;
  final String emptyBody;
  final int? selectedMood;
  final List<String> metadataLabels;
  final bool isEmpty;
  final String? extraEntriesLabel;
  final VoidCallback? onViewAllTap;

  @override
  Widget build(BuildContext context) {
    final hasExcerpt = excerpt.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: DiaryV2Styles.cream.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(DiaryV2Styles.cardRadius),
        border: Border.all(color: DiaryV2Styles.border.withValues(alpha: 0.9)),
        boxShadow: const [
          BoxShadow(
            color: DiaryV2Styles.shadowWarm,
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: DiaryV2Styles.accentSoftMuted,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  CupertinoIcons.book,
                  color: DiaryV2Styles.accentDeep,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DiaryV2Styles.title(context).copyWith(
                      fontSize: 18,
                      color: DiaryV2Styles.textStrong,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    dateLabel,
                    maxLines: 2,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: DiaryV2Styles.mutedText,
                          fontSize: 12,
                          height: 1.2,
                        ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: isEmpty
                ? _EmptyState(
                    title: emptyTitle,
                    body: emptyBody,
                  )
                : hasExcerpt
                    ? _Excerpt(excerpt: excerpt)
                    : const SizedBox.shrink(key: ValueKey('no-excerpt')),
          ),
          if ((!isEmpty && hasExcerpt) ||
              metadataLabels.isNotEmpty ||
              extraEntriesLabel != null ||
              selectedMood != null) ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (metadataLabels.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: metadataLabels
                              .map((label) => _TagChip(label: label))
                              .toList(growable: false),
                        ),
                      if (extraEntriesLabel != null && onViewAllTap != null) ...[
                        if (metadataLabels.isNotEmpty) const SizedBox(height: 10),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          onPressed: onViewAllTap,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  extraEntriesLabel!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: DiaryV2Styles.accentDeep,
                                        fontWeight: FontWeight.w600,
                                        height: 1.2,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                CupertinoIcons.chevron_right,
                                color: DiaryV2Styles.accentDeep,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (selectedMood != null) ...[
                  const SizedBox(width: 12),
                  _MoodIndicator(moodValue: selectedMood!),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('empty'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: DiaryV2Styles.textStrong,
                fontWeight: FontWeight.w600,
                height: 1.15,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DiaryV2Styles.mutedTextStrong,
                height: 1.4,
              ),
        ),
      ],
    );
  }
}

class _Excerpt extends StatelessWidget {
  const _Excerpt({required this.excerpt});

  final String excerpt;

  @override
  Widget build(BuildContext context) {
    return Text(
      excerpt,
      key: const ValueKey('excerpt'),
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: DiaryV2Styles.textStrong,
            height: 1.5,
          ),
    );
  }
}

class _MoodIndicator extends StatelessWidget {
  const _MoodIndicator({
    required this.moodValue,
  });

  final int moodValue;

  @override
  Widget build(BuildContext context) {
    final emoji = DiaryMoodVisuals.emojiFor(moodValue);
    final borderColor = DiaryMoodVisuals.borderColorFor(moodValue);
    final fillColor = DiaryMoodVisuals.fillColorFor(moodValue);
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: fillColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 1.3,
        ),
      ),
      child: Center(
        child: Text(
          emoji,
          style: TextStyle(
            fontSize: moodValue == 0 ? 16 : 14,
            height: 1,
            color: borderColor,
            fontWeight: moodValue == 0 ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: DiaryV2Styles.creamStrong.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: DiaryV2Styles.border.withValues(alpha: 0.72),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: DiaryV2Styles.mutedTextStrong,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
      ),
    );
  }
}
