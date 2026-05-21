import 'package:flutter/material.dart';
import 'package:rutio/features/statistics/presentation/v3/widgets/statistics_v3_consistency_palette.dart';
import 'package:rutio/l10n/l10n.dart';

class StatisticsV3ConsistencyLegend extends StatelessWidget {
  const StatisticsV3ConsistencyLegend({
    super.key,
    this.showFuture = false,
    this.showNoData = false,
  });

  final bool showFuture;
  final bool showNoData;

  @override
  Widget build(BuildContext context) {
    final labels = _labels(context);
    final items = <Widget>[
      for (var i = 0;
          i < StatisticsV3ConsistencyPalette.percentageBuckets.length;
          i++) ...[
        if (i > 0) const SizedBox(width: 8),
        _LegendItem(
          key: Key(
            'statisticsV3ConsistencyLegend_${StatisticsV3ConsistencyPalette.percentageBuckets[i].intensity.name}',
          ),
          colorTone: StatisticsV3ConsistencyPalette.toneFor(
            StatisticsV3ConsistencyPalette.percentageBuckets[i].intensity,
          ),
          label: _rangeLabel(StatisticsV3ConsistencyPalette.percentageBuckets[i]),
        ),
      ],
    ];
    if (showNoData) {
      items
        ..add(const SizedBox(width: 8))
        ..add(
          _LegendItem(
            key: const Key('statisticsV3ConsistencyLegend_unavailable'),
            colorTone: StatisticsV3ConsistencyPalette.toneFor(
              StatisticsV3ConsistencyIntensity.unavailable,
            ),
            label: labels.noData,
          ),
        );
    }
    if (showFuture) {
      items
        ..add(const SizedBox(width: 8))
        ..add(
          _LegendItem(
            key: const Key('statisticsV3ConsistencyLegend_future'),
            colorTone: StatisticsV3ConsistencyPalette.toneFor(
              StatisticsV3ConsistencyIntensity.future,
            ),
            label: labels.future,
          ),
        );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          child: FittedBox(
            key: const Key('statisticsV3ConsistencyLegend'),
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: items,
            ),
          ),
        );
      },
    );
  }

  _LegendLabels _labels(BuildContext context) {
    final l10n = context.l10n;
    return _LegendLabels(
      noData: l10n.statisticsV3ConsistencyLegendNoData,
      future: l10n.statisticsV3ConsistencyLegendFuture,
    );
  }

  String _rangeLabel(StatisticsV3ConsistencyRangeBucket bucket) {
    if (bucket.minPercentage == bucket.maxPercentage) {
      return '${bucket.maxPercentage}%';
    }
    return '${bucket.minPercentage}–${bucket.maxPercentage}%';
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    super.key,
    required this.colorTone,
    required this.label,
  });

  final StatisticsV3ConsistencyTone colorTone;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: colorTone.fillColor,
            shape: BoxShape.circle,
            border: Border.all(color: colorTone.borderColor, width: 0.9),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10.0,
                height: 1,
                color: StatisticsV3ConsistencyPalette.mutedText,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _LegendLabels {
  const _LegendLabels({
    required this.noData,
    required this.future,
  });

  final String noData;
  final String future;
}
