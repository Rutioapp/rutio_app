import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HabitCardBadgeZone extends StatelessWidget {
  const HabitCardBadgeZone({
    super.key,
    required this.familyColor,
    required this.compact,
    this.reminderLabel,
    this.countLabel,
    this.extraBadges = const <Widget>[],
  });

  static const double _badgeGap = 6;

  final Color familyColor;
  final bool compact;
  final String? reminderLabel;
  final String? countLabel;
  final List<Widget> extraBadges;

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[
      if (reminderLabel?.trim().isNotEmpty ?? false)
        HabitReminderBadge(
          label: reminderLabel!.trim(),
          familyColor: familyColor,
          compact: compact,
        ),
      if (countLabel?.trim().isNotEmpty ?? false)
        HabitCountBadge(
          label: countLabel!.trim(),
          familyColor: familyColor,
          compact: compact,
        ),
      ...extraBadges,
    ];

    if (badges.isEmpty) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var index = 0; index < badges.length; index++) ...[
            if (index > 0) const SizedBox(width: _badgeGap),
            badges[index],
          ],
        ],
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
  });

  final String label;
  final Color familyColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          CupertinoIcons.bell_fill,
          size: compact ? 11 : 12,
          color: familyColor.withValues(alpha: 0.88),
        ),
        SizedBox(width: compact ? 4 : 5),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: compact ? 10.5 : 11,
            fontWeight: FontWeight.w600,
            color: Colors.black.withValues(alpha: 0.56),
            letterSpacing: -0.1,
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
  });

  final String label;
  final Color familyColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: compact ? 10.5 : 11,
        fontWeight: FontWeight.w700,
        color: familyColor.withValues(alpha: 0.88),
        letterSpacing: -0.1,
      ),
    );
  }
}
