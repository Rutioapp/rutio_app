import 'package:flutter/foundation.dart';

@immutable
class FamilyLevel {
  final String id;
  final String name;
  final int level;
  final int xp;
  final int xpToNext;

  const FamilyLevel({
    required this.id,
    required this.name,
    required this.level,
    required this.xp,
    required this.xpToNext,
  });
}

@immutable
class LevelData {
  final int level;
  final int xpToNext;

  const LevelData({required this.level, required this.xpToNext});
}
