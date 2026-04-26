import 'package:flutter/foundation.dart';

@immutable
class RemoteHabit {
  const RemoteHabit({
    this.id,
    required this.userId,
    required this.name,
    this.familyId,
    this.emoji,
    required this.habitType,
    this.targetCount,
    this.unit,
    this.colorId,
    required this.reminderEnabled,
    this.reminderTime,
    required this.isArchived,
    required this.sortOrder,
    this.createdAt,
    this.updatedAt,
    this.raw = const <String, dynamic>{},
  });

  final String? id;
  final String userId;
  final String name;
  final String? familyId;
  final String? emoji;
  final String habitType;
  final int? targetCount;
  final String? unit;
  final String? colorId;
  final bool reminderEnabled;
  final String? reminderTime;
  final bool isArchived;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> raw;

  factory RemoteHabit.fromMap(Map<String, dynamic> map) {
    final normalizedHabitType = _normalizeHabitType(map['habit_type']);

    return RemoteHabit(
      id: _nullableTrim(map['id']),
      userId: (map['user_id'] ?? map['userId'] ?? '').toString().trim(),
      name: (map['name'] ?? 'Habit').toString().trim(),
      familyId: _nullableTrim(map['family_id'] ?? map['familyId']),
      emoji: _nullableTrim(map['emoji']),
      habitType: normalizedHabitType,
      targetCount: _nullableInt(map['target_count'] ?? map['targetCount']),
      unit: _nullableTrim(map['unit']),
      colorId: _nullableTrim(map['color_id'] ?? map['colorId']),
      reminderEnabled: map['reminder_enabled'] == true,
      reminderTime:
          _nullableTrim(map['reminder_time'] ?? map['reminderTime']),
      isArchived: map['is_archived'] == true,
      sortOrder: _safeInt(map['sort_order'], fallback: 0),
      createdAt: _nullableDateTime(map['created_at']),
      updatedAt: _nullableDateTime(map['updated_at']),
      raw: Map<String, dynamic>.from(map),
    );
  }

  /// Maps to confirmed `public.habits` writable columns.
  Map<String, dynamic> toUpsertMap() {
    final payload = <String, dynamic>{
      'user_id': userId,
      'name': name,
      'habit_type': _normalizeHabitType(habitType),
      'target_count': targetCount,
      'unit': unit,
      'color_id': colorId,
      'reminder_enabled': reminderEnabled,
      'reminder_time': reminderTime,
      'is_archived': isArchived,
      'sort_order': sortOrder,
      'family_id': familyId,
      'emoji': emoji,
    };

    final remoteId = _nullableTrim(id);
    if (remoteId != null) {
      payload['id'] = remoteId;
    }

    payload.removeWhere((_, value) => value == null);
    return payload;
  }

  /// Maps current local `activeHabits` shape to confirmed `public.habits` columns.
  /// No local behavior changes are applied in this phase; this is foundation-only.
  factory RemoteHabit.fromLocalMap(
    Map<String, dynamic> local, {
    required String userId,
  }) {
    final rawRemoteId = (local['remoteId'] ??
            local['remoteHabitId'] ??
            local['supabaseHabitId'] ??
            local['id'] ??
            local['habitId'] ??
            '')
        .toString()
        .trim()
        .toLowerCase();
    final normalizedId = _isUuid(rawRemoteId) ? rawRemoteId : null;

    final rawType = (local['type'] ?? '').toString().trim().toLowerCase();

    return RemoteHabit(
      id: normalizedId,
      userId: userId,
      name: (local['name'] ?? local['title'] ?? 'Habit').toString().trim(),
      familyId: _nullableTrim(local['familyId']),
      emoji: _nullableTrim(local['emoji'] ?? local['habitEmoji']),
      habitType: _normalizeHabitType(rawType),
      targetCount: _nullableInt(local['target']),
      unit: _nullableTrim(local['unit']),
      colorId: _nullableTrim(local['colorId']),
      reminderEnabled:
          local['reminderEnabled'] == true || local['remindersEnabled'] == true,
      reminderTime: _nullableTrim(local['reminderTime']),
      isArchived: local['is_archived'] == true ||
          local['isArchived'] == true ||
          local['archived'] == true,
      sortOrder: _safeInt(local['sortOrder'], fallback: 0),
      createdAt: _nullableDateTime(local['createdAt']),
      updatedAt: _nullableDateTime(local['updatedAt']),
      raw: Map<String, dynamic>.from(local),
    );
  }

  static String? _nullableTrim(dynamic value) {
    final normalized = (value ?? '').toString().trim();
    return normalized.isEmpty ? null : normalized;
  }

  static int _safeInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString().trim()) ?? fallback;
  }

  static int? _nullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString().trim());
  }

  static DateTime? _nullableDateTime(dynamic value) {
    if (value == null) return null;
    final normalized = (value ?? '').toString().trim();
    if (normalized.isEmpty) return null;
    return DateTime.tryParse(normalized);
  }

  static String _normalizeHabitType(dynamic value) {
    final normalized = (value ?? '').toString().trim().toLowerCase();
    return normalized == 'count' ? 'count' : 'check';
  }

  static bool _isUuid(String value) {
    final uuidRegExp = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidRegExp.hasMatch(value);
  }
}
