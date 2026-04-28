import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/rutio_supabase_client.dart';
import '../models/remote/remote_journal_entry.dart';
import 'repository_result.dart';

class JournalEntryRepository {
  JournalEntryRepository({SupabaseClient? client})
      : _client = client ?? RutioSupabaseClient.instance;

  final SupabaseClient _client;

  static const String _journalEntriesTable = 'journal_entries';
  static const String _journalEntryColumns = '''
id,
user_id,
entry_date,
title,
content,
mood,
emoji,
habit_id,
local_habit_id,
family_id,
source,
is_deleted,
created_at,
updated_at
''';

  Future<RepositoryResult<List<RemoteJournalEntry>>> fetchEntriesForDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final userId = _currentUserId();
    if (userId == null) {
      return RepositoryResult<List<RemoteJournalEntry>>.failure(
        _notAuthenticated(),
      );
    }

    final startKey = _dateOnlyIso(start);
    final endKey = _dateOnlyIso(end);

    try {
      final rows = await _client
          .from(_journalEntriesTable)
          .select(_journalEntryColumns)
          .eq('user_id', userId)
          .gte('entry_date', startKey)
          .lte('entry_date', endKey)
          .order('entry_date', ascending: true)
          .order('created_at', ascending: true);

      final entries = rows
          .whereType<Map>()
          .map(
            (row) => RemoteJournalEntry.fromMap(
              Map<String, dynamic>.from(row.cast<String, dynamic>()),
            ),
          )
          .toList(growable: false);

      return RepositoryResult<List<RemoteJournalEntry>>.success(data: entries);
    } on PostgrestException catch (error) {
      return RepositoryResult<List<RemoteJournalEntry>>.failure(
        _mapPostgrestError(
          error,
          fallbackMessage: 'Could not fetch journal entries.',
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[journal_entry_repository] unexpected fetch-range error: $error');
      }
      return RepositoryResult<List<RemoteJournalEntry>>.failure(
        RepositoryError(
          code: RepositoryErrorCode.unknown,
          message: 'Could not fetch journal entries.',
          cause: error,
        ),
      );
    }
  }

  Future<RepositoryResult<List<RemoteJournalEntry>>> fetchRecentEntries({
    int limit = 50,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return RepositoryResult<List<RemoteJournalEntry>>.failure(
        _notAuthenticated(),
      );
    }

    final safeLimit = limit < 1 ? 1 : limit;
    try {
      final rows = await _client
          .from(_journalEntriesTable)
          .select(_journalEntryColumns)
          .eq('user_id', userId)
          .order('entry_date', ascending: false)
          .order('created_at', ascending: false)
          .limit(safeLimit);

      final entries = rows
          .whereType<Map>()
          .map(
            (row) => RemoteJournalEntry.fromMap(
              Map<String, dynamic>.from(row.cast<String, dynamic>()),
            ),
          )
          .toList(growable: false);

      return RepositoryResult<List<RemoteJournalEntry>>.success(data: entries);
    } on PostgrestException catch (error) {
      return RepositoryResult<List<RemoteJournalEntry>>.failure(
        _mapPostgrestError(
          error,
          fallbackMessage: 'Could not fetch recent journal entries.',
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[journal_entry_repository] unexpected fetch-recent error: $error');
      }
      return RepositoryResult<List<RemoteJournalEntry>>.failure(
        RepositoryError(
          code: RepositoryErrorCode.unknown,
          message: 'Could not fetch recent journal entries.',
          cause: error,
        ),
      );
    }
  }

  Future<RepositoryResult<RemoteJournalEntry>> insertJournalEntry(
    RemoteJournalEntry entry,
  ) async {
    final userId = _currentUserId();
    if (userId == null) {
      return RepositoryResult<RemoteJournalEntry>.failure(_notAuthenticated());
    }

    final payload = Map<String, dynamic>.from(entry.toUpsertMap());
    payload['user_id'] = userId;
    payload.remove('id');

    try {
      final row = await _client
          .from(_journalEntriesTable)
          .insert(payload)
          .select(_journalEntryColumns)
          .single();

      final remote = RemoteJournalEntry.fromMap(Map<String, dynamic>.from(row));
      return _validateScopedEntry(
        remote: remote,
        userId: userId,
        expectedRemoteId: null,
      );
    } on PostgrestException catch (error) {
      return RepositoryResult<RemoteJournalEntry>.failure(
        _mapPostgrestError(
          error,
          fallbackMessage: 'Could not insert journal entry.',
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[journal_entry_repository] unexpected insert error: $error');
      }
      return RepositoryResult<RemoteJournalEntry>.failure(
        RepositoryError(
          code: RepositoryErrorCode.unknown,
          message: 'Could not insert journal entry.',
          cause: error,
        ),
      );
    }
  }

  Future<RepositoryResult<RemoteJournalEntry>> updateJournalEntry(
    RemoteJournalEntry entry,
  ) async {
    final userId = _currentUserId();
    if (userId == null) {
      return RepositoryResult<RemoteJournalEntry>.failure(_notAuthenticated());
    }

    final remoteId = (entry.id ?? '').trim().toLowerCase();
    if (remoteId.isEmpty) {
      return RepositoryResult<RemoteJournalEntry>.failure(
        const RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: 'Remote journal entry id is required for update.',
        ),
      );
    }

    final payload = Map<String, dynamic>.from(entry.toUpsertMap())
      ..remove('id')
      ..['user_id'] = userId;

    try {
      final rows = await _client
          .from(_journalEntriesTable)
          .update(payload)
          .eq('user_id', userId)
          .eq('id', remoteId)
          .select(_journalEntryColumns);

      if (rows.isEmpty) {
        return RepositoryResult<RemoteJournalEntry>.failure(
          const RepositoryError(
            code: RepositoryErrorCode.notFound,
            message: 'Journal entry row was not found for update.',
          ),
        );
      }

      final remote = RemoteJournalEntry.fromMap(
        Map<String, dynamic>.from(rows.first as Map),
      );
      return _validateScopedEntry(
        remote: remote,
        userId: userId,
        expectedRemoteId: remoteId,
      );
    } on PostgrestException catch (error) {
      return RepositoryResult<RemoteJournalEntry>.failure(
        _mapPostgrestError(
          error,
          fallbackMessage: 'Could not update journal entry.',
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[journal_entry_repository] unexpected update error: $error');
      }
      return RepositoryResult<RemoteJournalEntry>.failure(
        RepositoryError(
          code: RepositoryErrorCode.unknown,
          message: 'Could not update journal entry.',
          cause: error,
        ),
      );
    }
  }

  Future<RepositoryResult<RemoteJournalEntry>> upsertJournalEntry(
    RemoteJournalEntry entry,
  ) async {
    final remoteId = (entry.id ?? '').trim();
    if (remoteId.isEmpty) {
      return insertJournalEntry(entry);
    }

    final updated = await updateJournalEntry(entry);
    if (updated.isSuccess) return updated;

    if (updated.error?.code == RepositoryErrorCode.notFound) {
      final payloadWithoutId = RemoteJournalEntry(
        id: null,
        userId: entry.userId,
        entryDate: entry.entryDate,
        title: entry.title,
        content: entry.content,
        mood: entry.mood,
        emoji: entry.emoji,
        habitId: entry.habitId,
        localHabitId: entry.localHabitId,
        familyId: entry.familyId,
        source: entry.source,
        isDeleted: entry.isDeleted,
        createdAt: entry.createdAt,
        updatedAt: entry.updatedAt,
        raw: entry.raw,
      );
      return insertJournalEntry(payloadWithoutId);
    }

    return updated;
  }

  Future<RepositoryResult<void>> deleteJournalEntry({
    required String id,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return RepositoryResult<void>.failure(_notAuthenticated());
    }

    final remoteId = id.trim().toLowerCase();
    if (remoteId.isEmpty) {
      return RepositoryResult<void>.failure(
        const RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: 'Remote journal entry id is required for delete.',
        ),
      );
    }

    try {
      await _client
          .from(_journalEntriesTable)
          .delete()
          .eq('user_id', userId)
          .eq('id', remoteId);
      return const RepositoryResult<void>.success();
    } on PostgrestException catch (error) {
      return RepositoryResult<void>.failure(
        _mapPostgrestError(
          error,
          fallbackMessage: 'Could not delete journal entry.',
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[journal_entry_repository] unexpected delete error: $error');
      }
      return RepositoryResult<void>.failure(
        RepositoryError(
          code: RepositoryErrorCode.unknown,
          message: 'Could not delete journal entry.',
          cause: error,
        ),
      );
    }
  }

  Future<RepositoryResult<RemoteJournalEntry>> softDeleteJournalEntry({
    required String id,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return RepositoryResult<RemoteJournalEntry>.failure(_notAuthenticated());
    }

    final remoteId = id.trim().toLowerCase();
    if (remoteId.isEmpty) {
      return RepositoryResult<RemoteJournalEntry>.failure(
        const RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: 'Remote journal entry id is required for soft delete.',
        ),
      );
    }

    try {
      final rows = await _client
          .from(_journalEntriesTable)
          .update(<String, dynamic>{
            'is_deleted': true,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('id', remoteId)
          .select(_journalEntryColumns);

      if (rows.isEmpty) {
        return RepositoryResult<RemoteJournalEntry>.failure(
          const RepositoryError(
            code: RepositoryErrorCode.notFound,
            message: 'Journal entry row was not found for soft delete.',
          ),
        );
      }

      final remote = RemoteJournalEntry.fromMap(
        Map<String, dynamic>.from(rows.first as Map),
      );
      return _validateScopedEntry(
        remote: remote,
        userId: userId,
        expectedRemoteId: remoteId,
      );
    } on PostgrestException catch (error) {
      return RepositoryResult<RemoteJournalEntry>.failure(
        _mapPostgrestError(
          error,
          fallbackMessage: 'Could not soft-delete journal entry.',
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[journal_entry_repository] unexpected soft-delete error: $error');
      }
      return RepositoryResult<RemoteJournalEntry>.failure(
        RepositoryError(
          code: RepositoryErrorCode.unknown,
          message: 'Could not soft-delete journal entry.',
          cause: error,
        ),
      );
    }
  }

  RepositoryResult<RemoteJournalEntry> _validateScopedEntry({
    required RemoteJournalEntry remote,
    required String userId,
    required String? expectedRemoteId,
  }) {
    final remoteId = (remote.id ?? '').trim().toLowerCase();
    final expectedId = (expectedRemoteId ?? '').trim().toLowerCase();
    if (remote.userId != userId ||
        remoteId.isEmpty ||
        (expectedId.isNotEmpty && remoteId != expectedId)) {
      return RepositoryResult<RemoteJournalEntry>.failure(
        const RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: 'Journal entry response did not match current user scope.',
        ),
      );
    }

    return RepositoryResult<RemoteJournalEntry>.success(data: remote);
  }

  String? _currentUserId() {
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
  }) {
    if (kDebugMode) {
      debugPrint(
        '[journal_entry_repository] postgrest error (${error.code}): ${error.message}',
      );
    }

    final code = (error.code ?? '').trim();
    if (_isSchemaMissingError(error)) {
      return RepositoryError(
        code: RepositoryErrorCode.invalidResponse,
        message: 'Journal entries table/schema is unavailable.',
        cause: error,
      );
    }
    if (code == 'PGRST116') {
      return RepositoryError(
        code: RepositoryErrorCode.notFound,
        message: 'Journal entry row was not found.',
        cause: error,
      );
    }
    if (code == '42501') {
      return RepositoryError(
        code: RepositoryErrorCode.permissionDenied,
        message: 'Permission denied for journal entry operation.',
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
        message: 'Network error while accessing journal entries.',
        cause: error,
      );
    }

    return RepositoryError(
      code: RepositoryErrorCode.unknown,
      message: fallbackMessage,
      cause: error,
    );
  }

  bool _isSchemaMissingError(PostgrestException error) {
    final code = (error.code ?? '').trim().toUpperCase();
    if (code == '42P01' || code == 'PGRST204' || code == '42703') {
      return true;
    }

    final message = error.message.toLowerCase();
    return message.contains('journal_entries') &&
        (message.contains('does not exist') ||
            message.contains('could not find') ||
            message.contains('schema cache') ||
            message.contains('column'));
  }

  String _dateOnlyIso(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }
}
