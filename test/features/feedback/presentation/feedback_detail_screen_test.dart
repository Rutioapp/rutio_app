import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/repositories/repository_result.dart';
import 'package:rutio/features/feedback/application/feedback_detail_controller.dart';
import 'package:rutio/features/feedback/data/feedback_repository.dart';
import 'package:rutio/features/feedback/data/feedback_storage_service.dart';
import 'package:rutio/features/feedback/domain/feedback_category.dart';
import 'package:rutio/features/feedback/domain/feedback_report.dart';
import 'package:rutio/features/feedback/domain/feedback_status.dart';
import 'package:rutio/features/feedback/domain/feedback_technical_context.dart';
import 'package:rutio/features/feedback/presentation/screens/feedback_edit_screen.dart';
import 'package:rutio/features/feedback/presentation/screens/feedback_detail_screen.dart';
import 'package:rutio/features/feedback/application/feedback_mutation_result.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';

void main() {
  const userId = '11111111-1111-4111-8111-111111111111';
  const feedbackId = '22222222-2222-4222-8222-222222222222';
  const screenshotIdA = '33333333-3333-4333-8333-333333333333';

  testWidgets('loading state is shown while the repository resolves',
      (tester) async {
    final completer = Completer<RepositoryResult<FeedbackReport>>();
    final repository = _FakeFeedbackRepository(pendingResult: completer);

    await _pumpWidget(
      tester,
      FeedbackDetailScreen(
        report: _report(
          id: feedbackId,
          status: FeedbackStatus.submitted,
          createdAt: DateTime(2026, 8, 30, 10, 0),
        ),
        repository: repository,
        storageService: _storageService(),
      ),
      settle: false,
    );
    await tester.pump();

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text(l10n.feedbackDetailLoadingState), findsNothing);

    completer.complete(
      RepositoryResult<FeedbackReport>.success(
        data: _report(
          id: feedbackId,
          status: FeedbackStatus.submitted,
          createdAt: DateTime(2026, 8, 30, 10, 0),
        ),
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets(
      'loaded detail shows the authoritative report, team response and screenshot preview',
      (tester) async {
    await _pumpWidget(
      tester,
      FeedbackDetailScreen(
        report: _report(
          id: feedbackId,
          status: FeedbackStatus.submitted,
          createdAt: DateTime(2026, 8, 30, 10, 0),
          screenshotPath:
              '$userId/$feedbackId/screenshot_$screenshotIdA.jpg',
          teamResponse: 'We fixed it.',
          reviewStartedAt: DateTime(2026, 8, 30, 11, 0),
          closedAt: DateTime(2026, 8, 30, 12, 0),
        ),
        repository: _FakeFeedbackRepository(
          result: RepositoryResult<FeedbackReport>.success(
            data: _report(
              id: feedbackId,
              status: FeedbackStatus.submitted,
              createdAt: DateTime(2026, 8, 30, 10, 0),
              screenshotPath:
                  '$userId/$feedbackId/screenshot_$screenshotIdA.jpg',
              teamResponse: 'We fixed it.',
              reviewStartedAt: DateTime(2026, 8, 30, 11, 0),
              closedAt: DateTime(2026, 8, 30, 12, 0),
            ),
          ),
        ),
        storageService: _storageService(
          gateway: _FakeFeedbackStorageGateway(
            signedUrl: 'https://example.com/screenshot.png',
          ),
        ),
        screenshotPreviewBuilder: (context, signedUrl) => Container(
          key: const ValueKey('screenshot-preview'),
          color: Colors.transparent,
        ),
      ),
    );

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    expect(find.text('We fixed it.'), findsOneWidget);
    expect(find.text(l10n.feedbackDetailScreenshotLabel), findsOneWidget);
    expect(find.byKey(const ValueKey('screenshot-preview')), findsOneWidget);
    expect(find.text(l10n.feedbackEditAction), findsOneWidget);
    expect(find.text(l10n.feedbackDeleteAction), findsOneWidget);
    expect(find.textContaining('feedback-screenshots'), findsNothing);
  });

  testWidgets('team response fallback and no screenshot work', (tester) async {
    await _pumpWidget(
      tester,
      FeedbackDetailScreen(
        report: _report(
          id: feedbackId,
          status: FeedbackStatus.resolved,
          createdAt: DateTime(2026, 8, 30, 10, 0),
          teamResponse: null,
          screenshotPath: null,
        ),
        repository: _FakeFeedbackRepository(
          result: RepositoryResult<FeedbackReport>.success(
            data: _report(
              id: feedbackId,
              status: FeedbackStatus.resolved,
              createdAt: DateTime(2026, 8, 30, 10, 0),
              teamResponse: null,
              screenshotPath: null,
            ),
          ),
        ),
        storageService: _storageService(),
      ),
    );

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    expect(find.text(l10n.feedbackResponseEmpty), findsOneWidget);
    expect(find.text(l10n.feedbackDetailScreenshotLabel), findsNothing);
  });

  testWidgets('screenshot loading is isolated from the rest of the detail',
      (tester) async {
    final completer = Completer<String>();
    await _pumpWidget(
      tester,
      FeedbackDetailScreen(
        report: _report(
          id: feedbackId,
          status: FeedbackStatus.submitted,
          createdAt: DateTime(2026, 8, 30, 10, 0),
          screenshotPath:
              '$userId/$feedbackId/screenshot_$screenshotIdA.jpg',
        ),
        repository: _FakeFeedbackRepository(
          result: RepositoryResult<FeedbackReport>.success(
            data: _report(
              id: feedbackId,
              status: FeedbackStatus.submitted,
              createdAt: DateTime(2026, 8, 30, 10, 0),
              screenshotPath:
                  '$userId/$feedbackId/screenshot_$screenshotIdA.jpg',
            ),
          ),
        ),
        storageService: _storageService(
          gateway: _FakeFeedbackStorageGateway(pendingSignedUrl: completer),
        ),
      ),
      settle: false,
    );

    await tester.pump();

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    expect(find.text(l10n.feedbackDetailScreenshotLoading), findsOneWidget);
    expect(find.text(l10n.feedbackDetailDescriptionLabel), findsOneWidget);
    completer.complete('https://example.com/screenshot.png');
    await tester.pumpAndSettle();
  });

  testWidgets('screenshot errors keep the report usable and can retry',
      (tester) async {
    final gateway = _FakeFeedbackStorageGateway(failSignedUrl: true);
    final repository = _FakeFeedbackRepository(
      result: RepositoryResult<FeedbackReport>.success(
        data: _report(
          id: feedbackId,
          status: FeedbackStatus.submitted,
          createdAt: DateTime(2026, 8, 30, 10, 0),
          screenshotPath:
              '$userId/$feedbackId/screenshot_$screenshotIdA.jpg',
        ),
      ),
    );

    await _pumpWidget(
      tester,
      FeedbackDetailScreen(
        report: _report(
          id: feedbackId,
          status: FeedbackStatus.submitted,
          createdAt: DateTime(2026, 8, 30, 10, 0),
          screenshotPath:
              '$userId/$feedbackId/screenshot_$screenshotIdA.jpg',
        ),
        repository: repository,
        storageService: _storageService(gateway: gateway),
        screenshotPreviewBuilder: (context, signedUrl) => Container(
          key: const ValueKey('screenshot-preview'),
          color: Colors.transparent,
        ),
      ),
    );

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    expect(find.text(l10n.feedbackDetailScreenshotError), findsOneWidget);
    expect(find.text(l10n.feedbackEditAction), findsOneWidget);

    gateway.failSignedUrl = false;
    await tester.tap(find.widgetWithText(FilledButton, l10n.feedbackDetailRetryAction));
    await tester.pumpAndSettle();

    expect(find.text(l10n.feedbackDetailScreenshotError), findsNothing);
    expect(find.byKey(const ValueKey('screenshot-preview')), findsOneWidget);
    expect(repository.callCount, 1);
  });

  testWidgets('refresh updates status and removes edit/delete actions',
      (tester) async {
    final repository = _FakeFeedbackRepository(
      queue: <RepositoryResult<FeedbackReport>>[
        RepositoryResult<FeedbackReport>.success(
        data: _report(
            id: feedbackId,
            status: FeedbackStatus.submitted,
            createdAt: DateTime(2026, 8, 30, 10, 0),
          ),
        ),
        RepositoryResult<FeedbackReport>.success(
          data: _report(
            id: feedbackId,
            status: FeedbackStatus.inReview,
            createdAt: DateTime(2026, 8, 30, 10, 0),
            reviewStartedAt: DateTime(2026, 8, 30, 11, 0),
          ),
        ),
      ],
    );
    final controller = FeedbackDetailController(
      repository: repository,
      storageService: _storageService(),
    );
    addTearDown(controller.dispose);

    await _pumpWidget(
      tester,
      FeedbackDetailScreen(
        report: _report(
          id: feedbackId,
          status: FeedbackStatus.submitted,
          createdAt: DateTime(2026, 8, 30, 10, 0),
        ),
        controller: controller,
      ),
    );

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    expect(find.text(l10n.feedbackEditAction), findsOneWidget);
    expect(find.text(l10n.feedbackDeleteAction), findsOneWidget);

    await controller.refresh();
    await tester.pumpAndSettle();

    expect(find.text(l10n.feedbackEditAction), findsNothing);
    expect(find.text(l10n.feedbackDeleteAction), findsNothing);
    expect(find.text(l10n.feedbackStatusInReview), findsWidgets);
  });

  testWidgets('tapping edit opens the edit route with the authoritative report',
      (tester) async {
    final expectedReport = _report(
      id: feedbackId,
      status: FeedbackStatus.submitted,
      createdAt: DateTime(2026, 8, 30, 10, 0),
      description: 'Editable report',
    );
    final controller = FeedbackDetailController(
      repository: _FakeFeedbackRepository(detailResult: expectedReport),
      storageService: _storageService(),
    );
    addTearDown(controller.dispose);
    await controller.load(
      feedbackId,
      initialReport: expectedReport,
    );
    FeedbackReport? receivedReport;

    await tester.pumpWidget(
      _app(
        FeedbackDetailScreen(
          report: expectedReport,
          controller: controller,
        ),
        routes: {
          FeedbackEditScreen.route: (context) {
            receivedReport =
                ModalRoute.of(context)!.settings.arguments as FeedbackReport;
            return FeedbackEditScreen(
              report: receivedReport!,
              repository: _FakeFeedbackRepository(
                result: RepositoryResult<FeedbackReport>.success(
                  data: receivedReport!,
                ),
              ),
              storageService: _storageService(),
            );
          },
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('feedback-detail-edit-action')),
      200,
    );
    await tester.tap(find.byKey(const ValueKey('feedback-detail-edit-action')));
    await tester.pumpAndSettle();

    expect(find.byType(FeedbackEditScreen), findsOneWidget);
    expect(receivedReport, same(expectedReport));
  });

  testWidgets('saving from edit refreshes detail and keeps it visible',
      (tester) async {
    final initialReport = _report(
      id: feedbackId,
      status: FeedbackStatus.submitted,
      createdAt: DateTime(2026, 8, 30, 10, 0),
      description: 'Before edit',
    );
    final updatedReport = _report(
      id: feedbackId,
      status: FeedbackStatus.submitted,
      createdAt: DateTime(2026, 8, 30, 10, 0),
      description: 'After edit',
    );
    final repository = _FakeFeedbackRepository(
      queue: <RepositoryResult<FeedbackReport>>[
        RepositoryResult<FeedbackReport>.success(data: initialReport),
        RepositoryResult<FeedbackReport>.success(data: updatedReport),
        ],
      );
    final controller = FeedbackDetailController(
      repository: repository,
      storageService: _storageService(),
    );
    addTearDown(controller.dispose);
    await controller.load(
      feedbackId,
      initialReport: initialReport,
    );

    await tester.pumpWidget(
      _app(
        FeedbackDetailScreen(
          report: initialReport,
          controller: controller,
        ),
        routes: {
          FeedbackEditScreen.route: (context) {
            final report =
                ModalRoute.of(context)!.settings.arguments as FeedbackReport;
            return Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      FeedbackMutationResult.saved(updatedReport),
                    );
                  },
                  child: Text('save ${report.description}'),
                ),
              ),
            );
          },
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('feedback-detail-edit-action')),
      200,
    );
    await tester.tap(find.byKey(const ValueKey('feedback-detail-edit-action')));
    await tester.pumpAndSettle();

    expect(find.text('save Before edit'), findsOneWidget);

    await tester.tap(find.text('save Before edit'));
    await tester.pumpAndSettle();

    expect(find.byType(FeedbackEditScreen), findsNothing);
    expect(find.text('After edit'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('feedback-detail-edit-action')),
      findsOneWidget,
    );
  });

  testWidgets('in review and closed reports do not show edit', (tester) async {
    await _pumpWidget(
      tester,
      FeedbackDetailScreen(
        report: _report(
          id: feedbackId,
          status: FeedbackStatus.inReview,
          createdAt: DateTime(2026, 8, 30, 10, 0),
        ),
        repository: _FakeFeedbackRepository(
          result: RepositoryResult<FeedbackReport>.success(
            data: _report(
              id: feedbackId,
              status: FeedbackStatus.inReview,
              createdAt: DateTime(2026, 8, 30, 10, 0),
            ),
          ),
        ),
        storageService: _storageService(),
      ),
    );

    expect(find.text(AppLocalizations.of(tester.element(find.byType(Scaffold)))
        .feedbackEditAction), findsNothing);

    await _pumpWidget(
      tester,
      FeedbackDetailScreen(
        report: _report(
          id: feedbackId,
          status: FeedbackStatus.resolved,
          createdAt: DateTime(2026, 8, 30, 10, 0),
        ),
        repository: _FakeFeedbackRepository(
          result: RepositoryResult<FeedbackReport>.success(
            data: _report(
              id: feedbackId,
              status: FeedbackStatus.resolved,
              createdAt: DateTime(2026, 8, 30, 10, 0),
            ),
          ),
        ),
        storageService: _storageService(),
      ),
    );

    expect(find.text(AppLocalizations.of(tester.element(find.byType(Scaffold)))
        .feedbackEditAction), findsNothing);

    await _pumpWidget(
      tester,
      FeedbackDetailScreen(
        report: _report(
          id: feedbackId,
          status: FeedbackStatus.dismissed,
          createdAt: DateTime(2026, 8, 30, 10, 0),
        ),
        repository: _FakeFeedbackRepository(
          result: RepositoryResult<FeedbackReport>.success(
            data: _report(
              id: feedbackId,
              status: FeedbackStatus.dismissed,
              createdAt: DateTime(2026, 8, 30, 10, 0),
            ),
          ),
        ),
        storageService: _storageService(),
      ),
    );

    expect(find.text(AppLocalizations.of(tester.element(find.byType(Scaffold)))
        .feedbackEditAction), findsNothing);
  });

  testWidgets('load failure is shown with controlled copy', (tester) async {
    await _pumpWidget(
      tester,
      FeedbackDetailScreen(
        report: _report(
          id: feedbackId,
          status: FeedbackStatus.submitted,
          createdAt: DateTime(2026, 8, 30, 10, 0),
        ),
        repository: _FakeFeedbackRepository(
          result: const RepositoryResult<FeedbackReport>.failure(
            RepositoryError(
              code: RepositoryErrorCode.network,
              message: 'network down',
            ),
          ),
        ),
        storageService: _storageService(),
      ),
    );

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    expect(find.text(l10n.feedbackDetailErrorTitle), findsOneWidget);
    expect(find.text(l10n.feedbackDetailLoadErrorMessage), findsOneWidget);
  });

  testWidgets('not found is shown with controlled copy', (tester) async {
    final notFoundController = FeedbackDetailController(
      repository: _FakeFeedbackRepository(
        result: const RepositoryResult<FeedbackReport>.failure(
          RepositoryError(
            code: RepositoryErrorCode.notFound,
            message: 'missing',
          ),
        ),
      ),
      storageService: _storageService(),
    );
    addTearDown(notFoundController.dispose);

    await notFoundController.load(
      feedbackId,
      initialReport: _report(
        id: feedbackId,
        status: FeedbackStatus.submitted,
        createdAt: DateTime(2026, 8, 30, 10, 0),
      ),
    );

    await _pumpWidget(
      tester,
      FeedbackDetailScreen(
        report: _report(
          id: feedbackId,
          status: FeedbackStatus.submitted,
          createdAt: DateTime(2026, 8, 30, 10, 0),
        ),
        controller: notFoundController,
      ),
    );

    expect(find.byType(FilledButton), findsOneWidget);
    final notFoundCopyMatches = find
            .textContaining('disponible')
            .evaluate()
            .isNotEmpty ||
        find.textContaining('available').evaluate().isNotEmpty;
    expect(notFoundCopyMatches, isTrue);
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

FeedbackReport _report({
  required String id,
  required FeedbackStatus status,
  required DateTime createdAt,
  String? description,
  String? screenshotPath,
  String? teamResponse,
  DateTime? reviewStartedAt,
  DateTime? closedAt,
}) {
  return FeedbackReport(
    id: id,
    category: FeedbackCategory.bug,
    description: description ?? 'Report $id',
    screenshotPath: screenshotPath,
    contactAllowed: false,
    status: status,
    teamResponse: teamResponse,
    createdAt: createdAt,
    reviewStartedAt: reviewStartedAt,
    closedAt: closedAt,
  );
}

FeedbackStorageService _storageService({
  _FakeFeedbackStorageGateway? gateway,
}) {
  return FeedbackStorageService(
    gateway: gateway ?? _FakeFeedbackStorageGateway(),
    currentUserIdProvider: () => 'user-1',
  );
}

class _FakeFeedbackRepository implements FeedbackRepository {
  _FakeFeedbackRepository({
    this.result,
    this.pendingResult,
    this.detailResult,
    List<RepositoryResult<FeedbackReport>>? queue,
  }) : _queue = queue != null
            ? List<RepositoryResult<FeedbackReport>>.from(queue)
            : <RepositoryResult<FeedbackReport>>[];

  final RepositoryResult<FeedbackReport>? result;
  final Completer<RepositoryResult<FeedbackReport>>? pendingResult;
  final FeedbackReport? detailResult;
  final List<RepositoryResult<FeedbackReport>> _queue;
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
  Future<RepositoryResult<FeedbackReport>> getMyFeedbackById({
    required String feedbackId,
  }) async {
    callCount += 1;
    final report = detailResult;
    if (report != null) {
      return RepositoryResult<FeedbackReport>.success(data: report);
    }
    if (pendingResult != null) {
      return pendingResult!.future;
    }
    if (_queue.isNotEmpty) {
      return _queue.removeAt(0);
    }
    return result ??
        const RepositoryResult<FeedbackReport>.failure(
          RepositoryError(
            code: RepositoryErrorCode.notFound,
            message: 'missing',
          ),
        );
  }

  @override
  Future<RepositoryResult<FeedbackReport>> updateMyFeedback({
    required String feedbackId,
    required String description,
    required bool contactAllowed,
    String? screenshotPath,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<RepositoryResult<String?>> deleteMyFeedback({
    required String feedbackId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<RepositoryResult<List<FeedbackReport>>> getMyFeedback() async {
    return const RepositoryResult<List<FeedbackReport>>.success(
      data: <FeedbackReport>[],
    );
  }
}

class _FakeFeedbackStorageGateway implements FeedbackStorageGateway {
  _FakeFeedbackStorageGateway({
    this.failSignedUrl = false,
    this.signedUrl,
    this.pendingSignedUrl,
  });

  bool failSignedUrl;
  final String? signedUrl;
  final Completer<String>? pendingSignedUrl;
  final List<String> requestedPaths = <String>[];

  @override
  Future<void> remove({
    required String bucket,
    required String path,
  }) async {}

  @override
  Future<String> createSignedUrl({
    required String bucket,
    required String path,
    required int expiresInSeconds,
  }) async {
    requestedPaths.add(path);
    if (pendingSignedUrl != null) {
      return pendingSignedUrl!.future;
    }
    if (failSignedUrl) {
      throw StateError('signed url failed');
    }
    return signedUrl ??
        'https://example.com/$bucket/$path?signed=${requestedPaths.length}';
  }

  @override
  Future<void> uploadBinary({
    required String bucket,
    required String path,
    required Uint8List bytes,
    required String contentType,
    required bool upsert,
  }) async {}
}
