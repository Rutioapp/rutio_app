import 'package:flutter/material.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/weekly_report.dart';
import '../weekly_report_visuals.dart';

class WeeklyReportRecommendationCard extends StatelessWidget {
  const WeeklyReportRecommendationCard(
      {super.key,
      required this.recommendation,
      required this.habit,
      required this.onReview});
  final WeeklyReportRecommendation recommendation;
  final WeeklyReportHabit? habit;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final current = recommendation.currentConfig['schedule'];
    final proposed = recommendation.proposedPatch['proposed'];
    final currentCount = current is Map ? current['timesPerWeek'] : null;
    final proposedSchedule = proposed is Map ? proposed['schedule'] : null;
    final proposedCount =
        proposedSchedule is Map ? proposedSchedule['timesPerWeek'] : null;
    if (recommendation.type != WeeklyReportRecommendationType.reduceFrequency ||
        currentCount is! num ||
        proposedCount is! num) {
      return const SizedBox.shrink();
    }
    final name = recommendation.habitName ??
        habit?.name ??
        l10n.weeklyReportRecommendationUnavailableHabit;
    final detail = habit == null
        ? l10n.weeklyReportRecommendationUnavailable
        : l10n.weeklyReportRecommendationReason(
            name, habit!.completedCount, habit!.scheduledCount);
    return Semantics(
      container: true,
      label:
          '${l10n.weeklyReportRecommendationTitle}. $name. ${l10n.weeklyReportRecommendationAdjustment(currentCount.toInt(), proposedCount.toInt())}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: WeeklyReportVisuals.cardDecoration(
                color: const Color(0xFFFFF5E8),
                borderColor: const Color(0xFFF0D7B8),
                radius: 14),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l10n.weeklyReportRecommendationTitle,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: WeeklyReportVisuals.text)),
              const SizedBox(height: 5),
              Row(children: [
                Text(recommendation.emoji ?? habit?.emoji ?? '•',
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 7),
                Expanded(
                    child: Text(name,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: WeeklyReportVisuals.text)))
              ]),
              const SizedBox(height: 3),
              Text(detail,
                  style: const TextStyle(
                      fontSize: 11, color: WeeklyReportVisuals.mutedText)),
              const SizedBox(height: 3),
              Text(
                  l10n.weeklyReportRecommendationAdjustment(
                      currentCount.toInt(), proposedCount.toInt()),
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: WeeklyReportVisuals.text)),
              const SizedBox(height: 6),
              Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                      onPressed: habit == null || recommendation.habitId == null
                          ? null
                          : onReview,
                      style: TextButton.styleFrom(
                          minimumSize: const Size(44, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 13),
                          foregroundColor: WeeklyReportVisuals.text,
                          backgroundColor: const Color(0xFFF4E6D4),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side:
                                  const BorderSide(color: Color(0xFFE2C7A7)))),
                      child: Text(l10n.weeklyReportRecommendationCta))),
            ]),
          ),
          const Positioned(
              right: -12,
              bottom: -26,
              child: WeeklyReportBotanicalDecoration()),
        ]),
      ),
    );
  }
}
