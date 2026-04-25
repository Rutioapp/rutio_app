import '../../../utils/family_theme.dart';
import '../domain/models/achievement.dart';
import '../domain/models/unlocked_achievement_record.dart';
import 'achievement_asset_mapper.dart';

class AchievementMilestone {
  const AchievementMilestone({
    required this.tier,
    required this.targetValue,
    required this.sortIndex,
  });

  final AchievementTier tier;
  final int targetValue;
  final int sortIndex;
}

class AchievementCatalog {
  const AchievementCatalog._();

  static const String specialSectionId = 'special';
  static const String _specialRoot = 'design/badges/Figma Icons/Logros';

  static const List<AchievementMilestone> streakMilestones = [
    AchievementMilestone(
      tier: AchievementTier.wood,
      targetValue: 7,
      sortIndex: 0,
    ),
    AchievementMilestone(
      tier: AchievementTier.stone,
      targetValue: 15,
      sortIndex: 1,
    ),
    AchievementMilestone(
      tier: AchievementTier.bronze,
      targetValue: 30,
      sortIndex: 2,
    ),
    AchievementMilestone(
      tier: AchievementTier.silver,
      targetValue: 45,
      sortIndex: 3,
    ),
    AchievementMilestone(
      tier: AchievementTier.gold,
      targetValue: 60,
      sortIndex: 4,
    ),
    AchievementMilestone(
      tier: AchievementTier.diamond,
      targetValue: 90,
      sortIndex: 5,
    ),
    AchievementMilestone(
      tier: AchievementTier.prismaticDiamond,
      targetValue: 150,
      sortIndex: 6,
    ),
  ];

  static const List<_SpecialAchievementDefinition> _specialAchievements = [
    _SpecialAchievementDefinition(
      id: 'special:madrugador',
      title: 'Madrugador',
      description: 'Completa 10 habitos antes de las 09:00.',
      assetFileName: 'Logro - Madrugador.png',
      targetValue: 10,
      sortIndex: 0,
      tier: AchievementTier.silver,
    ),
    _SpecialAchievementDefinition(
      id: 'special:buho_nocturno',
      title: 'Buho nocturno',
      description: 'Completa 10 habitos despues de las 22:00.',
      assetFileName: 'Logro - B\u00FAho Nocturno.png',
      targetValue: 10,
      sortIndex: 1,
      tier: AchievementTier.silver,
    ),
    _SpecialAchievementDefinition(
      id: 'special:flash',
      title: 'Flash',
      description: 'Completa 5 habitos en un solo dia.',
      assetFileName: 'Logro - Flash.png',
      targetValue: 5,
      sortIndex: 2,
      tier: AchievementTier.bronze,
    ),
    _SpecialAchievementDefinition(
      id: 'special:guerrero_del_finde',
      title: 'Guerrero del finde',
      description: 'Completa habitos durante 25 dias de fin de semana.',
      assetFileName: 'Logro - Guerrero del finde.png',
      targetValue: 25,
      sortIndex: 3,
      tier: AchievementTier.gold,
    ),
    _SpecialAchievementDefinition(
      id: 'special:el_arquitecto',
      title: 'El arquitecto',
      description: 'Realiza 500 acciones totales.',
      assetFileName: 'Logro - El arquitecto.png',
      targetValue: 500,
      sortIndex: 4,
      tier: AchievementTier.gold,
    ),
    _SpecialAchievementDefinition(
      id: 'special:turista',
      title: 'Turista',
      description:
          'Explora 5 familias distintas con al menos un habito completado.',
      assetFileName: 'Logro - Turista.png',
      targetValue: 5,
      sortIndex: 5,
      tier: AchievementTier.silver,
    ),
    _SpecialAchievementDefinition(
      id: 'special:polimota',
      title: 'Polimota',
      description: 'Manten al menos un habito activo en cada familia de Rutio.',
      assetFileName: 'Logro - Polimota.png',
      targetValue: 7,
      sortIndex: 6,
      tier: AchievementTier.gold,
    ),
    _SpecialAchievementDefinition(
      id: 'special:hay_alguien_ahi',
      title: '\u00BFHay alguien ahi?',
      description: 'Completa habitos sociales en 7 dias distintos.',
      assetFileName: 'Logro - \u00BFHay alguien alli_.png',
      targetValue: 7,
      sortIndex: 7,
      tier: AchievementTier.wood,
    ),
    _SpecialAchievementDefinition(
      id: 'special:ave_fenix',
      title: 'Ave fenix',
      description: 'Recupera una racha despues de haberla roto.',
      assetFileName: 'Logro - Ave Fenix.png',
      targetValue: 1,
      sortIndex: 8,
      tier: AchievementTier.gold,
    ),
    _SpecialAchievementDefinition(
      id: 'special:perfeccionista',
      title: 'Perfeccionista',
      description:
          'Consigue 10 dias perfectos completando todo lo programado.',
      assetFileName: 'Logro - Perfeccionista.png',
      targetValue: 10,
      sortIndex: 9,
      tier: AchievementTier.diamond,
    ),
    _SpecialAchievementDefinition(
      id: 'special:el_centurion',
      title: 'El centurion',
      description: 'Completa 100 habitos en total.',
      assetFileName: 'Logro - El centurion.png',
      targetValue: 100,
      sortIndex: 10,
      tier: AchievementTier.diamond,
    ),
    _SpecialAchievementDefinition(
      id: 'special:imparable',
      title: 'Imparable',
      description:
          'Encadena una racha global de 21 dias con al menos un habito completado.',
      assetFileName: 'Logro - Imparable.png',
      targetValue: 21,
      sortIndex: 11,
      tier: AchievementTier.diamond,
    ),
    _SpecialAchievementDefinition(
      id: 'special:coleccionista',
      title: 'Coleccionista',
      description: 'Desbloquea 30 logros distintos.',
      assetFileName: 'Logro - Coleccionista.png',
      targetValue: 30,
      sortIndex: 12,
      tier: AchievementTier.diamond,
    ),
    _SpecialAchievementDefinition(
      id: 'special:leyenda_viva',
      title: 'Leyenda viva',
      description: 'Completa 1000 veces en historico tus habitos.',
      assetFileName: 'Logro - Leyenda viva.png',
      targetValue: 1000,
      sortIndex: 13,
      tier: AchievementTier.prismaticDiamond,
    ),
    _SpecialAchievementDefinition(
      id: 'special:francotirados',
      title: 'Francotirados',
      description:
          'Clava exactamente el objetivo de un habito numerico 25 veces.',
      assetFileName: 'Logro - Francotirados.png',
      targetValue: 25,
      sortIndex: 14,
      tier: AchievementTier.silver,
    ),
    _SpecialAchievementDefinition(
      id: 'special:plusmarquista',
      title: 'Plusmarquista',
      description: 'Alcanza una racha de 100 dias en un mismo habito.',
      assetFileName: 'Logro - Plusmarquista.png',
      targetValue: 100,
      sortIndex: 15,
      tier: AchievementTier.diamond,
    ),
    _SpecialAchievementDefinition(
      id: 'special:reloj_suizo',
      title: 'Reloj suizo',
      description:
          'Completa 20 veces un habito dentro de los 10 minutos de su recordatorio.',
      assetFileName: 'Logro - Reloj Suizo.png',
      targetValue: 20,
      sortIndex: 16,
      tier: AchievementTier.gold,
    ),
    _SpecialAchievementDefinition(
      id: 'special:veterano',
      title: 'Veterano',
      description: 'Completa tus habitos en 180 dias distintos.',
      assetFileName: 'Logro - Veterano.png',
      targetValue: 180,
      sortIndex: 17,
      tier: AchievementTier.diamond,
    ),
  ];

  static String familyConsistencyAchievementId({
    required String familyId,
    required AchievementTier tier,
  }) {
    return '${AchievementType.familyConsistency.key}:$familyId:${tier.key}';
  }

  static String tierLabel(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.oldWood:
        return 'Madera vieja';
      case AchievementTier.wood:
        return 'Madera';
      case AchievementTier.stone:
        return 'Piedra';
      case AchievementTier.bronze:
        return 'Bronce';
      case AchievementTier.silver:
        return 'Plata';
      case AchievementTier.gold:
        return 'Oro';
      case AchievementTier.diamond:
        return 'Diamante';
      case AchievementTier.prismaticDiamond:
        return 'Diamante prismatico';
    }
  }

  static String familyAchievementTitle({
    required String familyId,
    required AchievementTier tier,
  }) {
    return '${FamilyTheme.nameOf(familyId)}: ${tierLabel(tier)}';
  }

  static String familyAchievementDescription({
    required String familyId,
    required int targetValue,
  }) {
    return 'Manten una constancia de $targetValue dias dentro de la familia ${FamilyTheme.nameOf(familyId)}.';
  }

  static List<Achievement> buildSpecialAchievements() {
    return _specialAchievements
        .map(
          (definition) => definition.toAchievement(
            assetPath: '$_specialRoot/${definition.assetFileName}',
          ),
        )
        .toList(growable: false);
  }

  static List<Achievement> buildAchievements({
    List<UnlockedAchievementRecord> unlockedRecords =
        const <UnlockedAchievementRecord>[],
  }) {
    final achievements = <Achievement>[
      ...buildFamilyConsistencyAchievements(unlockedRecords: unlockedRecords),
      ...buildSpecialAchievements(),
    ];
    achievements.sort((a, b) {
      final order = a.sortOrder.compareTo(b.sortOrder);
      if (order != 0) return order;
      return a.id.compareTo(b.id);
    });
    return achievements;
  }

  static Achievement? achievementForId(
    String id, {
    List<UnlockedAchievementRecord> unlockedRecords =
        const <UnlockedAchievementRecord>[],
  }) {
    for (final achievement in buildAchievements(
      unlockedRecords: unlockedRecords,
    )) {
      if (achievement.id == id) return achievement;
    }
    return null;
  }

  static Achievement? achievementForRecord(UnlockedAchievementRecord record) {
    return achievementForId(record.id, unlockedRecords: [record]);
  }

  static Achievement achievementForUnlockSheetRecord(
    UnlockedAchievementRecord record, {
    List<UnlockedAchievementRecord> unlockedRecords =
        const <UnlockedAchievementRecord>[],
    int xpReward = 0,
    int ambarReward = 0,
  }) {
    final baseAchievement =
        achievementForId(
          record.id,
          unlockedRecords: [record],
        ) ??
        Achievement(
          id: record.id,
          type: record.type,
          tier: record.tier,
          title: record.habitName,
          description: '',
          hidden: false,
          targetValue: record.targetValue,
          assetPath: AchievementAssetMapper.assetPathFor(
            tier: record.tier,
            familyId: record.familyId,
          ),
          sortOrder: 0,
          habitId: record.habitId,
          habitName: record.habitName,
          familyId: record.familyId,
        );

    return Achievement(
      id: baseAchievement.id,
      type: baseAchievement.type,
      tier: baseAchievement.tier,
      title: baseAchievement.title,
      description: baseAchievement.description,
      hidden: baseAchievement.hidden,
      targetValue: baseAchievement.targetValue,
      assetPath: baseAchievement.assetPath,
      sortOrder: baseAchievement.sortOrder,
      habitId: baseAchievement.habitId,
      habitName: baseAchievement.habitName,
      familyId: baseAchievement.familyId,
      xpReward: xpReward,
      ambarReward: ambarReward,
      collection: collectionForAchievement(
        baseAchievement,
        unlockedRecords: unlockedRecords,
      ),
    );
  }

  static AchievementCollection? collectionForAchievement(
    Achievement achievement, {
    List<UnlockedAchievementRecord> unlockedRecords =
        const <UnlockedAchievementRecord>[],
  }) {
    if (achievement.type != AchievementType.familyConsistency) return null;

    final allInCollection = buildFamilyConsistencyAchievements(
      unlockedRecords: unlockedRecords,
    ).where((item) => item.familyId == achievement.familyId).toList(growable: false);
    final totalCount = allInCollection.length;
    final unlockedCount = unlockedRecords
        .where((record) => record.type == AchievementType.familyConsistency)
        .where((record) => record.familyId == achievement.familyId)
        .length;

    return AchievementCollection(
      name: FamilyTheme.nameOf(achievement.familyId),
      familyColor: FamilyTheme.colorOf(achievement.familyId),
      totalCount: totalCount,
      unlockedCount: unlockedCount,
    );
  }

  static List<Achievement> buildFamilyConsistencyAchievements({
    List<UnlockedAchievementRecord> unlockedRecords =
        const <UnlockedAchievementRecord>[],
  }) {
    final achievements = <Achievement>[];
    final existingIds = <String>{};

    for (
      var familyIndex = 0;
      familyIndex < FamilyTheme.order.length;
      familyIndex++
    ) {
      final familyId = FamilyTheme.order[familyIndex];

      for (final milestone in streakMilestones) {
        final achievement = Achievement(
          id: familyConsistencyAchievementId(
            familyId: familyId,
            tier: milestone.tier,
          ),
          type: AchievementType.familyConsistency,
          tier: milestone.tier,
          title: familyAchievementTitle(
            familyId: familyId,
            tier: milestone.tier,
          ),
          description: familyAchievementDescription(
            familyId: familyId,
            targetValue: milestone.targetValue,
          ),
          hidden: false,
          targetValue: milestone.targetValue,
          assetPath: AchievementAssetMapper.assetPathFor(
            tier: milestone.tier,
            familyId: familyId,
          ),
          sortOrder: (familyIndex * 100) + milestone.sortIndex,
          habitId: familyId,
          habitName: familyAchievementTitle(
            familyId: familyId,
            tier: milestone.tier,
          ),
          familyId: familyId,
        );
        achievements.add(achievement);
        existingIds.add(achievement.id);
      }
    }

    for (final record in unlockedRecords) {
      if (record.type != AchievementType.familyConsistency) continue;
      if (record.tier == AchievementTier.oldWood) continue;
      if (existingIds.contains(record.id)) continue;

      final milestone = streakMilestones.firstWhere(
        (candidate) => candidate.tier == record.tier,
        orElse: () => AchievementMilestone(
          tier: record.tier,
          targetValue: record.targetValue,
          sortIndex: streakMilestones.length,
        ),
      );
      final familyIndex = FamilyTheme.order.indexOf(record.familyId);
      final safeFamilyIndex =
          familyIndex == -1 ? FamilyTheme.order.length : familyIndex;

      final achievement = Achievement(
        id: record.id,
        type: record.type,
        tier: record.tier,
        title: familyAchievementTitle(
          familyId: record.familyId,
          tier: record.tier,
        ),
        description: familyAchievementDescription(
          familyId: record.familyId,
          targetValue: record.targetValue,
        ),
        hidden: false,
        targetValue: record.targetValue,
        assetPath: AchievementAssetMapper.assetPathFor(
          tier: record.tier,
          familyId: record.familyId,
        ),
        sortOrder: (safeFamilyIndex * 100) + milestone.sortIndex,
        habitId: record.familyId,
        habitName: familyAchievementTitle(
          familyId: record.familyId,
          tier: record.tier,
        ),
        familyId: record.familyId,
      );
      achievements.add(achievement);
      existingIds.add(achievement.id);
    }

    achievements.sort((a, b) {
      final order = a.sortOrder.compareTo(b.sortOrder);
      if (order != 0) return order;

      return a.id.compareTo(b.id);
    });

    return achievements;
  }
}

class _SpecialAchievementDefinition {
  const _SpecialAchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.assetFileName,
    required this.targetValue,
    required this.sortIndex,
    required this.tier,
  });

  final String id;
  final String title;
  final String description;
  final String assetFileName;
  final int targetValue;
  final int sortIndex;
  final AchievementTier tier;

  Achievement toAchievement({required String assetPath}) {
    return Achievement(
      id: id,
      type: AchievementType.special,
      tier: tier,
      title: title,
      description: description,
      hidden: false,
      targetValue: targetValue,
      assetPath: assetPath,
      sortOrder: 1000 + sortIndex,
      habitId: id,
      habitName: title,
      familyId: AchievementCatalog.specialSectionId,
    );
  }
}
