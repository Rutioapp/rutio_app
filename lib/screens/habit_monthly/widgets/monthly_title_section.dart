import 'package:flutter/material.dart';

import 'package:rutio/utils/app_theme.dart';

class MonthlyTitleSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const MonthlyTitleSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.welcomeTitle.copyWith(
                  fontSize: 45,
                  color: const Color(0xFF242018),
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: (textTheme.bodySmall ?? const TextStyle()).copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black.withValues(alpha: 0.58),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _MonthNavButton(
            icon: Icons.chevron_left_rounded, onTap: onPreviousMonth),
        const SizedBox(width: 8),
        _MonthNavButton(icon: Icons.chevron_right_rounded, onTap: onNextMonth),
      ],
    );
  }
}

class _MonthNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MonthNavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.62)),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Colors.black.withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }
}
