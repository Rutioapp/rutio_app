import 'package:flutter/material.dart';
import 'package:rutio/utils/family_theme.dart';

class AppDateUtils {
  static DateTime onlyDate(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime startOfWeek(DateTime d) {
    final date = onlyDate(d);
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  static String toYMD(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class DataHelpers {
  static Map<String, dynamic> toMap(dynamic v) =>
      (v is Map<String, dynamic>) ? v : <String, dynamic>{};

  static List<Map<String, dynamic>> toListMap(dynamic v) {
    if (v is List) {
      return v
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }
}

class ColorHelper {
  static Color parse(
    dynamic v, {
    Color fallback = const Color(0xFF6D4CFF),
  }) {
    try {
      if (v is int) return Color(v);

      if (v is String) {
        final s = v.trim();
        if (s.startsWith('#')) {
          final hex = s.substring(1);
          if (hex.length == 6) return Color(int.parse('FF$hex', radix: 16));
          if (hex.length == 8) return Color(int.parse(hex, radix: 16));
        }
        if (s.startsWith('0x')) return Color(int.parse(s));
      }
    } catch (_) {}
    return fallback;
  }

  static Color familyColor(String id) => FamilyTheme.colorOf(id);

  static Color resolveFamilyColor(
    Map<String, dynamic> habit,
    Map<String, dynamic> userState,
    Map<String, dynamic>? root,
  ) {
    final rootMap = root ?? {};

    final familyIdStr =
        (habit['familyId'] ?? habit['familyKey'] ?? '').toString().trim();
    if (familyIdStr.isNotEmpty) {
      return FamilyTheme.colorOf(familyIdStr);
    }

    final familyRaw = habit['family'];
    if (familyRaw is String && familyRaw.trim().isNotEmpty) {
      return FamilyTheme.colorOf(familyRaw.trim());
    }

    final direct =
        habit['familyColor'] ?? habit['color'] ?? habit['accentColor'];
    if (direct != null) {
      return parse(direct,
          fallback: FamilyTheme.colorOf(FamilyTheme.fallbackId));
    }

    final famMap = DataHelpers.toMap(habit['family']);
    final famColor =
        famMap['color'] ?? famMap['accent'] ?? famMap['accentColor'];
    if (famColor != null) {
      return parse(famColor,
          fallback: FamilyTheme.colorOf(FamilyTheme.fallbackId));
    }

    final familyName =
        (habit['familyName'] ?? habit['familyTitle'] ?? habit['category'] ?? '')
            .toString()
            .toLowerCase()
            .trim();

    if (familyName.isNotEmpty) {
      if (familyName.contains('mente') || familyName.contains('mind')) {
        return FamilyTheme.colorOf(FamilyTheme.mind);
      }
      if (familyName.contains('espíritu') ||
          familyName.contains('espiritu') ||
          familyName.contains('spirit')) {
        return FamilyTheme.colorOf(FamilyTheme.spirit);
      }
      if (familyName.contains('cuerpo') || familyName.contains('body')) {
        return FamilyTheme.colorOf(FamilyTheme.body);
      }
      if (familyName.contains('emoc')) {
        return FamilyTheme.colorOf(FamilyTheme.emotional);
      }
      if (familyName.contains('social')) {
        return FamilyTheme.colorOf(FamilyTheme.social);
      }
      if (familyName.contains('disciplina') ||
          familyName.contains('discipline')) {
        return FamilyTheme.colorOf(FamilyTheme.discipline);
      }
      if (familyName.contains('prof')) {
        return FamilyTheme.colorOf(FamilyTheme.professional);
      }
    }

    final theme = DataHelpers.toMap(rootMap['theme']);
    final primaryDark = theme['primaryDark'];
    if (primaryDark != null) {
      return parse(primaryDark,
          fallback: FamilyTheme.colorOf(FamilyTheme.fallbackId));
    }

    return FamilyTheme.colorOf(FamilyTheme.fallbackId);
  }
}
