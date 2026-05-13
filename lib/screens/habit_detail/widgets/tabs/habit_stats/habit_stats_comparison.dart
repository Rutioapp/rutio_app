import 'package:flutter/material.dart';

import '../../../../../utils/app_theme.dart';
import 'habit_stats_helpers.dart';

class HabitStatsComparisonCard extends StatelessWidget {
  const HabitStatsComparisonCard({
    super.key,
    required this.title,
    required this.mainText,
    required this.subtitle,
    required this.trendText,
    required this.trendPositive,
    required this.isCountHabit,
  });

  final String title;
  final String mainText;
  final String subtitle;
  final String trendText;
  final bool trendPositive;
  final bool isCountHabit;

  @override
  Widget build(BuildContext context) {
    final trendColor =
        trendPositive ? const Color(0xFF4E8B51) : const Color(0xFFB25A44);

    return HabitStatsSurfaceCard(
      child: SizedBox(
        height: 110,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.bottomRight,
              child: Opacity(
                opacity: 0.22,
                child: SizedBox(
                  width: 180,
                  height: 52,
                  child: CustomPaint(
                    painter: _HabitStatsMiniTrendPainter(color: trendColor),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFF4EEE5),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    isCountHabit
                        ? Icons.emoji_events_outlined
                        : Icons.trending_up_rounded,
                    color: isCountHabit
                        ? const Color(0xFFBB7A1F)
                        : const Color(0xFF5A8B57),
                    size: 31,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.sansFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF23201C),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mainText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.serifFamily,
                          fontSize: 47,
                          height: 0.95,
                          letterSpacing: -0.5,
                          color: Color(0xFF1A1714),
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.sansFamily,
                          fontSize: 15,
                          color: Color(0xFF4E4B46),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  trendText,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: AppTextStyles.sansFamily,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: trendColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitStatsMiniTrendPainter extends CustomPainter {
  const _HabitStatsMiniTrendPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;

    final path = Path()
      ..moveTo(0, size.height * 0.84)
      ..lineTo(size.width * 0.20, size.height * 0.52)
      ..lineTo(size.width * 0.38, size.height * 0.64)
      ..lineTo(size.width * 0.56, size.height * 0.34)
      ..lineTo(size.width * 0.74, size.height * 0.46)
      ..lineTo(size.width * 0.94, size.height * 0.20);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HabitStatsMiniTrendPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
