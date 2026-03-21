import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';

class DailySummaryCard extends StatelessWidget {
  const DailySummaryCard({
    super.key,
    required this.entriesCount,
    required this.emotionalXp,
  });

  final int entriesCount;
  final int emotionalXp;

  ({String title, String subtitle}) _messageForCount(BuildContext context) {
    final l10n = context.l10n;
    if (entriesCount <= 0) {
      return (
        title: l10n.diarySummaryEmptyTitle,
        subtitle: l10n.diarySummaryEmptySubtitle,
      );
    }
    if (entriesCount == 1) {
      return (
        title: l10n.diarySummaryOneTitle,
        subtitle: l10n.diarySummaryOneSubtitle,
      );
    }
    if (entriesCount <= 3) {
      return (
        title: l10n.diarySummaryFewTitle,
        subtitle: l10n.diarySummaryFewSubtitle,
      );
    }
    return (
      title: l10n.diarySummaryManyTitle,
      subtitle: l10n.diarySummaryManySubtitle,
    );
  }

  Color _resolveSummaryBackground(BuildContext context, int entryCount) {
    final scheme = Theme.of(context).colorScheme;

    if (entryCount <= 0) {
      return Colors.grey.withValues(alpha: 0.08);
    }
    if (entryCount == 1) {
      return scheme.primary.withValues(alpha: 0.10);
    }
    if (entryCount <= 3) {
      return const Color(0xFFBFE3C8).withValues(alpha: 0.34);
    }
    return const Color(0xFFF3DFA2).withValues(alpha: 0.42);
  }

  Color _resolveBorderColor(BuildContext context, int entryCount) {
    final scheme = Theme.of(context).colorScheme;

    if (entryCount <= 0) {
      return Colors.grey.withValues(alpha: 0.14);
    }
    if (entryCount == 1) {
      return scheme.primary.withValues(alpha: 0.16);
    }
    if (entryCount <= 3) {
      return const Color(0xFF9ACAAB).withValues(alpha: 0.46);
    }
    return const Color(0xFFE3C778).withValues(alpha: 0.52);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final message = _messageForCount(context);
    final backgroundColor = _resolveSummaryBackground(context, entriesCount);
    final borderColor = _resolveBorderColor(context, entriesCount);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C584A7A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.diaryWrittenEntriesToday(entriesCount),
            style: theme.textTheme.titleMedium?.copyWith(
              color: const Color(0xFF43334E),
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.diaryEmotionalXp(emotionalXp),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF7E708F),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF5D4B69),
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message.subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF8F839A),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
