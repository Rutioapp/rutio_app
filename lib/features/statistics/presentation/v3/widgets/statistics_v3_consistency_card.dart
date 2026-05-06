import 'package:flutter/material.dart';

class StatisticsV3ConsistencyCard extends StatelessWidget {
  const StatisticsV3ConsistencyCard({
    super.key,
    required this.title,
    required this.activeDaysLabel,
    required this.completionLabel,
    required this.activeDays,
    required this.totalDays,
    required this.completionPct,
  });

  final String title;
  final String activeDaysLabel;
  final String completionLabel;
  final int activeDays;
  final int totalDays;
  final int completionPct;

  @override
  Widget build(BuildContext context) {
    final clampedPct = completionPct.clamp(0, 100);
    final progress = clampedPct / 100;

    return Container(
      constraints: const BoxConstraints(minHeight: 150),
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9E3D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2F251C),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 54,
                height: 54,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 6,
                      color: const Color(0xFF739E71),
                      backgroundColor: const Color(0xFFE6E8E2),
                    ),
                    Text(
                      '$clampedPct%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4E4438),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  '$activeDays/$totalDays\n$activeDaysLabel',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4F463A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$clampedPct% $completionLabel',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E251C),
            ),
          ),
        ],
      ),
    );
  }
}
