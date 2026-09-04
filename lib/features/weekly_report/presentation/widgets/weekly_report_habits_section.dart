import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../habits/domain/metrics/habit_occurrence_result.dart';
import '../../domain/weekly_report.dart';
import '../weekly_report_copy_resolver.dart';
import '../weekly_report_visuals.dart';

/// Compact, snapshot-only rendering of the habits part of a weekly report.
class WeeklyReportHabitsSection extends StatefulWidget {
  const WeeklyReportHabitsSection({super.key, required this.habits});

  final List<WeeklyReportHabit> habits;

  @override
  State<WeeklyReportHabitsSection> createState() =>
      _WeeklyReportHabitsSectionState();
}

class _WeeklyReportHabitsSectionState extends State<WeeklyReportHabitsSection> {
  final Set<WeeklyReportHabitClassification> _expanded = {};

  @override
  Widget build(BuildContext context) {
    if (widget.habits.isEmpty) return const SizedBox.shrink();
    final groups = <_HabitGroup>[
      _HabitGroup(
          WeeklyReportHabitClassification.highlighted,
          _byClassification(WeeklyReportHabitClassification.highlighted),
          context.l10n.weeklyReportHabitGroupFeatured,
          context.l10n.weeklyReportHabitGroupFeaturedSubtitle,
          Icons.star_rounded),
      _HabitGroup(
          WeeklyReportHabitClassification.stable,
          _byClassification(WeeklyReportHabitClassification.stable),
          context.l10n.weeklyReportHabitGroupStable,
          context.l10n.weeklyReportHabitGroupStableSubtitle,
          Icons.circle),
      _HabitGroup(
          WeeklyReportHabitClassification.needsAttention,
          _byClassification(WeeklyReportHabitClassification.needsAttention),
          context.l10n.weeklyReportHabitGroupNeedsAttention,
          context.l10n.weeklyReportHabitGroupNeedsAttentionSubtitle,
          Icons.change_history_rounded),
    ];
    final unavailable =
        _byClassification(WeeklyReportHabitClassification.unavailable);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(context.l10n.weeklyReportHabitsTitle,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2F251C))),
      const SizedBox(height: 6),
      Container(
        decoration: WeeklyReportVisuals.cardDecoration(),
        child: Column(children: [
          for (var i = 0; i < groups.length; i++) ...[
            _GroupView(
                group: groups[i],
                expanded: _expanded.contains(groups[i].classification),
                onToggle: () => _toggle(groups[i].classification)),
            if (i < groups.length - 1)
              Divider(
                  height: 1,
                  indent: 10,
                  endIndent: 10,
                  color: WeeklyReportVisuals.border),
          ],
          if (unavailable.isNotEmpty) ...[
            Divider(
                height: 1,
                indent: 10,
                endIndent: 10,
                color: WeeklyReportVisuals.border),
            _GroupView(
                group: _HabitGroup(
                    WeeklyReportHabitClassification.unavailable,
                    unavailable,
                    context.l10n.weeklyReportHabitUnavailable,
                    null,
                    Icons.schedule_outlined),
                expanded: _expanded
                    .contains(WeeklyReportHabitClassification.unavailable),
                onToggle: () =>
                    _toggle(WeeklyReportHabitClassification.unavailable),
                secondary: true),
          ],
        ]),
      ),
    ]);
  }

  List<WeeklyReportHabit> _byClassification(
          WeeklyReportHabitClassification classification) =>
      [
        for (final habit in widget.habits)
          if (habit.classification == classification) habit,
      ];

  void _toggle(WeeklyReportHabitClassification classification) {
    if (_byClassification(classification).isEmpty) return;
    setState(() {
      if (!_expanded.add(classification)) _expanded.remove(classification);
    });
  }
}

class _HabitGroup {
  const _HabitGroup(
      this.classification, this.habits, this.title, this.subtitle, this.icon);
  final WeeklyReportHabitClassification classification;
  final List<WeeklyReportHabit> habits;
  final String title;
  final String? subtitle;
  final IconData icon;
}

class _GroupView extends StatelessWidget {
  const _GroupView(
      {required this.group,
      required this.expanded,
      required this.onToggle,
      this.secondary = false});
  final _HabitGroup group;
  final bool expanded;
  final VoidCallback onToggle;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    final empty = group.habits.isEmpty;
    final action = expanded
        ? context.l10n.weeklyReportHabitCollapse
        : context.l10n.weeklyReportHabitExpand;
    final state = expanded
        ? context.l10n.weeklyReportHabitExpanded
        : context.l10n.weeklyReportHabitCollapsed;
    final semantics = empty
        ? '${group.title}. 0'
        : '${group.title}. ${group.habits.length} ${context.l10n.weeklyReportHabitCountUnit}. $state';

    final tone = _tone(group.classification);
    return Column(children: [
      Semantics(
        container: true,
        label: semantics,
        button: !empty,
        enabled: !empty,
        onTap: empty ? null : onToggle,
        child: InkWell(
          onTap: empty ? null : onToggle,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: 10, vertical: secondary ? 5 : 6),
            child: Row(children: [
              Container(
                  width: secondary ? 22 : 24,
                  height: secondary ? 22 : 24,
                  decoration: BoxDecoration(
                      color: tone.background, shape: BoxShape.circle),
                  child: Icon(group.icon,
                      size: secondary ? 15 : 17, color: tone.foreground)),
              const SizedBox(width: 8),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(group.title,
                        style: TextStyle(
                            fontSize: secondary ? 12 : 13,
                            fontWeight: FontWeight.w700,
                            color: secondary
                                ? WeeklyReportVisuals.mutedText
                                : tone.foreground)),
                    if (group.subtitle != null)
                      Text(group.subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 10, color: Color(0xFF746A60))),
                  ])),
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(minWidth: 30),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                    color: tone.background,
                    borderRadius: BorderRadius.circular(20)),
                child: Text('${group.habits.length}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: tone.foreground)),
              ),
              if (!empty) ...[
                const SizedBox(width: 5),
                Semantics(
                    label: action,
                    child: Icon(
                        expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: WeeklyReportVisuals.text,
                        size: 22)),
              ],
            ]),
          ),
        ),
      ),
      AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: expanded
              ? Column(children: [
                  for (var i = 0; i < group.habits.length; i++) ...[
                    _WeeklyReportHabitRow(habit: group.habits[i]),
                    if (i < group.habits.length - 1)
                      Divider(
                          height: 1,
                          indent: 10,
                          endIndent: 10,
                          color: WeeklyReportVisuals.border),
                  ],
                ])
              : const SizedBox.shrink()),
    ]);
  }

  _GroupTone _tone(WeeklyReportHabitClassification classification) {
    switch (classification) {
      case WeeklyReportHabitClassification.highlighted:
        return const _GroupTone(
            WeeklyReportVisuals.stableSoft, WeeklyReportVisuals.successStrong);
      case WeeklyReportHabitClassification.needsAttention:
        return const _GroupTone(
            WeeklyReportVisuals.warningSoft, WeeklyReportVisuals.warningStrong);
      case WeeklyReportHabitClassification.stable:
        return const _GroupTone(Color(0xFFF0EEE8), WeeklyReportVisuals.stable);
      case WeeklyReportHabitClassification.unavailable:
        return const _GroupTone(
            Color(0xFFF2EEE8), WeeklyReportVisuals.neutralStrong);
    }
  }
}

class _GroupTone {
  const _GroupTone(this.background, this.foreground);
  final Color background;
  final Color foreground;
}

class _WeeklyReportHabitRow extends StatelessWidget {
  const _WeeklyReportHabitRow({required this.habit});
  final WeeklyReportHabit habit;

  @override
  Widget build(BuildContext context) {
    final result = habit.scheduledCount == 0
        ? context.l10n.weeklyReportHabitNoSchedule
        : '${habit.completedCount}/${habit.scheduledCount} · ${(habit.completionRate! * 100).round()}%';
    final streak = habit.streakSnapshot;
    final streakText = streak == null
        ? null
        : '${streak.currentStreak} ${context.l10n.weeklyReportHabitStreak}';
    final label = [
      habit.name,
      result,
      if (streakText != null) streakText,
      _daysSummary(context, habit)
    ].join('. ');

    return Semantics(
      container: true,
      label: label,
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: LayoutBuilder(builder: (context, constraints) {
            final narrow = constraints.maxWidth < 380;
            final identity = Expanded(
                child: Row(children: [
              Text(habit.emoji ?? '•', style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 7),
              Flexible(
                  child: Text(habit.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2F251C)))),
            ]));
            final details = Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                  Text(result,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5F554A))),
                  const SizedBox(height: 4),
                  _HabitDayDots(habit: habit),
                  if (WeeklyReportCopyResolver.observation(context.l10n, habit)
                      case final observation?)
                    Align(
                        alignment: Alignment.centerRight,
                        child: Text(observation,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                fontSize: 10, color: Color(0xFF746A60)))),
                  if (streakText != null)
                    Align(
                        alignment: Alignment.centerRight,
                        child: Text(streakText,
                            style: const TextStyle(
                                fontSize: 10, color: Color(0xFF746A60)))),
                ]));
            return narrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Row(children: [identity]),
                        const SizedBox(height: 6),
                        Row(children: [details]),
                      ])
                : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    identity,
                    const SizedBox(width: 8),
                    details,
                  ]);
          })),
    );
  }

  String _daysSummary(BuildContext context, WeeklyReportHabit habit) =>
      List.generate(7, (i) => _dayLabel(context, habit, i + 1)).join(', ');

  String _dayLabel(BuildContext context, WeeklyReportHabit habit, int weekday) {
    final day = context.l10n.weekdayFull(weekday);
    final occurrence = _occurrenceFor(habit, weekday);
    return occurrence == null
        ? context.l10n.weeklyReportHabitDayNoActivity(day)
        : _occurrenceLabel(context, day, occurrence);
  }

  HabitOccurrenceResult? _occurrenceFor(WeeklyReportHabit habit, int weekday) {
    for (final occurrence in habit.occurrences) {
      if (occurrence.date.weekday == weekday &&
          (occurrence.scope == HabitOccurrenceScope.dateBound ||
              habit.schedule.isTimesPerWeek)) return occurrence;
    }
    return null;
  }

  String _occurrenceLabel(
      BuildContext context, String day, HabitOccurrenceResult occurrence) {
    final l10n = context.l10n;
    if (occurrence.skipped) return l10n.weeklyReportHabitDaySkipped(day);
    if (occurrence.completed) return l10n.weeklyReportHabitDayCompleted(day);
    if (occurrence.isPartialProgress)
      return l10n.weeklyReportHabitDayPartial(day);
    if (occurrence.scheduled) return l10n.weeklyReportHabitDayIncomplete(day);
    return l10n.weeklyReportHabitDayNoSchedule(day);
  }
}

class _HabitDayDots extends StatelessWidget {
  const _HabitDayDots({required this.habit});
  final WeeklyReportHabit habit;

  @override
  Widget build(BuildContext context) => Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(7, (i) {
        final occurrence = _occurrenceFor(i + 1);
        return Padding(
            padding: const EdgeInsets.only(left: 3),
            child: Semantics(
                label: _daySemantics(context, i + 1, occurrence),
                child: Column(children: [
                  _Dot(occurrence: occurrence),
                  const SizedBox(height: 2),
                  Text(context.l10n.weekdayLetter(i + 1),
                      style: const TextStyle(
                          fontSize: 9, color: Color(0xFF746A60))),
                ])));
      }));

  HabitOccurrenceResult? _occurrenceFor(int weekday) {
    for (final occurrence in habit.occurrences) {
      if (occurrence.date.weekday == weekday &&
          (occurrence.scope == HabitOccurrenceScope.dateBound ||
              habit.schedule.isTimesPerWeek)) return occurrence;
    }
    return null;
  }

  String _daySemantics(
      BuildContext context, int weekday, HabitOccurrenceResult? occurrence) {
    final day = context.l10n.weekdayFull(weekday);
    if (occurrence == null)
      return context.l10n.weeklyReportHabitDayNoActivity(day);
    final l10n = context.l10n;
    if (occurrence.skipped) return l10n.weeklyReportHabitDaySkipped(day);
    if (occurrence.completed) return l10n.weeklyReportHabitDayCompleted(day);
    if (occurrence.isPartialProgress)
      return l10n.weeklyReportHabitDayPartial(day);
    if (occurrence.scheduled) return l10n.weeklyReportHabitDayIncomplete(day);
    return l10n.weeklyReportHabitDayNoSchedule(day);
  }
}

class _Dot extends StatelessWidget {
  const _Dot({this.occurrence});
  final HabitOccurrenceResult? occurrence;

  @override
  Widget build(BuildContext context) {
    final o = occurrence;
    final partial = o?.isPartialProgress ?? false;
    final completed = o?.completed ?? false;
    final skipped = o?.skipped ?? false;
    final scheduled = o?.scheduled ?? false;
    final color = completed
        ? const Color(0xFF76AD45)
        : partial
            ? const Color(0xFFBBD09A)
            : skipped
                ? const Color(0xFFC58D2A)
                : scheduled
                    ? const Color(0xFFE0D7CA)
                    : const Color(0xFFF1ECE5);
    return Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
                color: skipped || scheduled
                    ? const Color(0xFF9F8661)
                    : const Color(0xFFE0D7CA))),
        child: skipped
            ? const Icon(Icons.remove, size: 9, color: Color(0xFF765321))
            : partial
                ? const Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                        widthFactor: .5,
                        child: DecoratedBox(
                            decoration: BoxDecoration(
                                color: Color(0xFF70965D),
                                shape: BoxShape.circle))))
                : null);
  }
}
