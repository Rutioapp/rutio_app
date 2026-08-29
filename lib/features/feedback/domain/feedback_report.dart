import 'feedback_category.dart';
import 'feedback_status.dart';

class FeedbackReport {
  const FeedbackReport({
    required this.id,
    required this.category,
    required this.description,
    required this.contactAllowed,
    required this.status,
    required this.createdAt,
    this.userId,
    this.screenshotPath,
    this.teamResponse,
    this.reviewStartedAt,
    this.closedAt,
  });

  final String id;
  final String? userId;
  final FeedbackCategory category;
  final String description;
  final String? screenshotPath;
  final bool contactAllowed;
  final FeedbackStatus status;
  final String? teamResponse;
  final DateTime createdAt;
  final DateTime? reviewStartedAt;
  final DateTime? closedAt;

  bool get canEdit => status == FeedbackStatus.submitted;

  bool get canDelete => status == FeedbackStatus.submitted;

  bool get hasScreenshot => screenshotPath?.trim().isNotEmpty == true;

  bool get hasTeamResponse => teamResponse?.trim().isNotEmpty == true;

  FeedbackReport copyWith({
    String? id,
    String? userId,
    FeedbackCategory? category,
    String? description,
    String? screenshotPath,
    bool? contactAllowed,
    FeedbackStatus? status,
    String? teamResponse,
    DateTime? createdAt,
    DateTime? reviewStartedAt,
    DateTime? closedAt,
  }) {
    return FeedbackReport(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      description: description ?? this.description,
      screenshotPath: screenshotPath ?? this.screenshotPath,
      contactAllowed: contactAllowed ?? this.contactAllowed,
      status: status ?? this.status,
      teamResponse: teamResponse ?? this.teamResponse,
      createdAt: createdAt ?? this.createdAt,
      reviewStartedAt: reviewStartedAt ?? this.reviewStartedAt,
      closedAt: closedAt ?? this.closedAt,
    );
  }
}
