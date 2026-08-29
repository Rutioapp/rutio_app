import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/feedback/domain/feedback_status.dart';
import 'package:rutio/features/feedback/presentation/widgets/feedback_progress_indicator.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';

void main() {
  testWidgets('submitted shows the first step active', (tester) async {
    await _pumpWidget(tester, FeedbackStatus.submitted);

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    expect(find.text(l10n.feedbackProgressSubmitted), findsWidgets);
    expect(find.text(l10n.feedbackProgressInReview), findsWidgets);
    expect(find.text(l10n.feedbackProgressTerminalLabel), findsWidgets);
  });

  testWidgets('resolved shows the resolved terminal state', (tester) async {
    await _pumpWidget(tester, FeedbackStatus.resolved);

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    expect(find.text(l10n.feedbackStatusResolved), findsWidgets);
    expect(find.text(l10n.feedbackProgressTerminalLabel), findsNothing);
  });

  testWidgets('dismissed shows the dismissed terminal state', (tester) async {
    await _pumpWidget(tester, FeedbackStatus.dismissed);

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    expect(find.text(l10n.feedbackStatusDismissed), findsWidgets);
    expect(find.text(l10n.feedbackProgressTerminalLabel), findsNothing);
  });
}

Future<void> _pumpWidget(WidgetTester tester, FeedbackStatus status) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('es'),
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: FeedbackProgressIndicator(status: status),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
