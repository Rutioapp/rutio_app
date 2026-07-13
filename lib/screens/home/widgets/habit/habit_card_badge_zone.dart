import 'package:flutter/cupertino.dart';

import 'package:rutio/screens/home/widgets/habit/habit_card_foreground_style.dart';

class HabitCardBadgeZone extends StatelessWidget {
  const HabitCardBadgeZone({
    super.key,
    required this.familyColor,
    required this.compact,
    required this.foregroundStyle,
    this.reminderLabel,
    this.countLabel,
    this.progressLabel,
    this.extraBadges = const <Widget>[],
  });

  static const double _badgeGap = 6;

  final Color familyColor;
  final bool compact;
  final HabitCardForegroundStyle foregroundStyle;
  final String? reminderLabel;
  final String? countLabel;
  final String? progressLabel;
  final List<Widget> extraBadges;

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[
      if (reminderLabel?.trim().isNotEmpty ?? false)
        HabitReminderBadge(
          label: reminderLabel!.trim(),
          familyColor: familyColor,
          compact: compact,
          foregroundStyle: foregroundStyle,
        ),
      if (countLabel?.trim().isNotEmpty ?? false)
        HabitCountBadge(
          label: countLabel!.trim(),
          familyColor: familyColor,
          compact: compact,
          foregroundStyle: foregroundStyle,
        ),
      if (progressLabel?.trim().isNotEmpty ?? false)
        HabitCountBadge(
          label: progressLabel!.trim(),
          familyColor: familyColor,
          compact: compact,
          foregroundStyle: foregroundStyle,
        ),
      ...extraBadges,
    ];

    if (badges.isEmpty) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: Wrap(
        spacing: _badgeGap,
        runSpacing: compact ? 4 : 5,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: badges,
      ),
    );
  }
}

class HabitReminderBadge extends StatelessWidget {
  const HabitReminderBadge({
    super.key,
    required this.label,
    required this.familyColor,
    required this.compact,
    required this.foregroundStyle,
  });

  final String label;
  final Color familyColor;
  final bool compact;
  final HabitCardForegroundStyle foregroundStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          CupertinoIcons.bell_fill,
          size: compact ? 11 : 12,
          color: foregroundStyle.accentColor(familyColor),
          shadows: foregroundStyle.emphasisShadows,
        ),
        SizedBox(width: compact ? 4 : 5),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: compact ? 10.5 : 11,
            fontWeight: FontWeight.w600,
            color: foregroundStyle.secondaryText,
            letterSpacing: -0.1,
            shadows: foregroundStyle.emphasisShadows,
          ),
        ),
      ],
    );
  }
}

class HabitCountBadge extends StatelessWidget {
  const HabitCountBadge({
    super.key,
    required this.label,
    required this.familyColor,
    required this.compact,
    required this.foregroundStyle,
  });

  final String label;
  final Color familyColor;
  final bool compact;
  final HabitCardForegroundStyle foregroundStyle;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: compact ? 10.5 : 11,
        fontWeight: FontWeight.w700,
        color: foregroundStyle.accentColor(familyColor),
        letterSpacing: -0.1,
        shadows: foregroundStyle.emphasisShadows,
      ),
    );
  }
}

class HabitSkippedBadge extends StatelessWidget {
  const HabitSkippedBadge({
    super.key,
    required this.label,
    required this.compact,
    required this.foregroundStyle,
  });

  final String label;
  final bool compact;
  final HabitCardForegroundStyle foregroundStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 9,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: foregroundStyle.translucentSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foregroundStyle.translucentBorder),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: compact ? 10.5 : 11,
          fontWeight: FontWeight.w700,
          color: foregroundStyle.secondaryText,
          letterSpacing: -0.1,
          shadows: foregroundStyle.emphasisShadows,
        ),
      ),
    );
  }
}
