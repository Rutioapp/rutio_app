import 'dart:math';

class LevelProgress {
  const LevelProgress({
    required this.totalXp,
    required this.level,
    required this.currentLevelXp,
    required this.xpForNextLevel,
    required this.progress,
  });

  final int totalXp;
  final int level;
  final int currentLevelXp;
  final int xpForNextLevel;
  final double progress;

  int get xpToNextLevel => xpForNextLevel - currentLevelXp;
}

class LevelProgression {
  static const int minLevel = 1;
  static const int _baseXp = 80;
  static const int _linearXpPerLevel = 35;
  static const double _curveExponent = 1.65;
  static const double _curveMultiplier = 18;

  static final List<int> _cumulativeXpToReachLevelCache = <int>[0, 0];

  static int xpRequiredForLevel(int level) {
    final safeLevel = level < minLevel ? minLevel : level;
    final levelOffset = safeLevel - 1;
    final linear = levelOffset * _linearXpPerLevel;
    final curve = pow(levelOffset, _curveExponent).toDouble() * _curveMultiplier;
    return (_baseXp + linear + curve).round();
  }

  static int xpToReachLevel(int level) {
    final safeLevel = level < minLevel ? minLevel : level;
    _ensureCumulativeCacheUpToLevel(safeLevel);
    return _cumulativeXpToReachLevelCache[safeLevel];
  }

  static LevelProgress fromTotalXp(int totalXp) {
    final safeTotalXp = totalXp < 0 ? 0 : totalXp;
    final level = _levelFromTotalXp(safeTotalXp);
    final xpAtLevelStart = xpToReachLevel(level);
    final currentLevelXp = safeTotalXp - xpAtLevelStart;
    final xpForNextLevel = xpRequiredForLevel(level);
    final normalizedProgress = xpForNextLevel <= 0
        ? 0.0
        : (currentLevelXp / xpForNextLevel).clamp(0.0, 1.0).toDouble();

    return LevelProgress(
      totalXp: safeTotalXp,
      level: level < minLevel ? minLevel : level,
      currentLevelXp: currentLevelXp < 0 ? 0 : currentLevelXp,
      xpForNextLevel: xpForNextLevel < 1 ? 1 : xpForNextLevel,
      progress: normalizedProgress,
    );
  }

  static int _levelFromTotalXp(int safeTotalXp) {
    var low = minLevel;
    var high = minLevel + 1;

    while (xpToReachLevel(high) <= safeTotalXp) {
      low = high;
      high = high * 2;
    }

    while (low + 1 < high) {
      final mid = low + ((high - low) ~/ 2);
      if (xpToReachLevel(mid) <= safeTotalXp) {
        low = mid;
      } else {
        high = mid;
      }
    }

    return low < minLevel ? minLevel : low;
  }

  static void _ensureCumulativeCacheUpToLevel(int level) {
    if (_cumulativeXpToReachLevelCache.length > level) return;

    for (var currentLevel = _cumulativeXpToReachLevelCache.length;
        currentLevel <= level;
        currentLevel++) {
      final previousLevel = currentLevel - 1;
      final previousTotal = _cumulativeXpToReachLevelCache[previousLevel];
      _cumulativeXpToReachLevelCache.add(
        previousTotal + xpRequiredForLevel(previousLevel),
      );
    }
  }
}
