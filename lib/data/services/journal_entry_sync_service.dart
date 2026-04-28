import 'package:flutter/foundation.dart';

import '../../core/supabase/rutio_supabase_client.dart';
import '../../models/diary_entry.dart';
import '../mappers/journal_entry_remote_mapper.dart';
import '../repositories/journal_entry_repository.dart';
import '../repositories/repository_result.dart';

typedef JournalEntryRemoteIdAssignedCallback = Future<void> Function({
  required String localEntryId,
  required String remoteEntryId,
});

@immutable
class JournalEntryBackfillSummary {
  const JournalEntryBackfillSummary({
    required this.totalCandidates,
    required this.uploadedCount,
    required this.skippedCount,
    required this.failedCount,
  });

  final int totalCandidates;
  final int uploadedCount;
  final int skippedCount;
  final int failedCount;
}

class JournalEntrySyncService {
  JournalEntrySyncService({JournalEntryRepository? journalEntryRepository})
      : _journalEntryRepository = journalEntryRepository;

  JournalEntryRepository? _journalEntryRepository;

  Future<String?> syncEntryCreated({
    required Map<String, dynamic> localEntry,
    required List<Map<String, dynamic>> activeHabits,
    String? expectedLocalUserId,
    String source = 'manual',
  }) async {
    try {
      final userId = _currentAuthenticatedUserId();
      if (userId == null) {
        _debugWarn('journal create sync skipped: no authenticated session');
        return null;
      }
      if (!_isExpectedUser(userId, expectedLocalUserId)) {
        _debugWarn('journal create sync skipped: local user mismatch');
        return null;
      }

      final diaryEntry = DiaryEntry.fromJson(localEntry);
      final remote = JournalEntryRemoteMapper.toRemoteJournalEntry(
        localEntry: diaryEntry,
        localEntryMap: localEntry,
        userId: userId,
        activeHabits: activeHabits,
        source: source,
        isDeleted: false,
      );
      if (remote == null) {
        _debugWarn(
          'journal create sync skipped: invalid/empty entry '
          '(localId=${_localEntryId(localEntry) ?? 'unknown'})',
        );
        return null;
      }

      final hasRemoteId = (remote.id ?? '').trim().isNotEmpty;
      final result = hasRemoteId
          ? await _repository.upsertJournalEntry(remote)
          : await _repository.insertJournalEntry(remote);
      if (!result.isSuccess || result.data == null) {
        _debugWarn(
          'journal create sync failed '
          '(localId=${_localEntryId(localEntry) ?? 'unknown'}, '
          'date=${_dateIsoFromEntry(diaryEntry)}): ${_errorMessage(result.error)}',
        );
        return null;
      }

      final remoteId = (result.data!.id ?? '').trim().toLowerCase();
      if (remoteId.isEmpty) return null;
      return remoteId;
    } catch (error) {
      _debugWarn('journal create sync unexpected error: $error');
      return null;
    }
  }

  Future<String?> syncEntryUpdated({
    required Map<String, dynamic> localEntry,
    required List<Map<String, dynamic>> activeHabits,
    String? expectedLocalUserId,
    bool allowCreateWhenRemoteIdMissing = false,
  }) async {
    try {
      final userId = _currentAuthenticatedUserId();
      if (userId == null) {
        _debugWarn('journal update sync skipped: no authenticated session');
        return null;
      }
      if (!_isExpectedUser(userId, expectedLocalUserId)) {
        _debugWarn('journal update sync skipped: local user mismatch');
        return null;
      }

      final remoteId = JournalEntryRemoteMapper.extractRemoteId(localEntry);
      if (remoteId == null && !allowCreateWhenRemoteIdMissing) {
        _debugWarn(
          'journal update sync skipped: missing remoteId '
          '(localId=${_localEntryId(localEntry) ?? 'unknown'})',
        );
        return null;
      }

      final diaryEntry = DiaryEntry.fromJson(localEntry);
      final remote = JournalEntryRemoteMapper.toRemoteJournalEntry(
        localEntry: diaryEntry,
        localEntryMap: localEntry,
        userId: userId,
        activeHabits: activeHabits,
        source: 'manual',
        remoteIdOverride: remoteId,
        isDeleted: false,
      );
      if (remote == null) {
        _debugWarn(
          'journal update sync skipped: invalid/empty entry '
          '(localId=${_localEntryId(localEntry) ?? 'unknown'})',
        );
        return null;
      }

      final result = remoteId == null
          ? await _repository.insertJournalEntry(remote)
          : await _repository.updateJournalEntry(remote);
      if (!result.isSuccess || result.data == null) {
        _debugWarn(
          'journal update sync failed '
          '(localId=${_localEntryId(localEntry) ?? 'unknown'}, '
          'remoteId=${remoteId ?? 'none'}, '
          'date=${_dateIsoFromEntry(diaryEntry)}): ${_errorMessage(result.error)}',
        );
        return null;
      }

      final syncedRemoteId = (result.data!.id ?? '').trim().toLowerCase();
      if (syncedRemoteId.isEmpty) return null;
      return syncedRemoteId;
    } catch (error) {
      _debugWarn('journal update sync unexpected error: $error');
      return null;
    }
  }

  Future<void> syncEntryDeleted({
    required String localEntryId,
    required String? remoteEntryId,
    String? expectedLocalUserId,
    bool preferSoftDelete = true,
  }) async {
    try {
      final userId = _currentAuthenticatedUserId();
      if (userId == null) {
        _debugWarn('journal delete sync skipped: no authenticated session');
        return;
      }
      if (!_isExpectedUser(userId, expectedLocalUserId)) {
        _debugWarn('journal delete sync skipped: local user mismatch');
        return;
      }

      final normalizedRemoteId = _normalizedUuidOrNull(remoteEntryId);
      if (normalizedRemoteId == null) {
        _debugWarn(
          'journal delete sync skipped: missing/invalid remoteId '
          '(localId=$localEntryId)',
        );
        return;
      }

      if (preferSoftDelete) {
        final softDeleteResult = await _repository.softDeleteJournalEntry(
          id: normalizedRemoteId,
        );
        if (!softDeleteResult.isSuccess) {
          _debugWarn(
            'journal soft-delete sync failed '
            '(localId=$localEntryId, remoteId=$normalizedRemoteId): '
            '${_errorMessage(softDeleteResult.error)}',
          );
        }
        return;
      }

      final deleteResult = await _repository.deleteJournalEntry(
        id: normalizedRemoteId,
      );
      if (!deleteResult.isSuccess) {
        _debugWarn(
          'journal delete sync failed '
          '(localId=$localEntryId, remoteId=$normalizedRemoteId): '
          '${_errorMessage(deleteResult.error)}',
        );
      }
    } catch (error) {
      _debugWarn('journal delete sync unexpected error: $error');
    }
  }

  Future<JournalEntryBackfillSummary> syncExistingLocalJournalEntriesOnce({
    required List<Map<String, dynamic>> localEntries,
    required List<Map<String, dynamic>> activeHabits,
    String? expectedLocalUserId,
    JournalEntryRemoteIdAssignedCallback? onRemoteIdAssigned,
    bool force = false,
  }) async {
    var totalCandidates = 0;
    var uploadedCount = 0;
    var skippedCount = 0;
    var failedCount = 0;

    try {
      final userId = _currentAuthenticatedUserId();
      if (userId == null) {
        _debugWarn('journal backfill skipped: no authenticated session');
        return const JournalEntryBackfillSummary(
          totalCandidates: 0,
          uploadedCount: 0,
          skippedCount: 0,
          failedCount: 0,
        );
      }
      if (!_isExpectedUser(userId, expectedLocalUserId)) {
        _debugWarn('journal backfill skipped: local user mismatch');
        return const JournalEntryBackfillSummary(
          totalCandidates: 0,
          uploadedCount: 0,
          skippedCount: 0,
          failedCount: 0,
        );
      }

      for (final localEntry in localEntries) {
        final localEntryId = _localEntryId(localEntry) ?? 'unknown';
        final existingRemoteId = JournalEntryRemoteMapper.extractRemoteId(
          localEntry,
        );

        if (!force && existingRemoteId != null) {
          continue;
        }

        totalCandidates += 1;
        final diaryEntry = DiaryEntry.fromJson(localEntry);
        final remote = JournalEntryRemoteMapper.toRemoteJournalEntry(
          localEntry: diaryEntry,
          localEntryMap: localEntry,
          userId: userId,
          activeHabits: activeHabits,
          source: 'migration',
          isDeleted: false,
        );
        if (remote == null) {
          skippedCount += 1;
          _debugWarn(
            'journal backfill skipped invalid entry '
            '(localId=$localEntryId, date=${_dateIsoFromEntry(diaryEntry)})',
          );
          continue;
        }

        final result = await _repository.insertJournalEntry(remote);
        if (!result.isSuccess || result.data == null) {
          failedCount += 1;
          _debugWarn(
            'journal backfill failed '
            '(localId=$localEntryId, date=${_dateIsoFromEntry(diaryEntry)}): '
            '${_errorMessage(result.error)}',
          );
          continue;
        }

        final syncedRemoteId = _normalizedUuidOrNull(result.data!.id);
        if (syncedRemoteId == null) {
          failedCount += 1;
          _debugWarn(
            'journal backfill failed: missing remote id in response '
            '(localId=$localEntryId, date=${_dateIsoFromEntry(diaryEntry)})',
          );
          continue;
        }

        if (onRemoteIdAssigned != null) {
          try {
            await onRemoteIdAssigned(
              localEntryId: localEntryId,
              remoteEntryId: syncedRemoteId,
            );
          } catch (error) {
            failedCount += 1;
            _debugWarn(
              'journal backfill failed persisting remoteId '
              '(localId=$localEntryId): $error',
            );
            continue;
          }
        }

        uploadedCount += 1;
      }
    } catch (error) {
      _debugWarn('journal backfill unexpected error: $error');
    }

    _debugWarn(
      'journal backfill finished: totalCandidates=$totalCandidates, '
      'uploaded=$uploadedCount, skipped=$skippedCount, failed=$failedCount',
    );

    return JournalEntryBackfillSummary(
      totalCandidates: totalCandidates,
      uploadedCount: uploadedCount,
      skippedCount: skippedCount,
      failedCount: failedCount,
    );
  }

  JournalEntryRepository get _repository {
    return _journalEntryRepository ??= JournalEntryRepository();
  }

  String? _currentAuthenticatedUserId() {
    if (!RutioSupabaseClient.isInitialized) return null;
    try {
      final userId = RutioSupabaseClient.instance.auth.currentUser?.id.trim();
      if (userId == null || userId.isEmpty) return null;
      return userId;
    } catch (_) {
      return null;
    }
  }

  bool _isExpectedUser(String authenticatedUserId, String? expectedLocalUserId) {
    final expected = (expectedLocalUserId ?? '').trim();
    if (expected.isEmpty) return true;
    return expected == authenticatedUserId;
  }

  String _errorMessage(RepositoryError? error) {
    if (error == null) return 'unknown repository error';
    return '${error.code.name}: ${error.message}';
  }

  String? _localEntryId(Map<String, dynamic> localEntry) {
    final normalized = (localEntry['id'] ?? '').toString().trim();
    return normalized.isEmpty ? null : normalized;
  }

  String? _normalizedUuidOrNull(dynamic value) {
    final normalized = (value ?? '').toString().trim();
    if (normalized.isEmpty) return null;
    if (!RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    ).hasMatch(normalized)) {
      return null;
    }
    return normalized.toLowerCase();
  }

  String _dateIsoFromEntry(DiaryEntry entry) {
    final date = DateTime.fromMillisecondsSinceEpoch(entry.createdAt);
    final normalized = DateTime(date.year, date.month, date.day);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }

  void _debugWarn(String message) {
    if (!kDebugMode) return;
    debugPrint('[journal_entry_sync] $message');
  }
}
