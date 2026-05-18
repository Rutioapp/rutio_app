import 'package:flutter/material.dart';

import '../../../../../l10n/l10n.dart';
import 'habit_stats_helpers.dart';
import 'habit_stats_models.dart';

class HabitStatsYearMonthGrid extends StatelessWidget {
  final List<HabitStatsYearMonthSummary> summaries;
  final bool isCounter;
  final Color accentColor;
  final String countUnitLabel;

  const HabitStatsYearMonthGrid({
    super.key,
    required this.summaries,
    required this.isCounter,
    required this.accentColor,
    this.countUnitLabel = '',
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final crossAxisCount = constraints.maxWidth < 250 ? 2 : 3;

        return GridView.builder(
          key: const Key('habit_stats_year_month_grid'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: summaries.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: crossAxisCount == 3 ? 1.28 : 1.55,
          ),
          itemBuilder: (context, index) {
            final summary = summaries[index];
            return _YearMonthCell(
              summary: summary,
              isCounter: isCounter,
              accentColor: accentColor,
              countUnitLabel: countUnitLabel,
            );
          },
        );
      },
    );
  }
}

class _YearMonthCell extends StatelessWidget {
  final HabitStatsYearMonthSummary summary;
  final bool isCounter;
  final Color accentColor;
  final String countUnitLabel;

  const _YearMonthCell({
    required this.summary,
    required this.isCounter,
    required this.accentColor,
    required this.countUnitLabel,
  });

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(
      summary.status,
      isCurrentMonth: summary.isCurrentMonth,
    );
    final monthLabel = _capitalizeFirst(context.l10n.monthShort(summary.month));
    final valueLabel = _valueLabel();

    return Container(
      key: Key('habit_stats_year_month_cell_${summary.month}_${summary.status.name}'),
      decoration: BoxDecoration(
        color: style.fillColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: style.borderColor,
          width: style.borderWidth,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            monthLabel,
            key: Key('habit_stats_year_month_label_${summary.month}'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: style.labelColor,
                ),
          ),
          const Spacer(),
          if (valueLabel != null)
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                valueLabel,
                key: Key('habit_stats_year_month_value_${summary.month}'),
                maxLines: 1,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11.6,
                      height: 1,
                      fontWeight: style.valueWeight,
                      color: style.valueColor,
                    ),
              ),
            ),
        ],
      ),
    );
  }

  String? _valueLabel() {
    if (summary.status == HabitStatsYearMonthStatus.unavailable ||
        summary.status == HabitStatsYearMonthStatus.future) {
      return null;
    }

    if (!isCounter) {
      final pct = summary.performancePct;
      if (pct == null) return null;
      return '$pct%';
    }

    if (summary.accumulatedValue <= 0) {
      return '0';
    }

    return formatCountMetricValue(
      summary.accumulatedValue,
      unitLabel: countUnitLabel,
    );
  }

  _YearMonthCellStyle _styleFor(
    HabitStatsYearMonthStatus status, {
    required bool isCurrentMonth,
  }) {
    final neutralSurface = const Color(0xFFFDFBF7);
    final mutedSurface = const Color(0xFFFAF6EF);
    final accent = accentColor;

    final base = switch (status) {
      HabitStatsYearMonthStatus.high => _YearMonthCellStyle(
          fillColor: accent.withValues(alpha: 0.20),
          borderColor: accent.withValues(alpha: 0.46),
          labelColor: const Color(0xFF2F251C).withValues(alpha: 0.92),
          valueColor: const Color(0xFF2F251C).withValues(alpha: 0.94),
          valueWeight: FontWeight.w700,
          borderWidth: 1.2,
        ),
      HabitStatsYearMonthStatus.medium => _YearMonthCellStyle(
          fillColor: accent.withValues(alpha: 0.13),
          borderColor: accent.withValues(alpha: 0.34),
          labelColor: const Color(0xFF2F251C).withValues(alpha: 0.86),
          valueColor: const Color(0xFF2F251C).withValues(alpha: 0.88),
          valueWeight: FontWeight.w600,
          borderWidth: 1.1,
        ),
      HabitStatsYearMonthStatus.low => _YearMonthCellStyle(
          fillColor: accent.withValues(alpha: 0.07),
          borderColor: accent.withValues(alpha: 0.24),
          labelColor: const Color(0xFF2F251C).withValues(alpha: 0.82),
          valueColor: const Color(0xFF2F251C).withValues(alpha: 0.82),
          valueWeight: FontWeight.w600,
          borderWidth: 1,
        ),
      HabitStatsYearMonthStatus.empty => _YearMonthCellStyle(
          fillColor: neutralSurface,
          borderColor: const Color(0xFFE9E3D9),
          labelColor: const Color(0xFF2F251C).withValues(alpha: 0.72),
          valueColor: const Color(0xFF2F251C).withValues(alpha: 0.62),
          valueWeight: FontWeight.w500,
          borderWidth: 1,
        ),
      HabitStatsYearMonthStatus.future => _YearMonthCellStyle(
          fillColor: mutedSurface.withValues(alpha: 0.72),
          borderColor: const Color(0xFFE4DCD0).withValues(alpha: 0.75),
          labelColor: const Color(0xFF2F251C).withValues(alpha: 0.42),
          valueColor: const Color(0xFF2F251C).withValues(alpha: 0.38),
          valueWeight: FontWeight.w500,
          borderWidth: 0.95,
        ),
      HabitStatsYearMonthStatus.unavailable => _YearMonthCellStyle(
          fillColor: mutedSurface.withValues(alpha: 0.55),
          borderColor: const Color(0xFFE0D8CC).withValues(alpha: 0.6),
          labelColor: const Color(0xFF2F251C).withValues(alpha: 0.34),
          valueColor: const Color(0xFF2F251C).withValues(alpha: 0.30),
          valueWeight: FontWeight.w500,
          borderWidth: 0.9,
        ),
    };

    if (!isCurrentMonth) return base;

    return _YearMonthCellStyle(
      fillColor: base.fillColor,
      borderColor: accent.withValues(alpha: 0.56),
      labelColor: base.labelColor,
      valueColor: base.valueColor,
      valueWeight: base.valueWeight,
      borderWidth: base.borderWidth + 0.35,
    );
  }
}

class _YearMonthCellStyle {
  final Color fillColor;
  final Color borderColor;
  final Color labelColor;
  final Color valueColor;
  final FontWeight valueWeight;
  final double borderWidth;

  const _YearMonthCellStyle({
    required this.fillColor,
    required this.borderColor,
    required this.labelColor,
    required this.valueColor,
    required this.valueWeight,
    this.borderWidth = 1,
  });
}

String _capitalizeFirst(String text) {
  if (text.isEmpty) return text;
  return '${text[0].toUpperCase()}${text.substring(1)}';
}
