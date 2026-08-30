import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/repositories/repository_result.dart';
import 'package:rutio/features/feedback/application/my_feedback_controller.dart';
import 'package:rutio/features/feedback/data/feedback_repository.dart';
import 'package:rutio/features/feedback/domain/feedback_category.dart';
import 'package:rutio/features/feedback/domain/feedback_report.dart';
import 'package:rutio/features/feedback/domain/feedback_status.dart';
import 'package:rutio/features/feedback/domain/feedback_technical_context.dart';

void main() {
  test('initial state is initial with no reports', () {
    final controller = FeedbackMineController(
      repository: _FakeFeedbackRepository(),
    );
    addTearDown(controller.dispose);

    expect(controller.state.status, FeedbackMineStatus.initial);
    expect(controller.reports, isEmpty);
  });

  test('load transitions through loading and loaded', () async {
    final completer = Completer<RepositoryResult<List<FeedbackReport>>>();
    final controller = FeedbackMineController(
      repository: _FakeFeedbackRepository(pendingResult: completer),
    );
    addTearDown(controller.dispose);

    final loadingFuture = controller.load();
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.status, FeedbackMineStatus.loading);

    final reports = <FeedbackReport>[
      _report(
        id: 'feedback-1',
        status: FeedbackStatus.submitted,
        createdAt: DateTime(2026, 8, 29, 10, 0),
      ),
      _report(
        id: 'feedback-2',
        status: FeedbackStatus.inReview,
        createdAt: DateTime(2026, 8, 30, 10, 0),
      ),
    ];
    completer.complete(RepositoryResult<List<FeedbackReport>>.success(
      data: reports,
    ));

    await loadingFuture;

    expect(controller.state.status, FeedbackMineStatus.loaded);
    expect(controller.reports, hasLength(2));
    expect(controller.reports.first.id, 'feedback-2');
  });

  test('load empty reports produces empty state', () async {
    final controller = FeedbackMineController(
      repository: _FakeFeedbackRepository(
        result: const RepositoryResult<List<FeedbackReport>>.success(
          data: <FeedbackReport>[],
        ),
      ),
    );
    addTearDown(controller.dispose);

    await controller.load();

    expect(controller.state.status, FeedbackMineStatus.empty);
    expect(controller.reports, isEmpty);
  });

  test('load failure produces error and retry fetches again', () async {
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
              status: FeedbackStatus.submitted,
              createdAt: DateTime(2026, 8, 30, 10, 0),
            ),
          ],
        ),
      ],
    );
    final controller = FeedbackMineController(repository: repository);
    addTearDown(controller.dispose);

    await controller.load();
    expect(controller.state.status, FeedbackMineStatus.error);

    await controller.retry();
    expect(repository.callCount, 2);
    expect(controller.state.status, FeedbackMineStatus.loaded);
    expect(controller.reports, hasLength(1));
  });

  test('refresh re-executes the query and updates the list', () async {
    final repository = _FakeFeedbackRepository(
      queue: <RepositoryResult<List<FeedbackReport>>>[
        RepositoryResult<List<FeedbackReport>>.success(
          data: <FeedbackReport>[
            _report(
              id: 'feedback-1',
              status: FeedbackStatus.submitted,
              createdAt: DateTime(2026, 8, 29, 10, 0),
            ),
          ],
        ),
        RepositoryResult<List<FeedbackReport>>.success(
          data: <FeedbackReport>[
            _report(
              id: 'feedback-2',
              status: FeedbackStatus.resolved,
              createdAt: DateTime(2026, 8, 30, 10, 0),
            ),
          ],
        ),
      ],
    );
    final controller = FeedbackMineController(repository: repository);
    addTearDown(controller.dispose);

    await controller.load();
    expect(controller.reports.single.id, 'feedback-1');

    await controller.refresh();

    expect(repository.callCount, 2);
    expect(controller.reports.single.id, 'feedback-2');
  });

  test('filters keep all submitted, in review and closed items local',
      () async {
    final controller = FeedbackMineController(
      repository: _FakeFeedbackRepository(
        result: RepositoryResult<List<FeedbackReport>>.success(
          data: <FeedbackReport>[
            _report(
              id: 'resolved',
              status: FeedbackStatus.resolved,
              createdAt: DateTime(2026, 8, 30, 13, 0),
            ),
            _report(
              id: 'dismissed',
              status: FeedbackStatus.dismissed,
              createdAt: DateTime(2026, 8, 30, 12, 0),
            ),
            _report(
              id: 'in-review',
              status: FeedbackStatus.inReview,
              createdAt: DateTime(2026, 8, 30, 11, 0),
            ),
            _report(
              id: 'submitted',
              status: FeedbackStatus.submitted,
              createdAt: DateTime(2026, 8, 30, 10, 0),
            ),
          ],
        ),
      ),
    );
    addTearDown(controller.dispose);

    await controller.load();

    controller.setFilter(FeedbackMineFilter.submitted);
    expect(controller.visibleReports.map((report) => report.id), ['submitted']);

    controller.setFilter(FeedbackMineFilter.inReview);
    expect(controller.visibleReports.map((report) => report.id), ['in-review']);

    controller.setFilter(FeedbackMineFilter.closed);
    expect(
      controller.visibleReports.map((report) => report.id),
      ['resolved', 'dismissed'],
    );

    controller.setFilter(FeedbackMineFilter.all);
    expect(
      controller.visibleReports.map((report) => report.id),
      ['resolved', 'dismissed', 'in-review', 'submitted'],
    );
  });
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
    callCount += 1;
    if (pendingResult != null) {
      return pendingResult!.future;
    }
    if (_queue.isNotEmpty) {
      return _queue.removeAt(0);
    }
    return result ??
        RepositoryResult<List<FeedbackReport>>.success(
          data: <FeedbackReport>[],
        );
  }

  @override
  Future<RepositoryResult<FeedbackReport>> getMyFeedbackById({
    required String feedbackId,
  }) async {
    return const RepositoryResult<FeedbackReport>.failure(
      RepositoryError(
        code: RepositoryErrorCode.notFound,
        message: 'Not implemented in my feedback controller tests.',
      ),
    );
  }
}

FeedbackReport _report({
  required String id,
  required FeedbackStatus status,
  required DateTime createdAt,
}) {
  return FeedbackReport(
    id: id,
    category: FeedbackCategory.bug,
    description: id,
    contactAllowed: false,
    status: status,
    createdAt: createdAt,
  );
}
