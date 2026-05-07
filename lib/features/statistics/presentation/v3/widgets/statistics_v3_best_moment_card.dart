import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rutio/features/statistics/presentation/v3/models/statistics_v3_view_data.dart';
import 'package:rutio/l10n/l10n.dart';

class StatisticsV3BestMomentCard extends StatelessWidget {
  const StatisticsV3BestMomentCard({
    super.key,
    required this.title,
    required this.insight,
    required this.fallback,
  });

  static const _cream = Color(0xFFFDFBF7);
  static const _border = Color(0xFFE9E3D9);
  static const _text = Color(0xFF2F251C);
  static const _muted = Color(0xFF746A60);
  static const _green = Color(0xFF4E7D35);
  static const _gold = Color(0xFFE2A13B);
  static const _night = Color(0xFF7077B8);

  final String title;
  final StatisticsV3BestMomentInsight insight;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 14),
      decoration: BoxDecoration(
        color: _cream.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 172;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BestMomentHeader(title: title, compact: compact),
              SizedBox(height: compact ? 6 : 7),
              Expanded(
                child: insight.hasData
                    ? _BestMomentBody(
                        insight: insight,
                        subtitle: l10n.statisticsV3BestMomentSubtitle,
                        compact: compact,
                      )
                    : _BestMomentEmptyState(message: fallback),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BestMomentHeader extends StatelessWidget {
  const _BestMomentHeader({
    required this.title,
    required this.compact,
  });

  final String title;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final badgeSize = compact ? 21.0 : 23.0;
    final chevronSize = compact ? 24.0 : 26.0;
    return SizedBox(
      height: chevronSize,
      child: Row(
        children: [
          Container(
            width: badgeSize,
            height: badgeSize,
            decoration: BoxDecoration(
              color: StatisticsV3BestMomentCard._green.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.schedule_rounded,
              size: compact ? 14 : 15,
              color: StatisticsV3BestMomentCard._green,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                maxLines: 1,
                style: TextStyle(
                  fontSize: compact ? 13.4 : 14.2,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: StatisticsV3BestMomentCard._text,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: chevronSize,
            height: chevronSize,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.64),
              shape: BoxShape.circle,
              border: Border.all(color: StatisticsV3BestMomentCard._border),
            ),
            child: Icon(
              Icons.chevron_right_rounded,
              size: compact ? 18 : 19,
              color: StatisticsV3BestMomentCard._text.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class _BestMomentBody extends StatelessWidget {
  const _BestMomentBody({
    required this.insight,
    required this.subtitle,
    required this.compact,
  });

  final StatisticsV3BestMomentInsight insight;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: compact ? 96 : 106,
            height: compact ? 50 : 55,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _paletteFor(insight.slot),
              ),
            ),
            child: CustomPaint(
              painter: _BestMomentPainter(insight.slot),
            ),
          ),
          SizedBox(height: compact ? 11 : 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              insight.label,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compact ? 24 : 26,
                height: 0.95,
                fontWeight: FontWeight.w800,
                color: StatisticsV3BestMomentCard._text,
              ),
            ),
          ),
          SizedBox(height: compact ? 6 : 7),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 11.3 : 12,
              height: 1,
              fontWeight: FontWeight.w500,
              color: StatisticsV3BestMomentCard._muted,
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _paletteFor(StatisticsV3BestMomentSlot slot) {
    switch (slot) {
      case StatisticsV3BestMomentSlot.morning:
        return const [Color(0xFFFFF5E8), Color(0xFFFFE8CA)];
      case StatisticsV3BestMomentSlot.noon:
        return const [Color(0xFFFFF8DF), Color(0xFFFFEDB7)];
      case StatisticsV3BestMomentSlot.afternoon:
        return const [Color(0xFFFFF5D8), Color(0xFFFFDCA6)];
      case StatisticsV3BestMomentSlot.night:
        return const [Color(0xFFEDEEFF), Color(0xFFD7DAF6)];
    }
  }
}

class _BestMomentPainter extends CustomPainter {
  const _BestMomentPainter(this.slot);

  final StatisticsV3BestMomentSlot slot;

  @override
  void paint(Canvas canvas, Size size) {
    switch (slot) {
      case StatisticsV3BestMomentSlot.morning:
        _paintMorning(canvas, size);
        break;
      case StatisticsV3BestMomentSlot.noon:
        _paintNoon(canvas, size);
        break;
      case StatisticsV3BestMomentSlot.afternoon:
        _paintAfternoon(canvas, size);
        break;
      case StatisticsV3BestMomentSlot.night:
        _paintNight(canvas, size);
        break;
    }
  }

  void _paintMorning(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF2A65B).withValues(alpha: 0.58)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final center = Offset(size.width / 2, size.height * 0.61);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.height * 0.28),
      math.pi,
      math.pi,
      false,
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.28, size.height * 0.67),
      Offset(size.width * 0.72, size.height * 0.67),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.40, size.height * 0.82),
      Offset(size.width * 0.60, size.height * 0.82),
      paint..color = paint.color.withValues(alpha: 0.38),
    );
    _paintRays(canvas, size, center.translate(0, -size.height * 0.04));
  }

  void _paintNoon(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    _paintSun(canvas, center, size.height * 0.17);
    _paintRays(canvas, size, center, radius: size.height * 0.29);
  }

  void _paintAfternoon(Canvas canvas, Size size) {
    final hill = Paint()
      ..color = const Color(0xFFF3C27A).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, size.height * 0.76)
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.58,
        size.width * 0.52,
        size.height * 0.73,
      )
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.90,
        size.width,
        size.height * 0.70,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, hill);
    final center = Offset(size.width / 2, size.height * 0.48);
    _paintSun(canvas, center, size.height * 0.16);
    _paintRays(canvas, size, center, radius: size.height * 0.28);
  }

  void _paintNight(Canvas canvas, Size size) {
    final moon = Paint()
      ..color = StatisticsV3BestMomentCard._night
      ..style = PaintingStyle.fill;
    final center = Offset(size.width * 0.50, size.height * 0.48);
    canvas.drawCircle(center, size.height * 0.21, moon);
    canvas.drawCircle(
      center.translate(size.height * 0.09, -size.height * 0.08),
      size.height * 0.21,
      Paint()
        ..color = const Color(0xFFEDEEFF)
        ..style = PaintingStyle.fill,
    );
    final star = Paint()
      ..color = StatisticsV3BestMomentCard._night.withValues(alpha: 0.78)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.24, size.height * 0.42), 2, star);
    canvas.drawCircle(Offset(size.width * 0.72, size.height * 0.38), 1.8, star);
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.62), 2.1, star);
  }

  void _paintSun(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF6C55A), Color(0xFFE89A1F)],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  void _paintRays(
    Canvas canvas,
    Size size,
    Offset center, {
    double? radius,
  }) {
    final rayRadius = radius ?? size.height * 0.34;
    final paint = Paint()
      ..color = StatisticsV3BestMomentCard._gold.withValues(alpha: 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i += 1) {
      final angle = (math.pi * 2 / 8) * i;
      final start = Offset(
        center.dx + math.cos(angle) * rayRadius * 0.66,
        center.dy + math.sin(angle) * rayRadius * 0.66,
      );
      final end = Offset(
        center.dx + math.cos(angle) * rayRadius,
        center.dy + math.sin(angle) * rayRadius,
      );
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BestMomentPainter oldDelegate) {
    return oldDelegate.slot != slot;
  }
}

class _BestMomentEmptyState extends StatelessWidget {
  const _BestMomentEmptyState({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11.5,
          height: 1.16,
          fontWeight: FontWeight.w500,
          color: StatisticsV3BestMomentCard._muted,
        ),
      ),
    );
  }
}
