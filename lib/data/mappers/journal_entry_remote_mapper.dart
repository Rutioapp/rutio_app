import '../../models/diary_entry.dart';
import '../models/remote/remote_journal_entry.dart';

class JournalEntryRemoteMapper {
  const JournalEntryRemoteMapper._();

  static RemoteJournalEntry? toRemoteJournalEntry({
    required DiaryEntry localEntry,
    required Map<String, dynamic> localEntryMap,
    required String userId,
    required List<Map<String, dynamic>> activeHabits,
    String source = 'manual',
    String? remoteIdOverride,
    bool isDeleted = false,
  }) {
    final content = localEntry.text.trim();
    if (content.isEmpty) return null;

    final localCreatedAt = DateTime.fromMillisecondsSinceEpoch(
      localEntry.createdAt,
    );
    final entryDate = DateTime(
      localCreatedAt.year,
      localCreatedAt.month,
      localCreatedAt.day,
    );

    final localHabitId = _nullableTrim(
      localEntryMap['habitId'] ?? localEntry.habitId,
    );
    final resolvedRemoteHabitId = _resolveRemoteHabitId(
      localHabitId: localHabitId,
      activeHabits: activeHabits,
    );

    return RemoteJournalEntry(
      id: _resolveRemoteId(localEntryMap, override: remoteIdOverride),
      userId: userId,
      entryDate: entryDate,
      title: _nullableTrim(localEntryMap['title']),
      content: content,
      mood: _normalizeMood(localEntryMap['mood'] ?? localEntry.mood),
      emoji: _nullableTrim(localEntryMap['emoji']),
      habitId: resolvedRemoteHabitId,
      localHabitId: localHabitId,
      familyId: _nullableTrim(localEntryMap['familyId'] ?? localEntry.familyId),
      source: _normalizeSource(source),
      isDeleted: isDeleted,
      createdAt: _nullableDateTime(localEntryMap['createdAtRemote']),
      updatedAt: _nullableDateTime(localEntryMap['updatedAtRemote']),
      raw: Map<String, dynamic>.from(localEntryMap),
    );
  }

  static String? extractRemoteId(Map<String, dynamic> localEntryMap) {
    final normalized = _nullableTrim(
      localEntryMap['remoteId'] ??
          localEntryMap['remoteJournalEntryId'] ??
          localEntryMap['supabaseJournalEntryId'],
    );
    if (normalized == null || !_isUuid(normalized)) return null;
    return normalized.toLowerCase();
  }

  static String? _resolveRemoteId(
    Map<String, dynamic> localEntryMap, {
    String? override,
  }) {
    final normalizedOverride = _nullableTrim(override);
    if (normalizedOverride != null && _isUuid(normalizedOverride)) {
      return normalizedOverride.toLowerCase();
    }
    return extractRemoteId(localEntryMap);
  }

  static String? _resolveRemoteHabitId({
    required String? localHabitId,
    required List<Map<String, dynamic>> activeHabits,
  }) {
    if (localHabitId == null || localHabitId.isEmpty) return null;

    for (final activeHabit in activeHabits) {
      final activeLocalId = _nullableTrim(
        activeHabit['id'] ??
            activeHabit['habitId'] ??
            activeHabit['uuid'] ??
            activeHabit['key'],
      );
      if (activeLocalId == null || activeLocalId != localHabitId) continue;

      final remoteHabitId = _nullableTrim(
        activeHabit['remoteId'] ??
            activeHabit['remoteHabitId'] ??
            activeHabit['supabaseHabitId'],
      );
      if (remoteHabitId != null && _isUuid(remoteHabitId)) {
        return remoteHabitId.toLowerCase();
      }
      return null;
    }

    return null;
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

  static String? _normalizeMood(dynamic value) {
    if (value == null) return null;
    if (value is int) return value.toString();
    if (value is num) return value.toInt().toString();
    return _nullableTrim(value);
  }

  static String? _nullableTrim(dynamic value) {
    final normalized = (value ?? '').toString().trim();
    return normalized.isEmpty ? null : normalized;
  }

  static DateTime? _nullableDateTime(dynamic value) {
    final normalized = _nullableTrim(value);
    if (normalized == null) return null;
    return DateTime.tryParse(normalized);
  }

  static bool _isUuid(String value) {
    final uuidRegExp = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidRegExp.hasMatch(value);
  }
}
