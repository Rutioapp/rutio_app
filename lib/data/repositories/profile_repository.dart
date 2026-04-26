import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/rutio_supabase_client.dart';
import '../models/remote/remote_profile.dart';
import 'repository_result.dart';

class ProfileRepository {
  ProfileRepository({SupabaseClient? client})
      : _client = client ?? RutioSupabaseClient.instance;

  final SupabaseClient _client;
  static const String _profilesTable = 'profiles';

  User? get currentUser => _client.auth.currentUser;

  Future<RepositoryResult<RemoteProfile?>> fetchCurrentProfile() async {
    final userId = _currentUserId();
    if (userId == null) {
      return RepositoryResult<RemoteProfile?>.failure(_notAuthenticated());
    }

    try {
      final row =
          await _client.from(_profilesTable).select().eq('id', userId).maybeSingle();
      if (row == null) {
        return const RepositoryResult<RemoteProfile?>.success(data: null);
      }
      return RepositoryResult<RemoteProfile?>.success(
        data: RemoteProfile.fromMap(Map<String, dynamic>.from(row)),
      );
    } on PostgrestException catch (error) {
      return RepositoryResult<RemoteProfile?>.failure(
        _mapPostgrestError(
          error,
          fallbackMessage: 'Could not fetch profile.',
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[profile_repository] unexpected fetch error: $error');
      }
      return RepositoryResult<RemoteProfile?>.failure(
        RepositoryError(
          code: RepositoryErrorCode.unknown,
          message: 'Could not fetch profile.',
          cause: error,
        ),
      );
    }
  }

  Future<RepositoryResult<RemoteProfile>> upsertCurrentProfile({
    String? email,
    String? displayName,
    String? avatarUrl,
  }) async {
    final user = currentUser;
    final userId = user?.id.trim();
    if (user == null || userId == null || userId.isEmpty) {
      return RepositoryResult<RemoteProfile>.failure(_notAuthenticated());
    }

    final payload = <String, dynamic>{
      'id': userId,
      'email': _firstNonEmptyValue(
        email,
        user.email,
      ),
      'display_name': _firstNonEmptyValue(
        displayName,
        user.userMetadata?['display_name']?.toString(),
        user.userMetadata?['name']?.toString(),
      ),
      'avatar_url': _firstNonEmptyValue(
        avatarUrl,
        user.userMetadata?['avatar_url']?.toString(),
        user.userMetadata?['avatarUrl']?.toString(),
      ),
    }..removeWhere((_, value) => value == null);

    try {
      final row = await _client
          .from(_profilesTable)
          .upsert(payload, onConflict: 'id')
          .select()
          .single();
      final profile = RemoteProfile.fromMap(Map<String, dynamic>.from(row));
      if (profile.id != userId) {
        return RepositoryResult<RemoteProfile>.failure(
          RepositoryError(
            code: RepositoryErrorCode.invalidResponse,
            message: 'Profile upsert response did not match current user.',
          ),
        );
      }

      return RepositoryResult<RemoteProfile>.success(
        data: profile,
      );
    } on PostgrestException catch (error) {
      return RepositoryResult<RemoteProfile>.failure(
        _mapPostgrestError(
          error,
          fallbackMessage: 'Could not upsert profile.',
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[profile_repository] unexpected upsert error: $error');
      }
      return RepositoryResult<RemoteProfile>.failure(
        RepositoryError(
          code: RepositoryErrorCode.unknown,
          message: 'Could not upsert profile.',
          cause: error,
        ),
      );
    }
  }

  Future<RepositoryResult<RemoteProfile>> ensureCurrentProfile({
    String? email,
    String? displayName,
    String? avatarUrl,
  }) async {
    final existingResult = await fetchCurrentProfile();
    if (!existingResult.isSuccess) {
      return RepositoryResult<RemoteProfile>.failure(existingResult.error!);
    }

    final existingProfile = existingResult.data;
    if (existingProfile != null) {
      return RepositoryResult<RemoteProfile>.success(data: existingProfile);
    }

    return upsertCurrentProfile(
      email: email,
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
  }

  /// Legacy compatibility method for existing callers that still expect a map.
  Future<Map<String, dynamic>?> fetchCurrentUserProfile() async {
    final result = await fetchCurrentProfile();
    if (!result.isSuccess || result.data == null) return null;
    return result.data!.toMap();
  }

  String? _currentUserId() {
    final userId = currentUser?.id.trim();
    if (userId == null || userId.isEmpty) return null;
    return userId;
  }

  RepositoryError _notAuthenticated() {
    return const RepositoryError(
      code: RepositoryErrorCode.notAuthenticated,
      message: 'No authenticated user session is available.',
    );
  }

  String? _firstNonEmptyValue(String? first, [String? second, String? third]) {
    final values = <String?>[first, second, third];
    for (final value in values) {
      final normalized = (value ?? '').trim();
      if (normalized.isNotEmpty) return normalized;
    }
    return null;
  }

  RepositoryError _mapPostgrestError(
    PostgrestException error, {
    required String fallbackMessage,
  }) {
    if (kDebugMode) {
      debugPrint(
        '[profile_repository] postgrest error (${error.code}): ${error.message}',
      );
    }

    final code = (error.code ?? '').trim();
    if (code == 'PGRST116') {
      return RepositoryError(
        code: RepositoryErrorCode.notFound,
        message: 'Profile row was not found.',
        cause: error,
      );
    }
    if (code == '42501') {
      return RepositoryError(
        code: RepositoryErrorCode.permissionDenied,
        message: 'Permission denied for profile operation.',
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
        message: 'Network error while accessing profile data.',
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
