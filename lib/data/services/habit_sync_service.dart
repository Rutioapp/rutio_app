import 'package:flutter/foundation.dart';

import '../../core/supabase/rutio_supabase_client.dart';
import '../mappers/habit_remote_mapper.dart';
import '../models/remote/remote_habit.dart';
import '../repositories/habit_repository.dart';
import '../repositories/repository_result.dart';

typedef HabitRemoteIdAssignedCallback = Future<void> Function({
  required String localHabitId,
  required String remoteHabitId,
});

@immutable
class HabitBackfillSummary {
  const HabitBackfillSummary({
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

/// Best-effort remote mirroring for local habit mutations.
///
/// This service must never throw into UI/store mutation flows.
class HabitSyncService {
  HabitSyncService({HabitRepository? habitRepository})
      : _habitRepository = habitRepository;

  HabitRepository? _habitRepository;
  final Map<String, String> _sessionRemoteIdByLocalId = <String, String>{};

  Future<void> syncHabitCreated({
    required Map<String, dynamic> localHabit,
    required int sortOrder,
    String? expectedLocalUserId,
    HabitRemoteIdAssignedCallback? onRemoteIdAssigned,
  }) async {
    await _syncUpsert(
      operation: 'create',
      localHabit: localHabit,
      sortOrder: sortOrder,
      expectedLocalUserId: expectedLocalUserId,
      allowInsertWithoutRemoteId: true,
      onRemoteIdAssigned: onRemoteIdAssigned,
    );
  }

  Future<void> syncHabitUpdated({
    required Map<String, dynamic> localHabit,
    required int sortOrder,
    String? expectedLocalUserId,
  }) async {
    await _syncUpsert(
      operation: 'update',
      localHabit: localHabit,
      sortOrder: sortOrder,
      expectedLocalUserId: expectedLocalUserId,
      allowInsertWithoutRemoteId: false,
    );
  }

  Future<void> syncHabitArchived({
    required Map<String, dynamic> localHabit,
    required int sortOrder,
    String? expectedLocalUserId,
  }) async {
    await _syncUpsert(
      operation: 'archive',
      localHabit: localHabit,
      sortOrder: sortOrder,
      expectedLocalUserId: expectedLocalUserId,
      allowInsertWithoutRemoteId: false,
    );
  }

  Future<void> syncHabitDeleted({
    required String localHabitId,
    Map<String, dynamic>? localHabitSnapshot,
    String? expectedLocalUserId,
  }) async {
    try {
      final userId = _currentAuthenticatedUserId();
      if (userId == null) {
        _debugWarn('habit sync delete skipped: no authenticated session');
        return;
      }

      if (!_isExpectedUser(userId, expectedLocalUserId)) {
        _debugWarn(
          'habit sync delete skipped: local user does not match active auth user',
        );
        return;
      }

      final remoteHabitId = _resolveRemoteHabitId(
        localHabitSnapshot: localHabitSnapshot,
        explicitLocalHabitId: localHabitId,
      );

      if (remoteHabitId == null) {
        _debugWarn(
          'habit sync delete skipped for local habit "$localHabitId": '
          'missing remote UUID mapping',
        );
        return;
      }

      final result = await _repository.deleteHabitForCurrentUser(
        habitId: remoteHabitId,
      );
      if (!result.isSuccess) {
        _debugWarn(
          'habit sync delete failed for local "$localHabitId" remote "$remoteHabitId": '
          '${_errorMessage(result.error)}',
        );
        return;
      }

      final normalizedLocalId = localHabitId.trim();
      if (normalizedLocalId.isNotEmpty) {
        _sessionRemoteIdByLocalId.remove(normalizedLocalId);
      }
    } catch (error) {
      _debugWarn('habit sync delete unexpected error: $error');
    }
  }

  /// Phase 3B candidate helper; intentionally not auto-triggered.
  Future<void> syncAllLocalHabitsForCurrentUser({
    required List<Map<String, dynamic>> localHabits,
    String? expectedLocalUserId,
  }) async {
    for (var i = 0; i < localHabits.length; i += 1) {
      await syncHabitCreated(
        localHabit: localHabits[i],
        sortOrder: i,
        expectedLocalUserId: expectedLocalUserId,
      );
    }
  }

  Future<HabitBackfillSummary> backfillLocalHabitsWithoutRemoteId({
    required List<Map<String, dynamic>> localHabits,
    String? expectedLocalUserId,
    HabitRemoteIdAssignedCallback? onRemoteIdAssigned,
  }) async {
    var totalCandidates = 0;
    var uploadedCount = 0;
    var skippedCount = 0;
    var failedCount = 0;

    try {
      final userId = _currentAuthenticatedUserId();
      if (userId == null) {
        _debugWarn('habit backfill skipped: no authenticated session');
        return const HabitBackfillSummary(
          totalCandidates: 0,
          uploadedCount: 0,
          skippedCount: 0,
          failedCount: 0,
        );
      }

      if (!_isExpectedUser(userId, expectedLocalUserId)) {
        _debugWarn(
          'habit backfill skipped: local user does not match active auth user',
        );
        return const HabitBackfillSummary(
          totalCandidates: 0,
          uploadedCount: 0,
          skippedCount: 0,
          failedCount: 0,
        );
      }

      final eligibleCandidates = <_HabitBackfillCandidate>[];
      for (var i = 0; i < localHabits.length; i += 1) {
        final localHabit = Map<String, dynamic>.from(localHabits[i]);
        final localHabitId = HabitRemoteMapper.extractLocalHabitId(localHabit);
        final hasRemoteId = _resolveRemoteHabitId(
          localHabitSnapshot: localHabit,
          explicitLocalHabitId: localHabitId,
        );
        if (hasRemoteId != null) {
          continue;
        }

        totalCandidates += 1;
        if (!_isBackfillEligible(localHabit, localHabitId: localHabitId)) {
          skippedCount += 1;
          _debugWarn(
            'habit backfill skipped invalid/deleted local habit '
            '"${localHabitId ?? 'unknown'}"',
          );
          continue;
        }

        eligibleCandidates.add(
          _HabitBackfillCandidate(
            localHabit: localHabit,
            localHabitId: localHabitId!.trim(),
            sortOrder: i,
          ),
        );
      }

      if (eligibleCandidates.isEmpty) {
        _debugWarn(
          'habit backfill finished with no eligible candidates '
          '(totalCandidates=$totalCandidates, skipped=$skippedCount)',
        );
        return HabitBackfillSummary(
          totalCandidates: totalCandidates,
          uploadedCount: uploadedCount,
          skippedCount: skippedCount,
          failedCount: failedCount,
        );
      }

      final existingByFingerprint = await _loadRemoteFingerprintIndex(userId);

      for (final candidate in eligibleCandidates) {
        final mappedLocalHabit = HabitRemoteMapper.toRemoteHabit(
          candidate.localHabit,
          userId: userId,
          sortOrder: candidate.sortOrder,
        );
        final localFingerprint = _habitFingerprint(mappedLocalHabit);

        final existingRemoteId = _consumeRemoteIdForFingerprint(
          existingByFingerprint,
          localFingerprint,
        );
        if (existingRemoteId != null) {
          final persisted = await _persistRemoteIdAssignment(
            localHabitId: candidate.localHabitId,
            remoteHabitId: existingRemoteId,
            onRemoteIdAssigned: onRemoteIdAssigned,
            operation: 'backfill_match_existing',
          );
          if (persisted) {
            skippedCount += 1;
          } else {
            failedCount += 1;
          }
          continue;
        }

        final result = await _repository.upsertHabitForCurrentUser(
          mappedLocalHabit,
        );
        if (!result.isSuccess || result.data == null) {
          failedCount += 1;
          _debugWarn(
            'habit backfill upload failed for local "${candidate.localHabitId}": '
            '${_errorMessage(result.error)}',
          );
          continue;
        }

        final syncedHabit = result.data!;
        if (syncedHabit.userId != userId) {
          failedCount += 1;
          _debugWarn(
            'habit backfill ignored response for local "${candidate.localHabitId}": '
            'user scope mismatch',
          );
          continue;
        }

        final syncedRemoteHabitId = (syncedHabit.id ?? '').trim();
        if (syncedRemoteHabitId.isEmpty) {
          failedCount += 1;
          _debugWarn(
            'habit backfill ignored response for local "${candidate.localHabitId}": '
            'missing remote UUID in payload',
          );
          continue;
        }

        final persisted = await _persistRemoteIdAssignment(
          localHabitId: candidate.localHabitId,
          remoteHabitId: syncedRemoteHabitId,
          onRemoteIdAssigned: onRemoteIdAssigned,
          operation: 'backfill_upload',
        );
        if (!persisted) {
          failedCount += 1;
          continue;
        }

        uploadedCount += 1;

        final syncedFingerprint = _habitFingerprint(syncedHabit);
        _indexRemoteIdForFingerprint(
          existingByFingerprint,
          fingerprint: syncedFingerprint,
          remoteHabitId: syncedRemoteHabitId,
        );
      }
    } catch (error) {
      _debugWarn('habit backfill unexpected error: $error');
    }

    _debugWarn(
      'habit backfill finished: totalCandidates=$totalCandidates, '
      'uploaded=$uploadedCount, skipped=$skippedCount, failed=$failedCount',
    );
    return HabitBackfillSummary(
      totalCandidates: totalCandidates,
      uploadedCount: uploadedCount,
      skippedCount: skippedCount,
      failedCount: failedCount,
    );
  }

  Future<void> _syncUpsert({
    required String operation,
    required Map<String, dynamic> localHabit,
    required int sortOrder,
    required String? expectedLocalUserId,
    required bool allowInsertWithoutRemoteId,
    HabitRemoteIdAssignedCallback? onRemoteIdAssigned,
  }) async {
    try {
      final userId = _currentAuthenticatedUserId();
      if (userId == null) {
        _debugWarn('habit sync $operation skipped: no authenticated session');
        return;
      }

      if (!_isExpectedUser(userId, expectedLocalUserId)) {
        _debugWarn(
          'habit sync $operation skipped: local user does not match active auth user',
        );
        return;
      }

      final localId = HabitRemoteMapper.extractLocalHabitId(localHabit);
      final existingRemoteId = _resolveRemoteHabitId(
        localHabitSnapshot: localHabit,
        explicitLocalHabitId: localId,
      );

      if (!allowInsertWithoutRemoteId && existingRemoteId == null) {
        _debugWarn(
          'habit sync $operation skipped for local habit "${localId ?? 'unknown'}": '
          'missing remote UUID mapping',
        );
        return;
      }

      final remoteHabit = HabitRemoteMapper.toRemoteHabit(
        localHabit,
        userId: userId,
        sortOrder: sortOrder,
        remoteHabitIdOverride: existingRemoteId,
      );

      final result = await _repository.upsertHabitForCurrentUser(remoteHabit);
      if (!result.isSuccess || result.data == null) {
        _debugWarn(
          'habit sync $operation failed for local "${localId ?? 'unknown'}": '
          '${_errorMessage(result.error)}',
        );
        return;
      }

      final syncedHabit = result.data!;
      if (syncedHabit.userId != userId) {
        _debugWarn(
          'habit sync $operation ignored response: user scope mismatch',
        );
        return;
      }

      final syncedRemoteHabitId = (syncedHabit.id ?? '').trim();
      if (syncedRemoteHabitId.isEmpty) {
        _debugWarn(
          'habit sync $operation ignored response: missing remote UUID in payload',
        );
        return;
      }

      if (localId != null && localId.isNotEmpty) {
        await _persistRemoteIdAssignment(
          localHabitId: localId,
          remoteHabitId: syncedRemoteHabitId,
          onRemoteIdAssigned: onRemoteIdAssigned,
          operation: operation,
        );
      }
    } catch (error) {
      _debugWarn('habit sync $operation unexpected error: $error');
    }
  }

  bool _isBackfillEligible(
    Map<String, dynamic> localHabit, {
    required String? localHabitId,
  }) {
    final normalizedLocalId = (localHabitId ?? '').trim();
    if (normalizedLocalId.isEmpty) return false;

    final isDeleted =
        localHabit['deleted'] == true || localHabit['isDeleted'] == true;
    if (isDeleted) return false;

    final name =
        (localHabit['name'] ?? localHabit['title'] ?? '').toString().trim();
    return name.isNotEmpty;
  }

  Future<Map<String, List<String>>> _loadRemoteFingerprintIndex(
    String userId,
  ) async {
    final index = <String, List<String>>{};
    final remoteResult = await _repository.fetchHabitsForCurrentUser();
    if (!remoteResult.isSuccess || remoteResult.data == null) {
      _debugWarn(
        'habit backfill could not prefetch remote habits for duplicate checks: '
        '${_errorMessage(remoteResult.error)}',
      );
      return index;
    }

    for (final remoteHabit in remoteResult.data!) {
      if (remoteHabit.userId != userId) continue;
      final remoteHabitId = (remoteHabit.id ?? '').trim();
      if (remoteHabitId.isEmpty) continue;
      final fingerprint = _habitFingerprint(remoteHabit);
      _indexRemoteIdForFingerprint(
        index,
        fingerprint: fingerprint,
        remoteHabitId: remoteHabitId,
      );
    }

    return index;
  }

  String? _consumeRemoteIdForFingerprint(
    Map<String, List<String>> fingerprintIndex,
    String fingerprint,
  ) {
    final bucket = fingerprintIndex[fingerprint];
    if (bucket == null || bucket.isEmpty) return null;
    final remoteHabitId = bucket.removeAt(0).trim().toLowerCase();
    if (bucket.isEmpty) {
      fingerprintIndex.remove(fingerprint);
    } else {
      fingerprintIndex[fingerprint] = bucket;
    }
    return remoteHabitId.isEmpty ? null : remoteHabitId;
  }

  void _indexRemoteIdForFingerprint(
    Map<String, List<String>> fingerprintIndex, {
    required String fingerprint,
    required String remoteHabitId,
  }) {
    final normalizedRemoteHabitId = remoteHabitId.trim().toLowerCase();
    if (normalizedRemoteHabitId.isEmpty) return;
    final bucket = fingerprintIndex.putIfAbsent(
      fingerprint,
      () => <String>[],
    );
    if (bucket.contains(normalizedRemoteHabitId)) return;
    bucket.add(normalizedRemoteHabitId);
  }

  String _habitFingerprint(RemoteHabit remoteHabit) {
    final reminderTime = (remoteHabit.reminderTime ?? '').trim();
    final normalizedName = remoteHabit.name.trim().toLowerCase();
    final normalizedFamily = (remoteHabit.familyId ?? '').trim().toLowerCase();
    final normalizedEmoji = (remoteHabit.emoji ?? '').trim();
    final normalizedUnit = (remoteHabit.unit ?? '').trim().toLowerCase();
    final normalizedColor = (remoteHabit.colorId ?? '').trim().toLowerCase();

    return [
      normalizedName,
      normalizedFamily,
      normalizedEmoji,
      remoteHabit.habitType.trim().toLowerCase(),
      remoteHabit.targetCount?.toString() ?? '',
      normalizedUnit,
      normalizedColor,
      remoteHabit.reminderEnabled ? '1' : '0',
      reminderTime,
      remoteHabit.isArchived ? '1' : '0',
      remoteHabit.sortOrder.toString(),
    ].join('|');
  }

  Future<bool> _persistRemoteIdAssignment({
    required String localHabitId,
    required String remoteHabitId,
    required String operation,
    HabitRemoteIdAssignedCallback? onRemoteIdAssigned,
  }) async {
    final normalizedLocalId = localHabitId.trim();
    final normalizedRemoteId = remoteHabitId.trim().toLowerCase();
    if (normalizedLocalId.isEmpty || normalizedRemoteId.isEmpty) {
      _debugWarn(
        'habit sync $operation skipped remoteId persistence: '
        'invalid local or remote habit id',
      );
      return false;
    }

    _sessionRemoteIdByLocalId[normalizedLocalId] = normalizedRemoteId;

    if (onRemoteIdAssigned == null) return true;
    try {
      await onRemoteIdAssigned(
        localHabitId: normalizedLocalId,
        remoteHabitId: normalizedRemoteId,
      );
      return true;
    } catch (error) {
      _debugWarn(
        'habit sync $operation failed to persist remoteId locally: $error',
      );
      return false;
    }
  }

  HabitRepository get _repository {
    return _habitRepository ??= HabitRepository();
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

  String? _resolveRemoteHabitId({
    required Map<String, dynamic>? localHabitSnapshot,
    required String? explicitLocalHabitId,
  }) {
    final localId = (explicitLocalHabitId ?? '').trim();

    if (localHabitSnapshot != null) {
      final mappedId = HabitRemoteMapper.extractRemoteHabitId(
        localHabitSnapshot,
        remoteHabitIdOverride:
            localId.isNotEmpty ? _sessionRemoteIdByLocalId[localId] : null,
      );
      if (mappedId != null) return mappedId;
    }

    if (localId.isNotEmpty && HabitRemoteMapper.isUuid(localId)) {
      return localId.toLowerCase();
    }

    final mappedBySession = _sessionRemoteIdByLocalId[localId];
    if (mappedBySession != null && mappedBySession.trim().isNotEmpty) {
      return mappedBySession.trim().toLowerCase();
    }

    return null;
  }

  String _errorMessage(RepositoryError? error) {
    if (error == null) return 'unknown repository error';
    return '${error.code.name}: ${error.message}';
  }

  void _debugWarn(String message) {
    if (!kDebugMode) return;
    debugPrint('[habit_sync] $message');
  }
}

class _HabitBackfillCandidate {
  const _HabitBackfillCandidate({
    required this.localHabit,
    required this.localHabitId,
    required this.sortOrder,
  });

  final Map<String, dynamic> localHabit;
  final String localHabitId;
  final int sortOrder;
}
