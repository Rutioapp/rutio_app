import 'package:flutter/material.dart';

TimeOfDay? parseHabitTime(String value) {
  final parts = value.split(':');
  if (parts.length != 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  if (h < 0 || h > 23 || m < 0 || m > 59) return null;
  return TimeOfDay(hour: h, minute: m);
}

String formatHabitTimeForSave(TimeOfDay time) {
  final hh = time.hour.toString().padLeft(2, '0');
  final mm = time.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

String formatHabitTimeLabel(TimeOfDay time) {
  final hh = time.hour.toString().padLeft(2, '0');
  final mm = time.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

String? getHabitString(dynamic habit, List<String> keys) {
  if (habit == null) return null;
  if (habit is Map) {
    for (final key in keys) {
      final value = habit[key];
      if (value != null) return value.toString();
    }
    return null;
  }

  for (final key in keys) {
    try {
      final value = (habit as dynamic).__get(key);
      if (value != null) return value.toString();
    } catch (_) {}
    try {
      final value = _tryReadProp(habit, key);
      if (value != null) return value.toString();
    } catch (_) {}
  }

  return null;
}

int? getHabitInt(dynamic habit, List<String> keys) {
  final value = getHabitString(habit, keys);
  if (value == null) return null;
  return int.tryParse(value);
}

bool? getHabitBool(dynamic habit, List<String> keys) {
  if (habit == null) return null;
  if (habit is Map) {
    for (final key in keys) {
      final value = habit[key];
      if (value is bool) return value;
      if (value is String) {
        if (value.toLowerCase() == 'true') return true;
        if (value.toLowerCase() == 'false') return false;
      }
    }
    return null;
  }

  for (final key in keys) {
    final value = _tryReadProp(habit, key);
    if (value is bool) return value;
  }

  return null;
}

void setHabitValue(dynamic habit, List<String> keys, dynamic value) {
  if (habit is Map) {
    for (final key in keys) {
      habit[key] = value;
    }
    return;
  }

  for (final key in keys) {
    try {
      switch (key) {
        case 'title':
          (habit as dynamic).title = value;
          break;
        case 'name':
          (habit as dynamic).name = value;
          break;
        case 'description':
          (habit as dynamic).description = value;
          break;
        case 'desc':
          (habit as dynamic).desc = value;
          break;
        case 'subtitle':
          (habit as dynamic).subtitle = value;
          break;
        case 'notes':
          (habit as dynamic).notes = value;
          break;
        case 'note':
          (habit as dynamic).note = value;
          break;
        case 'emoji':
          (habit as dynamic).emoji = value;
          break;
        case 'habitEmoji':
          (habit as dynamic).habitEmoji = value;
          break;
        case 'familyId':
          (habit as dynamic).familyId = value;
          break;
        case 'frequency':
          (habit as dynamic).frequency = value;
          break;
        case 'cadence':
          (habit as dynamic).cadence = value;
          break;
        case 'targetCount':
          (habit as dynamic).targetCount = value;
          break;
        case 'goal':
          (habit as dynamic).goal = value;
          break;
        case 'times':
          (habit as dynamic).times = value;
          break;
        case 'target':
          (habit as dynamic).target = value;
          break;
        case 'trackingType':
          (habit as dynamic).trackingType = value;
          break;
        case 'habitType':
          (habit as dynamic).habitType = value;
          break;
        case 'type':
          (habit as dynamic).type = value;
          break;
        case 'tracking':
          (habit as dynamic).tracking = value;
          break;
        case 'unitLabel':
          (habit as dynamic).unitLabel = value;
          break;
        case 'unit':
          (habit as dynamic).unit = value;
          break;
        case 'counterUnit':
          (habit as dynamic).counterUnit = value;
          break;
        case 'counterStep':
          (habit as dynamic).counterStep = value;
          break;
        case 'step':
          (habit as dynamic).step = value;
          break;
        case 'remindersEnabled':
          (habit as dynamic).remindersEnabled = value;
          break;
        case 'reminderEnabled':
          (habit as dynamic).reminderEnabled = value;
          break;
        case 'reminderTime':
          (habit as dynamic).reminderTime = value;
          break;
        case 'archived':
          (habit as dynamic).archived = value;
          break;
        case 'isArchived':
          (habit as dynamic).isArchived = value;
          break;
      }
    } catch (_) {}
  }
}

dynamic _tryReadProp(dynamic object, String key) {
  try {
    switch (key) {
      case 'title':
        return (object as dynamic).title;
      case 'name':
        return (object as dynamic).name;
      case 'description':
        return (object as dynamic).description;
      case 'desc':
        return (object as dynamic).desc;
      case 'emoji':
        return (object as dynamic).emoji;
      case 'habitEmoji':
        return (object as dynamic).habitEmoji;
      case 'subtitle':
        return (object as dynamic).subtitle;
      case 'notes':
        return (object as dynamic).notes;
      case 'note':
        return (object as dynamic).note;
      case 'frequency':
        return (object as dynamic).frequency;
      case 'cadence':
        return (object as dynamic).cadence;
      case 'targetCount':
        return (object as dynamic).targetCount;
      case 'goal':
        return (object as dynamic).goal;
      case 'times':
        return (object as dynamic).times;
      case 'unitLabel':
        return (object as dynamic).unitLabel;
      case 'unit':
        return (object as dynamic).unit;
      case 'counterUnit':
        return (object as dynamic).counterUnit;
      case 'counterStep':
        return (object as dynamic).counterStep;
      case 'step':
        return (object as dynamic).step;
      case 'remindersEnabled':
        return (object as dynamic).remindersEnabled;
      case 'reminderEnabled':
        return (object as dynamic).reminderEnabled;
      case 'reminderTime':
        return (object as dynamic).reminderTime;
      case 'archived':
        return (object as dynamic).archived;
      case 'isArchived':
        return (object as dynamic).isArchived;
      case 'familyId':
        return (object as dynamic).familyId;
      case 'target':
        return (object as dynamic).target;
      case 'trackingType':
        return (object as dynamic).trackingType;
      case 'habitType':
        return (object as dynamic).habitType;
      case 'type':
        return (object as dynamic).type;
      case 'tracking':
        return (object as dynamic).tracking;
    }
  } catch (_) {}

  return null;
}
