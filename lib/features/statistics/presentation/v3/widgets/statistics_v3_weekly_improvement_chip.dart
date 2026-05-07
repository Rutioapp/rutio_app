import 'package:flutter/material.dart';

class StatisticsV3WeeklyImprovementChip extends StatelessWidget {
  const StatisticsV3WeeklyImprovementChip({
    super.key,
    required this.title,
    required this.subtitle,
    this.deltaPercentage,
  });

  final String title;
  final String subtitle;
  final int? deltaPercentage;

  static const _border = Color(0xFFE9E3D9);
  static const _text = Color(0xFF2F251C);
  static const _green = Color(0xFF4E7D35);

  @override
  Widget build(BuildContext context) {
    final delta = deltaPercentage;
    final hasDelta = delta != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF7).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 172;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WeeklyImprovementHeader(
                title: title,
                compact: compact,
              ),
              const Spacer(),
              Center(
                child: hasDelta
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            _formatDelta(delta),
                            style: TextStyle(
                              fontSize: 20,
                              height: 1,
                              fontWeight: FontWeight.w700,
                              color: _deltaColor(delta),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6A5A47),
                            ),
                          ),
                        ],
                      )
                    : Text(
                        subtitle,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.1,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6A5A47),
                        ),
                      ),
              ),
              const Spacer(),
            ],
          );
        },
      ),
    );
  }

  String _formatDelta(int delta) => '${delta > 0 ? '+' : ''}$delta%';

  Color _deltaColor(int delta) {
    if (delta > 0) return const Color(0xFF4E7756);
    if (delta < 0) return const Color(0xFF8C5A4A);
    return const Color(0xFF6A5A47);
  }
}

class _WeeklyImprovementHeader extends StatelessWidget {
  const _WeeklyImprovementHeader({
    required this.title,
    required this.compact,
  });

  final String title;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 22 : 23,
      child: Row(
        children: [
          Container(
            width: compact ? 21 : 23,
            height: compact ? 21 : 23,
            decoration: BoxDecoration(
              color: StatisticsV3WeeklyImprovementChip._green
                  .withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.trending_up_rounded,
              size: compact ? 15 : 16,
              color: StatisticsV3WeeklyImprovementChip._green,
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
                  color: StatisticsV3WeeklyImprovementChip._text,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
