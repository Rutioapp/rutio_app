import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/repositories/repository_result.dart';
import 'package:rutio/features/feedback/data/feedback_repository.dart';
import 'package:rutio/features/feedback/domain/feedback_category.dart';
import 'package:rutio/features/feedback/domain/feedback_report.dart';
import 'package:rutio/features/feedback/domain/feedback_status.dart';
import 'package:rutio/features/feedback/domain/feedback_technical_context.dart';
import 'package:rutio/features/feedback/presentation/screens/feedback_detail_screen.dart';
import 'package:rutio/features/feedback/presentation/screens/my_feedback_screen.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';

void main() {
  testWidgets('loading state is shown while the repository resolves',
      (tester) async {
    final completer = Completer<RepositoryResult<List<FeedbackReport>>>();
    final repository = _FakeFeedbackRepository(pendingResult: completer);

    await _pumpWidget(
      tester,
      MyFeedbackScreen(repository: repository),
      settle: false,
    );
    await tester.pump();

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(l10n.feedbackMineLoadingState), findsOneWidget);

    completer.complete(
      const RepositoryResult<List<FeedbackReport>>.success(
        data: <FeedbackReport>[],
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('empty state is shown when there are no submissions',
      (tester) async {
    await _pumpWidget(
      tester,
      MyFeedbackScreen(
        repository: _FakeFeedbackRepository(
          result: const RepositoryResult<List<FeedbackReport>>.success(
            data: <FeedbackReport>[],
          ),
        ),
      ),
    );

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    expect(find.text(l10n.feedbackMineEmptyState), findsOneWidget);
  });

  testWidgets('error state offers a retry that reloads data', (tester) async {
    final repository = _FakeFeedbackRepository(
      queue: <RepositoryResult<List<FeedbackReport>>>[
        const RepositoryResult<List<FeedbackReport>>.failure(
          RepositoryError(
            code: RepositoryErrorCode.network,
            message: 'network down',
          ),
        ),
        RepositoryResult<List<FeedbackReport>>.success(
          data: <FeedbackReport>[
            _report(
              id: 'feedback-1',
              description: 'Recovered report',
              category: FeedbackCategory.bug,
              status: FeedbackStatus.submitted,
              createdAt: DateTime(2026, 8, 30, 12, 0),
            ),
          ],
        ),
      ],
    );

    await _pumpWidget(tester, MyFeedbackScreen(repository: repository));

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    expect(find.text(l10n.feedbackMineErrorTitle), findsOneWidget);
    expect(find.text(l10n.feedbackMineRetryAction), findsOneWidget);

    await tester
        .tap(find.widgetWithText(FilledButton, l10n.feedbackMineRetryAction));
    await tester.pumpAndSettle();

    expect(find.text('Recovered report'), findsOneWidget);
    expect(repository.callCount, 2);
  });

  testWidgets('reports render in created_at descending order', (tester) async {
    await _pumpWidget(
      tester,
      MyFeedbackScreen(
        repository: _FakeFeedbackRepository(
          result: RepositoryResult<List<FeedbackReport>>.success(
            data: <FeedbackReport>[
              _report(
                id: 'old',
                description: 'Oldest report',
                category: FeedbackCategory.bug,
                status: FeedbackStatus.submitted,
                createdAt: DateTime(2026, 8, 28, 10, 0),
              ),
              _report(
                id: 'new',
                description: 'Newest report',
                category: FeedbackCategory.suggestion,
                status: FeedbackStatus.inReview,
                createdAt: DateTime(2026, 8, 30, 10, 0),
              ),
              _report(
                id: 'middle',
                description: 'Middle report',
                category: FeedbackCategory.improvement,
                status: FeedbackStatus.resolved,
                createdAt: DateTime(2026, 8, 29, 10, 0),
              ),
            ],
          ),
        ),
      ),
    );

    final newest = tester.getTopLeft(find.text('Newest report'));
    final middle = tester.getTopLeft(find.text('Middle report'));
    final oldest = tester.getTopLeft(find.text('Oldest report'));

    expect(newest.dy, lessThan(middle.dy));
    expect(middle.dy, lessThan(oldest.dy));
  });

  testWidgets('filters remain local to the loaded list', (tester) async {
    await _pumpWidget(
      tester,
      MyFeedbackScreen(
        repository: _FakeFeedbackRepository(
          result: RepositoryResult<List<FeedbackReport>>.success(
            data: <FeedbackReport>[
              _report(
                id: 'resolved',
                description: 'Resolved report',
                category: FeedbackCategory.bug,
                status: FeedbackStatus.resolved,
                createdAt: DateTime(2026, 8, 30, 13, 0),
              ),
              _report(
                id: 'dismissed',
                description: 'Dismissed report',
                category: FeedbackCategory.other,
                status: FeedbackStatus.dismissed,
                createdAt: DateTime(2026, 8, 30, 12, 0),
              ),
              _report(
                id: 'review',
                description: 'In review report',
                category: FeedbackCategory.suggestion,
                status: FeedbackStatus.inReview,
                createdAt: DateTime(2026, 8, 30, 11, 0),
              ),
              _report(
                id: 'submitted',
                description: 'Submitted report',
                category: FeedbackCategory.improvement,
                status: FeedbackStatus.submitted,
                createdAt: DateTime(2026, 8, 30, 10, 0),
              ),
            ],
          ),
        ),
      ),
    );

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    expect(find.text('Resolved report'), findsOneWidget);
    expect(find.text('Dismissed report'), findsOneWidget);
    expect(find.text('In review report'), findsOneWidget);
    expect(find.text('Submitted report'), findsOneWidget);

    await tester
        .tap(find.widgetWithText(ChoiceChip, l10n.feedbackFilterSubmitted));
    await tester.pumpAndSettle();
    expect(find.text('Submitted report'), findsOneWidget);
    expect(find.text('Resolved report'), findsNothing);
    expect(find.text('Dismissed report'), findsNothing);
    expect(find.text('In review report'), findsNothing);

    await tester
        .tap(find.widgetWithText(ChoiceChip, l10n.feedbackFilterInReview));
    await tester.pumpAndSettle();
    expect(find.text('In review report'), findsOneWidget);
    expect(find.text('Submitted report'), findsNothing);

    await tester
        .tap(find.widgetWithText(ChoiceChip, l10n.feedbackFilterClosed));
    await tester.pumpAndSettle();
    expect(find.text('Resolved report'), findsOneWidget);
    expect(find.text('Dismissed report'), findsOneWidget);
    expect(find.text('In review report'), findsNothing);
    expect(find.text('Submitted report'), findsNothing);
  });

  testWidgets('tapping a report opens the detail screen with the report',
      (tester) async {
    final expectedReport = _report(
      id: 'feedback-1',
      description: 'Tap opens detail',
      category: FeedbackCategory.bug,
      status: FeedbackStatus.submitted,
      createdAt: DateTime(2026, 8, 30, 10, 0),
      teamResponse: null,
      screenshotPath: null,
    );
    FeedbackReport? receivedReport;

    await tester.pumpWidget(
      _app(
        MyFeedbackScreen(
          repository: _FakeFeedbackRepository(
            result: RepositoryResult<List<FeedbackReport>>.success(
              data: <FeedbackReport>[expectedReport],
            ),
          ),
        ),
        routes: {
          '/feedback/detail': (context) {
            final report =
                ModalRoute.of(context)!.settings.arguments as FeedbackReport;
            receivedReport = report;
            return FeedbackDetailScreen(report: report);
          },
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tap opens detail'));
    await tester.pumpAndSettle();

    expect(receivedReport, same(expectedReport));
  });
}

Widget _app(
  Widget child, {
  Map<String, WidgetBuilder>? routes,
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
    routes: routes ?? const {},
    home: child,
  );
}

Future<void> _pumpWidget(
  WidgetTester tester,
  Widget child, {
  bool settle = true,
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 2600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_app(child));
  if (settle) {
    await tester.pumpAndSettle();
  }
}

class _FakeFeedbackRepository implements FeedbackRepository {
  _FakeFeedbackRepository({
    this.result,
    this.pendingResult,
    List<RepositoryResult<List<FeedbackReport>>>? queue,
  }) : _queue = queue != null
            ? List<RepositoryResult<List<FeedbackReport>>>.from(queue)
            : <RepositoryResult<List<FeedbackReport>>>[];

  final RepositoryResult<List<FeedbackReport>>? result;
  final Completer<RepositoryResult<List<FeedbackReport>>>? pendingResult;
  final List<RepositoryResult<List<FeedbackReport>>> _queue;

  int callCount = 0;

  @override
  Future<RepositoryResult<FeedbackReport>> createFeedback({
    required String id,
    required FeedbackCategory category,
    required String description,
    required bool contactAllowed,
    required FeedbackTechnicalContext technicalContext,
    String? screenshotPath,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<RepositoryResult<List<FeedbackReport>>> getMyFeedback() async {
    callCount += 1;
    if (pendingResult != null) {
      return pendingResult!.future;
    }
    if (_queue.isNotEmpty) {
      return _queue.removeAt(0);
    }
    return result ??
        const RepositoryResult<List<FeedbackReport>>.success(
          data: <FeedbackReport>[],
        );
  }
}

FeedbackReport _report({
  required String id,
  required String description,
  required FeedbackCategory category,
  required FeedbackStatus status,
  required DateTime createdAt,
  String? screenshotPath,
  String? teamResponse,
}) {
  return FeedbackReport(
    id: id,
    category: category,
    description: description,
    screenshotPath: screenshotPath,
    contactAllowed: false,
    status: status,
    teamResponse: teamResponse,
    createdAt: createdAt,
  );
}
