import 'package:flutter/foundation.dart';

import '../../core/supabase/rutio_supabase_client.dart';
import '../mappers/habit_remote_mapper.dart';
import '../repositories/habit_repository.dart';
import '../repositories/repository_result.dart';

typedef HabitRemoteIdAssignedCallback = Future<void> Function({
  required String localHabitId,
  required String remoteHabitId,
});

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
        _sessionRemoteIdByLocalId[localId] = syncedRemoteHabitId;

        if (onRemoteIdAssigned != null) {
          try {
            await onRemoteIdAssigned(
              localHabitId: localId,
              remoteHabitId: syncedRemoteHabitId,
            );
          } catch (error) {
            _debugWarn(
              'habit sync $operation failed to persist remoteId locally: $error',
            );
          }
        }
      }
    } catch (error) {
      _debugWarn('habit sync $operation unexpected error: $error');
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
