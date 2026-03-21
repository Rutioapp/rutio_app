part of 'diary_entry_composer_sheet.dart';

class _HabitPickOption {
  const _HabitPickOption({
    required this.id,
    required this.name,
    required this.familyId,
    required this.familyName,
    required this.familyColor,
  });

  final String id;
  final String name;
  final String? familyId;
  final String familyName;
  final Color familyColor;
}

class _DiaryComposerInitialValues {
  const _DiaryComposerInitialValues({
    required this.type,
    required this.title,
    required this.reflection,
    required this.mood,
    required this.habitId,
    required this.habitName,
    required this.familyName,
    required this.familyColor,
  });

  factory _DiaryComposerInitialValues.fromWidget(
    DiaryEntryComposerSheet widget,
  ) {
    final entry = widget.editing;
    final hasPresetHabit = widget.presetHabitId != null;
    final splitText = _splitInitialText(entry?.text.trim() ?? '');

    return _DiaryComposerInitialValues(
      type: hasPresetHabit
          ? dt.DiaryEntryType.habit
          : (entry?.type ?? dt.DiaryEntryType.personal),
      title: splitText.$1,
      reflection: splitText.$2,
      mood: entry?.mood,
      habitId: widget.presetHabitId ?? entry?.habitId,
      habitName: widget.presetHabitName ?? entry?.habitName,
      familyName: widget.presetFamilyName ?? entry?.familyName,
      familyColor: widget.presetFamilyColor ?? entry?.familyColor,
    );
  }

  final dt.DiaryEntryType type;
  final String title;
  final String reflection;
  final int? mood;
  final String? habitId;
  final String? habitName;
  final String? familyName;
  final Color? familyColor;
}

class DiaryEntryComposerDraft {
  const DiaryEntryComposerDraft({
    required this.type,
    required this.text,
    this.mood,
    this.habitId,
    this.habitName,
    this.familyName,
    this.familyColor,
  });

  final dt.DiaryEntryType type;
  final String text;
  final int? mood;
  final String? habitId;
  final String? habitName;
  final String? familyName;
  final Color? familyColor;
}
