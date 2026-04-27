import 'package:flutter/foundation.dart';

import '../../core/supabase/rutio_supabase_client.dart';
import '../mappers/habit_log_remote_mapper.dart';
import '../repositories/habit_log_repository.dart';
import '../repositories/repository_result.dart';

/// Best-effort remote mirroring for local habit log mutations.
///
/// This service must never throw into UI/store mutation flows.
class HabitLogSyncService {
  HabitLogSyncService({HabitLogRepository? habitLogRepository})
      : _habitLogRepository = habitLogRepository;

  HabitLogRepository? _habitLogRepository;

  Future<void> syncTodayLogForHabit({
    required Map<String, dynamic> localHabit,
    required bool isCompleted,
    required bool isSkipped,
    num? countValue,
    String? expectedLocalUserId,
    String? note,
  }) async {
    await syncDailyLogForHabit(
      localHabit: localHabit,
      date: DateTime.now(),
      isCompleted: isCompleted,
      isSkipped: isSkipped,
      countValue: countValue,
      expectedLocalUserId: expectedLocalUserId,
      note: note,
    );
  }

  Future<void> syncDailyLogForHabit({
    required Map<String, dynamic> localHabit,
    required DateTime date,
    required bool isCompleted,
    required bool isSkipped,
    num? countValue,
    String? expectedLocalUserId,
    String? note,
  }) async {
    try {
      final authenticatedUserId = _currentAuthenticatedUserId();
      if (authenticatedUserId == null) {
        _debugWarn('habit log sync skipped: no authenticated session');
        return;
      }

      if (!_isExpectedUser(authenticatedUserId, expectedLocalUserId)) {
        _debugWarn(
          'habit log sync skipped: local user does not match active auth user',
        );
        return;
      }

      final localHabitId = _localHabitId(localHabit);
      final remoteHabitId = HabitLogRemoteMapper.extractRemoteHabitId(localHabit);
      if (remoteHabitId == null) {
        _debugWarn(
          'habit log sync skipped for local habit "${localHabitId ?? 'unknown'}": '
          'missing persisted remoteId',
        );
        return;
      }

      final remoteLog = HabitLogRemoteMapper.toRemoteHabitLog(
        localHabit: localHabit,
        userId: authenticatedUserId,
        date: date,
        isCompleted: isCompleted,
        isSkipped: isSkipped,
        countValue: countValue,
        note: note,
        source: 'manual',
      );
      if (remoteLog == null) {
        _debugWarn(
          'habit log sync skipped for local habit "${localHabitId ?? 'unknown'}": '
          'could not map daily state',
        );
        return;
      }

      final result = await _repository.upsertDailyLog(remoteLog);
      if (!result.isSuccess) {
        _debugWarn(
          'habit log sync failed for local "${localHabitId ?? 'unknown'}": '
          '${_errorMessage(result.error)}',
        );
      }
    } catch (error) {
      _debugWarn('habit log sync unexpected error: $error');
    }
  }

  Future<void> deleteDailyLogForHabit({
    required Map<String, dynamic> localHabit,
    required DateTime date,
    String? expectedLocalUserId,
  }) async {
    try {
      final authenticatedUserId = _currentAuthenticatedUserId();
      if (authenticatedUserId == null) {
        _debugWarn('habit log delete skipped: no authenticated session');
        return;
      }

      if (!_isExpectedUser(authenticatedUserId, expectedLocalUserId)) {
        _debugWarn(
          'habit log delete skipped: local user does not match active auth user',
        );
        return;
      }

      final localHabitId = _localHabitId(localHabit);
      final remoteHabitId = HabitLogRemoteMapper.extractRemoteHabitId(localHabit);
      if (remoteHabitId == null) {
        _debugWarn(
          'habit log delete skipped for local habit "${localHabitId ?? 'unknown'}": '
          'missing persisted remoteId',
        );
        return;
      }

      final result = await _repository.deleteDailyLog(
        habitId: remoteHabitId,
        logDate: date,
      );
      if (!result.isSuccess) {
        _debugWarn(
          'habit log delete failed for local "${localHabitId ?? 'unknown'}": '
          '${_errorMessage(result.error)}',
        );
      }
    } catch (error) {
      _debugWarn('habit log delete unexpected error: $error');
    }
  }

  HabitLogRepository get _repository {
    return _habitLogRepository ??= HabitLogRepository();
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

  String? _localHabitId(Map<String, dynamic> localHabit) {
    final normalized = (localHabit['id'] ??
            localHabit['habitId'] ??
            localHabit['uuid'] ??
            localHabit['key'] ??
            '')
        .toString()
        .trim();
    return normalized.isEmpty ? null : normalized;
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

  void _debugWarn(String message) {
    if (!kDebugMode) return;
    debugPrint('[habit_log_sync] $message');
  }
}
