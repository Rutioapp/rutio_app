import '../../../data/repositories/repository_result.dart';
import '../domain/feedback_category.dart';
import '../domain/feedback_report.dart';
import '../domain/feedback_technical_context.dart';

typedef FeedbackCurrentUserIdProvider = String? Function();

abstract interface class FeedbackRepository {
  Future<RepositoryResult<FeedbackReport>> createFeedback({
    required String id,
    required FeedbackCategory category,
    required String description,
    required bool contactAllowed,
    required FeedbackTechnicalContext technicalContext,
    String? screenshotPath,
  });
}
