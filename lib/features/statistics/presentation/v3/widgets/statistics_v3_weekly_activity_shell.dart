import 'package:flutter/material.dart';
import 'package:rutio/features/statistics/presentation/v3/models/statistics_v3_view_data.dart';
import 'package:rutio/l10n/l10n.dart';

class StatisticsV3WeeklyActivityShell extends StatelessWidget {
  const StatisticsV3WeeklyActivityShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.days,
  });

  final String title;
  final String subtitle;
  final List<StatisticsV3WeeklyActivityDay> days;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9E3D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2F251C),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6A6155),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var index = 0; index < days.length; index++) ...[
                () {
                  final item = days[index];
                  final fillFraction = item.isFuture
                      ? 0.0
                      : (item.percentage / 100).clamp(0.0, 1.0);

                  return Expanded(
                    child: _WeekdayActivityColumn(
                      label: l10n.weekdayShort(item.date.weekday),
                      fillFraction: fillFraction,
                      isToday: item.isToday,
                      isFuture: item.isFuture,
                    ),
                  );
                }(),
                if (index < days.length - 1) const SizedBox(width: 4),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekdayActivityColumn extends StatelessWidget {
  const _WeekdayActivityColumn({
    required this.label,
    required this.fillFraction,
    required this.isToday,
    required this.isFuture,
  });

  final String label;
  final double fillFraction;
  final bool isToday;
  final bool isFuture;

  @override
  Widget build(BuildContext context) {
    final labelColor = isFuture
        ? const Color(0xFFB9B0A5)
        : (isToday ? const Color(0xFF5B4A37) : const Color(0xFF7A6D5E));
    final trackColor = isFuture
        ? const Color(0xFFF7F3EC)
        : const Color(0xFFF2EBE0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 46,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: isToday ? 11 : 10,
                decoration: BoxDecoration(
                  color: trackColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              if (fillFraction > 0)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: isToday ? 11 : 10,
                    child: FractionallySizedBox(
                      heightFactor: fillFraction,
                      widthFactor: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x6FB79A75),
                              Color(0xA8D4C1AE),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
