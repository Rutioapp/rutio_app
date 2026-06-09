import 'package:flutter/material.dart';

import 'diary_v2_styles.dart';

class DiaryV2WeekDay {
  const DiaryV2WeekDay({
    required this.label,
    required this.dayNumber,
    required this.date,
    this.isSelected = false,
  });

  final String label;
  final String dayNumber;
  final DateTime date;
  final bool isSelected;
}

class DiaryV2WeekStrip extends StatelessWidget {
  const DiaryV2WeekStrip({
    super.key,
    required this.days,
    this.onDaySelected,
  });

  final List<DiaryV2WeekDay> days;
  final ValueChanged<DiaryV2WeekDay>? onDaySelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DiaryV2Styles.weekStripOuterHorizontalPadding,
        vertical: DiaryV2Styles.weekStripOuterVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.26),
        borderRadius: BorderRadius.circular(DiaryV2Styles.cardRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: days
            .map(
              (day) => Expanded(
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(
                        DiaryV2Styles.weekStripItemRadius,
                      ),
                      onTap: onDaySelected == null
                          ? null
                          : () => onDaySelected!(day),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        constraints: const BoxConstraints(
                          minHeight: DiaryV2Styles.weekStripMinItemHeight,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: day.isSelected
                              ? DiaryV2Styles.weekStripSelectedHorizontalPadding
                              : DiaryV2Styles.weekStripItemHorizontalPadding,
                          vertical: DiaryV2Styles.weekStripItemVerticalPadding,
                        ),
                        decoration: BoxDecoration(
                          color: day.isSelected
                              ? DiaryV2Styles.accentSoft.withValues(alpha: 0.94)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(
                            DiaryV2Styles.weekStripItemRadius,
                          ),
                          boxShadow: day.isSelected
                              ? const [
                                  BoxShadow(
                                    color: Color(0x18B86E1C),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              day.label,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: day.isSelected
                                        ? DiaryV2Styles.accentDeep
                                        : DiaryV2Styles.mutedText,
                                    fontSize: DiaryV2Styles.weekStripDayFontSize,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              day.dayNumber,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: day.isSelected
                                        ? DiaryV2Styles.textStrong
                                        : DiaryV2Styles.text,
                                    fontSize:
                                        DiaryV2Styles.weekStripDateFontSize,
                                    fontWeight: day.isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 180),
                              opacity: day.isSelected ? 1 : 0,
                              child: Container(
                                width: DiaryV2Styles.weekStripDotSize,
                                height: DiaryV2Styles.weekStripDotSize,
                                decoration: const BoxDecoration(
                                  color: DiaryV2Styles.accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
