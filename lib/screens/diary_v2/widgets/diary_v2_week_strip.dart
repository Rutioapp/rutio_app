import 'package:flutter/material.dart';

import 'diary_v2_styles.dart';

class DiaryV2WeekDay {
  const DiaryV2WeekDay({
    required this.label,
    required this.dayNumber,
    this.isSelected = false,
  });

  final String label;
  final String dayNumber;
  final bool isSelected;
}

class DiaryV2WeekStrip extends StatelessWidget {
  const DiaryV2WeekStrip({
    super.key,
    required this.days,
  });

  final List<DiaryV2WeekDay> days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: days
            .map(
              (day) => Expanded(
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: day.isSelected
                          ? DiaryV2Styles.accentSoft.withValues(alpha: 0.92)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          day.label,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: DiaryV2Styles.mutedText,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          day.dayNumber,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: DiaryV2Styles.text,
                                fontSize: 18,
                              ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: day.isSelected ? 1 : 0,
                          child: Container(
                            width: 8,
                            height: 8,
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
            )
            .toList(),
      ),
    );
  }
}
