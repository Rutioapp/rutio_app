import 'package:flutter/material.dart';

import 'avatar_core.dart';
import 'avatar_ring_palette.dart';
import 'xp_progress_ring.dart';

class AvatarWithXpRing extends StatelessWidget {
  final String? avatarUrl;
  final String fallbackLabel;
  final double progress;
  final double size;
  final double strokeWidth;
  final double innerPadding;
  final Duration animationDuration;
  final Curve animationCurve;

  const AvatarWithXpRing({
    super.key,
    required this.avatarUrl,
    required this.fallbackLabel,
    required this.progress,
    this.size = 44,
    this.strokeWidth = 2.5,
    this.innerPadding = 2.2,
    this.animationDuration = const Duration(milliseconds: 680),
    this.animationCurve = Curves.easeInOutCubic,
  }) : assert(size > 0),
       assert(strokeWidth > 0),
       assert(innerPadding >= 0);

  @override
  Widget build(BuildContext context) {
    final palette = AvatarRingPalette.resolve(context);
    final safeProgress = progress.clamp(0.0, 1.0).toDouble();
    final innerSize = (size - (innerPadding * 2)).clamp(0.0, size).toDouble();

    return SizedBox.square(
      dimension: size,
      child: XpProgressRing(
        progress: safeProgress,
        size: size,
        strokeWidth: strokeWidth,
        palette: palette,
        duration: animationDuration,
        curve: animationCurve,
        child: Padding(
          padding: EdgeInsets.all(innerPadding),
          child: AvatarCore(
            avatarUrl: avatarUrl,
            fallbackLabel: fallbackLabel,
            size: innerSize,
            palette: palette,
          ),
        ),
      ),
    );
  }
}
