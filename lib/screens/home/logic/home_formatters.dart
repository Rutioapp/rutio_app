part of 'package:rutio/screens/home/home_screen.dart';

/// Formatting helpers for Home.
///
/// Contains small pure-ish methods for labels, family names and display text.
extension _HomeScreenFormatters on _HomeScreenState {
  Color _familyColor(String id) {
    return FamilyTheme.colorOf(id);
  }

  String? _habitReminderLabel(Map<String, dynamic> habit) {
    final hasReminder =
        getHabitBool(habit, ['remindersEnabled', 'reminderEnabled']) == true;
    if (!hasReminder) return null;

    final rawTime = (getHabitString(habit, ['reminderTime']) ?? '').trim();
    if (rawTime.isEmpty) return null;

    final parsedTime = parseHabitTime(rawTime);
    if (parsedTime == null) return null;

    return formatHabitTimeLabel(parsedTime);
  }

  String _localizedUnitLabel(BuildContext context, String rawUnit) {
    final trimmed = rawUnit.trim();
    if (trimmed.isEmpty) return '';
    return context.l10n.habitUnitLabel(trimmed);
  }

  String _catalogRenderedName(Map<String, dynamic> habitDef, num target) {
    final rawName =
        (habitDef['nameTemplate'] ?? habitDef['name'] ?? habitDef['id'] ?? '')
            .toString();
    final targetText =
        (target % 1 == 0) ? target.toInt().toString() : target.toString();

    return rawName
        .replaceAll('{target}', targetText)
        .replaceAllMapped(RegExp(r'\bX\b'), (_) => targetText);
  }

  String _localizedHabitTitle(
    BuildContext context, {
    required Map<String, dynamic> habit,
    required String fallbackTitle,
    required num target,
  }) {
    final id = (habit['id'] ?? habit['habitId'] ?? '').toString();
    if (id.isEmpty) {
      return fallbackTitle.isEmpty
          ? context.l10n.homeFallbackHabitTitle
          : fallbackTitle;
    }

    final catalogHabit = _catalogHabitsById[id];
    if (catalogHabit == null) {
      return fallbackTitle.isEmpty
          ? context.l10n.homeFallbackHabitTitle
          : fallbackTitle;
    }

    final rawName = (catalogHabit['name'] ?? '').toString();
    final rawTemplate = (catalogHabit['nameTemplate'] ?? '').toString();
    final renderedTemplate =
        rawTemplate.isEmpty ? '' : _catalogRenderedName(catalogHabit, target);

    final shouldTranslate = fallbackTitle.isEmpty ||
        fallbackTitle == rawName ||
        fallbackTitle == renderedTemplate;

    if (!shouldTranslate) {
      return fallbackTitle;
    }

    return context.l10n.catalogHabitName(
      id,
      target: target,
      preferTemplate: renderedTemplate.isNotEmpty,
      fallback: fallbackTitle.isEmpty
          ? context.l10n.homeFallbackHabitTitle
          : fallbackTitle,
    );
  }
}
