import 'feedback_category.dart';
import 'feedback_status.dart';
import 'feedback_technical_context.dart';

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
    this.technicalContext,
    this.reviewStartedAt,
    this.closedAt,
    this.updatedAt,
  });

  final String id;
  final String? userId;
  final FeedbackCategory category;
  final String description;
  final String? screenshotPath;
  final bool contactAllowed;
  final FeedbackStatus status;
  final String? teamResponse;
  final FeedbackTechnicalContext? technicalContext;
  final DateTime createdAt;
  final DateTime? reviewStartedAt;
  final DateTime? closedAt;
  final DateTime? updatedAt;

  factory FeedbackReport.fromSupabaseRow(Map<String, dynamic> row) {
    final id = _requiredString(row['id'], field: 'id');
    final userId = _requiredString(row['user_id'], field: 'user_id');
    final category = FeedbackCategory.fromPostgresValue(
      _requiredString(row['category'], field: 'category'),
    );
    final description =
        _requiredString(row['description'], field: 'description');
    final status = FeedbackStatus.fromPostgresValue(
      _requiredString(row['status'], field: 'status'),
    );
    final createdAt = _requiredDateTime(row['created_at'], field: 'created_at');
    final updatedAt = _optionalDateTime(row['updated_at']);
    final screenshotPath = _optionalString(row['screenshot_path']);
    final teamResponse = _optionalString(row['team_response']);
    final reviewStartedAt = _optionalDateTime(row['review_started_at']);
    final closedAt = _optionalDateTime(row['closed_at']);
    final technicalContext = _optionalTechnicalContext(
      row['technical_context'],
    );

    return FeedbackReport(
      id: id,
      userId: userId,
      category: category,
      description: description,
      screenshotPath: screenshotPath,
      contactAllowed: row['contact_allowed'] == true,
      status: status,
      teamResponse: teamResponse,
      technicalContext: technicalContext,
      createdAt: createdAt,
      reviewStartedAt: reviewStartedAt,
      closedAt: closedAt,
      updatedAt: updatedAt,
    );
  }

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
    FeedbackTechnicalContext? technicalContext,
    DateTime? updatedAt,
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
      technicalContext: technicalContext ?? this.technicalContext,
      createdAt: createdAt ?? this.createdAt,
      reviewStartedAt: reviewStartedAt ?? this.reviewStartedAt,
      closedAt: closedAt ?? this.closedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String _requiredString(Object? value, {required String field}) {
    final normalized = (value ?? '').toString().trim();
    if (normalized.isEmpty) {
      throw FormatException('Missing or empty $field.');
    }
    return normalized;
  }

  static String? _optionalString(Object? value) {
    final normalized = (value ?? '').toString().trim();
    return normalized.isEmpty ? null : normalized;
  }

  static DateTime _requiredDateTime(Object? value, {required String field}) {
    final parsed = _optionalDateTime(value);
    if (parsed == null) {
      throw FormatException('Missing or invalid $field.');
    }
    return parsed;
  }

  static DateTime? _optionalDateTime(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final normalized = value.toString().trim();
    if (normalized.isEmpty) return null;
    return DateTime.tryParse(normalized);
  }

  static FeedbackTechnicalContext? _optionalTechnicalContext(Object? value) {
    if (value == null) return null;
    if (value is! Map) {
      throw FormatException('technical_context must be a JSON object.');
    }
    return FeedbackTechnicalContext.fromJson(
      Map<String, dynamic>.from(value.cast<String, dynamic>()),
    );
  }
}
