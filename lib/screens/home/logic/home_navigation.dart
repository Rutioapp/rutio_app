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
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => const StatisticsV3Screen(),
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
          CupertinoPageRoute(builder: (_) => const DiaryV2Screen()),
        );
      },
      onGoDiaryV2: () => Navigator.pushNamed(context, '/diary'),
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
