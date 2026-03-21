import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../ui/foundations/ios_foundations.dart';

class WeekNavigator extends StatelessWidget {
  final int weekNumber;
  final String rangeLabel;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;
  final Animation<double> animation;

  const WeekNavigator({
    super.key,
    required this.weekNumber,
    required this.rangeLabel,
    required this.onPreviousWeek,
    required this.onNextWeek,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    // IOS-FIRST IMPROVEMENT START
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final dx = (1 - animation.value) * 10;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: Opacity(
            opacity: 0.86 + (animation.value * 0.14),
            child: child,
          ),
        );
      },
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${context.l10n.weeklyWeekPrefix} $weekNumber',
                  style: IosTypography.title(context).copyWith(
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: IosSpacing.xxs),
                Text(
                  rangeLabel,
                  style: IosTypography.caption(context).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: IosSpacing.sm),
          Padding(
            // IOS-FIRST IMPROVEMENT START
            padding: const EdgeInsets.only(right: IosSpacing.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _WeekNavButton(
                  icon: CupertinoIcons.chevron_left,
                  onPressed: onPreviousWeek,
                  primary: primary,
                ),
                const SizedBox(width: IosSpacing.xs),
                _WeekNavButton(
                  icon: CupertinoIcons.chevron_right,
                  onPressed: onNextWeek,
                  primary: primary,
                ),
              ],
            ),
          ),
          // IOS-FIRST IMPROVEMENT END
        ],
      ),
    );
    // IOS-FIRST IMPROVEMENT END
  }
}

class _WeekNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color primary;

  const _WeekNavButton({
    required this.icon,
    required this.onPressed,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(IosCornerRadius.control),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(IosCornerRadius.control),
            border: Border.all(color: primary.withValues(alpha: 0.10)),
          ),
          child: Icon(icon, color: primary, size: 18),
        ),
      ),
    );
  }
}
