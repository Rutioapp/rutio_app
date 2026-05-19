import 'package:flutter/material.dart';

import '../../../../../l10n/l10n.dart';
import 'habit_stats_models.dart';

class HabitStatsYearMonthGrid extends StatelessWidget {
  final int year;
  final List<HabitStatsYearCalendarMonth> months;
  final Color accentColor;

  const HabitStatsYearMonthGrid({
    super.key,
    required this.year,
    required this.months,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final panel = theme.colorScheme.surface.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.42 : 0.72,
    );
    final panelBorder = theme.colorScheme.outlineVariant.withValues(alpha: 0.32);

    return Container(
      key: const Key('habit_stats_year_calendar_grid'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: panelBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const columnSpacing = 10.0;
          const rowSpacing = 10.0;
          final columns = constraints.maxWidth < 295 ? 2 : 3;
          final monthWidth =
              (constraints.maxWidth - (columnSpacing * (columns - 1))) / columns;
          final dayGap = monthWidth < 96 ? 1.5 : 2.0;
          final daySize =
              ((monthWidth - (dayGap * 6)) / 7).clamp(4.0, 9.0).toDouble();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _YearHeader(
                year: year,
                accentColor: accentColor,
              ),
              const SizedBox(height: 12),
              GridView.builder(
                key: const Key('habit_stats_year_calendar_month_grid'),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: months.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: columnSpacing,
                  mainAxisSpacing: rowSpacing,
                  childAspectRatio: columns == 3 ? 0.92 : 1.14,
                ),
                itemBuilder: (context, index) {
                  final month = months[index];
                  return _YearCalendarMonthCell(
                    month: month,
                    accentColor: accentColor,
                    daySize: daySize,
                    dayGap: dayGap,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _YearHeader extends StatelessWidget {
  final int year;
  final Color accentColor;

  const _YearHeader({
    required this.year,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.72),
        );

    return Row(
      children: [
        Text(
          '$year',
          key: const Key('habit_stats_year_calendar_year_label'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.94),
              ),
        ),
        const Spacer(),
        Wrap(
          spacing: 10,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _LegendDot(
              key: const Key('habit_stats_year_calendar_legend_skipped'),
              color: accentColor.withValues(alpha: 0.45),
              label: l10n.habitStatsYearCalendarSkipped,
              labelStyle: labelStyle,
            ),
            _LegendDot(
              key: const Key('habit_stats_year_calendar_legend_done'),
              color: accentColor.withValues(alpha: 0.90),
              label: l10n.habitStatsYearCalendarDone,
              labelStyle: labelStyle,
            ),
            _LegendDot(
              key: const Key('habit_stats_year_calendar_legend_missed'),
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24),
              label: l10n.habitStatsYearCalendarMissed,
              labelStyle: labelStyle,
            ),
          ],
        ),
      ],
    );
  }
}

class _YearCalendarMonthCell extends StatelessWidget {
  final HabitStatsYearCalendarMonth month;
  final Color accentColor;
  final double daySize;
  final double dayGap;

  const _YearCalendarMonthCell({
    required this.month,
    required this.accentColor,
    required this.daySize,
    required this.dayGap,
  });

  @override
  Widget build(BuildContext context) {
    final monthLabel = _capitalizeFirst(context.l10n.monthShort(month.month));
    final rows = _buildRows();

    return Column(
      key: Key('habit_stats_year_calendar_month_${month.month}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          monthLabel,
          key: Key('habit_stats_year_calendar_month_label_${month.month}'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.88),
              ),
        ),
        const SizedBox(height: 6),
        for (var row = 0; row < rows.length; row++) ...[
          if (row > 0) SizedBox(height: dayGap),
          Row(
            children: [
              for (var column = 0; column < rows[row].length; column++) ...[
                if (column > 0) SizedBox(width: dayGap),
                _DayDot(
                  day: rows[row][column],
                  accentColor: accentColor,
                  size: daySize,
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  List<List<HabitStatsYearCalendarDay?>> _buildRows() {
    final slots = <HabitStatsYearCalendarDay?>[
      for (var i = 0; i < month.leadingEmptyDays; i++) null,
      ...month.days,
    ];
    final remainder = slots.length % DateTime.daysPerWeek;
    if (remainder != 0) {
      final tail = DateTime.daysPerWeek - remainder;
      for (var i = 0; i < tail; i++) {
        slots.add(null);
      }
    }
    final rows = <List<HabitStatsYearCalendarDay?>>[];
    for (var index = 0; index < slots.length; index += DateTime.daysPerWeek) {
      rows.add(slots.sublist(index, index + DateTime.daysPerWeek));
    }
    return rows;
  }
}

class _DayDot extends StatelessWidget {
  final HabitStatsYearCalendarDay? day;
  final Color accentColor;
  final double size;

  const _DayDot({
    required this.day,
    required this.accentColor,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (day == null) {
      return SizedBox.square(dimension: size);
    }

    final color = _colorForStatus(
      context,
      day!.status,
      accentColor: accentColor,
    );
    final isToday = _isToday(day!.date);

    return Container(
      key: Key(
          'habit_stats_year_calendar_day_${day!.date.year}_${day!.date.month}_${day!.date.day}_${day!.status.name}'),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.34),
        border: isToday
            ? Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.45),
                width: 0.9,
              )
            : null,
      ),
    );
  }

  bool _isToday(DateTime day) {
    final today = DateTime.now();
    return day.year == today.year && day.month == today.month && day.day == today.day;
  }

  Color _colorForStatus(
    BuildContext context,
    HabitStatsYearCalendarDayStatus status, {
    required Color accentColor,
  }) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final brightness = Theme.of(context).brightness;

    return switch (status) {
      HabitStatsYearCalendarDayStatus.completed =>
        accentColor.withValues(alpha: brightness == Brightness.dark ? 0.90 : 0.84),
      HabitStatsYearCalendarDayStatus.skipped =>
        accentColor.withValues(alpha: brightness == Brightness.dark ? 0.52 : 0.44),
      HabitStatsYearCalendarDayStatus.missed =>
        onSurface.withValues(alpha: brightness == Brightness.dark ? 0.26 : 0.18),
      HabitStatsYearCalendarDayStatus.future =>
        onSurface.withValues(alpha: brightness == Brightness.dark ? 0.18 : 0.11),
      HabitStatsYearCalendarDayStatus.unavailable =>
        onSurface.withValues(alpha: brightness == Brightness.dark ? 0.11 : 0.06),
    };
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final TextStyle? labelStyle;

  const _LegendDot({
    super.key,
    required this.color,
    required this.label,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: labelStyle),
      ],
    );
  }
}

String _capitalizeFirst(String text) {
  if (text.isEmpty) return text;
  return '${text[0].toUpperCase()}${text.substring(1)}';
}
