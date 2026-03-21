import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:rutio/ui/behaviours/ios_feedback.dart';

import '../weekly_helpers.dart';
import 'helpers/weekly_count_prompt_builder.dart';
import 'helpers/weekly_habit_data_helper.dart';
import 'helpers/weekly_habit_day_state_resolver.dart';
import 'sheets/weekly_count_entry_sheet.dart';
import 'weekly_habit_list_view.dart';

class WeeklyHabitList extends StatefulWidget {
  final List<Map<String, dynamic>> habits;
  final List<DateTime> days;
  final Map<String, dynamic> habitCompletions;
  final Map<String, dynamic> habitSkips;
  final Map<String, dynamic> habitCountValues;
  final Map<String, dynamic> userState;
  final Map<String, dynamic>? root;
  final VoidCallback onOpenDailyView;

  const WeeklyHabitList({
    super.key,
    required this.habits,
    required this.days,
    required this.habitCompletions,
    required this.habitSkips,
    required this.habitCountValues,
    required this.userState,
    required this.root,
    required this.onOpenDailyView,
  });

  @override
  State<WeeklyHabitList> createState() => _WeeklyHabitListState();
}

class _WeeklyHabitListState extends State<WeeklyHabitList> {
  static const Duration _expandDuration = Duration(milliseconds: 420);
  static const Curve _expandCurve = Curves.easeInOutCubic;

  bool _showNames = false;

  void _toggleExpanded() {
    setState(() => _showNames = !_showNames);
  }

  Future<void> _cycleCheckState({
    required String habitId,
    required DateTime day,
    required WeeklyHabitDayStateResolver dayStateResolver,
    required Map<String, dynamic> habit,
  }) async {
    final store = context.read<UserStateStore>();
    final dateKey = AppDateUtils.toYMD(day);
    final currentState =
        dayStateResolver.buildDayState(habit, habitId, dateKey);

    if (currentState.isSkipped) {
      await IosFeedback.selection();
      await store.setHabitSkipForKey(
        habitId: habitId,
        dateKey: dateKey,
        skipped: false,
      );
      return;
    }

    if (currentState.isDone) {
      await IosFeedback.selection();
      await store.setHabitSkipForKey(
        habitId: habitId,
        dateKey: dateKey,
        skipped: true,
      );
      return;
    }

    await IosFeedback.success();
    await store.setHabitCompletionForKey(
      habitId: habitId,
      dateKey: dateKey,
      done: true,
    );
  }

  Future<void> _openCountEditor({
    required Map<String, dynamic> habit,
    required String habitId,
    required DateTime day,
    required num? currentValue,
  }) async {
    final question = buildWeeklyCountPrompt(context, habit);
    final unitLabel = WeeklyHabitDataHelper.resolveCountUnit(habit);
    final allowDecimal = WeeklyHabitDataHelper.supportsDecimals(
      habit,
      currentValue: currentValue,
    );
    final familyColor = ColorHelper.resolveFamilyColor(
      habit,
      widget.userState,
      widget.root,
    );

    final result = await showModalBottomSheet<num>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.22),
      builder: (_) {
        return WeeklyCountEntrySheet(
          accentColor: familyColor,
          title: question,
          subtitle: (habit['title'] ?? habit['name'] ?? '').toString().trim(),
          unitLabel: unitLabel,
          initialValue: currentValue,
          allowDecimal: allowDecimal,
        );
      },
    );

    if (result == null || !mounted) return;

    await context.read<UserStateStore>().setCountHabitValueForDate(
          habitId: habitId,
          date: day,
          value: result,
        );
  }

  WeeklyHabitListRowData _buildHabitRowData(
    Map<String, dynamic> habit, {
    required WeeklyHabitDayStateResolver dayStateResolver,
  }) {
    final title = WeeklyHabitDataHelper.resolveTitle(
      habit,
      fallback: context.l10n.homeFallbackHabitTitle,
    );
    final emoji = WeeklyHabitDataHelper.resolveHabitEmoji(habit);
    final familyColor = ColorHelper.resolveFamilyColor(
      habit,
      widget.userState,
      widget.root,
    );
    final habitId = (habit['id'] ?? habit['habitId'] ?? '').toString();
    final habitType = WeeklyHabitDataHelper.normalizeHabitType(habit);

    final dayStates = widget.days
        .map(
          (day) => dayStateResolver.buildDayState(
            habit,
            habitId,
            AppDateUtils.toYMD(day),
          ),
        )
        .toList(growable: false);

    return WeeklyHabitListRowData(
      title: title,
      emoji: emoji,
      familyColor: familyColor,
      dayStates: dayStates,
      isInteractive: habitId.isNotEmpty,
      onToggleDay: (DateTime day) async {
        if (habitId.isEmpty) return;

        final dateKey = AppDateUtils.toYMD(day);
        if (habitType == 'count') {
          await _openCountEditor(
            habit: habit,
            habitId: habitId,
            day: day,
            currentValue: dayStateResolver.countValueFor(
              habitId: habitId,
              dateKey: dateKey,
            ),
          );
          return;
        }

        await _cycleCheckState(
          habitId: habitId,
          day: day,
          dayStateResolver: dayStateResolver,
          habit: habit,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dayStateResolver = WeeklyHabitDayStateResolver(
      habitCompletions: widget.habitCompletions,
      habitSkips: widget.habitSkips,
      habitCountValues: widget.habitCountValues,
    );
    final rows = widget.habits
        .map(
          (habit) => _buildHabitRowData(
            habit,
            dayStateResolver: dayStateResolver,
          ),
        )
        .toList(growable: false);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: _showNames ? 1 : 0),
      duration: _expandDuration,
      curve: _expandCurve,
      builder: (context, expansionT, _) {
        return WeeklyHabitListView(
          habitsCount: widget.habits.length,
          days: widget.days,
          rows: rows,
          today: today,
          expansionT: expansionT,
          showNames: _showNames,
          onToggleExpand: _toggleExpanded,
          onOpenDailyView: widget.onOpenDailyView,
        );
      },
    );
  }
}
