import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/rutio_supabase_client.dart';
import '../models/remote/remote_user_progress.dart';
import 'repository_result.dart';

class UserProgressRepository {
  UserProgressRepository({
    SupabaseClient? client,
    String? Function()? currentUserIdProvider,
  })  : _client = client ?? RutioSupabaseClient.instance,
        _currentUserIdProvider = currentUserIdProvider;

  final SupabaseClient _client;
  final String? Function()? _currentUserIdProvider;

  static const String _userProgressTable = 'user_progress';

  Future<RepositoryResult<RemoteUserProgress?>> fetchCurrentProgress() async {
    final userId = _currentUserId();
    if (userId == null) {
      return RepositoryResult<RemoteUserProgress?>.failure(_notAuthenticated());
    }

    try {
      final row = await _client
          .from(_userProgressTable)
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (row == null) {
        return const RepositoryResult<RemoteUserProgress?>.success(data: null);
      }

      final progress =
          RemoteUserProgress.fromMap(Map<String, dynamic>.from(row));
      if (progress.userId != userId) {
        return RepositoryResult<RemoteUserProgress?>.failure(
          const RepositoryError(
            code: RepositoryErrorCode.invalidResponse,
            message: 'Fetched user progress did not match current user.',
          ),
        );
      }
      return RepositoryResult<RemoteUserProgress?>.success(data: progress);
    } on PostgrestException catch (error) {
      return RepositoryResult<RemoteUserProgress?>.failure(
        _mapPostgrestError(
          error,
          fallbackMessage: 'Could not fetch user progress.',
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[user_progress_repository] unexpected fetch error: $error');
      }
      return RepositoryResult<RemoteUserProgress?>.failure(
        RepositoryError(
          code: RepositoryErrorCode.unknown,
          message: 'Could not fetch user progress.',
          cause: error,
        ),
      );
    }
  }

  Future<RepositoryResult<RemoteUserProgress>> upsertCurrentProgress(
    RemoteUserProgress progress,
  ) async {
    return _clientWriteDisabled();
  }

  Future<RepositoryResult<RemoteUserProgress>> touchProgressFromLocalState({
    required int level,
    required int totalXp,
    required int currentLevelXp,
    required int nextLevelXp,
    required int ambarBalance,
    int ambarEarnedDelta = 0,
    int ambarSpentDelta = 0,
  }) async {
    return _clientWriteDisabled();
  }

  RepositoryResult<RemoteUserProgress> _clientWriteDisabled() {
    if (kDebugMode) {
      debugPrint(
        '[user_progress_repository] client progress writes are disabled; '
        'authoritative RPCs refresh the projection',
      );
    }
    return const RepositoryResult<RemoteUserProgress>.failure(
      RepositoryError(
        code: RepositoryErrorCode.permissionDenied,
        message: 'User progress is server-owned and read-only for clients.',
      ),
    );
  }

  String? _currentUserId() {
    if (_currentUserIdProvider != null) {
      final userId = _currentUserIdProvider!()?.trim();
      if (userId == null || userId.isEmpty) return null;
      return userId;
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
  }) {
    if (kDebugMode) {
      debugPrint(
        '[user_progress_repository] postgrest error (${error.code}): ${error.message}',
      );
    }

    final code = (error.code ?? '').trim();
    if (code == 'PGRST116') {
      return RepositoryError(
        code: RepositoryErrorCode.notFound,
        message: 'User progress row was not found.',
        cause: error,
      );
    }
    if (code == '42501') {
      return RepositoryError(
        code: RepositoryErrorCode.permissionDenied,
        message: 'Permission denied for user progress operation.',
        cause: error,
      );
    }
    if (code == '42703' || code == 'PGRST204') {
      return RepositoryError(
        code: RepositoryErrorCode.invalidResponse,
        message:
            'User progress schema is missing one or more expected columns.',
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
        message: 'Network error while accessing user progress.',
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
