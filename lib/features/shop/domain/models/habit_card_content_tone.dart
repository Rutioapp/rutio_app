enum HabitCardContentTone {
  dark,
  light,
}

extension HabitCardContentToneX on HabitCardContentTone {
  String get key {
    switch (this) {
      case HabitCardContentTone.dark:
        return 'dark';
      case HabitCardContentTone.light:
        return 'light';
    }
  }

  static HabitCardContentTone fromKey(String? key) {
    switch ((key ?? '').trim()) {
      case 'light':
        return HabitCardContentTone.light;
      case 'dark':
      default:
        return HabitCardContentTone.dark;
    }
  }
}
