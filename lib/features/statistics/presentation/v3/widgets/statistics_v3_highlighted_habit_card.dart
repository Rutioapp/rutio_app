import 'package:flutter/material.dart';
import 'package:rutio/features/statistics/presentation/v3/models/statistics_v3_view_data.dart';
import 'package:rutio/l10n/l10n.dart';

class StatisticsV3HighlightedHabitCard extends StatelessWidget {
  const StatisticsV3HighlightedHabitCard({
    super.key,
    required this.title,
    required this.emptyLabel,
    required this.items,
    required this.streakDays,
  });

  static const _cream = Color(0xFFFDFBF7);
  static const _border = Color(0xFFE9E3D9);
  static const _text = Color(0xFF1F2A1F);
  static const _muted = Color(0xFF746A60);
  static const _green = Color(0xFF4E7D35);
  static const _fire = Color(0xFFE46F1B);

  final String title;
  final String emptyLabel;
  final List<StatisticsV3HighlightedHabitItem> items;
  final int streakDays;

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
              _FeaturedHabitHeader(
                title: title,
                compact: compact,
              ),
              SizedBox(height: compact ? 9 : 10),
              Expanded(
                child: item == null
                    ? _FeaturedHabitEmptyState(message: emptyLabel)
                    : _FeaturedHabitBody(
                        item: item,
                        countLabel: l10n.unitTimesShort,
                        streakLabel:
                            l10n.statisticsV3HighlightedHabitStreakLabel,
                        streakValueLabel:
                            l10n.statisticsV3HighlightedHabitStreakDays(
                          streakDays,
                        ),
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

class _FeaturedHabitHeader extends StatelessWidget {
  const _FeaturedHabitHeader({
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
              color: StatisticsV3HighlightedHabitCard._green
                  .withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.star_border_rounded,
              size: compact ? 15 : 16,
              color: StatisticsV3HighlightedHabitCard._green,
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
                  color: StatisticsV3HighlightedHabitCard._text,
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
                color: StatisticsV3HighlightedHabitCard._border,
              ),
            ),
            child: Icon(
              Icons.chevron_right_rounded,
              size: compact ? 17 : 18,
              color: StatisticsV3HighlightedHabitCard._green,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedHabitBody extends StatelessWidget {
  const _FeaturedHabitBody({
    required this.item,
    required this.countLabel,
    required this.streakLabel,
    required this.streakValueLabel,
    required this.compact,
  });

  final StatisticsV3HighlightedHabitItem item;
  final String countLabel;
  final String streakLabel;
  final String streakValueLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: compact ? 56 : 62,
                height: compact ? 56 : 62,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFEAC9).withValues(alpha: 0.48),
                  border: Border.all(
                    color: const Color(0xFFECA94D).withValues(alpha: 0.24),
                  ),
                ),
                child: Container(
                  width: compact ? 43 : 48,
                  height: compact ? 43 : 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFEAC9).withValues(alpha: 0.60),
                  ),
                  child: Text(
                    item.emoji,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: compact ? 23 : 26),
                  ),
                ),
              ),
              SizedBox(height: compact ? 6 : 7),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _displayName(item.name),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: compact ? 19 : 21,
                      height: 1.02,
                      fontWeight: FontWeight.w800,
                      color: StatisticsV3HighlightedHabitCard._text,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${item.completedCount}',
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: compact ? 22 : 24,
                      height: 0.95,
                      fontWeight: FontWeight.w800,
                      color: StatisticsV3HighlightedHabitCard._green,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      countLabel,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: compact ? 10.4 : 10.8,
                        height: 1,
                        fontWeight: FontWeight.w600,
                        color: StatisticsV3HighlightedHabitCard._muted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: compact ? 5 : 6),
        Align(
          alignment: Alignment.centerRight,
          child: _FeaturedHabitStreak(
            label: streakLabel,
            value: streakValueLabel,
            compact: compact,
          ),
        ),
      ],
    );
  }

  String _displayName(String value) {
    final words = value.trim().split(RegExp(r'\s+'));
    if (words.length < 4) return value;

    final splitIndex = words.length - 2;
    return '${words.take(splitIndex).join(' ')}\n'
        '${words.skip(splitIndex).join(' ')}';
  }
}

class _FeaturedHabitStreak extends StatelessWidget {
  const _FeaturedHabitStreak({
    required this.label,
    required this.value,
    required this.compact,
  });

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 24.0 : 26.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: StatisticsV3HighlightedHabitCard._fire
                .withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.local_fire_department_rounded,
            size: compact ? 14 : 15,
            color: StatisticsV3HighlightedHabitCard._fire,
          ),
        ),
        const SizedBox(width: 7),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: compact ? 11.5 : 12.3,
                height: 1,
                fontWeight: FontWeight.w800,
                color: StatisticsV3HighlightedHabitCard._text,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: compact ? 10.5 : 11,
                height: 1,
                fontWeight: FontWeight.w500,
                color: StatisticsV3HighlightedHabitCard._muted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FeaturedHabitEmptyState extends StatelessWidget {
  const _FeaturedHabitEmptyState({
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
          color: StatisticsV3HighlightedHabitCard._muted,
        ),
      ),
    );
  }
}
