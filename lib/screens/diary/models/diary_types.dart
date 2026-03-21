import 'package:flutter/material.dart';

enum DiaryPeriod { today, last7, month, all }

enum DiaryEntryType { habit, personal }

class DiaryEntryUi {
  final String id;

  /// CreatedAt raw value stored in your model (epoch ms in la mayoría de casos).
  final int createdAtRaw;

  /// CreatedAt convertido a DateTime (para agrupar/mostrar).
  final DateTime createdAt;

  final DiaryEntryType type;
  final String text;
  final int? mood;

  final String? habitId;
  final String? habitName;
  final String? familyName;
  final Color? familyColor;

  String get timeLabel {
    final hh = createdAt.hour.toString().padLeft(2, '0');
    final mm = createdAt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  const DiaryEntryUi._({
    required this.id,
    required this.createdAtRaw,
    required this.createdAt,
    required this.type,
    required this.text,
    this.mood,
    this.habitId,
    this.habitName,
    this.familyName,
    this.familyColor,
  });

  factory DiaryEntryUi.fromModel({
    required dynamic id,
    required dynamic createdAt,
    required DiaryEntryType type,
    required String text,
    int? mood,
    String? habitId,
    String? habitName,
    String? familyName,
    Color? familyColor,
  }) {
    final String sid = id?.toString() ?? '';
    final DateTime dt = _toDateTime(createdAt);
    final int raw = createdAt is int ? createdAt : dt.millisecondsSinceEpoch;

    return DiaryEntryUi._(
      id: sid,
      createdAtRaw: raw,
      createdAt: dt,
      type: type,
      text: text,
      mood: mood,
      habitId: habitId,
      habitName: habitName,
      familyName: familyName,
      familyColor: familyColor,
    );
  }

  static DateTime _toDateTime(dynamic v) {
    if (v is DateTime) return v;
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
    if (v is String) {
      final parsed = DateTime.tryParse(v);
      if (parsed != null) return parsed;
      final ms = int.tryParse(v);
      if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);
    }
    return DateTime.now();
  }
}

class HabitPick {
  final String id;
  final String name;
  final String? familyName;
  final Color? familyColor;

  const HabitPick({
    required this.id,
    required this.name,
    this.familyName,
    this.familyColor,
  });
}
