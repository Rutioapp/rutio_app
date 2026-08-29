import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/feedback/presentation/mock/feedback_mock_reports.dart';
import 'package:rutio/features/feedback/presentation/screens/feedback_success_screen.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';

void main() {
  testWidgets('shows success summary and progress', (tester) async {
    await _pumpWidget(
      tester,
      FeedbackSuccessScreen(report: FeedbackMockReports.examples.first),
    );

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    expect(find.text(l10n.feedbackSuccessTitle), findsWidgets);
    expect(find.text(l10n.feedbackSuccessBody), findsOneWidget);
    expect(find.text(l10n.feedbackStatusSubmitted), findsWidgets);
    expect(find.text(l10n.feedbackSuccessMineAction), findsOneWidget);
    expect(find.text(l10n.feedbackSuccessHomeAction), findsOneWidget);
    expect(find.text(l10n.feedbackSuccessCanEditDelete), findsOneWidget);
  });

  testWidgets('view submissions navigates to /feedback/mine', (tester) async {
    final observer = _RecordingNavigatorObserver();

    await tester.pumpWidget(
      _app(
        FeedbackSuccessScreen(report: FeedbackMockReports.examples.first),
        navigatorObservers: [observer],
        routes: {
          '/feedback/mine': (_) => const SizedBox.shrink(),
          '/feedback': (_) => const SizedBox.shrink(),
        },
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    await _dragUntilTextVisible(tester, l10n.feedbackSuccessMineAction);
    await tester.tap(find.text(l10n.feedbackSuccessMineAction));
    await tester.pumpAndSettle();

    expect(observer.lastPushedRouteName, '/feedback/mine');
  });

  testWidgets('back to feedback returns to the feedback route', (tester) async {
    await tester.pumpWidget(
      _pushedApp(
        FeedbackSuccessScreen(report: FeedbackMockReports.examples.first),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    await _dragUntilTextVisible(tester, l10n.feedbackSuccessHomeAction);
    await tester.tap(find.text(l10n.feedbackSuccessHomeAction));
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
    expect(find.byType(FeedbackSuccessScreen), findsNothing);
  });
}

Future<void> _pumpWidget(WidgetTester tester, Widget child) async {
  await tester.binding.setSurfaceSize(const Size(800, 2600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_app(child));
  await tester.pumpAndSettle();
}

Future<void> _dragUntilTextVisible(WidgetTester tester, String text) async {
  final scrollable = find.byType(Scrollable).first;
  for (var i = 0; i < 12 && find.text(text).evaluate().isEmpty; i++) {
    await tester.drag(scrollable, const Offset(0, -500));
    await tester.pumpAndSettle();
  }
  expect(find.text(text), findsWidgets);
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
    builder: (context, child) {
      final mediaQuery = MediaQuery.of(context);
      return MediaQuery(
        data: mediaQuery.copyWith(
          size: const Size(800, 2600),
          padding: EdgeInsets.zero,
          viewInsets: EdgeInsets.zero,
        ),
        child: child ?? const SizedBox.shrink(),
      );
    },
    home: child,
  );
}

Widget _pushedApp(Widget child) {
  var pushed = false;
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
    initialRoute: '/feedback',
    builder: (context, child) {
      final mediaQuery = MediaQuery.of(context);
      return MediaQuery(
        data: mediaQuery.copyWith(
          size: const Size(800, 2600),
          padding: EdgeInsets.zero,
          viewInsets: EdgeInsets.zero,
        ),
        child: child ?? const SizedBox.shrink(),
      );
    },
    routes: {
      '/feedback': (_) => Builder(
            builder: (context) {
              if (!pushed) {
                pushed = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => child),
                  );
                });
              }
              return const Scaffold(
                body: Center(child: Text('home')),
              );
            },
          ),
    },
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
