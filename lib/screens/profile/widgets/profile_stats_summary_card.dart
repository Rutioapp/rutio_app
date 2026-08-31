import 'package:flutter/material.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/utils/app_theme.dart';

import 'section_card.dart';

class ProfileStatsSummaryCard extends StatelessWidget {
  const ProfileStatsSummaryCard({
    super.key,
    required this.title,
    required this.currentStreakDays,
    required this.bestStreakDays,
    required this.weeklyConsistencyPct,
    required this.activeDaysLabel,
    required this.activeDaysCount,
    required this.onTap,
  });

  final String title;
  final int currentStreakDays;
  final int bestStreakDays;
  final int weeklyConsistencyPct;
  final String activeDaysLabel;
  final int activeDaysCount;
  final VoidCallback onTap;

  static const double _radius = 18;
  static const double _tileGap = 10;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(_radius),
        onTap: onTap,
        child: SectionCard(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth = (constraints.maxWidth - _tileGap) / 2;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.insights_rounded,
                        size: 19,
                        color: AppColors.earth,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2E241A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: AppColors.earthSoft,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: _tileGap,
                    runSpacing: _tileGap,
                    children: [
                      SizedBox(
                        width: tileWidth,
                        child: _MetricTile(
                          icon: Icons.local_fire_department_outlined,
                          iconColor: const Color(0xFFC06A3A),
                          value: currentStreakDays.toString(),
                          label: l10n.achievementsCurrentStreakTitle,
                        ),
                      ),
                      SizedBox(
                        width: tileWidth,
                        child: _MetricTile(
                          icon: Icons.emoji_events_outlined,
                          iconColor: const Color(0xFFAA8130),
                          value: bestStreakDays.toString(),
                          label: l10n.habitStatsMetricBestStreak,
                        ),
                      ),
                      SizedBox(
                        width: tileWidth,
                        child: _MetricTile(
                          icon: Icons.check_circle_outline_rounded,
                          iconColor: const Color(0xFF5D965A),
                          value: '$weeklyConsistencyPct%',
                          label: l10n.statisticsV3ConsistencyCompletionLabel,
                        ),
                      ),
                      SizedBox(
                        width: tileWidth,
                        child: _MetricTile(
                          icon: Icons.calendar_month_outlined,
                          iconColor: AppColors.earth,
                          value: activeDaysCount.toString(),
                          label: activeDaysLabel,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF9F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7DED1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CircleIcon(
                color: iconColor,
                icon: icon,
                size: 24,
                iconSize: 12,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    height: 1.05,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF73685B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: 22,
                height: 1,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF2E241A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({
    required this.color,
    required this.icon,
    required this.size,
    required this.iconSize,
  });

  final Color color;
  final IconData icon;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: color,
      ),
    );
  }
}
