import 'models/onboarding_recommendation.dart';
import 'models/onboarding_types.dart';
import 'onboarding_goals.dart';

enum OnboardingRecommendationCatalogIssueCode {
  emptyId,
  duplicateId,
  wrongVersion,
  missingLocale,
  invalidFamily,
  invalidGoal,
  invalidPace,
  invalidPriority,
  invalidHabitType,
  unsupportedSchedule,
  invalidTarget,
  inactive,
}

class OnboardingRecommendationCatalogIssue {
  const OnboardingRecommendationCatalogIssue({
    required this.code,
    required this.message,
    this.recommendationId,
  });

  final OnboardingRecommendationCatalogIssueCode code;
  final String message;
  final String? recommendationId;
}

class OnboardingRecommendationCatalogValidationResult {
  const OnboardingRecommendationCatalogValidationResult({
    required this.validRecommendations,
    required this.issues,
  });

  final List<OnboardingRecommendation> validRecommendations;
  final List<OnboardingRecommendationCatalogIssue> issues;

  bool get isValid => issues.isEmpty;
}

/// Pure validation for bundled (and future remote) catalog snapshots.
class OnboardingRecommendationCatalogValidator {
  const OnboardingRecommendationCatalogValidator._();

  static OnboardingRecommendationCatalogValidationResult validate(
    OnboardingRecommendationCatalogSnapshot snapshot, {
    int expectedVersion = OnboardingVersions.catalogVersion,
  }) {
    final issues = <OnboardingRecommendationCatalogIssue>[];
    final valid = <OnboardingRecommendation>[];
    final ids = <String>{};
    final families = <String>{
      'mind',
      'spirit',
      'body',
      'emotional',
      'social',
      'discipline',
      'professional',
    };

    if (snapshot.version != expectedVersion) {
      issues.add(OnboardingRecommendationCatalogIssue(
        code: OnboardingRecommendationCatalogIssueCode.wrongVersion,
        message: 'Catalog version does not match the pinned version.',
      ));
    }

    for (final recommendation in snapshot.recommendations) {
      final id = recommendation.id.trim();
      var validEntry = true;
      void issue(
        OnboardingRecommendationCatalogIssueCode code,
        String message,
      ) {
        validEntry = false;
        issues.add(OnboardingRecommendationCatalogIssue(
          code: code,
          message: message,
          recommendationId: recommendation.id,
        ));
      }

      if (id.isEmpty) {
        issue(OnboardingRecommendationCatalogIssueCode.emptyId,
            'Recommendation id must not be empty.');
      } else if (!ids.add(id)) {
        issue(OnboardingRecommendationCatalogIssueCode.duplicateId,
            'Recommendation ids must be unique.');
      }
      if (recommendation.catalogVersion != expectedVersion) {
        issue(OnboardingRecommendationCatalogIssueCode.wrongVersion,
            'Recommendation version does not match the catalog.');
      }
      if (!recommendation.localizedContent.names.containsKey('es') ||
          !recommendation.localizedContent.names.containsKey('en') ||
          recommendation.localizedContent.names['es']!.trim().isEmpty ||
          recommendation.localizedContent.names['en']!.trim().isEmpty) {
        issue(OnboardingRecommendationCatalogIssueCode.missingLocale,
            'Recommendation requires ES and EN localized content.');
      }
      if (!families.contains(recommendation.primaryFamilyCode) ||
          recommendation.secondaryFamilyCodes
              .any((code) => !families.contains(code)) ||
          recommendation.secondaryFamilyCodes
              .contains(recommendation.primaryFamilyCode)) {
        issue(OnboardingRecommendationCatalogIssueCode.invalidFamily,
            'Recommendation family metadata is invalid.');
      }
      if (recommendation.goalCodes.isEmpty ||
          recommendation.goalCodes.any(
              (code) => !OnboardingGoalCatalog.validCodes.contains(code))) {
        issue(OnboardingRecommendationCatalogIssueCode.invalidGoal,
            'Recommendation contains an unknown goal code.');
      }
      if (recommendation.paceCompatibility.length !=
              OnboardingPace.values.length ||
          OnboardingPace.values.any(
              (pace) => !recommendation.paceCompatibility.containsKey(pace))) {
        issue(OnboardingRecommendationCatalogIssueCode.invalidPace,
            'Recommendation must declare compatibility for every pace.');
      }
      if (recommendation.editorialPriority < 0 ||
          recommendation.editorialPriority > 20) {
        issue(OnboardingRecommendationCatalogIssueCode.invalidPriority,
            'Editorial priority must be between 0 and 20.');
      }
      if (recommendation.habitType != 'check' &&
          recommendation.habitType != 'count') {
        issue(OnboardingRecommendationCatalogIssueCode.invalidHabitType,
            'Habit type must be check or count.');
      }
      final scheduleType =
          (recommendation.initialScheduleSnapshot['type'] ?? '').toString();
      final scheduleValid = switch (scheduleType) {
        'daily' => true,
        'weekly' => _validWeekdays(
            recommendation.initialScheduleSnapshot['weekdays'],
          ),
        'once' => _validDate(recommendation.initialScheduleSnapshot['date']),
        _ => false,
      };
      if (!scheduleValid ||
          recommendation.initialScheduleSnapshot.containsKey('timesPerWeek')) {
        issue(OnboardingRecommendationCatalogIssueCode.unsupportedSchedule,
            'Recommendation schedule is not supported by onboarding.');
      }
      if (recommendation.habitType == 'count' &&
          (recommendation.targetValue == null ||
              recommendation.targetValue! <= 0 ||
              recommendation.unit == null ||
              recommendation.unit!.trim().isEmpty)) {
        issue(OnboardingRecommendationCatalogIssueCode.invalidTarget,
            'Count recommendations require a positive target and unit.');
      }
      if (!recommendation.active) {
        // Inactive entries remain resolvable for historical selected IDs, but
        // cannot be presented in a new batch.
        issue(OnboardingRecommendationCatalogIssueCode.inactive,
            'Inactive recommendations are not eligible for presentation.');
      }
      if (validEntry) valid.add(recommendation);
    }

    return OnboardingRecommendationCatalogValidationResult(
      validRecommendations: List.unmodifiable(valid),
      issues: List.unmodifiable(issues),
    );
  }

  static bool _validWeekdays(Object? value) {
    if (value is! List || value.isEmpty) return false;
    final days = value.whereType<int>().toSet();
    return days.length == value.length &&
        days.every((day) => day >= 1 && day <= 7);
  }

  static bool _validDate(Object? value) {
    final raw = (value ?? '').toString();
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) return false;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return false;
    final normalized =
        '${parsed.year.toString().padLeft(4, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
    return normalized == raw;
  }
}
