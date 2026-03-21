import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';

class DiaryDayHeader extends StatelessWidget {
  const DiaryDayHeader({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final label = _formatDay(context, date);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.56),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF8E8078),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
          ),
        ),
      ],
    );
  }

  static String _formatDay(BuildContext context, DateTime d) {
    final w = context.l10n.weekdayShort(d.weekday);
    final m = context.l10n.monthShort(d.month);
    return '$w, ${d.day} $m';
  }
}
