import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/feedback/domain/feedback_report.dart';
import 'package:rutio/features/feedback/presentation/screens/feedback_detail_screen.dart';
import 'package:rutio/features/feedback/presentation/screens/my_feedback_screen.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';

void main() {
  testWidgets('renders mock reports and all filter shows every item',
      (tester) async {
    await _pumpWidget(tester, const MyFeedbackScreen());

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    expect(find.text(l10n.feedbackCategoryBugTitle), findsOneWidget);
    expect(find.text(l10n.feedbackCategoryImprovementTitle), findsOneWidget);
    expect(find.text(l10n.feedbackCategorySuggestionTitle), findsOneWidget);
    expect(find.text(l10n.feedbackCategoryOtherTitle), findsOneWidget);
  });

  testWidgets('submitted filter shows only submitted reports', (tester) async {
    await _pumpWidget(tester, const MyFeedbackScreen());

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    await tester
        .tap(find.widgetWithText(ChoiceChip, l10n.feedbackFilterSubmitted));
    await tester.pumpAndSettle();

    expect(find.text(l10n.feedbackCategoryBugTitle), findsOneWidget);
    expect(find.text(l10n.feedbackCategoryImprovementTitle), findsNothing);
    expect(find.text(l10n.feedbackCategorySuggestionTitle), findsNothing);
    expect(find.text(l10n.feedbackCategoryOtherTitle), findsNothing);
  });

  testWidgets('in review filter shows only in review reports', (tester) async {
    await _pumpWidget(tester, const MyFeedbackScreen());

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    await tester
        .tap(find.widgetWithText(ChoiceChip, l10n.feedbackFilterInReview));
    await tester.pumpAndSettle();

    expect(find.text(l10n.feedbackCategoryImprovementTitle), findsOneWidget);
    expect(find.text(l10n.feedbackCategoryBugTitle), findsNothing);
    expect(find.text(l10n.feedbackCategorySuggestionTitle), findsNothing);
    expect(find.text(l10n.feedbackCategoryOtherTitle), findsNothing);
  });

  testWidgets('closed filter groups resolved and dismissed reports',
      (tester) async {
    await _pumpWidget(tester, const MyFeedbackScreen());

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    await tester
        .tap(find.widgetWithText(ChoiceChip, l10n.feedbackFilterClosed));
    await tester.pumpAndSettle();

    expect(find.text(l10n.feedbackCategorySuggestionTitle), findsOneWidget);
    expect(find.text(l10n.feedbackCategoryOtherTitle), findsOneWidget);
    expect(find.text(l10n.feedbackCategoryBugTitle), findsNothing);
    expect(find.text(l10n.feedbackCategoryImprovementTitle), findsNothing);
  });

  testWidgets('tapping a card opens the detail route', (tester) async {
    final observer = _RecordingNavigatorObserver();

    await tester.pumpWidget(
      _app(
        const MyFeedbackScreen(),
        navigatorObservers: [observer],
        routes: {
          '/feedback/detail': (context) {
            final report =
                ModalRoute.of(context)!.settings.arguments as FeedbackReport;
            return FeedbackDetailScreen(report: report);
          },
        },
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    await _dragUntilTextVisible(tester, l10n.feedbackCategorySuggestionTitle);
    await tester.tap(find.text(l10n.feedbackCategorySuggestionTitle));
    await tester.pumpAndSettle();

    expect(observer.lastPushedRouteName, '/feedback/detail');
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

class _RecordingNavigatorObserver extends NavigatorObserver {
  String? lastPushedRouteName;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    lastPushedRouteName = route.settings.name;
    super.didPush(route, previousRoute);
  }
}
