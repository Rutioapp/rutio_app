import 'package:flutter/foundation.dart';

enum OnboardingStatus {
  pending,
  inProgress,
  completed;

  factory OnboardingStatus.fromSupabase(String value) {
    final normalized = value.trim();
    switch (normalized) {
      case 'pending':
        return OnboardingStatus.pending;
      case 'in_progress':
        return OnboardingStatus.inProgress;
      case 'completed':
        return OnboardingStatus.completed;
    }
    throw RemoteProfileParseException(
      'Unknown onboarding_status "$value".',
    );
  }

  String toSupabase() {
    switch (this) {
      case OnboardingStatus.pending:
        return 'pending';
      case OnboardingStatus.inProgress:
        return 'in_progress';
      case OnboardingStatus.completed:
        return 'completed';
    }
  }
}

class RemoteProfileParseException implements FormatException {
  const RemoteProfileParseException(this.message, [this.source, this.offset]);

  @override
  final String message;

  @override
  final dynamic source;

  @override
  final int? offset;

  @override
  String toString() => 'RemoteProfileParseException: $message';
}

@immutable
class BootstrapProfileDecision {
  const BootstrapProfileDecision({
    required this.userId,
    required this.onboardingStatus,
    required this.onboardingVersion,
    required this.onboardingCompletedAt,
  });

  final String userId;
  final OnboardingStatus onboardingStatus;
  final int onboardingVersion;
  final DateTime? onboardingCompletedAt;

  factory BootstrapProfileDecision.fromMap(
    Map<String, dynamic> map, {
    required String expectedUserId,
  }) {
    final userId = RemoteProfile._requiredTrim(map, 'id');
    if (userId != expectedUserId) {
      throw RemoteProfileParseException(
        'Profile decision id "$userId" did not match current user.',
      );
    }

    final onboardingStatus = OnboardingStatus.fromSupabase(
      RemoteProfile._requiredTrim(map, 'onboarding_status'),
    );
    final onboardingVersion = RemoteProfile._requiredPositiveInt(
      map,
      'onboarding_version',
    );
    final onboardingCompletedAt = RemoteProfile._nullableDateTime(
      map['onboarding_completed_at'] ?? map['onboardingCompletedAt'],
    );
    RemoteProfile._validateOnboardingConsistency(
      status: onboardingStatus,
      completedAt: onboardingCompletedAt,
    );

    return BootstrapProfileDecision(
      userId: userId,
      onboardingStatus: onboardingStatus,
      onboardingVersion: onboardingVersion,
      onboardingCompletedAt: onboardingCompletedAt,
    );
  }

  RemoteProfile toRemoteProfile() {
    return RemoteProfile(
      id: userId,
      onboardingStatus: onboardingStatus,
      onboardingVersion: onboardingVersion,
      onboardingCompletedAt: onboardingCompletedAt,
    );
  }

  factory BootstrapProfileDecision.fromRemoteProfile(
    RemoteProfile profile, {
    String? expectedUserId,
  }) {
    final userId = profile.id.trim();
    if (userId.isEmpty) {
      throw const RemoteProfileParseException(
        'Profile decision requires a non-empty user id.',
      );
    }
    if (expectedUserId != null && userId != expectedUserId) {
      throw RemoteProfileParseException(
        'Profile decision id "$userId" did not match current user.',
      );
    }
    RemoteProfile._validateOnboardingConsistency(
      status: profile.onboardingStatus,
      completedAt: profile.onboardingCompletedAt,
    );
    return BootstrapProfileDecision(
      userId: userId,
      onboardingStatus: profile.onboardingStatus,
      onboardingVersion: profile.onboardingVersion,
      onboardingCompletedAt: profile.onboardingCompletedAt,
    );
  }
}

@immutable
class RemoteProfile {
  const RemoteProfile({
    required this.id,
    required this.onboardingStatus,
    required this.onboardingVersion,
    required this.onboardingCompletedAt,
    this.email,
    this.displayName,
    this.avatarUrl,
    this.preferredLanguageCode,
    this.pillarHabitIds = const <String>[],
    this.notificationsEnabled,
    this.dailyMotivationEnabled,
    this.marketingNotificationsEnabled,
    this.dailyMotivationTime,
    this.lastLoginAt,
    this.lastSeenAt,
    this.createdAt,
    this.updatedAt,
    this.raw = const <String, dynamic>{},
  });

  final String id;
  final OnboardingStatus onboardingStatus;
  final int onboardingVersion;
  final DateTime? onboardingCompletedAt;
  final String? email;
  final String? displayName;
  final String? avatarUrl;
  final String? preferredLanguageCode;
  final List<String> pillarHabitIds;
  final bool? notificationsEnabled;
  final bool? dailyMotivationEnabled;
  final bool? marketingNotificationsEnabled;
  final String? dailyMotivationTime;
  final DateTime? lastLoginAt;
  final DateTime? lastSeenAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> raw;

  factory RemoteProfile.fromMap(Map<String, dynamic> map) {
    final onboardingStatus = OnboardingStatus.fromSupabase(
      _requiredTrim(map, 'onboarding_status'),
    );
    final onboardingVersion = _requiredPositiveInt(
      map,
      'onboarding_version',
    );
    final onboardingCompletedAt = _nullableDateTime(
      map['onboarding_completed_at'] ?? map['onboardingCompletedAt'],
    );
    _validateOnboardingConsistency(
      status: onboardingStatus,
      completedAt: onboardingCompletedAt,
    );

    return RemoteProfile(
      id: (map['id'] ?? '').toString(),
      onboardingStatus: onboardingStatus,
      onboardingVersion: onboardingVersion,
      onboardingCompletedAt: onboardingCompletedAt,
      email: _nullableTrim(map['email']),
      displayName: _nullableTrim(map['display_name'] ?? map['displayName']),
      avatarUrl: _nullableTrim(map['avatar_url'] ?? map['avatarUrl']),
      preferredLanguageCode: _nullableTrim(
        map['preferred_language_code'] ?? map['preferredLanguageCode'],
      ),
      pillarHabitIds: _normalizeStringList(
        map['pillar_habit_ids'] ?? map['pillarHabitIds'],
        maxLength: 3,
      ),
      notificationsEnabled: _nullableBool(
        map['notifications_enabled'] ?? map['notificationsEnabled'],
      ),
      dailyMotivationEnabled: _nullableBool(
        map['daily_motivation_enabled'] ?? map['dailyMotivationEnabled'],
      ),
      marketingNotificationsEnabled: _nullableBool(
        map['marketing_notifications_enabled'] ??
            map['marketingNotificationsEnabled'],
      ),
      dailyMotivationTime: _nullableTrim(
        map['daily_motivation_time'] ?? map['dailyMotivationTime'],
      ),
      lastLoginAt:
          _nullableDateTime(map['last_login_at'] ?? map['lastLoginAt']),
      lastSeenAt: _nullableDateTime(map['last_seen_at'] ?? map['lastSeenAt']),
      createdAt: _nullableDateTime(map['created_at'] ?? map['createdAt']),
      updatedAt: _nullableDateTime(map['updated_at'] ?? map['updatedAt']),
      raw: Map<String, dynamic>.from(map),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      if (email != null) 'email': email,
      'onboarding_status': onboardingStatus.toSupabase(),
      'onboarding_version': onboardingVersion,
      if (onboardingCompletedAt != null)
        'onboarding_completed_at':
            onboardingCompletedAt!.toUtc().toIso8601String(),
      if (displayName != null) 'display_name': displayName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (preferredLanguageCode != null)
        'preferred_language_code': preferredLanguageCode,
      'pillar_habit_ids': pillarHabitIds,
      if (notificationsEnabled != null)
        'notifications_enabled': notificationsEnabled,
      if (dailyMotivationEnabled != null)
        'daily_motivation_enabled': dailyMotivationEnabled,
      if (marketingNotificationsEnabled != null)
        'marketing_notifications_enabled': marketingNotificationsEnabled,
      if (dailyMotivationTime != null)
        'daily_motivation_time': dailyMotivationTime,
      if (lastLoginAt != null)
        'last_login_at': lastLoginAt!.toUtc().toIso8601String(),
      if (lastSeenAt != null)
        'last_seen_at': lastSeenAt!.toUtc().toIso8601String(),
      if (createdAt != null) 'created_at': createdAt!.toUtc().toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toUtc().toIso8601String(),
    };
  }

  BootstrapProfileDecision toBootstrapProfileDecision({
    String? expectedUserId,
  }) {
    return BootstrapProfileDecision.fromRemoteProfile(
      this,
      expectedUserId: expectedUserId,
    );
  }

  static String? _nullableTrim(dynamic value) {
    final normalized = (value ?? '').toString().trim();
    return normalized.isEmpty ? null : normalized;
  }

  static List<String> _normalizeStringList(
    dynamic value, {
    int? maxLength,
  }) {
    final output = <String>[];
    final seen = <String>{};

    if (value is Iterable) {
      for (final entry in value) {
        final normalized = (entry ?? '').toString().trim();
        if (normalized.isEmpty) continue;
        if (!seen.add(normalized)) continue;
        output.add(normalized);
        if (maxLength != null && output.length >= maxLength) break;
      }
    }

    return List<String>.unmodifiable(output);
  }

  static String _requiredTrim(Map<String, dynamic> map, String key) {
    final normalized = _nullableTrim(map[key]);
    if (normalized == null) {
      throw RemoteProfileParseException('Missing required "$key".');
    }
    return normalized;
  }

  static int _requiredPositiveInt(Map<String, dynamic> map, String key) {
    final raw = map[key];
    final parsed = raw is int ? raw : int.tryParse((raw ?? '').toString());
    if (parsed == null) {
      throw RemoteProfileParseException('Invalid "$key".');
    }
    if (parsed < 1) {
      throw RemoteProfileParseException('"$key" must be >= 1.');
    }
    return parsed;
  }

  static void _validateOnboardingConsistency({
    required OnboardingStatus status,
    required DateTime? completedAt,
  }) {
    if (status == OnboardingStatus.completed && completedAt == null) {
      throw const RemoteProfileParseException(
        'completed onboarding requires onboarding_completed_at.',
      );
    }
    if (status != OnboardingStatus.completed && completedAt != null) {
      throw const RemoteProfileParseException(
        'pending/in_progress onboarding requires null onboarding_completed_at.',
      );
    }
  }

  static bool? _nullableBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value > 0;

    final normalized = value.toString().trim().toLowerCase();
    if (normalized.isEmpty) return null;
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
    return null;
  }

  static DateTime? _nullableDateTime(dynamic value) {
    final normalized = _nullableTrim(value);
    if (normalized == null) return null;
    return DateTime.tryParse(normalized);
  }
}
