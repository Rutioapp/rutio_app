import 'package:flutter/material.dart';

/// Simple pill-shaped progress bar.
///
/// - [value] is a fraction between 0.0 and 1.0 (values are clamped).
/// - [color] is the filled color of the bar (typically your family color).
///
/// If you want the bar to pick the color from a family id + map, use:
/// `ProgressBar.family(value: ..., familyId: ..., familyColors: ...)`
class ProgressBar extends StatelessWidget {
  final double value; // 0..1

  /// Filled color (typically the family color).
  final Color color;

  final double height;

  /// How much the family color tints the track/background.
  final double trackOpacity;

  const ProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 8,
    this.trackOpacity = 0.18,
  });

  /// Convenience constructor: resolve the bar color from a [familyId]
  /// using the provided [familyColors] map.
  ///
  /// Important:
  /// This is a `factory` (not `const`) because looking up a color in a map
  /// is not a compile-time constant expression.
  ///
  /// Robustness:
  /// - Accepts nullable [familyId] / [familyColors] and always falls back safely.
  factory ProgressBar.family({
    Key? key,
    required double value,
    String? familyId,
    Map<String, Color>? familyColors,
    double height = 8,
    double trackOpacity = 0.18,
    Color fallbackColor = const Color(0xFF9E9E9E),
  }) {
    final resolved = (familyId != null && familyColors != null)
        ? familyColors[familyId]
        : null;

    return ProgressBar(
      key: key,
      value: value,
      color: resolved ?? fallbackColor,
      height: height,
      trackOpacity: trackOpacity,
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);

    // Tint the track with the family color so it's visible even with small values.
    final trackBase = Theme.of(context).colorScheme.surfaceContainerHighest;
    final track =
        Color.alphaBlend(_withOpacity(color, trackOpacity), trackBase);

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: v,
        minHeight: height,
        backgroundColor: track,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }

  /// Avoids any potential API warnings around `withOpacity` in some Flutter versions.
  static Color _withOpacity(Color c, double opacity) {
    final a = (opacity.clamp(0.0, 1.0) * 255).round().clamp(0, 255);
    return c.withAlpha(a);
  }
}
