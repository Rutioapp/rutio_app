import 'package:flutter/foundation.dart';

@immutable
class RemoteProfile {
  const RemoteProfile({
    required this.id,
    this.email,
    this.displayName,
    this.avatarUrl,
    this.preferredLanguageCode,
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
  final String? email;
  final String? displayName;
  final String? avatarUrl;
  final String? preferredLanguageCode;
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
    return RemoteProfile(
      id: (map['id'] ?? '').toString(),
      email: _nullableTrim(map['email']),
      displayName: _nullableTrim(map['display_name'] ?? map['displayName']),
      avatarUrl: _nullableTrim(map['avatar_url'] ?? map['avatarUrl']),
      preferredLanguageCode: _nullableTrim(
        map['preferred_language_code'] ?? map['preferredLanguageCode'],
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
      lastLoginAt: _nullableDateTime(map['last_login_at'] ?? map['lastLoginAt']),
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
      if (displayName != null) 'display_name': displayName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (preferredLanguageCode != null)
        'preferred_language_code': preferredLanguageCode,
      if (notificationsEnabled != null)
        'notifications_enabled': notificationsEnabled,
      if (dailyMotivationEnabled != null)
        'daily_motivation_enabled': dailyMotivationEnabled,
      if (marketingNotificationsEnabled != null)
        'marketing_notifications_enabled': marketingNotificationsEnabled,
      if (dailyMotivationTime != null) 'daily_motivation_time': dailyMotivationTime,
      if (lastLoginAt != null) 'last_login_at': lastLoginAt!.toUtc().toIso8601String(),
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt!.toUtc().toIso8601String(),
      if (createdAt != null) 'created_at': createdAt!.toUtc().toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toUtc().toIso8601String(),
    };
  }

  static String? _nullableTrim(dynamic value) {
    final normalized = (value ?? '').toString().trim();
    return normalized.isEmpty ? null : normalized;
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
