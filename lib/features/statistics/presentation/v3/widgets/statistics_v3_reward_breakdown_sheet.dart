import 'package:flutter/material.dart';
import 'package:rutio/features/statistics/presentation/v3/models/statistics_v3_view_data.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';

Future<void> showStatisticsV3RewardBreakdownSheet(
  BuildContext context, {
  required AppLocalizations l10n,
  required StatisticsV3RewardBreakdown breakdown,
  required int totalXp,
  required int totalAmber,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.22),
    builder: (sheetContext) {
      final visibleRows = breakdown.visibleRows;
      final hasRows = visibleRows.isNotEmpty;

      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 420,
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.78,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F1E6),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.62),
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 34,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8A7D6D).withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.statisticsV3RewardBreakdownTitle,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2F261E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.statisticsV3RewardBreakdownSubtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6E6256),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (!hasRows) ...[
                      Text(
                        l10n.statisticsV3RewardBreakdownEmpty,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF7E7265),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      for (final row in visibleRows) ...[
                        _BreakdownRow(
                          label: _sourceLabel(row.source, l10n),
                          value: _rewardPairText(
                            xp: row.xp,
                            amber: row.amber,
                            xpLabel: l10n.statisticsV3SummaryXpLabel,
                            amberLabel: l10n.statisticsV3SummaryAmberLabel,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                    Container(
                      height: 1,
                      color: const Color(0x33A69581),
                    ),
                    const SizedBox(height: 10),
                    _BreakdownRow(
                      label: l10n.statisticsV3RewardBreakdownTotal,
                      value: _rewardPairText(
                        xp: totalXp,
                        amber: totalAmber,
                        xpLabel: l10n.statisticsV3SummaryXpLabel,
                        amberLabel: l10n.statisticsV3SummaryAmberLabel,
                      ),
                      isTotal: true,
                    ),
                    if (breakdown.hasUnavailableLevelUpAttribution) ...[
                      const SizedBox(height: 10),
                      Text(
                        l10n.statisticsV3RewardBreakdownLevelUpFootnote,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xCC7D7266),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

String _sourceLabel(
  StatisticsV3RewardBreakdownSource source,
  AppLocalizations l10n,
) {
  switch (source) {
    case StatisticsV3RewardBreakdownSource.habits:
      return l10n.statisticsV3RewardBreakdownHabits;
    case StatisticsV3RewardBreakdownSource.diary:
      return l10n.statisticsV3RewardBreakdownDiary;
    case StatisticsV3RewardBreakdownSource.achievements:
      return l10n.statisticsV3RewardBreakdownAchievements;
    case StatisticsV3RewardBreakdownSource.levelUps:
      return l10n.statisticsV3RewardBreakdownLevelUps;
  }
}

String _rewardPairText({
  required int xp,
  required int amber,
  required String xpLabel,
  required String amberLabel,
}) {
  return '+$xp $xpLabel · +$amber $amberLabel';
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      fontSize: 14,
      color: const Color(0xFF3A2E25),
      fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
    );
    final valueStyle = TextStyle(
      fontSize: 13,
      color: const Color(0xFF4D4034),
      fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
    );

    return Row(
      children: [
        Expanded(child: Text(label, style: labelStyle)),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: valueStyle,
          ),
        ),
      ],
    );
  }
}
