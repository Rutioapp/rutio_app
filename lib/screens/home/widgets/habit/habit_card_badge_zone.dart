import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HabitCardBadgeZone extends StatelessWidget {
  const HabitCardBadgeZone({
    super.key,
    required this.familyColor,
    required this.compact,
    this.reminderLabel,
    this.countLabel,
    this.progressLabel,
    this.extraBadges = const <Widget>[],
  });

  static const double _badgeGap = 6;

  final Color familyColor;
  final bool compact;
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
        ),
      if (countLabel?.trim().isNotEmpty ?? false)
        HabitCountBadge(
          label: countLabel!.trim(),
          familyColor: familyColor,
          compact: compact,
        ),
      if (progressLabel?.trim().isNotEmpty ?? false)
        HabitCountBadge(
          label: progressLabel!.trim(),
          familyColor: familyColor,
          compact: compact,
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

class HabitSkippedBadge extends StatelessWidget {
  const HabitSkippedBadge({
    super.key,
    required this.label,
    required this.compact,
  });

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final background = brightness == Brightness.dark
        ? const Color(0xFF2C2A25)
        : const Color(0xFFF2EBDD);
    final border = brightness == Brightness.dark
        ? const Color(0xFF474039)
        : const Color(0xFFE1D8C7);
    final foreground = brightness == Brightness.dark
        ? const Color(0xFFD8D1C3)
        : const Color(0xFF72695C);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 9,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: compact ? 10.5 : 11,
          fontWeight: FontWeight.w700,
          color: foreground,
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}
