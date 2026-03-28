import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/widgets/app_view_drawer.dart';

void main() {
  testWidgets('AppViewDrawer renders support action in Spanish', (
    WidgetTester tester,
  ) async {
    final scaffoldKey = GlobalKey<ScaffoldState>();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          key: scaffoldKey,
          drawer: AppViewDrawer(
            onGoDaily: () {},
            onGoWeekly: () {},
            onGoMonthly: () {},
            onGoTodo: () {},
            onGoDiary: () {},
            onGoArchived: () {},
            onGoStats: () {},
            onGoProfile: () {},
          ),
          body: const SizedBox.shrink(),
        ),
      ),
    );

    scaffoldKey.currentState!.openDrawer();
    await tester.pumpAndSettle();

    expect(find.text('AYUDA'), findsOneWidget);
    expect(find.text('Reportar incidencia'), findsOneWidget);
  });
}
