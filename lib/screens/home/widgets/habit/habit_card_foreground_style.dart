import 'package:flutter/material.dart';

import 'package:rutio/features/shop/domain/models/habit_card_content_tone.dart';

class HabitCardForegroundStyle {
  const HabitCardForegroundStyle({
    required this.tone,
    required this.primaryText,
    required this.secondaryText,
    required this.iconColor,
    required this.translucentSurface,
    required this.translucentBorder,
    required this.progressTrackColor,
    required this.controlSurface,
    required this.controlBorder,
    required this.controlIcon,
    required this.emphasisShadows,
  });

  final HabitCardContentTone tone;
  final Color primaryText;
  final Color secondaryText;
  final Color iconColor;
  final Color translucentSurface;
  final Color translucentBorder;
  final Color progressTrackColor;
  final Color controlSurface;
  final Color controlBorder;
  final Color controlIcon;
  final List<Shadow> emphasisShadows;

  Color accentColor(Color base) {
    switch (tone) {
      case HabitCardContentTone.dark:
        return base.withValues(alpha: 0.88);
      case HabitCardContentTone.light:
        return Color.lerp(base, Colors.white, 0.38)!.withValues(alpha: 0.96);
    }
  }

  Color accentSurface(Color base) {
    switch (tone) {
      case HabitCardContentTone.dark:
        return base.withValues(alpha: 0.14);
      case HabitCardContentTone.light:
        return Colors.white.withValues(alpha: 0.18);
    }
  }

  Color accentBorder(Color base) {
    switch (tone) {
      case HabitCardContentTone.dark:
        return base.withValues(alpha: 0.28);
      case HabitCardContentTone.light:
        return Colors.white.withValues(alpha: 0.22);
    }
  }
}

const List<Shadow> _lightToneShadows = <Shadow>[
  Shadow(
    color: Color(0x52000000),
    offset: Offset(0, 1),
    blurRadius: 3,
  ),
];

const HabitCardForegroundStyle _darkToneStyle = HabitCardForegroundStyle(
  tone: HabitCardContentTone.dark,
  primaryText: Color(0xFF25221F),
  secondaryText: Color(0xB325221F),
  iconColor: Color(0xFF25221F),
  translucentSurface: Color(0xB8FFFFFF),
  translucentBorder: Color(0x14000000),
  progressTrackColor: Color(0x14000000),
  controlSurface: Color(0xB8FFFFFF),
  controlBorder: Color(0x14000000),
  controlIcon: Color(0x9925221F),
  emphasisShadows: <Shadow>[],
);

const HabitCardForegroundStyle _lightToneStyle = HabitCardForegroundStyle(
  tone: HabitCardContentTone.light,
  primaryText: Color(0xFFF9F7F2),
  secondaryText: Color(0xD9F9F7F2),
  iconColor: Color(0xFFF9F7F2),
  translucentSurface: Color(0x26FFFFFF),
  translucentBorder: Color(0x38FFFFFF),
  progressTrackColor: Color(0x33FFFFFF),
  controlSurface: Color(0x26FFFFFF),
  controlBorder: Color(0x38FFFFFF),
  controlIcon: Color(0xFFF9F7F2),
  emphasisShadows: _lightToneShadows,
);

const LinearGradient habitCardContentScrim = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: <Color>[
    Color(0x52000000),
    Color(0x26000000),
    Color(0x00000000),
  ],
  stops: <double>[0.0, 0.55, 1.0],
);

HabitCardForegroundStyle resolveHabitCardForegroundStyle(
  HabitCardContentTone tone,
) {
  switch (tone) {
    case HabitCardContentTone.dark:
      return _darkToneStyle;
    case HabitCardContentTone.light:
      return _lightToneStyle;
  }
}
