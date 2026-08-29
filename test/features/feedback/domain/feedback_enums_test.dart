import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/feedback/domain/feedback_category.dart';
import 'package:rutio/features/feedback/domain/feedback_status.dart';

void main() {
  test('FeedbackCategory postgres mapping is stable', () {
    expect(FeedbackCategory.bug.postgresValue, 'bug');
    expect(FeedbackCategory.suggestion.postgresValue, 'suggestion');
    expect(FeedbackCategory.improvement.postgresValue, 'improvement');
    expect(FeedbackCategory.other.postgresValue, 'other');

    expect(FeedbackCategory.fromPostgresValue('bug'), FeedbackCategory.bug);
    expect(
      FeedbackCategory.fromPostgresValue('suggestion'),
      FeedbackCategory.suggestion,
    );
    expect(
      FeedbackCategory.fromPostgresValue('improvement'),
      FeedbackCategory.improvement,
    );
    expect(FeedbackCategory.fromPostgresValue('other'), FeedbackCategory.other);
  });

  test('FeedbackStatus postgres mapping is stable', () {
    expect(FeedbackStatus.submitted.postgresValue, 'submitted');
    expect(FeedbackStatus.inReview.postgresValue, 'in_review');
    expect(FeedbackStatus.resolved.postgresValue, 'resolved');
    expect(FeedbackStatus.dismissed.postgresValue, 'dismissed');

    expect(
      FeedbackStatus.fromPostgresValue('submitted'),
      FeedbackStatus.submitted,
    );
    expect(
      FeedbackStatus.fromPostgresValue('in_review'),
      FeedbackStatus.inReview,
    );
    expect(
      FeedbackStatus.fromPostgresValue('resolved'),
      FeedbackStatus.resolved,
    );
    expect(
      FeedbackStatus.fromPostgresValue('dismissed'),
      FeedbackStatus.dismissed,
    );
  });
}
