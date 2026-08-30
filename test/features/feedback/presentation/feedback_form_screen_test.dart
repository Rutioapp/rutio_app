import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/repositories/repository_result.dart';
import 'package:rutio/features/feedback/application/feedback_form_controller.dart';
import 'package:rutio/features/feedback/data/feedback_repository.dart';
import 'package:rutio/features/feedback/data/feedback_technical_context_service.dart';
import 'package:rutio/features/feedback/domain/feedback_category.dart';
import 'package:rutio/features/feedback/domain/feedback_report.dart';
import 'package:rutio/features/feedback/domain/feedback_status.dart';
import 'package:rutio/features/feedback/domain/feedback_technical_context.dart';
import 'package:rutio/features/feedback/presentation/screens/feedback_form_screen.dart';
import 'package:rutio/features/feedback/presentation/screens/feedback_success_screen.dart';
import 'package:rutio/features/feedback/presentation/widgets/feedback_category_card.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';

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
      feedbackIdGenerator: () => 'feedback-123',
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

  testWidgets('screenshot field shows the empty placeholder', (tester) async {
    await _pumpApp(tester, FeedbackFormScreen(controller: _buildController()));

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    await _scrollToText(tester, l10n.feedbackScreenshotTitle);
    expect(find.text(l10n.feedbackScreenshotTitle), findsWidgets);
    expect(find.text(l10n.feedbackScreenshotPlaceholder), findsWidgets);
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
      id: 'feedback-123',
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
      feedbackIdGenerator: () => 'feedback-123',
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
      feedbackIdGenerator: () => 'feedback-123',
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

Future<void> _pumpApp(
  WidgetTester tester,
  Widget child, {
  Map<String, WidgetBuilder>? routes,
  List<NavigatorObserver>? navigatorObservers,
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 2600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    _app(
      child,
      routes: routes,
      navigatorObservers: navigatorObservers,
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

FeedbackFormController _buildController({
  RepositoryResult<FeedbackReport>? result,
  FeedbackTechnicalContext? technicalContext,
}) {
  final controller = FeedbackFormController(
    repository: _FakeFeedbackRepository(result: result),
    technicalContextService: _FakeTechnicalContextService(
      context: technicalContext ?? _FakeTechnicalContextService.defaultContext,
    ),
    feedbackIdGenerator: () => 'feedback-123',
  );
  addTearDown(controller.dispose);
  return controller;
}

class _FakeFeedbackRepository implements FeedbackRepository {
  _FakeFeedbackRepository({
    this.result,
  });

  final RepositoryResult<FeedbackReport>? result;
  _CreateFeedbackRequest? lastRequest;

  @override
  Future<RepositoryResult<FeedbackReport>> createFeedback({
    required String id,
    required FeedbackCategory category,
    required String description,
    required bool contactAllowed,
    required FeedbackTechnicalContext technicalContext,
    String? screenshotPath,
  }) async {
    lastRequest = _CreateFeedbackRequest(
      id: id,
      category: category,
      description: description,
      contactAllowed: contactAllowed,
      technicalContext: technicalContext,
      screenshotPath: screenshotPath,
    );
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
