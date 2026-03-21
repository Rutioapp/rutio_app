import 'package:flutter/material.dart';

class WeekStripWidget extends StatelessWidget {
  final DateTime selectedDay;
  final ValueChanged<DateTime> onSelectedDay;

  // Accent color (family color).
  //
  // Backward compatibility: older code may pass `primaryDark`. If both are
  // provided, `accentColor` wins.
  final Color accentColor;

  const WeekStripWidget({
    super.key,
    required this.selectedDay,
    required this.onSelectedDay,
    Color? accentColor,
    Color? primaryDark,
  })  : accentColor = (accentColor ?? primaryDark ?? const Color(0xFF6D4CFF)),
        assert(
          accentColor != null || primaryDark != null,
          'WeekStripWidget: provide accentColor (preferred) or primaryDark.',
        );

  DateTime _onlyDate(DateTime d) => DateTime(d.year, d.month, d.day);

  String _weekdayShort(DateTime d) {
    // 3-letter-ish spanish labels to match the minimal weekly card.
    const labels = ['lun', 'mar', 'mie', 'jue', 'vie', 'sab', 'dom'];
    final i = (d.weekday - 1).clamp(0, 6);
    return labels[i];
  }

  List<DateTime> _daysForStrip(DateTime anchor) {
    // Semana (L..D) de la fecha "anchor"
    final a = _onlyDate(anchor);
    final monday = a.subtract(Duration(days: a.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    final days = _daysForStrip(selectedDay);
    final today = _onlyDate(DateTime.now());

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v == 0) return;

        // 👉 No hacemos setState aquí (este widget es stateless).
        //    Emitimos el nuevo día al padre, y el padre actualiza su estado.
        final next = (v > 0)
            ? _onlyDate(selectedDay.subtract(const Duration(days: 7)))
            : _onlyDate(selectedDay.add(const Duration(days: 7)));

        onSelectedDay(next);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 22),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              blurRadius: 14,
              offset: const Offset(0, 8),
              color: Colors.black.withValues(alpha: 0.06),
            ),
          ],
        ),
        child: Row(
          children: [
            for (final d in days) ...[
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onSelectedDay(_onlyDate(d)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: _onlyDate(d) == _onlyDate(selectedDay)
                          ? accentColor.withValues(alpha: 0.10)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _weekdayShort(d),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: Colors.black.withValues(alpha: 0.75),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          height: 28,
                          width: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _onlyDate(d) == _onlyDate(selectedDay)
                                ? accentColor.withValues(alpha: 0.88)
                                : Colors.transparent,
                            border: Border.all(
                              color: _onlyDate(d) == today
                                  ? accentColor.withValues(alpha: 0.95)
                                  : accentColor.withValues(alpha: 0.55),
                              width: _onlyDate(d) == today ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            '${d.day}'.padLeft(2, '0'),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              color: _onlyDate(d) == _onlyDate(selectedDay)
                                  ? Colors.white
                                  : Colors.black.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
