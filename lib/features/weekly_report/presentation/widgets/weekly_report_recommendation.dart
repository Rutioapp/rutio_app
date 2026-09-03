import 'package:flutter/material.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/weekly_report.dart';

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
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: const Color(0xFFFDFBF7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE9E3D9))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.weeklyReportRecommendationTitle,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2F251C))),
          const SizedBox(height: 5),
          Row(children: [
            Text(recommendation.emoji ?? habit?.emoji ?? '•',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 7),
            Expanded(
                child: Text(name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)))
          ]),
          const SizedBox(height: 3),
          Text(detail,
              style: const TextStyle(fontSize: 11, color: Color(0xFF746A60))),
          const SizedBox(height: 3),
          Text(
              l10n.weeklyReportRecommendationAdjustment(
                  currentCount.toInt(), proposedCount.toInt()),
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5F554A))),
          const SizedBox(height: 6),
          Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                  onPressed: habit == null || recommendation.habitId == null
                      ? null
                      : onReview,
                  style: TextButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 8)),
                  child: Text(l10n.weeklyReportRecommendationCta))),
        ]),
      ),
    );
  }
}
