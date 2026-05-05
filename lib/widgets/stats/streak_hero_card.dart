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
    final visual = _visualForStreak(widget.streakDays);
    final onDark = visual.gradient.first.computeLuminance() < 0.35;
    final textColor = onDark ? Colors.white : const Color(0xFF1F1B16);
    final mutedTextColor =
        onDark ? Colors.white.withValues(alpha: 0.72) : const Color(0xFF6A6153);
    final trackColor =
        onDark ? Colors.white.withValues(alpha: 0.16) : Colors.black.withValues(alpha: 0.10);
    final captionColor =
        onDark ? Colors.white.withValues(alpha: 0.55) : Colors.black.withValues(alpha: 0.55);

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
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: visual.gradient,
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: visual.border),
            boxShadow: [
              BoxShadow(
                color: visual.shadow,
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
                  opacity: visual.emojiOpacity,
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
                      style: TextStyle(
                        fontSize: 72,
                        height: 0.95,
                        color: textColor,
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
                            color: mutedTextColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _headline(context, widget.streakDays, next),
                          style: TextStyle(
                            color: textColor,
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
                            color: mutedTextColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _ProgressBar(
                          progress: progress,
                          leftLabel: left,
                          rightLabel: right,
                          trackColor: trackColor,
                          captionColor: captionColor,
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

  _StreakVisual _visualForStreak(int streak) {
    if (streak <= 2) {
      return const _StreakVisual(
        gradient: [Color(0xFFF6F1E7), Color(0xFFF1E7D8)],
        border: Color(0xFFE7D9C6),
        shadow: Color(0x2213120F),
        emojiOpacity: 0.10,
      );
    }
    if (streak <= 6) {
      return const _StreakVisual(
        gradient: [Color(0xFFEAF3E7), Color(0xFFE0ECDE)],
        border: Color(0xFFC9DDC2),
        shadow: Color(0x22334A34),
        emojiOpacity: 0.12,
      );
    }
    if (streak <= 13) {
      return const _StreakVisual(
        gradient: [Color(0xFFF7EEE1), Color(0xFFF2E3C8)],
        border: Color(0xFFE7CFAC),
        shadow: Color(0x224A3A2A),
        emojiOpacity: 0.14,
      );
    }
    return const _StreakVisual(
      gradient: [Color(0xFF1D2622), Color(0xFF2D342D)],
      border: Color(0xFF4A5F4E),
      shadow: Color(0x33322A1F),
      emojiOpacity: 0.20,
    );
  }
}

class _StreakVisual {
  const _StreakVisual({
    required this.gradient,
    required this.border,
    required this.shadow,
    required this.emojiOpacity,
  });

  final List<Color> gradient;
  final Color border;
  final Color shadow;
  final double emojiOpacity;
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.progress,
    required this.leftLabel,
    required this.rightLabel,
    required this.trackColor,
    required this.captionColor,
  });

  final double progress;
  final String leftLabel;
  final String rightLabel;
  final Color trackColor;
  final Color captionColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 6,
            color: trackColor,
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
                color: captionColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              rightLabel,
              style: TextStyle(
                color: captionColor,
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
