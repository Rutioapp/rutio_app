import 'package:flutter/material.dart';

import 'package:rutio/l10n/l10n.dart';

class WeeklyViewMenuSheet extends StatelessWidget {
  final VoidCallback onDailyTap;
  final VoidCallback onWeeklyTap;
  final VoidCallback onMonthlyTap;

  const WeeklyViewMenuSheet({
    super.key,
    required this.onDailyTap,
    required this.onWeeklyTap,
    required this.onMonthlyTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6D4CFF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.view_module_rounded,
                    color: Color(0xFF6D4CFF),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.weeklyViewMenuTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          WeeklyViewOption(
            icon: Icons.today_rounded,
            title: l10n.weeklyViewMenuDailyTitle,
            subtitle: l10n.weeklyViewMenuDailySubtitle,
            color: Colors.blue,
            onTap: onDailyTap,
          ),
          WeeklyViewOption(
            icon: Icons.calendar_view_week_rounded,
            title: l10n.weeklyViewMenuWeeklyTitle,
            subtitle: l10n.weeklyViewMenuWeeklySubtitle,
            color: const Color(0xFF6D4CFF),
            isSelected: true,
            onTap: onWeeklyTap,
          ),
          WeeklyViewOption(
            icon: Icons.calendar_month_rounded,
            title: l10n.weeklyViewMenuMonthlyTitle,
            subtitle: l10n.weeklyViewMenuMonthlySubtitle,
            color: Colors.green,
            onTap: onMonthlyTap,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class WeeklyViewOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const WeeklyViewOption({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color:
                isSelected ? color.withValues(alpha: 0.08) : Colors.transparent,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? color : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: color,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
