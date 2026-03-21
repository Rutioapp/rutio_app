import 'package:flutter/material.dart';

import 'package:rutio/l10n/l10n.dart';

class WeekdayRow extends StatelessWidget {
  const WeekdayRow({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Row(
      children: [
        _WeekdayLabel(l10n.weekdayLetter(DateTime.monday)),
        _WeekdayLabel(l10n.weekdayLetter(DateTime.tuesday)),
        _WeekdayLabel(l10n.weekdayLetter(DateTime.wednesday)),
        _WeekdayLabel(l10n.weekdayLetter(DateTime.thursday)),
        _WeekdayLabel(l10n.weekdayLetter(DateTime.friday)),
        _WeekdayLabel(l10n.weekdayLetter(DateTime.saturday)),
        _WeekdayLabel(l10n.weekdayLetter(DateTime.sunday)),
      ],
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String t;
  const _WeekdayLabel(this.t);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          t,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.black.withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }
}
