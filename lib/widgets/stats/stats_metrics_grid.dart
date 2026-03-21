import 'package:flutter/material.dart';
import 'package:rutio/utils/app_theme.dart';

class StatsMetric {
  final String labelUpper;
  final String value;
  final String description;
  final IconData icon;
  final Color accent;

  const StatsMetric({
    required this.labelUpper,
    required this.value,
    required this.description,
    required this.icon,
    required this.accent,
  });
}

class StatsMetricsGrid extends StatefulWidget {
  const StatsMetricsGrid({
    super.key,
    required this.metrics,
  });

  final List<StatsMetric> metrics; // ideally 4

  @override
  State<StatsMetricsGrid> createState() => _StatsMetricsGridState();
}

class _StatsMetricsGridState extends State<StatsMetricsGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.metrics.take(4).toList();
    if (m.length < 4) return const SizedBox.shrink();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _AnimatedMetricCard(
                    metric: m[0], index: 0, controller: _c)),
            const SizedBox(width: 12),
            Expanded(
                child: _AnimatedMetricCard(
                    metric: m[1], index: 1, controller: _c)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _AnimatedMetricCard(
                    metric: m[2], index: 2, controller: _c)),
            const SizedBox(width: 12),
            Expanded(
                child: _AnimatedMetricCard(
                    metric: m[3], index: 3, controller: _c)),
          ],
        ),
      ],
    );
  }
}

class _AnimatedMetricCard extends StatelessWidget {
  const _AnimatedMetricCard({
    required this.metric,
    required this.index,
    required this.controller,
  });

  final StatsMetric metric;
  final int index;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final start = 0.08 * index;
    final end = (start + 0.45).clamp(0.0, 1.0);

    final opacity = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    final slide = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    ));

    final scale = Tween<double>(begin: 0.98, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ),
    );

    return FadeTransition(
      opacity: opacity,
      child: SlideTransition(
        position: slide,
        child: ScaleTransition(
          scale: scale,
          child: _MetricCard(metric: metric),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final StatsMetric metric;

  @override
  Widget build(BuildContext context) {
    final tint = metric.accent.withValues(alpha: 0.14);

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
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      metric.accent,
                      metric.accent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(metric.icon, color: metric.accent, size: 18),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            metric.value,
            style: const TextStyle(
              fontSize: 32,
              height: 1.0,
              fontFamily: AppTextStyles.serifFamily,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            metric.labelUpper.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.description,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8B8B8B),
            ),
          ),
        ],
      ),
    );
  }
}
