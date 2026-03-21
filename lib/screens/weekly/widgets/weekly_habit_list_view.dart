import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/ui/foundations/ios_foundations.dart';
import 'package:rutio/utils/family_theme.dart';

import '../weekly_helpers.dart';
import 'helpers/weekly_ui_lerp.dart';
import 'weekly_day_cell.dart';
import 'weekly_habit_row.dart';

class WeeklyHabitListRowData {
  const WeeklyHabitListRowData({
    required this.title,
    required this.emoji,
    required this.familyColor,
    required this.dayStates,
    required this.isInteractive,
    required this.onToggleDay,
  });

  final String title;
  final String emoji;
  final Color familyColor;
  final List<WeeklyDayCellData> dayStates;
  final bool isInteractive;
  final Future<void> Function(DateTime day)? onToggleDay;
}

class WeeklyHabitListView extends StatelessWidget {
  const WeeklyHabitListView({
    super.key,
    required this.habitsCount,
    required this.days,
    required this.rows,
    required this.today,
    required this.expansionT,
    required this.showNames,
    required this.onToggleExpand,
    required this.onOpenDailyView,
  });

  static const double _emojiSlotWidth = 30.0;
  static const double _nameGap = 8.0;

  final int habitsCount;
  final List<DateTime> days;
  final List<WeeklyHabitListRowData> rows;
  final DateTime today;
  final double expansionT;
  final bool showNames;
  final VoidCallback onToggleExpand;
  final VoidCallback onOpenDailyView;

  @override
  Widget build(BuildContext context) {
    final accentColor = FamilyTheme.colorOf(FamilyTheme.discipline);

    return ListView(
      // IOS-FIRST IMPROVEMENT START
      clipBehavior: Clip.hardEdge,
      // IOS-FIRST IMPROVEMENT END
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(
        IosSpacing.lg,
        IosSpacing.sm,
        IosSpacing.lg,
        MediaQuery.paddingOf(context).bottom + IosSpacing.xl,
      ),
      children: [
        // IOS-FIRST IMPROVEMENT START
        Text(
          context.l10n.weeklyActiveHabitsCount(habitsCount.toString()),
          style: IosTypography.caption(context).copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: accentColor.withValues(alpha: 0.88),
          ),
        ),
        const SizedBox(height: IosSpacing.sm),
        if (rows.isEmpty)
          _WeeklyEmptyStateCard(
            onOpenDailyView: onOpenDailyView,
          )
        else
          IosFrostedCard(
            elevated: true,
            padding: const EdgeInsets.all(IosSpacing.sm),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final contentWidth = constraints.maxWidth;
                final dayCount = days.isEmpty ? 7 : days.length;
                final gap = uiLerpDouble(6.0, 4.0, expansionT)!;

                final expandedTextWidth =
                    (contentWidth * 0.26).clamp(76.0, 112.0);
                final collapsedLeftColumnWidth = _emojiSlotWidth;
                final expandedLeftColumnWidth =
                    _emojiSlotWidth + _nameGap + expandedTextWidth;

                final leftColumnWidth = uiLerpDouble(
                  collapsedLeftColumnWidth,
                  expandedLeftColumnWidth,
                  expansionT,
                )!;

                final daysContentWidth =
                    (contentWidth - leftColumnWidth - gap).clamp(
                  0.0,
                  double.infinity,
                );
                final daySlotRaw = dayCount <= 0
                    ? 24.0
                    : (daysContentWidth - ((dayCount - 1) * gap)) / dayCount;
                final dayCellSize = daySlotRaw.clamp(24.0, 44.0);

                final dayNameStyle = IosTypography.caption(context).copyWith(
                  fontSize: uiLerpDouble(10.0, 8.0, expansionT)!,
                  fontWeight: FontWeight.w700,
                  color: accentColor.withValues(alpha: 0.70),
                  letterSpacing: uiLerpDouble(0.25, 0.05, expansionT)!,
                  height: 1.0,
                );

                final dayNumberStyle = IosTypography.body(context).copyWith(
                  fontSize: uiLerpDouble(13.0, 10.0, expansionT)!,
                  fontWeight: FontWeight.w800,
                  color: accentColor.withValues(alpha: 0.92),
                  height: 1.0,
                );

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        0,
                        IosSpacing.xs,
                        0,
                        IosSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: leftColumnWidth),
                          SizedBox(width: gap),
                          Expanded(
                            child: Row(
                              children: List.generate(dayCount, (index) {
                                final day = days[index];
                                final isToday =
                                    AppDateUtils.isSameDay(day, today);
                                final isLast = index == dayCount - 1;

                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                        right: isLast ? 0 : gap),
                                    child: SizedBox(
                                      child: Column(
                                        children: [
                                          Text(
                                            _weekdayLabel(context, day),
                                            style: dayNameStyle,
                                          ),
                                          SizedBox(
                                            height: uiLerpDouble(
                                              6,
                                              4,
                                              expansionT,
                                            )!,
                                          ),
                                          SizedBox(
                                            width: dayCellSize,
                                            height: dayCellSize,
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                color: isToday
                                                    ? accentColor.withValues(
                                                        alpha: 0.14)
                                                    : Colors.white.withValues(
                                                        alpha: 0.24),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  uiLerpDouble(
                                                    12,
                                                    10,
                                                    expansionT,
                                                  )!,
                                                ),
                                                border: Border.all(
                                                  color: isToday
                                                      ? accentColor.withValues(
                                                          alpha: 0.32)
                                                      : Colors.white.withValues(
                                                          alpha: 0.22),
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  day.day
                                                      .toString()
                                                      .padLeft(2, '0'),
                                                  style:
                                                      dayNumberStyle.copyWith(
                                                    color: isToday
                                                        ? accentColor
                                                        : dayNumberStyle.color,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: accentColor.withValues(alpha: 0.08),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        0,
                        IosSpacing.xs,
                        0,
                        IosSpacing.xs,
                      ),
                      child: Column(
                        children: [
                          for (int i = 0; i < rows.length; i++) ...[
                            WeeklyHabitRow(
                              title: rows[i].title,
                              emoji: rows[i].emoji,
                              familyColor: rows[i].familyColor,
                              days: days,
                              dayStates: rows[i].dayStates,
                              today: today,
                              nameColumnWidth: leftColumnWidth,
                              gap: gap,
                              expansionT: expansionT,
                              dayCellSize: dayCellSize,
                              onToggleExpand: onToggleExpand,
                              isInteractive: rows[i].isInteractive,
                              onToggleDay: rows[i].onToggleDay,
                            ),
                            if (i != rows.length - 1)
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: accentColor.withValues(alpha: 0.06),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        if (!showNames && rows.isNotEmpty) ...[
          const SizedBox(height: IosSpacing.sm),
          Text(
            context.l10n.weeklyShowHabitNameHint,
            textAlign: TextAlign.center,
            style: IosTypography.caption(context).copyWith(
              color: accentColor.withValues(alpha: 0.48),
            ),
          ),
        ],
        // IOS-FIRST IMPROVEMENT END
      ],
    );
  }

  static String _weekdayLabel(BuildContext context, DateTime day) {
    return context.l10n.weekdayLetter(day.weekday);
  }
}

// IOS-FIRST IMPROVEMENT START
class _WeeklyEmptyStateCard extends StatelessWidget {
  final VoidCallback onOpenDailyView;

  const _WeeklyEmptyStateCard({
    required this.onOpenDailyView,
  });

  @override
  Widget build(BuildContext context) {
    return IosFrostedCard(
      elevated: true,
      padding: const EdgeInsets.all(IosSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: FamilyTheme.colorOf(FamilyTheme.discipline)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(IosCornerRadius.chip),
            ),
            alignment: Alignment.center,
            child: Icon(
              CupertinoIcons.calendar,
              size: 24,
              color: FamilyTheme.colorOf(FamilyTheme.discipline),
            ),
          ),
          const SizedBox(height: IosSpacing.md),
          Text(
            context.l10n.homeEmptyStateSingleLine,
            style: IosTypography.title(context),
          ),
          const SizedBox(height: IosSpacing.xs),
          Text(
            context.l10n.homeEmptyStateMultiline.replaceAll('`n', '\n'),
            style: IosTypography.body(context),
          ),
          const SizedBox(height: IosSpacing.lg),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(
              horizontal: IosSpacing.md,
              vertical: IosSpacing.sm,
            ),
            color: FamilyTheme.colorOf(FamilyTheme.discipline),
            borderRadius: BorderRadius.circular(IosCornerRadius.control),
            onPressed: onOpenDailyView,
            child: Text(context.l10n.weeklyViewMenuDailyTitle),
          ),
        ],
      ),
    );
  }
}
// IOS-FIRST IMPROVEMENT END
