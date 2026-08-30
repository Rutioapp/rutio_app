import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/repositories/repository_result.dart';
import 'package:rutio/features/feedback/application/feedback_form_controller.dart';
import 'package:rutio/features/feedback/data/feedback_repository.dart';
import 'package:rutio/features/feedback/data/feedback_technical_context_service.dart';
import 'package:rutio/features/feedback/domain/feedback_category.dart';
import 'package:rutio/features/feedback/domain/feedback_report.dart';
import 'package:rutio/features/feedback/domain/feedback_status.dart';
import 'package:rutio/features/feedback/domain/feedback_technical_context.dart';

void main() {
  test('initial category is null', () {
    final controller = FeedbackFormController(
      repository: _FakeFeedbackRepository(),
      technicalContextService: _FakeTechnicalContextService(),
      feedbackIdGenerator: () => 'feedback-id',
    );
    addTearDown(controller.dispose);

    expect(controller.category, isNull);
  });

  test('initial contactAllowed is false', () {
    final controller = FeedbackFormController(
      repository: _FakeFeedbackRepository(),
      technicalContextService: _FakeTechnicalContextService(),
      feedbackIdGenerator: () => 'feedback-id',
    );
    addTearDown(controller.dispose);

    expect(controller.contactAllowed, isFalse);
  });

  test('selecting a category updates state', () {
    final controller = FeedbackFormController(
      repository: _FakeFeedbackRepository(),
      technicalContextService: _FakeTechnicalContextService(),
      feedbackIdGenerator: () => 'feedback-id',
    );
    addTearDown(controller.dispose);

    controller.selectCategory(FeedbackCategory.bug);

    expect(controller.category, FeedbackCategory.bug);
  });

  test('only one category stays active at a time', () {
    final controller = FeedbackFormController(
      repository: _FakeFeedbackRepository(),
      technicalContextService: _FakeTechnicalContextService(),
      feedbackIdGenerator: () => 'feedback-id',
    );
    addTearDown(controller.dispose);

    controller.selectCategory(FeedbackCategory.bug);
    controller.selectCategory(FeedbackCategory.other);

    expect(controller.category, FeedbackCategory.other);
  });

  test('description with 19 trimmed characters is invalid', () {
    final controller = FeedbackFormController(
      repository: _FakeFeedbackRepository(),
      technicalContextService: _FakeTechnicalContextService(),
      feedbackIdGenerator: () => 'feedback-id',
    );
    addTearDown(controller.dispose);

    controller.setDescription('a' * 19);

    expect(isFeedbackDescriptionValid(controller.description), isFalse);
  });

  test('description with 20 trimmed characters is valid', () {
    final controller = FeedbackFormController(
      repository: _FakeFeedbackRepository(),
      technicalContextService: _FakeTechnicalContextService(),
      feedbackIdGenerator: () => 'feedback-id',
    );
    addTearDown(controller.dispose);

    controller.setDescription('a' * 20);

    expect(isFeedbackDescriptionValid(controller.description), isTrue);
  });

  test('description with 5000 trimmed characters is valid', () {
    final controller = FeedbackFormController(
      repository: _FakeFeedbackRepository(),
      technicalContextService: _FakeTechnicalContextService(),
      feedbackIdGenerator: () => 'feedback-id',
    );
    addTearDown(controller.dispose);

    controller.setDescription('a' * 5000);

    expect(isFeedbackDescriptionValid(controller.description), isTrue);
  });

  test('description with 5001 trimmed characters is invalid', () {
    final controller = FeedbackFormController(
      repository: _FakeFeedbackRepository(),
      technicalContextService: _FakeTechnicalContextService(),
      feedbackIdGenerator: () => 'feedback-id',
    );
    addTearDown(controller.dispose);

    controller.setDescription('a' * 5001);

    expect(isFeedbackDescriptionValid(controller.description), isFalse);
  });

  test('trim is applied when validating description', () {
    final controller = FeedbackFormController(
      repository: _FakeFeedbackRepository(),
      technicalContextService: _FakeTechnicalContextService(),
      feedbackIdGenerator: () => 'feedback-id',
    );
    addTearDown(controller.dispose);

    controller.setDescription('  ${'a' * 20}  ');

    expect(controller.trimmedDescription, 'a' * 20);
    expect(isFeedbackDescriptionValid(controller.description), isTrue);
  });

  test('canSubmit requires category and valid description', () {
    final controller = FeedbackFormController(
      repository: _FakeFeedbackRepository(),
      technicalContextService: _FakeTechnicalContextService(),
      feedbackIdGenerator: () => 'feedback-id',
    );
    addTearDown(controller.dispose);

    expect(controller.canSubmit, isFalse);

    controller.selectCategory(FeedbackCategory.bug);
    controller.setDescription('a' * 19);
    expect(controller.canSubmit, isFalse);

    controller.setDescription('a' * 20);
    expect(controller.canSubmit, isTrue);
  });

  test('dirty state tracks modified fields', () {
    final controller = FeedbackFormController(
      repository: _FakeFeedbackRepository(),
      technicalContextService: _FakeTechnicalContextService(),
      feedbackIdGenerator: () => 'feedback-id',
    );
    addTearDown(controller.dispose);

    expect(controller.isDirty, isFalse);

    controller.selectCategory(FeedbackCategory.bug);
    expect(controller.isDirty, isTrue);

    controller.selectCategory(null);
    expect(controller.isDirty, isFalse);

    controller.setDescription('a');
    expect(controller.isDirty, isTrue);

    controller.setDescription('');
    expect(controller.isDirty, isFalse);

    controller.setContactAllowed(true);
    expect(controller.isDirty, isTrue);
  });

  test('submit forwards a generated id and technical context to the repository',
      () async {
    final repository = _FakeFeedbackRepository(
      result: RepositoryResult<FeedbackReport>.success(
        data: _submittedReport(
          id: 'feedback-123',
          category: FeedbackCategory.bug,
          description: 'A' * 20,
          contactAllowed: true,
          technicalContext: const FeedbackTechnicalContext(
            appVersion: '1.2.3',
            buildNumber: '456',
            platform: 'android',
            osVersion: '15',
            deviceModel: 'Pixel 8',
            appLocale: 'es_ES',
            sourceRoute: '/feedback/new',
          ),
        ),
      ),
    );
    final controller = FeedbackFormController(
      repository: repository,
      technicalContextService: _FakeTechnicalContextService(
        context: const FeedbackTechnicalContext(
          appVersion: '1.2.3',
          buildNumber: '456',
          platform: 'android',
          osVersion: '15',
          deviceModel: 'Pixel 8',
          appLocale: 'es_ES',
          sourceRoute: '/feedback/new',
        ),
      ),
      feedbackIdGenerator: () => 'feedback-123',
    );
    addTearDown(controller.dispose);

    controller.selectCategory(FeedbackCategory.bug);
    controller.setDescription('A' * 20);
    controller.setContactAllowed(true);

    final result = await controller.submit();

    expect(result?.isSuccess, isTrue);
    expect(repository.lastRequest?.id, 'feedback-123');
    expect(repository.lastRequest?.category, FeedbackCategory.bug);
    expect(repository.lastRequest?.description, 'A' * 20);
    expect(repository.lastRequest?.contactAllowed, isTrue);
    expect(repository.lastRequest?.screenshotPath, isNull);
    expect(
        repository.lastRequest?.technicalContext.sourceRoute, '/feedback/new');
    expect(controller.isSubmitting, isFalse);
  });

  test('submit converts technical context format failures to invalidResponse',
      () async {
    final controller = FeedbackFormController(
      repository: _FakeFeedbackRepository(),
      technicalContextService: _FakeTechnicalContextService(
        error: const FormatException('broken metadata'),
      ),
      feedbackIdGenerator: () => 'feedback-123',
    );
    addTearDown(controller.dispose);

    controller.selectCategory(FeedbackCategory.bug);
    controller.setDescription('A' * 20);

    final result = await controller.submit();

    expect(result?.isSuccess, isFalse);
    expect(result?.error?.code, RepositoryErrorCode.invalidResponse);
    expect(result?.error?.message, contains('broken metadata'));
    expect(controller.isSubmitting, isFalse);
  });

  test('submit ignores invalid state and does not call the repository',
      () async {
    final repository = _FakeFeedbackRepository();
    final controller = FeedbackFormController(
      repository: repository,
      technicalContextService: _FakeTechnicalContextService(),
      feedbackIdGenerator: () => 'feedback-123',
    );
    addTearDown(controller.dispose);

    final result = await controller.submit();

    expect(result, isNull);
    expect(repository.callCount, 0);
  });
}

class _FakeFeedbackRepository implements FeedbackRepository {
  _FakeFeedbackRepository({
    this.result,
  });

  final RepositoryResult<FeedbackReport>? result;

  int callCount = 0;
  _CreateFeedbackRequest? lastRequest;

  @override
  Future<RepositoryResult<FeedbackReport>> createFeedback({
    required String id,
    required FeedbackCategory category,
    required String description,
    required bool contactAllowed,
    required FeedbackTechnicalContext technicalContext,
    String? screenshotPath,
  }) {
    callCount += 1;
    lastRequest = _CreateFeedbackRequest(
      id: id,
      category: category,
      description: description,
      contactAllowed: contactAllowed,
      technicalContext: technicalContext,
      screenshotPath: screenshotPath,
    );

    return Future<RepositoryResult<FeedbackReport>>.value(
      result ??
          RepositoryResult<FeedbackReport>.success(
            data: _submittedReport(
              id: id,
              category: category,
              description: description,
              contactAllowed: contactAllowed,
              technicalContext: technicalContext,
            ),
          ),
    );
  }
}

class _FakeTechnicalContextService extends FeedbackTechnicalContextService {
  _FakeTechnicalContextService({
    this.context = const FeedbackTechnicalContext(
      appVersion: '1.0.0',
      buildNumber: '1',
      platform: 'android',
      osVersion: '15',
      deviceModel: 'device',
      appLocale: 'es_ES',
      sourceRoute: '/feedback/new',
    ),
    this.error,
  });

  final FeedbackTechnicalContext context;
  final FormatException? error;

  @override
  Future<FeedbackTechnicalContext> buildTechnicalContext({
    required String sourceRoute,
  }) async {
    if (error != null) throw error!;
    return context.copyWithRoute(sourceRoute);
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

extension on FeedbackTechnicalContext {
  FeedbackTechnicalContext copyWithRoute(String sourceRoute) {
    return FeedbackTechnicalContext(
      appVersion: appVersion,
      buildNumber: buildNumber,
      platform: platform,
      osVersion: osVersion,
      deviceModel: deviceModel,
      appLocale: appLocale,
      sourceRoute: sourceRoute,
    );
  }
}
