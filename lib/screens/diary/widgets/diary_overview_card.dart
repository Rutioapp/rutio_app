import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../models/diary_entry.dart';
import '../../../utils/app_theme.dart';

class DiaryOverviewCard extends StatelessWidget {
  const DiaryOverviewCard({
    super.key,
    required this.entriesCount,
    required this.emotionalXp,
    required this.entries,
  });

  final int entriesCount;
  final int emotionalXp;
  final List<DiaryEntry> entries;

  Color _resolveSummaryBackground(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (entriesCount <= 0) {
      return Colors.grey.withValues(alpha: 0.08);
    }
    if (entriesCount == 1) {
      return scheme.primary.withValues(alpha: 0.10);
    }
    if (entriesCount <= 3) {
      return const Color(0xFFBFE3C8).withValues(alpha: 0.34);
    }
    return const Color(0xFFF3DFA2).withValues(alpha: 0.42);
  }

  Color _resolveBorderColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (entriesCount <= 0) {
      return Colors.grey.withValues(alpha: 0.14);
    }
    if (entriesCount == 1) {
      return scheme.primary.withValues(alpha: 0.16);
    }
    if (entriesCount <= 3) {
      return const Color(0xFF9ACAAB).withValues(alpha: 0.46);
    }
    return const Color(0xFFE3C778).withValues(alpha: 0.52);
  }

  DateTime _startOfWeek(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  Set<DateTime> _entryDaysThisWeek(DateTime now) {
    final start = _startOfWeek(now);
    final end = start.add(const Duration(days: 7));

    return entries
        .map((e) => DateTime.fromMillisecondsSinceEpoch(e.createdAt))
        .map((d) => DateTime(d.year, d.month, d.day))
        .where((d) => !d.isBefore(start) && d.isBefore(end))
        .toSet();
  }

  int _currentStreak(DateTime today, Set<DateTime> completedDays) {
    var streak = 0;
    var cursor = DateTime(today.year, today.month, today.day);
    final start = _startOfWeek(today);

    while (!cursor.isBefore(start) && completedDays.contains(cursor)) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  List<_WeekDayData> _weekDays(
      BuildContext context, DateTime now, Set<DateTime> completedDays) {
    final start = _startOfWeek(now);
    final today = DateTime(now.year, now.month, now.day);

    return List.generate(7, (index) {
      final date = start.add(Duration(days: index));
      final normalized = DateTime(date.year, date.month, date.day);
      return _WeekDayData(
        label: context.l10n.weekdayLetter(index + 1),
        isCompleted: completedDays.contains(normalized),
        isToday: normalized == today,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final backgroundColor = _resolveSummaryBackground(context);
    final borderColor = _resolveBorderColor(context);
    final now = DateTime.now();
    final completedDays = _entryDaysThisWeek(now);
    final streak = _currentStreak(now, completedDays);
    final weekDays = _weekDays(context, now, completedDays);
    final accent = theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
            style: AppTextStyles.authTitle.copyWith(
              fontSize: 21,
              color: const Color(0xFF43334E),
              letterSpacing: -0.35,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Text(
                l10n.diaryEmotionalXp(emotionalXp),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF7E708F),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFF9E91A9),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                l10n.diaryStreakLabel(streak, streak == 1 ? '' : 's'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6C5E79),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < weekDays.length; i++) ...[
                Expanded(
                  child: _WeekDayIndicator(
                    data: weekDays[i],
                    accent: accent,
                  ),
                ),
                if (i != weekDays.length - 1) const SizedBox(width: 4),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekDayData {
  const _WeekDayData({
    required this.label,
    required this.isCompleted,
    required this.isToday,
  });

  final String label;
  final bool isCompleted;
  final bool isToday;
}

class _WeekDayIndicator extends StatelessWidget {
  const _WeekDayIndicator({
    required this.data,
    required this.accent,
  });

  final _WeekDayData data;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final background = data.isCompleted
        ? accent.withValues(alpha: 0.11)
        : const Color(0xFFF7F3F8);
    final borderColor = data.isToday
        ? accent.withValues(alpha: 0.46)
        : (data.isCompleted
            ? accent.withValues(alpha: 0.08)
            : const Color(0xFFE8E2EB));
    final textColor =
        data.isCompleted ? const Color(0xFF584865) : const Color(0xFF9C91A4);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
          width: data.isToday ? 1.2 : 1,
        ),
        boxShadow: data.isToday
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            data.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
          ),
          const SizedBox(height: 4),
          data.isCompleted
              ? const Text(
                  '\uD83C\uDF31',
                  style: TextStyle(fontSize: 10.5, height: 1),
                )
              : Container(
                  width: data.isToday ? 7 : 6,
                  height: data.isToday ? 7 : 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD9D0DE),
                    shape: BoxShape.circle,
                  ),
                ),
        ],
      ),
    );
  }
}
