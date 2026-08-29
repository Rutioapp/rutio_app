enum FeedbackCategory {
  bug,
  suggestion,
  improvement,
  other;

  String get postgresValue => name;

  static FeedbackCategory fromPostgresValue(String value) {
    switch (value.trim().toLowerCase()) {
      case 'bug':
        return FeedbackCategory.bug;
      case 'suggestion':
        return FeedbackCategory.suggestion;
      case 'improvement':
        return FeedbackCategory.improvement;
      case 'other':
        return FeedbackCategory.other;
      default:
        throw ArgumentError.value(value, 'value', 'Unknown feedback category');
    }
  }
}
