import 'package:flutter/material.dart';

import '../../../../../utils/family_theme.dart';
import '../../editor/habit_editor_utils.dart';

class EditHabitTabFormData {
  EditHabitTabFormData({
    required this.familyId,
    required this.emoji,
    required this.emojiWasEdited,
    required this.trackingType,
    required this.targetCount,
    required this.unitLabel,
    required this.frequencyMode,
    required Set<int> selectedDays,
    required this.remindersEnabled,
    required this.reminderTime,
    required this.archived,
    required this.timesPerWeekTarget,
    required this.counterStep,
  }) : selectedDays = Set<int>.from(selectedDays);

  factory EditHabitTabFormData.fromHabit(dynamic habit) {
    final families = availableFamilies;
    final fallbackFamilyId =
        families.isNotEmpty ? families.first : FamilyTheme.fallbackId;

    final savedFamilyId = getHabitString(habit, ['familyId']);
    final familyId =
        families.contains(savedFamilyId) ? savedFamilyId! : fallbackFamilyId;

    var emoji = (getHabitString(habit, ['emoji', 'habitEmoji']) ?? '').trim();
    if (emoji.isEmpty) {
      emoji = FamilyTheme.emojiOf(familyId);
    }

    const defaultTrackingType = 'check';
    final rawTrackingType = (getHabitString(
              habit,
              ['trackingType', 'habitType', 'type', 'tracking'],
            ) ??
            defaultTrackingType)
        .toLowerCase();
    final trackingType =
        (rawTrackingType == 'count' || rawTrackingType == 'counter')
            ? 'count'
            : 'check';

    final rawTarget = getHabitInt(
          habit,
          ['target', 'targetCount', 'goal', 'times', 'timesPerWeekTarget'],
        ) ??
        1;

    final timeOfDay =
        parseHabitTime(getHabitString(habit, ['reminderTime']) ?? '');
    final now = TimeOfDay.now();

    final data = EditHabitTabFormData(
      familyId: familyId,
      emoji: emoji,
      emojiWasEdited: false,
      trackingType: trackingType,
      targetCount: rawTarget < 1 ? 1 : rawTarget,
      unitLabel:
          getHabitString(habit, ['unitLabel', 'unit', 'counterUnit']) ?? '',
      frequencyMode: 'daily',
      selectedDays: const <int>{1, 2, 3, 4, 5, 6, 7},
      remindersEnabled:
          getHabitBool(habit, ['remindersEnabled', 'reminderEnabled']) ?? false,
      reminderTime: DateTime(
        2000,
        1,
        1,
        timeOfDay?.hour ?? now.hour,
        timeOfDay?.minute ?? now.minute,
      ),
      archived: getHabitBool(habit, ['archived', 'isArchived']) ?? false,
      timesPerWeekTarget: rawTarget < 1 ? 1 : rawTarget,
      counterStep: getHabitInt(habit, ['counterStep', 'step']) ?? 1,
    );

    data._hydrateFrequencyFromHabit(habit);
    return data;
  }

  static List<String> get availableFamilies {
    final dynamic families = _readFamilyThemeFamilies();
    if (families is List) {
      return families.whereType<String>().toList(growable: false);
    }
    return FamilyTheme.order;
  }

  String familyId;
  String emoji;
  bool emojiWasEdited;
  String trackingType;
  int targetCount;
  String unitLabel;
  String frequencyMode;
  final Set<int> selectedDays;
  bool remindersEnabled;
  DateTime reminderTime;
  bool archived;
  int timesPerWeekTarget;
  int counterStep;

  Color get currentFamilyColor => FamilyTheme.colorOf(familyId);

  bool get showsCountTargetSection => trackingType == 'count';

  bool get showsWeeklyCheckTargetSection =>
      trackingType == 'check' && frequencyMode == 'timesPerWeek';

  void updateArchivedFromHabit(dynamic habit) {
    archived = getHabitBool(habit, ['archived', 'isArchived']) ?? archived;
  }

  void selectFamily(String nextFamilyId) {
    familyId = nextFamilyId;
    if (!emojiWasEdited) {
      emoji = FamilyTheme.emojiOf(nextFamilyId);
    }
  }

  void setEmoji(String value) {
    emoji = value;
    emojiWasEdited = true;
  }

  void setTrackingTypeToCheck() {
    trackingType = 'check';
    targetCount = 1;
    if (timesPerWeekTarget < 1) {
      timesPerWeekTarget = 1;
    }
  }

  void setTrackingTypeToCount() {
    trackingType = 'count';
    frequencyMode = frequencyMode == 'timesPerWeek' ? 'daily' : frequencyMode;
    if (targetCount < 1) {
      targetCount = 1;
    }
  }

  void toggleSelectedDay(int day) {
    final isSelected = selectedDays.contains(day);
    if (isSelected && selectedDays.length > 1) {
      selectedDays.remove(day);
      return;
    }
    if (!isSelected) {
      selectedDays.add(day);
    }
  }

  List<int> resolvedRoutineDaysForSave() {
    if (frequencyMode != 'specificDays') {
      return <int>[];
    }

    final ordered = selectedDays.toList()..sort();
    return ordered;
  }

  Map<String, dynamic> buildScheduleForSave() {
    final routineDays = resolvedRoutineDaysForSave();
    if (routineDays.isEmpty || routineDays.length == 7) {
      return <String, dynamic>{'type': 'daily'};
    }
    return <String, dynamic>{
      'type': 'weekly',
      'weekdays': routineDays,
    };
  }

  String legacyFrequencyLabel() {
    switch (frequencyMode) {
      case 'specificDays':
      case 'timesPerWeek':
        return 'Semanal';
      default:
        return 'Diario';
    }
  }

  Map<String, dynamic> buildUpdatedHabit({
    required dynamic sourceHabit,
    required String title,
    required String description,
    required String notes,
  }) {
    final updatedHabit = sourceHabit is Map
        ? Map<String, dynamic>.from(sourceHabit)
        : <String, dynamic>{
            'id': getHabitString(sourceHabit, ['id', 'habitId', 'uuid']) ?? '',
          };

    setHabitValue(updatedHabit, ['title', 'name'], title);
    setHabitValue(
      updatedHabit,
      ['description', 'desc', 'subtitle'],
      description,
    );
    setHabitValue(updatedHabit, ['notes', 'note'], notes);
    setHabitValue(updatedHabit, ['emoji', 'habitEmoji'], emoji);
    setHabitValue(updatedHabit, ['familyId'], familyId);
    setHabitValue(
      updatedHabit,
      ['trackingType', 'habitType', 'type', 'tracking'],
      trackingType,
    );
    setHabitValue(
      updatedHabit,
      ['unitLabel', 'unit', 'counterUnit'],
      trackingType == 'count' ? unitLabel.trim() : '',
    );
    setHabitValue(updatedHabit, ['counterStep', 'step'], counterStep);
    setHabitValue(
      updatedHabit,
      ['remindersEnabled', 'reminderEnabled'],
      remindersEnabled,
    );
    setHabitValue(
      updatedHabit,
      ['reminderTime'],
      formatHabitTimeForSave(
        TimeOfDay(hour: reminderTime.hour, minute: reminderTime.minute),
      ),
    );
    setHabitValue(updatedHabit, ['archived', 'isArchived'], archived);
    setHabitValue(updatedHabit, ['frequencyMode'], frequencyMode);
    setHabitValue(
      updatedHabit,
      ['frequency', 'cadence'],
      legacyFrequencyLabel(),
    );

    if (trackingType == 'count') {
      setHabitValue(updatedHabit, ['target', 'targetCount'], targetCount);
      setHabitValue(updatedHabit, ['goal', 'times'], targetCount);
    } else if (showsWeeklyCheckTargetSection) {
      setHabitValue(updatedHabit, ['target', 'targetCount'], 1);
      setHabitValue(
        updatedHabit,
        ['goal', 'times', 'timesPerWeekTarget'],
        timesPerWeekTarget,
      );
    } else {
      setHabitValue(updatedHabit, ['target', 'targetCount'], 1);
      setHabitValue(updatedHabit, ['goal', 'times', 'timesPerWeekTarget'], 1);
    }

    updatedHabit['schedule'] = buildScheduleForSave();
    updatedHabit['routineDays'] = resolvedRoutineDaysForSave();
    return updatedHabit;
  }

  void _hydrateFrequencyFromHabit(dynamic habit) {
    final rawFrequencyMode =
        (getHabitString(habit, ['frequencyMode']) ?? '').trim();
    final rawFrequency =
        (getHabitString(habit, ['frequency', 'cadence']) ?? '').toLowerCase();

    final schedule = habit is Map ? habit['schedule'] : null;
    if (schedule is Map) {
      final type = (schedule['type'] ?? 'daily').toString();
      final weekdays = (schedule['weekdays'] is List)
          ? (schedule['weekdays'] as List)
              .whereType<num>()
              .map((e) => e.toInt())
              .where((day) => day >= 1 && day <= 7)
              .toList(growable: false)
          : const <int>[];

      if (type == 'weekly' && weekdays.isNotEmpty && weekdays.length < 7) {
        frequencyMode = 'specificDays';
        selectedDays
          ..clear()
          ..addAll(weekdays);
      }
    }

    if (rawFrequencyMode == 'timesPerWeek') {
      frequencyMode = 'timesPerWeek';
    } else if (trackingType == 'check' &&
        frequencyMode == 'daily' &&
        rawFrequency.contains('seman') &&
        timesPerWeekTarget > 1) {
      frequencyMode = 'timesPerWeek';
    }

    if (selectedDays.isEmpty) {
      selectedDays.addAll(<int>{1, 2, 3, 4, 5, 6, 7});
    }

    if (trackingType == 'check' && targetCount < 1) {
      targetCount = 1;
    }
    if (timesPerWeekTarget < 1) {
      timesPerWeekTarget = 1;
    }
  }

  static dynamic _readFamilyThemeFamilies() {
    try {
      return (FamilyTheme as dynamic).families;
    } catch (_) {
      return null;
    }
  }
}
