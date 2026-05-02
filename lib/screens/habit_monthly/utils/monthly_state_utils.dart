import 'package:rutio/features/gamification/domain/level_progression.dart';

class MonthlyHeaderVM {
  final String username;
  final int level;
  final double xpValue; // 0..1
  final int coins;

  const MonthlyHeaderVM({
    required this.username,
    required this.level,
    required this.xpValue,
    required this.coins,
  });
}

class MonthlyStateUtils {
  static Map<String, dynamic> mapCast(dynamic v) =>
      (v is Map) ? v.cast<String, dynamic>() : <String, dynamic>{};

  static Map<String, dynamic> userState(Map<String, dynamic>? root) =>
      (root == null) ? <String, dynamic>{} : mapCast(root['userState']);

  static Map<String, dynamic> history(Map<String, dynamic>? root) =>
      mapCast(userState(root)['history']);

  static Map<String, dynamic>? findHabitInState(
      Map<String, dynamic>? root, String habitId) {
    if (root == null) return null;

    final us = userState(root);
    final activeHabits = (us['activeHabits'] is List)
        ? (us['activeHabits'] as List)
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList()
        : <Map<String, dynamic>>[];

    for (final h in activeHabits) {
      if ((h['id'] ?? '').toString() == habitId) return h;
    }
    return null;
  }

  static bool isScheduledForDate(Map<String, dynamic> habit, DateTime date,
      String Function(DateTime) dateKey) {
    final schedule = mapCast(habit['schedule']);
    final type = (schedule['type'] ?? 'daily').toString();

    if (type == 'daily') return true;

    if (type == 'once') {
      final d = (schedule['date'] ?? '').toString();
      return d.isNotEmpty && d == dateKey(date);
    }

    if (type == 'weekly') {
      final weekdays = (schedule['weekdays'] is List)
          ? (schedule['weekdays'] as List)
              .whereType<num>()
              .map((e) => e.toInt())
              .toList()
          : <int>[];
      return weekdays.contains(date.weekday); // Mon=1..Sun=7
    }

    return true;
  }

  static MonthlyHeaderVM headerVM(Map<String, dynamic>? root) {
    final us = userState(root);
    final profile = mapCast(us['profile']);
    final progression = mapCast(us['progression']);
    final wallet = mapCast(us['wallet']);

    final username = (profile['username'] ??
            profile['name'] ??
            us['username'] ??
            us['name'] ??
            '')
        .toString();

    final totalXp = ((progression['xp'] as num?) ??
            (us['xp'] as num?) ??
            (us['xpTotal'] as num?) ??
            0)
        .toInt();
    final levelProgress = LevelProgression.fromTotalXp(totalXp);
    final level = levelProgress.level;
    final xpValue = levelProgress.progress;

    final coins = ((wallet['coins'] as num?) ??
            (us['coins'] as num?) ??
            (us['money'] as num?) ??
            (us['gold'] as num?) ??
            0)
        .toInt();

    return MonthlyHeaderVM(
      username: username,
      level: level,
      coins: coins,
      xpValue: xpValue,
    );
  }
}
