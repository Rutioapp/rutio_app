import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rutio/data/repositories/repository_result.dart';
import 'package:rutio/features/feedback/application/feedback_form_controller.dart';
import 'package:rutio/features/feedback/data/feedback_image_service.dart';
import 'package:rutio/features/feedback/data/feedback_repository.dart';
import 'package:rutio/features/feedback/data/feedback_storage_service.dart';
import 'package:rutio/features/feedback/data/feedback_technical_context_service.dart';
import 'package:rutio/features/feedback/domain/feedback_category.dart';
import 'package:rutio/features/feedback/domain/feedback_report.dart';
import 'package:rutio/features/feedback/domain/feedback_status.dart';
import 'package:rutio/features/feedback/domain/feedback_technical_context.dart';
import 'package:rutio/features/feedback/presentation/screens/feedback_form_screen.dart';
import 'package:rutio/features/feedback/presentation/screens/feedback_success_screen.dart';
import 'package:rutio/features/feedback/presentation/widgets/feedback_category_card.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';

const String _feedbackUserId = '11111111-1111-1111-1111-111111111111';
const String _feedbackId = '22222222-2222-4222-8222-222222222222';
const String _screenshotId = '33333333-3333-4333-8333-333333333333';

void main() {
  testWidgets('renders the four categories', (tester) async {
    await _pumpApp(tester, FeedbackFormScreen(controller: _buildController()));

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    expect(find.text(l10n.feedbackCategoryBugTitle), findsOneWidget);
    expect(find.text(l10n.feedbackCategorySuggestionTitle), findsOneWidget);
    expect(find.text(l10n.feedbackCategoryImprovementTitle), findsOneWidget);
    expect(find.text(l10n.feedbackCategoryOtherTitle), findsOneWidget);
  });

  testWidgets('selection visual state updates when tapping a category',
      (tester) async {
    await _pumpApp(tester, FeedbackFormScreen(controller: _buildController()));

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

  testWidgets('category grid fits a small Android-like width without overflow',
      (tester) async {
    await _pumpApp(
      tester,
      FeedbackFormScreen(controller: _buildController()),
      surfaceSize: const Size(320, 640),
    );

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    expect(find.text(l10n.feedbackCategoryBugTitle), findsOneWidget);
    expect(find.text(l10n.feedbackCategorySuggestionTitle), findsOneWidget);
    expect(find.text(l10n.feedbackCategoryImprovementTitle), findsOneWidget);
    expect(find.text(l10n.feedbackCategoryOtherTitle), findsOneWidget);

    await _scrollToText(tester, l10n.feedbackCategoryBugTitle);
    await tester.tap(find.text(l10n.feedbackCategoryBugTitle));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<FeedbackCategoryCard>(find.byKey(
            const ValueKey('feedback-category-bug'),
          ))
          .selected,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('category grid stays safe with English copy and larger text',
      (tester) async {
    await _pumpApp(
      tester,
      FeedbackFormScreen(controller: _buildController()),
      surfaceSize: const Size(320, 640),
      locale: const Locale('en'),
      textScaleFactor: 1.3,
    );

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    expect(find.text(l10n.feedbackCategoryBugTitle), findsOneWidget);
    expect(find.text(l10n.feedbackCategorySuggestionTitle), findsOneWidget);
    expect(find.text(l10n.feedbackCategoryImprovementTitle), findsOneWidget);
    expect(find.text(l10n.feedbackCategoryOtherTitle), findsOneWidget);

    await _scrollToText(tester, l10n.feedbackCategoryBugTitle);
    await tester.tap(find.text(l10n.feedbackCategoryBugTitle));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<FeedbackCategoryCard>(find.byKey(
            const ValueKey('feedback-category-bug'),
          ))
          .selected,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('category help copy changes immediately', (tester) async {
    await _pumpApp(tester, FeedbackFormScreen(controller: _buildController()));

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
    await _pumpApp(tester, FeedbackFormScreen(controller: _buildController()));

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);
    await _scrollToText(tester, l10n.feedbackSubmitAction);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, l10n.feedbackSubmitAction),
    );

    expect(button.onPressed, isNull);
  });

  testWidgets('CTA stays disabled with invalid description', (tester) async {
    await _pumpApp(tester, FeedbackFormScreen(controller: _buildController()));

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
    await _pumpApp(tester, FeedbackFormScreen(controller: _buildController()));

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
    final controller = FeedbackFormController(
      repository: _FakeFeedbackRepository(),
      technicalContextService: _FakeTechnicalContextService(),
      feedbackIdGenerator: () => _feedbackId,
    );
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

  testWidgets('screenshot field supports preview replace and remove',
      (tester) async {
    final controller = _buildController(
      imageService: _FakeFeedbackImageService(
        selection: _selection(),
      ),
    );

    await _pumpApp(tester, FeedbackFormScreen(controller: controller));

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    await _scrollToText(tester, l10n.feedbackScreenshotTitle);
    expect(find.text(l10n.feedbackScreenshotTitle), findsWidgets);
    expect(find.text(l10n.feedbackScreenshotPlaceholder), findsWidgets);

    await tester.tap(
      find.widgetWithText(FilledButton, l10n.feedbackScreenshotSelectAction),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.feedbackScreenshotSelectedLabel), findsOneWidget);
    expect(find.text(l10n.feedbackScreenshotReplaceAction), findsOneWidget);
    expect(find.text(l10n.feedbackScreenshotRemoveAction), findsOneWidget);
    expect(controller.hasScreenshotSelection, isTrue);

    await tester.tap(
      find.widgetWithText(TextButton, l10n.feedbackScreenshotRemoveAction),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.feedbackScreenshotPlaceholder), findsWidgets);
    expect(controller.hasScreenshotSelection, isFalse);
  });

  testWidgets('screenshot selection errors are localized', (tester) async {
    final controller = _buildController(
      imageService: _FakeFeedbackImageService(
        pickError: const FeedbackImageException(
          FeedbackImageErrorType.unsupportedType,
        ),
      ),
    );

    await _pumpApp(tester, FeedbackFormScreen(controller: controller));

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    await _scrollToText(tester, l10n.feedbackScreenshotTitle);
    await tester.tap(
      find.widgetWithText(FilledButton, l10n.feedbackScreenshotSelectAction),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(l10n.feedbackScreenshotErrorUnsupported),
      findsOneWidget,
    );
  });

  testWidgets('submit disables screenshot actions while processing',
      (tester) async {
    final pending = Completer<RepositoryResult<FeedbackReport>>();
    final controller = _buildController(
      repository: _FakeFeedbackRepository(pendingResult: pending),
    );

    await _pumpApp(
      tester,
      FeedbackFormScreen(controller: controller),
      routes: {
        '/feedback/success': (_) => const SizedBox.shrink(),
      },
    );
    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    await tester.tap(find.text(l10n.feedbackCategoryBugTitle));
    await tester.pumpAndSettle();
    await _scrollToText(tester, l10n.feedbackDescriptionHint);
    await tester.enterText(find.byType(TextField), 'A' * 20);
    await tester.pumpAndSettle();
    await _scrollToText(tester, l10n.feedbackSubmitAction);
    await tester
        .tap(find.widgetWithText(FilledButton, l10n.feedbackSubmitAction));
    await tester.pump();

    final buttons = tester.widgetList<FilledButton>(find.byType(FilledButton));

    expect(buttons.every((button) => button.onPressed == null), isTrue);

    pending.complete(
      RepositoryResult<FeedbackReport>.success(
        data: _submittedReport(
          id: _feedbackId,
          category: FeedbackCategory.bug,
          description: 'A' * 20,
          contactAllowed: false,
          technicalContext: _FakeTechnicalContextService.defaultContext,
        ),
      ),
    );

    await tester.pumpAndSettle();
  });

  testWidgets('dirty back navigation opens a confirmation dialog',
      (tester) async {
    await _pumpPushedApp(
      tester,
      FeedbackFormScreen(controller: _buildController()),
    );

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
    await _pumpPushedApp(
      tester,
      FeedbackFormScreen(controller: _buildController()),
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('submitting navigates to success with the real report',
      (tester) async {
    final technicalContext = const FeedbackTechnicalContext(
      appVersion: '1.2.3',
      buildNumber: '456',
      platform: 'android',
      osVersion: '15',
      deviceModel: 'Pixel 8',
      appLocale: 'es_ES',
      sourceRoute: '/feedback/new',
    );
    final expectedReport = FeedbackReport(
      id: _feedbackId,
      category: FeedbackCategory.bug,
      description: 'A' * 20,
      contactAllowed: true,
      status: FeedbackStatus.submitted,
      technicalContext: technicalContext,
      createdAt: DateTime(2026, 8, 30, 12, 0),
    );
    final controller = FeedbackFormController(
      repository: _FakeFeedbackRepository(
        result: RepositoryResult<FeedbackReport>.success(data: expectedReport),
      ),
      technicalContextService: _FakeTechnicalContextService(
        context: technicalContext,
      ),
      feedbackIdGenerator: () => _feedbackId,
    );
    addTearDown(controller.dispose);

    FeedbackReport? receivedReport;
    await _pumpApp(
      tester,
      FeedbackFormScreen(controller: controller),
      routes: {
        '/feedback/success': (context) {
          receivedReport =
              ModalRoute.of(context)!.settings.arguments as FeedbackReport;
          return FeedbackSuccessScreen(report: receivedReport);
        },
      },
    );

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    await tester.tap(find.text(l10n.feedbackCategoryBugTitle));
    await tester.pumpAndSettle();
    await _scrollToText(tester, l10n.feedbackDescriptionHint);
    await tester.enterText(find.byType(TextField), 'A' * 20);
    await tester.pumpAndSettle();
    await _scrollToText(tester, l10n.feedbackSubmitAction);
    await tester
        .tap(find.widgetWithText(FilledButton, l10n.feedbackSubmitAction));
    await tester.pumpAndSettle();

    expect(receivedReport, same(expectedReport));
    expect(receivedReport!.technicalContext, same(technicalContext));
    expect(find.text(l10n.feedbackSuccessTitle), findsWidgets);
    expect(find.text(l10n.feedbackSuccessMineAction), findsOneWidget);
  });

  testWidgets('preselected screenshot renders in the form', (tester) async {
    final controller = _buildController(
      imageService: _FakeFeedbackImageService(
        selection: _selection(),
      ),
    );

    await controller.selectScreenshot();

    await _pumpApp(tester, FeedbackFormScreen(controller: controller));

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    expect(controller.hasScreenshotSelection, isTrue);
    expect(find.text(l10n.feedbackScreenshotSelectedLabel), findsOneWidget);
    expect(
        find.widgetWithText(
            OutlinedButton, l10n.feedbackScreenshotReplaceAction),
        findsOneWidget);
    expect(find.widgetWithText(TextButton, l10n.feedbackScreenshotRemoveAction),
        findsOneWidget);
  });

  testWidgets('failed submit shows a session-expired snackbar', (tester) async {
    final controller = FeedbackFormController(
      repository: _FakeFeedbackRepository(
        result: RepositoryResult<FeedbackReport>.failure(
          const RepositoryError(
            code: RepositoryErrorCode.notAuthenticated,
            message: 'No authenticated user session is available.',
          ),
        ),
      ),
      technicalContextService: _FakeTechnicalContextService(),
      feedbackIdGenerator: () => _feedbackId,
    );
    addTearDown(controller.dispose);

    await _pumpApp(tester, FeedbackFormScreen(controller: controller));

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    await tester.tap(find.text(l10n.feedbackCategoryBugTitle));
    await tester.pumpAndSettle();
    await _scrollToText(tester, l10n.feedbackDescriptionHint);
    await tester.enterText(find.byType(TextField), 'A' * 20);
    await tester.pumpAndSettle();
    await _scrollToText(tester, l10n.feedbackSubmitAction);
    await tester
        .tap(find.widgetWithText(FilledButton, l10n.feedbackSubmitAction));
    await tester.pumpAndSettle();

    expect(find.text(l10n.feedbackSubmitErrorSessionExpired), findsOneWidget);
  });
}

Widget _app(
  Widget child, {
  Map<String, WidgetBuilder>? routes,
  List<NavigatorObserver>? navigatorObservers,
  Locale locale = const Locale('es'),
  Size surfaceSize = const Size(800, 2600),
  double textScaleFactor = 1.0,
}) {
  return MaterialApp(
    locale: locale,
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
          size: surfaceSize,
          textScaler: TextScaler.linear(textScaleFactor),
          padding: EdgeInsets.zero,
          viewInsets: EdgeInsets.zero,
        ),
        child: child ?? const SizedBox.shrink(),
      );
    },
    home: child,
  );
}

Future<void> _pumpApp(
  WidgetTester tester,
  Widget child, {
  Map<String, WidgetBuilder>? routes,
  List<NavigatorObserver>? navigatorObservers,
  Locale locale = const Locale('es'),
  Size surfaceSize = const Size(800, 2600),
  double textScaleFactor = 1.0,
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    _app(
      child,
      routes: routes,
      navigatorObservers: navigatorObservers,
      locale: locale,
      surfaceSize: surfaceSize,
      textScaleFactor: textScaleFactor,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpPushedApp(WidgetTester tester, Widget child) async {
  await tester.binding.setSurfaceSize(const Size(800, 2600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_pushedApp(child));
  await tester.pumpAndSettle();
}

Widget _pushedApp(
  Widget child, {
  Locale locale = const Locale('es'),
  Size surfaceSize = const Size(800, 2600),
  double textScaleFactor = 1.0,
}) {
  return MaterialApp(
    locale: locale,
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
          size: surfaceSize,
          textScaler: TextScaler.linear(textScaleFactor),
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

FeedbackFormController _buildController({
  RepositoryResult<FeedbackReport>? result,
  FeedbackTechnicalContext? technicalContext,
  FeedbackImageService? imageService,
  FeedbackStorageService? storageService,
  FeedbackRepository? repository,
}) {
  final controller = FeedbackFormController(
    repository: repository ?? _FakeFeedbackRepository(result: result),
    technicalContextService: _FakeTechnicalContextService(
      context: technicalContext ?? _FakeTechnicalContextService.defaultContext,
    ),
    imageService: imageService ?? _FakeFeedbackImageService(),
    storageService: storageService ?? _FakeFeedbackStorageService(),
    feedbackIdGenerator: () => _feedbackId,
    screenshotIdGenerator: () => _screenshotId,
  );
  addTearDown(controller.dispose);
  return controller;
}

class _FakeFeedbackRepository implements FeedbackRepository {
  _FakeFeedbackRepository({
    this.result,
    this.pendingResult,
  });

  final RepositoryResult<FeedbackReport>? result;
  final Completer<RepositoryResult<FeedbackReport>>? pendingResult;
  _CreateFeedbackRequest? lastRequest;
  int callCount = 0;

  @override
  Future<RepositoryResult<FeedbackReport>> createFeedback({
    required String id,
    required FeedbackCategory category,
    required String description,
    required bool contactAllowed,
    required FeedbackTechnicalContext technicalContext,
    String? screenshotPath,
  }) async {
    callCount += 1;
    lastRequest = _CreateFeedbackRequest(
      id: id,
      category: category,
      description: description,
      contactAllowed: contactAllowed,
      technicalContext: technicalContext,
      screenshotPath: screenshotPath,
    );

    if (pendingResult != null) {
      return pendingResult!.future;
    }
    return result ??
        RepositoryResult<FeedbackReport>.success(
          data: FeedbackReport(
            id: id,
            category: category,
            description: description,
            contactAllowed: contactAllowed,
            status: FeedbackStatus.submitted,
            technicalContext: technicalContext,
            createdAt: DateTime(2026, 8, 30, 12, 0),
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
    return const RepositoryResult<List<FeedbackReport>>.failure(
      RepositoryError(
        code: RepositoryErrorCode.unknown,
        message: 'Not implemented in form screen tests.',
      ),
    );
  }

  @override
  Future<RepositoryResult<FeedbackReport>> getMyFeedbackById({
    required String feedbackId,
  }) async {
    return const RepositoryResult<FeedbackReport>.failure(
      RepositoryError(
        code: RepositoryErrorCode.notFound,
        message: 'Not implemented in form screen tests.',
      ),
    );
  }
}

class _FakeFeedbackImageService extends FeedbackImageService {
  _FakeFeedbackImageService({
    this.selection,
    this.pickError,
  }) : super(
          picker: _NoopImagePicker(),
          compressor: _NoopImageCompressor(),
          tempDirectoryProvider: _temporaryImageDirectory,
        );

  final FeedbackScreenshotSelection? selection;
  final FeedbackImageException? pickError;

  @override
  Future<FeedbackScreenshotSelection?> pickFromGallery() async {
    if (pickError != null) throw pickError!;
    return selection;
  }

  @override
  Future<FeedbackPreparedImage> prepareForUpload(
    FeedbackScreenshotSelection selection,
  ) async {
    final tempDir = await _temporaryImageDirectory();
    final file = File('${tempDir.path}/prepared.jpg')
      ..writeAsBytesSync(selection.previewBytes, flush: true);

    return FeedbackPreparedImage(
      file: file,
      bytes: selection.previewBytes,
      cleanup: () async {
        if (await file.exists()) {
          await file.delete();
        }
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      },
    );
  }
}

class _FakeFeedbackStorageService extends FeedbackStorageService {
  _FakeFeedbackStorageService()
      : super(
          gateway: _NoopStorageGateway(),
          currentUserIdProvider: () => _feedbackUserId,
        );

  int uploadCalls = 0;
  int removeCalls = 0;

  @override
  Future<String> uploadScreenshot({
    required String feedbackId,
    required String screenshotId,
    required FeedbackPreparedImage image,
  }) async {
    uploadCalls += 1;
    return buildScreenshotPath(
      userId: _feedbackUserId,
      feedbackId: feedbackId,
      screenshotId: screenshotId,
    );
  }

  @override
  Future<void> removeScreenshot({
    required String path,
  }) async {
    removeCalls += 1;
  }
}

class _FakeTechnicalContextService extends FeedbackTechnicalContextService {
  static const FeedbackTechnicalContext defaultContext =
      FeedbackTechnicalContext(
    appVersion: '1.0.0',
    buildNumber: '1',
    platform: 'android',
    osVersion: '15',
    deviceModel: 'device',
    appLocale: 'es_ES',
    sourceRoute: '/feedback/new',
  );

  _FakeTechnicalContextService({
    this.context = defaultContext,
  });

  final FeedbackTechnicalContext context;

  @override
  Future<FeedbackTechnicalContext> buildTechnicalContext({
    required String sourceRoute,
  }) async {
    return FeedbackTechnicalContext(
      appVersion: context.appVersion,
      buildNumber: context.buildNumber,
      platform: context.platform,
      osVersion: context.osVersion,
      deviceModel: context.deviceModel,
      appLocale: context.appLocale,
      sourceRoute: sourceRoute.trim(),
    );
  }
}

class _CreateFeedbackRequest {
  const _CreateFeedbackRequest({
    required this.id,
    required this.category,
    required this.description,
    required this.contactAllowed,
    required this.technicalContext,
    required this.screenshotPath,
  });

  final String id;
  final FeedbackCategory category;
  final String description;
  final bool contactAllowed;
  final FeedbackTechnicalContext technicalContext;
  final String? screenshotPath;
}

FeedbackReport _submittedReport({
  required String id,
  required FeedbackCategory category,
  required String description,
  required bool contactAllowed,
  required FeedbackTechnicalContext technicalContext,
}) {
  return FeedbackReport(
    id: id,
    category: category,
    description: description,
    contactAllowed: contactAllowed,
    status: FeedbackStatus.submitted,
    technicalContext: technicalContext,
    createdAt: DateTime(2026, 8, 30, 12, 0),
  );
}

class _NoopImagePicker implements FeedbackImagePicker {
  @override
  Future<XFile?> pickGalleryImage() async => null;
}

class _NoopImageCompressor implements FeedbackImageCompressor {
  @override
  Future<Uint8List?> compress({
    required String sourcePath,
    required int quality,
    required int minWidth,
    required int minHeight,
  }) async {
    return Uint8List.fromList(<int>[1, 2, 3]);
  }
}

class _NoopStorageGateway implements FeedbackStorageGateway {
  @override
  Future<void> remove({
    required String bucket,
    required String path,
  }) async {}

  @override
  Future<void> uploadBinary({
    required String bucket,
    required String path,
    required Uint8List bytes,
    required String contentType,
    required bool upsert,
  }) async {}

  @override
  Future<String> createSignedUrl({
    required String bucket,
    required String path,
    required int expiresInSeconds,
  }) async {
    return 'https://example.com/$bucket/$path?expires=$expiresInSeconds';
  }
}

FeedbackScreenshotSelection _selection() {
  final bytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAA'
    'AAC0lEQVR42mP8/x8AAwMCAO6X0WQAAAAASUVORK5CYII=',
  );
  final file = XFile.fromData(
    bytes,
    name: 'capture.png',
    mimeType: 'image/png',
  );

  return FeedbackScreenshotSelection(
    file: file,
    previewBytes: bytes,
    mimeType: 'image/png',
  );
}

Future<Directory> _temporaryImageDirectory() async {
  return Directory.systemTemp.createTemp('feedback-form-image-test-');
}
