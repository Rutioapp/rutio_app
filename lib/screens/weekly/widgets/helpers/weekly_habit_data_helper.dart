import 'package:rutio/utils/family_theme.dart';

class WeeklyHabitDataHelper {
  static String resolveTitle(
    Map<String, dynamic> habit, {
    required String fallback,
  }) {
    return (habit['title'] ?? habit['name'] ?? fallback).toString();
  }

  static String resolveFamilyId(Map<String, dynamic> habit) {
    final familyId =
        (habit['familyId'] ?? habit['familyKey'] ?? habit['family'] ?? '')
            .toString()
            .trim();
    if (familyId.isNotEmpty) return familyId;
    return FamilyTheme.fallbackId;
  }

  static String resolveHabitEmoji(Map<String, dynamic> habit) {
    final direct =
        (habit['emoji'] ?? habit['habitEmoji'] ?? '').toString().trim();
    if (direct.isNotEmpty) return direct;

    return FamilyTheme.emojiOf(resolveFamilyId(habit));
  }

  static String normalizeHabitType(Map<String, dynamic> habit) {
    final raw =
        (habit['type'] ?? habit['kind'] ?? habit['trackingType'] ?? 'check')
            .toString()
            .trim()
            .toLowerCase();
    return (raw == 'count' || raw == 'counter') ? 'count' : 'check';
  }

  static String resolveCountUnit(Map<String, dynamic> habit) {
    return (habit['unit'] ?? habit['unitLabel'] ?? habit['units'] ?? '')
        .toString()
        .trim();
  }

  static num numValue(dynamic value, {num fallback = 0}) {
    if (value is num) {
      if (value is double && !value.isFinite) return fallback;
      return value;
    }

    final raw = (value ?? '').toString().trim();
    if (raw.isEmpty) return fallback;

    final parsed = num.tryParse(raw.replaceAll(',', '.'));
    if (parsed == null) return fallback;
    if (parsed is double && !parsed.isFinite) return fallback;
    return parsed;
  }

  static num positiveNum(dynamic value, {num fallback = 1}) {
    final parsed = numValue(value, fallback: fallback);
    return parsed > 0 ? parsed : fallback;
  }

  static bool supportsDecimals(
    Map<String, dynamic> habit, {
    num? currentValue,
  }) {
    bool hasFraction(dynamic value) {
      final parsed = numValue(value, fallback: 0);
      return parsed % 1 != 0;
    }

    return hasFraction(habit['counterStep']) ||
        hasFraction(habit['step']) ||
        hasFraction(habit['target']) ||
        hasFraction(habit['progress']) ||
        hasFraction(currentValue);
  }
}
