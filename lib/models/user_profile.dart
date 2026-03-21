import 'package:flutter/foundation.dart';
@immutable
class UserProfile {
  final Map<String, String> equipped;

  const UserProfile({
    required this.equipped,
  });

  UserProfile copyWith({
    Map<String, String>? equipped,
  }) {
    return UserProfile(
      equipped: equipped ?? this.equipped,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      equipped: Map<String, String>.from(json['equipped']),
    );
  }

  Map<String, dynamic> toJson() => {
        'equipped': equipped,
      };
}
