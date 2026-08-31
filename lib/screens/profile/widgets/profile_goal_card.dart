import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import 'pill_button.dart';
import 'progress_bar.dart';
import 'section_card.dart';

class ProfileGoalCard extends StatelessWidget {
  const ProfileGoalCard({
    super.key,
    required this.accent,
    required this.goalText,
    required this.weeklyConsistencyPct,
    required this.onEdit,
  });

  final Color accent;
  final String? goalText;
  final int weeklyConsistencyPct;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final trimmedGoal = (goalText ?? '').trim();
    final hasGoal = trimmedGoal.isNotEmpty;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.flag_outlined, color: accent, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.editProfileGoalSectionTitle,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2E241A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PillButton(
                accent: accent,
                icon: hasGoal ? Icons.edit_rounded : Icons.add_rounded,
                label: hasGoal
                    ? l10n.profileEditButton
                    : l10n.profileGoalAddAction,
                onTap: onEdit,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasGoal)
            Text(
              trimmedGoal,
              style: const TextStyle(
                fontSize: 14.5,
                height: 1.35,
                color: Color(0xFF4F4A42),
              ),
            )
          else
            Text(
              l10n.profileGoalEmptyTitle,
              style: const TextStyle(
                fontSize: 14.5,
                height: 1.35,
                color: Color(0xFF4F4A42),
              ),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.profileGoalWeeklyProgressLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6C6257),
                  ),
                ),
              ),
              Text(
                '$weeklyConsistencyPct%',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ProgressBar(
            value: (weeklyConsistencyPct / 100).clamp(0.0, 1.0),
            color: accent,
            height: 9,
          ),
        ],
      ),
    );
  }
}
