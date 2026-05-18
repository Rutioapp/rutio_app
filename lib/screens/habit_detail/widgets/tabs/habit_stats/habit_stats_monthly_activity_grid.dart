import 'package:flutter/material.dart';

import '../../../../../l10n/l10n.dart';
import 'habit_stats_models.dart';
import 'habit_stats_section_card.dart';

class HabitStatsMonthlyActivityGrid extends StatelessWidget {
  final HabitStatsMonthlyData monthlyData;
  final DateTime month;

  const HabitStatsMonthlyActivityGrid({
    super.key,
    required this.monthlyData,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cells = buildHabitStatsMonthlyGridCells(monthlyData.days);

    return HabitStatsSectionCard(
      key: const Key('habitStatsMonthlyActivityGrid'),
      title: l10n.habitStatsMonthlyActivityTitle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _capitalizeFirst(l10n.monthFull(month.month)),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11.6,
                  height: 1,
                  color: const Color(0xFF847669),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 10),
          _WeekdayHeader(),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 6.0;
              final rawCellWidth = (constraints.maxWidth - (spacing * 6)) / 7;
              final markerSize = rawCellWidth.clamp(30.0, 34.0).toDouble();
              final cellHeight = markerSize + 4;
              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: cells.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  childAspectRatio: rawCellWidth / cellHeight,
                ),
                itemBuilder: (context, index) {
                  final cell = cells[index];
                  switch (cell) {
                    case HabitStatsMonthlyGridLeadingCell():
                      return SizedBox(
                        key: Key('habitStatsMonthLeadingCell_${cell.index}'),
                      );
                    case HabitStatsMonthlyGridTrailingCell():
                      return SizedBox(
                        key: Key('habitStatsMonthTrailingCell_${cell.index}'),
                      );
                    case HabitStatsMonthlyGridDayCell():
                      return _MonthDayMarker(
                        day: cell.day,
                        markerSize: markerSize,
                      );
                  }
                },
              );
            },
          ),
          const SizedBox(height: 10),
          _Legend(),
        ],
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final labels = <String>[
      context.l10n.weekdayLetter(DateTime.monday),
      context.l10n.weekdayLetter(DateTime.tuesday),
      context.l10n.weekdayLetter(DateTime.wednesday),
      context.l10n.weekdayLetter(DateTime.thursday),
      context.l10n.weekdayLetter(DateTime.friday),
      context.l10n.weekdayLetter(DateTime.saturday),
      context.l10n.weekdayLetter(DateTime.sunday),
    ];
    return Row(
      children: [
        for (final label in labels)
          Expanded(
            child: Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10.8,
                      height: 1,
                      color: const Color(0xFF8B7D6E),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MonthDayMarker extends StatelessWidget {
  final HabitStatsMonthDayState day;
  final double markerSize;

  const _MonthDayMarker({
    required this.day,
    required this.markerSize,
  });

  @override
  Widget build(BuildContext context) {
    final style = _markerStyleFor(day.status);
    final key = Key('habitStatsMonthDay_${day.status.name}_${_dateKey(day.date)}');
    return Center(
      child: Container(
        key: key,
        width: markerSize,
        height: markerSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: style.fillColor,
          border: style.borderColor == null
              ? null
              : Border.all(
                  color: style.borderColor!,
                  width: style.borderWidth,
                ),
        ),
        child: Center(
          child: Text(
            '${day.date.day}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: markerSize >= 32 ? 12.2 : 11.4,
                  height: 1,
                  color: style.textColor,
                  fontWeight: style.fontWeight,
                ),
          ),
        ),
      ),
    );
  }

  _MonthDayMarkerStyle _markerStyleFor(HabitStatsMonthDayStatus status) {
    switch (status) {
      case HabitStatsMonthDayStatus.completed:
        return const _MonthDayMarkerStyle(
          fillColor: Color(0xFF6D9660),
          borderColor: Color(0xFF628957),
          textColor: Color(0xFFFFFAF1),
          borderWidth: 1.2,
          fontWeight: FontWeight.w700,
        );
      case HabitStatsMonthDayStatus.skipped:
        return const _MonthDayMarkerStyle(
          fillColor: Color(0xFFF5EDE2),
          borderColor: Color(0xFFDCCCB7),
          textColor: Color(0xFF8D7359),
          borderWidth: 1.2,
          fontWeight: FontWeight.w700,
        );
      case HabitStatsMonthDayStatus.missed:
        return const _MonthDayMarkerStyle(
          fillColor: Color(0xFFFEFBF6),
          borderColor: Color(0xFFD6C9BB),
          textColor: Color(0xFF9B8F83),
          borderWidth: 1.2,
          fontWeight: FontWeight.w600,
        );
      case HabitStatsMonthDayStatus.future:
        return _MonthDayMarkerStyle(
          fillColor: const Color(0xFFFCF8F2).withValues(alpha: 0.65),
          borderColor: const Color(0xFFE7DFD3).withValues(alpha: 0.8),
          textColor: const Color(0xFFB7AA9B),
          borderWidth: 1.1,
          fontWeight: FontWeight.w500,
        );
      case HabitStatsMonthDayStatus.notScheduled:
        return _MonthDayMarkerStyle(
          fillColor: const Color(0xFFF6F0E7).withValues(alpha: 0.42),
          borderColor: const Color(0xFFE8DDCE).withValues(alpha: 0.35),
          textColor: const Color(0xFFC0B3A3),
          borderWidth: 0.9,
          fontWeight: FontWeight.w500,
        );
    }
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      spacing: 14,
      runSpacing: 7,
      children: [
        _LegendItem(
          color: const Color(0xFF6D9660),
          label: l10n.habitStatsMonthlyLegendDone,
        ),
        _LegendItem(
          color: const Color(0xFFD8C1A7),
          label: l10n.habitStatsMonthlyLegendSkipped,
        ),
        _LegendItem(
          color: const Color(0xFFD6C9BB),
          label: l10n.habitStatsMonthlyLegendPending,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.22),
            border: Border.all(color: color, width: 1),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11.4,
                height: 1,
                color: const Color(0xFF87796D),
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _MonthDayMarkerStyle {
  final Color fillColor;
  final Color? borderColor;
  final Color textColor;
  final double borderWidth;
  final FontWeight fontWeight;

  const _MonthDayMarkerStyle({
    required this.fillColor,
    required this.borderColor,
    required this.textColor,
    required this.borderWidth,
    required this.fontWeight,
  });
}

sealed class HabitStatsMonthlyGridCell {
  const HabitStatsMonthlyGridCell();
}

class HabitStatsMonthlyGridLeadingCell extends HabitStatsMonthlyGridCell {
  final int index;

  const HabitStatsMonthlyGridLeadingCell(this.index);
}

class HabitStatsMonthlyGridTrailingCell extends HabitStatsMonthlyGridCell {
  final int index;

  const HabitStatsMonthlyGridTrailingCell(this.index);
}

class HabitStatsMonthlyGridDayCell extends HabitStatsMonthlyGridCell {
  final HabitStatsMonthDayState day;

  const HabitStatsMonthlyGridDayCell(this.day);
}

List<HabitStatsMonthlyGridCell> buildHabitStatsMonthlyGridCells(
  List<HabitStatsMonthDayState> days,
) {
  if (days.isEmpty) return const <HabitStatsMonthlyGridCell>[];
  final firstDay = days.first.date;
  final leadingEmptyCells = (firstDay.weekday - DateTime.monday + 7) % 7;
  final totalFilledCells = leadingEmptyCells + days.length;
  final trailingEmptyCells = (7 - (totalFilledCells % 7)) % 7;

  return <HabitStatsMonthlyGridCell>[
    for (var index = 0; index < leadingEmptyCells; index++)
      HabitStatsMonthlyGridLeadingCell(index),
    for (final day in days) HabitStatsMonthlyGridDayCell(day),
    for (var index = 0; index < trailingEmptyCells; index++)
      HabitStatsMonthlyGridTrailingCell(index),
  ];
}

String _dateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String _capitalizeFirst(String text) {
  if (text.isEmpty) return text;
  return '${text[0].toUpperCase()}${text.substring(1)}';
}
