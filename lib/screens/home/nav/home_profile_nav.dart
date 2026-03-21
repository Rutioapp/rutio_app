part of 'package:rutio/screens/home/home_screen.dart';

extension _HomeScreenProfileNav on _HomeScreenState {
  void _openProfileFromHome(
    BuildContext context, {
    bool openEditProfileOnLoad = false,
    bool useCupertinoRoute = false,
  }) {
    final store = context.read<UserStateStore>();
    final habitsWithHistory = _buildHabitsWithHistory(store);

    String? name;
    String? email;
    try {
      final root = store.state;
      final userState = _map(root is Map ? (root as Map)['userState'] : null);
      final profile = _map(userState['profile']);
      name = (profile['name'] ??
              profile['displayName'] ??
              profile['userName'] ??
              profile['username'])
          ?.toString();
      email = (profile['email'] ?? profile['mail'])?.toString();
    } catch (_) {}

    final screen = ProfileScreen(
      userName: name,
      email: email,
      habits: habitsWithHistory,
      openEditProfileOnLoad: openEditProfileOnLoad,
      familyColorResolver: (h) {
        if (h is Map) {
          final fid =
              (h['familyId'] ?? h['family'] ?? h['Family'] ?? '').toString();
          return _familyColor(fid);
        }
        return const Color(0xFF6C5CE7);
      },
      titleResolver: (h) {
        if (h is Map) {
          final v = h['name'] ?? h['title'] ?? h['habitName'] ?? h['label'];
          return (v?.toString().trim().isNotEmpty ?? false)
              ? v.toString().trim()
              : context.l10n.homeFallbackHabitTitle;
        }
        return context.l10n.homeFallbackHabitTitle;
      },
    );

    Navigator.push(
      context,
      useCupertinoRoute
          ? CupertinoPageRoute(builder: (_) => screen)
          : MaterialPageRoute(builder: (_) => screen),
    );
  }

  List<Map<String, dynamic>> _buildHabitsWithHistory(UserStateStore store) {
    final root = store.state;
    final userState = _map(root is Map ? (root as Map)['userState'] : null);

    final activeHabits = _listMap(userState['activeHabits']);
    final history = _map(userState['history']);
    final habitCompletions = _map(history['habitCompletions']);
    final habitCountValues = _map(history['habitCountValues']);

    final habitsWithHistory = <Map<String, dynamic>>[];

    for (final h in activeHabits) {
      final id = (h['id'] ?? h['habitId'] ?? '').toString();
      if (id.isEmpty) continue;

      final out = Map<String, dynamic>.from(h);

      final c = habitCompletions[id];
      if (c is List) {
        out['completedDates'] = c.map((e) => e.toString()).toList();
      } else if (c is Map) {
        final dates = <String>[];
        c.forEach((k, v) {
          if (v == true) dates.add(k.toString());
        });
        if (dates.isNotEmpty) out['completedDates'] = dates;
      }

      final cv = habitCountValues[id];
      if (cv is Map) {
        out['countValues'] = cv.map((k, v) => MapEntry(k.toString(), v));
      }

      final records = <Map<String, dynamic>>[];
      habitCountValues.forEach((dateKey, dayMap) {
        final dm = _map(dayMap);
        final v = dm[id];
        if (v is num && v > 0) {
          records.add({'date': dateKey.toString(), 'count': v});
        }
      });
      if (records.isNotEmpty) out['records'] = records;

      habitsWithHistory.add(out);
    }

    return habitsWithHistory;
  }
}
