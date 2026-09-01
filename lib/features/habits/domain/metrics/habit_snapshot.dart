import 'habit_date_utils.dart';

enum HabitKind {
  check,
  count,
}

extension HabitKindX on HabitKind {
  static HabitKind fromString(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'count':
      case 'counter':
      case 'numeric':
        return HabitKind.count;
      default:
        return HabitKind.check;
    }
  }

  String get key {
    switch (this) {
      case HabitKind.check:
        return 'check';
      case HabitKind.count:
        return 'count';
    }
  }
}

class HabitSnapshot {
  const HabitSnapshot({
    required this.habitId,
    required this.name,
    required this.kind,
    required this.schedule,
    this.emoji,
    this.target,
    this.createdAt,
    this.archived = false,
    this.familyId,
  });

  final String habitId;
  final String name;
  final String? emoji;
  final HabitKind kind;
  final HabitSchedule schedule;
  final num? target;
  final DateTime? createdAt;
  final bool archived;
  final String? familyId;

  bool get isCheck => kind == HabitKind.check;
  bool get isCount => kind == HabitKind.count;

  HabitSnapshot copyWith({
    String? habitId,
    String? name,
    String? emoji,
    HabitKind? kind,
    HabitSchedule? schedule,
    num? target,
    bool clearTarget = false,
    DateTime? createdAt,
    bool clearCreatedAt = false,
    bool? archived,
    String? familyId,
    bool clearEmoji = false,
    bool clearFamilyId = false,
  }) {
    return HabitSnapshot(
      habitId: habitId ?? this.habitId,
      name: name ?? this.name,
      emoji: clearEmoji ? null : emoji ?? this.emoji,
      kind: kind ?? this.kind,
      schedule: schedule ?? this.schedule,
      target: clearTarget ? null : target ?? this.target,
      createdAt: clearCreatedAt ? null : createdAt ?? this.createdAt,
      archived: archived ?? this.archived,
      familyId: clearFamilyId ? null : familyId ?? this.familyId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HabitSnapshot &&
        other.habitId == habitId &&
        other.name == name &&
        other.emoji == emoji &&
        other.kind == kind &&
        other.schedule == schedule &&
        other.target == target &&
        other.createdAt == createdAt &&
        other.archived == archived &&
        other.familyId == familyId;
  }

  @override
  int get hashCode => Object.hash(
        habitId,
        name,
        emoji,
        kind,
        schedule,
        target,
        createdAt,
        archived,
        familyId,
      );
}

enum HabitScheduleType {
  daily,
  weekly,
  once,
  timesPerWeek,
}

extension HabitScheduleTypeX on HabitScheduleType {
  static HabitScheduleType fromString(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'weekly':
        return HabitScheduleType.weekly;
      case 'once':
        return HabitScheduleType.once;
      case 'timesperweek':
        return HabitScheduleType.timesPerWeek;
      default:
        return HabitScheduleType.daily;
    }
  }

  String get key {
    switch (this) {
      case HabitScheduleType.daily:
        return 'daily';
      case HabitScheduleType.weekly:
        return 'weekly';
      case HabitScheduleType.once:
        return 'once';
      case HabitScheduleType.timesPerWeek:
        return 'timesPerWeek';
    }
  }
}

class HabitSchedule {
  const HabitSchedule._({
    required this.type,
    this.weekdays = const <int>[],
    this.date,
    this.timesPerWeek,
    this.weekStartsOn = DateTime.monday,
  });

  factory HabitSchedule.daily() {
    return const HabitSchedule._(type: HabitScheduleType.daily);
  }

  factory HabitSchedule.weekly({
    required List<int> weekdays,
  }) {
    return HabitSchedule._(
      type: HabitScheduleType.weekly,
      weekdays: _normalizeWeekdays(weekdays),
    );
  }

  factory HabitSchedule.once({
    required DateTime date,
  }) {
    return HabitSchedule._(
      type: HabitScheduleType.once,
      date: dateOnly(date),
    );
  }

  factory HabitSchedule.timesPerWeek({
    required int timesPerWeek,
    int weekStartsOn = DateTime.monday,
  }) {
    return HabitSchedule._(
      type: HabitScheduleType.timesPerWeek,
      timesPerWeek: timesPerWeek < 1 ? 1 : timesPerWeek,
      weekStartsOn:
          weekStartsOn < DateTime.monday || weekStartsOn > DateTime.sunday
              ? DateTime.monday
              : weekStartsOn,
    );
  }

  final HabitScheduleType type;
  final List<int> weekdays;
  final DateTime? date;
  final int? timesPerWeek;
  final int weekStartsOn;

  bool get isDaily => type == HabitScheduleType.daily;
  bool get isWeekly => type == HabitScheduleType.weekly;
  bool get isOnce => type == HabitScheduleType.once;
  bool get isTimesPerWeek => type == HabitScheduleType.timesPerWeek;

  bool scheduledForDate(DateTime dateTime) {
    final normalized = dateOnly(dateTime);
    switch (type) {
      case HabitScheduleType.daily:
        return true;
      case HabitScheduleType.weekly:
        return weekdays.contains(normalized.weekday);
      case HabitScheduleType.once:
        return date != null && sameDate(date!, normalized);
      case HabitScheduleType.timesPerWeek:
        return false;
    }
  }

  HabitSchedule copyWith({
    HabitScheduleType? type,
    List<int>? weekdays,
    DateTime? date,
    int? timesPerWeek,
    int? weekStartsOn,
  }) {
    final nextType = type ?? this.type;
    switch (nextType) {
      case HabitScheduleType.daily:
        return HabitSchedule.daily();
      case HabitScheduleType.weekly:
        return HabitSchedule.weekly(
          weekdays: weekdays ?? this.weekdays,
        );
      case HabitScheduleType.once:
        return HabitSchedule.once(
          date: date ?? this.date ?? DateTime.now(),
        );
      case HabitScheduleType.timesPerWeek:
        return HabitSchedule.timesPerWeek(
          timesPerWeek: timesPerWeek ?? this.timesPerWeek ?? 1,
          weekStartsOn: weekStartsOn ?? this.weekStartsOn,
        );
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HabitSchedule &&
        other.type == type &&
        _listEquals(other.weekdays, weekdays) &&
        other.date == date &&
        other.timesPerWeek == timesPerWeek &&
        other.weekStartsOn == weekStartsOn;
  }

  @override
  int get hashCode => Object.hash(
        type,
        Object.hashAll(weekdays),
        date,
        timesPerWeek,
        weekStartsOn,
      );
}

List<int> _normalizeWeekdays(Iterable<int> weekdays) {
  final normalized = <int>{};
  for (final weekday in weekdays) {
    if (weekday < DateTime.monday || weekday > DateTime.sunday) continue;
    normalized.add(weekday);
  }
  final output = normalized.toList()..sort();
  return List<int>.unmodifiable(output);
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
