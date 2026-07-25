import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/rutio_supabase_client.dart';
import '../../../../data/repositories/repository_result.dart';
import 'streak_protection_remote_models.dart';

abstract class StreakProtectionRepository {
  Future<RepositoryResult<void>> setHabitTimeZone(String timeZone);

  Future<RepositoryResult<ActivateStreakShieldRemoteResult>>
      activateStreakShield({
    required String requestId,
    required String habitId,
    required String protectedOccurrenceDate,
    required String operationId,
    required String utilityId,
  });

  Future<RepositoryResult<CloseMissedHabitOccurrenceRemoteResult>>
      closeMissedHabitOccurrence({
    required String requestId,
    required String habitId,
    required String logicalDate,
    required String breakId,
  });

  Future<RepositoryResult<RecoverStreakBreakRemoteResult>> recoverStreakBreak({
    required String requestId,
    required String breakId,
    required String utilityId,
  });

  Future<RepositoryResult<List<HabitStreakShieldRemote>>>
      fetchShieldsForCurrentUser();

  Future<RepositoryResult<List<HabitStreakBreakRemote>>>
      fetchBreaksForCurrentUser();

  Future<RepositoryResult<List<HabitStreakShieldRemote>>>
      fetchArmedShieldsForCurrentUser();

  Future<RepositoryResult<List<HabitStreakBreakRemote>>>
      fetchRecoverableBreaksForCurrentUser();
}

@visibleForTesting
Map<String, dynamic> buildCloseMissedHabitOccurrenceRpcParams({
  required String requestId,
  required String habitId,
  required String logicalDate,
  required String breakId,
}) {
  return <String, dynamic>{
    'p_request_id': requestId.trim(),
    'p_habit_id': habitId.trim(),
    'p_logical_date': logicalDate.trim(),
    'p_break_id': breakId.trim(),
  };
}

class SupabaseStreakProtectionRepository implements StreakProtectionRepository {
  SupabaseStreakProtectionRepository({SupabaseClient? client})
      : _client = client ?? RutioSupabaseClient.instance;

  final SupabaseClient _client;

  static const String _shieldColumns = '''
id,
request_id,
operation_id,
habit_id,
utility_id,
effect_id,
logical_time_zone,
protected_occurrence_date,
status,
activated_at,
consumed_at
''';

  static const String _breakColumns = '''
id,
request_id,
recovery_request_id,
break_id,
habit_id,
logical_time_zone,
missed_occurrence_date,
previous_streak,
current_streak_after_break,
status,
broken_at,
recoverable_until,
recovered_at
''';

  @override
  Future<RepositoryResult<void>> setHabitTimeZone(String timeZone) async {
    final normalized = timeZone.trim();
    if (normalized.isEmpty) {
      return RepositoryResult<void>.failure(
        const RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: 'Habit time zone is required.',
        ),
      );
    }
    if (_client.auth.currentUser == null) {
      return RepositoryResult<void>.failure(_notAuthenticated());
    }

    try {
      await _client.rpc(
        'set_habit_time_zone',
        params: <String, dynamic>{'p_time_zone': normalized},
      );
      return const RepositoryResult<void>.success();
    } on PostgrestException catch (error) {
      return RepositoryResult<void>.failure(
        _mapPostgrestError(
          error,
          fallbackMessage: 'Could not update habit time zone.',
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[streak_protection_repository] unexpected timezone error: $error',
        );
      }
      return RepositoryResult<void>.failure(
        RepositoryError(
          code: RepositoryErrorCode.unknown,
          message: 'Could not update habit time zone.',
          cause: error,
        ),
      );
    }
  }

  @override
  Future<RepositoryResult<ActivateStreakShieldRemoteResult>>
      activateStreakShield({
    required String requestId,
    required String habitId,
    required String protectedOccurrenceDate,
    required String operationId,
    required String utilityId,
  }) async {
    if (_client.auth.currentUser == null) {
      return RepositoryResult<ActivateStreakShieldRemoteResult>.failure(
        _notAuthenticated(),
      );
    }

    return _rpcResult<ActivateStreakShieldRemoteResult>(
      rpcName: 'activate_streak_shield',
      params: <String, dynamic>{
        'p_request_id': requestId.trim(),
        'p_habit_id': habitId.trim(),
        'p_protected_occurrence_date': protectedOccurrenceDate.trim(),
        'p_operation_id': operationId.trim(),
        'p_utility_id': utilityId.trim(),
      },
      parser: ActivateStreakShieldRemoteResult.fromMap,
      fallbackMessage: 'Could not activate streak shield.',
    );
  }

  @override
  Future<RepositoryResult<CloseMissedHabitOccurrenceRemoteResult>>
      closeMissedHabitOccurrence({
    required String requestId,
    required String habitId,
    required String logicalDate,
    required String breakId,
  }) async {
    if (_client.auth.currentUser == null) {
      return RepositoryResult<CloseMissedHabitOccurrenceRemoteResult>.failure(
        _notAuthenticated(),
      );
    }

    return _rpcResult<CloseMissedHabitOccurrenceRemoteResult>(
      rpcName: 'close_missed_habit_occurrence',
      params: buildCloseMissedHabitOccurrenceRpcParams(
        requestId: requestId,
        habitId: habitId,
        logicalDate: logicalDate,
        breakId: breakId,
      ),
      parser: CloseMissedHabitOccurrenceRemoteResult.fromMap,
      fallbackMessage: 'Could not close missed habit occurrence.',
    );
  }

  @override
  Future<RepositoryResult<RecoverStreakBreakRemoteResult>> recoverStreakBreak({
    required String requestId,
    required String breakId,
    required String utilityId,
  }) async {
    if (_client.auth.currentUser == null) {
      return RepositoryResult<RecoverStreakBreakRemoteResult>.failure(
        _notAuthenticated(),
      );
    }

    return _rpcResult<RecoverStreakBreakRemoteResult>(
      rpcName: 'recover_streak_break',
      params: <String, dynamic>{
        'p_request_id': requestId.trim(),
        'p_break_id': breakId.trim(),
        'p_utility_id': utilityId.trim(),
      },
      parser: RecoverStreakBreakRemoteResult.fromMap,
      fallbackMessage: 'Could not recover streak break.',
    );
  }

  @override
  Future<RepositoryResult<List<HabitStreakShieldRemote>>>
      fetchShieldsForCurrentUser() {
    return _fetchShields(status: null);
  }

  @override
  Future<RepositoryResult<List<HabitStreakShieldRemote>>>
      fetchArmedShieldsForCurrentUser() {
    return _fetchShields(status: 'armed');
  }

  @override
  Future<RepositoryResult<List<HabitStreakBreakRemote>>>
      fetchBreaksForCurrentUser() {
    return _fetchBreaks(status: null);
  }

  @override
  Future<RepositoryResult<List<HabitStreakBreakRemote>>>
      fetchRecoverableBreaksForCurrentUser() {
    return _fetchBreaks(status: 'recoverable');
  }

  Future<RepositoryResult<List<HabitStreakShieldRemote>>> _fetchShields({
    required String? status,
  }) async {
    if (_client.auth.currentUser == null) {
      return const RepositoryResult<List<HabitStreakShieldRemote>>.success(
        data: <HabitStreakShieldRemote>[],
      );
    }

    try {
      var query = _client.from('habit_streak_shields').select(_shieldColumns);
      if (status != null) {
        query = query.eq('status', status);
      }
      final rows = await query.order('activated_at', ascending: false);
      final shields = rows
          .whereType<Map>()
          .map((row) => HabitStreakShieldRemote.fromMap(
                Map<String, dynamic>.from(row.cast<String, dynamic>()),
              ))
          .toList(growable: false);
      return RepositoryResult<List<HabitStreakShieldRemote>>.success(
        data: shields,
      );
    } on RemoteStreakProtectionParseException catch (error) {
      return RepositoryResult<List<HabitStreakShieldRemote>>.failure(
        RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: error.message,
          cause: error,
        ),
      );
    } on PostgrestException catch (error) {
      return RepositoryResult<List<HabitStreakShieldRemote>>.failure(
        _mapPostgrestError(
          error,
          fallbackMessage: 'Could not fetch streak shields.',
        ),
      );
    } catch (error) {
      return RepositoryResult<List<HabitStreakShieldRemote>>.failure(
        RepositoryError(
          code: RepositoryErrorCode.unknown,
          message: 'Could not fetch streak shields.',
          cause: error,
        ),
      );
    }
  }

  Future<RepositoryResult<List<HabitStreakBreakRemote>>> _fetchBreaks({
    required String? status,
  }) async {
    if (_client.auth.currentUser == null) {
      return const RepositoryResult<List<HabitStreakBreakRemote>>.success(
        data: <HabitStreakBreakRemote>[],
      );
    }

    try {
      var query = _client.from('habit_streak_breaks').select(_breakColumns);
      if (status != null) {
        query = query.eq('status', status);
      }
      final rows = await query.order('broken_at', ascending: false);
      final breaks = rows
          .whereType<Map>()
          .map((row) => HabitStreakBreakRemote.fromMap(
                Map<String, dynamic>.from(row.cast<String, dynamic>()),
              ))
          .toList(growable: false);
      return RepositoryResult<List<HabitStreakBreakRemote>>.success(
        data: breaks,
      );
    } on RemoteStreakProtectionParseException catch (error) {
      return RepositoryResult<List<HabitStreakBreakRemote>>.failure(
        RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: error.message,
          cause: error,
        ),
      );
    } on PostgrestException catch (error) {
      return RepositoryResult<List<HabitStreakBreakRemote>>.failure(
        _mapPostgrestError(
          error,
          fallbackMessage: 'Could not fetch streak breaks.',
        ),
      );
    } catch (error) {
      return RepositoryResult<List<HabitStreakBreakRemote>>.failure(
        RepositoryError(
          code: RepositoryErrorCode.unknown,
          message: 'Could not fetch streak breaks.',
          cause: error,
        ),
      );
    }
  }

  Future<RepositoryResult<T>> _rpcResult<T>({
    required String rpcName,
    required Map<String, dynamic> params,
    required T Function(Map<String, dynamic>) parser,
    required String fallbackMessage,
  }) async {
    try {
      final response = await _client.rpc(rpcName, params: params);
      final map = _responseMap(response);
      return RepositoryResult<T>.success(data: parser(map));
    } on RemoteStreakProtectionParseException catch (error) {
      return RepositoryResult<T>.failure(
        RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: error.message,
          cause: error,
        ),
      );
    } on PostgrestException catch (error) {
      return RepositoryResult<T>.failure(
        _mapPostgrestError(error, fallbackMessage: fallbackMessage),
      );
    } catch (error) {
      return RepositoryResult<T>.failure(
        RepositoryError(
          code: RepositoryErrorCode.unknown,
          message: fallbackMessage,
          cause: error,
        ),
      );
    }
  }

  Map<String, dynamic> _responseMap(Object? response) {
    if (response is Map) {
      return Map<String, dynamic>.from(response.cast<String, dynamic>());
    }
    throw const RemoteStreakProtectionParseException(
      'RPC returned an invalid streak protection response.',
    );
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
        '[streak_protection_repository] postgrest error '
        '(${error.code}): ${error.message}',
      );
    }

    final code = (error.code ?? '').trim();
    if (code == '42501') {
      return RepositoryError(
        code: RepositoryErrorCode.permissionDenied,
        message: 'Permission denied for streak protection operation.',
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
        message: 'Network error while accessing streak protection data.',
        cause: error,
      );
    }

    return RepositoryError(
      code: RepositoryErrorCode.unknown,
      message: fallbackMessage,
      cause: error,
    );
  }
}
