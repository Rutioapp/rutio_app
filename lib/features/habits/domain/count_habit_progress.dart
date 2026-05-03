/// Single source of truth for count-habit progress.
///
/// Count habits are completed only when currentValue reaches the effective
/// target. Partial progress is not completion.
class CountHabitProgress {
  const CountHabitProgress._({
    required this.currentValue,
    required this.targetValue,
    required this.effectiveTarget,
    required this.completionRatio,
    required this.progressPercent,
    required this.isCompleted,
    required this.hasPartialProgress,
    required this.remainingValue,
    required this.isTargetValid,
    required this.isSkipped,
    required this.unit,
  });

  factory CountHabitProgress.fromValues({
    num? currentValue,
    num? targetValue,
    bool skipped = false,
    String? unit,
  }) {
    final safeCurrent = _safeNum(currentValue).clamp(0.0, double.infinity);
    final safeTarget = _safeNum(targetValue);
    final targetIsValid = safeTarget > 0;
    final effective = targetIsValid ? safeTarget : 1.0;
    final normalizedUnit = _normalizeUnit(unit);

    // Explicit decision: when skipped, progress ratio is reset to 0 for
    // status semantics (not completed and not partial).
    final ratio = skipped
        ? 0.0
        : (safeCurrent / effective).clamp(0.0, 1.0).toDouble();
    final completed = !skipped && safeCurrent >= effective;
    final partial = !skipped && safeCurrent > 0 && safeCurrent < effective;
    final remaining = skipped
        ? effective
        : (effective - safeCurrent).clamp(0.0, double.infinity).toDouble();

    return CountHabitProgress._(
      currentValue: safeCurrent.toDouble(),
      targetValue: safeTarget.toDouble(),
      effectiveTarget: effective.toDouble(),
      completionRatio: ratio,
      progressPercent: (ratio * 100).clamp(0.0, 100.0).toDouble(),
      isCompleted: completed,
      hasPartialProgress: partial,
      remainingValue: remaining,
      isTargetValid: targetIsValid,
      isSkipped: skipped,
      unit: normalizedUnit,
    );
  }

  factory CountHabitProgress.fromHabitMap(
    Map<String, dynamic> habit, {
    num? currentValue,
    num? targetValue,
    bool? skipped,
    String? unit,
  }) {
    final resolvedCurrent = currentValue ??
        _firstNum(
          habit,
          const <String>['progress', 'currentValue', 'value', 'current'],
        );
    final resolvedTarget = targetValue ??
        _firstNum(
          habit,
          const <String>['target', 'targetCount', 'goal', 'times'],
        );
    final resolvedSkipped = skipped ?? _firstBool(habit, const <String>[
      'skipped',
      'skippedToday',
      'isSkipped',
    ]);
    final resolvedUnit = unit ??
        _firstString(
          habit,
          const <String>['unit', 'unitLabel', 'counterUnit'],
        );

    return CountHabitProgress.fromValues(
      currentValue: resolvedCurrent,
      targetValue: resolvedTarget,
      skipped: resolvedSkipped,
      unit: resolvedUnit,
    );
  }

  final double currentValue;
  final double targetValue;
  final double effectiveTarget;
  final double completionRatio;
  final double progressPercent;
  final bool isCompleted;
  final bool hasPartialProgress;
  final double remainingValue;
  final bool isTargetValid;
  final bool isSkipped;
  final String? unit;

  String get displayText {
    final left = _formatNumber(currentValue);
    final right = _formatNumber(effectiveTarget);
    final unitSuffix =
        (unit == null || unit!.isEmpty) ? '' : ' ${unit!.trim()}';
    return '$left / $right$unitSuffix';
  }

  static String _formatNumber(num value) {
    final asDouble = value.toDouble();
    if (asDouble.isNaN || asDouble.isInfinite) return '0';
    if (asDouble % 1 == 0) return asDouble.toInt().toString();
    return asDouble
        .toStringAsFixed(6)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  static double _safeNum(dynamic value) {
    if (value is num) {
      final asDouble = value.toDouble();
      if (asDouble.isNaN || asDouble.isInfinite) return 0.0;
      return asDouble;
    }

    final raw = (value ?? '').toString().trim();
    if (raw.isEmpty) return 0.0;
    final parsed = double.tryParse(raw.replaceAll(',', '.'));
    if (parsed == null || parsed.isNaN || parsed.isInfinite) return 0.0;
    return parsed;
  }

  static num? _firstNum(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      if (!map.containsKey(key)) continue;
      return _safeNum(map[key]);
    }
    return null;
  }

  static bool _firstBool(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      if (!map.containsKey(key)) continue;
      final value = map[key];
      if (value is bool) return value;
      if (value is num) return value > 0;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true' || normalized == '1') return true;
        if (normalized == 'false' || normalized == '0') return false;
      }
    }
    return false;
  }

  static String? _firstString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      if (!map.containsKey(key)) continue;
      final normalized = _normalizeUnit(map[key]?.toString());
      if (normalized != null) return normalized;
    }
    return null;
  }

  static String? _normalizeUnit(String? value) {
    final normalized = (value ?? '').trim();
    return normalized.isEmpty ? null : normalized;
  }
}
