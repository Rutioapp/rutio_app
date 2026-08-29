import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/feedback/domain/feedback_category.dart';
import 'package:rutio/features/feedback/domain/feedback_report.dart';
import 'package:rutio/features/feedback/domain/feedback_status.dart';

void main() {
  test('canEdit and canDelete are true only for submitted reports', () {
    final submitted = FeedbackReport(
      id: 'submitted',
      category: FeedbackCategory.bug,
      description: 'A' * 20,
      contactAllowed: false,
      status: FeedbackStatus.submitted,
      createdAt: DateTime(2026, 8, 29),
    );
    final inReview = submitted.copyWith(
      id: 'in-review',
      status: FeedbackStatus.inReview,
    );
    final resolved = submitted.copyWith(
      id: 'resolved',
      status: FeedbackStatus.resolved,
    );
    final dismissed = submitted.copyWith(
      id: 'dismissed',
      status: FeedbackStatus.dismissed,
    );

    expect(submitted.canEdit, isTrue);
    expect(submitted.canDelete, isTrue);

    expect(inReview.canEdit, isFalse);
    expect(inReview.canDelete, isFalse);

    expect(resolved.canEdit, isFalse);
    expect(resolved.canDelete, isFalse);

    expect(dismissed.canEdit, isFalse);
    expect(dismissed.canDelete, isFalse);
  });
}
