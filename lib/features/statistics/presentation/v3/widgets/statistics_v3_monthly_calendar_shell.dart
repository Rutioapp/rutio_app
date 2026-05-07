import 'dart:math' as math;

import 'package:flutter/material.dart';

class StatisticsV3MonthlyCalendarShell extends StatelessWidget {
  const StatisticsV3MonthlyCalendarShell({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  static const _border = Color(0xFFE9E3D9);
  static const _cream = Color(0xFFFDFBF7);
  static const _text = Color(0xFF2F251C);
  static const _mutedText = Color(0xFF6A6155);
  static const _cellBase = Color(0xFFD8D1C5);
  static const _cellBorder = Color(0xFFE5DED3);
  static const _todayBorder = Color(0xFF9AA789);
  static const _todayFill = Color(0xFFE8EFE1);
  static const _futureFill = Color(0xFFF0EBE3);
  static const _placeholderFill = Color(0x00FFFFFF);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    const daysPerWeek = 7;
    final leadingDays =
        (firstDay.weekday - DateTime.monday + daysPerWeek) % daysPerWeek;
    final totalCells = leadingDays + daysInMonth;
    final rows = math.max(4, (totalCells / daysPerWeek).ceil());
    final cellCount = rows * daysPerWeek;
    final todayDay = now.year == firstDay.year && now.month == firstDay.month
        ? now.day
        : -1;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
      decoration: BoxDecoration(
        color: _cream.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 172;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: compact ? 23 : 24,
                    child: Row(
                      children: [
                        Container(
                          width: compact ? 22 : 24,
                          height: compact ? 22 : 24,
                          decoration: BoxDecoration(
                            color: _todayBorder.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.calendar_month_rounded,
                            size: compact ? 15 : 16,
                            color: _todayBorder,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              title,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: compact ? 13.4 : 14.2,
                                height: 1,
                                fontWeight: FontWeight.w700,
                                color: _text,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.1,
                      fontWeight: FontWeight.w500,
                      color: _mutedText,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              );
            },
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: cellCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              if (index < leadingDays || index >= leadingDays + daysInMonth) {
                return _CalendarCell(
                  fillColor: _placeholderFill,
                  borderColor: _cellBorder.withValues(alpha: 0.25),
                  dotColor: _cellBase.withValues(alpha: 0.20),
                  showDot: false,
                );
              }

              final dayNumber = index - leadingDays + 1;
              final isToday = dayNumber == todayDay;
              final isFuture = todayDay != -1 && dayNumber > todayDay;
              final fillColor = isToday
                  ? _todayFill
                  : isFuture
                      ? _futureFill.withValues(alpha: 0.48)
                      : _cellBase.withValues(alpha: 0.52);

              return _CalendarCell(
                fillColor: fillColor,
                borderColor: isToday
                    ? _todayBorder.withValues(alpha: 0.72)
                    : _cellBorder,
                dotColor: isFuture
                    ? _cellBase.withValues(alpha: 0.45)
                    : _todayBorder.withValues(alpha: 0.45),
                showDot: true,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CalendarCell extends StatelessWidget {
  const _CalendarCell({
    required this.fillColor,
    required this.borderColor,
    required this.dotColor,
    required this.showDot,
  });

  final Color fillColor;
  final Color borderColor;
  final Color dotColor;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: borderColor),
      ),
      child: Center(
        child: Container(
          width: showDot ? 6 : 0,
          height: showDot ? 6 : 0,
          decoration: BoxDecoration(
            color: showDot ? dotColor : Colors.transparent,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
