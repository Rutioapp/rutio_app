import '../domain/models/onboarding_recommendation.dart';
import '../domain/models/onboarding_types.dart';
import '../domain/onboarding_recommendation_catalog_validator.dart';
import 'recommendation_catalog_repository.dart';

/// The only active bundled snapshot in Phase 4A.
///
/// Habit names and emojis are reused from the canonical bundled habit catalog;
/// this snapshot only adds onboarding metadata and stable recommendation ids.
class BundledRecommendationCatalogRepository
    implements RecommendationCatalogRepository {
  const BundledRecommendationCatalogRepository();

  static final OnboardingRecommendationCatalogSnapshot snapshot =
      OnboardingRecommendationCatalogSnapshot(
    version: OnboardingVersions.catalogVersion,
    goalFamilyRelations: <OnboardingGoalFamilyRelation>[
      OnboardingGoalFamilyRelation(
        goalCode: 'care_body',
        primaryFamilyCodes: {'body'},
        secondaryFamilyCodes: {'emotional'},
      ),
      OnboardingGoalFamilyRelation(
        goalCode: 'find_calm',
        primaryFamilyCodes: {'emotional', 'spirit'},
        secondaryFamilyCodes: {'mind'},
      ),
      OnboardingGoalFamilyRelation(
        goalCode: 'organize_days',
        primaryFamilyCodes: {'professional', 'discipline'},
        secondaryFamilyCodes: {'mind'},
      ),
      OnboardingGoalFamilyRelation(
        goalCode: 'learn_grow',
        primaryFamilyCodes: {'mind', 'professional'},
        secondaryFamilyCodes: {'discipline'},
      ),
      OnboardingGoalFamilyRelation(
        goalCode: 'care_relationships',
        primaryFamilyCodes: {'social', 'emotional'},
        secondaryFamilyCodes: const <String>{},
      ),
      OnboardingGoalFamilyRelation(
        goalCode: 'build_discipline',
        primaryFamilyCodes: {'discipline'},
        secondaryFamilyCodes: {'professional', 'body'},
      ),
    ],
    recommendations: <OnboardingRecommendation>[
      OnboardingRecommendation(
        id: 'onboarding_v1_move_body',
        catalogVersion: OnboardingVersions.catalogVersion,
        localizedContent: OnboardingLocalizedContent(
          names: {'es': 'Hacer ejercicio', 'en': 'Exercise'},
        ),
        emoji: '🏋️',
        habitType: 'check',
        primaryFamilyCode: 'body',
        secondaryFamilyCodes: {'discipline'},
        goalCodes: {'care_body', 'build_discipline'},
        paceCompatibility: _allPaces(
          gentle: OnboardingPaceCompatibility.adjacent,
          balanced: OnboardingPaceCompatibility.ideal,
          energized: OnboardingPaceCompatibility.ideal,
        ),
        editorialPriority: 18,
        initialScheduleSnapshot: {'type': 'daily'},
        suggestedReminderTime: '08:00',
        habitCatalogId: 'hacer_ejercicio',
      ),
      OnboardingRecommendation(
        id: 'onboarding_v1_walk_body',
        catalogVersion: OnboardingVersions.catalogVersion,
        localizedContent: OnboardingLocalizedContent(
          names: {'es': 'Caminar', 'en': 'Go for a walk'},
        ),
        emoji: '👟',
        habitType: 'count',
        primaryFamilyCode: 'body',
        secondaryFamilyCodes: {'discipline'},
        goalCodes: {'care_body'},
        paceCompatibility: _allPaces(
          gentle: OnboardingPaceCompatibility.ideal,
          balanced: OnboardingPaceCompatibility.ideal,
          energized: OnboardingPaceCompatibility.adjacent,
        ),
        editorialPriority: 17,
        initialScheduleSnapshot: {'type': 'daily'},
        targetValue: 6000,
        unit: 'steps',
        habitCatalogId: 'caminar_pasos_km',
      ),
      OnboardingRecommendation(
        id: 'onboarding_v1_breathe_calm',
        catalogVersion: OnboardingVersions.catalogVersion,
        localizedContent: OnboardingLocalizedContent(
          names: {'es': 'Respiración consciente', 'en': 'Mindful breathing'},
        ),
        emoji: '🌬️',
        habitType: 'check',
        primaryFamilyCode: 'emotional',
        secondaryFamilyCodes: {'spirit'},
        goalCodes: {'find_calm'},
        paceCompatibility: _allPaces(
          gentle: OnboardingPaceCompatibility.ideal,
          balanced: OnboardingPaceCompatibility.ideal,
          energized: OnboardingPaceCompatibility.adjacent,
        ),
        editorialPriority: 19,
        initialScheduleSnapshot: {'type': 'daily'},
        habitCatalogId: 'respiracion_consciente',
      ),
      OnboardingRecommendation(
        id: 'onboarding_v1_meditate_calm',
        catalogVersion: OnboardingVersions.catalogVersion,
        localizedContent: OnboardingLocalizedContent(
          names: {'es': 'Meditar', 'en': 'Meditate'},
        ),
        emoji: '🧘',
        habitType: 'count',
        primaryFamilyCode: 'spirit',
        secondaryFamilyCodes: {'emotional'},
        goalCodes: {'find_calm'},
        paceCompatibility: _allPaces(
          gentle: OnboardingPaceCompatibility.ideal,
          balanced: OnboardingPaceCompatibility.adjacent,
          energized: OnboardingPaceCompatibility.neutral,
        ),
        editorialPriority: 20,
        initialScheduleSnapshot: {'type': 'daily'},
        targetValue: 5,
        unit: 'minutes',
        habitCatalogId: 'meditar',
      ),
      OnboardingRecommendation(
        id: 'onboarding_v1_write_mind',
        catalogVersion: OnboardingVersions.catalogVersion,
        localizedContent: OnboardingLocalizedContent(
          names: {
            'es': 'Escribir ideas o reflexiones',
            'en': 'Write ideas or reflections'
          },
        ),
        emoji: '✍️',
        habitType: 'check',
        primaryFamilyCode: 'mind',
        secondaryFamilyCodes: {'emotional'},
        goalCodes: {'find_calm', 'learn_grow'},
        paceCompatibility: _allPaces(
          gentle: OnboardingPaceCompatibility.ideal,
          balanced: OnboardingPaceCompatibility.ideal,
          energized: OnboardingPaceCompatibility.adjacent,
        ),
        editorialPriority: 18,
        initialScheduleSnapshot: {'type': 'daily'},
        habitCatalogId: 'escribir_ideas_reflexiones',
      ),
      OnboardingRecommendation(
        id: 'onboarding_v1_read_grow',
        catalogVersion: OnboardingVersions.catalogVersion,
        localizedContent: OnboardingLocalizedContent(
          names: {'es': 'Leer 10 minutos', 'en': 'Read for 10 minutes'},
        ),
        emoji: '📖',
        habitType: 'count',
        primaryFamilyCode: 'mind',
        secondaryFamilyCodes: {'professional'},
        goalCodes: {'learn_grow'},
        paceCompatibility: _allPaces(
          gentle: OnboardingPaceCompatibility.ideal,
          balanced: OnboardingPaceCompatibility.ideal,
          energized: OnboardingPaceCompatibility.adjacent,
        ),
        editorialPriority: 17,
        initialScheduleSnapshot: {'type': 'daily'},
        targetValue: 10,
        unit: 'minutes',
        habitCatalogId: 'leer_x_minutos',
      ),
      OnboardingRecommendation(
        id: 'onboarding_v1_plan_day',
        catalogVersion: OnboardingVersions.catalogVersion,
        localizedContent: OnboardingLocalizedContent(
          names: {'es': 'Planificar el día', 'en': 'Plan your day'},
        ),
        emoji: '📋',
        habitType: 'check',
        primaryFamilyCode: 'discipline',
        secondaryFamilyCodes: {'professional', 'mind'},
        goalCodes: {'organize_days', 'build_discipline'},
        paceCompatibility: _allPaces(
          gentle: OnboardingPaceCompatibility.ideal,
          balanced: OnboardingPaceCompatibility.ideal,
          energized: OnboardingPaceCompatibility.adjacent,
        ),
        editorialPriority: 19,
        initialScheduleSnapshot: {'type': 'daily'},
        habitCatalogId: 'planificar_dia',
      ),
      OnboardingRecommendation(
        id: 'onboarding_v1_organize_work',
        catalogVersion: OnboardingVersions.catalogVersion,
        localizedContent: OnboardingLocalizedContent(
          names: {
            'es': 'Organizar tareas del día',
            'en': 'Organize your tasks'
          },
        ),
        emoji: '🗂️',
        habitType: 'check',
        primaryFamilyCode: 'professional',
        secondaryFamilyCodes: {'discipline'},
        goalCodes: {'organize_days', 'learn_grow'},
        paceCompatibility: _allPaces(
          gentle: OnboardingPaceCompatibility.adjacent,
          balanced: OnboardingPaceCompatibility.ideal,
          energized: OnboardingPaceCompatibility.ideal,
        ),
        editorialPriority: 16,
        initialScheduleSnapshot: {'type': 'daily'},
        habitCatalogId: 'organizar_tareas',
      ),
      OnboardingRecommendation(
        id: 'onboarding_v1_routine_discipline',
        catalogVersion: OnboardingVersions.catalogVersion,
        localizedContent: OnboardingLocalizedContent(
          names: {'es': 'Cumplir la rutina', 'en': 'Follow your routine'},
        ),
        emoji: '🔁',
        habitType: 'check',
        primaryFamilyCode: 'discipline',
        secondaryFamilyCodes: {'professional', 'body'},
        goalCodes: {'build_discipline', 'organize_days'},
        paceCompatibility: _allPaces(
          gentle: OnboardingPaceCompatibility.adjacent,
          balanced: OnboardingPaceCompatibility.ideal,
          energized: OnboardingPaceCompatibility.ideal,
        ),
        editorialPriority: 15,
        initialScheduleSnapshot: {'type': 'daily'},
        habitCatalogId: 'cumplir_rutina',
      ),
      OnboardingRecommendation(
        id: 'onboarding_v1_contact_social',
        catalogVersion: OnboardingVersions.catalogVersion,
        localizedContent: OnboardingLocalizedContent(
          names: {
            'es': 'Hablar con alguien querido',
            'en': 'Talk to someone you love'
          },
        ),
        emoji: '❤️',
        habitType: 'check',
        primaryFamilyCode: 'social',
        secondaryFamilyCodes: {'emotional'},
        goalCodes: {'care_relationships'},
        paceCompatibility: _allPaces(
          gentle: OnboardingPaceCompatibility.ideal,
          balanced: OnboardingPaceCompatibility.ideal,
          energized: OnboardingPaceCompatibility.neutral,
        ),
        editorialPriority: 18,
        initialScheduleSnapshot: {'type': 'daily'},
        habitCatalogId: 'hablar_ser_querido',
      ),
      OnboardingRecommendation(
        id: 'onboarding_v1_gratitude_social',
        catalogVersion: OnboardingVersions.catalogVersion,
        localizedContent: OnboardingLocalizedContent(
          names: {
            'es': 'Expresar gratitud a alguien',
            'en': 'Show gratitude to someone'
          },
        ),
        emoji: '🙌',
        habitType: 'check',
        primaryFamilyCode: 'social',
        secondaryFamilyCodes: {'emotional'},
        goalCodes: {'care_relationships'},
        paceCompatibility: _allPaces(
          gentle: OnboardingPaceCompatibility.ideal,
          balanced: OnboardingPaceCompatibility.ideal,
          energized: OnboardingPaceCompatibility.neutral,
        ),
        editorialPriority: 17,
        initialScheduleSnapshot: {'type': 'daily'},
        habitCatalogId: 'expresar_gratitud',
      ),
      OnboardingRecommendation(
        id: 'onboarding_v1_deep_work',
        catalogVersion: OnboardingVersions.catalogVersion,
        localizedContent: OnboardingLocalizedContent(
          names: {
            'es': 'Sesión de trabajo profundo',
            'en': 'Deep work session'
          },
        ),
        emoji: '🔬',
        habitType: 'count',
        primaryFamilyCode: 'professional',
        secondaryFamilyCodes: {'mind'},
        goalCodes: {'learn_grow', 'organize_days'},
        paceCompatibility: _allPaces(
          gentle: OnboardingPaceCompatibility.neutral,
          balanced: OnboardingPaceCompatibility.ideal,
          energized: OnboardingPaceCompatibility.ideal,
        ),
        editorialPriority: 18,
        initialScheduleSnapshot: {'type': 'daily'},
        targetValue: 25,
        unit: 'minutes',
        habitCatalogId: 'trabajo_profundo',
      ),
    ],
  );

  @override
  Future<OnboardingRecommendationCatalogSnapshot> resolve({
    required int catalogVersion,
    required String locale,
  }) async {
    if (catalogVersion != snapshot.version) {
      throw RecommendationCatalogException(
        message: 'Pinned recommendation catalog version is unavailable.',
        catalogVersion: catalogVersion,
      );
    }
    final result = OnboardingRecommendationCatalogValidator.validate(snapshot);
    if (result.validRecommendations.isEmpty) {
      throw RecommendationCatalogException(
        message: 'Bundled recommendation catalog has no valid entries.',
        catalogVersion: catalogVersion,
      );
    }
    // The model owns locale fallback: es-ES -> es, en-US -> en, then es.
    // Keeping locale as an input (rather than reading it here) keeps this
    // repository deterministic and ready for a future remote implementation.
    return snapshot;
  }
}

Map<OnboardingPace, OnboardingPaceCompatibility> _allPaces({
  required OnboardingPaceCompatibility gentle,
  required OnboardingPaceCompatibility balanced,
  required OnboardingPaceCompatibility energized,
}) =>
    <OnboardingPace, OnboardingPaceCompatibility>{
      OnboardingPace.gentle: gentle,
      OnboardingPace.balanced: balanced,
      OnboardingPace.energized: energized,
    };
