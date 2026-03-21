import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../utils/app_theme.dart';

class StreakHeroCard extends StatefulWidget {
  const StreakHeroCard({
    super.key,
    required this.streakDays,
    required this.nextMilestoneDays,
    this.milestoneLabel = '',
    this.leftLabel,
    this.rightLabel,
    this.decorEmoji = '🔥',
  });

  final int streakDays;
  final int nextMilestoneDays;

  final String milestoneLabel;
  final String? leftLabel;
  final String? rightLabel;
  final String decorEmoji;

  @override
  State<StreakHeroCard> createState() => _StreakHeroCardState();
}

class _StreakHeroCardState extends State<StreakHeroCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _opacity = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));

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
    final l10n = context.l10n;
    const bg = Color(0xFF1C1A17);

    final next = widget.nextMilestoneDays <= 0 ? 1 : widget.nextMilestoneDays;
    final progress = (widget.streakDays / next).clamp(0.0, 1.0);

    final left =
        widget.leftLabel ?? l10n.habitStatsDaysLabel(widget.streakDays);
    final right = widget.rightLabel ?? l10n.habitStatsDaysLabel(next);
    final milestoneLabel = widget.milestoneLabel.isEmpty
        ? l10n.habitStatsNextMilestone
        : widget.milestoneLabel;

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: 2,
                bottom: -6,
                child: Opacity(
                  opacity: 0.18,
                  child: Text(
                    widget.decorEmoji,
                    style: const TextStyle(fontSize: 86),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 78,
                    child: Text(
                      '${widget.streakDays}',
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        fontSize: 72,
                        height: 0.95,
                        color: Colors.white,
                        fontFamily: AppTextStyles.serifFamily,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text(
                          l10n.habitStatsCurrentStreakUpper,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.50),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _headline(context, widget.streakDays, next),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.habitStatsMilestoneProgress(
                              milestoneLabel, next),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _ProgressBar(
                          progress: progress,
                          leftLabel: left,
                          rightLabel: right,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _headline(BuildContext context, int streak, int next) {
    final l10n = context.l10n;
    if (streak <= 0) return l10n.habitStatsHeadlineStartToday;
    if (streak < next) return l10n.habitStatsHeadlineGoodStart;
    return l10n.habitStatsHeadlineOnStreak;
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.progress,
    required this.leftLabel,
    required this.rightLabel,
  });

  final double progress;
  final String leftLabel;
  final String rightLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 6,
            color: Colors.white.withValues(alpha: 0.16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2B542),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              leftLabel,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              rightLabel,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
