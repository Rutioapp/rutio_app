enum FeedbackStatus {
  submitted,
  inReview,
  resolved,
  dismissed;

  String get postgresValue {
    switch (this) {
      case FeedbackStatus.submitted:
        return 'submitted';
      case FeedbackStatus.inReview:
        return 'in_review';
      case FeedbackStatus.resolved:
        return 'resolved';
      case FeedbackStatus.dismissed:
        return 'dismissed';
    }
  }

  static FeedbackStatus fromPostgresValue(String value) {
    switch (value.trim().toLowerCase()) {
      case 'submitted':
        return FeedbackStatus.submitted;
      case 'in_review':
        return FeedbackStatus.inReview;
      case 'resolved':
        return FeedbackStatus.resolved;
      case 'dismissed':
        return FeedbackStatus.dismissed;
      default:
        throw ArgumentError.value(value, 'value', 'Unknown feedback status');
    }
  }
}
