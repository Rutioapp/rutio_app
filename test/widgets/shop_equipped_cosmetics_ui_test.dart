import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/screens/home/widgets/habit/habit_card_widget.dart';
import 'package:rutio/widgets/backgrounds/home_landscape_background.dart';
import 'package:rutio/widgets/home/user_identity_row.dart';

Widget _app(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('home background keeps fallback scene when no wallpaper is set',
      (tester) async {
    await tester.pumpWidget(
      _app(
        const Stack(
          children: [
            HomeBackground(resolveEquippedWallpaper: false),
          ],
        ),
      ),
    );

    expect(find.byKey(const Key('homeBackgroundWallpaperImage')), findsNothing);
  });

  testWidgets('home background renders equipped wallpaper image layer',
      (tester) async {
    await tester.pumpWidget(
      _app(
        const Stack(
          children: [
            HomeBackground(
              resolveEquippedWallpaper: false,
              wallpaperAssetPath: 'assets/shop/wallpapers/common/wallpaper_warm_beige.webp',
            ),
          ],
        ),
      ),
    );

    expect(find.byKey(const Key('homeBackgroundWallpaperImage')), findsOneWidget);
  });

  testWidgets('habit card keeps fallback design when no skin is set',
      (tester) async {
    await tester.pumpWidget(
      _app(
        HabitCardWidget(
          title: 'Read',
          description: '20 min',
          familyColor: Colors.blue,
          progress: 0,
        ),
      ),
    );

    expect(find.byKey(const Key('habitCardBackgroundImage')), findsNothing);
  });

  testWidgets('habit card renders equipped skin image layer', (tester) async {
    await tester.pumpWidget(
      _app(
        HabitCardWidget(
          title: 'Read',
          description: '20 min',
          familyColor: Colors.blue,
          progress: 0,
          backgroundImageAssetPath:
              'assets/shop/habit_cards/common/habit_card_warm_beige.webp',
        ),
      ),
    );

    expect(find.byKey(const Key('habitCardBackgroundImage')), findsOneWidget);
  });

  testWidgets('user identity row keeps fallback design when no skin is set',
      (tester) async {
    await tester.pumpWidget(
      _app(
        const UserIdentityRow(
          username: 'Alex',
          level: 4,
          coins: 120,
          xpProgress: 0.5,
          backgroundImageAssetPath: null,
        ),
      ),
    );

    expect(find.byKey(const Key('userIdentityRowBackgroundImage')), findsNothing);
  });

  testWidgets('user identity row renders equipped skin image layer',
      (tester) async {
    await tester.pumpWidget(
      _app(
        const UserIdentityRow(
          username: 'Alex',
          level: 4,
          coins: 120,
          xpProgress: 0.5,
          backgroundImageAssetPath:
              'assets/shop/user_cards/common/user_card_warm_beige.webp',
        ),
      ),
    );

    expect(find.byKey(const Key('userIdentityRowBackgroundImage')), findsOneWidget);
  });
}
