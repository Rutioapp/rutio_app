import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/rutio_supabase_client.dart';
import '../../models/daily_mood.dart';
import '../../models/diary_entry.dart';
import 'repository_result.dart';

typedef CurrentUserIdProvider = String? Function();

class DiaryV2SupabaseRepository {
  DiaryV2SupabaseRepository({
    SupabaseClient? client,
    CurrentUserIdProvider? currentUserIdProvider,
  })  : _client = client ?? RutioSupabaseClient.instance,
        _currentUserIdProvider = currentUserIdProvider;

  final SupabaseClient _client;
  final CurrentUserIdProvider? _currentUserIdProvider;

  static const String _diaryEntriesTable = 'diary_entries';
  static const String _dailyMoodsTable = 'daily_moods';
  static const String _diaryEntryColumns = '''
id,
user_id,
local_id,
entry_date,
created_at,
updated_at,
local_created_at_ms,
title,
body,
legacy_text,
mood,
entry_type,
tags,
is_pinned,
habit_id,
family_id,
metadata
''';
  static const String _dailyMoodColumns = '''
id,
user_id,
mood_date,
mood,
note,
created_at,
updated_at,
local_created_at_ms,
local_updated_at_ms,
metadata
''';

  Future<RepositoryResult<List<DiaryEntry>>> fetchDiaryEntriesForCurrentUser({
    DateTime? start,
    DateTime? end,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const RepositoryResult<List<DiaryEntry>>.success(
        data: <DiaryEntry>[],
      );
    }

    try {
      var query = _client
          .from(_diaryEntriesTable)
          .select(_diaryEntryColumns)
          .eq('user_id', userId);

      if (start != null) {
        query = query.gte('entry_date', _dateOnlyIso(start));
      }
      if (end != null) {
        query = query.lte('entry_date', _dateOnlyIso(end));
      }

      final rows = await query
          .order('entry_date', ascending: false)
          .order('local_created_at_ms', ascending: false);

      final entries = rows
          .whereType<Map>()
          .map(
            (row) => diaryEntryFromRow(
              Map<String, dynamic>.from(row.cast<String, dynamic>()),
            ),
          )
          .toList(growable: false);

      return RepositoryResult<List<DiaryEntry>>.success(data: entries);
    } on PostgrestException catch (error) {
      return RepositoryResult<List<DiaryEntry>>.failure(
        _mapPostgrestError(
          error,
          fallbackMessage: 'Could not fetch Diary V2 entries.',
          schemaLabel: 'Diary V2 entries table/schema is unavailable.',
          debugLabel: 'diary_v2_supabase_repository',
          tableName: _diaryEntriesTable,
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[diary_v2_supabase_repository] unexpected diary fetch error: $error',
        );
      }
      return RepositoryResult<List<DiaryEntry>>.failure(
        RepositoryError(
          code: RepositoryErrorCode.unknown,
          message: 'Could not fetch Diary V2 entries.',
          cause: error,
        ),
      );
    }
  }

  Future<RepositoryResult<DiaryEntry>> upsertDiaryEntry(
    DiaryEntry entry,
  ) async {
    final userId = _currentUserId();
    if (userId == null) {
      return RepositoryResult<DiaryEntry>.failure(_notAuthenticated());
    }

    final payload = diaryEntryToRow(entry, userId: userId);

    try {
      final row = await _client
          .from(_diaryEntriesTable)
          .upsert(payload, onConflict: 'user_id,local_id')
          .select(_diaryEntryColumns)
          .single();

      final mapped = diaryEntryFromRow(Map<String, dynamic>.from(row));
      return _validateDiaryEntry(
        entry: mapped,
        userId: userId,
        expectedLocalId: entry.id,
      );
    } on PostgrestException catch (error) {
      return RepositoryResult<DiaryEntry>.failure(
        _mapPostgrestError(
          error,
          fallbackMessage: 'Could not upsert Diary V2 entry.',
          schemaLabel: 'Diary V2 entries table/schema is unavailable.',
          debugLabel: 'diary_v2_supabase_repository',
          tableName: _diaryEntriesTable,
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[diary_v2_supabase_repository] unexpected diary upsert error: $error',
        );
      }
      return RepositoryResult<DiaryEntry>.failure(
        RepositoryError(
          code: RepositoryErrorCode.unknown,
          message: 'Could not upsert Diary V2 entry.',
          cause: error,
        ),
      );
    }
  }

  Future<RepositoryResult<List<DiaryEntry>>> upsertDiaryEntries(
    List<DiaryEntry> entries,
  ) async {
    if (entries.isEmpty) {
      return const RepositoryResult<List<DiaryEntry>>.success(
        data: <DiaryEntry>[],
      );
    }

    final userId = _currentUserId();
    if (userId == null) {
      return RepositoryResult<List<DiaryEntry>>.failure(_notAuthenticated());
    }

    final payload = entries
        .map((entry) => diaryEntryToRow(entry, userId: userId))
        .toList(growable: false);

    try {
      final rows = await _client
          .from(_diaryEntriesTable)
          .upsert(payload, onConflict: 'user_id,local_id')
          .select(_diaryEntryColumns);

      final mapped = rows
          .whereType<Map>()
          .map(
            (row) => diaryEntryFromRow(
              Map<String, dynamic>.from(row.cast<String, dynamic>()),
            ),
          )
          .toList(growable: false);

      final expectedLocalIds =
          entries.map((entry) => entry.id.trim()).where((id) => id.isNotEmpty).toSet();
      final actualLocalIds = mapped.map((entry) => entry.id.trim()).toSet();
      if (mapped.length != entries.length ||
          actualLocalIds.length != expectedLocalIds.length ||
          !actualLocalIds.containsAll(expectedLocalIds)) {
        return RepositoryResult<List<DiaryEntry>>.failure(
          const RepositoryError(
            code: RepositoryErrorCode.invalidResponse,
            message: 'Diary V2 upsert response did not match requested entries.',
          ),
        );
      }

      return RepositoryResult<List<DiaryEntry>>.success(data: mapped);
    } on PostgrestException catch (error) {
      return RepositoryResult<List<DiaryEntry>>.failure(
        _mapPostgrestError(
          error,
          fallbackMessage: 'Could not upsert Diary V2 entries.',
          schemaLabel: 'Diary V2 entries table/schema is unavailable.',
          debugLabel: 'diary_v2_supabase_repository',
          tableName: _diaryEntriesTable,
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[diary_v2_supabase_repository] unexpected diary batch upsert error: $error',
        );
      }
      return RepositoryResult<List<DiaryEntry>>.failure(
        RepositoryError(
          code: RepositoryErrorCode.unknown,
          message: 'Could not upsert Diary V2 entries.',
          cause: error,
        ),
      );
    }
  }

  Future<RepositoryResult<void>> deleteDiaryEntry({
    String? localId,
    String? remoteId,
  }) async {
    final normalizedLocalId = _nullableTrim(localId);
    if (normalizedLocalId != null) {
      return deleteDiaryEntryByLocalId(normalizedLocalId);
    }

    final userId = _currentUserId();
    if (userId == null) {
      if (kDebugMode) {
        debugPrint(
          '[diary_v2_supabase_repository] delete skipped: auth unavailable, '
          'localId="${normalizedLocalId ?? ''}", remoteId="${_nullableTrim(remoteId) ?? ''}"',
        );
      }
      return RepositoryResult<void>.failure(_notAuthenticated());
    }

    final normalizedRemoteId = _nullableTrim(remoteId)?.toLowerCase();
    if (normalizedRemoteId == null) {
      return RepositoryResult<void>.failure(
        const RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: 'Local id or remote id is required for Diary V2 delete.',
        ),
      );
    }

    try {
      if (kDebugMode) {
        debugPrint(
          '[diary_v2_supabase_repository] delete attempt by remote id: '
          'authAvailable=true, remoteId="$normalizedRemoteId"',
        );
      }
      await _client
          .from(_diaryEntriesTable)
          .delete()
          .eq('user_id', userId)
          .eq('id', normalizedRemoteId);
      return const RepositoryResult<void>.success();
    } on PostgrestException catch (error) {
      return RepositoryResult<void>.failure(
        _mapPostgrestError(
          error,
          fallbackMessage: 'Could not delete Diary V2 entry.',
          schemaLabel: 'Diary V2 entries table/schema is unavailable.',
          debugLabel: 'diary_v2_supabase_repository',
          tableName: _diaryEntriesTable,
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[diary_v2_supabase_repository] unexpected diary delete error: $error',
        );
      }
      return RepositoryResult<void>.failure(
        RepositoryError(
          code: RepositoryErrorCode.unknown,
          message: 'Could not delete Diary V2 entry.',
          cause: error,
        ),
      );
    }
  }

  Future<RepositoryResult<void>> deleteDiaryEntryByLocalId(String localId) async {
    final normalizedLocalId = _nullableTrim(localId);
    final userId = _currentUserId();

    if (kDebugMode) {
      debugPrint(
        '[diary_v2_supabase_repository] delete attempt by local id: '
        'localId="${normalizedLocalId ?? ''}", authAvailable=${userId != null}',
      );
    }

    if (userId == null) {
      return RepositoryResult<void>.failure(_notAuthenticated());
    }
    if (normalizedLocalId == null) {
      return RepositoryResult<void>.failure(
        const RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: 'Local id is required for Diary V2 delete.',
        ),
      );
    }

    try {
      await _client
          .from(_diaryEntriesTable)
          .delete()
          .eq('user_id', userId)
          .eq('local_id', normalizedLocalId);
      return const RepositoryResult<void>.success();
    } on PostgrestException catch (error) {
      return RepositoryResult<void>.failure(
        _mapPostgrestError(
          error,
          fallbackMessage: 'Could not delete Diary V2 entry.',
          schemaLabel: 'Diary V2 entries table/schema is unavailable.',
          debugLabel: 'diary_v2_supabase_repository',
          tableName: _diaryEntriesTable,
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[diary_v2_supabase_repository] unexpected diary delete error '
          'for localId="$normalizedLocalId": $error',
        );
      }
      return RepositoryResult<void>.failure(
        RepositoryError(
          code: RepositoryErrorCode.unknown,
          message: 'Could not delete Diary V2 entry.',
          cause: error,
        ),
      );
    }
  }

  Future<RepositoryResult<List<DailyMood>>> fetchDailyMoodsForCurrentUser({
    DateTime? start,
    DateTime? end,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const RepositoryResult<List<DailyMood>>.success(
        data: <DailyMood>[],
      );
    }

    try {
      var query = _client
          .from(_dailyMoodsTable)
          .select(_dailyMoodColumns)
          .eq('user_id', userId);

      if (start != null) {
        query = query.gte('mood_date', _dateOnlyIso(start));
      }
      if (end != null) {
        query = query.lte('mood_date', _dateOnlyIso(end));
      }

      final rows = await query.order('mood_date', ascending: false);

      final moods = rows
          .whereType<Map>()
          .map(
            (row) => dailyMoodFromRow(
              Map<String, dynamic>.from(row.cast<String, dynamic>()),
            ),
          )
          .toList(growable: false);

      return RepositoryResult<List<DailyMood>>.success(data: moods);
    } on PostgrestException catch (error) {
      return RepositoryResult<List<DailyMood>>.failure(
        _mapPostgrestError(
          error,
          fallbackMessage: 'Could not fetch Diary V2 daily moods.',
          schemaLabel: 'Diary V2 daily moods table/schema is unavailable.',
          debugLabel: 'diary_v2_supabase_repository',
          tableName: _dailyMoodsTable,
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[diary_v2_supabase_repository] unexpected daily mood fetch error: $error',
        );
      }
      return RepositoryResult<List<DailyMood>>.failure(
        RepositoryError(
          code: RepositoryErrorCode.unknown,
          message: 'Could not fetch Diary V2 daily moods.',
          cause: error,
        ),
      );
    }
  }

  Future<RepositoryResult<DailyMood>> upsertDailyMood(DailyMood dailyMood) async {
    final userId = _currentUserId();
    if (userId == null) {
      return RepositoryResult<DailyMood>.failure(_notAuthenticated());
    }

    final payload = dailyMoodToRow(dailyMood, userId: userId);

    try {
      final row = await _client
          .from(_dailyMoodsTable)
          .upsert(payload, onConflict: 'user_id,mood_date')
          .select(_dailyMoodColumns)
          .single();

      final mapped = dailyMoodFromRow(Map<String, dynamic>.from(row));
      return _validateDailyMood(
        dailyMood: mapped,
        userId: userId,
        expectedDateKey: _dateOnlyIso(dailyMood.date),
      );
    } on PostgrestException catch (error) {
      return RepositoryResult<DailyMood>.failure(
        _mapPostgrestError(
          error,
          fallbackMessage: 'Could not upsert Diary V2 daily mood.',
          schemaLabel: 'Diary V2 daily moods table/schema is unavailable.',
          debugLabel: 'diary_v2_supabase_repository',
          tableName: _dailyMoodsTable,
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[diary_v2_supabase_repository] unexpected daily mood upsert error: $error',
        );
      }
      return RepositoryResult<DailyMood>.failure(
        RepositoryError(
          code: RepositoryErrorCode.unknown,
          message: 'Could not upsert Diary V2 daily mood.',
          cause: error,
        ),
      );
    }
  }

  Future<RepositoryResult<List<DailyMood>>> upsertDailyMoods(
    List<DailyMood> dailyMoods,
  ) async {
    if (dailyMoods.isEmpty) {
      return const RepositoryResult<List<DailyMood>>.success(
        data: <DailyMood>[],
      );
    }

    final userId = _currentUserId();
    if (userId == null) {
      return RepositoryResult<List<DailyMood>>.failure(_notAuthenticated());
    }

    final payload = dailyMoods
        .map((dailyMood) => dailyMoodToRow(dailyMood, userId: userId))
        .toList(growable: false);

    try {
      final rows = await _client
          .from(_dailyMoodsTable)
          .upsert(payload, onConflict: 'user_id,mood_date')
          .select(_dailyMoodColumns);

      final mapped = rows
          .whereType<Map>()
          .map(
            (row) => dailyMoodFromRow(
              Map<String, dynamic>.from(row.cast<String, dynamic>()),
            ),
          )
          .toList(growable: false);

      final expectedDateKeys =
          dailyMoods.map((dailyMood) => _dateOnlyIso(dailyMood.date)).toSet();
      final actualDateKeys =
          mapped.map((dailyMood) => _dateOnlyIso(dailyMood.date)).toSet();
      if (mapped.length != dailyMoods.length ||
          actualDateKeys.length != expectedDateKeys.length ||
          !actualDateKeys.containsAll(expectedDateKeys)) {
        return RepositoryResult<List<DailyMood>>.failure(
          const RepositoryError(
            code: RepositoryErrorCode.invalidResponse,
            message:
                'Diary V2 daily mood upsert response did not match requested rows.',
          ),
        );
      }

      return RepositoryResult<List<DailyMood>>.success(data: mapped);
    } on PostgrestException catch (error) {
      return RepositoryResult<List<DailyMood>>.failure(
        _mapPostgrestError(
          error,
          fallbackMessage: 'Could not upsert Diary V2 daily moods.',
          schemaLabel: 'Diary V2 daily moods table/schema is unavailable.',
          debugLabel: 'diary_v2_supabase_repository',
          tableName: _dailyMoodsTable,
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[diary_v2_supabase_repository] unexpected daily mood batch upsert error: $error',
        );
      }
      return RepositoryResult<List<DailyMood>>.failure(
        RepositoryError(
          code: RepositoryErrorCode.unknown,
          message: 'Could not upsert Diary V2 daily moods.',
          cause: error,
        ),
      );
    }
  }

  Future<RepositoryResult<void>> deleteDailyMoodByDate(DateTime date) async {
    final userId = _currentUserId();
    if (userId == null) {
      return RepositoryResult<void>.failure(_notAuthenticated());
    }

    try {
      await _client
          .from(_dailyMoodsTable)
          .delete()
          .eq('user_id', userId)
          .eq('mood_date', _dateOnlyIso(date));
      return const RepositoryResult<void>.success();
    } on PostgrestException catch (error) {
      return RepositoryResult<void>.failure(
        _mapPostgrestError(
          error,
          fallbackMessage: 'Could not delete Diary V2 daily mood.',
          schemaLabel: 'Diary V2 daily moods table/schema is unavailable.',
          debugLabel: 'diary_v2_supabase_repository',
          tableName: _dailyMoodsTable,
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[diary_v2_supabase_repository] unexpected daily mood delete error: $error',
        );
      }
      return RepositoryResult<void>.failure(
        RepositoryError(
          code: RepositoryErrorCode.unknown,
          message: 'Could not delete Diary V2 daily mood.',
          cause: error,
        ),
      );
    }
  }

  static DiaryEntry diaryEntryFromRow(Map<String, dynamic> row) {
    final title = _nullableTrim(row['title']);
    final body = _nullableTrim(row['body']);
    final legacyText = _nullableTrim(row['legacy_text']);
    final localCreatedAtMs = _safeInt(row['local_created_at_ms']);
    final createdAt = localCreatedAtMs ??
        _dateTimeToEpochMs(_nullableDateTime(row['created_at'])) ??
        _dateTimeToEpochMs(_nullableDateTime(row['entry_date'])) ??
        0;

    return DiaryEntry(
      id: _nullableTrim(row['local_id']) ?? '',
      createdAt: createdAt,
      text: composeLegacyDiaryText(
        title: title,
        body: body,
        fallbackText: legacyText ?? '',
      ),
      title: title,
      body: body,
      remoteId: _nullableTrim(row['id'])?.toLowerCase(),
      habitId: _nullableTrim(row['habit_id']),
      familyId: _nullableTrim(row['family_id']),
      mood: _safeInt(row['mood']),
      entryType: diaryEntryContentTypeFromJsonValue(
        row['entry_type'] ?? row['entryType'],
      ),
      tags: _normalizeSupportedTags(row['tags']),
      isPinned: row['is_pinned'] == true,
    );
  }

  static Map<String, dynamic> diaryEntryToRow(
    DiaryEntry entry, {
    required String userId,
  }) {
    final payload = <String, dynamic>{
      'user_id': userId.trim(),
      'local_id': entry.id.trim(),
      'entry_date': _dateOnlyIso(DateTime.fromMillisecondsSinceEpoch(entry.createdAt)),
      'local_created_at_ms': entry.createdAt,
      'title': _nullableTrim(entry.title),
      'body': _nullableTrim(entry.body),
      'legacy_text': _nullableTrim(entry.legacyText),
      'mood': entry.mood,
      'entry_type': entry.entryType?.name,
      'tags': entry.tags
          .map((tag) => tag.trim().toLowerCase())
          .where(DiaryEntry.supportedTags.contains)
          .toSet()
          .toList(growable: false),
      'is_pinned': entry.isPinned,
      'habit_id': _nullableTrim(entry.habitId),
      'family_id': _nullableTrim(entry.familyId),
      'metadata': const <String, dynamic>{},
    };

    payload.removeWhere((_, value) => value == null);
    if (!payload.containsKey('entry_type')) {
      payload['entry_type'] = null;
    }
    return payload;
  }

  static DailyMood dailyMoodFromRow(Map<String, dynamic> row) {
    final date = _nullableDateTime(row['mood_date']) ?? DateTime.now();

    return DailyMood(
      date: DateTime(date.year, date.month, date.day),
      mood: _safeInt(row['mood']) ?? 0,
      note: _nullableTrim(row['note']),
      createdAt: _safeInt(row['local_created_at_ms']) ??
          _dateTimeToEpochMs(_nullableDateTime(row['created_at'])) ??
          0,
      updatedAt: _safeInt(row['local_updated_at_ms']) ??
          _dateTimeToEpochMs(_nullableDateTime(row['updated_at'])) ??
          _safeInt(row['local_created_at_ms']) ??
          _dateTimeToEpochMs(_nullableDateTime(row['created_at'])) ??
          0,
    );
  }

  static Map<String, dynamic> dailyMoodToRow(
    DailyMood dailyMood, {
    required String userId,
  }) {
    final payload = <String, dynamic>{
      'user_id': userId.trim(),
      'mood_date': _dateOnlyIso(dailyMood.date),
      'mood': dailyMood.mood,
      'note': _nullableTrim(dailyMood.note),
      'local_created_at_ms': dailyMood.createdAt == 0 ? null : dailyMood.createdAt,
      'local_updated_at_ms': dailyMood.updatedAt == 0 ? null : dailyMood.updatedAt,
      'metadata': const <String, dynamic>{},
    };

    payload.removeWhere((_, value) => value == null);
    return payload;
  }

  RepositoryResult<DiaryEntry> _validateDiaryEntry({
    required DiaryEntry entry,
    required String userId,
    required String expectedLocalId,
  }) {
    final currentUserId = userId.trim();
    final entryLocalId = entry.id.trim();
    if (currentUserId.isEmpty ||
        entryLocalId.isEmpty ||
        entryLocalId != expectedLocalId.trim()) {
      return RepositoryResult<DiaryEntry>.failure(
        const RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: 'Diary V2 entry response did not match current user scope.',
        ),
      );
    }
    return RepositoryResult<DiaryEntry>.success(data: entry);
  }

  RepositoryResult<DailyMood> _validateDailyMood({
    required DailyMood dailyMood,
    required String userId,
    required String expectedDateKey,
  }) {
    final currentUserId = userId.trim();
    if (currentUserId.isEmpty || _dateOnlyIso(dailyMood.date) != expectedDateKey) {
      return RepositoryResult<DailyMood>.failure(
        const RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: 'Diary V2 daily mood response did not match current user scope.',
        ),
      );
    }
    return RepositoryResult<DailyMood>.success(data: dailyMood);
  }

  String? _currentUserId() {
    final providedUserId = _currentUserIdProvider?.call();
    if (providedUserId != null) {
      final normalized = providedUserId.trim();
      return normalized.isEmpty ? null : normalized;
    }

    final userId = _client.auth.currentUser?.id.trim();
    if (userId == null || userId.isEmpty) return null;
    return userId;
  }

  RepositoryError _notAuthenticated() {
    return const RepositoryError(
      code: RepositoryErrorCode.notAuthenticated,
      message: 'No authenticated user session is available.',
    );
  }

  RepositoryError _mapPostgrestError(
    PostgrestException error, {
    required String fallbackMessage,
    required String schemaLabel,
    required String debugLabel,
    required String tableName,
  }) {
    if (kDebugMode) {
      debugPrint('[$debugLabel] postgrest error (${error.code}): ${error.message}');
    }

    final code = (error.code ?? '').trim().toUpperCase();
    if (code == '42P01' || code == 'PGRST204' || code == '42703') {
      return RepositoryError(
        code: RepositoryErrorCode.invalidResponse,
        message: schemaLabel,
        cause: error,
      );
    }
    if (code == 'PGRST116') {
      return RepositoryError(
        code: RepositoryErrorCode.notFound,
        message: 'Diary V2 row was not found.',
        cause: error,
      );
    }
    if (code == '42501') {
      return RepositoryError(
        code: RepositoryErrorCode.permissionDenied,
        message: 'Permission denied for Diary V2 repository operation.',
        cause: error,
      );
    }

    final rawMessage = error.message.toLowerCase();
    if (rawMessage.contains('network') ||
        rawMessage.contains('socket') ||
        rawMessage.contains('timeout') ||
        rawMessage.contains('connection')) {
      return RepositoryError(
        code: RepositoryErrorCode.network,
        message: 'Network error while accessing Diary V2 data.',
        cause: error,
      );
    }
    if (rawMessage.contains(tableName) &&
        (rawMessage.contains('does not exist') ||
            rawMessage.contains('could not find') ||
            rawMessage.contains('schema cache') ||
            rawMessage.contains('column'))) {
      return RepositoryError(
        code: RepositoryErrorCode.invalidResponse,
        message: schemaLabel,
        cause: error,
      );
    }

    return RepositoryError(
      code: RepositoryErrorCode.unknown,
      message: fallbackMessage,
      cause: error,
    );
  }

  static String _dateOnlyIso(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }

  static String? _nullableTrim(Object? value) {
    final normalized = (value ?? '').toString().trim();
    return normalized.isEmpty ? null : normalized;
  }

  static int? _safeInt(Object? value) {
    if (value is int) return value;
    return int.tryParse((value ?? '').toString().trim());
  }

  static DateTime? _nullableDateTime(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final normalized = value.toString().trim();
    if (normalized.isEmpty) return null;
    return DateTime.tryParse(normalized);
  }

  static int? _dateTimeToEpochMs(DateTime? value) {
    if (value == null) return null;
    return value.toLocal().millisecondsSinceEpoch;
  }

  static List<String> _normalizeSupportedTags(Object? value) {
    if (value is! List) return const <String>[];
    final normalized = <String>[];
    for (final item in value) {
      final tag = (item ?? '').toString().trim().toLowerCase();
      if (tag.isEmpty || !DiaryEntry.supportedTags.contains(tag)) continue;
      if (!normalized.contains(tag)) {
        normalized.add(tag);
      }
    }
    return List<String>.unmodifiable(normalized);
  }
}
