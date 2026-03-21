import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../models/diary_entry.dart';

class WeeklyEmotionalStreakCard extends StatelessWidget {
  const WeeklyEmotionalStreakCard({
    super.key,
    required this.entries,
  });

  final List<DiaryEntry> entries;

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

  List<_WeekDayIndicatorData> _weekDays(
    BuildContext context,
    DateTime now,
    Set<DateTime> completedDays,
  ) {
    final start = _startOfWeek(now);
    final today = DateTime(now.year, now.month, now.day);

    return List.generate(7, (index) {
      final date = start.add(Duration(days: index));
      final normalized = DateTime(date.year, date.month, date.day);
      return _WeekDayIndicatorData(
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
    final now = DateTime.now();
    final completedDays = _entryDaysThisWeek(now);
    final streak = _currentStreak(now, completedDays);
    final weekDays = _weekDays(context, now, completedDays);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(22),
        border:
            Border.all(color: scheme.outlineVariant.withValues(alpha: 0.36)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0944374E),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.diaryEmotionalStreakTitle,
            style: theme.textTheme.labelLarge?.copyWith(
              color: const Color(0xFF6A5B71),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            l10n.diaryDaysLabel(streak, streak == 1 ? '' : 's'),
            style: theme.textTheme.titleLarge?.copyWith(
              color: const Color(0xFF36283D),
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < weekDays.length; i++) ...[
                Expanded(
                  child: _WeekDayIndicator(
                    data: weekDays[i],
                    accent: scheme.primary,
                  ),
                ),
                if (i != weekDays.length - 1) const SizedBox(width: 6),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekDayIndicatorData {
  const _WeekDayIndicatorData({
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

  final _WeekDayIndicatorData data;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final background = data.isCompleted
        ? accent.withValues(alpha: 0.12)
        : const Color(0xFFF6F2F8);
    final borderColor = data.isToday
        ? accent.withValues(alpha: 0.5)
        : (data.isCompleted
            ? accent.withValues(alpha: 0.10)
            : const Color(0xFFE7E1EB));
    final textColor =
        data.isCompleted ? const Color(0xFF4E3D58) : const Color(0xFF998DA3);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: data.isToday ? 1.3 : 1,
        ),
        boxShadow: data.isToday
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
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
                ),
          ),
          const SizedBox(height: 5),
          data.isCompleted
              ? const Text(
                  '\uD83C\uDF31',
                  style: TextStyle(fontSize: 12, height: 1),
                )
              : Container(
                  width: data.isToday ? 8 : 7,
                  height: data.isToday ? 8 : 7,
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
