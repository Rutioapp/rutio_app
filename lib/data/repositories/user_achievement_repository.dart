import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/rutio_supabase_client.dart';
import '../models/remote/remote_user_achievement.dart';
import 'repository_result.dart';

class UserAchievementRepository {
  UserAchievementRepository({SupabaseClient? client})
      : _client = client ?? RutioSupabaseClient.instance;

  final SupabaseClient _client;

  static const String _userAchievementsTable = 'user_achievements';
  static const String _userAchievementColumns = '''
id,
user_id,
achievement_id,
family_id,
tier,
unlocked_at,
reward_xp,
reward_ambar,
reward_applied,
created_at,
updated_at
''';

  Future<RepositoryResult<List<RemoteUserAchievement>>>
      fetchCurrentUserAchievements() async {
    final userId = _currentUserId();
    if (userId == null) {
      return RepositoryResult<List<RemoteUserAchievement>>.failure(
        _notAuthenticated(),
      );
    }

    try {
      final rows = await _client
          .from(_userAchievementsTable)
          .select(_userAchievementColumns)
          .eq('user_id', userId)
          .order('unlocked_at', ascending: false)
          .order('created_at', ascending: false);

      final achievements = rows
          .whereType<Map>()
          .map(
            (row) => RemoteUserAchievement.fromMap(
              Map<String, dynamic>.from(row.cast<String, dynamic>()),
            ),
          )
          .toList(growable: false);

      return RepositoryResult<List<RemoteUserAchievement>>.success(
        data: achievements,
      );
    } on PostgrestException catch (error) {
      return RepositoryResult<List<RemoteUserAchievement>>.failure(
        _mapPostgrestError(
          error,
          fallbackMessage: 'Could not fetch user achievements.',
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[user_achievement_repository] unexpected fetch error: $error',
        );
      }
      return RepositoryResult<List<RemoteUserAchievement>>.failure(
        RepositoryError(
          code: RepositoryErrorCode.unknown,
          message: 'Could not fetch user achievements.',
          cause: error,
        ),
      );
    }
  }

  Future<RepositoryResult<RemoteUserAchievement>> upsertUnlockedAchievement({
    required String achievementId,
    String? familyId,
    required String tier,
    required DateTime unlockedAt,
    required int rewardXp,
    required int rewardAmbar,
    required bool rewardApplied,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return RepositoryResult<RemoteUserAchievement>.failure(
        _notAuthenticated(),
      );
    }

    final normalizedAchievementId = achievementId.trim();
    if (normalizedAchievementId.isEmpty) {
      return RepositoryResult<RemoteUserAchievement>.failure(
        const RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: 'Achievement id is required.',
        ),
      );
    }

    final payload = RemoteUserAchievement(
      userId: userId,
      achievementId: normalizedAchievementId,
      familyId: _nullableTrim(familyId),
      tier: tier.trim(),
      unlockedAt: unlockedAt,
      rewardXp: rewardXp < 0 ? 0 : rewardXp,
      rewardAmbar: rewardAmbar < 0 ? 0 : rewardAmbar,
      rewardApplied: rewardApplied,
    ).toUpsertMap()
      ..['user_id'] = userId;
    payload.remove('id');

    if (kDebugMode) {
      debugPrint(
        '[user_achievement_repository] upsert payload: ${_debugSafePayload(payload)}',
      );
    }

    try {
      final row = await _client
          .from(_userAchievementsTable)
          .upsert(payload, onConflict: 'user_id,achievement_id')
          .select(_userAchievementColumns)
          .single();

      final remoteAchievement = RemoteUserAchievement.fromMap(
        Map<String, dynamic>.from(row),
      );

      if (remoteAchievement.userId != userId ||
          remoteAchievement.achievementId != normalizedAchievementId) {
        return RepositoryResult<RemoteUserAchievement>.failure(
          const RepositoryError(
            code: RepositoryErrorCode.invalidResponse,
            message:
                'Achievement upsert response did not match current user scope.',
          ),
        );
      }

      if (kDebugMode) {
        debugPrint(
          '[user_achievement_repository] upsert success: '
          'achievementId="$normalizedAchievementId", '
          'tier="${remoteAchievement.tier}", '
          'familyId="${remoteAchievement.familyId ?? 'null'}"',
        );
      }
      return RepositoryResult<RemoteUserAchievement>.success(
        data: remoteAchievement,
      );
    } on PostgrestException catch (error) {
      if ((error.code ?? '').trim() == '42P10') {
        if (kDebugMode) {
          debugPrint(
            '[user_achievement_repository] upsert onConflict fallback (42P10): ${_postgrestDebugMessage(error)}',
          );
        }
        try {
          final fallback = await _updateThenInsertAchievementForCurrentUser(
            payload: payload,
            userId: userId,
            achievementId: normalizedAchievementId,
          );
          if (fallback.isSuccess) return fallback;
        } on PostgrestException catch (fallbackError) {
          if (kDebugMode) {
            debugPrint(
              '[user_achievement_repository] fallback update/insert failed: ${_postgrestDebugMessage(fallbackError)}',
            );
          }
          return RepositoryResult<RemoteUserAchievement>.failure(
            _mapPostgrestError(
              fallbackError,
              fallbackMessage:
                  'Could not upsert user achievement (fallback failed).',
            ),
          );
        } catch (fallbackError) {
          if (kDebugMode) {
            debugPrint(
              '[user_achievement_repository] fallback update/insert unexpected error: $fallbackError',
            );
          }
          return RepositoryResult<RemoteUserAchievement>.failure(
            RepositoryError(
              code: RepositoryErrorCode.unknown,
              message: 'Could not upsert user achievement (fallback failed).',
              cause: fallbackError,
            ),
          );
        }
      }

      if (kDebugMode) {
        debugPrint(
          '[user_achievement_repository] upsert failed: ${_postgrestDebugMessage(error)}',
        );
      }
      return RepositoryResult<RemoteUserAchievement>.failure(
        _mapPostgrestError(
          error,
          fallbackMessage: 'Could not upsert user achievement.',
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[user_achievement_repository] unexpected upsert error: $error',
        );
      }
      return RepositoryResult<RemoteUserAchievement>.failure(
        RepositoryError(
          code: RepositoryErrorCode.unknown,
          message: 'Could not upsert user achievement.',
          cause: error,
        ),
      );
    }
  }

  Future<RepositoryResult<List<RemoteUserAchievement>>>
      upsertUnlockedAchievements(
    List<RemoteUserAchievement> achievements,
  ) async {
    final userId = _currentUserId();
    if (userId == null) {
      return RepositoryResult<List<RemoteUserAchievement>>.failure(
        _notAuthenticated(),
      );
    }

    final payload = <Map<String, dynamic>>[];
    for (final achievement in achievements) {
      final normalizedAchievementId = achievement.achievementId.trim();
      if (normalizedAchievementId.isEmpty) continue;

      payload.add(
        Map<String, dynamic>.from(achievement.toUpsertMap())
          ..['achievement_id'] = normalizedAchievementId
          ..['user_id'] = userId,
      );
      payload.last.remove('id');
    }

    if (payload.isEmpty) {
      return const RepositoryResult<List<RemoteUserAchievement>>.success(
        data: <RemoteUserAchievement>[],
      );
    }

    try {
      final rows = await _client
          .from(_userAchievementsTable)
          .upsert(payload, onConflict: 'user_id,achievement_id')
          .select(_userAchievementColumns);

      final remoteAchievements = rows
          .whereType<Map>()
          .map(
            (row) => RemoteUserAchievement.fromMap(
              Map<String, dynamic>.from(row.cast<String, dynamic>()),
            ),
          )
          .toList(growable: false);

      for (final achievement in remoteAchievements) {
        if (achievement.userId != userId || achievement.achievementId.isEmpty) {
          return RepositoryResult<List<RemoteUserAchievement>>.failure(
            const RepositoryError(
              code: RepositoryErrorCode.invalidResponse,
              message:
                  'One or more achievement upsert responses were out of scope.',
            ),
          );
        }
      }

      return RepositoryResult<List<RemoteUserAchievement>>.success(
        data: remoteAchievements,
      );
    } on PostgrestException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[user_achievement_repository] batch upsert failed: '
          '${_postgrestDebugMessage(error)}',
        );
      }
      return RepositoryResult<List<RemoteUserAchievement>>.failure(
        _mapPostgrestError(
          error,
          fallbackMessage: 'Could not upsert user achievements.',
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[user_achievement_repository] unexpected batch upsert error: $error',
        );
      }
      return RepositoryResult<List<RemoteUserAchievement>>.failure(
        RepositoryError(
          code: RepositoryErrorCode.unknown,
          message: 'Could not upsert user achievements.',
          cause: error,
        ),
      );
    }
  }

  Future<RepositoryResult<bool>> hasUnlockedAchievement(
    String achievementId,
  ) async {
    final userId = _currentUserId();
    if (userId == null) {
      return RepositoryResult<bool>.failure(_notAuthenticated());
    }

    final normalizedAchievementId = achievementId.trim();
    if (normalizedAchievementId.isEmpty) {
      return const RepositoryResult<bool>.success(data: false);
    }

    try {
      final row = await _client
          .from(_userAchievementsTable)
          .select('achievement_id')
          .eq('user_id', userId)
          .eq('achievement_id', normalizedAchievementId)
          .maybeSingle();

      return RepositoryResult<bool>.success(data: row != null);
    } on PostgrestException catch (error) {
      return RepositoryResult<bool>.failure(
        _mapPostgrestError(
          error,
          fallbackMessage: 'Could not check user achievement state.',
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[user_achievement_repository] unexpected has-check error: $error',
        );
      }
      return RepositoryResult<bool>.failure(
        RepositoryError(
          code: RepositoryErrorCode.unknown,
          message: 'Could not check user achievement state.',
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
        '[user_achievement_repository] postgrest error: ${_postgrestDebugMessage(error)}',
      );
    }

    final code = (error.code ?? '').trim();
    if (code == 'PGRST116') {
      return RepositoryError(
        code: RepositoryErrorCode.notFound,
        message: 'User achievement row was not found.',
        cause: error,
      );
    }
    if (code == '42501') {
      return RepositoryError(
        code: RepositoryErrorCode.permissionDenied,
        message: 'Permission denied for user achievement operation.',
        cause: error,
      );
    }
    if (code == '42P01' || code == '42703' || code == 'PGRST204') {
      return RepositoryError(
        code: RepositoryErrorCode.invalidResponse,
        message: 'User achievements schema/table is missing expected structure.',
        cause: error,
      );
    }
    if (code == 'PGRST205') {
      return RepositoryError(
        code: RepositoryErrorCode.invalidResponse,
        message: 'User achievements table is not available in schema cache.',
        cause: error,
      );
    }

    final rawMessage = error.message.toLowerCase();
    if (rawMessage.contains('does not exist') ||
        rawMessage.contains('relation') &&
            rawMessage.contains('user_achievements')) {
      return RepositoryError(
        code: RepositoryErrorCode.invalidResponse,
        message:
            'User achievements table is not available for this environment.',
        cause: error,
      );
    }
    if (rawMessage.contains('network') ||
        rawMessage.contains('socket') ||
        rawMessage.contains('timeout') ||
        rawMessage.contains('connection')) {
      return RepositoryError(
        code: RepositoryErrorCode.network,
        message: 'Network error while accessing user achievements.',
        cause: error,
      );
    }

    return RepositoryError(
      code: RepositoryErrorCode.unknown,
      message: fallbackMessage,
      cause: error,
    );
  }

  String? _nullableTrim(dynamic value) {
    final normalized = (value ?? '').toString().trim();
    return normalized.isEmpty ? null : normalized;
  }

  Future<RepositoryResult<RemoteUserAchievement>>
      _updateThenInsertAchievementForCurrentUser({
    required Map<String, dynamic> payload,
    required String userId,
    required String achievementId,
  }) async {
    final updatePayload = Map<String, dynamic>.from(payload)..remove('user_id');
    final updatedRows = await _client
        .from(_userAchievementsTable)
        .update(updatePayload)
        .eq('user_id', userId)
        .eq('achievement_id', achievementId)
        .select(_userAchievementColumns);

    if (updatedRows.isNotEmpty) {
      final remote = RemoteUserAchievement.fromMap(
        Map<String, dynamic>.from(updatedRows.first as Map),
      );
      if (remote.userId != userId || remote.achievementId != achievementId) {
        return RepositoryResult<RemoteUserAchievement>.failure(
          const RepositoryError(
            code: RepositoryErrorCode.invalidResponse,
            message: 'Achievement fallback update response was out of scope.',
          ),
        );
      }
      return RepositoryResult<RemoteUserAchievement>.success(data: remote);
    }

    final row = await _client
        .from(_userAchievementsTable)
        .insert(payload)
        .select(_userAchievementColumns)
        .single();
    final remote = RemoteUserAchievement.fromMap(Map<String, dynamic>.from(row));
    if (remote.userId != userId || remote.achievementId != achievementId) {
      return RepositoryResult<RemoteUserAchievement>.failure(
        const RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: 'Achievement fallback insert response was out of scope.',
        ),
      );
    }
    return RepositoryResult<RemoteUserAchievement>.success(data: remote);
  }

  String _postgrestDebugMessage(PostgrestException error) {
    final code = (error.code ?? '').trim();
    final message = error.message;
    final details = (error.details ?? '').toString().trim();
    final hint = (error.hint ?? '').toString().trim();
    return 'code=$code message="$message" details="${details.isEmpty ? 'null' : details}" hint="${hint.isEmpty ? 'null' : hint}"';
  }

  Map<String, dynamic> _debugSafePayload(Map<String, dynamic> payload) {
    final redacted = Map<String, dynamic>.from(payload);
    redacted.remove('user_id');
    return redacted;
  }
}
