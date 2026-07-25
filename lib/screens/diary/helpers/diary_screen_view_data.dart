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
  DateTime? now,
}) {
  final calendarNow = (now ?? DateTime.now()).toLocal();
  final filteredEntries = _filterByPeriod(entries, period, calendarNow);
  final uiEntries = filteredEntries
      .map(_toUi)
      .where((entry) => _matchesSearch(entry, store, searchQuery, searchScope))
      .toList(growable: false);
  final groupedEntries = _groupFromUi(uiEntries);
  final sortedDays = groupedEntries.keys.toList()
    ..sort((a, b) => b.compareTo(a));
  final todayEntriesCount = _todayEntriesCount(entries, calendarNow);

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
  final parts = entry.textParts;
  return DiaryEntryUi.fromModel(
    id: entry.id,
    createdAt: entry.createdAt,
    type: entry.habitId != null && entry.habitId!.isNotEmpty
        ? DiaryEntryType.habit
        : DiaryEntryType.personal,
    text: entry.legacyText,
    title: parts.title,
    body: parts.body,
    mood: entry.mood,
    habitId: entry.habitId,
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

List<DiaryEntry> _filterByPeriod(
  List<DiaryEntry> entries,
  DiaryPeriod period,
  DateTime now,
) {
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

int _todayEntriesCount(List<DiaryEntry> entries, DateTime now) {
  final start = DateTime(now.year, now.month, now.day);

  return entries
      .where((entry) => !_toDateTime(entry.createdAt).isBefore(start))
      .length;
}

int _dailyEmotionalXp(int entriesCount) => entriesCount * 12;
