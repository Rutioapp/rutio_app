import 'package:flutter/material.dart';
import 'package:rutio/l10n/l10n.dart';

class StatisticsV3WeeklyActivityShell extends StatelessWidget {
  const StatisticsV3WeeklyActivityShell({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  static const List<int> _weekdays = <int>[
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
    DateTime.sunday,
  ];

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
              for (var index = 0; index < _weekdays.length; index++) ...[
                Expanded(
                  child: _WeekdayActivityColumn(
                    label: l10n.weekdayShort(_weekdays[index]),
                    fillFraction: 0.18,
                  ),
                ),
                if (index < _weekdays.length - 1) const SizedBox(width: 4),
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
  });

  final String label;
  final double fillFraction;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF7A6D5E),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 46,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2EBE0),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
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
            ],
          ),
        ),
      ],
    );
  }
}
