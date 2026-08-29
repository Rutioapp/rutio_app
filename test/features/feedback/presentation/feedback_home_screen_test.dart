import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:rutio/features/feedback/presentation/screens/feedback_home_screen.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';

void main() {
  testWidgets('FeedbackHomeScreen renders the two actions', (tester) async {
    await tester.pumpWidget(_app(const FeedbackHomeScreen()));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    expect(find.text(l10n.feedbackTitle), findsWidgets);
    expect(find.text(l10n.feedbackSendAction), findsOneWidget);
    expect(find.text(l10n.feedbackMineAction), findsOneWidget);
  });

  testWidgets('FeedbackHomeScreen navigates to /feedback/new', (tester) async {
    final observer = _RecordingNavigatorObserver();

    await tester.pumpWidget(
      _app(
        const FeedbackHomeScreen(),
        navigatorObservers: [observer],
        routes: {
          '/feedback/new': (_) => const SizedBox.shrink(),
          '/feedback/mine': (_) => const SizedBox.shrink(),
        },
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    await tester.tap(find.text(l10n.feedbackSendAction));
    await tester.pumpAndSettle();

    expect(observer.lastPushedRouteName, '/feedback/new');
  });

  testWidgets('FeedbackHomeScreen navigates to /feedback/mine', (tester) async {
    final observer = _RecordingNavigatorObserver();

    await tester.pumpWidget(
      _app(
        const FeedbackHomeScreen(),
        navigatorObservers: [observer],
        routes: {
          '/feedback/new': (_) => const SizedBox.shrink(),
          '/feedback/mine': (_) => const SizedBox.shrink(),
        },
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    await tester.tap(find.text(l10n.feedbackMineAction));
    await tester.pumpAndSettle();

    expect(observer.lastPushedRouteName, '/feedback/mine');
  });
}

Widget _app(
  Widget child, {
  Map<String, WidgetBuilder>? routes,
  List<NavigatorObserver>? navigatorObservers,
}) {
  return MaterialApp(
    locale: const Locale('es'),
    theme: ThemeData(splashFactory: NoSplash.splashFactory),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    navigatorObservers: navigatorObservers ?? const [],
    routes: routes ?? const {},
    home: child,
  );
}

class _RecordingNavigatorObserver extends NavigatorObserver {
  String? lastPushedRouteName;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    lastPushedRouteName = route.settings.name;
    super.didPush(route, previousRoute);
  }
}
