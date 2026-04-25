import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/l10n.dart';
import '../../../../stores/user_state_store.dart';
import '../../../../utils/family_theme.dart';
import '../../application/achievement_catalog.dart';
import '../../application/achievement_progress_service.dart';
import '../../domain/models/achievement.dart';
import '../../domain/models/achievement_progress.dart';
import '../sheets/achievement_detail_sheet.dart';
import '../widgets/achievements_family_section.dart';
import '../widgets/achievements_latest_unlocked_card.dart';
import '../widgets/achievements_page_header.dart';
import '../widgets/achievements_summary_row.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  static const String route = '/achievements';

  static const List<String> _familyDisplayOrder = <String>[
    FamilyTheme.body,
    FamilyTheme.mind,
    FamilyTheme.discipline,
    FamilyTheme.spirit,
    FamilyTheme.social,
    FamilyTheme.emotional,
    FamilyTheme.professional,
  ];
  static const Color _specialSectionColor = Color(0xFFB07B42);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: const Color(0xFFF6EEDD),
      body: SafeArea(
        child: Selector<UserStateStore, _AchievementsScreenData>(
          selector: (_, store) => _AchievementsScreenData.fromStore(store),
          builder: (context, data, _) {
            return CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 30),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        AchievementsPageHeader(
                          title: l10n.achievementsTitle,
                          onBack: () => Navigator.of(context).maybePop(),
                        ),
                        const SizedBox(height: 22),
                        AchievementsSummaryRow(
                          unlockedCount: data.unlockedCount,
                          totalCount: data.totalCount,
                          progress: data.totalProgress,
                        ),
                        const SizedBox(height: 24),
                        if (data.latestUnlocked != null) ...[
                          AchievementsLatestUnlockedCard(
                            progress: data.latestUnlocked!,
                            dateLabel:
                                _formatDate(data.latestUnlocked!.unlockedAt),
                            onTap: () => showAchievementDetailSheet(
                              context,
                              progress: data.latestUnlocked!,
                            ),
                          ),
                          const SizedBox(height: 28),
                        ],
                        for (
                          var index = 0;
                          index < data.sections.length;
                          index++
                        ) ...[
                          AchievementsFamilySection(
                            sectionId: data.sections[index].sectionId,
                            sectionColor: data.sections[index].sectionColor,
                            items: data.sections[index].items,
                            onItemTap: (progress) => showAchievementDetailSheet(
                              context,
                              progress: progress,
                            ),
                          ),
                          if (index != data.sections.length - 1)
                            const SizedBox(height: 30),
                        ],
                        if (data.sections.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Text(
                              l10n.achievementsEmptyAll,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF8A7A68),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';

    final month = DateFormat.MMMM('es').format(date).toLowerCase();
    return '${date.day} $month ${date.year}';
  }
}

class _AchievementsScreenData {
  const _AchievementsScreenData({
    required this.items,
    required this.sections,
    required this.unlockedCount,
    required this.totalCount,
    required this.totalProgress,
    required this.latestUnlocked,
  });

  final List<AchievementProgress> items;
  final List<_AchievementFamilySectionData> sections;
  final int unlockedCount;
  final int totalCount;
  final double totalProgress;
  final AchievementProgress? latestUnlocked;

  factory _AchievementsScreenData.fromStore(UserStateStore store) {
    final achievements = AchievementCatalog.buildAchievements(
      unlockedRecords: store.unlockedAchievementRecords,
    );
    final items = AchievementProgressService.resolve(
      achievements: achievements,
      snapshotsBySourceId: store.achievementMetricSnapshots,
      unlockedById: store.unlockedAchievementsById,
    );
    final unlockedItems = items
        .where((item) => item.status == AchievementStatus.unlocked)
        .toList(growable: false);
    final latestUnlocked = unlockedItems.isEmpty
        ? null
        : unlockedItems.reduce((current, next) {
            final currentDate =
                current.unlockedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final nextDate =
                next.unlockedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return nextDate.isAfter(currentDate) ? next : current;
          });
    final grouped = <String, List<AchievementProgress>>{};

    for (final item in items) {
      final sectionId = item.achievement.type == AchievementType.special
          ? AchievementCatalog.specialSectionId
          : item.achievement.familyId;
      grouped.putIfAbsent(sectionId, () => <AchievementProgress>[]);
      grouped[sectionId]!.add(item);
    }

    final sections = <_AchievementFamilySectionData>[];
    for (final sectionId in [
      ...AchievementsScreen._familyDisplayOrder,
      AchievementCatalog.specialSectionId,
    ]) {
      final familyItems =
          grouped.remove(sectionId) ?? const <AchievementProgress>[];
      sections.add(
        _AchievementFamilySectionData(
          sectionId: sectionId,
          sectionColor: sectionId == AchievementCatalog.specialSectionId
              ? AchievementsScreen._specialSectionColor
              : FamilyTheme.colorOf(sectionId),
          items: familyItems,
        ),
      );
    }

    final remainingKeys = grouped.keys.toList()..sort();
    for (final familyId in remainingKeys) {
      final familyItems = grouped[familyId];
      if (familyItems == null || familyItems.isEmpty) continue;
      sections.add(
        _AchievementFamilySectionData(
          sectionId: familyId,
          sectionColor: familyId == AchievementCatalog.specialSectionId
              ? AchievementsScreen._specialSectionColor
              : FamilyTheme.colorOf(familyId),
          items: familyItems,
        ),
      );
    }

    final totalCount = items.length;
    final unlockedCount = unlockedItems.length;
    final totalProgress = totalCount == 0
        ? 0.0
        : math.min(unlockedCount / totalCount, 1.0);

    return _AchievementsScreenData(
      items: items,
      sections: sections,
      unlockedCount: unlockedCount,
      totalCount: totalCount,
      totalProgress: totalProgress,
      latestUnlocked: latestUnlocked,
    );
  }
}

class _AchievementFamilySectionData {
  const _AchievementFamilySectionData({
    required this.sectionId,
    required this.sectionColor,
    required this.items,
  });

  final String sectionId;
  final Color sectionColor;
  final List<AchievementProgress> items;
}
