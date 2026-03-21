import 'package:flutter/foundation.dart';

import 'inventory.dart';
import 'user_profile.dart';

@immutable
class UserState {
  final int level;
  final int xp;
  final int coins;
  final Inventory inventory;
  final UserProfile profile;

  const UserState({
    required this.level,
    required this.xp,
    required this.coins,
    required this.inventory,
    required this.profile,
  });

  UserState copyWith({
    int? level,
    int? xp,
    int? coins,
    Inventory? inventory,
    UserProfile? profile,
  }) {
    return UserState(
      level: level ?? this.level,
      xp: xp ?? this.xp,
      coins: coins ?? this.coins,
      inventory: inventory ?? this.inventory,
      profile: profile ?? this.profile,
    );
  }

  factory UserState.fromJson(Map<String, dynamic> json) {
    return UserState(
      level: (json['level'] as num?)?.toInt() ?? 1,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      coins: (json['coins'] as num?)?.toInt() ?? 0,
      inventory: Inventory.fromJson((json['inventory'] as Map?)?.cast<String, dynamic>() ?? const {}),
      profile: UserProfile.fromJson((json['profile'] as Map?)?.cast<String, dynamic>() ?? const {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'level': level,
        'xp': xp,
        'coins': coins,
        'inventory': inventory.toJson(),
        'profile': profile.toJson(),
      };
}
