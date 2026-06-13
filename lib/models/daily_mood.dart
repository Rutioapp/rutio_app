import 'package:flutter/foundation.dart';

@immutable
class DailyMood {
  const DailyMood({
    required this.date,
    required this.mood,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final DateTime date;
  final int mood;
  final String? note;
  final int createdAt;
  final int updatedAt;

  DateTime get dateOnly => DateTime(date.year, date.month, date.day);

  String get dateKey {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  DailyMood copyWith({
    DateTime? date,
    int? mood,
    Object? note = _dailyMoodNoChange,
    int? createdAt,
    int? updatedAt,
  }) {
    return DailyMood(
      date: _normalizeDateOnly(date ?? this.date),
      mood: mood ?? this.mood,
      note: identical(note, _dailyMoodNoChange)
          ? this.note
          : _normalizedNote(note as String?),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': dateKey,
        'mood': mood,
        'note': _normalizedNote(note),
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory DailyMood.fromJson(Map<String, dynamic> json) {
    final date = _parseDailyMoodDate(
      json['date'] ?? json['dateKey'] ?? json['day'],
    );

    return DailyMood(
      date: date,
      mood: (json['mood'] is int)
          ? json['mood'] as int
          : int.tryParse((json['mood'] ?? '0').toString()) ?? 0,
      note: _normalizedNote(json['note']?.toString()),
      createdAt: (json['createdAt'] is int)
          ? json['createdAt'] as int
          : int.tryParse((json['createdAt'] ?? '0').toString()) ?? 0,
      updatedAt: (json['updatedAt'] is int)
          ? json['updatedAt'] as int
          : int.tryParse((json['updatedAt'] ?? '0').toString()) ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyMood &&
        other.dateOnly == dateOnly &&
        other.mood == mood &&
        other.note == note &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
        dateOnly,
        mood,
        note,
        createdAt,
        updatedAt,
      );
}

const Object _dailyMoodNoChange = Object();

DateTime _parseDailyMoodDate(Object? value) {
  if (value is DateTime) return _normalizeDateOnly(value);

  final raw = (value ?? '').toString().trim();
  if (raw.isEmpty) return _normalizeDateOnly(DateTime.now());

  final dateKeyMatch = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(raw);
  if (dateKeyMatch != null) {
    return DateTime(
      int.parse(dateKeyMatch.group(1)!),
      int.parse(dateKeyMatch.group(2)!),
      int.parse(dateKeyMatch.group(3)!),
    );
  }

  final parsed = DateTime.tryParse(raw);
  if (parsed != null) return _normalizeDateOnly(parsed.toLocal());

  return _normalizeDateOnly(DateTime.now());
}

DateTime _normalizeDateOnly(DateTime date) =>
    DateTime(date.year, date.month, date.day);

String? _normalizedNote(String? value) {
  final normalized = (value ?? '').trim();
  return normalized.isEmpty ? null : normalized;
}
