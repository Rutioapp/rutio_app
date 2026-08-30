import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/feedback/domain/feedback_report.dart';
import 'package:rutio/features/feedback/presentation/mock/feedback_mock_reports.dart';
import 'package:rutio/features/feedback/presentation/screens/feedback_detail_screen.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';

void main() {
  testWidgets('submitted shows edit and delete actions', (tester) async {
    await _pumpWidget(tester, FeedbackMockReports.examples.first);

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    expect(find.text(l10n.feedbackEditAction), findsOneWidget);
    expect(find.text(l10n.feedbackDeleteAction), findsOneWidget);
  });

  testWidgets('other statuses do not show edit or delete actions',
      (tester) async {
    for (final report in FeedbackMockReports.examples.skip(1)) {
      await _pumpWidget(tester, report);

      final context = tester.element(find.byType(Scaffold));
      final l10n = AppLocalizations.of(context);

      expect(find.text(l10n.feedbackEditAction), findsNothing);
      expect(find.text(l10n.feedbackDeleteAction), findsNothing);
    }
  });

  testWidgets('team response renders and fallback without response works',
      (tester) async {
    await _pumpWidget(tester, FeedbackMockReports.examples[2]);

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    expect(find.text(l10n.feedbackResponseTitle), findsOneWidget);
    expect(find.text(l10n.feedbackResponseEmpty), findsNothing);

    await _pumpWidget(tester, FeedbackMockReports.examples.first);
    final fallbackContext = tester.element(find.byType(Scaffold));
    final fallbackL10n = AppLocalizations.of(fallbackContext);

    expect(find.text(fallbackL10n.feedbackResponseEmpty), findsOneWidget);
  });

  testWidgets('shows screenshot and date sections when available',
      (tester) async {
    await _pumpWidget(tester, FeedbackMockReports.examples[2]);

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    expect(find.text(l10n.feedbackDetailScreenshotLabel), findsOneWidget);
    expect(find.textContaining('mock://'), findsNothing);
    expect(find.text(l10n.feedbackDetailReviewDateLabel), findsOneWidget);
    expect(find.text(l10n.feedbackDetailClosedDateLabel), findsOneWidget);
  });
}

Future<void> _pumpWidget(WidgetTester tester, FeedbackReport report) async {
  await tester.binding.setSurfaceSize(const Size(800, 2600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
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
      home: FeedbackDetailScreen(report: report),
    ),
  );
  await tester.pumpAndSettle();
}
