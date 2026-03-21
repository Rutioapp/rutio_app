import 'package:flutter/material.dart';
import 'package:rutio/ui/behaviours/ios_feedback.dart';
import 'package:rutio/ui/foundations/ios_foundations.dart';

import '../weekly_helpers.dart';
import 'helpers/weekly_ui_lerp.dart';
import 'weekly_day_cell.dart';

class WeeklyHabitRow extends StatelessWidget {
  final String title;
  final String emoji;
  final Color familyColor;
  final List<DateTime> days;
  final List<WeeklyDayCellData> dayStates;
  final DateTime today;

  final double nameColumnWidth;
  final double gap;
  final double expansionT;
  final double dayCellSize;
  final VoidCallback onToggleExpand;
  final Future<void> Function(DateTime day)? onToggleDay;
  final bool isInteractive;

  static const double _emojiSlotWidth = 28.0;
  static const double _textLeftPadding = 8.0;

  const WeeklyHabitRow({
    super.key,
    required this.title,
    required this.emoji,
    required this.familyColor,
    required this.days,
    required this.dayStates,
    required this.today,
    required this.nameColumnWidth,
    required this.gap,
    required this.expansionT,
    required this.dayCellSize,
    required this.onToggleExpand,
    this.onToggleDay,
    this.isInteractive = true,
  });

  @override
  Widget build(BuildContext context) {
    // IOS-FIRST IMPROVEMENT START
    final textStyle = IosTypography.caption(context).copyWith(
      fontSize: uiLerpDouble(0.0, 11.5, expansionT)!,
      fontWeight: FontWeight.w700,
      color: Colors.black.withValues(alpha: 0.74),
      height: 1.08,
    );

    final emojiSize = uiLerpDouble(28.0, 22.0, expansionT)!;
    final emojiFontSize = uiLerpDouble(17.0, 14.0, expansionT)!;
    final verticalPadding = uiLerpDouble(12.0, 10.0, expansionT)!;
    // IOS-FIRST IMPROVEMENT END

    final availableTextWidth =
        (nameColumnWidth - _emojiSlotWidth - _textLeftPadding)
            .clamp(0.0, double.infinity);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: Row(
        children: [
          ClipRect(
            child: SizedBox(
              width: nameColumnWidth,
              child: InkWell(
                onTap: () {
                  IosFeedback.selection();
                  onToggleExpand();
                },
                borderRadius: BorderRadius.circular(IosCornerRadius.control),
                child: Row(
                  children: [
                    SizedBox(
                      width: _emojiSlotWidth,
                      child: SizedBox(
                        height: 44,
                        child: Center(
                          child: Container(
                            width: emojiSize,
                            height: emojiSize,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: familyColor.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              emoji.isEmpty ? '\u2728' : emoji,
                              style: TextStyle(fontSize: emojiFontSize),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (availableTextWidth > 2)
                      Padding(
                        padding: const EdgeInsets.only(left: _textLeftPadding),
                        child: SizedBox(
                          width: availableTextWidth,
                          child: SizedBox(
                            height: 44,
                            child: Opacity(
                              opacity: expansionT.clamp(0.0, 1.0),
                              child: Tooltip(
                                message: title,
                                waitDuration: const Duration(milliseconds: 350),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: true,
                                    style: textStyle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: gap),
          Expanded(
            child: Row(
              children: List.generate(days.length, (index) {
                final day = days[index];
                final isLast = index == days.length - 1;
                final state = index < dayStates.length
                    ? dayStates[index]
                    : const WeeklyDayCellData.empty();
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: isLast ? 0 : gap),
                    child: Align(
                      alignment: Alignment.center,
                      child: WeeklyDayCell(
                        day: day,
                        state: state,
                        isToday: AppDateUtils.isSameDay(day, today),
                        color: familyColor,
                        size: dayCellSize,
                        isEnabled: isInteractive,
                        onTap: isInteractive
                            ? () async {
                                await onToggleDay?.call(day);
                              }
                            : null,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
