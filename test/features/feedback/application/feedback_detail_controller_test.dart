import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/repositories/repository_result.dart';
import 'package:rutio/features/feedback/application/feedback_detail_controller.dart';
import 'package:rutio/features/feedback/data/feedback_repository.dart';
import 'package:rutio/features/feedback/data/feedback_storage_service.dart';
import 'package:rutio/features/feedback/domain/feedback_category.dart';
import 'package:rutio/features/feedback/domain/feedback_report.dart';
import 'package:rutio/features/feedback/domain/feedback_status.dart';
import 'package:rutio/features/feedback/domain/feedback_technical_context.dart';

void main() {
  const userId = '11111111-1111-4111-8111-111111111111';
  const feedbackId = '22222222-2222-4222-8222-222222222222';
  const screenshotIdA = '33333333-3333-4333-8333-333333333333';
  const screenshotIdB = '44444444-4444-4444-8444-444444444444';

  test('load transitions through loading and loaded', () async {
    final completer = Completer<RepositoryResult<FeedbackReport>>();
    final repository = _FakeFeedbackRepository(
      pendingResult: completer,
    );
    final gateway = _FakeFeedbackStorageGateway();
    final controller = FeedbackDetailController(
      repository: repository,
      storageService: FeedbackStorageService(
        gateway: gateway,
        currentUserIdProvider: () => 'user-1',
      ),
    );
    addTearDown(controller.dispose);

    final future = controller.load(feedbackId);
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.status, FeedbackDetailStatus.loading);

    completer.complete(
      RepositoryResult<FeedbackReport>.success(
        data: _report(
          id: feedbackId,
          status: FeedbackStatus.submitted,
          createdAt: DateTime(2026, 8, 30, 10, 0),
        ),
      ),
    );

    await future;

    expect(controller.state.status, FeedbackDetailStatus.loaded);
    expect(controller.state.report?.id, feedbackId);
    expect(controller.state.canEdit, isTrue);
    expect(controller.state.canDelete, isTrue);
  });

  test('load maps not found to notFound', () async {
    final controller = FeedbackDetailController(
      repository: _FakeFeedbackRepository(
        result: const RepositoryResult<FeedbackReport>.failure(
          RepositoryError(
            code: RepositoryErrorCode.notFound,
            message: 'not found',
          ),
        ),
      ),
      storageService: FeedbackStorageService(
        gateway: _FakeFeedbackStorageGateway(),
        currentUserIdProvider: () => 'user-1',
      ),
    );
    addTearDown(controller.dispose);

    await controller.load(feedbackId);

    expect(controller.state.status, FeedbackDetailStatus.notFound);
  });

  test('refresh reloads the authoritative report and updates permissions',
      () async {
    final repository = _FakeFeedbackRepository(
      queue: <RepositoryResult<FeedbackReport>>[
        RepositoryResult<FeedbackReport>.success(
          data: _report(
            id: feedbackId,
            status: FeedbackStatus.submitted,
            createdAt: DateTime(2026, 8, 30, 10, 0),
            screenshotPath:
                '$userId/$feedbackId/screenshot_$screenshotIdA.jpg',
          ),
        ),
        RepositoryResult<FeedbackReport>.success(
          data: _report(
            id: feedbackId,
            status: FeedbackStatus.inReview,
            createdAt: DateTime(2026, 8, 30, 10, 0),
            reviewStartedAt: DateTime(2026, 8, 30, 11, 0),
            screenshotPath:
                '$userId/$feedbackId/screenshot_$screenshotIdB.jpg',
          ),
        ),
      ],
    );
    final storageGateway = _FakeFeedbackStorageGateway();
    final controller = FeedbackDetailController(
      repository: repository,
      storageService: FeedbackStorageService(
        gateway: storageGateway,
        currentUserIdProvider: () => 'user-1',
      ),
    );
    addTearDown(controller.dispose);

    await controller.load(feedbackId);
    expect(controller.state.canEdit, isTrue);
    expect(storageGateway.requestedPaths, hasLength(1));
    expect(controller.state.screenshotSignedUrl, contains('signed=1'));

    await controller.refresh();

    expect(repository.callCount, 2);
    expect(controller.state.status, FeedbackDetailStatus.loaded);
    expect(controller.state.canEdit, isFalse);
    expect(controller.state.canDelete, isFalse);
    expect(controller.state.report?.status, FeedbackStatus.inReview);
    expect(storageGateway.requestedPaths, hasLength(2));
  });

  test('screenshotPath null does not request a signed URL', () async {
    final storageGateway = _FakeFeedbackStorageGateway();
    final controller = FeedbackDetailController(
      repository: _FakeFeedbackRepository(
        result: RepositoryResult<FeedbackReport>.success(
          data: _report(
            id: feedbackId,
            status: FeedbackStatus.submitted,
            createdAt: DateTime(2026, 8, 30, 10, 0),
          ),
        ),
      ),
      storageService: FeedbackStorageService(
        gateway: storageGateway,
        currentUserIdProvider: () => 'user-1',
      ),
    );
    addTearDown(controller.dispose);

    await controller.load(feedbackId);

    expect(storageGateway.requestedPaths, isEmpty);
    expect(controller.state.screenshotStatus, FeedbackDetailScreenshotStatus.idle);
  });

  test('screenshotPath non-null requests a signed URL', () async {
    final storageGateway = _FakeFeedbackStorageGateway();
    final controller = FeedbackDetailController(
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
      storageService: FeedbackStorageService(
        gateway: storageGateway,
        currentUserIdProvider: () => 'user-1',
      ),
    );
    addTearDown(controller.dispose);

    await controller.load(feedbackId);

    expect(storageGateway.requestedPaths, hasLength(1));
    expect(controller.state.screenshotStatus, FeedbackDetailScreenshotStatus.loaded);
    expect(controller.state.screenshotSignedUrl, contains('signed=1'));
  });

  test('signed URL failures keep the report loaded and the screenshot errored',
      () async {
    final controller = FeedbackDetailController(
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
      storageService: FeedbackStorageService(
        gateway: _FakeFeedbackStorageGateway(failSignedUrl: true),
        currentUserIdProvider: () => 'user-1',
      ),
    );
    addTearDown(controller.dispose);

    await controller.load(feedbackId);

    expect(controller.state.status, FeedbackDetailStatus.loaded);
    expect(controller.state.screenshotStatus, FeedbackDetailScreenshotStatus.error);
    expect(controller.state.report?.id, feedbackId);
  });

  test('status-derived permissions only remain true while submitted',
      () async {
    final controller = FeedbackDetailController(
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
    );
    addTearDown(controller.dispose);

    await controller.load(feedbackId);

    expect(controller.state.canEdit, isFalse);
    expect(controller.state.canDelete, isFalse);
  });
}

class _FakeFeedbackRepository implements FeedbackRepository {
  _FakeFeedbackRepository({
    this.result,
    this.pendingResult,
    List<RepositoryResult<FeedbackReport>>? queue,
  }) : _queue = queue != null
            ? List<RepositoryResult<FeedbackReport>>.from(queue)
            : <RepositoryResult<FeedbackReport>>[];

  final RepositoryResult<FeedbackReport>? result;
  final Completer<RepositoryResult<FeedbackReport>>? pendingResult;
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
  });

  bool failSignedUrl;
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
    if (failSignedUrl) {
      throw StateError('signed url failed');
    }
    return 'https://example.com/$bucket/$path?signed=${requestedPaths.length}';
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

FeedbackStorageService _storageService({
  _FakeFeedbackStorageGateway? gateway,
}) {
  return FeedbackStorageService(
    gateway: gateway ?? _FakeFeedbackStorageGateway(),
    currentUserIdProvider: () => 'user-1',
  );
}
FeedbackReport _report({
  required String id,
  required FeedbackStatus status,
  required DateTime createdAt,
  String? screenshotPath,
  DateTime? reviewStartedAt,
  DateTime? closedAt,
}) {
  return FeedbackReport(
    id: id,
    category: FeedbackCategory.bug,
    description: 'Report $id',
    screenshotPath: screenshotPath,
    contactAllowed: false,
    status: status,
    createdAt: createdAt,
    reviewStartedAt: reviewStartedAt,
    closedAt: closedAt,
  );
}
