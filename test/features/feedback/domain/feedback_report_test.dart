import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/feedback/domain/feedback_category.dart';
import 'package:rutio/features/feedback/domain/feedback_report.dart';
import 'package:rutio/features/feedback/domain/feedback_status.dart';
import 'package:rutio/features/feedback/domain/feedback_technical_context.dart';

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

  test('fromSupabaseRow maps nested technical context and timestamps', () {
    final report = FeedbackReport.fromSupabaseRow(<String, dynamic>{
      'id': 'feedback-123',
      'user_id': 'user-1',
      'category': 'bug',
      'description': 'A' * 20,
      'screenshot_path': null,
      'contact_allowed': true,
      'status': 'submitted',
      'team_response': null,
      'technical_context': <String, dynamic>{
        'appVersion': '1.2.3',
        'buildNumber': '456',
        'platform': 'android',
        'osVersion': '15',
        'deviceModel': 'Pixel 8',
        'appLocale': 'es_ES',
        'sourceRoute': '/feedback/new',
      },
      'review_started_at': '2026-08-29T10:00:00.000Z',
      'closed_at': null,
      'created_at': '2026-08-30T12:30:00.000Z',
      'updated_at': '2026-08-30T12:45:00.000Z',
    });

    expect(report.id, 'feedback-123');
    expect(report.userId, 'user-1');
    expect(report.category, FeedbackCategory.bug);
    expect(report.description, 'A' * 20);
    expect(report.contactAllowed, isTrue);
    expect(report.status, FeedbackStatus.submitted);
    expect(report.technicalContext, isNotNull);
    expect(
      report.technicalContext,
      const TypeMatcher<FeedbackTechnicalContext>(),
    );
    expect(report.technicalContext!.appVersion, '1.2.3');
    expect(report.technicalContext!.sourceRoute, '/feedback/new');
    expect(report.reviewStartedAt, DateTime.parse('2026-08-29T10:00:00.000Z'));
    expect(report.createdAt, DateTime.parse('2026-08-30T12:30:00.000Z'));
    expect(report.updatedAt, DateTime.parse('2026-08-30T12:45:00.000Z'));
  });
}
