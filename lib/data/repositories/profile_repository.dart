import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/rutio_supabase_client.dart';
import '../models/remote/remote_profile.dart';
import 'repository_result.dart';

class ProfileRepository {
  ProfileRepository({SupabaseClient? client})
      : _client = client ?? RutioSupabaseClient.instance;

  final SupabaseClient _client;
  final Set<String> _unsupportedColumns = <String>{};

  static const String _profilesTable = 'profiles';
  static const int _maxRetryableColumnDrops = 12;

  User? get currentUser => _client.auth.currentUser;

  Future<RepositoryResult<RemoteProfile?>> fetchCurrentProfile() async {
    final userId = _currentUserId();
    if (userId == null) {
      return RepositoryResult<RemoteProfile?>.failure(_notAuthenticated());
    }

    try {
      final row = await _client
          .from(_profilesTable)
          .select()
          .eq('id', userId)
          .maybeSingle();
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

    return _upsertScopedProfilePatch(
      user: user,
      patch: payload,
      fallbackMessage: 'Could not upsert profile.',
    );
  }

  Future<RepositoryResult<RemoteProfile>> updateProfileBasics({
    String? email,
    String? displayName,
    String? avatarUrl,
    bool clearAvatarUrl = false,
  }) {
    final patch = <String, dynamic>{};
    if (email != null) {
      patch['email'] = _nullableTrim(email);
    }
    if (displayName != null) {
      patch['display_name'] = _nullableTrim(displayName);
    }
    if (avatarUrl != null) {
      patch['avatar_url'] = _nullableTrim(avatarUrl);
    }
    if (clearAvatarUrl) {
      patch['avatar_url'] = null;
    }

    if (patch.isEmpty) {
      return ensureCurrentProfile();
    }

    return _upsertScopedProfilePatch(
      patch: patch,
      fallbackMessage: 'Could not update profile basics.',
    );
  }

  Future<RepositoryResult<RemoteProfile>> updatePreferredLanguage(
    String? languageCode,
  ) {
    final normalized = _nullableTrim(languageCode)?.toLowerCase();
    return _upsertScopedProfilePatch(
      patch: <String, dynamic>{'preferred_language_code': normalized},
      fallbackMessage: 'Could not update preferred language.',
    );
  }

  Future<RepositoryResult<RemoteProfile>> updateNotificationSettings({
    bool? notificationsEnabled,
    bool? dailyMotivationEnabled,
    bool? marketingNotificationsEnabled,
    String? dailyMotivationTime,
    bool includeDailyMotivationTime = false,
  }) {
    final patch = <String, dynamic>{};
    if (notificationsEnabled != null) {
      patch['notifications_enabled'] = notificationsEnabled;
    }
    if (dailyMotivationEnabled != null) {
      patch['daily_motivation_enabled'] = dailyMotivationEnabled;
    }
    if (marketingNotificationsEnabled != null) {
      patch['marketing_notifications_enabled'] = marketingNotificationsEnabled;
    }
    if (includeDailyMotivationTime) {
      patch['daily_motivation_time'] = _nullableTrim(dailyMotivationTime);
    }

    if (patch.isEmpty) {
      return ensureCurrentProfile();
    }

    return _upsertScopedProfilePatch(
      patch: patch,
      fallbackMessage: 'Could not update notification settings.',
    );
  }

  Future<RepositoryResult<RemoteProfile>> touchLastLogin({
    DateTime? at,
  }) {
    return _upsertScopedProfilePatch(
      patch: <String, dynamic>{
        'last_login_at': (at ?? DateTime.now()).toUtc().toIso8601String(),
      },
      fallbackMessage: 'Could not update last login.',
    );
  }

  Future<RepositoryResult<RemoteProfile>> touchLastSeen({
    DateTime? at,
  }) {
    return _upsertScopedProfilePatch(
      patch: <String, dynamic>{
        'last_seen_at': (at ?? DateTime.now()).toUtc().toIso8601String(),
      },
      fallbackMessage: 'Could not update last seen.',
    );
  }

  /// Legacy compatibility method for existing callers that still expect a map.
  Future<Map<String, dynamic>?> fetchCurrentUserProfile() async {
    final result = await fetchCurrentProfile();
    if (!result.isSuccess || result.data == null) return null;
    return result.data!.toMap();
  }

  Future<RepositoryResult<RemoteProfile>> _upsertScopedProfilePatch({
    required Map<String, dynamic> patch,
    required String fallbackMessage,
    User? user,
  }) async {
    final activeUser = user ?? currentUser;
    final userId = activeUser?.id.trim();
    if (activeUser == null || userId == null || userId.isEmpty) {
      return RepositoryResult<RemoteProfile>.failure(_notAuthenticated());
    }

    var payload = <String, dynamic>{
      'id': userId,
      ...patch,
    };

    // Keep email best-effort for row creation safety when the column exists.
    if (!payload.containsKey('email')) {
      final fallbackEmail = _nullableTrim(activeUser.email);
      if (fallbackEmail != null) {
        payload['email'] = fallbackEmail;
      }
    }

    payload = _removeKnownUnsupportedColumns(payload);
    if (!payload.containsKey('id')) {
      payload['id'] = userId;
    }

    var droppedColumns = 0;

    while (true) {
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
        return RepositoryResult<RemoteProfile>.success(data: profile);
      } on PostgrestException catch (error) {
        final missingColumn = _extractMissingColumn(error);
        final canRetryWithColumnDropped = missingColumn != null &&
            missingColumn != 'id' &&
            payload.containsKey(missingColumn) &&
            droppedColumns < _maxRetryableColumnDrops;

        if (canRetryWithColumnDropped) {
          droppedColumns += 1;
          _unsupportedColumns.add(missingColumn);
          payload = Map<String, dynamic>.from(payload)
            ..remove(missingColumn)
            ..['id'] = userId;
          if (kDebugMode) {
            debugPrint(
              '[profile_repository] ignoring unsupported column "$missingColumn" for profiles upsert',
            );
          }
          continue;
        }

        return RepositoryResult<RemoteProfile>.failure(
          _mapPostgrestError(
            error,
            fallbackMessage: fallbackMessage,
          ),
        );
      } catch (error) {
        if (kDebugMode) {
          debugPrint('[profile_repository] unexpected upsert error: $error');
        }
        return RepositoryResult<RemoteProfile>.failure(
          RepositoryError(
            code: RepositoryErrorCode.unknown,
            message: fallbackMessage,
            cause: error,
          ),
        );
      }
    }
  }

  Map<String, dynamic> _removeKnownUnsupportedColumns(
    Map<String, dynamic> payload,
  ) {
    if (_unsupportedColumns.isEmpty) return payload;

    final filtered = Map<String, dynamic>.from(payload);
    for (final key in _unsupportedColumns) {
      if (key == 'id') continue;
      filtered.remove(key);
    }
    return filtered;
  }

  String? _extractMissingColumn(PostgrestException error) {
    final combined = [
      error.message,
      error.details,
      error.hint,
    ].whereType<String>().join('\n');

    final patterns = <RegExp>[
      RegExp(r'column\s+"([a-zA-Z0-9_]+)"', caseSensitive: false),
      RegExp(r"column\s+'([a-zA-Z0-9_]+)'", caseSensitive: false),
      RegExp(r"'([a-zA-Z0-9_]+)'\s+column", caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(combined);
      final column = match?.group(1)?.trim();
      if (column != null && column.isNotEmpty) {
        return column;
      }
    }
    return null;
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
      final normalized = _nullableTrim(value);
      if (normalized != null) return normalized;
    }
    return null;
  }

  String? _nullableTrim(dynamic value) {
    final normalized = (value ?? '').toString().trim();
    return normalized.isEmpty ? null : normalized;
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
    if (code == '42703' || code == 'PGRST204') {
      return RepositoryError(
        code: RepositoryErrorCode.invalidResponse,
        message: 'Profile schema is missing one or more expected columns.',
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
