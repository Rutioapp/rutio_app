part of 'package:rutio/screens/home/home_screen.dart';

/// Home navigation actions.
///
/// Mantiene toda la navegacion de Home en un unico sitio:
/// drawer lateral, vista mensual, estadisticas y accesos a otras pantallas.
extension _HomeScreenNavigation on _HomeScreenState {
  void _openMonthlyOverview(BuildContext context) {
    Navigator.of(context).push(
      // IOS-FIRST IMPROVEMENT START
      CupertinoPageRoute(builder: (_) => const HabitMonthlyOverviewScreen()),
      // IOS-FIRST IMPROVEMENT END
    );
  }

  // NUEVO: menu de vistas (Diaria / Semanal / Mensual).
  void _openViewMenu(BuildContext context) {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _openStatsOverview(BuildContext context) {
    // Construimos una lista de habitos con historial embebido para stats.
    final store = context.read<UserStateStore>();
    final root = store.state;
    final rootMap = (root is Map) ? (root as Map) : <dynamic, dynamic>{};
    final userState = _map(rootMap['userState']);
    final activeHabits = _listMap(userState['activeHabits']);

    final history = _map(userState['history']);
    final habitCompletions = _map(history['habitCompletions']);
    final habitCountValues = _map(history['habitCountValues']);

    final habitsWithHistory = <Map<String, dynamic>>[];

    for (final h in activeHabits) {
      final id = (h['id'] ?? '').toString();
      final out = Map<String, dynamic>.from(h);

      final completedDates = <String>[];
      habitCompletions.forEach((dateKey, dayMap) {
        final dm = _map(dayMap);
        if (dm[id] == true) completedDates.add(dateKey.toString());
      });
      out['completedDates'] = completedDates;

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

    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => HabitStatsOverviewScreen(
          habits: habitsWithHistory,
          familyColorResolver: (h) {
            if (h is Map) {
              final fid = (h['familyId'] ?? '').toString();
              return _familyColor(fid);
            }
            return const Color(0xFF6C5CE7);
          },
          titleResolver: (h) {
            if (h is Map) {
              final v = h['name'] ?? h['title'] ?? h['habitName'] ?? h['label'];
              return (v?.toString().trim().isNotEmpty ?? false)
                  ? v.toString()
                  : context.l10n.homeFallbackHabitTitle;
            }
            return context.l10n.homeFallbackHabitTitle;
          },
        ),
      ),
    );
  }

  Widget _buildViewDrawer(BuildContext context) {
    return AppViewDrawer(
      onGoDaily: () {
        // Home diaria.
      },
      onGoWeekly: () {
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (_) => const HabitWeeklyScreen()),
        );
      },
      onGoMonthly: () => _openMonthlyOverview(context),
      onGoTodo: () => Navigator.pushNamed(context, '/todo'),
      onGoDiary: () {
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (_) => const DiaryScreen()),
        );
      },
      onGoArchived: () {
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (_) => const ArchivedHabitsScreen()),
        );
      },
      onGoStats: () => _openStatsOverview(context),
      onGoShop: () => Navigator.pushNamed(context, '/shop'),
      onGoProfile: () => _openProfileFromHome(context),
    );
  }
}
