import 'package:flutter/material.dart';

class StatsBarPoint {
  final String label;
  final double value;
  final bool isActive;

  const StatsBarPoint({
    required this.label,
    required this.value,
    required this.isActive,
  });
}

class StatsWeeklyBarChartCard extends StatelessWidget {
  const StatsWeeklyBarChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.points,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final List<StatsBarPoint> points;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final maxValue = points.isEmpty
        ? 1.0
        : points
            .map((e) => e.value)
            .reduce((a, b) => a > b ? a : b)
            .clamp(1.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8B8B8B),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 98,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: points.map((p) {
                final h = (p.value / maxValue).clamp(0.0, 1.0);
                return Expanded(
                  child: _Bar(
                    label: p.label,
                    heightFactor: h,
                    isActive: p.isActive,
                    accent: accent,
                    valueText: p.isActive ? p.value.toStringAsFixed(0) : null,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.label,
    required this.heightFactor,
    required this.isActive,
    required this.accent,
    this.valueText,
  });

  final String label;
  final double heightFactor;
  final bool isActive;
  final Color accent;
  final String? valueText;

  @override
  Widget build(BuildContext context) {
    const inactive = Color(0xFFEDEDED);
    const barWidth = 18.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: 18,
            child: Center(
              child: valueText == null
                  ? const SizedBox.shrink()
                  : Text(
                      valueText!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: barWidth,
                height: 70 * heightFactor,
                decoration: BoxDecoration(
                  color: isActive ? null : inactive,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(9),
                    bottom: Radius.circular(6),
                  ),
                  gradient: isActive
                      ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            accent.withValues(alpha: 0.95),
                            accent.withValues(alpha: 0.55),
                          ],
                        )
                      : null,
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.25),
                            blurRadius: 14,
                            offset: const Offset(0, 10),
                          )
                        ]
                      : const [],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF8B8B8B),
            ),
          ),
        ],
      ),
    );
  }
}
