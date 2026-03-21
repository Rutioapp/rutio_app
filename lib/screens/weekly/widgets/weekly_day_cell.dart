import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum WeeklyDayCellKind { empty, done, skip, value }

class WeeklyDayCellData {
  const WeeklyDayCellData._(
    this.kind, {
    this.label,
    this.isAchieved = false,
  });

  const WeeklyDayCellData.empty() : this._(WeeklyDayCellKind.empty);

  const WeeklyDayCellData.done()
      : this._(WeeklyDayCellKind.done, isAchieved: true);

  const WeeklyDayCellData.skip() : this._(WeeklyDayCellKind.skip);

  const WeeklyDayCellData.value(
    String label, {
    bool isAchieved = false,
  }) : this._(
          WeeklyDayCellKind.value,
          label: label,
          isAchieved: isAchieved,
        );

  final WeeklyDayCellKind kind;
  final String? label;
  final bool isAchieved;

  bool get isDone => kind == WeeklyDayCellKind.done;
  bool get isSkipped => kind == WeeklyDayCellKind.skip;
  bool get hasValue => kind == WeeklyDayCellKind.value;
}

class WeeklyDayCell extends StatelessWidget {
  final DateTime day;
  final WeeklyDayCellData state;
  final bool isToday;
  final Color color;
  final double size;
  final VoidCallback? onTap;
  final bool isEnabled;

  const WeeklyDayCell({
    super.key,
    required this.day,
    required this.state,
    required this.isToday,
    required this.color,
    required this.size,
    this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    // IOS-FIRST IMPROVEMENT START
    final skipColor = Color.lerp(color, const Color(0xFFF59E0B), 0.62) ??
        const Color(0xFFF59E0B);
    final hasValue =
        state.hasValue && (state.label?.trim().isNotEmpty ?? false);
    final isCompleted = state.isDone || (hasValue && state.isAchieved);
    final accentColor = state.isSkipped ? skipColor : color;

    final borderColor = state.isSkipped
        ? accentColor.withValues(alpha: isToday ? 0.82 : 0.68)
        : isCompleted
            ? accentColor.withValues(alpha: hasValue ? 0.58 : 0.46)
            : hasValue
                ? accentColor.withValues(alpha: 0.30)
                : isToday
                    ? accentColor.withValues(alpha: 0.72)
                    : accentColor.withValues(alpha: 0.18);

    final fillColor = state.isSkipped
        ? accentColor.withValues(alpha: 0.14)
        : isCompleted
            ? accentColor.withValues(alpha: hasValue ? 0.18 : 0.16)
            : hasValue
                ? accentColor.withValues(alpha: 0.10)
                : isToday
                    ? accentColor.withValues(alpha: 0.10)
                    : accentColor.withValues(alpha: 0.05);

    final childColor = state.isSkipped
        ? accentColor.withValues(alpha: 0.96)
        : isCompleted
            ? accentColor.withValues(alpha: 0.98)
            : hasValue
                ? accentColor.withValues(alpha: 0.82)
                : accentColor.withValues(alpha: 0.40);

    final radius = size >= 28 ? 9.0 : 8.0;
    final iconSize = size >= 28 ? 14.0 : 12.0;
    final valueFontSize = size >= 32 ? 11.0 : 9.6;

    final visualCell = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isEnabled ? fillColor : fillColor.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isEnabled ? borderColor : borderColor.withValues(alpha: 0.55),
          width: isToday && !isCompleted && !state.isSkipped ? 1.35 : 1,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      alignment: Alignment.center,
      child: state.isSkipped
          ? Icon(
              CupertinoIcons.forward_end_fill,
              size: iconSize,
              color: childColor,
            )
          : hasValue
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      state.label!.trim(),
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: valueFontSize,
                        fontWeight:
                            isCompleted ? FontWeight.w800 : FontWeight.w700,
                        color: childColor,
                      ),
                    ),
                  ),
                )
              : state.isDone
                  ? Icon(
                      CupertinoIcons.check_mark,
                      size: iconSize,
                      color: childColor,
                    )
                  : const SizedBox.shrink(),
    );

    final cell = SizedBox(
      height: 44,
      child: Center(
        child: visualCell,
      ),
    );
    // IOS-FIRST IMPROVEMENT END

    if (onTap == null || !isEnabled) {
      return cell;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: cell,
      ),
    );
  }
}
