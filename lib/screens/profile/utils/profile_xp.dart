import 'package:intl/intl.dart';
import 'package:rutio/features/gamification/domain/level_progression.dart';

import '../models/family_level.dart';

/// XP rules aligned with UserStateStore.
/// - "check" habit completion: 10 XP
/// - "count" habit completion: fixed XP by target (cap 5..15)
int xpForCheckCompletion() => 10;

/// Same formula used in UserStateStore:
/// int _xpForCountCompletion(num target) =>
///     ((target / 5).ceil() * 2 + 5).clamp(5, 15);
int xpForCountCompletion(num target) =>
    (((target / 5).ceil() * 2) + 5).clamp(5, 15);

/// Progression aligned with LevelProgression.
LevelData levelFromXp(int xp) {
  final progress = LevelProgression.fromTotalXp(xp);
  return LevelData(
    level: progress.level,
    xpToNext: progress.xpToNextLevel,
  );
}

/// Progress within current level (0..1) for progress bars.
double normalizedProgressWithinLevel({required int xp}) {
  return LevelProgression.fromTotalXp(xp).progress;
}

/// Compact visual formatter for large XP values.
///
/// Examples:
/// - 950 -> 950
/// - 1000 -> 1k
/// - 1500 -> 1.5k / 1,5k
/// - 12400 -> 12.4k / 12,4k
/// - 1200000 -> 1.2M / 1,2M
String formatCompactXp(
  int value, {
  String? localeName,
}) {
  final safeValue = value < 0 ? 0 : value;
  if (safeValue < 1000) {
    return NumberFormat.decimalPattern(localeName).format(safeValue);
  }

  final units = <({int divisor, String suffix})>[
    (divisor: 1000000, suffix: 'M'),
    (divisor: 1000, suffix: 'k'),
  ];

  for (final unit in units) {
    if (safeValue < unit.divisor) continue;

    final scaled = safeValue / unit.divisor;
    final useDecimal = scaled < 100 && scaled != scaled.roundToDouble();
    final formattedValue =
        useDecimal ? double.parse(scaled.toStringAsFixed(1)) : scaled.round();
    final number =
        NumberFormat.decimalPattern(localeName).format(formattedValue);
    return '$number${unit.suffix}';
  }

  return NumberFormat.decimalPattern(localeName).format(safeValue);
}

/// Global 0..1 value for radar:
/// combines level + local progress, normalized to a max level.
double normalizedRadarValue({
  required int xp,
  required LevelData levelData,
  int maxLevel = 10,
}) {
  final safeXp = xp < 0 ? 0 : xp;
  final level = levelData.level;
  final local = normalizedProgressWithinLevel(xp: safeXp);
  final global = (level - 1) + local;
  final denom = maxLevel <= 1 ? 1.0 : maxLevel.toDouble();
  final value = global / denom;
  if (value.isNaN) return 0.0;
  return value.clamp(0.0, 1.0);
}
