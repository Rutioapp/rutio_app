import 'package:flutter/material.dart';
import 'package:rutio/features/statistics/presentation/v3/models/statistics_v3_view_data.dart';
import 'package:rutio/l10n/l10n.dart';

class StatisticsV3FamilyChipsCard extends StatelessWidget {
  const StatisticsV3FamilyChipsCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.emptyLabel,
    required this.items,
  });

  static const _cream = Color(0xFFFDFBF7);
  static const _border = Color(0xFFE9E3D9);
  static const _text = Color(0xFF1F2A1F);
  static const _muted = Color(0xFF746A60);
  static const _green = Color(0xFF4E7D35);

  final String title;
  final String subtitle;
  final String emptyLabel;
  final List<StatisticsV3FamilyItem> items;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final item = items.isEmpty ? null : items.first;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      decoration: BoxDecoration(
        color: _cream.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 172;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FeaturedFamilyHeader(
                title: title,
                compact: compact,
              ),
              SizedBox(height: compact ? 8 : 9),
              Expanded(
                child: item == null
                    ? _FeaturedFamilyEmptyState(message: emptyLabel)
                    : _FeaturedFamilyBody(
                        item: item,
                        subtitle: subtitle,
                        completedLabel: l10n.statisticsV3SummaryCompletedLabel,
                        compact: compact,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FeaturedFamilyHeader extends StatelessWidget {
  const _FeaturedFamilyHeader({
    required this.title,
    required this.compact,
  });

  final String title;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final badgeSize = compact ? 21.0 : 23.0;
    final chevronSize = compact ? 22.0 : 24.0;
    return SizedBox(
      height: chevronSize,
      child: Row(
        children: [
          Container(
            width: badgeSize,
            height: badgeSize,
            decoration: BoxDecoration(
              color: StatisticsV3FamilyChipsCard._green.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.emoji_events_outlined,
              size: compact ? 15 : 16,
              color: StatisticsV3FamilyChipsCard._green,
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
                  color: StatisticsV3FamilyChipsCard._text,
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Container(
            width: chevronSize,
            height: chevronSize,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.64),
              shape: BoxShape.circle,
              border: Border.all(
                color: StatisticsV3FamilyChipsCard._border,
              ),
            ),
            child: Icon(
              Icons.chevron_right_rounded,
              size: compact ? 17 : 18,
              color: StatisticsV3FamilyChipsCard._green,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedFamilyBody extends StatelessWidget {
  const _FeaturedFamilyBody({
    required this.item,
    required this.subtitle,
    required this.completedLabel,
    required this.compact,
  });

  final StatisticsV3FamilyItem item;
  final String subtitle;
  final String completedLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: compact ? 56 : 62,
          height: compact ? 56 : 62,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: item.color.withValues(alpha: 0.10),
            border: Border.all(color: item.color.withValues(alpha: 0.26)),
          ),
          child: Container(
            width: compact ? 43 : 48,
            height: compact ? 43 : 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: item.color.withValues(alpha: 0.12),
            ),
            child: Text(
              item.emoji,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: compact ? 23 : 26),
            ),
          ),
        ),
        SizedBox(height: compact ? 6 : 7),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            item.name,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 23 : 26,
              height: 0.95,
              fontWeight: FontWeight.w800,
              color: StatisticsV3FamilyChipsCard._text,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '${item.completedCount} $completedLabel',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: compact ? 11.2 : 11.8,
            height: 1,
            fontWeight: FontWeight.w600,
            color: StatisticsV3FamilyChipsCard._text,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: compact ? 9.8 : 10.3,
            height: 1.12,
            fontWeight: FontWeight.w500,
            color: StatisticsV3FamilyChipsCard._muted,
          ),
        ),
      ],
    );
  }
}

class _FeaturedFamilyEmptyState extends StatelessWidget {
  const _FeaturedFamilyEmptyState({
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
          color: StatisticsV3FamilyChipsCard._muted,
        ),
      ),
    );
  }
}
