import 'package:flutter/foundation.dart';

import 'onboarding_types.dart';

/// A localized editorial reference owned by the onboarding catalog.
///
/// This is intentionally separate from the app's habit payload. A
/// recommendation can suggest a habit, but it is not a configured habit.
@immutable
class OnboardingLocalizedContent {
  OnboardingLocalizedContent({
    required Map<String, String> names,
    Map<String, String>? descriptions,
  })  : names = Map.unmodifiable(names),
        descriptions =
            Map.unmodifiable(descriptions ?? const <String, String>{});

  final Map<String, String> names;
  final Map<String, String> descriptions;

  String? valueFor(String locale, Map<String, String> values) {
    final normalized = locale.trim().replaceAll('_', '-').toLowerCase();
    final language = normalized.split('-').first;
    return values[normalized] ?? values[language] ?? values['es'];
  }

  String nameFor(String locale) => valueFor(locale, names) ?? '';

  String? descriptionFor(String locale) => valueFor(locale, descriptions);

  bool supportsFallbackFor(String locale) {
    final normalized = locale.trim().replaceAll('_', '-').toLowerCase();
    final language = normalized.split('-').first;
    return names.containsKey(normalized) ||
        names.containsKey(language) ||
        names.containsKey('es');
  }
}

enum OnboardingPaceCompatibility {
  ideal,
  adjacent,
  neutral,
  unsuitable,
}

/// A versioned editorial recommendation template.
@immutable
class OnboardingRecommendation {
  OnboardingRecommendation({
    required this.id,
    required this.catalogVersion,
    required this.localizedContent,
    required this.emoji,
    required this.habitType,
    required this.primaryFamilyCode,
    required Set<String> secondaryFamilyCodes,
    required Set<String> goalCodes,
    required Map<OnboardingPace, OnboardingPaceCompatibility> paceCompatibility,
    required this.editorialPriority,
    required Map<String, dynamic> initialScheduleSnapshot,
    this.targetValue,
    this.unit,
    this.suggestedReminderTime,
    this.habitCatalogId,
    this.active = true,
  })  : secondaryFamilyCodes = Set.unmodifiable(secondaryFamilyCodes),
        goalCodes = Set.unmodifiable(goalCodes),
        paceCompatibility = Map.unmodifiable(paceCompatibility),
        initialScheduleSnapshot = Map.unmodifiable(
          Map<String, dynamic>.from(initialScheduleSnapshot),
        );

  final String id;
  final int catalogVersion;
  final OnboardingLocalizedContent localizedContent;
  final String emoji;
  final String habitType;
  final String primaryFamilyCode;
  final Set<String> secondaryFamilyCodes;
  final Set<String> goalCodes;
  final Map<OnboardingPace, OnboardingPaceCompatibility> paceCompatibility;
  final int editorialPriority;
  final Map<String, dynamic> initialScheduleSnapshot;
  final num? targetValue;
  final String? unit;
  final String? suggestedReminderTime;
  final String? habitCatalogId;
  final bool active;

  String nameFor(String locale) => localizedContent.nameFor(locale);

  String? descriptionFor(String locale) =>
      localizedContent.descriptionFor(locale);

  Set<String> get allFamilyCodes =>
      <String>{primaryFamilyCode, ...secondaryFamilyCodes};
}

@immutable
class OnboardingGoalFamilyRelation {
  OnboardingGoalFamilyRelation({
    required this.goalCode,
    required Set<String> primaryFamilyCodes,
    required Set<String> secondaryFamilyCodes,
  })  : primaryFamilyCodes = Set.unmodifiable(primaryFamilyCodes),
        secondaryFamilyCodes = Set.unmodifiable(secondaryFamilyCodes);

  final String goalCode;
  final Set<String> primaryFamilyCodes;
  final Set<String> secondaryFamilyCodes;
}

@immutable
class OnboardingRecommendationCatalogSnapshot {
  OnboardingRecommendationCatalogSnapshot({
    required this.version,
    required List<OnboardingRecommendation> recommendations,
    required List<OnboardingGoalFamilyRelation> goalFamilyRelations,
  })  : recommendations = List.unmodifiable(recommendations),
        goalFamilyRelations = List.unmodifiable(goalFamilyRelations);

  final int version;
  final List<OnboardingRecommendation> recommendations;
  final List<OnboardingGoalFamilyRelation> goalFamilyRelations;

  OnboardingRecommendation? findById(String? id) {
    if (id == null || id.trim().isEmpty) return null;
    for (final recommendation in recommendations) {
      if (recommendation.id == id) return recommendation;
    }
    return null;
  }

  OnboardingGoalFamilyRelation? relationFor(String goalCode) {
    for (final relation in goalFamilyRelations) {
      if (relation.goalCode == goalCode) return relation;
    }
    return null;
  }
}
