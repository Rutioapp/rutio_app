import 'package:flutter/foundation.dart';

/// Stable bundled V1 goal definition. Presentation resolves [localizationKey]
/// through the app's l10n layer; this model never stores translated labels.
@immutable
class OnboardingGoalDefinition {
  const OnboardingGoalDefinition({
    required this.code,
    required this.localizationKey,
  });

  final String code;
  final String localizationKey;
}

/// The only source of truth for the six bundled V1 goal codes.
class OnboardingGoalCatalog {
  const OnboardingGoalCatalog._();

  static const List<OnboardingGoalDefinition> definitions = [
    OnboardingGoalDefinition(
      code: 'care_body',
      localizationKey: 'onboardingGoalCareBody',
    ),
    OnboardingGoalDefinition(
      code: 'find_calm',
      localizationKey: 'onboardingGoalFindCalm',
    ),
    OnboardingGoalDefinition(
      code: 'organize_days',
      localizationKey: 'onboardingGoalOrganizeDays',
    ),
    OnboardingGoalDefinition(
      code: 'learn_grow',
      localizationKey: 'onboardingGoalLearnGrow',
    ),
    OnboardingGoalDefinition(
      code: 'care_relationships',
      localizationKey: 'onboardingGoalCareRelationships',
    ),
    OnboardingGoalDefinition(
      code: 'build_discipline',
      localizationKey: 'onboardingGoalBuildDiscipline',
    ),
  ];

  static final Set<String> validCodes = Set<String>.unmodifiable(
    definitions.map((definition) => definition.code),
  );

  static bool isValidSelection(Iterable<String> values) {
    final selection = values.toSet();
    return selection.isNotEmpty &&
        selection.length <= 3 &&
        selection.every(validCodes.contains);
  }
}
