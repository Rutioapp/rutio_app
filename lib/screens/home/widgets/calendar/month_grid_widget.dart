import 'package:flutter/material.dart';

class MonthGridWidget extends StatelessWidget {
  final DateTime monthCursor;
  final String habitId;
  final Map<String, dynamic> habitCompletions;
  final Color color;
  final String Function(DateTime d) dateKey;

  const MonthGridWidget({
    super.key,
    required this.monthCursor,
    required this.habitId,
    required this.habitCompletions,
    required this.color,
    required this.dateKey,
  });

  Map<String, dynamic> _map(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
    return <String, dynamic>{};
  }

  @override
  Widget build(BuildContext context) {
    final firstDay =
        DateTime(monthCursor.year, monthCursor.month, 1); // ✅ NUEVO
    final nextMonth =
        DateTime(monthCursor.year, monthCursor.month + 1, 1); // ✅ NUEVO
    final daysInMonth =
        nextMonth.subtract(const Duration(days: 1)).day; // ✅ NUEVO

    // ✅ NUEVO: offset para que la semana empiece en lunes (Mon=1..Sun=7)
    final leadingEmpty = (firstDay.weekday - 1); // 0..6

    final totalCells = leadingEmpty + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: List.generate(7, (col) {
              final cellIndex = row * 7 + col;
              final dayNumber = cellIndex - leadingEmpty + 1;

              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const Expanded(
                    child: SizedBox(height: 18)); // ✅ NUEVO: celda vacía
              }

              final date =
                  DateTime(monthCursor.year, monthCursor.month, dayNumber);
              final key = dateKey(date);
              final dayMap = _map(habitCompletions[key]);
              final isDone =
                  (dayMap[habitId] == true); // ✅ NUEVO: marcado en el historial

              return Expanded(
                child: Container(
                  height: 18,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isDone
                        ? color.withValues(alpha: 0.25)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDone
                          ? color.withValues(alpha: 0.75)
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Text(
                    '$dayNumber',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color:
                          isDone ? color : Colors.black.withValues(alpha: 0.55),
                      height: 1.0,
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}
