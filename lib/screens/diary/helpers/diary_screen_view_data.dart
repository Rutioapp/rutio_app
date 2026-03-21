import 'package:flutter/material.dart';

import '../../../models/diary_entry.dart';
import '../../../stores/user_state_store.dart';
import '../models/diary_types.dart';
import '../widgets/diary_header.dart';

class DiaryScreenViewData {
  const DiaryScreenViewData({
    required this.groupedEntries,
    required this.sortedDays,
    required this.entriesCount,
    required this.todayEntriesCount,
    required this.dailyXp,
  });

  final Map<DateTime, List<DiaryEntryUi>> groupedEntries;
  final List<DateTime> sortedDays;
  final int entriesCount;
  final int todayEntriesCount;
  final int dailyXp;
}

DiaryScreenViewData buildDiaryScreenViewData({
  required List<DiaryEntry> entries,
  required DiaryPeriod period,
  required String searchQuery,
  required SearchScope? searchScope,
  required UserStateStore store,
}) {
  final filteredEntries = _filterByPeriod(entries, period);
  final uiEntries = filteredEntries
      .map(_toUi)
      .where((entry) => _matchesSearch(entry, store, searchQuery, searchScope))
      .toList(growable: false);
  final groupedEntries = _groupFromUi(uiEntries);
  final sortedDays = groupedEntries.keys.toList()
    ..sort((a, b) => b.compareTo(a));
  final todayEntriesCount = _todayEntriesCount(entries);

  return DiaryScreenViewData(
    groupedEntries: groupedEntries,
    sortedDays: sortedDays,
    entriesCount: _countFrom(groupedEntries),
    todayEntriesCount: todayEntriesCount,
    dailyXp: _dailyEmotionalXp(todayEntriesCount),
  );
}

DateTime _toDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
    final milliseconds = int.tryParse(value);
    if (milliseconds != null) {
      return DateTime.fromMillisecondsSinceEpoch(milliseconds);
    }
  }
  return DateTime.now();
}

int _countFrom(Map<DateTime, List<DiaryEntryUi>> groupedEntries) {
  return groupedEntries.values.fold<int>(
    0,
    (total, entries) => total + entries.length,
  );
}

DiaryEntryUi _toUi(DiaryEntry entry) {
  final dynamic raw = entry;

  dynamic id;
  dynamic createdAt;
  String text = '';
  int? mood;
  String? habitId;
  String? habitName;
  String? familyName;
  Color? familyColor;

  try {
    if (raw is Map) id = raw['id'] ?? raw['_id'] ?? raw['uid'];
  } catch (_) {}
  try {
    id ??= (raw as dynamic).id;
  } catch (_) {}
  try {
    id ??= (raw as dynamic)._id;
  } catch (_) {}
  try {
    id ??= (raw as dynamic).uid;
  } catch (_) {}

  try {
    if (raw is Map) {
      createdAt = raw['createdAt'] ??
          raw['createdAtRaw'] ??
          raw['timestamp'] ??
          raw['date'];
    }
  } catch (_) {}
  try {
    createdAt ??= (raw as dynamic).createdAt;
  } catch (_) {}
  try {
    createdAt ??= (raw as dynamic).createdAtRaw;
  } catch (_) {}
  try {
    createdAt ??= (raw as dynamic).timestamp;
  } catch (_) {}

  try {
    if (raw is Map) {
      text = (raw['text'] ?? raw['note'] ?? raw['content'] ?? '').toString();
    }
  } catch (_) {}
  if (text.isEmpty) {
    try {
      text = ((raw as dynamic).text ?? '').toString();
    } catch (_) {}
  }
  if (text.isEmpty) {
    try {
      text = ((raw as dynamic).note ?? '').toString();
    } catch (_) {}
  }

  dynamic moodValue;
  try {
    if (raw is Map) moodValue = raw['mood'];
  } catch (_) {}
  try {
    moodValue ??= (raw as dynamic).mood;
  } catch (_) {}
  if (moodValue is int) {
    mood = moodValue;
  } else if (moodValue != null) {
    mood = int.tryParse(moodValue.toString());
  }

  try {
    if (raw is Map) {
      habitId = raw['habitId']?.toString();
      habitName = raw['habitName']?.toString();
      familyName = raw['familyName']?.toString();
    }
  } catch (_) {}
  try {
    habitId ??= (raw as dynamic).habitId?.toString();
  } catch (_) {}
  try {
    habitName ??= (raw as dynamic).habitName?.toString();
  } catch (_) {}
  try {
    familyName ??= (raw as dynamic).familyName?.toString();
  } catch (_) {}

  dynamic rawFamilyColor;
  try {
    if (raw is Map) rawFamilyColor = raw['familyColor'];
  } catch (_) {}
  try {
    rawFamilyColor ??= (raw as dynamic).familyColor;
  } catch (_) {}
  if (rawFamilyColor is Color) {
    familyColor = rawFamilyColor;
  } else if (rawFamilyColor is int) {
    familyColor = Color(rawFamilyColor);
  } else if (rawFamilyColor is String) {
    final value = rawFamilyColor.trim();
    int? parsedColor;
    try {
      if (value.startsWith('0x')) {
        parsedColor = int.parse(value);
      } else if (value.length == 6) {
        parsedColor = int.parse('0xFF$value');
      } else {
        parsedColor = int.tryParse(value);
      }
    } catch (_) {}
    if (parsedColor != null) familyColor = Color(parsedColor);
  }

  DiaryEntryType type = DiaryEntryType.personal;
  dynamic rawType;
  dynamic isHabit;
  try {
    if (raw is Map) {
      rawType = raw['type'] ?? raw['entryType'];
      isHabit = raw['isHabit'];
    }
  } catch (_) {}
  try {
    rawType ??= (raw as dynamic).type;
  } catch (_) {}
  try {
    rawType ??= (raw as dynamic).entryType;
  } catch (_) {}
  try {
    isHabit ??= (raw as dynamic).isHabit;
  } catch (_) {}

  if (rawType is DiaryEntryType) {
    type = rawType;
  } else if (rawType is String) {
    final normalized = rawType.toLowerCase();
    if (normalized.contains('habit')) type = DiaryEntryType.habit;
    if (normalized.contains('personal') || normalized.contains('note')) {
      type = DiaryEntryType.personal;
    }
  } else if (rawType is int) {
    type = rawType == 0 ? DiaryEntryType.habit : DiaryEntryType.personal;
  } else if (isHabit is bool) {
    type = isHabit ? DiaryEntryType.habit : DiaryEntryType.personal;
  } else if (habitId != null && habitId.isNotEmpty) {
    type = DiaryEntryType.habit;
  }

  return DiaryEntryUi.fromModel(
    id: id,
    createdAt: createdAt,
    type: type,
    text: text,
    mood: mood,
    habitId: habitId,
    habitName: habitName,
    familyName: familyName,
    familyColor: familyColor,
  );
}

Map<DateTime, List<DiaryEntryUi>> _groupFromUi(List<DiaryEntryUi> entries) {
  final groupedEntries = <DateTime, List<DiaryEntryUi>>{};

  for (final entry in entries) {
    final createdAt = entry.createdAt;
    final day = DateTime(createdAt.year, createdAt.month, createdAt.day);
    (groupedEntries[day] ??= <DiaryEntryUi>[]).add(entry);
  }

  for (final day in groupedEntries.keys) {
    groupedEntries[day]!.sort(
      (left, right) => right.createdAt.compareTo(left.createdAt),
    );
  }

  return groupedEntries;
}

List<DiaryEntry> _filterByPeriod(List<DiaryEntry> entries, DiaryPeriod period) {
  final now = DateTime.now();

  switch (period) {
    case DiaryPeriod.today:
      final start = DateTime(now.year, now.month, now.day);
      return entries
          .where((entry) => !_toDateTime(entry.createdAt).isBefore(start))
          .toList(growable: false);
    case DiaryPeriod.last7:
      final start = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 6));
      return entries
          .where((entry) => !_toDateTime(entry.createdAt).isBefore(start))
          .toList(growable: false);
    case DiaryPeriod.month:
      final start = DateTime(now.year, now.month, 1);
      return entries
          .where((entry) => !_toDateTime(entry.createdAt).isBefore(start))
          .toList(growable: false);
    case DiaryPeriod.all:
      return entries;
  }
}

bool _matchesSearch(
  DiaryEntryUi entry,
  UserStateStore store,
  String searchQuery,
  SearchScope? searchScope,
) {
  final query = searchQuery.trim().toLowerCase();
  if (query.isEmpty) return true;

  final scopeText = (searchScope ?? '').toString().toLowerCase();
  final wantsHabits = scopeText.contains('habit');
  final wantsPersonal = scopeText.contains('personal');
  if (wantsHabits && entry.type != DiaryEntryType.habit) return false;
  if (wantsPersonal && entry.type != DiaryEntryType.personal) return false;

  String habitName = entry.habitName ?? '';
  String familyName = entry.familyName ?? '';

  if (habitName.isEmpty && entry.habitId != null) {
    final habit = store.getActiveHabitById(entry.habitId!);
    if (habit is Map) {
      final habitMap = Map<String, dynamic>.from(habit);
      habitName = (habitMap['nameTemplate'] ??
              habitMap['name'] ??
              habitMap['title'] ??
              '')
          .toString();
      familyName = (habitMap['familyName'] ?? '').toString();
    } else {
      try {
        habitName = (habit as dynamic).name?.toString() ?? habitName;
      } catch (_) {}
    }
  }

  final haystack = [
    entry.text,
    habitName,
    familyName,
    entry.habitId ?? '',
  ].join(' ').toLowerCase();

  return haystack.contains(query);
}

int _todayEntriesCount(List<DiaryEntry> entries) {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);

  return entries
      .where((entry) => !_toDateTime(entry.createdAt).isBefore(start))
      .length;
}

int _dailyEmotionalXp(int entriesCount) => entriesCount * 12;
