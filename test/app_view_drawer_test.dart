import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/l10n/l10n.dart';
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);
    final supportSectionFinder = find.text(l10n.drawerSectionSupport);
    final reportIssueFinder = find.text(l10n.drawerReportIssue);

    await tester.scrollUntilVisible(
      supportSectionFinder,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(supportSectionFinder, findsOneWidget);
    expect(reportIssueFinder, findsOneWidget);
  });

  testWidgets('AppViewDrawer exposes a single visible statistics entry', (
    WidgetTester tester,
  ) async {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    var statsTapCount = 0;

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
            onGoStats: () => statsTapCount++,
            onGoProfile: () {},
          ),
          body: const SizedBox.shrink(),
        ),
      ),
    );

    scaffoldKey.currentState!.openDrawer();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);
    final statsFinder = find.text(l10n.drawerStatistics);
    final statsV3Finder = find.text(l10n.drawerStatisticsV3);

    expect(statsFinder, findsOneWidget);
    expect(statsV3Finder, findsNothing);

    await tester.tap(statsFinder);
    await tester.pumpAndSettle();

    expect(statsTapCount, 1);
  });
}
