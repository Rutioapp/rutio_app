import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'diary_v2_styles.dart';

class DiaryV2MonthDot {
  const DiaryV2MonthDot({
    required this.active,
    this.highlighted = false,
  });

  final bool active;
  final bool highlighted;
}

class DiaryV2MonthPreviewCard extends StatelessWidget {
  const DiaryV2MonthPreviewCard({
    super.key,
    required this.title,
    required this.summary,
    required this.moodLabel,
    required this.dots,
  });

  final String title;
  final String summary;
  final String moodLabel;
  final List<DiaryV2MonthDot> dots;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: DiaryV2Styles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: DiaryV2Styles.title(context),
                ),
              ),
              const Icon(
                CupertinoIcons.chevron_right,
                color: DiaryV2Styles.text,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _WeekLabels(),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: dots.map((dot) => _MonthDot(dot: dot)).toList(),
          ),
          const SizedBox(height: 14),
          Text(
            summary,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: DiaryV2Styles.text,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  moodLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DiaryV2Styles.mutedText,
                  ),
                ),
              ),
              const Icon(
                CupertinoIcons.smiley,
                color: DiaryV2Styles.sage,
                size: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekLabels extends StatelessWidget {
  const _WeekLabels();

  @override
  Widget build(BuildContext context) {
    const labels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: labels
          .map(
            (label) => Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: DiaryV2Styles.mutedText,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _MonthDot extends StatelessWidget {
  const _MonthDot({required this.dot});

  final DiaryV2MonthDot dot;

  @override
  Widget build(BuildContext context) {
    final color = !dot.active
        ? const Color(0xFFE0DACE)
        : dot.highlighted
            ? DiaryV2Styles.accent
            : DiaryV2Styles.sage;
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
