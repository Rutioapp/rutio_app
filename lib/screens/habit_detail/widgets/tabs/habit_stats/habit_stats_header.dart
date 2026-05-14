import 'package:flutter/material.dart';

class HabitStatsHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String typeLabel;
  final Color familyColor;

  const HabitStatsHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.typeLabel,
    required this.familyColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.08,
                color: const Color(0xFF1D1A16),
              ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF7A6853),
                    ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: familyColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: familyColor.withValues(alpha: 0.28)),
              ),
              child: Text(
                typeLabel,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: const Color(0xFF4C4034),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
