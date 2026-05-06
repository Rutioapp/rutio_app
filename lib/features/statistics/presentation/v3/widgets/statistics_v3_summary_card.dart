import 'package:flutter/material.dart';

class StatisticsV3SummaryCard extends StatelessWidget {
  const StatisticsV3SummaryCard({
    super.key,
    required this.title,
    required this.completedLabel,
    required this.completedHabits,
    required this.xpLabel,
    required this.xpGained,
    required this.amberLabel,
    required this.amberGained,
  });

  final String title;
  final String completedLabel;
  final int completedHabits;
  final String xpLabel;
  final int xpGained;
  final String amberLabel;
  final int amberGained;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFDDEEF9), Color(0xFFF6F1E5)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.58)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C241B),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _SummaryMetric(
                icon: Icons.check_circle_rounded,
                iconColor: const Color(0xFF5D965A),
                value: '$completedHabits',
                label: completedLabel,
              ),
              const _VerticalSeparator(),
              _SummaryMetric(
                icon: Icons.auto_awesome_rounded,
                iconColor: const Color(0xFFC58D2A),
                value: '+$xpGained',
                label: xpLabel,
              ),
              const _VerticalSeparator(),
              _SummaryMetric(
                icon: Icons.hexagon_rounded,
                iconColor: const Color(0xFFB88937),
                value: '+$amberGained',
                label: amberLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
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
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 25),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 29,
              height: 1.0,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2E241A),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF5F554A),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalSeparator extends StatelessWidget {
  const _VerticalSeparator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 76,
      color: const Color(0x33B8A98F),
    );
  }
}
