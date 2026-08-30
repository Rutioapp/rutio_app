import '../domain/feedback_report.dart';
import '../../../data/repositories/repository_result.dart';

enum FeedbackMutationResultType {
  saved,
  deleted,
  stale,
}

class FeedbackMutationResult {
  const FeedbackMutationResult._({
    required this.type,
    this.report,
    this.screenshotPath,
    this.error,
  });

  factory FeedbackMutationResult.saved(FeedbackReport report) {
    return FeedbackMutationResult._(
      type: FeedbackMutationResultType.saved,
      report: report,
    );
  }

  factory FeedbackMutationResult.deleted({String? screenshotPath}) {
    return FeedbackMutationResult._(
      type: FeedbackMutationResultType.deleted,
      screenshotPath: screenshotPath?.trim().isEmpty == true
          ? null
          : screenshotPath?.trim(),
    );
  }

  factory FeedbackMutationResult.stale(RepositoryError error) {
    return FeedbackMutationResult._(
      type: FeedbackMutationResultType.stale,
      error: error,
    );
  }

  final FeedbackMutationResultType type;
  final FeedbackReport? report;
  final String? screenshotPath;
  final RepositoryError? error;

  bool get isSaved => type == FeedbackMutationResultType.saved;

  bool get isDeleted => type == FeedbackMutationResultType.deleted;

  bool get isStale => type == FeedbackMutationResultType.stale;

  bool get shouldRefreshMyFeedback => isSaved || isDeleted;
}
