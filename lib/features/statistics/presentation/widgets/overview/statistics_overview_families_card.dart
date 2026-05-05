import 'package:flutter/material.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/utils/family_theme.dart';

import '../../../domain/statistics_models.dart';
import 'statistics_overview_section_card.dart';

class StatisticsOverviewFamiliesCard extends StatelessWidget {
  const StatisticsOverviewFamiliesCard({
    super.key,
    required this.summary,
  });

  final StatisticsOverviewSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return StatisticsOverviewSectionCard(
      title: l10n.statisticsV2OverviewFamiliesTitle,
      subtitle: l10n.statisticsV2OverviewFamiliesSubtitle,
      child: summary.families.isEmpty
          ? Text(
              l10n.statisticsV2OverviewFamiliesEmpty,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black.withValues(alpha: 0.56),
              ),
            )
          : Column(
              children: summary.families
                  .map((family) => _FamilyRow(family: family))
                  .toList(growable: false),
            ),
    );
  }
}

class _FamilyRow extends StatelessWidget {
  const _FamilyRow({required this.family});

  final StatisticsOverviewFamilySummary family;

  @override
  Widget build(BuildContext context) {
    final color = FamilyTheme.colorOf(family.familyId);
    final completionValue = (family.completionPct / 100).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            FamilyTheme.emojiOf(family.familyId),
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              FamilyTheme.nameOf(family.familyId),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ),
          SizedBox(
            width: 100,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 7,
                value: completionValue,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${family.completedHabits}/${family.totalHabits}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.black.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}
