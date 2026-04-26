import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/rutio_supabase_client.dart';
import '../models/remote/remote_habit_log.dart';
import 'repository_result.dart';

class HabitLogRepository {
  HabitLogRepository({SupabaseClient? client})
      : _client = client ?? RutioSupabaseClient.instance;

  final SupabaseClient _client;

  static const String _habitLogsTable = 'habit_logs';
  static const String _habitLogColumns = '''
id,
user_id,
habit_id,
log_date,
value,
is_completed,
note,
source,
created_at,
updated_at
''';

  Future<RepositoryResult<List<RemoteHabitLog>>> fetchLogsForDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final userId = _currentUserId();
    if (userId == null) {
      return RepositoryResult<List<RemoteHabitLog>>.failure(_notAuthenticated());
    }

    final startKey = _dateOnlyIso(start);
    final endKey = _dateOnlyIso(end);

    try {
      final rows = await _client
          .from(_habitLogsTable)
          .select(_habitLogColumns)
          .eq('user_id', userId)
          .gte('log_date', startKey)
          .lte('log_date', endKey)
          .order('log_date', ascending: true)
          .order('created_at', ascending: true);

      final logs = rows
          .whereType<Map>()
          .map(
            (row) => RemoteHabitLog.fromMap(
              Map<String, dynamic>.from(row.cast<String, dynamic>()),
            ),
          )
          .toList(growable: false);

      return RepositoryResult<List<RemoteHabitLog>>.success(data: logs);
    } on PostgrestException catch (error) {
      return RepositoryResult<List<RemoteHabitLog>>.failure(
        _mapPostgrestError(
          error,
          fallbackMessage: 'Could not fetch habit logs.',
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[habit_log_repository] unexpected fetch-range error: $error');
      }
      return RepositoryResult<List<RemoteHabitLog>>.failure(
        RepositoryError(
          code: RepositoryErrorCode.unknown,
          message: 'Could not fetch habit logs.',
          cause: error,
        ),
      );
    }
  }

  Future<RepositoryResult<List<RemoteHabitLog>>> fetchLogsForHabit(
    String habitId, {
    DateTime? start,
    DateTime? end,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return RepositoryResult<List<RemoteHabitLog>>.failure(_notAuthenticated());
    }

    final normalizedHabitId = habitId.trim();
    if (normalizedHabitId.isEmpty) {
      return RepositoryResult<List<RemoteHabitLog>>.failure(
        const RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: 'Habit id is required to fetch habit logs.',
        ),
      );
    }

    try {
      var query = _client
          .from(_habitLogsTable)
          .select(_habitLogColumns)
          .eq('user_id', userId)
          .eq('habit_id', normalizedHabitId);

      if (start != null) {
        query = query.gte('log_date', _dateOnlyIso(start));
      }
      if (end != null) {
        query = query.lte('log_date', _dateOnlyIso(end));
      }

      final rows = await query
          .order('log_date', ascending: true)
          .order('created_at', ascending: true);

      final logs = rows
          .whereType<Map>()
          .map(
            (row) => RemoteHabitLog.fromMap(
              Map<String, dynamic>.from(row.cast<String, dynamic>()),
            ),
          )
          .toList(growable: false);

      return RepositoryResult<List<RemoteHabitLog>>.success(data: logs);
    } on PostgrestException catch (error) {
      return RepositoryResult<List<RemoteHabitLog>>.failure(
        _mapPostgrestError(
          error,
          fallbackMessage: 'Could not fetch habit logs for habit.',
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[habit_log_repository] unexpected fetch-habit error: $error');
      }
      return RepositoryResult<List<RemoteHabitLog>>.failure(
        RepositoryError(
          code: RepositoryErrorCode.unknown,
          message: 'Could not fetch habit logs for habit.',
          cause: error,
        ),
      );
    }
  }

  Future<RepositoryResult<RemoteHabitLog>> upsertDailyLog(
    RemoteHabitLog log,
  ) async {
    final userId = _currentUserId();
    if (userId == null) {
      return RepositoryResult<RemoteHabitLog>.failure(_notAuthenticated());
    }

    final normalizedHabitId = log.habitId.trim();
    if (normalizedHabitId.isEmpty) {
      return RepositoryResult<RemoteHabitLog>.failure(
        const RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: 'Habit id is required to upsert a daily log.',
        ),
      );
    }

    final payload = Map<String, dynamic>.from(log.toUpsertMap());
    payload['user_id'] = userId;
    payload['habit_id'] = normalizedHabitId;

    try {
      final row = await _client
          .from(_habitLogsTable)
          .upsert(payload, onConflict: 'user_id,habit_id,log_date')
          .select(_habitLogColumns)
          .single();

      final remoteLog = RemoteHabitLog.fromMap(Map<String, dynamic>.from(row));
      if (remoteLog.userId != userId ||
          remoteLog.habitId != normalizedHabitId ||
          _dateOnlyIso(remoteLog.logDate) != _dateOnlyIso(log.logDate)) {
        return RepositoryResult<RemoteHabitLog>.failure(
          const RepositoryError(
            code: RepositoryErrorCode.invalidResponse,
            message: 'Habit log upsert response did not match requested log.',
          ),
        );
      }

      return RepositoryResult<RemoteHabitLog>.success(data: remoteLog);
    } on PostgrestException catch (error) {
      return RepositoryResult<RemoteHabitLog>.failure(
        _mapPostgrestError(
          error,
          fallbackMessage: 'Could not upsert habit log.',
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[habit_log_repository] unexpected upsert error: $error');
      }
      return RepositoryResult<RemoteHabitLog>.failure(
        RepositoryError(
          code: RepositoryErrorCode.unknown,
          message: 'Could not upsert habit log.',
          cause: error,
        ),
      );
    }
  }

  Future<RepositoryResult<void>> deleteDailyLog({
    required String habitId,
    required DateTime logDate,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return RepositoryResult<void>.failure(_notAuthenticated());
    }

    final normalizedHabitId = habitId.trim();
    if (normalizedHabitId.isEmpty) {
      return RepositoryResult<void>.failure(
        const RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: 'Habit id is required to delete a daily log.',
        ),
      );
    }

    try {
      await _client
          .from(_habitLogsTable)
          .delete()
          .eq('user_id', userId)
          .eq('habit_id', normalizedHabitId)
          .eq('log_date', _dateOnlyIso(logDate));
      return const RepositoryResult<void>.success();
    } on PostgrestException catch (error) {
      return RepositoryResult<void>.failure(
        _mapPostgrestError(
          error,
          fallbackMessage: 'Could not delete habit log.',
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[habit_log_repository] unexpected delete error: $error');
      }
      return RepositoryResult<void>.failure(
        RepositoryError(
          code: RepositoryErrorCode.unknown,
          message: 'Could not delete habit log.',
          cause: error,
        ),
      );
    }
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
        '[habit_log_repository] postgrest error (${error.code}): ${error.message}',
      );
    }

    final code = (error.code ?? '').trim();

    if (code == 'PGRST116') {
      return RepositoryError(
        code: RepositoryErrorCode.notFound,
        message: 'Habit log row was not found.',
        cause: error,
      );
    }
    if (code == '42501') {
      return RepositoryError(
        code: RepositoryErrorCode.permissionDenied,
        message: 'Permission denied for habit log operation.',
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
        message: 'Network error while accessing habit logs.',
        cause: error,
      );
    }

    return RepositoryError(
      code: RepositoryErrorCode.unknown,
      message: fallbackMessage,
      cause: error,
    );
  }

  String _dateOnlyIso(DateTime date) {
    final utc = DateTime.utc(date.year, date.month, date.day);
    final month = utc.month.toString().padLeft(2, '0');
    final day = utc.day.toString().padLeft(2, '0');
    return '${utc.year}-$month-$day';
  }
}
