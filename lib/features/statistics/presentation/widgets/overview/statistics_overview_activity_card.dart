import 'package:flutter/material.dart';
import 'package:rutio/l10n/l10n.dart';

import '../../../domain/statistics_models.dart';
import 'statistics_overview_section_card.dart';

class StatisticsOverviewActivityCard extends StatelessWidget {
  const StatisticsOverviewActivityCard({
    super.key,
    required this.summary,
  });

  final StatisticsOverviewSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return StatisticsOverviewSectionCard(
      title: l10n.statisticsV2OverviewActivityTitle,
      subtitle: l10n.statisticsV2OverviewActivitySubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricLine(
                  label: l10n.statisticsV2OverviewHabitsWithProgress,
                  value: summary.habitsWithProgress.toString(),
                ),
              ),
              Expanded(
                child: _MetricLine(
                  label: l10n.statisticsV2OverviewActiveDays,
                  value: summary.daysWithActivity.toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActivityPill(
                label: l10n.statisticsV2OverviewCountGoalCompletedDays,
                value: summary.countGoalCompletedDays.toString(),
                tint: const Color(0xFFEAF6EE),
                textColor: const Color(0xFF2F6B4F),
              ),
              _ActivityPill(
                label: l10n.statisticsV2OverviewCountPartialDays,
                value: summary.countPartialProgressDays.toString(),
                tint: const Color(0xFFF8EED8),
                textColor: const Color(0xFF8B5A1F),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.statisticsV2OverviewActivityHint,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.64),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricLine extends StatelessWidget {
  const _MetricLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.black.withValues(alpha: 0.58),
          ),
        ),
      ],
    );
  }
}

class _ActivityPill extends StatelessWidget {
  const _ActivityPill({
    required this.label,
    required this.value,
    required this.tint,
    required this.textColor,
  });

  final String label;
  final String value;
  final Color tint;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 144),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
