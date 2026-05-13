import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../l10n/l10n.dart';
import '../../../../../utils/app_theme.dart';
import 'habit_stats_helpers.dart';

class HabitStatsCheckLast7DaysCard extends StatelessWidget {
  const HabitStatsCheckLast7DaysCard({
    super.key,
    required this.days,
    required this.doneStates,
    required this.skippedStates,
  });

  final List<DateTime> days;
  final List<bool> doneStates;
  final List<bool> skippedStates;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return HabitStatsSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.habitStatsTabLastDaysTitle(7),
            style: const TextStyle(
              fontFamily: AppTextStyles.sansFamily,
              fontSize: 45,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F1A17),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List<Widget>.generate(days.length, (index) {
              return Expanded(
                child: Column(
                  children: [
                    Text(
                      dowShort(context, days[index]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.sansFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4F4B46),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _HabitStatsCheckDayCircle(
                      done: doneStates[index],
                      skipped: skippedStates[index],
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _HabitStatsCheckDayCircle extends StatelessWidget {
  const _HabitStatsCheckDayCircle({
    required this.done,
    required this.skipped,
  });

  final bool done;
  final bool skipped;

  @override
  Widget build(BuildContext context) {
    final border = skipped
        ? const Color(0xFFCCC8C1)
        : done
            ? const Color(0xFF6A9E68)
            : const Color(0xFFC9C5BE);
    final fill = skipped
        ? const Color(0xFFEDE9E2)
        : done
            ? const Color(0xFF6A9E68)
            : Colors.transparent;

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: Border.all(color: border, width: 2),
      ),
      alignment: Alignment.center,
      child: done
          ? const Icon(
              CupertinoIcons.check_mark,
              size: 21,
              color: Colors.white,
            )
          : skipped
              ? const Icon(
                  CupertinoIcons.minus,
                  size: 18,
                  color: Color(0xFF8C877F),
                )
              : null,
    );
  }
}

class HabitStatsCountLast7DaysCard extends StatelessWidget {
  const HabitStatsCountLast7DaysCard({
    super.key,
    required this.days,
    required this.values,
    required this.target,
    required this.unit,
  });

  final List<DateTime> days;
  final List<double> values;
  final double target;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final maxValue = math.max(
      target,
      values.fold<double>(0, math.max),
    );
    final chartMax = maxValue <= 0 ? 1.0 : maxValue;

    return HabitStatsSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.habitStatsTabLastDaysTitle(7),
            style: const TextStyle(
              fontFamily: AppTextStyles.sansFamily,
              fontSize: 45,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F1A17),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 230,
            child: Column(
              children: [
                Row(
                  children: List<Widget>.generate(days.length, (index) {
                    return Expanded(
                      child: Text(
                        dowShort(context, days[index]),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.sansFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4F4B46),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        top: (1 - (target / chartMax).clamp(0.0, 1.0)) * 132,
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1.5,
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: const Color(0xFFB9B09F)
                                          .withValues(alpha: 0.8),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${formatValue(target, keepOneDecimal: true)} $unit',
                              style: const TextStyle(
                                fontFamily: AppTextStyles.sansFamily,
                                fontSize: 15,
                                color: Color(0xFF4D4A45),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned.fill(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List<Widget>.generate(days.length, (index) {
                            final value = values[index];
                            final ratio = (value / chartMax).clamp(0.0, 1.0);
                            return Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    width: 28,
                                    height: 132,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEDE9E1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      width: 28,
                                      height: 132 * ratio,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            Color(0xFF568A53),
                                            Color(0xFF7DAC7A),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '${formatValue(value, keepOneDecimal: true)} $unit',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: AppTextStyles.sansFamily,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF3E3A35),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
