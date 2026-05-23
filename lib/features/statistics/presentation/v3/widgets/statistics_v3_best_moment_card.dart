import 'package:flutter/material.dart';
import 'package:rutio/features/statistics/presentation/shared/statistics_best_moment_illustrations.dart';
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
    final illustrationAsset = _assetFor(insight.slot);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: compact ? 96 : 106,
            height: compact ? 50 : 55,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              illustrationAsset,
              key: Key(
                  'statisticsV3BestMomentIllustration-${insight.slot.name}'),
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
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

  String _assetFor(StatisticsV3BestMomentSlot slot) {
    switch (slot) {
      case StatisticsV3BestMomentSlot.morning:
        return statisticsBestMomentIllustrationAssetForBucket(
          StatisticsBestMomentBucket.morning,
        );
      case StatisticsV3BestMomentSlot.noon:
        return statisticsBestMomentIllustrationAssetForBucket(
          StatisticsBestMomentBucket.midday,
        );
      case StatisticsV3BestMomentSlot.afternoon:
        return statisticsBestMomentIllustrationAssetForBucket(
          StatisticsBestMomentBucket.afternoon,
        );
      case StatisticsV3BestMomentSlot.night:
        return statisticsBestMomentIllustrationAssetForBucket(
          StatisticsBestMomentBucket.night,
        );
    }
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
