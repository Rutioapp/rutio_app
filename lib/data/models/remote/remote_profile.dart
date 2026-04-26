import 'package:flutter/foundation.dart';

@immutable
class RemoteProfile {
  const RemoteProfile({
    required this.id,
    this.email,
    this.displayName,
    this.avatarUrl,
    this.raw = const <String, dynamic>{},
  });

  final String id;
  final String? email;
  final String? displayName;
  final String? avatarUrl;
  final Map<String, dynamic> raw;

  factory RemoteProfile.fromMap(Map<String, dynamic> map) {
    return RemoteProfile(
      id: (map['id'] ?? '').toString(),
      email: _nullableTrim(map['email']),
      displayName: _nullableTrim(map['display_name'] ?? map['displayName']),
      avatarUrl: _nullableTrim(map['avatar_url'] ?? map['avatarUrl']),
      raw: Map<String, dynamic>.from(map),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      if (email != null) 'email': email,
      if (displayName != null) 'display_name': displayName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };
  }

  static String? _nullableTrim(dynamic value) {
    final normalized = (value ?? '').toString().trim();
    return normalized.isEmpty ? null : normalized;
  }
}
