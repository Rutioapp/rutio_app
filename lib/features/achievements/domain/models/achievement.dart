import 'dart:ui' show Color;

enum AchievementType {
  habitStreak,
  familyConsistency,
  special,
}

enum AchievementTier {
  oldWood,
  wood,
  stone,
  bronze,
  silver,
  gold,
  diamond,
  prismaticDiamond,
}

enum AchievementStatus {
  locked,
  inProgress,
  unlocked,
}

extension AchievementTypeX on AchievementType {
  String get key {
    switch (this) {
      case AchievementType.habitStreak:
        return 'habit_streak';
      case AchievementType.familyConsistency:
        return 'family_consistency';
      case AchievementType.special:
        return 'special';
    }
  }

  static AchievementType fromKey(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'family_consistency':
        return AchievementType.familyConsistency;
      case 'special':
        return AchievementType.special;
      case 'habit_streak':
      default:
        return AchievementType.habitStreak;
    }
  }
}

extension AchievementTierX on AchievementTier {
  String get key {
    switch (this) {
      case AchievementTier.oldWood:
        return 'madera_vieja';
      case AchievementTier.wood:
        return 'madera';
      case AchievementTier.stone:
        return 'piedra';
      case AchievementTier.bronze:
        return 'bronce';
      case AchievementTier.silver:
        return 'plata';
      case AchievementTier.gold:
        return 'oro';
      case AchievementTier.diamond:
        return 'diamante';
      case AchievementTier.prismaticDiamond:
        return 'diamante_prismatico';
    }
  }

  static AchievementTier fromKey(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'madera_vieja':
        return AchievementTier.oldWood;
      case 'madera':
        return AchievementTier.wood;
      case 'piedra':
        return AchievementTier.stone;
      case 'bronce':
        return AchievementTier.bronze;
      case 'plata':
        return AchievementTier.silver;
      case 'oro':
        return AchievementTier.gold;
      case 'diamante':
        return AchievementTier.diamond;
      case 'diamante_prismatico':
      default:
        return AchievementTier.prismaticDiamond;
    }
  }
}

class Achievement {
  const Achievement({
    required this.id,
    required this.type,
    required this.tier,
    required this.title,
    required this.description,
    required this.hidden,
    required this.targetValue,
    required this.assetPath,
    required this.sortOrder,
    required this.habitId,
    required this.habitName,
    required this.familyId,
    this.xpReward = 0,
    this.ambarReward = 0,
    this.collection,
  });

  final String id;
  final AchievementType type;
  final AchievementTier tier;
  final String title;
  final String description;
  final bool hidden;
  final int targetValue;
  final String assetPath;
  final int sortOrder;
  final String habitId;
  final String habitName;
  final String familyId;
  final int xpReward;
  final int ambarReward;
  final AchievementCollection? collection;

  String get name => title;
  String get badgeAssetPath => assetPath;
}

class AchievementCollection {
  const AchievementCollection({
    required this.name,
    required this.familyColor,
    required this.totalCount,
    required this.unlockedCount,
  });

  final String name;
  final Color familyColor;
  final int totalCount;
  final int unlockedCount;
}
