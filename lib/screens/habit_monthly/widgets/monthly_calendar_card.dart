import 'package:flutter/material.dart';

import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/screens/habit_monthly/widgets/monthly_calendar_grid.dart';
import 'package:rutio/screens/habit_monthly/widgets/monthly_streak_row.dart';

class MonthlyCalendarCard extends StatefulWidget {
  final DateTime monthCursor;
  final Map<String, dynamic> habit;
  final Color accentColor;
  final Map<String, dynamic> habitCompletions;
  final Map<String, dynamic> habitCountValues;
  final Map<String, dynamic> habitSkips;
  final int currentStreak;
  final int bestStreak;

  const MonthlyCalendarCard({
    super.key,
    required this.monthCursor,
    required this.habit,
    required this.accentColor,
    required this.habitCompletions,
    required this.habitCountValues,
    required this.habitSkips,
    required this.currentStreak,
    required this.bestStreak,
  });

  @override
  State<MonthlyCalendarCard> createState() => _MonthlyCalendarCardState();
}

class _MonthlyCalendarCardState extends State<MonthlyCalendarCard> {
  DateTime? _selectedDate;
  MonthlyDayStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _syncInitialSelection();
  }

  @override
  void didUpdateWidget(covariant MonthlyCalendarCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final monthChanged =
        oldWidget.monthCursor.year != widget.monthCursor.year ||
            oldWidget.monthCursor.month != widget.monthCursor.month;
    final habitChanged = (oldWidget.habit['id'] ?? '').toString() !=
        (widget.habit['id'] ?? '').toString();

    if (monthChanged || habitChanged) {
      _syncInitialSelection();
    }
  }

  void _syncInitialSelection() {
    final now = DateTime.now();
    final currentMonth = widget.monthCursor.year == now.year &&
        widget.monthCursor.month == now.month;
    final initialDay = currentMonth ? now.day : 1;
    _selectedDate =
        DateTime(widget.monthCursor.year, widget.monthCursor.month, initialDay);
    _selectedStatus = null;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;
    final labelsColor = Colors.black.withValues(alpha: 0.42);
    final selectionTextColor = Colors.black.withValues(alpha: 0.56);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.64),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.62)),
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(7, (i) {
              return Expanded(
                child: Center(
                  child: Text(
                    l10n.weekdayLetter(i + 1),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: labelsColor,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          MonthlyCalendarGrid(
            monthCursor: widget.monthCursor,
            habit: widget.habit,
            accentColor: widget.accentColor,
            habitCompletions: widget.habitCompletions,
            habitCountValues: widget.habitCountValues,
            habitSkips: widget.habitSkips,
            selectedDate: _selectedDate,
            onDayTap: (date, status) {
              setState(() {
                _selectedDate = date;
                _selectedStatus = status;
              });
            },
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeOut,
            child: _selectedDate == null
                ? const SizedBox.shrink()
                : Text(
                    _selectionLabel(_selectedDate!, _selectedStatus),
                    key: ValueKey<String>(
                      '${_selectedDate!.year}-${_selectedDate!.month}-${_selectedDate!.day}-${_selectedStatus?.name ?? 'na'}',
                    ),
                    style:
                        (textTheme.labelMedium ?? const TextStyle()).copyWith(
                      color: selectionTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          MonthlyStreakRow(
            currentStreak: widget.currentStreak,
            bestStreak: widget.bestStreak,
          ),
        ],
      ),
    );
  }

  String _selectionLabel(DateTime date, MonthlyDayStatus? status) {
    final l10n = context.l10n;
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    String state;
    switch (status) {
      case MonthlyDayStatus.today:
        state = l10n.monthlySelectionToday;
        break;
      case MonthlyDayStatus.done:
        state = l10n.monthlySelectionDone;
        break;
      case MonthlyDayStatus.skip:
        state = l10n.monthlySelectionSkipped;
        break;
      case MonthlyDayStatus.missed:
        state = l10n.monthlySelectionPending;
        break;
      case MonthlyDayStatus.future:
        state = l10n.monthlySelectionFuture;
        break;
      case MonthlyDayStatus.unscheduled:
        state = l10n.monthlySelectionUnscheduled;
        break;
      case null:
        state = l10n.monthlySelectionSelected;
        break;
    }

    return l10n.monthlySelectionLabel(int.parse(day), int.parse(month), state);
  }
}
