import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/rutio_supabase_client.dart';
import '../models/remote/remote_habit.dart';
import 'repository_result.dart';

typedef HabitCurrentUserIdProvider = String? Function();

class HabitRepository {
  HabitRepository({
    SupabaseClient? client,
    HabitCurrentUserIdProvider? currentUserIdProvider,
  })  : _client = client ?? RutioSupabaseClient.instance,
        _currentUserIdProvider = currentUserIdProvider;

  final SupabaseClient _client;
  final HabitCurrentUserIdProvider? _currentUserIdProvider;

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
schedule,
is_archived,
sort_order,
created_at,
updated_at,
source_mutation_id,
effective_from,
effective_timezone_name
''';

  Future<RepositoryResult<List<RemoteHabit>>>
      fetchHabitsForCurrentUser() async {
    final userId = _currentUserId();
    if (userId == null) {
      return const RepositoryResult<List<RemoteHabit>>.success(
        data: <RemoteHabit>[],
      );
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
            (row) => RemoteHabit.fromMap(
                Map<String, dynamic>.from(row.cast<String, dynamic>())),
          )
          .toList(growable: false);

      return RepositoryResult<List<RemoteHabit>>.success(data: habits);
    } on PostgrestException catch (error, stackTrace) {
      return RepositoryResult<List<RemoteHabit>>.failure(
        _mapPostgrestError(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Could not fetch habits.',
        ),
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[habit_repository] unexpected fetch error: $error');
      }
      return RepositoryResult<List<RemoteHabit>>.failure(
        RepositoryError(
          code: RepositoryErrorCode.unknown,
          message: 'Could not fetch habits.',
          cause: error,
          causeStackTrace: stackTrace,
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
    final remoteHabitId = (habit.id ?? '').trim();

    try {
      if (remoteHabitId.isEmpty) {
        return await _insertHabitForCurrentUser(
          payload: payload,
          userId: userId,
        );
      }

      return await _updateOrInsertHabitForCurrentUser(
        payload: payload,
        userId: userId,
        remoteHabitId: remoteHabitId,
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

  /// Creates a habit with a client-owned UUID and resolves an ambiguous
  /// insert by reading only that user's row.
  ///
  /// The method never updates an existing row. A row found after an insert
  /// error is accepted only when its writable fields still match the create
  /// request; otherwise the result is kept unresolved.
  Future<RepositoryResult<RemoteHabit>> createHabitIdempotentlyForCurrentUser(
    RemoteHabit habit,
  ) async {
    final userId = _currentUserId();
    if (userId == null) {
      return RepositoryResult<RemoteHabit>.failure(_notAuthenticated());
    }

    final remoteHabitId = (habit.id ?? '').trim().toLowerCase();
    if (remoteHabitId.isEmpty || !_isUuid(remoteHabitId)) {
      return RepositoryResult<RemoteHabit>.failure(
        const RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: 'A valid client habit UUID is required for creation.',
        ),
      );
    }

    final payload = Map<String, dynamic>.from(habit.toUpsertMap())
      ..['user_id'] = userId
      ..['id'] = remoteHabitId;

    try {
      final row = await _client
          .from(_habitsTable)
          .insert(payload)
          .select(_habitColumns)
          .single();
      return _validateScopedHabit(
        remoteHabit: RemoteHabit.fromMap(Map<String, dynamic>.from(row)),
        userId: userId,
        expectedHabitId: remoteHabitId,
        expectedCreate: habit,
      );
    } catch (error, stackTrace) {
      final verification = await _verifyCreatedHabit(
        habit: habit,
        userId: userId,
        remoteHabitId: remoteHabitId,
      );
      if (verification != null) return verification;

      if (error is PostgrestException) {
        return RepositoryResult<RemoteHabit>.failure(
          _mapPostgrestError(
            error,
            stackTrace: stackTrace,
            fallbackMessage: 'Could not create habit.',
          ),
        );
      }
      return RepositoryResult<RemoteHabit>.failure(
        RepositoryError(
          code: RepositoryErrorCode.network,
          message: 'Could not confirm habit creation.',
          cause: error,
          causeStackTrace: stackTrace,
        ),
      );
    }
  }

  Future<RepositoryResult<RemoteHabit>?> _verifyCreatedHabit({
    required RemoteHabit habit,
    required String userId,
    required String remoteHabitId,
  }) async {
    try {
      final row = await _client
          .from(_habitsTable)
          .select(_habitColumns)
          .eq('user_id', userId)
          .eq('id', remoteHabitId)
          .maybeSingle();
      if (row == null) return null;

      final remoteHabit = RemoteHabit.fromMap(
        Map<String, dynamic>.from((row as Map).cast<String, dynamic>()),
      );
      return _validateScopedHabit(
        remoteHabit: remoteHabit,
        userId: userId,
        expectedHabitId: remoteHabitId,
        expectedCreate: habit,
      );
    } catch (_) {
      // An unavailable verification leaves the operation unresolved. The
      // caller retains the same UUID and may safely try again later.
      return null;
    }
  }

  Future<RepositoryResult<RemoteHabit>> _insertHabitForCurrentUser({
    required Map<String, dynamic> payload,
    required String userId,
  }) async {
    final row = await _client
        .from(_habitsTable)
        .insert(payload)
        .select(_habitColumns)
        .single();

    final remoteHabit = RemoteHabit.fromMap(Map<String, dynamic>.from(row));
    return _validateScopedHabit(
      remoteHabit: remoteHabit,
      userId: userId,
      expectedHabitId: null,
    );
  }

  Future<RepositoryResult<RemoteHabit>> _updateOrInsertHabitForCurrentUser({
    required Map<String, dynamic> payload,
    required String userId,
    required String remoteHabitId,
  }) async {
    final updatePayload = Map<String, dynamic>.from(payload)..remove('id');

    final updatedRows = await _client
        .from(_habitsTable)
        .update(updatePayload)
        .eq('user_id', userId)
        .eq('id', remoteHabitId)
        .select(_habitColumns);

    if (updatedRows.isNotEmpty) {
      final remoteHabit = RemoteHabit.fromMap(
        Map<String, dynamic>.from(updatedRows.first as Map),
      );
      return _validateScopedHabit(
        remoteHabit: remoteHabit,
        userId: userId,
        expectedHabitId: remoteHabitId,
      );
    }

    final row = await _client
        .from(_habitsTable)
        .insert(payload)
        .select(_habitColumns)
        .single();

    final remoteHabit = RemoteHabit.fromMap(Map<String, dynamic>.from(row));
    return _validateScopedHabit(
      remoteHabit: remoteHabit,
      userId: userId,
      expectedHabitId: remoteHabitId,
    );
  }

  RepositoryResult<RemoteHabit> _validateScopedHabit({
    required RemoteHabit remoteHabit,
    required String userId,
    required String? expectedHabitId,
    RemoteHabit? expectedCreate,
  }) {
    final actualHabitId = (remoteHabit.id ?? '').trim();
    final expectedId = (expectedHabitId ?? '').trim();

    if (remoteHabit.userId != userId ||
        actualHabitId.isEmpty ||
        (expectedId.isNotEmpty && actualHabitId != expectedId)) {
      return RepositoryResult<RemoteHabit>.failure(
        const RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: 'Habit upsert response did not match current user.',
        ),
      );
    }

    if (expectedCreate != null &&
        !_matchesCreateRequest(remoteHabit, expectedCreate)) {
      return RepositoryResult<RemoteHabit>.failure(
        const RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: 'Remote habit does not match the create request.',
        ),
      );
    }

    return RepositoryResult<RemoteHabit>.success(data: remoteHabit);
  }

  bool _matchesCreateRequest(RemoteHabit actual, RemoteHabit expected) {
    final actualPayload = actual.toUpsertMap()..remove('id');
    final expectedPayload = expected.toUpsertMap()..remove('id');
    return jsonEncode(actualPayload) == jsonEncode(expectedPayload);
  }

  bool _isUuid(String value) {
    return RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    ).hasMatch(value);
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
      final rows = await _client
          .from(_habitsTable)
          .update(<String, dynamic>{'is_archived': true})
          .eq('user_id', userId)
          .eq('id', normalizedHabitId)
          .select('id,user_id,is_archived');

      if (rows.isNotEmpty) {
        final row = Map<String, dynamic>.from(
          (rows.first as Map).cast<String, dynamic>(),
        );
        if (row['user_id'] != userId || row['is_archived'] != true) {
          return RepositoryResult<void>.failure(
            const RepositoryError(
              code: RepositoryErrorCode.invalidResponse,
              message: 'Archived habit response did not match current user.',
            ),
          );
        }
      }

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
    StackTrace? stackTrace,
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
        causeStackTrace: stackTrace,
      );
    }
    if (code == '42501') {
      return RepositoryError(
        code: RepositoryErrorCode.permissionDenied,
        message: 'Permission denied for habits operation.',
        cause: error,
        causeStackTrace: stackTrace,
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
        causeStackTrace: stackTrace,
      );
    }

    return RepositoryError(
      code: RepositoryErrorCode.unknown,
      message: fallbackMessage,
      cause: error,
      causeStackTrace: stackTrace,
    );
  }
}
