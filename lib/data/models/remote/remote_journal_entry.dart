import 'package:flutter/foundation.dart';

@immutable
class RemoteJournalEntry {
  const RemoteJournalEntry({
    this.id,
    required this.userId,
    required this.entryDate,
    this.title,
    required this.content,
    this.mood,
    this.emoji,
    this.habitId,
    this.localHabitId,
    this.familyId,
    required this.source,
    required this.isDeleted,
    this.createdAt,
    this.updatedAt,
    this.raw = const <String, dynamic>{},
  });

  final String? id;
  final String userId;
  final DateTime entryDate;
  final String? title;
  final String content;
  final String? mood;
  final String? emoji;
  final String? habitId;
  final String? localHabitId;
  final String? familyId;
  final String source;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> raw;

  factory RemoteJournalEntry.fromMap(Map<String, dynamic> map) {
    final parsedEntryDate = _nullableDateTime(map['entry_date']) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return RemoteJournalEntry(
      id: _nullableTrim(map['id']),
      userId: _nullableTrim(map['user_id']) ?? '',
      entryDate: DateTime(
        parsedEntryDate.year,
        parsedEntryDate.month,
        parsedEntryDate.day,
      ),
      title: _nullableTrim(map['title']),
      content: _nullableTrim(map['content']) ?? '',
      mood: _nullableTrim(map['mood']),
      emoji: _nullableTrim(map['emoji']),
      habitId: _nullableTrim(map['habit_id']),
      localHabitId: _nullableTrim(map['local_habit_id']),
      familyId: _nullableTrim(map['family_id']),
      source: _normalizeSource(map['source']),
      isDeleted: map['is_deleted'] == true,
      createdAt: _nullableDateTime(map['created_at']),
      updatedAt: _nullableDateTime(map['updated_at']),
      raw: Map<String, dynamic>.from(map),
    );
  }

  Map<String, dynamic> toUpsertMap() {
    final payload = <String, dynamic>{
      'user_id': userId,
      'entry_date': _dateOnlyIso(entryDate),
      'title': _nullableTrim(title),
      'content': content.trim(),
      'mood': _nullableTrim(mood),
      'emoji': _nullableTrim(emoji),
      'habit_id': _nullableTrim(habitId),
      'local_habit_id': _nullableTrim(localHabitId),
      'family_id': _nullableTrim(familyId),
      'source': _normalizeSource(source),
      'is_deleted': isDeleted,
    };

    final normalizedId = _nullableTrim(id);
    if (normalizedId != null) {
      payload['id'] = normalizedId;
    }

    payload.removeWhere((_, value) => value == null);
    return payload;
  }

  static String _dateOnlyIso(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
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
    final normalized = value.toString().trim();
    if (normalized.isEmpty) return null;
    return DateTime.tryParse(normalized);
  }
}
