import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/rutio_supabase_client.dart';
import '../models/remote/remote_user_progress.dart';
import 'repository_result.dart';

class UserProgressRepository {
  UserProgressRepository({SupabaseClient? client})
      : _client = client ?? RutioSupabaseClient.instance;

  final SupabaseClient _client;

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

      final progress = RemoteUserProgress.fromMap(Map<String, dynamic>.from(row));
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
    final userId = _currentUserId();
    if (userId == null) {
      return RepositoryResult<RemoteUserProgress>.failure(_notAuthenticated());
    }

    final payload = Map<String, dynamic>.from(progress.toUpsertMap())
      ..['user_id'] = userId;

    if (kDebugMode) {
      debugPrint(
        '[user_progress_repository] upsert payload: ${_debugSafePayload(payload)}',
      );
    }

    try {
      await _client.from(_userProgressTable).upsert(payload, onConflict: 'user_id');

      if (kDebugMode) {
        debugPrint('[user_progress_repository] upsert success');
      }

      final fetched = await fetchCurrentProgress();
      if (fetched.isSuccess && fetched.data != null) {
        return RepositoryResult<RemoteUserProgress>.success(data: fetched.data!);
      }

      return RepositoryResult<RemoteUserProgress>.success(
        data: RemoteUserProgress(
          userId: userId,
          level: _safeInt(payload['level'], fallback: 1),
          totalXp: _safeInt(payload['total_xp'], fallback: 0),
          currentLevelXp: _safeInt(payload['current_level_xp'], fallback: 0),
          nextLevelXp: _safeInt(payload['next_level_xp'], fallback: 100),
          ambarBalance: _safeInt(payload['ambar_balance'], fallback: 0),
          totalAmbarEarned: _safeInt(payload['total_ambar_earned'], fallback: 0),
          totalAmbarSpent: _safeInt(payload['total_ambar_spent'], fallback: 0),
          raw: payload,
        ),
      );
    } on PostgrestException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[user_progress_repository] upsert failure: ${error.code} ${error.message}',
        );
      }
      return RepositoryResult<RemoteUserProgress>.failure(
        _mapPostgrestError(
          error,
          fallbackMessage: 'Could not upsert user progress.',
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[user_progress_repository] unexpected upsert error: $error');
      }
      return RepositoryResult<RemoteUserProgress>.failure(
        RepositoryError(
          code: RepositoryErrorCode.unknown,
          message: 'Could not upsert user progress.',
          cause: error,
        ),
      );
    }
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
    final userId = _currentUserId();
    if (userId == null) {
      return RepositoryResult<RemoteUserProgress>.failure(_notAuthenticated());
    }

    final safeLevel = level < 1 ? 1 : level;
    final safeTotalXp = totalXp < 0 ? 0 : totalXp;
    final safeCurrentLevelXp = currentLevelXp < 0 ? 0 : currentLevelXp;
    final safeNextLevelXp = nextLevelXp < 1 ? 1 : nextLevelXp;
    final safeAmbarBalance = ambarBalance < 0 ? 0 : ambarBalance;
    final safeEarnedDelta = ambarEarnedDelta < 0 ? 0 : ambarEarnedDelta;
    final safeSpentDelta = ambarSpentDelta < 0 ? 0 : ambarSpentDelta;

    var nextTotalAmbarEarned = safeEarnedDelta;
    var nextTotalAmbarSpent = safeSpentDelta;

    final existing = await fetchCurrentProgress();
    if (existing.isSuccess && existing.data != null) {
      final currentEarned = existing.data!.totalAmbarEarned;
      final currentSpent = existing.data!.totalAmbarSpent;
      nextTotalAmbarEarned =
          (currentEarned < 0 ? 0 : currentEarned) + safeEarnedDelta;
      nextTotalAmbarSpent = (currentSpent < 0 ? 0 : currentSpent) + safeSpentDelta;
    } else if (!existing.isSuccess && kDebugMode) {
      debugPrint(
        '[user_progress_repository] existing progress unavailable; using safe deltas',
      );
    }

    return upsertCurrentProgress(
      RemoteUserProgress(
        userId: userId,
        level: safeLevel,
        totalXp: safeTotalXp,
        currentLevelXp: safeCurrentLevelXp,
        nextLevelXp: safeNextLevelXp,
        ambarBalance: safeAmbarBalance,
        totalAmbarEarned: nextTotalAmbarEarned,
        totalAmbarSpent: nextTotalAmbarSpent,
      ),
    );
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

  Map<String, dynamic> _debugSafePayload(Map<String, dynamic> payload) {
    final redacted = Map<String, dynamic>.from(payload);
    redacted.remove('user_id');
    return redacted;
  }

  int _safeInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString().trim()) ?? fallback;
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
        message: 'User progress schema is missing one or more expected columns.',
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
