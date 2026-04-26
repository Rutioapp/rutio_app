import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/rutio_supabase_client.dart';
import '../models/remote/remote_habit.dart';
import 'repository_result.dart';

class HabitRepository {
  HabitRepository({SupabaseClient? client})
      : _client = client ?? RutioSupabaseClient.instance;

  final SupabaseClient _client;

  static const String _habitsTable = 'habits';
  static const String _habitColumns = '''
id,
user_id,
name,
family_id,
emoji,
habit_type,
target_count,
unit,
color_id,
reminder_enabled,
reminder_time,
is_archived,
sort_order,
created_at,
updated_at
''';

  Future<RepositoryResult<List<RemoteHabit>>> fetchHabitsForCurrentUser() async {
    final userId = _currentUserId();
    if (userId == null) {
      return RepositoryResult<List<RemoteHabit>>.failure(_notAuthenticated());
    }

    try {
      final rows = await _client
          .from(_habitsTable)
          .select(_habitColumns)
          .eq('user_id', userId)
          .order('sort_order', ascending: true)
          .order('created_at', ascending: true);

      final habits = rows
          .whereType<Map>()
          .map(
            (row) =>
                RemoteHabit.fromMap(Map<String, dynamic>.from(row.cast<String, dynamic>())),
          )
          .toList(growable: false);

      return RepositoryResult<List<RemoteHabit>>.success(data: habits);
    } on PostgrestException catch (error) {
      return RepositoryResult<List<RemoteHabit>>.failure(
        _mapPostgrestError(
          error,
          fallbackMessage: 'Could not fetch habits.',
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[habit_repository] unexpected fetch error: $error');
      }
      return RepositoryResult<List<RemoteHabit>>.failure(
        RepositoryError(
          code: RepositoryErrorCode.unknown,
          message: 'Could not fetch habits.',
          cause: error,
        ),
      );
    }
  }

  Future<RepositoryResult<RemoteHabit>> upsertHabitForCurrentUser(
    RemoteHabit habit,
  ) async {
    final userId = _currentUserId();
    if (userId == null) {
      return RepositoryResult<RemoteHabit>.failure(_notAuthenticated());
    }

    final payload = Map<String, dynamic>.from(habit.toUpsertMap());
    payload['user_id'] = userId;

    try {
      final row = await _client
          .from(_habitsTable)
          .upsert(payload, onConflict: 'id')
          .select(_habitColumns)
          .single();
      final remoteHabit = RemoteHabit.fromMap(Map<String, dynamic>.from(row));
      final expectedId = habit.id.trim();
      if (remoteHabit.userId != userId ||
          (expectedId.isNotEmpty && remoteHabit.id != expectedId)) {
        return RepositoryResult<RemoteHabit>.failure(
          const RepositoryError(
            code: RepositoryErrorCode.invalidResponse,
            message: 'Habit upsert response did not match current user.',
          ),
        );
      }

      return RepositoryResult<RemoteHabit>.success(
        data: remoteHabit,
      );
    } on PostgrestException catch (error) {
      return RepositoryResult<RemoteHabit>.failure(
        _mapPostgrestError(
          error,
          fallbackMessage: 'Could not upsert habit.',
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[habit_repository] unexpected upsert error: $error');
      }
      return RepositoryResult<RemoteHabit>.failure(
        RepositoryError(
          code: RepositoryErrorCode.unknown,
          message: 'Could not upsert habit.',
          cause: error,
        ),
      );
    }
  }

  Future<RepositoryResult<void>> deleteHabitForCurrentUser({
    required String habitId,
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
          message: 'Habit id is required for delete.',
        ),
      );
    }

    try {
      await _client
          .from(_habitsTable)
          .delete()
          .eq('user_id', userId)
          .eq('id', normalizedHabitId);
      return RepositoryResult<void>.success();
    } on PostgrestException catch (error) {
      return RepositoryResult<void>.failure(
        _mapPostgrestError(
          error,
          fallbackMessage: 'Could not delete habit.',
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[habit_repository] unexpected delete error: $error');
      }
      return RepositoryResult<void>.failure(
        RepositoryError(
          code: RepositoryErrorCode.unknown,
          message: 'Could not delete habit.',
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
        '[habit_repository] postgrest error (${error.code}): ${error.message}',
      );
    }

    final code = (error.code ?? '').trim();

    if (code == 'PGRST116') {
      return RepositoryError(
        code: RepositoryErrorCode.notFound,
        message: 'Habit row was not found.',
        cause: error,
      );
    }
    if (code == '42501') {
      return RepositoryError(
        code: RepositoryErrorCode.permissionDenied,
        message: 'Permission denied for habits operation.',
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
        message: 'Network error while accessing habits.',
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
