part of 'package:rutio/screens/home/home_screen.dart';

extension _HomeScreenProfileNav on _HomeScreenState {
  void _openProfileFromHome(
    BuildContext context, {
    bool openEditProfileOnLoad = false,
    bool useCupertinoRoute = false,
  }) {
    final screen = ProfileScreen(
      openEditProfileOnLoad: openEditProfileOnLoad,
      familyColorResolver: (h) {
        if (h is Map) {
          final fid =
              (h['familyId'] ?? h['family'] ?? h['Family'] ?? '').toString();
          return _familyColor(fid);
        }
        return const Color(0xFF6C5CE7);
      },
    );

    Navigator.push(
      context,
      useCupertinoRoute
          ? CupertinoPageRoute(builder: (_) => screen)
          : MaterialPageRoute(builder: (_) => screen),
    );
  }
}
