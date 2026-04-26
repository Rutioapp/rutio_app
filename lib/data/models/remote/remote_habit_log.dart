import 'package:flutter/foundation.dart';

@immutable
class RemoteHabitLog {
  const RemoteHabitLog({
    required this.id,
    required this.userId,
    required this.habitId,
    required this.logDate,
    required this.value,
    required this.isCompleted,
    this.note,
    required this.source,
    this.createdAt,
    this.updatedAt,
    this.raw = const <String, dynamic>{},
  });

  final String id;
  final String userId;
  final String habitId;
  final DateTime logDate;
  final int value;
  final bool isCompleted;
  final String? note;
  final String source;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> raw;

  factory RemoteHabitLog.fromMap(Map<String, dynamic> map) {
    final parsedDate =
        _nullableDateTime(map['log_date']) ?? DateTime.fromMillisecondsSinceEpoch(0);

    return RemoteHabitLog(
      id: (map['id'] ?? '').toString().trim(),
      userId: (map['user_id'] ?? '').toString().trim(),
      habitId: (map['habit_id'] ?? '').toString().trim(),
      logDate: DateTime(parsedDate.year, parsedDate.month, parsedDate.day),
      value: _safeInt(map['value'], fallback: 0),
      isCompleted: map['is_completed'] == true,
      note: _nullableTrim(map['note']),
      source: _normalizeSource(map['source']),
      createdAt: _nullableDateTime(map['created_at']),
      updatedAt: _nullableDateTime(map['updated_at']),
      raw: Map<String, dynamic>.from(map),
    );
  }

  Map<String, dynamic> toUpsertMap() {
    final payload = <String, dynamic>{
      'user_id': userId,
      'habit_id': habitId,
      'log_date': _dateOnlyIso(logDate),
      'value': value,
      'is_completed': isCompleted,
      'note': note,
      'source': _normalizeSource(source),
    };

    if (id.isNotEmpty) {
      payload['id'] = id;
    }

    payload.removeWhere((_, value) => value == null);
    return payload;
  }

  static String _dateOnlyIso(DateTime date) {
    final utc = DateTime.utc(date.year, date.month, date.day);
    final month = utc.month.toString().padLeft(2, '0');
    final day = utc.day.toString().padLeft(2, '0');
    return '${utc.year}-$month-$day';
  }

  static String _normalizeSource(dynamic value) {
    final normalized = (value ?? '').toString().trim().toLowerCase();
    switch (normalized) {
      case 'manual':
      case 'migration':
      case 'system':
        return normalized;
      default:
        return 'manual';
    }
  }

  static String? _nullableTrim(dynamic value) {
    final normalized = (value ?? '').toString().trim();
    return normalized.isEmpty ? null : normalized;
  }

  static DateTime? _nullableDateTime(dynamic value) {
    if (value == null) return null;
    final normalized = (value ?? '').toString().trim();
    if (normalized.isEmpty) return null;
    return DateTime.tryParse(normalized);
  }

  static int _safeInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString().trim()) ?? fallback;
  }
}
