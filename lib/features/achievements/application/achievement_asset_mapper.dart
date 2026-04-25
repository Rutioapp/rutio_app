import '../../../utils/family_theme.dart';
import '../domain/models/achievement.dart';

class AchievementAssetMapper {
  const AchievementAssetMapper._();

  static const String _root = 'design/badges/Figma Icons';

  static const Map<AchievementTier, String> _folders = {
    AchievementTier.oldWood: 'Madera',
    AchievementTier.wood: 'Madera',
    AchievementTier.stone: 'Piedra',
    AchievementTier.bronze: 'Bronce',
    AchievementTier.silver: 'Plata',
    AchievementTier.gold: 'Oro',
    AchievementTier.diamond: 'Diamante',
    AchievementTier.prismaticDiamond: 'Diamante Prismatico',
  };

  static const Map<AchievementTier, Map<String, String>> _fileNames = {
    AchievementTier.oldWood: {
      FamilyTheme.discipline: 'Disciplina - Madera.png',
      FamilyTheme.emotional: 'Emocional - Madera.png',
      FamilyTheme.spirit: 'Espiritu - Madera.png',
      FamilyTheme.mind: 'Mente - Madera.png',
      FamilyTheme.professional: 'Profesional - Madera.png',
      FamilyTheme.body: 'Salud - Madera.png',
      FamilyTheme.social: 'Social - Madera.png',
    },
    AchievementTier.wood: {
      FamilyTheme.discipline: 'Disciplina - Madera.png',
      FamilyTheme.emotional: 'Emocional - Madera.png',
      FamilyTheme.spirit: 'Espiritu - Madera.png',
      FamilyTheme.mind: 'Mente - Madera.png',
      FamilyTheme.professional: 'Profesional - Madera.png',
      FamilyTheme.body: 'Salud - Madera.png',
      FamilyTheme.social: 'Social - Madera.png',
    },
    AchievementTier.stone: {
      FamilyTheme.discipline: 'Disciplina - Piedra.png',
      FamilyTheme.emotional: 'Emocional - Piedra.png',
      FamilyTheme.spirit: 'Espiritu - Piedra.png',
      FamilyTheme.mind: 'Mente - Piedra.png',
      FamilyTheme.professional: 'Profesional - Piedra.png',
      FamilyTheme.body: 'Salud - Piedra.png',
      FamilyTheme.social: 'Social - Piedra.png',
    },
    AchievementTier.bronze: {
      FamilyTheme.discipline: 'Disciplina - Bronce.png',
      FamilyTheme.emotional: 'Emocional - Bronce.png',
      FamilyTheme.spirit: 'Espiritu - Bronce.png',
      FamilyTheme.mind: 'Mente - Bronce.png',
      FamilyTheme.professional: 'Profesional - Bronce.png',
      FamilyTheme.body: 'Salud - Bronce.png',
      FamilyTheme.social: 'Social - Bronce.png',
    },
    AchievementTier.silver: {
      FamilyTheme.discipline: 'Disciplina - Plata.png',
      FamilyTheme.emotional: 'Emocional - Plata.png',
      FamilyTheme.spirit: 'Espiritu - Plata.png',
      FamilyTheme.mind: 'Mente - Plata.png',
      FamilyTheme.professional: 'Profesional - Plata.png',
      FamilyTheme.body: 'Salud - Plata.png',
      FamilyTheme.social: 'Social - Plata.png',
    },
    AchievementTier.gold: {
      FamilyTheme.discipline: 'Disciplina - Oro.png',
      FamilyTheme.emotional: 'Emocional - Oro.png',
      FamilyTheme.spirit: 'Espiritu - Oro.png',
      FamilyTheme.mind: 'Mente - Oro.png',
      FamilyTheme.professional: 'Profesional - Oro.png',
      FamilyTheme.body: 'Salud - Oro.png',
      FamilyTheme.social: 'Social - Oro.png',
    },
    AchievementTier.diamond: {
      FamilyTheme.discipline: 'Disciplina - Diamante.png',
      FamilyTheme.emotional: 'Emocional -Diamante.png',
      FamilyTheme.spirit: 'Espiritu - Diamante.png',
      FamilyTheme.mind: 'Mente - Diamante.png',
      FamilyTheme.professional: 'Profesional - Diamante.png',
      FamilyTheme.body: 'Salud - Diamante.png',
      FamilyTheme.social: 'Social - Diamante.png',
    },
    AchievementTier.prismaticDiamond: {
      FamilyTheme.discipline: 'Disciplina - Diamante Prismatico.png',
      FamilyTheme.emotional: 'Emocional -Diamante Prismatico.png',
      FamilyTheme.spirit: 'Espiritu - Diamante Prismatico.png',
      FamilyTheme.mind: 'Mente - Diamante Prismatico.png',
      FamilyTheme.professional: 'Profesional - Diamante Prismatico.png',
      FamilyTheme.body: 'Salud - Diamante Prismatico.png',
      FamilyTheme.social: 'Social - Diamante Prismatico.png',
    },
  };

  static String assetPathFor({
    required AchievementTier tier,
    required String familyId,
  }) {
    final normalizedFamily = FamilyTheme.order.contains(familyId)
        ? familyId
        : FamilyTheme.fallbackId;
    final folder = _folders[tier]!;
    final fileName = _fileNames[tier]![normalizedFamily] ??
        _fileNames[tier]![FamilyTheme.fallbackId]!;
    return '$_root/$folder/$fileName';
  }
}
