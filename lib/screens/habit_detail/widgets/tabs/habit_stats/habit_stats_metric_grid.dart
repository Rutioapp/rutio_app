import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../l10n/l10n.dart';
import 'habit_stats_helpers.dart';
import 'habit_stats_models.dart';

class HabitStatsMetricGrid extends StatelessWidget {
  final HabitStatsShellData shellData;

  const HabitStatsMetricGrid({
    super.key,
    required this.shellData,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = shellData.isCheckHabit
        ? _checkMetricItems(context, shellData)
        : _countMetricItems(context, shellData);

    return GridView.builder(
      key: Key(
        shellData.isCheckHabit
            ? 'habit_stats_check_metric_grid'
            : 'habit_stats_count_metric_grid',
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.94,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (context, index) => _MetricCard(metric: metrics[index]),
    );
  }
}

List<_MetricItem> _checkMetricItems(BuildContext context, HabitStatsShellData shellData) {
  final l10n = context.l10n;
  final goalValue = _goalValueLabel(context, shellData.weeklyTarget);
  return <_MetricItem>[
    _MetricItem(
      icon: Icons.gps_fixed_rounded,
      title: l10n.habitConfigGoalSection,
      value: goalValue,
      subtitle: l10n.habitStatsPerWeek,
      iconColor: const Color(0xFF5A3B23),
    ),
    _MetricItem(
      icon: Icons.check_circle_outline_rounded,
      title: l10n.habitStatsMetricCompleted,
      value: '${shellData.weeklyCompleted}/${shellData.weeklyTarget}',
      subtitle: l10n.habitStatsThisWeek,
      iconColor: const Color(0xFF5A3B23),
    ),
    _MetricItem(
      icon: Icons.trending_up_rounded,
      title: l10n.habitStatsMetricConsistency,
      value: '${shellData.weeklyConsistencyPct}%',
      subtitle: l10n.habitStatsMetricCompletion,
      iconColor: const Color(0xFF5B975A),
      valueColor: const Color(0xFF4E7D35),
    ),
    _MetricItem(
      icon: Icons.schedule_rounded,
      title: l10n.statisticsV3BestMomentCardTitle,
      value: shellData.bestMomentLabel,
      subtitle: l10n.statisticsV3BestMomentSubtitle,
      iconColor: const Color(0xFF4E7D35),
      bestMomentSlot: shellData.bestMomentSlot,
      useBestMomentVisual: shellData.hasBestMomentData,
    ),
  ];
}

List<_MetricItem> _countMetricItems(BuildContext context, HabitStatsShellData shellData) {
  final l10n = context.l10n;
  final summary = buildCountMetricSummary(shellData);
  return <_MetricItem>[
    _MetricItem(
      icon: Icons.flag_rounded,
      title: l10n.habitStatsCountObjectiveTitle,
      value: formatCountMetricValue(summary.dailyTarget, unitLabel: summary.unitLabel),
      subtitle: _countPerDayLabel(context),
      iconColor: const Color(0xFF5A3B23),
    ),
    _MetricItem(
      icon: Icons.water_drop_rounded,
      title: l10n.habitStatsCountVolumeTitle,
      value: formatCountMetricValue(summary.weeklyTotal, unitLabel: summary.unitLabel),
      subtitle: l10n.habitStatsThisWeek,
      iconColor: const Color(0xFF3E7B7A),
    ),
    _MetricItem(
      icon: Icons.bar_chart_rounded,
      title: l10n.habitStatsCountDailyAverage,
      value: formatCountMetricValue(summary.dailyAverage, unitLabel: summary.unitLabel),
      subtitle: _countAverageLabel(context),
      iconColor: const Color(0xFF5B975A),
    ),
    _MetricItem(
      icon: Icons.check_circle_outline_rounded,
      title: l10n.habitStatsMetricCompletion,
      value: '${summary.completionPct}%',
      subtitle: _countOfGoalLabel(context),
      iconColor: const Color(0xFF8A5B2C),
    ),
  ];
}

class _MetricItem {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color iconColor;
  final Color? valueColor;
  final HabitStatsBestMomentSlot? bestMomentSlot;
  final bool useBestMomentVisual;

  const _MetricItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.iconColor,
    this.valueColor,
    this.bestMomentSlot,
    this.useBestMomentVisual = false,
  });
}

class _MetricCard extends StatelessWidget {
  final _MetricItem metric;

  const _MetricCard({
    required this.metric,
  });

  static const _cream = Color(0xFFFDFBF7);
  static const _border = Color(0xFFE9E3D9);
  static const _text = Color(0xFF2F251C);
  static const _muted = Color(0xFF746A60);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cream.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MetricHeader(metric: metric),
          const SizedBox(height: 8),
          Expanded(
            child: metric.useBestMomentVisual
                ? _BestMomentMetricBody(metric: metric)
                : _StandardMetricBody(metric: metric),
          ),
        ],
      ),
    );
  }
}

class _MetricHeader extends StatelessWidget {
  const _MetricHeader({
    required this.metric,
  });

  final _MetricItem metric;

  @override
  Widget build(BuildContext context) {
    final chevronSize = 24.0;
    return SizedBox(
      height: chevronSize,
      child: Row(
        children: [
          Container(
            width: 23,
            height: 23,
            decoration: BoxDecoration(
              color: metric.iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(metric.icon, color: metric.iconColor, size: 15),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              metric.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14.2,
                height: 1,
                fontWeight: FontWeight.w700,
                color: _MetricCard._text,
              ),
            ),
          ),
          const SizedBox(width: 5),
        ],
      ),
    );
  }
}

class _StandardMetricBody extends StatelessWidget {
  const _StandardMetricBody({
    required this.metric,
  });

  final _MetricItem metric;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              metric.value,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                height: 0.95,
                fontWeight: FontWeight.w800,
                color: metric.valueColor ?? _MetricCard._text,
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            metric.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.2,
              height: 1,
              fontWeight: FontWeight.w500,
              color: _MetricCard._muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _BestMomentMetricBody extends StatelessWidget {
  const _BestMomentMetricBody({
    required this.metric,
  });

  final _MetricItem metric;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTight = constraints.maxHeight < 58;
        if (isTight) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _BestMomentPill(
                    slot: metric.bestMomentSlot ?? HabitStatsBestMomentSlot.unknown,
                    compact: true,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      metric.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15.5,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        color: _MetricCard._text,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                metric.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 9.6,
                  height: 1,
                  fontWeight: FontWeight.w500,
                  color: _MetricCard._muted,
                ),
              ),
            ],
          );
        }

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _BestMomentPill(
                slot: metric.bestMomentSlot ?? HabitStatsBestMomentSlot.unknown,
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  metric.value,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    height: 0.95,
                    fontWeight: FontWeight.w800,
                    color: _MetricCard._text,
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                metric.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11.2,
                  height: 1,
                  fontWeight: FontWeight.w500,
                  color: _MetricCard._muted,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BestMomentPill extends StatelessWidget {
  const _BestMomentPill({
    required this.slot,
    this.compact = false,
  });

  final HabitStatsBestMomentSlot slot;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final pillWidth = compact ? 46.0 : 106.0;
    final pillHeight = compact ? 24.0 : 55.0;
    final iconSize = compact ? 13.0 : 16.0;

    if (slot == HabitStatsBestMomentSlot.unknown) {
      return Container(
        width: pillWidth,
        height: pillHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: const Color(0xFFF2F2F2),
        ),
        child: Icon(
          Icons.schedule_rounded,
          size: iconSize,
          color: const Color(0xFF8E8B86),
        ),
      );
    }

    return Container(
      width: pillWidth,
      height: pillHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _paletteFor(slot),
        ),
      ),
      child: CustomPaint(
        painter: _BestMomentPainter(slot),
      ),
    );
  }

  List<Color> _paletteFor(HabitStatsBestMomentSlot slot) {
    switch (slot) {
      case HabitStatsBestMomentSlot.morning:
        return const [Color(0xFFFFF5E8), Color(0xFFFFE8CA)];
      case HabitStatsBestMomentSlot.noon:
        return const [Color(0xFFFFF8DF), Color(0xFFFFEDB7)];
      case HabitStatsBestMomentSlot.afternoon:
        return const [Color(0xFFFFF5D8), Color(0xFFFFDCA6)];
      case HabitStatsBestMomentSlot.night:
        return const [Color(0xFFEDEEFF), Color(0xFFD7DAF6)];
      case HabitStatsBestMomentSlot.unknown:
        return const [Color(0xFFF2F2F2), Color(0xFFEAEAEA)];
    }
  }
}

class _BestMomentPainter extends CustomPainter {
  const _BestMomentPainter(this.slot);

  static const _gold = Color(0xFFE2A13B);
  static const _night = Color(0xFF7077B8);

  final HabitStatsBestMomentSlot slot;

  @override
  void paint(Canvas canvas, Size size) {
    switch (slot) {
      case HabitStatsBestMomentSlot.morning:
        _paintMorning(canvas, size);
        break;
      case HabitStatsBestMomentSlot.noon:
        _paintNoon(canvas, size);
        break;
      case HabitStatsBestMomentSlot.afternoon:
        _paintAfternoon(canvas, size);
        break;
      case HabitStatsBestMomentSlot.night:
        _paintNight(canvas, size);
        break;
      case HabitStatsBestMomentSlot.unknown:
        break;
    }
  }

  void _paintMorning(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF2A65B).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final center = Offset(size.width / 2, size.height * 0.62);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.height * 0.22),
      math.pi,
      math.pi,
      false,
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.30, size.height * 0.68),
      Offset(size.width * 0.70, size.height * 0.68),
      paint,
    );
    _paintRays(canvas, size, center.translate(0, -size.height * 0.03));
  }

  void _paintNoon(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    _paintSun(canvas, center, size.height * 0.13);
    _paintRays(canvas, size, center, radius: size.height * 0.23);
  }

  void _paintAfternoon(Canvas canvas, Size size) {
    final hill = Paint()
      ..color = const Color(0xFFF3C27A).withValues(alpha: 0.30)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.30,
        size.height * 0.60,
        size.width * 0.52,
        size.height * 0.74,
      )
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.90,
        size.width,
        size.height * 0.72,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, hill);
    final center = Offset(size.width / 2, size.height * 0.45);
    _paintSun(canvas, center, size.height * 0.12);
    _paintRays(canvas, size, center, radius: size.height * 0.22);
  }

  void _paintNight(Canvas canvas, Size size) {
    final moon = Paint()
      ..color = _night
      ..style = PaintingStyle.fill;
    final center = Offset(size.width * 0.50, size.height * 0.48);
    canvas.drawCircle(center, size.height * 0.18, moon);
    canvas.drawCircle(
      center.translate(size.height * 0.07, -size.height * 0.06),
      size.height * 0.18,
      Paint()
        ..color = const Color(0xFFEDEEFF)
        ..style = PaintingStyle.fill,
    );
    final star = Paint()
      ..color = _night.withValues(alpha: 0.78)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.26, size.height * 0.42), 1.4, star);
    canvas.drawCircle(Offset(size.width * 0.72, size.height * 0.40), 1.2, star);
    canvas.drawCircle(Offset(size.width * 0.76, size.height * 0.61), 1.5, star);
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
    final rayRadius = radius ?? size.height * 0.24;
    final paint = Paint()
      ..color = _gold.withValues(alpha: 0.80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.45
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i += 1) {
      final angle = (math.pi * 2 / 8) * i;
      final start = Offset(
        center.dx + math.cos(angle) * rayRadius * 0.68,
        center.dy + math.sin(angle) * rayRadius * 0.68,
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

String _goalValueLabel(BuildContext context, int weeklyTarget) {
  if (weeklyTarget <= 0) return '0';
  final isSpanish = _isSpanish(context);
  if (weeklyTarget == 1) return isSpanish ? '1 vez' : '1 time';
  return isSpanish ? '$weeklyTarget veces' : '$weeklyTarget times';
}

String _countPerDayLabel(BuildContext context) {
  return _isSpanish(context) ? 'Por día' : 'Per day';
}

String _countAverageLabel(BuildContext context) {
  return _isSpanish(context) ? 'Promedio' : 'Average';
}

String _countOfGoalLabel(BuildContext context) {
  return _isSpanish(context) ? 'Del objetivo' : 'Of goal';
}

bool _isSpanish(BuildContext context) {
  return Localizations.localeOf(context).languageCode.toLowerCase() == 'es';
}

