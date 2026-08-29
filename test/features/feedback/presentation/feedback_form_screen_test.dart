import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/feedback/application/feedback_form_controller.dart';
import 'package:rutio/features/feedback/domain/feedback_category.dart';
import 'package:rutio/features/feedback/domain/feedback_report.dart';
import 'package:rutio/features/feedback/domain/feedback_status.dart';
import 'package:rutio/features/feedback/presentation/widgets/feedback_category_card.dart';
import 'package:rutio/features/feedback/presentation/screens/feedback_form_screen.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';

void main() {
  testWidgets('renders the four categories', (tester) async {
    await _pumpApp(tester, const FeedbackFormScreen());

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    expect(find.text(l10n.feedbackCategoryBugTitle), findsOneWidget);
    expect(find.text(l10n.feedbackCategorySuggestionTitle), findsOneWidget);
    expect(find.text(l10n.feedbackCategoryImprovementTitle), findsOneWidget);
    expect(find.text(l10n.feedbackCategoryOtherTitle), findsOneWidget);
  });

  testWidgets('selection visual state updates when tapping a category',
      (tester) async {
    await _pumpApp(tester, const FeedbackFormScreen());

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);
    final bugCardKey = const ValueKey('feedback-category-bug');
    expect(
      tester.widget<FeedbackCategoryCard>(find.byKey(bugCardKey)).selected,
      isFalse,
    );

    await tester.tap(find.text(l10n.feedbackCategoryBugTitle));
    await tester.pumpAndSettle();

    expect(
      tester.widget<FeedbackCategoryCard>(find.byKey(bugCardKey)).selected,
      isTrue,
    );
  });

  testWidgets('category help copy changes immediately', (tester) async {
    await _pumpApp(tester, const FeedbackFormScreen());

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    await _scrollToText(tester, l10n.feedbackCategoryGeneralHelp);
    expect(find.text(l10n.feedbackCategoryGeneralHelp), findsWidgets);

    await tester.tap(find.text(l10n.feedbackCategorySuggestionTitle));
    await tester.pumpAndSettle();

    await _scrollToText(tester, l10n.feedbackCategorySuggestionHelp);
    expect(find.text(l10n.feedbackCategorySuggestionHelp), findsWidgets);
  });

  testWidgets('CTA starts disabled', (tester) async {
    await _pumpApp(tester, const FeedbackFormScreen());

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);
    await _scrollToText(tester, l10n.feedbackSubmitAction);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, l10n.feedbackSubmitAction),
    );

    expect(button.onPressed, isNull);
  });

  testWidgets('CTA stays disabled with invalid description', (tester) async {
    await _pumpApp(tester, const FeedbackFormScreen());

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    await tester.tap(find.text(l10n.feedbackCategoryBugTitle));
    await tester.pumpAndSettle();

    await _scrollToText(tester, l10n.feedbackDescriptionHint);
    await tester.enterText(
      find.byType(TextField),
      'a' * 19,
    );
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, l10n.feedbackSubmitAction),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('CTA becomes active with category and valid description',
      (tester) async {
    await _pumpApp(tester, const FeedbackFormScreen());

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    await tester.tap(find.text(l10n.feedbackCategoryBugTitle));
    await tester.pumpAndSettle();

    await _scrollToText(tester, l10n.feedbackDescriptionHint);
    await tester.enterText(
      find.byType(TextField),
      'a' * 20,
    );
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, l10n.feedbackSubmitAction),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('contact switch updates local state', (tester) async {
    final controller = FeedbackFormController();
    addTearDown(controller.dispose);

    await _pumpApp(tester, FeedbackFormScreen(controller: controller));

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);
    expect(controller.contactAllowed, isFalse);

    await _scrollToText(tester, l10n.feedbackContactSwitchLabel);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(controller.contactAllowed, isTrue);
  });

  testWidgets('screenshot field shows the empty placeholder', (tester) async {
    await _pumpApp(tester, const FeedbackFormScreen());

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    await _scrollToText(tester, l10n.feedbackScreenshotTitle);
    expect(find.text(l10n.feedbackScreenshotTitle), findsWidgets);
    expect(find.text(l10n.feedbackScreenshotPlaceholder), findsWidgets);
  });

  testWidgets('dirty back navigation opens a confirmation dialog',
      (tester) async {
    await _pumpPushedApp(tester, const FeedbackFormScreen());

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    await tester.tap(find.text(l10n.feedbackCategoryBugTitle));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text(l10n.feedbackExitConfirmTitle), findsOneWidget);
    expect(find.text(l10n.feedbackExitConfirmLeave), findsOneWidget);
    expect(find.text(l10n.feedbackExitConfirmStay), findsOneWidget);
  });

  testWidgets('clean back navigation does not require confirmation',
      (tester) async {
    await _pumpPushedApp(tester, const FeedbackFormScreen());

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('submitting uses the temporary success callback', (tester) async {
    var submitted = false;
    FeedbackReport? receivedReport;

    await _pumpApp(
      tester,
      FeedbackFormScreen(
        onSubmitSuccess: (context, report) async {
          submitted = true;
          receivedReport = report;
        },
      ),
    );

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    await tester.tap(find.text(l10n.feedbackCategoryBugTitle));
    await tester.pumpAndSettle();
    await _scrollToText(tester, l10n.feedbackDescriptionHint);
    await tester.enterText(find.byType(TextField), 'a' * 20);
    await tester.pumpAndSettle();

    await _scrollToText(tester, l10n.feedbackSubmitAction);
    await tester
        .tap(find.widgetWithText(FilledButton, l10n.feedbackSubmitAction));
    await tester.pumpAndSettle();

    expect(submitted, isTrue);
    expect(receivedReport, isNotNull);
    expect(receivedReport!.status, FeedbackStatus.submitted);
    expect(receivedReport!.category, FeedbackCategory.bug);
  });
}

Widget _app(Widget child) {
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

Future<void> _pumpApp(WidgetTester tester, Widget child) async {
  await tester.binding.setSurfaceSize(const Size(800, 2600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_app(child));
  await tester.pumpAndSettle();
}

Future<void> _pumpPushedApp(WidgetTester tester, Widget child) async {
  await tester.binding.setSurfaceSize(const Size(800, 2600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_pushedApp(child));
  await tester.pumpAndSettle();
}

Widget _pushedApp(Widget child) {
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
    home: Builder(
      builder: (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => child),
          );
        });
        return const Scaffold(
          body: Center(child: Text('home')),
        );
      },
    ),
  );
}

Future<void> _scrollToText(WidgetTester tester, String text) async {
  final scrollable = find.byType(Scrollable).first;
  final target = find.text(text).first;
  await tester.scrollUntilVisible(
    target,
    400,
    scrollable: scrollable,
  );
  await tester.pumpAndSettle();
}
