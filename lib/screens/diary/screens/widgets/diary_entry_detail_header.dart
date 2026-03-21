import 'package:flutter/material.dart';

class DiaryEntryDetailHeader extends StatelessWidget {
  const DiaryEntryDetailHeader({
    super.key,
    required this.moodEmoji,
    required this.familyColor,
    required this.title,
    required this.subtitle,
  });

  final String moodEmoji;
  final Color familyColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            shape: BoxShape.circle,
            border: Border.all(
              color: familyColor.withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            moodEmoji,
            style: const TextStyle(fontSize: 22, height: 1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF2A2119),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF8D7966),
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
