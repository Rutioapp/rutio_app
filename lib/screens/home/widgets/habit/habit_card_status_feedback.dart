import 'package:flutter/cupertino.dart';
import 'package:rutio/ui/foundations/ios_foundations.dart';

enum HomeHabitStatusFeedbackKind {
  completed,
  skipped,
}

class HabitCardStatusFeedbackMotionConfig {
  const HabitCardStatusFeedbackMotionConfig._();

  static const Duration completedHoldDuration = Duration(milliseconds: 100);
  static const Duration skippedHoldDuration = Duration(milliseconds: 210);
  static const Duration completedCollapseDuration = Duration(milliseconds: 300);
  static const Duration skippedCollapseDuration = Duration(milliseconds: 290);
  static const double springMass = 1;
  static const double springStiffness = 400;
  static const double springDamping = 42;
  static const double skippedEntrySpringStiffness = 280;
  static const double skippedEntrySpringDamping = 38;
  static const double fadeStartCollapseFraction = 0.62;
  static const double statusIconHorizontalInset = 24;
  static const double tickRevealStartFraction = 0.10;
  static const double tickRevealEndFraction = 0.75;
  static const double tickInitialScale = 0.94;
  static const double tickFinalScale = 1;
  static const Curve tickRevealCurve = Curves.easeOutCubic;
  static const double skippedRevealExtent = 234;

  static Duration holdDurationFor(HomeHabitStatusFeedbackKind kind) {
    return kind == HomeHabitStatusFeedbackKind.skipped
        ? skippedHoldDuration
        : completedHoldDuration;
  }

  static Duration collapseDurationFor(HomeHabitStatusFeedbackKind kind) {
    return kind == HomeHabitStatusFeedbackKind.skipped
        ? skippedCollapseDuration
        : completedCollapseDuration;
  }
}

class HabitCardStatusFeedback extends StatelessWidget {
  const HabitCardStatusFeedback({
    super.key,
    required this.kind,
    this.borderRadius,
    this.semanticLabel,
    this.iconProgress = 1,
    this.iconOpacityKey,
  });

  static const Color previousCompletedBackground = CupertinoColors.systemGreen;
  static const Color previousSkippedBackground = Color(0xFFC28A2B);
  static const Color completedBackground = Color(0xFFBCD8C0);
  static const Color completedBorder = Color(0xFF94B89D);
  static const Color completedIcon = Color(0xFF284A32);
  static const Color skippedBackground = Color(0xFFD0BAA2);
  static const Color skippedBorder = Color(0xFFB58F6D);
  static const Color skippedIcon = Color(0xFF503B2B);

  final HomeHabitStatusFeedbackKind kind;
  final BorderRadius? borderRadius;
  final String? semanticLabel;
  final double iconProgress;
  final Key? iconOpacityKey;

  @override
  Widget build(BuildContext context) {
    final isCompleted = kind == HomeHabitStatusFeedbackKind.completed;
    final background = isCompleted ? completedBackground : skippedBackground;
    final border = isCompleted ? completedBorder : skippedBorder;
    final iconColor = isCompleted ? completedIcon : skippedIcon;
    final icon = isCompleted
        ? CupertinoIcons.check_mark_circled_solid
        : CupertinoIcons.forward_end_fill;
    final progress = iconProgress.clamp(0.0, 1.0).toDouble();
    final iconOpacity = _lerpFromInterval(
      progress,
      start: HabitCardStatusFeedbackMotionConfig.tickRevealStartFraction,
      end: HabitCardStatusFeedbackMotionConfig.tickRevealEndFraction,
      curve: HabitCardStatusFeedbackMotionConfig.tickRevealCurve,
    );
    final iconScale = HabitCardStatusFeedbackMotionConfig.tickInitialScale +
        ((HabitCardStatusFeedbackMotionConfig.tickFinalScale -
                HabitCardStatusFeedbackMotionConfig.tickInitialScale) *
            iconOpacity);

    return IgnorePointer(
      ignoring: true,
      child: Semantics(
        container: true,
        liveRegion: true,
        label: semanticLabel ??
            (isCompleted ? 'Habito completado' : 'Habito saltado'),
        child: ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: background,
              border: Border.all(color: border),
              borderRadius:
                  borderRadius ?? BorderRadius.circular(IosCornerRadius.card),
            ),
            child: Align(
              alignment:
                  isCompleted ? Alignment.centerLeft : Alignment.centerRight,
              child: Padding(
                padding: isCompleted
                    ? const EdgeInsets.only(
                        left: HabitCardStatusFeedbackMotionConfig
                            .statusIconHorizontalInset,
                      )
                    : const EdgeInsets.only(
                        right: HabitCardStatusFeedbackMotionConfig
                            .statusIconHorizontalInset,
                      ),
                child: Opacity(
                  key: iconOpacityKey,
                  opacity: iconOpacity,
                  child: Transform.scale(
                    key: const Key('habitCardStatusFeedbackIconScale'),
                    scale: iconScale,
                    child: Icon(
                      icon,
                      key: const Key('habitCardStatusFeedbackIcon'),
                      size: 32,
                      color: iconColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _lerpFromInterval(
    double value, {
    required double start,
    required double end,
    Curve curve = Curves.linear,
  }) {
    if (value <= start) return 0;
    if (value >= end) return 1;
    return curve.transform((value - start) / (end - start));
  }
}
